import 'package:nousen/features/activity/data/activity_sync_failures.dart';

/// Teks UI status tulis activity cloud-first (S1b) — dipisah agar bisa
/// dites unit tanpa membangun widget.
String activitySyncPendingTooltip({required bool isId}) {
  return isId ? 'Menunggu sinkronisasi ke cloud' : 'Waiting to sync to cloud';
}

String activitySyncFailureTooltip({
  required bool isId,
  required String reason,
}) {
  return isId
      ? 'Gagal sinkron ke cloud: $reason'
      : 'Cloud sync failed: $reason';
}

/// Tooltip badge GABUNGAN kartu/header aktivitas (aktivitas + progres).
///
/// Domain disebut eksplisit ("aktivitas" / "progres") karena satu ikon
/// mewakili dua domain sekaligus — tooltip tidak boleh ambigu.
String activityCardSyncPendingTooltip({required bool isId}) {
  return isId
      ? 'Aktivitas menunggu sinkronisasi ke cloud'
      : 'Activity waiting to sync to cloud';
}

String activityCardSyncFailureTooltip({
  required bool isId,
  required String reason,
}) {
  return isId
      ? 'Gagal sinkron aktivitas ke cloud: $reason'
      : 'Activity cloud sync failed: $reason';
}

/// Pesan snackbar saat server menolak tulis activity (non-silent).
String activitySyncFailureSnackMessage({
  required bool isId,
  required ActivitySyncFailure failure,
}) {
  final String action = switch (failure.operation) {
    ActivitySyncOperation.save => isId ? 'simpan' : 'save',
    ActivitySyncOperation.delete => isId ? 'hapus' : 'delete',
  };
  return isId
      ? 'Gagal $action ke cloud: ${failure.message}'
      : 'Failed to $action to cloud: ${failure.message}';
}
