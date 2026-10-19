import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_sync_failures.dart';
import 'package:nousen/features/one_time_reminder/presentation/one_time_reminder_sync_messages.dart';

/// Badge status tulis cloud per-reminder (S3):
/// - `failed`  → awan silang merah (tooltip pesan server, non-silent);
/// - `pending` → awan panah amber (belum di-ACK server lebih dari
///   [pendingBadgeGrace]; ACK cepat tidak sempat tampil);
/// - `synced`  → tidak ada ikon.
///
/// `pending` berasal dari metadata snapshot Firestore (`hasPendingWrites`),
/// `failed` dari `OneTimeReminderSyncFailures.byReminder`. Flag OFF →
/// pending kosong.
class ReminderSyncBadge extends ConsumerWidget {
  const ReminderSyncBadge({super.key, required this.reminderId});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Set<String> pendingIds =
        ref.watch(reminderPendingIdsProvider).value ?? const <String>{};
    final ValueNotifier<Map<String, OneTimeReminderSyncFailure>> failures = ref
        .watch(oneTimeReminderSyncFailuresProvider)
        .byReminder;

    return ValueListenableBuilder<Map<String, OneTimeReminderSyncFailure>>(
      valueListenable: failures,
      builder:
          (
            BuildContext context,
            Map<String, OneTimeReminderSyncFailure> value,
            Widget? child,
          ) {
            final OneTimeReminderSyncFailure? failure = value[reminderId];
            if (failure != null) {
              return Tooltip(
                message: oneTimeReminderSyncFailureTooltip(
                  isId: isId,
                  target: OneTimeReminderSyncTarget.reminder,
                  reason: failure.message,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: Colors.redAccent,
                ),
              );
            }
            if (pendingIds.contains(reminderId)) {
              return Tooltip(
                message: oneTimeReminderSyncPendingTooltip(
                  isId: isId,
                  target: OneTimeReminderSyncTarget.reminder,
                ),
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

/// Badge status tulis cloud per-catatan agenda (S3) — pola sama dengan
/// [ReminderSyncBadge], memakai `byNote`/`notePendingIdsProvider`.
class AgendaNoteSyncBadge extends ConsumerWidget {
  const AgendaNoteSyncBadge({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Set<String> pendingIds =
        ref.watch(notePendingIdsProvider).value ?? const <String>{};
    final ValueNotifier<Map<String, OneTimeReminderSyncFailure>> failures = ref
        .watch(oneTimeReminderSyncFailuresProvider)
        .byNote;

    return ValueListenableBuilder<Map<String, OneTimeReminderSyncFailure>>(
      valueListenable: failures,
      builder:
          (
            BuildContext context,
            Map<String, OneTimeReminderSyncFailure> value,
            Widget? child,
          ) {
            final OneTimeReminderSyncFailure? failure = value[noteId];
            if (failure != null) {
              return Tooltip(
                message: oneTimeReminderSyncFailureTooltip(
                  isId: isId,
                  target: OneTimeReminderSyncTarget.note,
                  reason: failure.message,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: Colors.redAccent,
                ),
              );
            }
            if (pendingIds.contains(noteId)) {
              return Tooltip(
                message: oneTimeReminderSyncPendingTooltip(
                  isId: isId,
                  target: OneTimeReminderSyncTarget.note,
                ),
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
