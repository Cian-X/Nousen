import 'package:nousen/features/settings/data/settings_sync_failures.dart';

/// Teks UI status tulis settings cloud-first (S3).
String settingsSyncPendingTooltip({required bool isId}) {
  return isId
      ? 'Menunggu sinkronisasi pengaturan ke cloud'
      : 'Waiting to sync settings to cloud';
}

String settingsSyncFailureTooltip({
  required bool isId,
  required String reason,
}) {
  return isId
      ? 'Gagal sinkron pengaturan ke cloud: $reason'
      : 'Cloud settings sync failed: $reason';
}

/// Pesan snackbar saat server menolak tulis settings (non-silent).
String settingsSyncFailureSnackMessage({
  required bool isId,
  required SettingsSyncFailure failure,
}) {
  final String action = switch (failure.operation) {
    SettingsSyncOperation.save => isId ? 'simpan' : 'save',
  };
  return isId
      ? 'Gagal $action pengaturan ke cloud: ${failure.message}'
      : 'Failed to $action settings to cloud: ${failure.message}';
}
