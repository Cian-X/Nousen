import 'dart:async';

import 'package:flutter/foundation.dart';

/// Jenis operasi tulis progress cloud-first (S2).
enum ProgressSyncOperation { save, delete }

/// Satu kegagalan ack server (reject) untuk satu operasi progress (S2).
///
/// [id] = subjek kegagalan: id entri progress untuk operasi `save`;
/// activity id untuk operasi `delete` (`deleteByActivity`). Pembersihan
/// progres per-activity tidak lagi punya baris entri di UI setelah mirror
/// terhapus, sehingga kegagalannya activity-scoped (badge di kartu/header
/// aktivitas) dan tidak boleh tercampur dengan id entri.
class ProgressSyncFailure {
  const ProgressSyncFailure({
    required this.id,
    required this.operation,
    required this.message,
    required this.at,
  });

  final String id;
  final ProgressSyncOperation operation;

  /// Pesan error dari SDK (mis. `[cloud_firestore/permission-denied] ...`).
  final String message;

  final DateTime at;
}

/// Pelacak kegagalan tulis cloud-first progress (S2).
///
/// Dua cakupan, dipisah map-nya:
/// - [byEntry]: reject `upsert` per entri progress — badge per-entry
///   (`ProgressSyncBadge`) + snackbar;
/// - [byActivity]: reject `deleteByActivity` per activity — badge
///   activity-scoped (`ProgressDeleteBadge`) yang TETAP terlihat setelah
///   baris progress lokal terhapus + snackbar.
///
/// Yang dilacak HANYA reject/gagal dari server saat ack (rules, auth,
/// error lain) — ini yang membuat kegagalan tulis TIDAK senyap.
/// Status `pending` (local queue / offline) TIDAK di sini: sumbernya
/// metadata snapshot Firestore (`hasPendingWrites` via
/// `CloudFirstProgressRepository.watchPendingIds`) yang durable lintas
/// force-stop karena persistence SDK.
///
/// Batas jujur: pelacak ini in-memory per sesi app. Reject yang diputuskan
/// server saat proses app sudah mati tidak bisa direkonstruksi SDK saat app
/// hidup kembali (mutation sudah dibuang dari antrean) — rekonsiliasi
/// semacam itu belum ada (kandidat tahap berikutnya).
class ProgressSyncFailures {
  static const int _maxMessageLength = 160;

  final Map<String, ProgressSyncFailure> _byEntry =
      <String, ProgressSyncFailure>{};

  final Map<String, ProgressSyncFailure> _byActivity =
      <String, ProgressSyncFailure>{};

  final StreamController<ProgressSyncFailure> _events =
      StreamController<ProgressSyncFailure>.broadcast();

  /// Status gagal terakhir per entry id (badge per-entry progress).
  final ValueNotifier<Map<String, ProgressSyncFailure>> byEntry =
      ValueNotifier<Map<String, ProgressSyncFailure>>(
    const <String, ProgressSyncFailure>{},
  );

  /// Status gagal terakhir per activity id untuk `deleteByActivity`
  /// (badge activity-scoped; tetap terlihat setelah baris entri terhapus).
  final ValueNotifier<Map<String, ProgressSyncFailure>> byActivity =
      ValueNotifier<Map<String, ProgressSyncFailure>>(
    const <String, ProgressSyncFailure>{},
  );

  /// Event kegagalan (untuk snackbar / notifikasi UI).
  Stream<ProgressSyncFailure> get events => _events.stream;

  ProgressSyncFailure _failure({
    required String id,
    required ProgressSyncOperation operation,
    required Object error,
  }) {
    final String raw = error.toString();
    return ProgressSyncFailure(
      id: id,
      operation: operation,
      message: raw.length <= _maxMessageLength
          ? raw
          : '${raw.substring(0, _maxMessageLength)}…',
      at: DateTime.now(),
    );
  }

  void _emit(ProgressSyncFailure failure) {
    if (!_events.isClosed) {
      _events.add(failure);
    }
  }

  void record({
    required String entryId,
    required ProgressSyncOperation operation,
    required Object error,
  }) {
    final ProgressSyncFailure failure = _failure(
      id: entryId,
      operation: operation,
      error: error,
    );
    _byEntry[entryId] = failure;
    byEntry.value = Map<String, ProgressSyncFailure>.unmodifiable(_byEntry);
    _emit(failure);
  }

  /// Catat kegagalan `deleteByActivity` per activity (badge yang tetap
  /// terlihat walau baris progress lokal sudah terhapus). Dipisah dari
  /// [byEntry] supaya id entri dan id aktivitas tidak pernah bertukar
  /// tampilan.
  void recordActivity({
    required String activityId,
    required ProgressSyncOperation operation,
    required Object error,
  }) {
    final ProgressSyncFailure failure = _failure(
      id: activityId,
      operation: operation,
      error: error,
    );
    _byActivity[activityId] = failure;
    byActivity.value =
        Map<String, ProgressSyncFailure>.unmodifiable(_byActivity);
    _emit(failure);
  }

  /// Hapus status gagal setelah ack sukses berikutnya untuk entry yang
  /// sama (menyimpan ulang = mengirim ulang = sembuh).
  void clear(String entryId) {
    if (_byEntry.remove(entryId) != null) {
      byEntry.value = Map<String, ProgressSyncFailure>.unmodifiable(_byEntry);
    }
  }

  /// Hapus status gagal setelah ack sukses berikutnya untuk activity yang
  /// sama (delete ulang = retry = sembuh).
  void clearActivity(String activityId) {
    if (_byActivity.remove(activityId) != null) {
      byActivity.value =
          Map<String, ProgressSyncFailure>.unmodifiable(_byActivity);
    }
  }

  void dispose() {
    _events.close();
    byEntry.dispose();
    byActivity.dispose();
  }
}
