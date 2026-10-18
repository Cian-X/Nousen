import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/progress/data/dual_write_progress_repository.dart';

/// Ikon kecil yang menampilkan status sync cloud terakhir.
///
/// - [CloudWriteStatus.synced] → awan centang hijau
/// - [CloudWriteStatus.failed] → awan silang merah (tooltip pesan error)
/// - [CloudWriteStatus.skippedOffline] → awan abu (offline/belum login)
class CloudSyncIndicator extends ConsumerWidget {
  const CloudSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flag cloud-first progress ON (S2) → status ditampilkan per-entry
    // (ProgressSyncBadge); indikator global last-write dual-write disembunyikan.
    final Object repo = ref.watch(progressRepositoryProvider);
    if (repo is! DualWriteProgressRepository) {
      return const SizedBox.shrink();
    }
    final notifier = ref.watch(cloudSyncStateProvider);
    return ValueListenableBuilder<CloudSyncState>(
      valueListenable: notifier,
      builder: (context, state, _) {
        final IconData icon;
        final Color color;
        final String tooltip;

        switch (state.status) {
          case CloudWriteStatus.synced:
            icon = Icons.cloud_done_outlined;
            color = Colors.green;
            tooltip = 'Synced';
          case CloudWriteStatus.failed:
            icon = Icons.cloud_off_outlined;
            color = Colors.redAccent;
            tooltip = state.message ?? 'Sync failed';
          case CloudWriteStatus.skippedOffline:
            icon = Icons.cloud_outlined;
            color = Colors.grey;
            tooltip = 'Offline';
        }

        return Tooltip(
          message: tooltip,
          child: Icon(icon, size: 20, color: color),
        );
      },
    );
  }
}
