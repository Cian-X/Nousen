import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/settings/data/settings_sync_failures.dart';
import 'package:nousen/features/settings/presentation/settings_sync_messages.dart';

/// Badge status tulis cloud settings (S3):
/// - `failed`  → awan silang merah (tooltip pesan server, non-silent);
/// - `pending` → awan panah amber (belum di-ACK server lebih dari
///   [pendingBadgeGrace]);
/// - `synced`  → tidak ada ikon.
///
/// `pending` dari metadata snapshot Firestore (`hasPendingWrites`),
/// `failed` dari `SettingsSyncFailures.byApp`. Flag OFF → pending kosong.
class SettingsSyncBadge extends ConsumerWidget {
  const SettingsSyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Set<String> pendingIds =
        ref.watch(settingsPendingIdsProvider).value ?? const <String>{};
    final ValueNotifier<SettingsSyncFailure?> failures = ref
        .watch(settingsSyncFailuresProvider)
        .byApp;

    return ValueListenableBuilder<SettingsSyncFailure?>(
      valueListenable: failures,
      builder:
          (BuildContext context, SettingsSyncFailure? failure, Widget? child) {
            if (failure != null) {
              return Tooltip(
                message: settingsSyncFailureTooltip(
                  isId: isId,
                  reason: failure.message,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: Colors.redAccent,
                ),
              );
            }
            if (pendingIds.contains('app')) {
              return Tooltip(
                message: settingsSyncPendingTooltip(isId: isId),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 16,
                  color: Colors.amber,
                ),
              );
            }
            return const SizedBox.shrink();
          },
    );
  }
}
