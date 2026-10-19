import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/presentation/activity_sync_messages.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/presentation/progress_sync_messages.dart';

/// Badge status tulis cloud GABUNGAN per kartu/header aktivitas (S1b + S2).
///
/// Menggantikan baris `ActivitySyncBadge` + `ProgressSyncBadge` +
/// `ProgressDeleteBadge` yang tampil berdampingan: dua ikon amber dari dua
/// domain berbeda terlihat seperti badge duplikat di device (temuan uji
/// 2026-10-19). Satu ikon per kartu:
/// - `failed`  → awan silang merah, PRIORITAS tertinggi — mencakup tulis
///   aktivitas, tulis entri progres, dan pembersihan progres per-aktivitas
///   (`deleteByActivity`);
/// - `pending` → awan panah amber (tulisan belum di-ACK server lebih dari
///   [pendingBadgeGrace]);
/// - `synced`  → tidak ada ikon.
///
/// Tooltip menyebut domain tiap baris (aktivitas / progres) supaya satu ikon
/// tetap informatif; beberapa masalah digabung sebagai baris terpisah.
class ActivityCardSyncBadge extends ConsumerWidget {
  const ActivityCardSyncBadge({
    super.key,
    required this.activityId,
    this.entryId,
  });

  /// Activity id — sumber status tulis aktivitas sekaligus kegagalan
  /// pembersihan progres per-aktivitas.
  final String activityId;

  /// Id entri progres (mis. entri hari ini). Null = belum ada entri:
  /// status pending/gagal per-entri dilewati.
  final String? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Set<String> activityPending =
        ref.watch(activityPendingIdsProvider).value ?? const <String>{};
    final Set<String> progressPending =
        ref.watch(progressPendingIdsProvider).value ?? const <String>{};
    final ValueNotifier<Map<String, ActivitySyncFailure>> activityFailures =
        ref.watch(activitySyncFailuresProvider).byActivity;
    final ValueNotifier<Map<String, ProgressSyncFailure>>
        progressEntryFailures = ref.watch(progressSyncFailuresProvider).byEntry;
    final ValueNotifier<Map<String, ProgressSyncFailure>>
        progressDeleteFailures =
        ref.watch(progressSyncFailuresProvider).byActivity;

    return ValueListenableBuilder<Map<String, ActivitySyncFailure>>(
      valueListenable: activityFailures,
      builder: (
        BuildContext context,
        Map<String, ActivitySyncFailure> activityFailuresById,
        Widget? child,
      ) {
        return ValueListenableBuilder<Map<String, ProgressSyncFailure>>(
          valueListenable: progressEntryFailures,
          builder: (
            BuildContext context,
            Map<String, ProgressSyncFailure> entryFailuresById,
            Widget? child,
          ) {
            return ValueListenableBuilder<Map<String, ProgressSyncFailure>>(
              valueListenable: progressDeleteFailures,
              builder: (
                BuildContext context,
                Map<String, ProgressSyncFailure> deleteFailuresByActivity,
                Widget? child,
              ) {
                final ActivitySyncFailure? activityFailure =
                    activityFailuresById[activityId];
                final String? id = entryId;
                final ProgressSyncFailure? entryFailure =
                    id == null ? null : entryFailuresById[id];
                final ProgressSyncFailure? deleteFailure =
                    deleteFailuresByActivity[activityId];

                final List<String> failureMessages = <String>[
                  if (activityFailure != null)
                    activityCardSyncFailureTooltip(
                      isId: isId,
                      reason: activityFailure.message,
                    ),
                  if (entryFailure != null)
                    progressSyncFailureTooltip(
                      isId: isId,
                      reason: entryFailure.message,
                    ),
                  if (deleteFailure != null)
                    progressSyncFailureTooltip(
                      isId: isId,
                      reason: deleteFailure.message,
                    ),
                ];
                if (failureMessages.isNotEmpty) {
                  return Tooltip(
                    message: failureMessages.join('\n'),
                    child: const Icon(
                      Icons.cloud_off_outlined,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                  );
                }

                final List<String> pendingMessages = <String>[
                  if (activityPending.contains(activityId))
                    activityCardSyncPendingTooltip(isId: isId),
                  if (id != null && progressPending.contains(id))
                    progressSyncPendingTooltip(isId: isId),
                ];
                if (pendingMessages.isNotEmpty) {
                  return Tooltip(
                    message: pendingMessages.join('\n'),
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
          },
        );
      },
    );
  }
}
