import 'dart:async';

import 'package:flutter/foundation.dart';

/// Jenis operasi tulis activity cloud-first (S1b).
enum ActivitySyncOperation { save, delete }

/// Satu kegagalan ack server (reject) untuk satu activity.
class ActivitySyncFailure {
  const ActivitySyncFailure({
    required this.activityId,
    required this.operation,
    required this.message,
    required this.at,
  });

  final String activityId;
  final ActivitySyncOperation operation;

  /// Pesan error dari SDK (mis. `[cloud_firestore/permission-denied] ...`).
  final String message;

  final DateTime at;
}

/// Pelacak kegagalan tulis cloud-first per-activity (S1b).
///
/// Yang dilacak HANYA reject/gagal dari server saat ack (rules, auth,
/// error lain) — ini yang membuat kegagalan tulis TIDAK senyap.
/// Status `pending` (local queue / offline) TIDAK di sini: sumbernya
/// metadata snapshot Firestore (`hasPendingWrites` via
/// `CloudFirstActivityRepository.watchPendingIds`) yang durable lintas
/// force-stop karena persistence SDK.
///
/// Batas jujur: pelacak ini in-memory per sesi app. Reject yang diputuskan
/// server saat proses app sudah mati tidak bisa direkonstruksi SDK saat app
/// hidup kembali (mutation sudah dibuang dari antrean) — rekonsiliasi
/// semacam itu = S2 (README §13.6).
class ActivitySyncFailures {
  static const int _maxMessageLength = 160;

  final Map<String, ActivitySyncFailure> _byActivity =
      <String, ActivitySyncFailure>{};

  final StreamController<ActivitySyncFailure> _events =
      StreamController<ActivitySyncFailure>.broadcast();

  /// Status gagal terakhir per activity id (untuk badge UI).
  final ValueNotifier<Map<String, ActivitySyncFailure>> byActivity =
      ValueNotifier<Map<String, ActivitySyncFailure>>(
        const <String, ActivitySyncFailure>{},
      );

  /// Event kegagalan (untuk snackbar / notifikasi UI).
  Stream<ActivitySyncFailure> get events => _events.stream;

  void record({
    required String activityId,
    required ActivitySyncOperation operation,
    required Object error,
  }) {
    final String raw = error.toString();
    final ActivitySyncFailure failure = ActivitySyncFailure(
      activityId: activityId,
      operation: operation,
      message: raw.length <= _maxMessageLength
          ? raw
          : '${raw.substring(0, _maxMessageLength)}…',
      at: DateTime.now(),
    );
    _byActivity[activityId] = failure;
    byActivity.value = Map<String, ActivitySyncFailure>.unmodifiable(
      _byActivity,
    );
    if (!_events.isClosed) {
      _events.add(failure);
    }
  }

  /// Hapus status gagal setelah ack sukses berikutnya untuk activity yang
  /// sama (menyimpan ulang = mengirim ulang = sembuh).
  void clear(String activityId) {
    if (_byActivity.remove(activityId) != null) {
      byActivity.value = Map<String, ActivitySyncFailure>.unmodifiable(
        _byActivity,
      );
    }
  }

  void dispose() {
    _events.close();
    byActivity.dispose();
  }
}
