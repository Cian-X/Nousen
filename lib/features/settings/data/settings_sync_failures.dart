import 'dart:async';

import 'package:flutter/foundation.dart';

/// Jenis operasi tulis settings cloud-first (S3).
enum SettingsSyncOperation { save }

/// Satu kegagalan ack server (reject) untuk settings (S3).
///
/// Settings hanya satu dokumen (`settings/app`), jadi [id] selalu `'app'`.
class SettingsSyncFailure {
  const SettingsSyncFailure({
    required this.operation,
    required this.message,
    required this.at,
  });

  final SettingsSyncOperation operation;

  /// Pesan error dari SDK (mis. `[cloud_firestore/permission-denied] ...`).
  final String message;

  final DateTime at;
}

/// Pelacak kegagalan tulis cloud-first settings (S3).
///
/// Yang dilacak HANYA reject/gagal dari server saat ack. Status `pending`
/// (local queue / offline) bersumber dari metadata snapshot Firestore
/// (`hasPendingWrites` via `CloudFirstSettingsRepository.watchPendingIds`).
class SettingsSyncFailures {
  static const int _maxMessageLength = 160;

  final StreamController<SettingsSyncFailure> _events =
      StreamController<SettingsSyncFailure>.broadcast();

  /// Status gagal terakhir `settings/app` (badge settings).
  final ValueNotifier<SettingsSyncFailure?> byApp =
      ValueNotifier<SettingsSyncFailure?>(null);

  /// Event kegagalan (untuk snackbar / notifikasi UI).
  Stream<SettingsSyncFailure> get events => _events.stream;

  void record({required Object error}) {
    final String raw = error.toString();
    final SettingsSyncFailure failure = SettingsSyncFailure(
      operation: SettingsSyncOperation.save,
      message: raw.length <= _maxMessageLength
          ? raw
          : '${raw.substring(0, _maxMessageLength)}…',
      at: DateTime.now(),
    );
    byApp.value = failure;
    if (!_events.isClosed) {
      _events.add(failure);
    }
  }

  /// Hapus status gagal setelah ack sukses berikutnya (simpan ulang =
  /// retry = sembuh).
  void clear() {
    if (byApp.value != null) {
      byApp.value = null;
    }
  }

  void dispose() {
    _events.close();
    byApp.dispose();
  }
}
