import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/presentation/progress_sync_messages.dart';

/// Badge status tulis cloud per-entry progress (S2):
/// - `failed`  → awan silang merah (tooltip pesan server, non-silent);
/// - `pending` → awan panah amber (menunggu ack server / offline);
/// - `synced`  → tidak ada ikon (status normal).
///
/// `pending` berasal dari metadata snapshot Firestore (`hasPendingWrites`),
/// `failed` dari `ProgressSyncFailures`. [entryId] null (mis. belum ada
/// entri hari ini) dan flag OFF → tidak ada ikon.
class ProgressSyncBadge extends ConsumerWidget {
  const ProgressSyncBadge({super.key, this.entryId});

  final String? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = entryId;
    if (id == null) {
      return const SizedBox.shrink();
    }
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Set<String> pendingIds =
        ref.watch(progressPendingIdsProvider).value ?? const <String>{};
    final ValueNotifier<Map<String, ProgressSyncFailure>> failures = ref
        .watch(progressSyncFailuresProvider)
        .byEntry;

    return ValueListenableBuilder<Map<String, ProgressSyncFailure>>(
      valueListenable: failures,
      builder:
          (
            BuildContext context,
            Map<String, ProgressSyncFailure> value,
            Widget? child,
          ) {
            final ProgressSyncFailure? failure = value[id];
            if (failure != null) {
              return Tooltip(
                message: progressSyncFailureTooltip(
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
            if (pendingIds.contains(id)) {
              return Tooltip(
                message: progressSyncPendingTooltip(isId: isId),
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

/// Badge status kegagalan HAPUS progres per-activity (S2).
///
/// `deleteByActivity` yang di-reject server (rules/auth/error) dicatat
/// activity-scoped di `ProgressSyncFailures.byActivity`; badge ini tetap
/// terlihat walau baris progress lokal sudah terhapus — dipasang di kartu
/// aktivitas (home) dan header detail. Status lain (pending/synced) tidak
/// ditampilkan di sini; kegagalan dihapus saat retry delete berikutnya
/// sukses (map dikosongkan → badge hilang).
class ProgressDeleteBadge extends ConsumerWidget {
  const ProgressDeleteBadge({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final ValueNotifier<Map<String, ProgressSyncFailure>> failures = ref
        .watch(progressSyncFailuresProvider)
        .byActivity;

    return ValueListenableBuilder<Map<String, ProgressSyncFailure>>(
      valueListenable: failures,
      builder:
          (
            BuildContext context,
            Map<String, ProgressSyncFailure> value,
            Widget? child,
          ) {
            final ProgressSyncFailure? failure = value[activityId];
            if (failure == null) {
              return const SizedBox.shrink();
            }
            return Tooltip(
              message: progressSyncFailureTooltip(
                isId: isId,
                reason: failure.message,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 16,
                color: Colors.redAccent,
              ),
            );
          },
    );
  }
}
