import 'dart:async';

import 'package:flutter/foundation.dart';

/// Jenis operasi tulis reminder/notes cloud-first (S3).
enum OneTimeReminderSyncOperation { save, delete }

/// Subjek kegagalan: reminder atau catatan agenda.
enum OneTimeReminderSyncTarget { reminder, note }

/// Satu kegagalan ack server (reject) untuk satu operasi reminder/note (S3).
class OneTimeReminderSyncFailure {
  const OneTimeReminderSyncFailure({
    required this.id,
    required this.target,
    required this.operation,
    required this.message,
    required this.at,
  });

  /// Id reminder untuk [OneTimeReminderSyncTarget.reminder]; id note untuk
  /// [OneTimeReminderSyncTarget.note].
  final String id;
  final OneTimeReminderSyncTarget target;
  final OneTimeReminderSyncOperation operation;

  /// Pesan error dari SDK (mis. `[cloud_firestore/permission-denied] ...`).
  final String message;

  final DateTime at;
}

/// Pelacak kegagalan tulis cloud-first reminder + agenda notes (S3).
///
/// Dua cakupan dipisah map-nya supaya id reminder dan id note tidak pernah
/// bertukar badge:
/// - [byReminder]: reject `upsert`/`delete` reminder;
/// - [byNote]: reject `upsertNote`/`deleteNote`.
///
/// Yang dilacak HANYA reject/gagal dari server saat ack (rules, auth, error
/// lain) — ini yang membuat kegagalan tulis TIDAK senyap. Status `pending`
/// (local queue / offline) TIDAK di sini: sumbernya metadata snapshot
/// Firestore (`hasPendingWrites` via
/// `CloudFirstOneTimeReminderRepository.watchReminderPendingIds` /
/// `watchNotePendingIds`) yang durable lintas force-stop karena persistence
/// SDK.
///
/// Batas jujur: pelacak ini in-memory per sesi app (sama dengan S1b/S2).
class OneTimeReminderSyncFailures {
  static const int _maxMessageLength = 160;

  final Map<String, OneTimeReminderSyncFailure> _byReminder =
      <String, OneTimeReminderSyncFailure>{};

  final Map<String, OneTimeReminderSyncFailure> _byNote =
      <String, OneTimeReminderSyncFailure>{};

  final StreamController<OneTimeReminderSyncFailure> _events =
      StreamController<OneTimeReminderSyncFailure>.broadcast();

  /// Status gagal terakhir per reminder id (badge kartu agenda).
  final ValueNotifier<Map<String, OneTimeReminderSyncFailure>> byReminder =
      ValueNotifier<Map<String, OneTimeReminderSyncFailure>>(
        const <String, OneTimeReminderSyncFailure>{},
      );

  /// Status gagal terakhir per note id (badge kartu catatan).
  final ValueNotifier<Map<String, OneTimeReminderSyncFailure>> byNote =
      ValueNotifier<Map<String, OneTimeReminderSyncFailure>>(
        const <String, OneTimeReminderSyncFailure>{},
      );

  /// Event kegagalan (untuk snackbar / notifikasi UI).
  Stream<OneTimeReminderSyncFailure> get events => _events.stream;

  OneTimeReminderSyncFailure _failure({
    required String id,
    required OneTimeReminderSyncTarget target,
    required OneTimeReminderSyncOperation operation,
    required Object error,
  }) {
    final String raw = error.toString();
    return OneTimeReminderSyncFailure(
      id: id,
      target: target,
      operation: operation,
      message: raw.length <= _maxMessageLength
          ? raw
          : '${raw.substring(0, _maxMessageLength)}…',
      at: DateTime.now(),
    );
  }

  void _emit(OneTimeReminderSyncFailure failure) {
    if (!_events.isClosed) {
      _events.add(failure);
    }
  }

  /// Catat reject server untuk reminder.
  void recordReminder({
    required String reminderId,
    required OneTimeReminderSyncOperation operation,
    required Object error,
  }) {
    final OneTimeReminderSyncFailure failure = _failure(
      id: reminderId,
      target: OneTimeReminderSyncTarget.reminder,
      operation: operation,
      error: error,
    );
    _byReminder[reminderId] = failure;
    byReminder.value = Map<String, OneTimeReminderSyncFailure>.unmodifiable(
      _byReminder,
    );
    _emit(failure);
  }

  /// Catat reject server untuk catatan agenda.
  void recordNote({
    required String noteId,
    required OneTimeReminderSyncOperation operation,
    required Object error,
  }) {
    final OneTimeReminderSyncFailure failure = _failure(
      id: noteId,
      target: OneTimeReminderSyncTarget.note,
      operation: operation,
      error: error,
    );
    _byNote[noteId] = failure;
    byNote.value = Map<String, OneTimeReminderSyncFailure>.unmodifiable(
      _byNote,
    );
    _emit(failure);
  }

  /// Hapus status gagal reminder setelah ack sukses berikutnya.
  void clearReminder(String reminderId) {
    if (_byReminder.remove(reminderId) != null) {
      byReminder.value = Map<String, OneTimeReminderSyncFailure>.unmodifiable(
        _byReminder,
      );
    }
  }

  /// Hapus status gagal note setelah ack sukses berikutnya.
  void clearNote(String noteId) {
    if (_byNote.remove(noteId) != null) {
      byNote.value = Map<String, OneTimeReminderSyncFailure>.unmodifiable(
        _byNote,
      );
    }
  }

  void dispose() {
    _events.close();
    byReminder.dispose();
    byNote.dispose();
  }
}
