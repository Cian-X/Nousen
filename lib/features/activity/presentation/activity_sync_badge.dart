import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/presentation/activity_sync_messages.dart';

/// Badge status tulis cloud per-activity (S1b):
/// - `failed`  → awan silang merah (tooltip pesan server, non-silent);
/// - `pending` → awan panah amber (menunggu ack server / offline);
/// - `synced`  → tidak ada ikon (status normal).
///
/// `pending` berasal dari metadata snapshot Firestore (`hasPendingWrites`),
/// `failed` dari `ActivitySyncFailures`. Flag OFF → pending kosong.
class ActivitySyncBadge extends ConsumerWidget {
  const ActivitySyncBadge({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Set<String> pendingIds =
        ref.watch(activityPendingIdsProvider).value ?? const <String>{};
    final ValueNotifier<Map<String, ActivitySyncFailure>> failures = ref
        .watch(activitySyncFailuresProvider)
        .byActivity;

    return ValueListenableBuilder<Map<String, ActivitySyncFailure>>(
      valueListenable: failures,
      builder:
          (
            BuildContext context,
            Map<String, ActivitySyncFailure> value,
            Widget? child,
          ) {
            final ActivitySyncFailure? failure = value[activityId];
            if (failure != null) {
              return Tooltip(
                message: activitySyncFailureTooltip(
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
            if (pendingIds.contains(activityId)) {
              return Tooltip(
                message: activitySyncPendingTooltip(isId: isId),
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
