import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/data/cloud_activities_backend.dart';
import 'package:nousen/features/activity/data/firestore_activity_repository.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Repository aktivitas cloud-first (S0 kerangka → S1 mirror Isar →
/// S1b offline UX).
///
/// Path: `/users/{uid}/activities/{activityId}` dengan skema v2:
/// - `updatedAt` = server timestamp (LWW oleh jam server, bukan jam device);
/// - hapus = tombstone `{deleted: true, deletedAt: serverTimestamp()}`,
///   tidak pernah hard delete;
/// - `clientUpdatedAt` menyimpan jam device untuk audit.
///
/// Semantik baca/tulis (S1b):
/// - BACA selalu dari Firestore (authoritative, cloud-first).
/// - TULIS: Firestore DIINISIASI lebih dulu, tetapi penyelesaian operasi
///   TIDAK menunggu ack server — SDK Firestore hanya resolve/error setelah
///   server menjawab, sehingga `await` penuh menggantung saat offline.
///   Mirror Isar di-await segera setelahnya (cepat, offline-safe) supaya
///   rollback (flag OFF → jalur Isar) melihat data terbaru; lalu operasi
///   selesai dan UI tidak pernah menggantung saat offline.
/// - Status tulis per-activity:
///   - `pending` (local queue, belum di-ack server) dari metadata snapshot
///     Firestore via [watchPendingIds] — durable lintas force-stop karena
///     persistence SDK (terbukti di repro runtime, README §13.6);
///   - `synced` = tidak pending dan tidak gagal;
///   - `failed` (reject server: rules/auth/error lain) via [failures] —
///     di-surfacekan ke UI (snackbar + badge), bukan log senyap.
///   - korelasi per-attempt: ack/reject HANYA berlaku untuk operasi tulis
///     TERBARU activity tersebut; hasil operasi yang sudah digantikan
///     diabaikan — mencegah reject lama menimpa `synced` baru, dan ack
///     lama membersihkan `failed` terbaru (race ack out-of-order, temuan
///     QC Hermes 2026-10-18). Implementasi di [_trackAck].
/// - Batas API (jujur): FlutterFire TIDAK menyediakan Future "queued lokal"
///   yang terpisah dari ack server. Satu-satunya sinyal local-queue adalah
///   metadata `hasPendingWrites`. Karena itu "queued" di sini berarti
///   "tulis sudah diserahkan ke SDK" (lalu diverifikasi lewat metadata),
///   bukan klaim ack lokal palsu.
/// - Retry policy: transient/offline ditangani otomatis oleh antrean SDK
///   (mutation bertahan sampai ack, termasuk lintas force-stop); reject
///   permanen (rules/auth) TIDAK di-retry otomatis — user melihat status
///   failed + alasan, dan menyimpan ulang akan mengirim ulang. Reject yang
///   terjadi saat app mati tidak bisa direkonstruksi SDK → rekonsiliasi
///   penuh = S2 (belum ada).
/// - Mirror TIDAK pernah dipakai untuk baca dan tidak di-refresh oleh baca.
///
/// Catatan:
/// - Hanya dipakai bila `MigrationFlags.cloudFirstActivities` aktif; default
///   produksi tetap `DualWriteActivityRepository` (Isar primer).
/// - Query memfilter `deleted == false`; dokumen lama yang belum pernah
///   ditulis dengan field `deleted` harus di-backfill dulu sebelum flag
///   dinyalakan (lihat `BackfillService`).
/// - Tanpa login Firebase repository ini melempar [StateError] (jalur
///   cloud-first mensyaratkan auth produksi) — belum ada fallback senyap.
class CloudFirstActivityRepository implements ActivityRepository {
  CloudFirstActivityRepository({
    required CloudActivitiesBackend backend,
    required CloudAuthState authState,
    ActivityRepository? mirror,
    ActivitySyncFailures? failures,
  }) : _backend = backend,
       _authState = authState,
       _mirror = mirror,
       _failures = failures ?? ActivitySyncFailures();

  final CloudActivitiesBackend _backend;
  final CloudAuthState _authState;

  /// Mirror lokal (Isar) untuk jalur rollback; null = tanpa mirror.
  final ActivityRepository? _mirror;

  /// Pelacak kegagalan ack server per-activity (dipakai UI via provider).
  final ActivitySyncFailures _failures;

  /// Nomor urut operasi tulis terakhir per activity — dasar korelasi
  /// ack/reject dengan operasi terbaru (guard race ack out-of-order).
  /// Nilai selalu naik dan tidak pernah direset selama repo hidup.
  final Map<String, int> _writeAttempts = <String, int>{};

  /// Akses pelacak kegagalan (wiring provider/UI).
  ActivitySyncFailures get failures => _failures;

  /// Versi skema dokumen cloud (S0/S1: v2 — tombstone + server timestamp).
  static const int schemaVersion = 2;

  String get _uid {
    final String? uid = _authState.currentUid;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'CloudFirstActivityRepository butuh login Firebase (uid null).',
      );
    }
    return uid;
  }

  /// Map tulis skema v2 dari model domain (dipakai upsert/tombstone).
  static Map<String, dynamic> toMap(
    ActivityModel activity, {
    required bool deleted,
  }) {
    return <String, dynamic>{
      ...FirestoreActivityRepository.toMap(activity),
      'clientUpdatedAt': activity.updatedAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': deleted,
      'deletedAt': deleted ? FieldValue.serverTimestamp() : null,
      'schemaVersion': schemaVersion,
    };
  }

  /// Map tombstone (delete = update, bukan hard delete).
  static Map<String, dynamic> tombstoneMap() {
    return <String, dynamic>{
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': schemaVersion,
    };
  }

  /// Baca aman: konversi nilai `Timestamp` server ke ISO-8601 string agar
  /// bisa diparse [FirestoreActivityRepository.fromMap].
  static ActivityModel fromFirestoreMap(Map<String, dynamic> m) {
    final Map<String, dynamic> normalized = <String, dynamic>{};
    m.forEach((String key, Object? value) {
      normalized[key] = value is Timestamp
          ? value.toDate().toIso8601String()
          : value;
    });
    return FirestoreActivityRepository.fromMap(normalized);
  }

  List<ActivityModel> _visible(Iterable<Map<String, dynamic>> docs) {
    final List<ActivityModel> list = <ActivityModel>[];
    for (final Map<String, dynamic> doc in docs) {
      if (doc['deleted'] == true) {
        continue;
      }
      list.add(fromFirestoreMap(doc));
    }
    list.sort((ActivityModel a, ActivityModel b) => a.title.compareTo(b.title));
    return list;
  }

  // ---- Baca: selalu cloud, reaktif terhadap sesi ----

  /// Validasi perilaku lama: pemanggilan watch tanpa login melempar
  /// `StateError` (dites), bukan diam-diam stream kosong.
  String _requireUid() => _uid;

  /// Stream cloud yang REAKTIF TERHADAP SESI (fix bug uji device S2).
  ///
  /// Listen Firestore lama TIDAK pernah hidup lagi setelah logout→login:
  /// saat logout SDK me-restart listen tanpa auth → server menolak
  /// (rules butuh auth) dan target itu gagal permanen; tanpa re-subscribe,
  /// UI beku — tulis jalan tapi baca tidak pernah terlihat ("tidak bisa
  /// ceklist / bikin aktivitas"). Karena itu listen dibuat ULANG setiap
  /// uid berubah (logout, login lagi, atau ganti akun).
  ///
  /// Kenapa bukan `asyncExpand`: implementasi Dart-nya mem-PAUSE source
  /// selama stream konversi hidup (`subscription.pause()`, dan `resume`
  /// baru setelah stream konversi SELESAI). `snapshots()` Firestore tidak
  /// pernah selesai, jadi setelah uid pertama source sesi ter-pause
  /// permanen dan event logout/login tidak pernah diproses — re-subscribe
  /// jadi no-op (bukti device 2026-10-18: `uid=` tercetak sekali per
  /// stream, lalu `listen ERROR` permission-denied tanpa pemulihan).
  ///
  /// Implementasi: switch manual — subscription sesi (`uidChanges`)
  /// SELALU hidup (tidak pernah di-pause); tiap uid baru, listen lama
  /// dibatalkan dan listen baru dibuka.
  ///
  /// Sesi berakhir (uid null) → emisi kosong (bukan error) supaya stream
  /// tetap hidup untuk sesi berikutnya.
  Stream<T> _sessionStream<T>(
    Stream<T> Function(String uid) open, {
    required T Function() whenLoggedOut,
    required String debugTag,
  }) {
    _requireUid();
    late final StreamController<T> controller;
    StreamSubscription<T>? inner;
    StreamSubscription<String?>? session;
    var closed = false;

    void emit(T data) {
      if (!closed) {
        controller.add(data);
      }
    }

    void emitError(Object error, StackTrace stackTrace) {
      if (!closed) {
        controller.addError(error, stackTrace);
      }
    }

    void openListen(String uid) {
      Stream<T> next;
      try {
        next = open(uid);
      } catch (error, stackTrace) {
        // Perilaku lama (asyncExpand) juga meneruskan kegagalan membuka
        // listen sebagai error stream, bukan crash di callback.
        emitError(error, stackTrace);
        return;
      }
      inner = next.listen(
        (T data) {
          debugPrint('[cloudfirst-activity] $debugTag listen DATA');
          emit(data);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[cloudfirst-activity] $debugTag listen ERROR: $error');
          emitError(error, stackTrace);
        },
        onDone: () {
          debugPrint('[cloudfirst-activity] $debugTag listen DONE');
        },
      );
    }

    void switchSession(String? uid) {
      debugPrint('[cloudfirst-activity] $debugTag uid=${uid ?? 'null'}');
      final StreamSubscription<T>? previous = inner;
      inner = null;
      if (previous != null) {
        unawaited(previous.cancel());
      }
      if (uid == null || uid.isEmpty) {
        emit(whenLoggedOut());
        return;
      }
      openListen(uid);
    }

    controller = StreamController<T>(
      onListen: () {
        session = _authState.uidChanges().distinct().listen(
          switchSession,
          onError: emitError,
        );
      },
      onCancel: () {
        closed = true;
        unawaited(session?.cancel());
        final StreamSubscription<T>? previous = inner;
        inner = null;
        if (previous != null) {
          unawaited(previous.cancel());
        }
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<ActivityModel>> watchAll() {
    return _sessionStream(
      (String uid) => _backend
          .watchVisible(uid)
          .map(
            (List<CloudActivityDoc> docs) =>
                _visible(docs.map((CloudActivityDoc d) => d.data)),
          ),
      whenLoggedOut: () => const <ActivityModel>[],
      debugTag: 'watchAll',
    );
  }

  /// Stream id activity yang tulisannya masih menunggu ack server
  /// (`hasPendingWrites == true` di snapshot Firestore).
  ///
  /// Dipakai UI untuk badge pending per-activity; durable lintas
  /// force-stop/relaunch karena cache + antrean tulis di-persist SDK.
  Stream<Set<String>> watchPendingIds() {
    return _sessionStream(
      (String uid) => _backend.watchVisible(uid).map(
            (List<CloudActivityDoc> docs) {
              final Set<String> pending = <String>{};
              for (final CloudActivityDoc doc in docs) {
                if (doc.hasPendingWrites && doc.data['deleted'] != true) {
                  pending.add(doc.id);
                }
              }
              return pending;
            },
          ),
      whenLoggedOut: () => const <String>{},
      debugTag: 'watchPendingIds',
    );
  }

  @override
  Future<List<ActivityModel>> getAll() async {
    final List<Map<String, dynamic>> docs = await _backend.queryVisible(_uid);
    return _visible(docs);
  }

  @override
  Future<ActivityModel?> getById(String id) async {
    final Map<String, dynamic>? data = await _backend.getDoc(_uid, id);
    if (data == null || data['deleted'] == true) {
      return null;
    }
    return fromFirestoreMap(data);
  }

  // ---- Tulis: cloud diinisiasi (tanpa menunggu ack), mirror segera ----

  @override
  Future<void> upsert(ActivityModel activity) async {
    // _uid melempar StateError (tanpa login) sebelum efek apa pun.
    final String uid = _uid;
    final int attempt = _registerWrite(activity.id);
    _trackAck(
      _backend.setDoc(uid, activity.id, toMap(activity, deleted: false)),
      activityId: activity.id,
      attempt: attempt,
      operation: ActivitySyncOperation.save,
    );
    // Mirror di-await supaya rollback (flag OFF) cepat melihat data —
    // Isar lokal tidak butuh jaringan, jadi tetap cepat saat offline.
    await _mirrorUpsert(activity);
  }

  @override
  Future<void> delete(String id) async {
    final String uid = _uid;
    final int attempt = _registerWrite(id);
    _trackAck(
      _backend.setDoc(uid, id, tombstoneMap()),
      activityId: id,
      attempt: attempt,
      operation: ActivitySyncOperation.delete,
    );
    // Mirror langsung dihapus (bukan menunggu ack): rollback tidak boleh
    // memunculkan entri yang sudah dihapus walau tombstone belum di-ack.
    await _mirrorDelete(id);
  }

  /// Daftarkan operasi tulis baru untuk [activityId]; kembalikan nomor
  /// urutnya (selalu naik, tidak pernah reset).
  int _registerWrite(String activityId) {
    final int next = (_writeAttempts[activityId] ?? 0) + 1;
    _writeAttempts[activityId] = next;
    return next;
  }

  /// Pantau ack/reject server tanpa memblokir pemanggil.
  ///
  /// Korelasi per-attempt (temuan QC Hermes 2026-10-18): hasil ack hanya
  /// diterapkan bila [attempt] masih operasi TERBARU untuk activity ini.
  /// Ack/reject yang datang telat (out-of-order) setelah operasi berikutnya
  /// TIDAK boleh menimpa status terbaru — baik itu stale reject yang
  /// memunculkan `failed` palsu, maupun stale ack yang membersihkan
  /// `failed` terbaru.
  ///
  /// - ack sukses terbaru → clear status failed activity ini (sembuh);
  /// - reject terbaru → catat di [failures] (snackbar + badge failed) + log;
  /// - hasil operasi yang sudah digantikan → diabaikan (log debug).
  void _trackAck(
    Future<void> ack, {
    required String activityId,
    required int attempt,
    required ActivitySyncOperation operation,
  }) {
    unawaited(
      ack.then(
        (_) {
          if (_writeAttempts[activityId] != attempt) {
            debugPrint(
              '[cloudfirst-activity] ack STALE diabaikan ${operation.name} '
              '$activityId (attempt $attempt)',
            );
            return;
          }
          _failures.clear(activityId);
          debugPrint(
            '[cloudfirst-activity] cloud ACK ${operation.name} $activityId',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_writeAttempts[activityId] != attempt) {
            debugPrint(
              '[cloudfirst-activity] reject STALE diabaikan '
              '${operation.name} $activityId (attempt $attempt): $error',
            );
            return;
          }
          _failures.record(
            activityId: activityId,
            operation: operation,
            error: error,
          );
          debugPrint(
            '[cloudfirst-activity] cloud FAIL ${operation.name} '
            '$activityId: $error',
          );
        },
      ),
    );
  }

  Future<void> _mirrorUpsert(ActivityModel activity) async {
    final ActivityRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.upsert(activity);
      debugPrint('[cloudfirst-activity] mirror Isar SYNCED ${activity.id}');
    } catch (e) {
      debugPrint(
        '[cloudfirst-activity] mirror Isar FAIL upsert ${activity.id}: $e',
      );
    }
  }

  Future<void> _mirrorDelete(String id) async {
    final ActivityRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.delete(id);
      debugPrint('[cloudfirst-activity] mirror Isar DELETE $id');
    } catch (e) {
      debugPrint('[cloudfirst-activity] mirror Isar FAIL delete $id: $e');
    }
  }
}
