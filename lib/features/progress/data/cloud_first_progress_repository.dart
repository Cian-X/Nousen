import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nousen/features/progress/data/cloud_progress_backend.dart';
import 'package:nousen/features/progress/data/firestore_progress_repository.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Repository progress cloud-first (S2) — pola sama dengan
/// `CloudFirstActivityRepository` S1b.
///
/// Path: `/users/{uid}/progress/{entryId}` — skema dokumen tetap v1
/// (identik `FirestoreProgressRepository.toMap/fromMap`): tanpa tombstone
/// `deleted`, hapus per-activity = batch hard delete. Kontrak skema
/// disatukan di [FirestoreProgressRepository] agar kompatibel dengan jalur
/// dual-write (rollback / restore).
///
/// Semantik baca/tulis (S2):
/// - BACA selalu dari Firestore (authoritative, cloud-first).
/// - TULIS: Firestore DIINISIASI lebih dulu, tetapi penyelesaian operasi
///   TIDAK menunggu ack server — SDK Firestore hanya resolve/error setelah
///   server menjawab, sehingga `await` penuh menggantung saat offline.
///   Mirror Isar di-await segera setelahnya (cepat, offline-safe) supaya
///   rollback (flag OFF → jalur Isar) melihat data terbaru; lalu operasi
///   selesai dan UI tidak pernah menggantung saat offline.
/// - Status tulis:
///   - `pending` (local queue, belum di-ack server) dari metadata snapshot
///     Firestore via [watchPendingIds] — durable lintas force-stop karena
///     persistence SDK (pola S1b, README §13.6);
///   - `synced` = tidak pending dan tidak gagal;
///   - `failed` (reject server: rules/auth/error lain) di-surfacekan ke UI
///     (snackbar + badge), bukan log senyap:
///     `upsert` → per-entry (`ProgressSyncFailures.byEntry`, badge entri);
///     `deleteByActivity` → activity-scoped
///     (`ProgressSyncFailures.byActivity`, badge kartu/header aktivitas —
///     tetap terlihat setelah baris entri lokal terhapus);
///   - korelasi per-attempt: ack/reject HANYA berlaku untuk operasi tulis
///     TERBARU entry tersebut (guard key; `deleteByActivity` memakai guard
///     key sendiri `delete-by-activity:<activityId>`); hasil operasi yang
///     sudah digantikan diabaikan — mencegah reject lama menimpa `synced`
///     baru dan ack lama membersihkan `failed` terbaru (race ack
///     out-of-order, pola fix QC Hermes 2026-10-18).
/// - Batas API (jujur): FlutterFire TIDAK menyediakan Future "queued lokal"
///   yang terpisah dari ack server. Satu-satunya sinyal local-queue adalah
///   metadata `hasPendingWrites`. Karena itu "pending" di sini berarti
///   "tulis sudah diserahkan ke SDK" (lalu diverifikasi lewat metadata),
///   bukan klaim ack lokal palsu.
/// - Retry policy: transient/offline ditangani otomatis oleh antrean SDK
///   (mutation bertahan sampai ack, termasuk lintas force-stop); reject
///   permanen (rules/auth) TIDAK di-retry otomatis — user melihat status
///   failed + alasan, dan menyimpan ulang akan mengirim ulang. Reject yang
///   terjadi saat app mati tidak bisa direkonstruksi SDK → rekonsiliasi
///   penuh belum ada.
/// - Mirror TIDAK pernah dipakai untuk baca dan tidak di-refresh oleh baca.
///
/// Catatan:
/// - Hanya dipakai bila `MigrationFlags.cloudFirstProgress` aktif; default
///   produksi tetap `DualWriteProgressRepository` (Isar primer).
/// - Tanpa login Firebase repository ini melempar [StateError] (jalur
///   cloud-first mensyaratkan auth produksi) — belum ada fallback senyap.
class CloudFirstProgressRepository implements ProgressRepository {
  CloudFirstProgressRepository({
    required CloudProgressBackend backend,
    required CloudAuthState authState,
    ProgressRepository? mirror,
    ProgressSyncFailures? failures,
  }) : _backend = backend,
       _authState = authState,
       _mirror = mirror,
       _failures = failures ?? ProgressSyncFailures();

  final CloudProgressBackend _backend;
  final CloudAuthState _authState;

  /// Mirror lokal (Isar) untuk jalur rollback; null = tanpa mirror.
  final ProgressRepository? _mirror;

  /// Pelacak kegagalan ack server per-entry (dipakai UI via provider).
  final ProgressSyncFailures _failures;

  /// Nomor urut operasi tulis terakhir per guard key — dasar korelasi
  /// ack/reject dengan operasi terbaru (guard race ack out-of-order).
  /// Nilai selalu naik dan tidak pernah direset selama repo hidup.
  final Map<String, int> _writeAttempts = <String, int>{};

  /// Prefix guard key untuk operasi pembersihan `deleteByActivity`
  /// (dipisah dari guard key entry id agar tidak saling mengganggu).
  static const String _deleteByActivityGuardPrefix = 'delete-by-activity:';

  /// Akses pelacak kegagalan (wiring provider/UI).
  ProgressSyncFailures get failures => _failures;

  String get _uid {
    final String? uid = _authState.currentUid;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'CloudFirstProgressRepository butuh login Firebase (uid null).',
      );
    }
    return uid;
  }

  List<ProgressEntryModel> _models(
    Iterable<Map<String, dynamic>> docs, {
    required int Function(ProgressEntryModel a, ProgressEntryModel b) compare,
  }) {
    final List<ProgressEntryModel> models = docs
        .map(FirestoreProgressRepository.fromMap)
        .toList();
    models.sort(compare);
    return models;
  }

  static int _byDateKeyDesc(ProgressEntryModel a, ProgressEntryModel b) =>
      b.dateKey.compareTo(a.dateKey);

  static int _byDateKeyAsc(ProgressEntryModel a, ProgressEntryModel b) =>
      a.dateKey.compareTo(b.dateKey);

  static int _byActivityIdAsc(ProgressEntryModel a, ProgressEntryModel b) =>
      a.activityId.compareTo(b.activityId);

  List<ProgressEntryModel> _visibleFrom(
    List<CloudProgressDoc> docs, {
    required int Function(ProgressEntryModel a, ProgressEntryModel b) compare,
  }) {
    return _models(
      docs.map((CloudProgressDoc d) => d.data),
      compare: compare,
    );
  }

  // ---- Baca: selalu cloud ----

  @override
  Stream<List<ProgressEntryModel>> watchAll() {
    return _backend
        .watchAll(_uid)
        .map(
          (List<CloudProgressDoc> docs) =>
              _visibleFrom(docs, compare: _byDateKeyDesc),
        );
  }

  /// Stream id entry progress yang tulisannya masih menunggu ack server
  /// (`hasPendingWrites == true` di snapshot Firestore).
  ///
  /// Dipakai UI untuk badge pending per-entry; durable lintas
  /// force-stop/relaunch karena cache + antrean tulis di-persist SDK.
  Stream<Set<String>> watchPendingIds() {
    return _backend.watchAll(_uid).map((List<CloudProgressDoc> docs) {
      final Set<String> pending = <String>{};
      for (final CloudProgressDoc doc in docs) {
        if (doc.hasPendingWrites) {
          pending.add(doc.id);
        }
      }
      return pending;
    });
  }

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) {
    return _backend.watchAll(_uid).map(
          (List<CloudProgressDoc> docs) => _visibleFrom(
            docs
                .where(
                  (CloudProgressDoc d) => d.data['activityId'] == activityId,
                )
                .toList(),
            compare: _byDateKeyDesc,
          ),
        );
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) {
    return _backend.watchAll(_uid).map(
          (List<CloudProgressDoc> docs) => _visibleFrom(
            docs
                .where((CloudProgressDoc d) => d.data['dateKey'] == dateKey)
                .toList(),
            compare: _byActivityIdAsc,
          ),
        );
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) {
    return _backend.watchAll(_uid).map(
          (List<CloudProgressDoc> docs) => _visibleFrom(
            docs
                .where((CloudProgressDoc d) {
                  final Object? key = d.data['dateKey'];
                  if (key is! String) {
                    return false;
                  }
                  return key.compareTo(fromDateKey) >= 0 &&
                      key.compareTo(toDateKey) <= 0;
                })
                .toList(),
            compare: _byDateKeyAsc,
          ),
        );
  }

  @override
  Future<List<ProgressEntryModel>> getAll() async {
    final List<Map<String, dynamic>> docs = await _backend.queryAll(_uid);
    return _models(docs, compare: _byDateKeyDesc);
  }

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async {
    final Map<String, dynamic>? data = await _backend.getByActivityAndDate(
      _uid,
      activityId: activityId,
      dateKey: dateKey,
    );
    if (data == null) {
      return null;
    }
    return FirestoreProgressRepository.fromMap(data);
  }

  // ---- Tulis: cloud diinisiasi (tanpa menunggu ack), mirror segera ----

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    // _uid melempar StateError (tanpa login) sebelum efek apa pun.
    final String uid = _uid;
    final int attempt = _registerWrite(entry.id);
    _trackAck(
      _backend.setDoc(uid, entry.id, FirestoreProgressRepository.toMap(entry)),
      guardKey: entry.id,
      recordId: entry.id,
      attempt: attempt,
      operation: ProgressSyncOperation.save,
      activityScoped: false,
    );
    // Mirror di-await supaya rollback (flag OFF) cepat melihat data —
    // Isar lokal tidak butuh jaringan, jadi tetap cepat saat offline.
    await _mirrorUpsert(entry);
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    final String uid = _uid;
    final String guardKey = '$_deleteByActivityGuardPrefix$activityId';
    final int attempt = _registerWrite(guardKey);
    _trackAck(
      _backend.deleteByActivity(uid, activityId),
      guardKey: guardKey,
      recordId: activityId,
      attempt: attempt,
      operation: ProgressSyncOperation.delete,
      activityScoped: true,
    );
    // Mirror langsung dihapus (bukan menunggu ack): rollback tidak boleh
    // memunculkan entri yang sudah dihapus walau batch delete belum di-ack.
    await _mirrorDeleteByActivity(activityId);
  }

  /// Daftarkan operasi tulis baru untuk [guardKey]; kembalikan nomor
  /// urutnya (selalu naik, tidak pernah reset).
  int _registerWrite(String guardKey) {
    final int next = (_writeAttempts[guardKey] ?? 0) + 1;
    _writeAttempts[guardKey] = next;
    return next;
  }

  /// Pantau ack/reject server tanpa memblokir pemanggil.
  ///
  /// Korelasi per-attempt (pola S1b): hasil ack hanya diterapkan bila
  /// [attempt] masih operasi TERBARU untuk [guardKey]. Ack/reject yang
  /// datang telat (out-of-order) setelah operasi berikutnya TIDAK boleh
  /// menimpa status terbaru — baik itu stale reject yang memunculkan
  /// `failed` palsu, maupun stale ack yang membersihkan `failed` terbaru.
  ///
  /// - ack sukses terbaru → clear status failed [recordId] (sembuh);
  /// - reject terbaru → catat di [failures] (snackbar + badge failed) + log;
  /// - hasil operasi yang sudah digantikan → diabaikan (log debug).
  ///
  /// [activityScoped] memilih cakupan pencatatan kegagalan: `false` untuk
  /// `upsert` (per-entry, [ProgressSyncFailures.byEntry]); `true` untuk
  /// `deleteByActivity` (per-activity, [ProgressSyncFailures.byActivity] —
  /// tetap terlihat setelah baris entri lokal terhapus).
  void _trackAck(
    Future<void> ack, {
    required String guardKey,
    required String recordId,
    required int attempt,
    required ProgressSyncOperation operation,
    required bool activityScoped,
  }) {
    unawaited(
      ack.then(
        (_) {
          if (_writeAttempts[guardKey] != attempt) {
            debugPrint(
              '[cloudfirst-progress] ack STALE diabaikan ${operation.name} '
              '$recordId (attempt $attempt)',
            );
            return;
          }
          if (activityScoped) {
            _failures.clearActivity(recordId);
          } else {
            _failures.clear(recordId);
          }
          debugPrint(
            '[cloudfirst-progress] cloud ACK ${operation.name} $recordId',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_writeAttempts[guardKey] != attempt) {
            debugPrint(
              '[cloudfirst-progress] reject STALE diabaikan '
              '${operation.name} $recordId (attempt $attempt): $error',
            );
            return;
          }
          if (activityScoped) {
            _failures.recordActivity(
              activityId: recordId,
              operation: operation,
              error: error,
            );
          } else {
            _failures.record(
              entryId: recordId,
              operation: operation,
              error: error,
            );
          }
          debugPrint(
            '[cloudfirst-progress] cloud FAIL ${operation.name} '
            '$recordId: $error',
          );
        },
      ),
    );
  }

  Future<void> _mirrorUpsert(ProgressEntryModel entry) async {
    final ProgressRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.upsert(entry);
      debugPrint('[cloudfirst-progress] mirror Isar SYNCED ${entry.id}');
    } catch (e) {
      debugPrint(
        '[cloudfirst-progress] mirror Isar FAIL upsert ${entry.id}: $e',
      );
    }
  }

  Future<void> _mirrorDeleteByActivity(String activityId) async {
    final ProgressRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.deleteByActivity(activityId);
      debugPrint(
        '[cloudfirst-progress] mirror Isar DELETE byActivity $activityId',
      );
    } catch (e) {
      debugPrint(
        '[cloudfirst-progress] mirror Isar FAIL delete $activityId: $e',
      );
    }
  }
}
