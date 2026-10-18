import 'package:nousen/features/progress/data/progress_sync_failures.dart';

/// Teks UI status tulis progress cloud-first (S2) — dipisah agar bisa
/// dites unit tanpa membangun widget.
String progressSyncPendingTooltip({required bool isId}) {
  return isId
      ? 'Menunggu sinkronisasi progres ke cloud'
      : 'Waiting to sync progress to cloud';
}

String progressSyncFailureTooltip({
  required bool isId,
  required String reason,
}) {
  return isId
      ? 'Gagal sinkron progres ke cloud: $reason'
      : 'Cloud progress sync failed: $reason';
}

/// Pesan snackbar saat server menolak tulis progress (non-silent).
String progressSyncFailureSnackMessage({
  required bool isId,
  required ProgressSyncFailure failure,
}) {
  final String action = switch (failure.operation) {
    ProgressSyncOperation.save => isId ? 'simpan' : 'save',
    ProgressSyncOperation.delete => isId ? 'hapus' : 'delete',
  };
  return isId
      ? 'Gagal $action progres ke cloud: ${failure.message}'
      : 'Failed to $action progress to cloud: ${failure.message}';
}
