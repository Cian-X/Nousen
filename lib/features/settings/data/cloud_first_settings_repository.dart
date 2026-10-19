import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';
import 'package:nousen/features/settings/data/cloud_settings_backend.dart';
import 'package:nousen/features/settings/data/settings_sync_failures.dart';
import 'package:nousen/features/settings/domain/app_settings_model.dart';
import 'package:nousen/features/settings/domain/settings_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Repository settings cloud-first (S3) — pola sama dengan
/// `CloudFirstProgressRepository` S2, dengan dua pengecualian yang disengaja
/// karena settings dibutuhkan SEBELUM AuthGate:
///
/// 1. **Belum login / Firebase off** → baca dari mirror Isar (default apps
///    tetap hidup di layar login). Jalur activity/progress melempar
///    `StateError`; settings tidak boleh, karena `appBootstrapProvider`
///    memanggil `get()` sebelum AuthGate dirender.
/// 2. **`get()` cloud diberi timeout** — bootstrap tidak boleh menggantung
///    saat offline pertama kali (dokumen belum ada di cache). Timeout/error
///    → fallback lokal (dicatat di log), bukan crash.
///
/// Path: `/users/{uid}/settings/app` (doc id `app`, skema v2).
///
/// Field yang TIDAK ikut cloud (path file perangkat; README §7/§15):
/// `profileAvatarPath`. Field lain (termasuk `notificationsEnabled` dan
/// `notificationVibration` di dalam `weeklyRoutineJson`) adalah preferensi
/// pengguna dan ikut tersinkron. Tidak ada field FCM/device id di model.
///
/// Semantik baca/tulis:
/// - BACA: Firestore authoritative; saat watch, nilai lokal dipakai hanya
///   sampai snapshot cloud pertama tiba / bila cloud error (settings harus
///   selalu punya nilai). Field lokal (`profileAvatarPath`) di-overlay dari
///   Isar.
/// - TULIS: Firestore diinisiasi dulu tanpa menunggu ack, mirror Isar
///   di-await segera (rollback flag OFF melihat data terbaru).
/// - LWW: `updatedAt = FieldValue.serverTimestamp()` — jam server yang
///   menentukan urutan menang, bukan jam device (`clientUpdatedAt` audit).
/// - Status: `pending` dari `hasPendingWrites`; `failed` dari reject server
///   ([SettingsSyncFailures]) — non-silent (badge + snackbar).
/// - Korelasi ack per-attempt: hanya hasil operasi terbaru yang diterapkan
///   (guard race ack out-of-order, pola S1b/S2).
class CloudFirstSettingsRepository implements SettingsRepository {
  CloudFirstSettingsRepository({
    required CloudSettingsBackend backend,
    required CloudAuthState authState,
    required SettingsRepository mirror,
    SettingsSyncFailures? failures,
    this.cloudGetTimeout = const Duration(seconds: 4),
  }) : _backend = backend,
       _authState = authState,
       _mirror = mirror,
       _failures = failures ?? SettingsSyncFailures();

  final CloudSettingsBackend _backend;
  final CloudAuthState _authState;
  final SettingsRepository _mirror;
  final SettingsSyncFailures _failures;

  /// Batas tunggu `get()` ke cloud saat bootstrap. Offline pertama kali
  /// (dokumen belum di-cache) tidak boleh menggantung app.
  final Duration cloudGetTimeout;

  /// Operasi tulis terakhir (settings singleton) — guard race ack.
  int _writeAttempt = 0;

  static const int schemaVersion = 2;

  /// Dokumen settings selalu `settings/app`.
  static const String singletonDocId = 'app';

  /// Akses pelacak kegagalan (wiring provider/UI).
  SettingsSyncFailures get failures => _failures;

  // ---------------------------------------------------------------------
  // Skema dokumen (dipakai tulis + tes; satu sumber kontrak)
  // ---------------------------------------------------------------------

  /// Dokumen settings hidup — field sama dengan backfill S0
  /// (`settingsBackfillMap`), ditambah `clientUpdatedAt` audit.
  ///
  /// `profileAvatarPath` sengaja TIDAK ditulis (path file perangkat).
  static Map<String, dynamic> settingsToMap(AppSettingsModel settings) {
    return <String, dynamic>{
      'id': singletonDocId,
      'morningReminderMinutes': settings.morningReminderMinutes,
      'endOfDayReminderMinutes': settings.endOfDayReminderMinutes,
      'localeCode': settings.localeCode,
      'notificationsEnabled': settings.notificationsEnabled,
      'profileName': settings.profileName,
      'weeklyRoutineJson': encodeSettingsPayload(
        settings.weeklyRoutine,
        settings.extraActivitiesNote,
        settings.hasSeededData,
        settings.notificationVibration,
      ),
      'wakeUpMinutes': settings.wakeUpMinutes,
      'sleepMinutes': settings.sleepMinutes,
      'usualBreakStartMinutes': settings.usualBreakStartMinutes,
      'usualBreakEndMinutes': settings.usualBreakEndMinutes,
      'clientUpdatedAt': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
      'deletedAt': null,
      'schemaVersion': schemaVersion,
    };
  }

  /// Bentuk domain dari dokumen cloud; [local] memasok field khusus
  /// perangkat (`profileAvatarPath`) dan fallback field yang tidak ada.
  static AppSettingsModel settingsFromMap(
    Map<String, dynamic> data, {
    required AppSettingsModel local,
  }) {
    final DecodedSettingsPayload payload = decodeSettingsPayload(
      _string(data['weeklyRoutineJson']),
    );
    return AppSettingsModel(
      morningReminderMinutes:
          _int(data['morningReminderMinutes']) ?? local.morningReminderMinutes,
      endOfDayReminderMinutes:
          _int(data['endOfDayReminderMinutes']) ??
          local.endOfDayReminderMinutes,
      localeCode: _string(data['localeCode']) ?? local.localeCode,
      notificationsEnabled: data['notificationsEnabled'] is bool
          ? data['notificationsEnabled'] as bool
          : local.notificationsEnabled,
      notificationVibration: payload.notificationVibration,
      profileName: data.containsKey('profileName')
          ? _string(data['profileName'])
          : local.profileName,
      extraActivitiesNote: payload.extraActivitiesNote,
      // Path avatar tetap lokal (tidak pernah ada di dokumen cloud).
      profileAvatarPath: local.profileAvatarPath,
      weeklyRoutine: payload.routine,
      wakeUpMinutes: data.containsKey('wakeUpMinutes')
          ? _int(data['wakeUpMinutes'])
          : local.wakeUpMinutes,
      sleepMinutes: data.containsKey('sleepMinutes')
          ? _int(data['sleepMinutes'])
          : local.sleepMinutes,
      usualBreakStartMinutes: data.containsKey('usualBreakStartMinutes')
          ? _int(data['usualBreakStartMinutes'])
          : local.usualBreakStartMinutes,
      usualBreakEndMinutes: data.containsKey('usualBreakEndMinutes')
          ? _int(data['usualBreakEndMinutes'])
          : local.usualBreakEndMinutes,
      hasSeededData: payload.hasSeededData,
    );
  }

  // ---------------------------------------------------------------------
  // Baca
  // ---------------------------------------------------------------------

  @override
  Stream<AppSettingsModel> watch() {
    return _switchOnSession<AppSettingsModel>(
      openCloud: _watchCloud,
      openLocal: _mirror.watch,
      debugTag: 'watch',
    );
  }

  /// Gabungan dua sumber selama sesi login:
  /// - mirror Isar → field khusus perangkat + nilai awal/fallback;
  /// - Firestore → preferensi authoritative; tiap snapshot cloud memicu
  ///   emisi gabungan.
  ///
  /// Error cloud TIDAK diteruskan mematikan stream: settings harus selalu
  /// punya nilai (locale/tema); error dicatat, UI lanjut dengan nilai lokal.
  Stream<AppSettingsModel> _watchCloud(String uid) {
    late final StreamController<AppSettingsModel> controller;
    StreamSubscription<AppSettingsModel>? localSub;
    StreamSubscription<CloudSettingsDoc?>? cloudSub;
    AppSettingsModel? local;
    Map<String, dynamic>? cloudData;
    var cloudSeen = false;
    var closed = false;

    void emit() {
      if (closed || local == null) {
        return;
      }
      final Map<String, dynamic>? data = cloudData;
      final AppSettingsModel value =
          (cloudSeen && data != null && data['deleted'] != true)
          ? settingsFromMap(data, local: local!)
          : local!;
      controller.add(value);
    }

    controller = StreamController<AppSettingsModel>(
      onListen: () {
        localSub = _mirror.watch().listen(
          (AppSettingsModel settings) {
            local = settings;
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!closed) {
              controller.addError(error, stackTrace);
            }
          },
        );
        cloudSub = _backend
            .watchDoc(uid)
            .listen(
              (CloudSettingsDoc? doc) {
                cloudSeen = true;
                cloudData = doc?.data;
                emit();
              },
              onError: (Object error, StackTrace stackTrace) {
                debugPrint(
                  '[cloudfirst-settings] watch cloud error → lokal: $error',
                );
                cloudSeen = true;
                cloudData = null;
                emit();
              },
            );
      },
      onCancel: () async {
        closed = true;
        await localSub?.cancel();
        await cloudSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<AppSettingsModel> get() async {
    final AppSettingsModel local = await _mirror.get();
    final String? uid = _authState.currentUid;
    if (uid == null || uid.isEmpty) {
      return local;
    }
    Map<String, dynamic>? data;
    try {
      data = await _backend.getDoc(uid).timeout(cloudGetTimeout);
    } catch (error) {
      debugPrint(
        '[cloudfirst-settings] get cloud gagal/timeout → lokal: $error',
      );
      return local;
    }
    if (data == null || data['deleted'] == true) {
      return local;
    }
    return settingsFromMap(data, local: local);
  }

  // ---------------------------------------------------------------------
  // Tulis
  // ---------------------------------------------------------------------

  @override
  Future<void> save(AppSettingsModel settings) async {
    final String? uid = _authState.currentUid;
    if (uid != null && uid.isNotEmpty) {
      final int attempt = _registerWrite();
      _trackAck(_backend.setDoc(uid, settingsToMap(settings)), attempt);
    }
    // Mirror di-await supaya rollback (flag OFF) cepat melihat data.
    // Settings pre-login tetap bisa disimpan lokal.
    try {
      await _mirror.save(settings);
      debugPrint('[cloudfirst-settings] mirror Isar SYNCED app');
    } catch (error) {
      debugPrint('[cloudfirst-settings] mirror Isar FAIL save: $error');
    }
  }

  /// Stream id pending settings; `{'app'}` bila dokumen menunggu ack.
  /// Kosong saat logout (tidak ada antrean cloud).
  Stream<Set<String>> watchPendingIds() {
    return _switchOnSession<Set<String>>(
      openCloud: (String uid) =>
          _backend.watchDoc(uid).map((CloudSettingsDoc? doc) {
            return doc != null && doc.hasPendingWrites
                ? const <String>{singletonDocId}
                : const <String>{};
          }),
      openLocal: () => Stream<Set<String>>.value(const <String>{}),
      debugTag: 'watchPendingIds',
    );
  }

  // ---------------------------------------------------------------------
  // Sesi + ack tracking
  // ---------------------------------------------------------------------

  /// Switch manual pada `uidChanges().distinct()` (bukan `asyncExpand` —
  /// source akan ter-pause permanen karena snapshots tidak pernah selesai).
  /// Logout → stream lokal; login → stream cloud+lokal. Re-subscribe tiap
  /// uid berubah agar listen Firestore hidup lagi setelah logout→login.
  Stream<T> _switchOnSession<T>({
    required Stream<T> Function(String uid) openCloud,
    required Stream<T> Function() openLocal,
    required String debugTag,
  }) {
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

    void openListen(Stream<T> next, String label) {
      inner = next.listen(
        (T data) {
          debugPrint('[cloudfirst-settings] $debugTag $label DATA');
          emit(data);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[cloudfirst-settings] $debugTag $label ERROR: $error');
          emitError(error, stackTrace);
        },
        onDone: () {
          debugPrint('[cloudfirst-settings] $debugTag $label DONE');
        },
      );
    }

    void switchSession(String? uid) {
      debugPrint('[cloudfirst-settings] $debugTag uid=${uid ?? 'null'}');
      final StreamSubscription<T>? previous = inner;
      inner = null;
      if (previous != null) {
        unawaited(previous.cancel());
      }
      if (uid == null || uid.isEmpty) {
        openListen(openLocal(), 'local');
        return;
      }
      openListen(openCloud(uid), 'cloud');
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

  int _registerWrite() {
    _writeAttempt += 1;
    return _writeAttempt;
  }

  /// Pantau ack/reject tanpa memblokir pemanggil; hanya operasi terbaru
  /// yang boleh mengubah status (pola S1b/S2).
  void _trackAck(Future<void> ack, int attempt) {
    unawaited(
      ack.then(
        (_) {
          if (_writeAttempt != attempt) {
            debugPrint(
              '[cloudfirst-settings] ack STALE diabaikan (attempt $attempt)',
            );
            return;
          }
          _failures.clear();
          debugPrint('[cloudfirst-settings] cloud ACK save app');
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_writeAttempt != attempt) {
            debugPrint(
              '[cloudfirst-settings] reject STALE diabaikan '
              '(attempt $attempt): $error',
            );
            return;
          }
          _failures.record(error: error);
          debugPrint('[cloudfirst-settings] cloud FAIL save: $error');
        },
      ),
    );
  }
}

String? _string(Object? raw) {
  if (raw is String) {
    return raw;
  }
  if (raw == null) {
    return null;
  }
  return '$raw';
}

int? _int(Object? raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw.trim());
  }
  return null;
}
