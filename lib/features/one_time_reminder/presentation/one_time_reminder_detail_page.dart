import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/core/widgets/activity_sticker_badge.dart';
import 'package:liburan_create/core/widgets/cartoon_appbar_action_button.dart';
import 'package:liburan_create/core/widgets/checklist_confirm_dialog.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/l10n/app_localizations.dart';

class OneTimeReminderDetailPage extends ConsumerWidget {
  const OneTimeReminderDetailPage({super.key, required this.args});

  final OneTimeReminderDetailArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final List<OneTimeReminderModel> reminders =
        ref.watch(oneTimeRemindersStreamProvider).value ??
        const <OneTimeReminderModel>[];
    final OneTimeReminderModel? reminder = _findById(
      reminders,
      args.reminderId,
    );

    if (reminder == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.oneTimeReminderDetail)),
        body: Center(child: Text(t.oneTimeReminderNotFound)),
      );
    }

    final bool isPast = reminder.scheduledAt.isBefore(DateTime.now());
    final bool isDone = reminder.isCompleted;
    final bool isMissed = isPast && !isDone;
    final ThemeData theme = Theme.of(context);
    final HabitBrandPalette semantic = theme.habitColors;
    final Color accent = isDone
        ? semantic.completed
        : (isMissed ? semantic.missed : semantic.pending);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.oneTimeReminderDetail),
        actions: <Widget>[
          CartoonAppBarActionButton(
            tooltip: t.deleteOneTimeReminder,
            icon: Icons.delete_sweep_rounded,
            accent: theme.colorScheme.error,
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(t.deleteOneTimeReminder),
                    content: Text(
                      t.deleteOneTimeReminderConfirm(reminder.title),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(t.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(t.delete),
                      ),
                    ],
                  );
                },
              );
              if (confirm != true) {
                return;
              }

              await ref
                  .read(oneTimeReminderActionsProvider)
                  .deleteReminder(reminder);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          final bool isLarge = constraints.maxWidth >= 1100;
          final double sidePadding = isWide ? 24 : 16;
          final double maxWidth = isLarge ? 860 : 680;
          final double contentWidth = constraints.maxWidth < maxWidth
              ? constraints.maxWidth
              : maxWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  AppSpacing.screenPadding,
                  sidePadding,
                  AppSpacing.screenPadding,
                ),
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.24),
                        width: 1.0,
                      ),
                      boxShadow: AppShadows.soft(accent),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              ActivityStickerBadge(
                                iconKey: reminder.iconKey,
                                size: 34,
                                accent: accent,
                                selected: true,
                              ),
                              const SizedBox(width: AppSpacing.minorGap),
                              Expanded(
                                child: Text(
                                  reminder.title,
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.minorGap),
                          Text(
                            DateFormat(
                              'EEEE, d MMM yyyy - HH:mm',
                              localeCode,
                            ).format(reminder.scheduledAt),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.componentGap),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _StatusPill(
                                text: isDone
                                    ? t.oneTimeStatusDone
                                    : t.oneTimeStatusPending,
                                color: isDone
                                    ? theme.colorScheme.tertiaryContainer
                                    : theme.colorScheme.secondaryContainer,
                              ),
                              if (isMissed)
                                _StatusPill(
                                  text: t.oneTimeStatusMissed,
                                  color: theme.colorScheme.errorContainer,
                                ),
                              _StatusPill(
                                text: reminder.isNotificationEnabled
                                    ? t.statusOn
                                    : t.statusOff,
                                color: semantic.inactive.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        children: <Widget>[
                          _InfoRow(
                            label: t.oneTimeDateLabel,
                            value: DateFormat(
                              'EEEE, d MMM yyyy',
                              localeCode,
                            ).format(reminder.scheduledAt),
                          ),
                          const SizedBox(height: AppSpacing.componentGap),
                          _InfoRow(
                            label: t.oneTimeTimeLabel,
                            value: DateFormat(
                              'HH:mm',
                              localeCode,
                            ).format(reminder.scheduledAt),
                          ),
                          const SizedBox(height: AppSpacing.componentGap),
                          _InfoRow(
                            label: t.preReminderLabel,
                            value: reminder.preReminderMinutes == 0
                                ? t.preReminderOff
                                : t.preReminderMinutesValue(
                                    reminder.preReminderMinutes,
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.componentGap),
                          _InfoRow(
                            label: t.enableNotifications,
                            value: reminder.isNotificationEnabled
                                ? t.statusOn
                                : t.statusOff,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: reminder.isCompleted,
                      onChanged: (bool? checked) async {
                        final bool confirmed = await showChecklistConfirmDialog(
                          context: context,
                          title: t.checklistConfirmTitle,
                          message: t.checklistConfirmMessage,
                          cancelLabel: t.cancel,
                          confirmLabel: t.checklistConfirmAction,
                        );
                        if (!confirmed) {
                          return;
                        }
                        await ref
                            .read(oneTimeReminderActionsProvider)
                            .toggleCompletion(
                              reminder: reminder,
                              completed: checked ?? false,
                            );
                      },
                      title: Text(t.oneTimeMarkDone),
                      subtitle: Text(
                        reminder.isCompleted
                            ? t.oneTimeDoneSubtitle
                            : t.oneTimePendingSubtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  OneTimeReminderModel? _findById(
    List<OneTimeReminderModel> reminders,
    String id,
  ) {
    for (final OneTimeReminderModel reminder in reminders) {
      if (reminder.id == id) {
        return reminder;
      }
    }
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
