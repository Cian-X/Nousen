import 'package:nousen/features/one_time_reminder/data/one_time_reminder_sync_failures.dart';

/// Teks UI status tulis reminder/note cloud-first (S3) — dipisah agar bisa
/// dites unit tanpa membangun widget.
String oneTimeReminderSyncPendingTooltip({
  required bool isId,
  required OneTimeReminderSyncTarget target,
}) {
  final bool note = target == OneTimeReminderSyncTarget.note;
  if (isId) {
    return note
        ? 'Menunggu sinkronisasi catatan ke cloud'
        : 'Menunggu sinkronisasi agenda ke cloud';
  }
  return note
      ? 'Waiting to sync note to cloud'
      : 'Waiting to sync agenda to cloud';
}

String oneTimeReminderSyncFailureTooltip({
  required bool isId,
  required OneTimeReminderSyncTarget target,
  required String reason,
}) {
  final bool note = target == OneTimeReminderSyncTarget.note;
  if (isId) {
    return note
        ? 'Gagal sinkron catatan ke cloud: $reason'
        : 'Gagal sinkron agenda ke cloud: $reason';
  }
  return note
      ? 'Cloud note sync failed: $reason'
      : 'Cloud agenda sync failed: $reason';
}

/// Pesan snackbar saat server menolak tulis reminder/note (non-silent).
String oneTimeReminderSyncFailureSnackMessage({
  required bool isId,
  required OneTimeReminderSyncFailure failure,
}) {
  final bool note = failure.target == OneTimeReminderSyncTarget.note;
  final String action = switch (failure.operation) {
    OneTimeReminderSyncOperation.save => isId ? 'simpan' : 'save',
    OneTimeReminderSyncOperation.delete => isId ? 'hapus' : 'delete',
  };
  if (isId) {
    return note
        ? 'Gagal $action catatan ke cloud: ${failure.message}'
        : 'Gagal $action agenda ke cloud: ${failure.message}';
  }
  return note
      ? 'Failed to $action note to cloud: ${failure.message}'
      : 'Failed to $action agenda to cloud: ${failure.message}';
}
