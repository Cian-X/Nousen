import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/core/widgets/optimized_file_image.dart';
import 'package:liburan_create/core/widgets/weekly_progress_widget.dart';
import 'package:liburan_create/features/activity/domain/activity_daily_progress_status.dart';
import 'package:liburan_create/features/activity/domain/activity_progress_summary.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/activity/application/activity_detail_ml_service.dart';
import 'package:liburan_create/features/activity/presentation/activity_status_visuals.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/l10n/app_localizations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:liburan_create/services/photo_access_service.dart';

void _disposeTextControllerSafely(TextEditingController controller) {
  // Delay disposal until the sheet close + keyboard detach sequence settles.
  Future<void>.delayed(const Duration(milliseconds: 1200), () {
    try {
      controller.dispose();
    } catch (_) {
      // Controller may already be detached/disposed by framework teardown.
    }
  });
}

class ActivityDetailPage extends ConsumerWidget {
  const ActivityDetailPage({super.key, required this.args});

  final ActivityDetailArgs args;

  static const String _menuEditActivity = 'edit_activity';
  static const String _menuSkipActivity = 'skip_activity';
  static const String _menuDeleteActivity = 'delete_activity';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final List<ActivityModel> activities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final ActivityModel? activity = _findActivity(activities, args.activityId);

    if (activity == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.activityDetail)),
        body: Center(child: Text(t.activityNotFound)),
      );
    }

    final List<ProgressEntryModel> entries =
        ref.watch(progressByActivityProvider(activity.id)).value ??
        const <ProgressEntryModel>[];
    final GlobalStats stats = ref.watch(globalStatsProvider);
    ActivityBreakdown? breakdown;
    for (final ActivityBreakdown item in stats.breakdowns) {
      if (item.activity.id == activity.id) {
        breakdown = item;
        break;
      }
    }
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final ThemeData theme = Theme.of(context);

    final DateTime today = dateOnly(DateTime.now());
    final String todayKey = dateKeyFromDate(today);
    ProgressEntryModel? todayEntry;
    for (final ProgressEntryModel item in entries) {
      if (item.dateKey == todayKey) {
        todayEntry = item;
        break;
      }
    }
    final ActivityProgressSummary todayProgress =
        resolveActivityProgressSummary(
          subActivities: activity.subActivities,
          entry: todayEntry,
        );
    final int completedSubCount = todayProgress.completedSubCount;
    final int totalSubCount = todayProgress.totalSubCount;
    final bool hasSubActivities = totalSubCount > 0;
    final List<String> visibleSubActivities = activity.subActivities
        .take(8)
        .toList();
    final int hiddenSubActivitiesCount = math.max(
      0,
      totalSubCount - visibleSubActivities.length,
    );
    final String todayNote = (todayEntry?.notes ?? '').trim();
    final bool hasTodayNote = todayNote.isNotEmpty;
    final List<String> todayPhotoPaths = _normalizedPhotoPaths(todayEntry);
    final int todayPhotoCount = todayPhotoPaths.length;
    final bool hasTodayPhoto = todayPhotoCount > 0;
    final bool hasTodayUpdate = hasTodayNote || hasTodayPhoto;
    final DateTime scheduleUpdatedAt =
        activity.scheduleUpdatedAt ?? activity.createdAt;
    final List<_ScheduledDaySnapshot> weeklyScheduledDays =
        _buildWeeklyScheduledDaySnapshots(
          activity: activity,
          entries: entries,
          referenceDate: today,
        );
    final int scheduledDaysThisWeek = weeklyScheduledDays
        .where((item) => item.countsTowardWeeklyCompletion)
        .length;
    final int doneFullDaysCount = weeklyScheduledDays
        .where((item) => item.isCompleted)
        .length;
    final int currentStreak = breakdown?.currentStreak ?? 0;
    final ActivityDailyProgressStatus todayVisualStatus =
        resolveActivityDailyProgressStatus(
          scheduledDate: today,
          today: DateTime.now(),
          scheduleUpdatedAt: scheduleUpdatedAt,
          subActivities: activity.subActivities,
          scheduledTimeMinutes: activity.timeMinutes,
          entry: todayEntry,
        );
    final bool todayCompleted =
        todayVisualStatus == ActivityDailyProgressStatus.done;
    final bool todaySkipped =
        todayVisualStatus == ActivityDailyProgressStatus.skipped;
    final bool isScheduledToday = activity.selectedDays.contains(today.weekday);
    final DateTime headerScheduleDate = args.scheduledDate == null
        ? _resolveHeaderScheduleDate(activity: activity, today: today)
        : dateOnly(args.scheduledDate!);
    final String headerScheduleDateKey = dateKeyFromDate(headerScheduleDate);
    ProgressEntryModel? headerEntry;
    for (final ProgressEntryModel item in entries) {
      if (item.dateKey == headerScheduleDateKey) {
        headerEntry = item;
        break;
      }
    }
    final ActivityProgressSummary headerProgress =
        resolveActivityProgressSummary(
          subActivities: activity.subActivities,
          entry: headerEntry,
        );
    final ActivityDailyProgressStatus headerVisualStatus =
        resolveActivityDailyProgressStatus(
          scheduledDate: headerScheduleDate,
          today: DateTime.now(),
          scheduleUpdatedAt: scheduleUpdatedAt,
          subActivities: activity.subActivities,
          scheduledTimeMinutes: activity.timeMinutes,
          entry: headerEntry,
        );
    final String headerScheduleText =
        '${weekdayShortLabel(headerScheduleDate.weekday, localeCode)}, ${formatDateShort(headerScheduleDate, localeCode)} • ${formatMinutesAsTime(activity.timeMinutes)}';
    final String weeklyHelperText = scheduledDaysThisWeek == 0
        ? (localeCode == 'id'
              ? 'Belum ada progres terjadwal minggu ini'
              : 'No scheduled progress this week')
        : (localeCode == 'id'
              ? '$doneFullDaysCount dari $scheduledDaysThisWeek hari selesai minggu ini'
              : '$doneFullDaysCount / $scheduledDaysThisWeek days completed this week');
    final String hiddenSubActivitiesLabel = localeCode == 'id'
        ? '+$hiddenSubActivitiesCount lainnya'
        : '+$hiddenSubActivitiesCount more';
    final _ActivityAiInsightData aiInsight = _buildActivityAiInsightData(
      activity: activity,
      entries: entries,
      breakdown: breakdown,
      localeCode: localeCode,
      today: today,
      mlPrediction: ref
          .watch(activityDetailMlPredictionProvider(activity.id))
          .valueOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localeCode == 'id' ? 'Detail aktivitas' : 'Activity detail',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: localeCode == 'id' ? 'Opsi aktivitas' : 'Activity options',
            icon: Icon(
              Icons.more_horiz_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (String action) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) {
                  return;
                }
                if (action == _menuEditActivity) {
                  Navigator.of(context).pushNamed(
                    AppRoutes.createActivity,
                    arguments: CreateActivityArgs(activity: activity),
                  );
                  return;
                }
                if (action == _menuSkipActivity) {
                  await _addDailyLogUpdate(
                    context: context,
                    ref: ref,
                    t: t,
                    localeCode: localeCode,
                    activity: activity,
                    existingEntry: todayEntry,
                    saveAsSkipped: true,
                  );
                  return;
                }
                if (action != _menuDeleteActivity) {
                  return;
                }
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      content: Text(
                        localeCode == 'id'
                            ? 'Yakin ingin menghapus aktivitas ini?'
                            : 'Are you sure you want to delete this activity?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(t.cancel),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
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
                    .read(activityActionsProvider)
                    .deleteActivity(activity);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: _menuEditActivity,
                child: Text(t.editActivity),
              ),
              PopupMenuItem<String>(
                value: _menuSkipActivity,
                enabled: isScheduledToday && !todayCompleted && !todaySkipped,
                child: Text(
                  localeCode == 'id' ? 'Lewati aktivitas' : 'Skip activity',
                ),
              ),
              PopupMenuItem<String>(
                value: _menuDeleteActivity,
                child: Text(t.deleteActivity),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          final bool isLarge = constraints.maxWidth >= 1100;
          final double sidePadding = isWide ? 24 : 16;
          final double contentMaxWidth = isLarge ? 980 : 760;
          final double contentWidth = constraints.maxWidth < contentMaxWidth
              ? constraints.maxWidth
              : contentMaxWidth;

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
                  _ActivityHeroCard(
                    scheduleText: headerScheduleText,
                    summaryText: aiInsight.heroLine,
                     progressPercent: headerProgress.percent,
                     progressRate: headerProgress.rate,
                     currentStreak: currentStreak,
                     streakText: 'Streak ${t.daysCount(currentStreak)}',
                     progressState: headerProgress.state,
                     visualStatus: headerVisualStatus,
                     localeCode: localeCode,
                   ),
                  const SizedBox(height: 18),
                  _ActivityAiInsightSection(
                    data: aiInsight,
                    localeCode: localeCode,
                  ),
                  const SizedBox(height: 18),
                   Text(
                     activity.title,
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                     style: theme.textTheme.headlineMedium?.copyWith(
                       fontSize: 24,
                       fontWeight: FontWeight.w700,
                       letterSpacing: -0.02,
                       color: theme.colorScheme.onSurface,
                     ),
                   ),
                  const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: <Widget>[
                       Text(
                         localeCode == 'id' ? 'Progres mingguan' : 'Weekly progress',
                         style: theme.textTheme.titleMedium?.copyWith(
                           fontSize: 18,
                           fontWeight: FontWeight.w700,
                           color: theme.colorScheme.onSurface,
                         ),
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.primary.withValues(alpha: 0.05),
                           borderRadius: BorderRadius.circular(6),
                         ),
                         child: Text(
                           localeCode == 'id' ? 'Minggu ini' : 'This week',
                           style: theme.textTheme.labelMedium?.copyWith(
                             color: theme.colorScheme.primary,
                             fontWeight: FontWeight.w600,
                             fontSize: 12,
                           ),
                         ),
                       ),
                     ],
                   ),
                  const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(28),
                       border: Border.all(
                         color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                         width: 1,
                       ),
                       boxShadow: <BoxShadow>[
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.04),
                           blurRadius: 24,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                         _CustomWeeklyBarChart(
                           days: weeklyScheduledDays,
                           localeCode: localeCode,
                         ),
                         const SizedBox(height: 20),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: <Widget>[
                             Container(
                               width: 6,
                               height: 6,
                               decoration: const BoxDecoration(
                                 color: Color(0xFFB4262C),
                                 shape: BoxShape.circle,
                               ),
                             ),
                             const SizedBox(width: 8),
                             Text(
                               weeklyHelperText,
                               style: theme.textTheme.bodyMedium?.copyWith(
                                 color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                    ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.14),
                  ),
                  if (hasSubActivities) ...<Widget>[
                    const SizedBox(height: 18),
                    Text(
                      t.subActivitiesLabel,
                       style: theme.textTheme.titleMedium?.copyWith(
                         fontSize: 18,
                         fontWeight: FontWeight.w700,
                         color: theme.colorScheme.onSurface,
                       ),
                     ),
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.all(24),
                       width: double.infinity,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(28),
                         border: Border.all(
                           color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                           width: 1,
                         ),
                         boxShadow: <BoxShadow>[
                           BoxShadow(
                             color: Colors.black.withValues(alpha: 0.04),
                             blurRadius: 24,
                             offset: const Offset(0, 4),
                           ),
                         ],
                       ),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                           Text(
                             t.subActivitiesProgress(completedSubCount, totalSubCount),
                             style: theme.textTheme.bodyMedium?.copyWith(
                               color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                               fontWeight: FontWeight.w500,
                               fontSize: 14,
                             ),
                           ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ...visibleSubActivities.map(
                                  (String subActivity) =>
                                      _SubActivityChip(label: subActivity),
                                ),
                                if (hiddenSubActivitiesCount > 0)
                                  _SubActivityChip(
                                    label: hiddenSubActivitiesLabel,
                                    isSummary: true,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _ActivityComparisonPage(
                                activityId: activity.id,
                                activityTitle: activity.title,
                                localeCode: localeCode,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.timeline_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  t.comparisonTimelineTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        localeCode == 'id' ? 'Catatan harian' : 'Daily note',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!hasTodayUpdate) ...<Widget>[
                         Container(
                           padding: const EdgeInsets.all(24),
                           width: double.infinity,
                           decoration: BoxDecoration(
                             color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                             borderRadius: BorderRadius.circular(28),
                             border: Border.all(
                               color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                               width: 2,
                               style: BorderStyle.solid,
                             ),
                           ),
                           child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: <Widget>[
                               Container(
                                 width: 64,
                                 height: 64,
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   shape: BoxShape.circle,
                                   boxShadow: <BoxShadow>[
                                     BoxShadow(
                                       color: Colors.black.withValues(alpha: 0.04),
                                       blurRadius: 10,
                                       offset: const Offset(0, 4),
                                     ),
                                   ],
                                 ),
                                 alignment: Alignment.center,
                                 child: Icon(
                                   Icons.edit_note_rounded,
                                   size: 32,
                                   color: theme.colorScheme.outline,
                                 ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localeCode == 'id'
                                    ? 'Belum ada catatan hari ini'
                                    : 'No notes yet today',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                localeCode == 'id'
                                    ? 'Tambahkan catatan atau foto untuk dokumentasi progres aktivitasmu.'
                                    : 'Add notes or photos to document your progress.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 2,
                                    shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  ),
                                  onPressed: () async {
                                    await _addDailyLogUpdate(
                                      context: context,
                                      ref: ref,
                                      t: t,
                                      localeCode: localeCode,
                                      activity: activity,
                                      existingEntry: todayEntry,
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(
                                    localeCode == 'id' ? 'Tambah catatan' : 'Add note',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          activityStatusIcon(todayVisualStatus),
                                          size: 16,
                                          color: activityStatusColor(
                                            theme: theme,
                                            status: todayVisualStatus,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            formatDateLong(
                                              todayEntry == null
                                                  ? today
                                                  : dateFromKey(
                                                      todayEntry.dateKey,
                                                    ),
                                              localeCode,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.74),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: localeCode == 'id'
                                        ? 'Opsi log'
                                        : 'Log options',
                                    icon: Icon(
                                      Icons.more_horiz_rounded,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.74),
                                    ),
                                    onSelected: (String action) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) async {
                                            if (!context.mounted) {
                                              return;
                                            }
                                            if (action == 'edit') {
                                              await _addDailyLogUpdate(
                                                context: context,
                                                ref: ref,
                                                t: t,
                                                localeCode: localeCode,
                                                activity: activity,
                                                existingEntry: todayEntry,
                                              );
                                            } else if (action == 'deleteLog' &&
                                                todayEntry != null) {
                                              await _deleteTodayLogText(
                                                context: context,
                                                ref: ref,
                                                t: t,
                                                localeCode: localeCode,
                                                entry: todayEntry,
                                              );
                                            } else if (action ==
                                                    'deletePhoto' &&
                                                todayEntry != null) {
                                              await _deleteTodayLogPhotos(
                                                context: context,
                                                ref: ref,
                                                t: t,
                                                localeCode: localeCode,
                                                entry: todayEntry,
                                                photoPaths: todayPhotoPaths,
                                              );
                                            }
                                          });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text(
                                            localeCode == 'id'
                                                ? 'Edit'
                                                : 'Edit',
                                          ),
                                        ),
                                        if (todayEntry != null &&
                                            (((todayEntry.notes ?? '')
                                                    .trim()
                                                    .isNotEmpty) ||
                                                ((todayEntry.photoNote ?? '')
                                                    .trim()
                                                    .isNotEmpty)))
                                          PopupMenuItem<String>(
                                            value: 'deleteLog',
                                            child: Text(
                                              localeCode == 'id'
                                                  ? 'Hapus log'
                                                  : 'Delete log',
                                            ),
                                          ),
                                        if (todayEntry != null &&
                                            todayPhotoPaths.isNotEmpty)
                                          PopupMenuItem<String>(
                                            value: 'deletePhoto',
                                            child: Text(
                                              localeCode == 'id'
                                                  ? 'Hapus foto'
                                                  : 'Delete photo',
                                            ),
                                          ),
                                      ];
                                    },
                                  ),
                                ],
                              ),
                              if (hasTodayPhoto) ...<Widget>[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _PhotoGalleryViewerPage(
                                          paths: todayPhotoPaths,
                                          localeCode: localeCode,
                                          dateKey:
                                              todayEntry?.dateKey ?? todayKey,
                                          initialIndex: 0,
                                          compareCandidates:
                                              const <_GalleryPhotoCandidate>[],
                                        ),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: <Widget>[
                                        AspectRatio(
                                          aspectRatio: 16 / 10,
                                          child: OptimizedFileImage(
                                            path: todayPhotoPaths.first,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            logicalCacheWidth:
                                                MediaQuery.sizeOf(
                                                  context,
                                                ).width,
                                            logicalCacheHeight: 220,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image_rounded,
                                                  size: 22,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (todayPhotoCount > 1)
                                          Positioned(
                                            right: 10,
                                            bottom: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.52,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.pill,
                                                    ),
                                              ),
                                              child: Text(
                                                localeCode == 'id'
                                                    ? '$todayPhotoCount foto'
                                                    : '$todayPhotoCount photos',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (hasTodayNote) ...<Widget>[
                                SizedBox(height: hasTodayPhoto ? 14 : 10),
                                Text(
                                  todayNote,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.86),
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _ActivityComparisonPage(
                              activityId: activity.id,
                              activityTitle: activity.title,
                              localeCode: localeCode,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.timeline_rounded,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                t.comparisonTimelineTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        localeCode == 'id' ? 'Catatan harian' : 'Daily note',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!hasTodayUpdate) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  size: 32,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localeCode == 'id'
                                    ? 'Belum ada catatan hari ini'
                                    : 'No notes yet today',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                localeCode == 'id'
                                    ? 'Tambahkan catatan atau foto untuk dokumentasi progres aktivitasmu.'
                                    : 'Add notes or photos to document your progress.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    elevation: 2,
                                    shadowColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                  onPressed: () async {
                                    await _addDailyLogUpdate(
                                      context: context,
                                      ref: ref,
                                      t: t,
                                      localeCode: localeCode,
                                      activity: activity,
                                      existingEntry: todayEntry,
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(
                                    localeCode == 'id'
                                        ? 'Tambah catatan'
                                        : 'Add note',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          activityStatusIcon(todayVisualStatus),
                                          size: 16,
                                          color: activityStatusColor(
                                            theme: theme,
                                            status: todayVisualStatus,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            formatDateLong(
                                              todayEntry == null
                                                  ? today
                                                  : dateFromKey(
                                                      todayEntry.dateKey,
                                                    ),
                                              localeCode,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.74),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: localeCode == 'id'
                                        ? 'Opsi log'
                                        : 'Log options',
                                    icon: Icon(
                                      Icons.more_horiz_rounded,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.74),
                                    ),
                                    onSelected: (String action) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) async {
                                        if (!context.mounted) {
                                          return;
                                        }
                                        if (action == 'edit') {
                                          await _addDailyLogUpdate(
                                            context: context,
                                            ref: ref,
                                            t: t,
                                            localeCode: localeCode,
                                            activity: activity,
                                            existingEntry: todayEntry,
                                          );
                                        } else if (action == 'deleteLog' &&
                                            todayEntry != null) {
                                          await _deleteTodayLogText(
                                            context: context,
                                            ref: ref,
                                            t: t,
                                            localeCode: localeCode,
                                            entry: todayEntry,
                                          );
                                        } else if (action == 'deletePhoto' &&
                                            todayEntry != null) {
                                          await _deleteTodayLogPhotos(
                                            context: context,
                                            ref: ref,
                                            t: t,
                                            localeCode: localeCode,
                                            entry: todayEntry,
                                            photoPaths: todayPhotoPaths,
                                          );
                                        }
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text(
                                            localeCode == 'id' ? 'Edit' : 'Edit',
                                          ),
                                        ),
                                        if (todayEntry != null &&
                                            (((todayEntry.notes ?? '')
                                                        .trim()
                                                        .isNotEmpty) ||
                                                    ((todayEntry.photoNote ?? '')
                                                        .trim()
                                                        .isNotEmpty)))
                                          PopupMenuItem<String>(
                                            value: 'deleteLog',
                                            child: Text(
                                              localeCode == 'id'
                                                  ? 'Hapus log'
                                                  : 'Delete log',
                                            ),
                                          ),
                                        if (todayEntry != null &&
                                            todayPhotoPaths.isNotEmpty)
                                          PopupMenuItem<String>(
                                            value: 'deletePhoto',
                                            child: Text(
                                              localeCode == 'id'
                                                  ? 'Hapus foto'
                                                  : 'Delete photo',
                                            ),
                                          ),
                                      ];
                                    },
                                  ),
                                ],
                              ),
                              if (hasTodayPhoto) ...<Widget>[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _PhotoGalleryViewerPage(
                                          paths: todayPhotoPaths,
                                          localeCode: localeCode,
                                          dateKey:
                                              todayEntry?.dateKey ?? todayKey,
                                          initialIndex: 0,
                                          compareCandidates:
                                              const <_GalleryPhotoCandidate>[],
                                        ),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: <Widget>[
                                        AspectRatio(
                                          aspectRatio: 16 / 10,
                                          child: OptimizedFileImage(
                                            path: todayPhotoPaths.first,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            logicalCacheWidth:
                                                MediaQuery.sizeOf(
                                              context,
                                            ).width,
                                            logicalCacheHeight: 220,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: theme.colorScheme
                                                    .surfaceContainerHighest,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image_rounded,
                                                  size: 22,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (todayPhotoCount > 1)
                                          Positioned(
                                            right: 10,
                                            bottom: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.52,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppRadius.pill,
                                                ),
                                              ),
                                              child: Text(
                                                localeCode == 'id'
                                                    ? '$todayPhotoCount foto'
                                                    : '$todayPhotoCount photos',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (hasTodayNote) ...<Widget>[
                                SizedBox(height: hasTodayPhoto ? 14 : 10),
                                Text(
                                  todayNote,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.86),
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ActivityModel? _findActivity(List<ActivityModel> items, String id) {
    for (final ActivityModel item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  DateTime _resolveHeaderScheduleDate({
    required ActivityModel activity,
    required DateTime today,
  }) {
    final List<int> scheduledDays = activity.selectedDays.toSet().toList()
      ..sort();
    final DateTime currentWeekStart = dateOnly(
      today,
    ).subtract(Duration(days: today.weekday - 1));

    if (scheduledDays.isEmpty) {
      return dateOnly(today);
    }

    if (scheduledDays.contains(today.weekday)) {
      return dateOnly(today);
    }

    return currentWeekStart.add(Duration(days: scheduledDays.first - 1));
  }

  List<_ScheduledDaySnapshot> _buildWeeklyScheduledDaySnapshots({
    required ActivityModel activity,
    required List<ProgressEntryModel> entries,
    required DateTime referenceDate,
  }) {
    final List<int> scheduledWeekdays = activity.selectedDays.toSet().toList()
      ..sort();
    final DateTime endDate = dateOnly(referenceDate);
    final DateTime weekStart = endDate.subtract(
      Duration(days: endDate.weekday - 1),
    );
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final DateTime scheduleUpdatedAt =
        activity.scheduleUpdatedAt ?? activity.createdAt;
    final Map<String, ProgressEntryModel> entryByDateKey =
        <String, ProgressEntryModel>{
      for (final ProgressEntryModel entry in entries)
        if (!dateOnly(entry.date).isBefore(weekStart) &&
            !dateOnly(entry.date).isAfter(weekEnd))
          entry.dateKey: entry,
    };

    final List<_ScheduledDaySnapshot> snapshots = <_ScheduledDaySnapshot>[];
    for (int weekday = 1; weekday <= 7; weekday++) {
      final DateTime day = weekStart.add(Duration(days: weekday - 1));
      final bool isScheduledDay = scheduledWeekdays.contains(weekday);
      final ProgressEntryModel? entry = entryByDateKey[dateKeyFromDate(day)];
      final double progressRate = _resolveDailyProgressRate(
        entry: entry,
        subActivities: activity.subActivities,
      );
      final bool isActiveScheduledDay = isScheduledDay &&
          !dateOnly(day).isBefore(dateOnly(scheduleUpdatedAt));
      final WeeklyProgressDayVisualState visualState =
          _resolveWeeklySnapshotVisualState(
        isScheduledDay: isScheduledDay,
        day: day,
        today: endDate,
        scheduleUpdatedAt: scheduleUpdatedAt,
        entry: entry,
        progressRate: progressRate,
      );
      final bool countsTowardWeeklyCompletion = isActiveScheduledDay &&
          !dateOnly(day).isAfter(endDate) &&
          entry?.status != ActivityDayStatus.skipped;
      snapshots.add(
        _ScheduledDaySnapshot(
          date: day,
          isScheduled: isScheduledDay,
          isCompleted: countsTowardWeeklyCompletion && progressRate >= 1,
          countsTowardWeeklyCompletion: countsTowardWeeklyCompletion,
          progressRate: progressRate >= 1 ? 1 : progressRate,
          visualState: visualState,
        ),
      );
    }
    return snapshots;
  }

  double _resolveDailyProgressRate({
    required ProgressEntryModel? entry,
    required List<String> subActivities,
  }) {
    return resolveActivityProgressSummary(
      subActivities: subActivities,
      entry: entry,
    ).rate;
  }

  WeeklyProgressDayVisualState _resolveWeeklySnapshotVisualState({
    required bool isScheduledDay,
    required DateTime day,
    required DateTime today,
    required DateTime scheduleUpdatedAt,
    required ProgressEntryModel? entry,
    required double progressRate,
  }) {
    final DateTime dayDate = dateOnly(day);
    final DateTime todayDate = dateOnly(today);
    final DateTime activeFrom = dateOnly(scheduleUpdatedAt);

    if (!isScheduledDay || dayDate.isBefore(activeFrom)) {
      return WeeklyProgressDayVisualState.notScheduled;
    }
    if (dayDate.isAfter(todayDate)) {
      return WeeklyProgressDayVisualState.future;
    }
    if (entry?.status == ActivityDayStatus.skipped) {
      return WeeklyProgressDayVisualState.pending;
    }
    if (progressRate >= 1) {
      return WeeklyProgressDayVisualState.complete;
    }
    if (progressRate > 0) {
      return WeeklyProgressDayVisualState.partial;
    }
    if (dayDate.isBefore(todayDate)) {
      return WeeklyProgressDayVisualState.missed;
    }
    return WeeklyProgressDayVisualState.pending;
  }

  _ActivityAiInsightData _buildActivityAiInsightData({
    required ActivityModel activity,
    required List<ProgressEntryModel> entries,
    required ActivityBreakdown? breakdown,
    required String localeCode,
    required DateTime today,
    ActivityDetailMlPrediction? mlPrediction,
  }) {
    final bool isId = localeCode == 'id';
    final DateTime normalizedToday = dateOnly(today);
    final DateTime scheduleStart = dateOnly(
      activity.scheduleUpdatedAt ?? activity.createdAt,
    );
    final DateTime lookbackStart = normalizedToday.subtract(
      const Duration(days: 27),
    );
    final DateTime start =
        lookbackStart.isAfter(scheduleStart) ? lookbackStart : scheduleStart;
    final Map<String, ProgressEntryModel> entryByDateKey =
        <String, ProgressEntryModel>{
      for (final ProgressEntryModel entry in entries) entry.dateKey: entry,
    };
    final Map<int, _ActivityDayPatternStat> weekdayStats =
        <int, _ActivityDayPatternStat>{};
    int scheduled = 0;
    int completed = 0;

    DateTime cursor = start;
    while (!cursor.isAfter(normalizedToday)) {
      if (activity.selectedDays.contains(cursor.weekday)) {
        final ProgressEntryModel? entry =
            entryByDateKey[dateKeyFromDate(cursor)];
        final bool isToday = dateOnly(cursor) == normalizedToday;
        final ActivityProgressSummary progress =
            resolveActivityProgressSummary(
          subActivities: activity.subActivities,
          entry: entry,
        );
        if (entry != null || !isToday) {
          scheduled++;
          final bool isCompleted =
              progress.rate >= 1 || entry?.status == ActivityDayStatus.done;
          final bool isIncomplete = !isCompleted;
          if (isCompleted) {
            completed++;
          }
          final _ActivityDayPatternStat previous =
              weekdayStats[cursor.weekday] ??
                  _ActivityDayPatternStat(
                    weekday: cursor.weekday,
                    scheduled: 0,
                    completed: 0,
                    incomplete: 0,
                  );
          weekdayStats[cursor.weekday] = _ActivityDayPatternStat(
            weekday: cursor.weekday,
            scheduled: previous.scheduled + 1,
            completed: previous.completed + (isCompleted ? 1 : 0),
            incomplete: previous.incomplete + (isIncomplete ? 1 : 0),
          );
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    final double overallRate = scheduled == 0
        ? (breakdown?.completionRate ?? 0)
        : completed / scheduled;
    final List<_ActivityDayPatternStat> bestDayCandidates = weekdayStats.values
        .where((_ActivityDayPatternStat item) => item.completed > 0)
        .toList()
      ..sort((_ActivityDayPatternStat a, _ActivityDayPatternStat b) {
        final int byRate = b.completionRate.compareTo(a.completionRate);
        if (byRate != 0) {
          return byRate;
        }
        return b.completed.compareTo(a.completed);
      });
    final List<_ActivityDayPatternStat> weakestDayCandidates = weekdayStats
        .values
        .where((_ActivityDayPatternStat item) => item.incomplete > 0)
        .toList()
      ..sort((_ActivityDayPatternStat a, _ActivityDayPatternStat b) {
        final int byIncomplete = b.incomplete.compareTo(a.incomplete);
        if (byIncomplete != 0) {
          return byIncomplete;
        }
        return a.completionRate.compareTo(b.completionRate);
      });

    final _ActivityDayPatternStat? strongestDay =
        bestDayCandidates.isEmpty ? null : bestDayCandidates.first;
    final _ActivityDayPatternStat? weakestDay =
        weakestDayCandidates.isEmpty ? null : weakestDayCandidates.first;

    final Map<String, int> timeBucketCounts = <String, int>{};
    for (final ProgressEntryModel entry in entries) {
      if (!entry.isCompleted) {
        continue;
      }
      final DateTime? completionTime = entry.effectiveCompletionTime;
      if (completionTime == null) {
        continue;
      }
      final String bucketKey = _timeBucketKey(
        completionTime.hour * 60 + completionTime.minute,
      );
      timeBucketCounts[bucketKey] = (timeBucketCounts[bucketKey] ?? 0) + 1;
    }

    String bestTimeLabel;
    if (timeBucketCounts.isEmpty) {
      bestTimeLabel =
          '${_timeBucketLabel(activity.timeMinutes, localeCode)} • ${formatMinutesAsTime(activity.timeMinutes)}';
    } else {
      final String strongestBucket = ([...timeBucketCounts.entries]
            ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
              final int byCount = b.value.compareTo(a.value);
              if (byCount != 0) {
                return byCount;
              }
              return a.key.compareTo(b.key);
            }))
          .first
          .key;
      bestTimeLabel = _timeBucketLabelFromKey(strongestBucket, localeCode);
    }
    bestTimeLabel = bestTimeLabel.replaceAll('â€¢', '-');

    final String? strongestDayLabel = strongestDay == null
        ? null
        : _weekdayLongLabel(strongestDay.weekday, localeCode);
    final String? weakestDayLabel = weakestDay == null
        ? null
        : _weekdayLongLabel(weakestDay.weekday, localeCode);

    String heroLine;
    String headline;
    String body;
    if (overallRate >= 0.8) {
      heroLine = isId ? 'Aktivitas ini lagi stabil' : 'This activity is stable';
      headline = isId
          ? 'Pola aktivitas ini sudah kuat'
          : 'This activity has a strong pattern';
      body = strongestDayLabel == null
          ? (isId
              ? 'Ritmenya sudah cukup konsisten di periode terakhir.'
              : 'Its rhythm has been quite consistent lately.')
          : (isId
              ? 'Hari paling kuat saat ini ada di $strongestDayLabel.'
              : 'Your strongest day right now is $strongestDayLabel.');
    } else if (overallRate >= 0.5) {
      heroLine =
          isId ? 'Aktivitas ini mulai terbentuk' : 'This activity is taking shape';
      headline =
          isId ? 'Aktivitas ini sudah punya pola' : 'This activity already has a pattern';
      body = strongestDayLabel != null
          ? (isId
              ? 'Paling sering selesai saat dijalankan di $strongestDayLabel.'
              : 'It gets completed most often on $strongestDayLabel.')
          : (isId
              ? 'Progress-nya sudah mulai kebaca dari beberapa minggu terakhir.'
              : 'Its progress is starting to emerge from the past few weeks.');
    } else {
      heroLine =
          isId ? 'Aktivitas ini belum stabil' : 'This activity is not stable yet';
      headline = isId
          ? 'Aktivitas ini masih perlu dirapikan'
          : 'This activity still needs tuning';
      body = weakestDayLabel != null
          ? (isId
              ? 'Paling sering tertunda saat jatuh di $weakestDayLabel.'
              : 'It gets postponed the most on $weakestDayLabel.')
          : (isId
              ? 'Belum cukup banyak progres untuk membaca pola yang kuat.'
              : 'There is not enough progress yet to read a strong pattern.');
    }

    String caution = weakestDayLabel == null
        ? (isId
            ? 'Belum ada pola hambatan yang benar-benar kuat.'
            : 'There is no clearly strong friction pattern yet.')
        : (isId
            ? 'Hari yang paling sering berat: $weakestDayLabel'
            : 'The hardest day so far: $weakestDayLabel');

    String recommendation;
    if (overallRate < 0.35) {
      recommendation = strongestDayLabel == null
          ? (isId
              ? 'Mulai dari target kecil dulu agar ritmenya lebih realistis.'
              : 'Start with a smaller target first so the rhythm feels realistic.')
          : (isId
              ? 'Kalau minggu terasa padat, prioritaskan dulu $strongestDayLabel.'
              : 'When the week feels packed, prioritize $strongestDayLabel first.');
    } else if (strongestDayLabel != null &&
        weakestDayLabel != null &&
        strongestDayLabel != weakestDayLabel) {
      recommendation = isId
          ? 'Fokuskan aktivitas ini di $strongestDayLabel dan jangan terlalu memaksa di $weakestDayLabel.'
          : 'Focus this activity on $strongestDayLabel and do not force it too much on $weakestDayLabel.';
    } else {
      recommendation = isId
          ? 'Pertahankan slot yang sekarang karena polanya sudah mulai terbaca.'
          : 'Keep the current slot because the pattern is starting to emerge.';
    }

    String dayMetricTitle = isId ? 'Hari Cocok' : 'Best day';
    String timeMetricTitle = isId ? 'Saran Waktu' : 'Best time';
    String bestDayLabel = strongestDayLabel ??
        (isId ? 'Pola hari belum terbaca' : 'Best day is not clear yet');
    String bestTimeMetricLabel = bestTimeLabel;

    if (mlPrediction != null) {
      dayMetricTitle = isId ? 'Hari Cocok' : 'Today fit';
      timeMetricTitle = isId ? 'Saran Waktu' : 'Suggested time';
      bestDayLabel = mlPrediction.isTodaySuitable
          ? (isId ? 'Cocok untuk hari ini' : 'Good for today')
          : (isId ? 'Belum ideal untuk hari ini' : 'Not ideal for today');
      if (mlPrediction.predictedTimeMinutes != null) {
        bestTimeMetricLabel =
            '${_timeBucketLabel(mlPrediction.predictedTimeMinutes!, localeCode)} - ${formatMinutesAsTime(mlPrediction.predictedTimeMinutes!)}';
      }

      final String readableTime = mlPrediction.predictedTimeMinutes == null
          ? bestTimeMetricLabel
          : formatMinutesAsTime(mlPrediction.predictedTimeMinutes!);
      if (mlPrediction.isTodaySuitable) {
        body = isId
            ? 'Hari ini masih cukup masuk untuk aktivitas ini, dengan slot yang cenderung aman di sekitar $readableTime.'
            : 'Today still looks suitable for this activity, with a safer slot around $readableTime.';
        recommendation = isId
            ? 'Kalau ritmemu belum berubah, coba pertahankan aktivitas ini di sekitar $readableTime.'
            : 'If your routine stays similar, try keeping this activity around $readableTime.';
      } else {
        heroLine = isId
            ? 'Hari ini kurang ideal untuk aktivitas ini'
            : 'Today is less ideal for this activity';
        body = isId
            ? 'Prediksi hari ini kurang ideal, jadi lebih aman kalau aktivitas ini diarahkan ke sekitar $readableTime.'
            : 'Today looks less ideal, so it is safer to steer this activity toward $readableTime.';
        caution = isId
            ? 'Kalau hari ini terasa padat, jangan terlalu memaksa aktivitas ini di luar slot yang disarankan.'
            : 'If today feels packed, avoid forcing this activity outside the suggested window.';
        recommendation = isId
            ? 'Coba pindahkan fokus ke sekitar $readableTime atau turunkan targetnya dulu.'
            : 'Try shifting the focus toward $readableTime or lower the target first.';
      }
    }

    return _ActivityAiInsightData(
      heroLine: heroLine,
      headline: headline,
      body: body,
      dayMetricTitle: dayMetricTitle,
      timeMetricTitle: timeMetricTitle,
      bestDayLabel: bestDayLabel,
      bestTimeLabel: bestTimeMetricLabel,
      caution: caution,
      recommendation: recommendation,
    );
  }

  String _timeBucketKey(int minutes) {
    if (minutes >= 5 * 60 && minutes < 11 * 60) {
      return 'morning';
    }
    if (minutes >= 11 * 60 && minutes < 15 * 60) {
      return 'midday';
    }
    if (minutes >= 15 * 60 && minutes < 18 * 60) {
      return 'afternoon';
    }
    return 'night';
  }

  String _timeBucketLabel(int minutes, String localeCode) {
    return _timeBucketLabelFromKey(_timeBucketKey(minutes), localeCode);
  }

  String _timeBucketLabelFromKey(String key, String localeCode) {
    final bool isId = localeCode == 'id';
    return switch (key) {
      'morning' => isId ? 'Pagi' : 'Morning',
      'midday' => isId ? 'Siang' : 'Midday',
      'afternoon' => isId ? 'Sore' : 'Afternoon',
      _ => isId ? 'Malam' : 'Night',
    };
  }

  String _weekdayLongLabel(int weekday, String localeCode) {
    const List<String> id = <String>[
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const List<String> en = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final List<String> labels = localeCode == 'id' ? id : en;
    if (weekday < 1 || weekday > 7) {
      return labels.first;
    }
    return labels[weekday - 1];
  }

  List<String> _normalizedPhotoPaths(ProgressEntryModel? entry) {
    if (entry == null) {
      return const <String>[];
    }
    final List<String> multiPhotoPaths = entry.photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    if (multiPhotoPaths.isNotEmpty) {
      return multiPhotoPaths;
    }
    final String singlePhoto = (entry.photoPath ?? '').trim();
    if (singlePhoto.isEmpty) {
      return const <String>[];
    }
    return <String>[singlePhoto];
  }

  Future<void> _addDailyLogUpdate({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required String localeCode,
    required ActivityModel activity,
    ProgressEntryModel? existingEntry,
    bool saveAsSkipped = false,
  }) async {
    final String initialNote = (existingEntry?.notes ?? '').trim();
    final List<String> initialPhotoPaths = _normalizedPhotoPaths(existingEntry);
    final TextEditingController noteController = TextEditingController(
      text: initialNote,
    );
    final List<String> draftPhotoPaths = List<String>.from(initialPhotoPaths);
    final Set<String> sessionPickedPaths = <String>{};
    bool pickingPhoto = false;

    final _DailyLogUpdateDraft? draft =
        await showModalBottomSheet<_DailyLogUpdateDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final bool canSave = saveAsSkipped ||
                noteController.text.trim().isNotEmpty ||
                draftPhotoPaths.isNotEmpty;
            final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        localeCode == 'id' ? 'Catatan harian' : 'Daily note',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        minLines: 4,
                        maxLines: 6,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: t.noteInputHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: pickingPhoto
                            ? null
                            : () async {
                                setSheetState(() {
                                  pickingPhoto = true;
                                });
                                final List<String> newPaths =
                                    await _pickDailyLogPhotoPaths(
                                  context: sheetContext,
                                  ref: ref,
                                  localeCode: localeCode,
                                );
                                if (!sheetContext.mounted) {
                                  return;
                                }
                                setSheetState(() {
                                  pickingPhoto = false;
                                  if (newPaths.isEmpty) {
                                    return;
                                  }
                                  for (final String path in newPaths) {
                                    final String cleanPath = path.trim();
                                    if (cleanPath.isEmpty) {
                                      continue;
                                    }
                                    sessionPickedPaths.add(cleanPath);
                                    if (!draftPhotoPaths.contains(cleanPath)) {
                                      draftPhotoPaths.add(cleanPath);
                                    }
                                  }
                                });
                              },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          t.addPhoto,
                        ),
                      ),
                      if (draftPhotoPaths.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: draftPhotoPaths.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final String path = draftPhotoPaths[index];
                              return Stack(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: OptimizedFileImage(
                                      path: path,
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 54,
                                          height: 54,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.broken_image_rounded,
                                            size: 16,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () {
                                        setSheetState(() {
                                          draftPhotoPaths.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.62,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canSave
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  Navigator.of(context).pop(
                                    _DailyLogUpdateDraft(
                                      note: noteController.text.trim(),
                                      photoPaths: List<String>.from(
                                        draftPhotoPaths,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(localeCode == 'id' ? 'Simpan' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    _disposeTextControllerSafely(noteController);

    if (draft == null) {
      await _cleanupDraftPhotos(ref, sessionPickedPaths.toList());
      return;
    }
    if (!context.mounted) {
      await _cleanupDraftPhotos(ref, sessionPickedPaths.toList());
      return;
    }

    final String skipSaveWarningMessage = localeCode == 'id'
        ? 'Status aktivitas hari ini akan disimpan sebagai dilewati. Catatan dan foto bersifat opsional.'
        : 'Today activity status will be saved as skipped. Notes and photos are optional.';
    final bool confirm = await _showImmutableSaveWarningDialog(
      context: context,
      title: t.dataImmutableWarningTitle,
      message: saveAsSkipped
          ? skipSaveWarningMessage
          : (draft.photoPaths.isNotEmpty
              ? t.photoSaveWarningMessage
              : t.noteSaveWarningMessage),
      cancelLabel: t.cancel,
      confirmLabel: localeCode == 'id' ? 'Simpan' : 'Save',
    );
    if (!confirm) {
      await _cleanupDraftPhotos(ref, sessionPickedPaths.toList());
      return;
    }

    final bool hasDraftChanges = draft.note.trim() != initialNote ||
        !_haveSamePathSet(initialPhotoPaths, draft.photoPaths);
    _DailyLogSaveResult saveResult = _DailyLogSaveResult(
      noteProvided: initialNote.isNotEmpty,
      noteSaved: true,
      savedPhotoCount: 0,
      keptPhotoPaths: List<String>.from(initialPhotoPaths),
    );
    if (hasDraftChanges) {
      saveResult = await _saveDailyLogUpdateDraft(
        ref: ref,
        activity: activity,
        existingEntry: existingEntry,
        initialNote: initialNote,
        initialPhotoPaths: initialPhotoPaths,
        draft: draft,
      );
    }
    if (saveAsSkipped) {
      await ref.read(activityActionsProvider).skipToday(
            activity: activity,
            note: draft.note.trim().isEmpty ? null : draft.note.trim(),
          );
    }
    final List<String> unusedSessionPhotos = sessionPickedPaths
        .where((String path) => !saveResult.keptPhotoPaths.contains(path))
        .toList();
    await _cleanupDraftPhotos(ref, unusedSessionPhotos);

    final List<String> removedExistingPhotos = initialPhotoPaths
        .where((String path) => !saveResult.keptPhotoPaths.contains(path))
        .toList();
    await _cleanupDraftPhotos(ref, removedExistingPhotos);

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saveAsSkipped
              ? _buildSkipActivitySaveMessage(
                  localeCode: localeCode,
                  noteProvided: draft.note.trim().isNotEmpty,
                  savedPhotoCount: saveResult.savedPhotoCount,
                )
              : _buildDailyLogSaveMessage(
                  localeCode: localeCode,
                  noteProvided: saveResult.noteProvided,
                  noteSaved: saveResult.noteSaved,
                  savedPhotoCount: saveResult.savedPhotoCount,
                ),
        ),
      ),
    );
  }

  Future<List<String>> _pickDailyLogPhotoPaths({
    required BuildContext context,
    required WidgetRef ref,
    required String localeCode,
  }) async {
    final _DailyLogPhotoSource? source = await _showDailyLogPhotoSourcePicker(
      context: context,
      localeCode: localeCode,
    );
    if (source == null || !context.mounted) {
      return const <String>[];
    }

    final bool allowed = await ref.read(photoAccessServiceProvider).ensureAccess(
          context: context,
          localeCode: localeCode,
          source: source == _DailyLogPhotoSource.camera
              ? PhotoAccessSource.camera
              : PhotoAccessSource.gallery,
        );
    if (!allowed) {
      return const <String>[];
    }

    final imageStorage = ref.read(imageStorageServiceProvider);
    return switch (source) {
      _DailyLogPhotoSource.camera => <String>[
          if (await imageStorage.pickAndSaveImageFromCamera()
              case final String path)
            path,
        ],
      _DailyLogPhotoSource.gallery => imageStorage.pickAndSaveImagesFromGallery(),
    };
  }

  Future<_DailyLogPhotoSource?> _showDailyLogPhotoSourcePicker({
    required BuildContext context,
    required String localeCode,
  }) async {
    final bool isId = localeCode == 'id';
    return showModalBottomSheet<_DailyLogPhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(isId ? 'Ambil foto dari kamera' : 'Take photo'),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DailyLogPhotoSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(
                    isId ? 'Pilih foto dari galeri' : 'Choose from gallery',
                  ),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DailyLogPhotoSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cleanupDraftPhotos(
    WidgetRef ref,
    List<String> photoPaths,
  ) async {
    for (final String path in photoPaths) {
      final String cleanPath = path.trim();
      if (cleanPath.isEmpty) {
        continue;
      }
      await ref.read(imageStorageServiceProvider).deleteImageAtPath(cleanPath);
    }
  }

  Future<_DailyLogSaveResult> _saveDailyLogUpdateDraft({
    required WidgetRef ref,
    required ActivityModel activity,
    required ProgressEntryModel? existingEntry,
    required String initialNote,
    required List<String> initialPhotoPaths,
    required _DailyLogUpdateDraft draft,
  }) async {
    final DateTime targetDate = dateOnly(DateTime.now());
    final String nextNote = draft.note.trim();
    final List<String> nextPhotoPaths = draft.photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList();
    final bool noteProvided = nextNote.isNotEmpty;
    final bool noteChanged = initialNote != nextNote;
    final bool photosChanged = !_haveSamePathSet(
      initialPhotoPaths,
      nextPhotoPaths,
    );

    ProgressEntryModel? baseEntry = existingEntry;
    if (baseEntry != null && noteChanged && initialNote.isNotEmpty) {
      await ref
          .read(activityActionsProvider)
          .removeNoteFromEntry(entry: baseEntry);
      baseEntry = baseEntry.copyWith(
        clearNotes: true,
        updatedAt: DateTime.now(),
      );
    }
    if (baseEntry != null && photosChanged && initialPhotoPaths.isNotEmpty) {
      await ref
          .read(activityActionsProvider)
          .removePhotoFromEntry(entry: baseEntry);
      baseEntry = baseEntry.copyWith(
        clearPhotoPath: true,
        clearPhotoPaths: true,
        clearPhotoNote: true,
        updatedAt: DateTime.now(),
      );
    }

    bool noteSaved = true;
    if (noteProvided &&
        (existingEntry == null || noteChanged || initialNote.isEmpty)) {
      noteSaved =
          await ref.read(activityActionsProvider).upsertNoteForDate(
                activity: activity,
                date: targetDate,
                notes: nextNote,
              );
    }

    int savedPhotoCount = 0;
    if (nextPhotoPaths.isNotEmpty &&
        (existingEntry == null || photosChanged || initialPhotoPaths.isEmpty)) {
      for (final String path in nextPhotoPaths) {
        await ref.read(activityActionsProvider).upsertPhotoForDate(
              activity: activity,
              date: targetDate,
              photoPath: path,
              notes: nextNote.isEmpty ? null : nextNote,
            );
        savedPhotoCount++;
      }
    }

    return _DailyLogSaveResult(
      noteProvided: noteProvided,
      noteSaved: noteSaved,
      savedPhotoCount: savedPhotoCount,
      keptPhotoPaths: nextPhotoPaths,
    );
  }

  bool _haveSamePathSet(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }
    final Set<String> firstSet = first.toSet();
    final Set<String> secondSet = second.toSet();
    if (firstSet.length != secondSet.length) {
      return false;
    }
    return firstSet.containsAll(secondSet);
  }

  Future<void> _deleteTodayLogText({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required String localeCode,
    required ProgressEntryModel entry,
  }) async {
    final bool hasNotes = (entry.notes ?? '').trim().isNotEmpty;
    final bool hasPhotoNote = (entry.photoNote ?? '').trim().isNotEmpty;
    if (!hasNotes && !hasPhotoNote) {
      return;
    }

    final bool confirm = await _showImmutableSaveWarningDialog(
      context: context,
      title: localeCode == 'id' ? 'Hapus log hari ini?' : 'Delete today log?',
      message: localeCode == 'id'
          ? 'Teks log hari ini akan dihapus.'
          : 'Today log text will be removed.',
      cancelLabel: t.cancel,
      confirmLabel: t.delete,
    );
    if (!confirm) {
      return;
    }

    ProgressEntryModel workingEntry = entry;
    if (hasNotes) {
      await ref
          .read(activityActionsProvider)
          .removeNoteFromEntry(entry: workingEntry);
      workingEntry = workingEntry.copyWith(
        clearNotes: true,
        updatedAt: DateTime.now(),
      );
    }
    if (hasPhotoNote) {
      await ref
          .read(activityActionsProvider)
          .removePhotoNoteFromEntry(entry: workingEntry);
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localeCode == 'id'
              ? 'Catatan harian dihapus.'
              : 'Daily note deleted.',
        ),
      ),
    );
  }

  Future<void> _deleteTodayLogPhotos({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required String localeCode,
    required ProgressEntryModel entry,
    required List<String> photoPaths,
  }) async {
    if (photoPaths.isEmpty) {
      return;
    }

    final bool deletePhotoAndComment =
        (entry.photoNote ?? '').trim().isNotEmpty;
    final bool confirm = await _showImmutableSaveWarningDialog(
      context: context,
      title:
          localeCode == 'id' ? 'Hapus foto hari ini?' : 'Delete today photo?',
      message: deletePhotoAndComment
          ? (localeCode == 'id'
              ? 'Foto dan komentar foto hari ini akan dihapus.'
              : 'Today photo and photo comment will be removed.')
          : (localeCode == 'id'
              ? 'Foto hari ini akan dihapus.'
              : 'Today photo will be removed.'),
      cancelLabel: t.cancel,
      confirmLabel: t.delete,
    );
    if (!confirm) {
      return;
    }

    await ref.read(activityActionsProvider).removePhotoFromEntry(entry: entry);
    await _cleanupDraftPhotos(ref, photoPaths);

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deletePhotoAndComment
              ? (localeCode == 'id'
                  ? 'Foto dihapus - Komentar foto dihapus.'
                  : 'Photo deleted - Photo comment deleted.')
              : (localeCode == 'id' ? 'Foto dihapus.' : 'Photo deleted.'),
        ),
      ),
    );
  }

  String _buildDailyLogSaveMessage({
    required String localeCode,
    required bool noteProvided,
    required bool noteSaved,
    required int savedPhotoCount,
  }) {
    if (noteProvided && savedPhotoCount > 0) {
      return noteSaved
          ? (localeCode == 'id'
              ? 'Update harian tersimpan.'
              : 'Daily update saved.')
          : (localeCode == 'id'
              ? 'Foto tersimpan. Catatan hari ini sudah ada.'
              : 'Photos saved. A note for today already exists.');
    }
    if (savedPhotoCount > 0) {
      return localeCode == 'id'
          ? '$savedPhotoCount foto berhasil ditambahkan.'
          : '$savedPhotoCount photos added successfully.';
    }
    if (noteProvided) {
      return noteSaved
          ? (localeCode == 'id'
              ? 'Catatan harian tersimpan.'
              : 'Daily note saved.')
          : (localeCode == 'id'
              ? 'Catatan hari ini sudah ada.'
              : 'A note for today already exists.');
    }
    return localeCode == 'id' ? 'Update tersimpan.' : 'Update saved.';
  }

  String _buildSkipActivitySaveMessage({
    required String localeCode,
    required bool noteProvided,
    required int savedPhotoCount,
  }) {
    if (noteProvided || savedPhotoCount > 0) {
      return localeCode == 'id'
          ? 'Aktivitas dilewati. Catatan harian tersimpan.'
          : 'Activity skipped. Daily note saved.';
    }
    return localeCode == 'id' ? 'Aktivitas dilewati.' : 'Activity skipped.';
  }

  Future<bool> _showImmutableSaveWarningDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirm == true;
  }
}

class _DailyLogUpdateDraft {
  const _DailyLogUpdateDraft({required this.note, required this.photoPaths});

  final String note;
  final List<String> photoPaths;
}

enum _DailyLogPhotoSource { camera, gallery }

class _DailyLogSaveResult {
  const _DailyLogSaveResult({
    required this.noteProvided,
    required this.noteSaved,
    required this.savedPhotoCount,
    required this.keptPhotoPaths,
  });

  final bool noteProvided;
  final bool noteSaved;
  final int savedPhotoCount;
  final List<String> keptPhotoPaths;
}

enum _DailyLogTextSource { none, notes, photoNote }

class _DailyLogTimelineEntry {
  const _DailyLogTimelineEntry({
    required this.entry,
    required this.dateKey,
    required this.logText,
    required this.textSource,
    required this.photoPaths,
  });

  final ProgressEntryModel entry;
  final String dateKey;
  final String logText;
  final _DailyLogTextSource textSource;
  final List<String> photoPaths;
}

enum _TimelineLogMenuAction { edit, delete }

enum _ComparisonRange { last7, last30, all }

class _ActivityComparisonPage extends StatelessWidget {
  const _ActivityComparisonPage({
    required this.activityId,
    required this.activityTitle,
    required this.localeCode,
  });

  final String activityId;
  final String activityTitle;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.comparisonTimelineTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          AppSpacing.screenPadding,
          AppSpacing.cardPadding,
          AppSpacing.screenPadding,
        ),
        children: <Widget>[
          Text(activityTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.componentGap),
          _ComparisonTimelineSection(
            activityId: activityId,
            localeCode: localeCode,
          ),
        ],
      ),
    );
  }
}

class _ComparisonTimelineSection extends ConsumerStatefulWidget {
  const _ComparisonTimelineSection({
    required this.activityId,
    required this.localeCode,
  });

  final String activityId;
  final String localeCode;

  @override
  ConsumerState<_ComparisonTimelineSection> createState() =>
      _ComparisonTimelineSectionState();
}

class _ComparisonTimelineSectionState
    extends ConsumerState<_ComparisonTimelineSection> {
  static const int _entriesPerPage = 5;

  _ComparisonRange _range = _ComparisonRange.last30;
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final List<ActivityModel> allActivities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    ActivityModel? activity;
    for (final ActivityModel item in allActivities) {
      if (item.id == widget.activityId) {
        activity = item;
        break;
      }
    }
    final List<ProgressEntryModel> entries =
        ref.watch(progressByActivityProvider(widget.activityId)).value ??
            const <ProgressEntryModel>[];
    final List<ProgressEntryModel> orderedEntries = _orderedEntries(entries);
    final List<_DailyLogTimelineEntry> orderedLogs =
        _buildDailyLogEntries(orderedEntries);
    final List<_DailyLogTimelineEntry> filteredLogs =
        _filteredLogEntries(orderedLogs);
    final int totalPages =
        filteredLogs.isEmpty ? 1 : (filteredLogs.length / _entriesPerPage).ceil();
    final int currentPage = _pageIndex.clamp(0, totalPages - 1);
    final int pageStart = currentPage * _entriesPerPage;
    final int pageEnd = filteredLogs.isEmpty
        ? 0
        : math.min(pageStart + _entriesPerPage, filteredLogs.length);
    final List<_DailyLogTimelineEntry> pagedLogs = filteredLogs.isEmpty
        ? const <_DailyLogTimelineEntry>[]
        : filteredLogs.sublist(pageStart, pageEnd);
    final List<_GalleryPhotoCandidate> comparisonCandidates =
        _buildComparisonCandidates(orderedLogs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              t.comparisonTimelineTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            _ComparisonRangeSwitcher(
              selected: _range,
              sevenDaysLabel: t.comparisonFilter7d,
              thirtyDaysLabel: t.comparisonFilter30d,
              allLabel: t.comparisonFilterAll,
              onChanged: (_ComparisonRange value) {
                setState(() {
                  _range = value;
                  _pageIndex = 0;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            if (filteredLogs.isEmpty)
              Text(t.comparisonEmpty)
            else
              ...pagedLogs.asMap().entries.map(
                (
                  MapEntry<int, _DailyLogTimelineEntry> item,
                ) {
                  final int index = item.key;
                  final _DailyLogTimelineEntry logEntry = item.value;
                  return _buildLogTimelineCard(
                    context: context,
                    ref: ref,
                    t: t,
                    logEntry: logEntry,
                    compareCandidates: comparisonCandidates,
                    activity: activity,
                    showConnector: index < pagedLogs.length - 1,
                  );
                },
              ),
            if (filteredLogs.isNotEmpty && totalPages > 1) ...<Widget>[
              const SizedBox(height: AppSpacing.xs / 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: currentPage > 0
                          ? () {
                              setState(() {
                                _pageIndex = currentPage - 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${pageStart + 1}-$pageEnd / ${filteredLogs.length} | ${currentPage + 1}/$totalPages',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: currentPage < totalPages - 1
                          ? () {
                              setState(() {
                                _pageIndex = currentPage + 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogTimelineCard({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required _DailyLogTimelineEntry logEntry,
    required List<_GalleryPhotoCandidate> compareCandidates,
    required ActivityModel? activity,
    required bool showConnector,
  }) {
    final ThemeData localTheme = Theme.of(context);
    final ProgressEntryModel entry = logEntry.entry;
    final bool hasLogText = logEntry.logText.isNotEmpty;
    final bool hasPhoto = logEntry.photoPaths.isNotEmpty;
    final DateTime entryDate = dateFromKey(logEntry.dateKey);
    final DateTime scheduleUpdatedAt =
        activity?.scheduleUpdatedAt ?? activity?.createdAt ?? entryDate;
    final ActivityDailyProgressStatus status = resolveActivityDailyProgressStatus(
      scheduledDate: entryDate,
      today: dateOnly(DateTime.now()),
      scheduleUpdatedAt: scheduleUpdatedAt,
      subActivities: activity?.subActivities ?? const <String>[],
      scheduledTimeMinutes: activity?.timeMinutes,
      entry: entry,
    );
    final String statusLabel = activityStatusLabel(
      status: status,
      localeCode: widget.localeCode,
    );
    final Color statusDotColor = activityStatusColor(
      theme: localTheme,
      status: status,
    ).withValues(alpha: 0.92);
    final Color statusColor = activityStatusColor(
      theme: localTheme,
      status: status,
    ).withValues(alpha: 0.86);

    final double connectorHeight = switch ((hasPhoto, hasLogText)) {
      (true, true) => 210,
      (true, false) => 150,
      (false, true) => 110,
      (false, false) => 56,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 4),
                Icon(
                  activityStatusIcon(status),
                  size: 14,
                  color: statusDotColor,
                ),
                if (showConnector)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 1,
                    height: connectorHeight,
                    color: localTheme.colorScheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              formatDateLong(
                                dateFromKey(logEntry.dateKey),
                                widget.localeCode,
                              ),
                              style: localTheme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusLabel,
                              style: localTheme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<_TimelineLogMenuAction>(
                        tooltip:
                            widget.localeCode == 'id' ? 'Opsi log' : 'Log options',
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: localTheme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                        ),
                        onSelected: (_TimelineLogMenuAction action) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (
                              _,
                            ) async {
                              if (!mounted || !context.mounted) {
                                return;
                              }
                              if (action == _TimelineLogMenuAction.edit) {
                                await _editTimelineLogEntry(
                                  context: context,
                                  ref: ref,
                                  t: t,
                                  logEntry: logEntry,
                                );
                              } else if (action ==
                                  _TimelineLogMenuAction.delete) {
                                await _deleteTimelineEntry(
                                  context: context,
                                  ref: ref,
                                  t: t,
                                  logEntry: logEntry,
                                );
                              }
                            },
                          );
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<_TimelineLogMenuAction>>[
                            PopupMenuItem<_TimelineLogMenuAction>(
                              value: _TimelineLogMenuAction.edit,
                              child: Text(
                                widget.localeCode == 'id' ? 'Edit' : 'Edit',
                              ),
                            ),
                            PopupMenuItem<_TimelineLogMenuAction>(
                              value: _TimelineLogMenuAction.delete,
                              child: Text(
                                widget.localeCode == 'id' ? 'Hapus' : 'Delete',
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                  if (hasPhoto) ...<Widget>[
                    const SizedBox(height: 16),
                    _TimelineEntryPhotoPreview(
                      paths: logEntry.photoPaths,
                      localeCode: widget.localeCode,
                      dateKey: logEntry.dateKey,
                      compareCandidates: compareCandidates,
                    ),
                  ],
                  if (hasLogText) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      logEntry.logText,
                      style: localTheme.textTheme.bodyMedium?.copyWith(
                        color: localTheme.colorScheme.onSurface.withValues(
                          alpha: 0.88,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTimelineLogEntry({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required _DailyLogTimelineEntry logEntry,
  }) async {
    final List<ActivityModel> activities =
        ref.read(activitiesStreamProvider).value ?? const <ActivityModel>[];
    ActivityModel? activity;
    for (final ActivityModel item in activities) {
      if (item.id == widget.activityId) {
        activity = item;
        break;
      }
    }
    if (activity == null) {
      return;
    }

    final TextEditingController controller = TextEditingController(
      text: logEntry.logText,
    );
    final String? nextValue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: widget.localeCode == 'id'
                          ? 'Apa yang kamu lakukan hari itu?'
                          : 'What did you do that day?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(controller.text.trim());
                      },
                      child: Text(t.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _disposeTextControllerSafely(controller);

    if (nextValue == null) {
      return;
    }
    final String previousText = logEntry.logText.trim();
    final String nextText = nextValue.trim();
    if (previousText == nextText) {
      return;
    }

    ProgressEntryModel workingEntry = logEntry.entry;
    if ((workingEntry.notes ?? '').trim().isNotEmpty) {
      await ref
          .read(activityActionsProvider)
          .removeNoteFromEntry(entry: workingEntry);
      workingEntry = workingEntry.copyWith(
        clearNotes: true,
        updatedAt: DateTime.now(),
      );
    }
    if ((workingEntry.photoNote ?? '').trim().isNotEmpty) {
      await ref
          .read(activityActionsProvider)
          .removePhotoNoteFromEntry(entry: workingEntry);
      workingEntry = workingEntry.copyWith(
        clearPhotoNote: true,
        updatedAt: DateTime.now(),
      );
    }

    bool noteSaved = true;
    if (nextText.isNotEmpty) {
      noteSaved =
          await ref.read(activityActionsProvider).upsertNoteForDate(
                activity: activity,
                date: dateFromKey(logEntry.dateKey),
                notes: nextText,
              );
    }

    if (!context.mounted) {
      return;
    }
    final String message = nextText.isEmpty
        ? (widget.localeCode == 'id'
            ? 'Catatan harian dihapus.'
            : 'Daily note deleted.')
        : (noteSaved
            ? (widget.localeCode == 'id'
                ? 'Catatan harian diperbarui.'
                : 'Daily note updated.')
            : (widget.localeCode == 'id'
                ? 'Catatan tidak bisa diperbarui.'
                : 'Note could not be updated.'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTimelineEntry({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required _DailyLogTimelineEntry logEntry,
  }) async {
    final bool hasNote = logEntry.logText.trim().isNotEmpty;
    final bool hasPhotos = logEntry.photoPaths.isNotEmpty;
    final bool hasPhotoNote = (logEntry.entry.photoNote ?? '').trim().isNotEmpty;
    if (!hasNote && !hasPhotos && !hasPhotoNote) {
      return;
    }

    final String dateLabel = formatDateLong(
      dateFromKey(logEntry.dateKey),
      widget.localeCode,
    );
    final bool confirm = await _showDeleteConfirmDialog(
      context: context,
      title: widget.localeCode == 'id' ? 'Hapus update' : 'Delete update',
      message: widget.localeCode == 'id'
          ? 'Hapus update pada $dateLabel?'
          : 'Delete update on $dateLabel?',
      cancelLabel: t.cancel,
      confirmLabel: t.delete,
    );
    if (!confirm) {
      return;
    }

    ProgressEntryModel workingEntry = logEntry.entry;
    if ((workingEntry.notes ?? '').trim().isNotEmpty) {
      await ref
          .read(activityActionsProvider)
          .removeNoteFromEntry(entry: workingEntry);
      workingEntry = workingEntry.copyWith(
        clearNotes: true,
        updatedAt: DateTime.now(),
      );
    }

    if (hasPhotos) {
      for (final String path in logEntry.photoPaths) {
        await ref.read(imageStorageServiceProvider).deleteImageAtPath(path);
      }
      await ref
          .read(activityActionsProvider)
          .removePhotoFromEntry(entry: workingEntry);
    } else if (hasPhotoNote) {
      await ref
          .read(activityActionsProvider)
          .removePhotoNoteFromEntry(entry: workingEntry);
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.localeCode == 'id' ? 'Update dihapus.' : 'Update deleted.',
        ),
      ),
    );
  }

  List<ProgressEntryModel> _orderedEntries(List<ProgressEntryModel> entries) {
    return List<ProgressEntryModel>.from(entries)
      ..sort((ProgressEntryModel a, ProgressEntryModel b) {
        return b.dateKey.compareTo(a.dateKey);
      });
  }

  List<String> _photoPathsForEntry(ProgressEntryModel entry) {
    final List<String> normalized = entry.photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    if (normalized.isEmpty &&
        entry.photoPath != null &&
        entry.photoPath!.trim().isNotEmpty) {
      normalized.add(entry.photoPath!.trim());
    }
    return normalized;
  }

  List<_DailyLogTimelineEntry> _buildDailyLogEntries(
    List<ProgressEntryModel> orderedEntries,
  ) {
    return orderedEntries.map((ProgressEntryModel entry) {
      final String noteText = (entry.notes ?? '').trim();
      final String legacyPhotoNote = (entry.photoNote ?? '').trim();
      if (noteText.isNotEmpty) {
        return _DailyLogTimelineEntry(
          entry: entry,
          dateKey: entry.dateKey,
          logText: noteText,
          textSource: _DailyLogTextSource.notes,
          photoPaths: _photoPathsForEntry(entry),
        );
      }
      if (legacyPhotoNote.isNotEmpty) {
        return _DailyLogTimelineEntry(
          entry: entry,
          dateKey: entry.dateKey,
          logText: legacyPhotoNote,
          textSource: _DailyLogTextSource.photoNote,
          photoPaths: _photoPathsForEntry(entry),
        );
      }
      return _DailyLogTimelineEntry(
        entry: entry,
        dateKey: entry.dateKey,
        logText: '',
        textSource: _DailyLogTextSource.none,
        photoPaths: _photoPathsForEntry(entry),
      );
    }).toList();
  }

  List<_DailyLogTimelineEntry> _filteredLogEntries(
    List<_DailyLogTimelineEntry> orderedLogs,
  ) {
    final DateTime today = dateOnly(DateTime.now());
    final int? dayCount = switch (_range) {
      _ComparisonRange.last7 => 7,
      _ComparisonRange.last30 => 30,
      _ComparisonRange.all => null,
    };
    final DateTime? threshold =
        dayCount == null ? null : today.subtract(Duration(days: dayCount - 1));

    return orderedLogs.where((_DailyLogTimelineEntry logEntry) {
      final bool hasSignal =
          logEntry.logText.isNotEmpty || logEntry.photoPaths.isNotEmpty;
      if (!hasSignal) {
        return false;
      }

      if (threshold == null) {
        return true;
      }
      final DateTime day = dateOnly(dateFromKey(logEntry.dateKey));
      return !day.isBefore(threshold);
    }).toList();
  }

  List<_GalleryPhotoCandidate> _buildComparisonCandidates(
    List<_DailyLogTimelineEntry> orderedLogs,
  ) {
    return <_GalleryPhotoCandidate>[
      for (final _DailyLogTimelineEntry logEntry in orderedLogs)
        if (logEntry.photoPaths.isNotEmpty)
          _GalleryPhotoCandidate(
            dateKey: logEntry.dateKey,
            paths: logEntry.photoPaths,
            logNote: logEntry.logText.isEmpty ? null : logEntry.logText,
          ),
    ];
  }

  Future<bool> _showDeleteConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirm == true;
  }
}

class _ComparisonRangeSwitcher extends StatelessWidget {
  const _ComparisonRangeSwitcher({
    required this.selected,
    required this.sevenDaysLabel,
    required this.thirtyDaysLabel,
    required this.allLabel,
    required this.onChanged,
  });

  final _ComparisonRange selected;
  final String sevenDaysLabel;
  final String thirtyDaysLabel;
  final String allLabel;
  final ValueChanged<_ComparisonRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadius.button);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.62,
          ),
          borderRadius: radius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: SizedBox(
            height: 42,
            child: Stack(
              children: <Widget>[
                AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  alignment: switch (selected) {
                    _ComparisonRange.last7 => Alignment.centerLeft,
                    _ComparisonRange.last30 => Alignment.center,
                    _ComparisonRange.all => Alignment.centerRight,
                  },
                  child: FractionallySizedBox(
                    widthFactor: 1 / 3,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ComparisonRangeSwitchItem(
                        selected: selected == _ComparisonRange.last7,
                        label: sevenDaysLabel,
                        onTap: () => onChanged(_ComparisonRange.last7),
                      ),
                    ),
                    Expanded(
                      child: _ComparisonRangeSwitchItem(
                        selected: selected == _ComparisonRange.last30,
                        label: thirtyDaysLabel,
                        onTap: () => onChanged(_ComparisonRange.last30),
                      ),
                    ),
                    Expanded(
                      child: _ComparisonRangeSwitchItem(
                        selected: selected == _ComparisonRange.all,
                        label: allLabel,
                        onTap: () => onChanged(_ComparisonRange.all),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonRangeSwitchItem extends StatelessWidget {
  const _ComparisonRangeSwitchItem({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final Color inactiveColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.72,
    );
    final Color selectedTextColor = theme.colorScheme.primary.withValues(
      alpha: 0.9,
    );

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return accent.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return accent.withValues(alpha: 0.04);
          }
          return null;
        }),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? selectedTextColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineEntryPhotoPreview extends StatefulWidget {
  const _TimelineEntryPhotoPreview({
    required this.paths,
    required this.localeCode,
    required this.dateKey,
    required this.compareCandidates,
  });

  final List<String> paths;
  final String localeCode;
  final String dateKey;
  final List<_GalleryPhotoCandidate> compareCandidates;

  @override
  State<_TimelineEntryPhotoPreview> createState() =>
      _TimelineEntryPhotoPreviewState();
}

class _TimelineEntryPhotoPreviewState
    extends State<_TimelineEntryPhotoPreview> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => _openGallery(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Stack(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.paths.length,
                onPageChanged: (int value) {
                  setState(() {
                    _index = value;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return OptimizedFileImage(
                    path: widget.paths[index],
                    fit: BoxFit.cover,
                    logicalCacheWidth: MediaQuery.sizeOf(context).width,
                    logicalCacheHeight: MediaQuery.sizeOf(context).width * 0.56,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.paths.length > 1)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${_index + 1}/${widget.paths.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      t.viewAllPhotoAction,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGallery(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoGalleryViewerPage(
          paths: widget.paths,
          localeCode: widget.localeCode,
          dateKey: widget.dateKey,
          initialIndex: _index,
          compareCandidates: widget.compareCandidates,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class _PhotoGalleryViewerPage extends StatefulWidget {
  const _PhotoGalleryViewerPage({
    required this.paths,
    required this.localeCode,
    required this.dateKey,
    required this.initialIndex,
    required this.compareCandidates,
  });

  final List<String> paths;
  final String localeCode;
  final String dateKey;
  final int initialIndex;
  final List<_GalleryPhotoCandidate> compareCandidates;

  @override
  State<_PhotoGalleryViewerPage> createState() =>
      _PhotoGalleryViewerPageState();
}

class _PhotoGalleryViewerPageState extends State<_PhotoGalleryViewerPage> {
  late final PageController _controller;
  late int _index;

  bool _canCompareAcrossDate() {
    if (widget.compareCandidates.isEmpty || widget.paths.isEmpty) {
      return false;
    }
    return widget.compareCandidates.any((_GalleryPhotoCandidate candidate) {
      return candidate.dateKey != widget.dateKey && candidate.paths.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.paths.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final bool canCompareAcrossDate = _canCompareAcrossDate();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          formatDateLong(dateFromKey(widget.dateKey), widget.localeCode),
        ),
        actions: <Widget>[
          if (canCompareAcrossDate)
            IconButton(
              tooltip: t.comparisonPhotoDialogTitle,
              onPressed: _openCompareFromCurrent,
              icon: const Icon(Icons.compare_arrows_rounded),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: OptimizedFileImage(
                    path: widget.paths[_index],
                    fit: BoxFit.cover,
                    logicalCacheWidth: MediaQuery.sizeOf(context).width,
                    logicalCacheHeight: MediaQuery.sizeOf(context).height,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.black);
                    },
                  ),
                ),
                Container(color: Colors.black.withValues(alpha: 0.46)),
                PhotoViewGallery.builder(
                  pageController: _controller,
                  itemCount: widget.paths.length,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (int value) {
                    setState(() {
                      _index = value;
                    });
                  },
                  builder: (BuildContext context, int index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: FileImage(File(widget.paths[index])),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained * 0.9,
                      maxScale: PhotoViewComputedScale.covered * 4.2,
                    );
                  },
                  loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
                if (widget.paths.length > 1)
                  Positioned(
                    right: 16,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '${_index + 1}/${widget.paths.length}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: <Widget>[
                  const Spacer(),
                  if (canCompareAcrossDate)
                    FilledButton.tonalIcon(
                      onPressed: _openCompareFromCurrent,
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: Text(t.comparisonPhotoDialogTitle),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCompareFromCurrent() async {
    final AppLocalizations t = AppLocalizations.of(context)!;
    _GalleryPhotoCandidate? firstCandidate;
    for (final _GalleryPhotoCandidate candidate in widget.compareCandidates) {
      if (candidate.dateKey == widget.dateKey) {
        firstCandidate = candidate;
        break;
      }
    }
    final List<_GalleryPhotoCandidate> candidates = <_GalleryPhotoCandidate>[
      for (final _GalleryPhotoCandidate candidate in widget.compareCandidates)
        if (candidate.dateKey != widget.dateKey && candidate.paths.isNotEmpty)
          candidate,
    ];
    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.comparisonNeedTwoPhotos)));
      }
      return;
    }

    final _GalleryPhotoCandidate? target =
        await showModalBottomSheet<_GalleryPhotoCandidate>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                title: Text(t.comparisonSecondSelection),
                subtitle: Text(t.comparisonTargetLabel),
              ),
              ...candidates.map((_GalleryPhotoCandidate candidate) {
                final String dateLabel = formatDateLong(
                  dateFromKey(candidate.dateKey),
                  widget.localeCode,
                );
                final String firstFile = candidate.paths.first;
                final String fileName = firstFile.contains('\\')
                    ? firstFile.split('\\').last
                    : firstFile.split('/').last;
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: OptimizedFileImage(
                        path: firstFile,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image_rounded),
                      ),
                    ),
                  ),
                  title: Text(dateLabel),
                  subtitle: Text(
                    '${candidate.paths.length} • $fileName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(bottomSheetContext).pop(candidate),
                );
              }),
            ],
          ),
        );
      },
    );
    if (!mounted || target == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoCompareViewerPage(
          firstPaths: widget.paths,
          firstDateKey: widget.dateKey,
          firstPhotoNote: firstCandidate?.bestNote,
          secondPaths: target.paths,
          secondDateKey: target.dateKey,
          secondPhotoNote: target.bestNote,
          localeCode: widget.localeCode,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class _PhotoCompareViewerPage extends StatelessWidget {
  const _PhotoCompareViewerPage({
    required this.firstPaths,
    required this.firstDateKey,
    required this.firstPhotoNote,
    required this.secondPaths,
    required this.secondDateKey,
    required this.secondPhotoNote,
    required this.localeCode,
  });

  final List<String> firstPaths;
  final String firstDateKey;
  final String? firstPhotoNote;
  final List<String> secondPaths;
  final String secondDateKey;
  final String? secondPhotoNote;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(t.comparisonPhotoDialogTitle),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useRow = constraints.maxWidth >= 860;
            final Widget first = _ZoomableComparePane(
              label:
                  '${t.comparisonFirstSelection} - ${formatDateLong(dateFromKey(firstDateKey), localeCode)}',
              paths: firstPaths,
              note: firstPhotoNote,
            );
            final Widget second = _ZoomableComparePane(
              label:
                  '${t.comparisonSecondSelection} - ${formatDateLong(dateFromKey(secondDateKey), localeCode)}',
              paths: secondPaths,
              note: secondPhotoNote,
            );
            if (useRow) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: first),
                    const SizedBox(width: 12),
                    Expanded(child: second),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                children: <Widget>[
                  Expanded(child: first),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(child: second),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ZoomableComparePane extends StatefulWidget {
  const _ZoomableComparePane({
    required this.label,
    required this.paths,
    required this.note,
  });

  final String label;
  final List<String> paths;
  final String? note;

  @override
  State<_ZoomableComparePane> createState() => _ZoomableComparePaneState();
}

class _ZoomableComparePaneState extends State<_ZoomableComparePane> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.paths.length;
    final String? note = widget.note?.trim();
    final bool hasNote = note != null && note.isNotEmpty;
    if (total == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
                if (total > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      '${_index + 1}/$total',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          if (hasNote)
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.16)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 18,
                          sigmaY: 18,
                        ),
                        child: OptimizedFileImage(
                          path: widget.paths[_index],
                          fit: BoxFit.cover,
                          logicalCacheWidth: MediaQuery.sizeOf(context).width,
                          logicalCacheHeight:
                              MediaQuery.sizeOf(context).height,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey.shade900);
                          },
                        ),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.34)),
                      PhotoViewGallery.builder(
                        pageController: _controller,
                        itemCount: widget.paths.length,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        scrollPhysics: const BouncingScrollPhysics(),
                        onPageChanged: (int value) {
                          setState(() {
                            _index = value;
                          });
                        },
                        builder: (BuildContext context, int index) {
                          return PhotoViewGalleryPageOptions(
                            imageProvider: FileImage(File(widget.paths[index])),
                            initialScale: PhotoViewComputedScale.contained,
                            minScale: PhotoViewComputedScale.contained * 0.9,
                            maxScale: PhotoViewComputedScale.covered * 4.0,
                          );
                        },
                        loadingBuilder:
                            (BuildContext context, ImageChunkEvent? event) {
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomWeeklyBarChart extends StatelessWidget {
  const _CustomWeeklyBarChart({
    required this.days,
    required this.localeCode,
  });

  final List<_ScheduledDaySnapshot> days;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime todayDate = dateOnly(DateTime.now());

    const double maxBarH = 108.0;
    const double pctLabelH = 14.0;
    const double pctToBarGap = 4.0;
    const double barToDayGap = 10.0;
    const double dayLabelH = 20.0;
    const double chartH =
        pctLabelH + pctToBarGap + maxBarH + barToDayGap + dayLabelH;

    return SizedBox(
      height: chartH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(days.length, (int index) {
          final _ScheduledDaySnapshot day = days[index];
          final double rate = day.progressRate.clamp(0.0, 1.0).toDouble();
          final bool isToday = dateOnly(day.date) == todayDate;
          final bool hasData = day.isScheduled;

          final Color barColor;
          if (!hasData) {
            barColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.2);
          } else if (rate == 0) {
            barColor = const Color(0xFFBA1A1A);
          } else if (rate < 1.0) {
            barColor = const Color(0xFFF59E0B);
          } else {
            barColor = const Color(0xFF1A5BAD);
          }

          final double fillH =
              rate > 0 ? maxBarH * rate.clamp(0.05, 1.0) : (hasData ? 4.0 : 0.0);
          final int pct = (rate * 100).round();

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isToday ? 1.0 : 2.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    height: pctLabelH,
                    child: hasData && rate > 0
                        ? Text(
                            '$pct%',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday
                                  ? barColor
                                  : barColor.withValues(alpha: 0.68),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: pctToBarGap),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        height: maxBarH,
                        decoration: BoxDecoration(
                          color: isToday
                              ? barColor.withValues(alpha: 0.09)
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: fillH),
                        duration: Duration(milliseconds: 450 + (index * 60)),
                        curve: Curves.easeOutCubic,
                        builder: (BuildContext ctx, double h, _) {
                          if (h < 1) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            width: double.infinity,
                            height: h,
                            decoration: BoxDecoration(
                              gradient: rate > 0.05
                                  ? LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: <Color>[
                                        barColor,
                                        barColor.withValues(alpha: 0.48),
                                      ],
                                    )
                                  : null,
                              color: rate <= 0.05
                                  ? barColor.withValues(alpha: 0.55)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isToday && rate > 0
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color:
                                            barColor.withValues(alpha: 0.42),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: h > 18
                                ? Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: barToDayGap),
                  SizedBox(
                    height: dayLabelH,
                    child: isToday
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                weekdayShortLabel(
                                    day.date.weekday, localeCode),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: barColor,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              weekdayShortLabel(day.date.weekday, localeCode),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ActivityHeroCard extends StatelessWidget {
  const _ActivityHeroCard({
    required this.scheduleText,
    required this.summaryText,
    required this.progressPercent,
    required this.progressRate,
    required this.currentStreak,
    required this.streakText,
    required this.progressState,
    required this.visualStatus,
    required this.localeCode,
  });

  final String scheduleText;
  final String summaryText;
  final int progressPercent;
  final double progressRate;
  final int currentStreak;
  final String streakText;
  final ActivityProgressState progressState;
  final ActivityDailyProgressStatus visualStatus;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isMissed = visualStatus == ActivityDailyProgressStatus.missed;
    final bool isNotStarted = visualStatus == ActivityDailyProgressStatus.future;
    final bool isCompleted = visualStatus == ActivityDailyProgressStatus.done;
    final bool isPartial = visualStatus == ActivityDailyProgressStatus.partial;
    final Color statusColor =
        activityStatusColor(theme: theme, status: visualStatus);
    final String displayStatusText = isMissed
        ? (localeCode == 'id' ? 'Tidak selesai' : 'Not completed')
        : isNotStarted
            ? (localeCode == 'id' ? 'Belum mulai' : 'Not started')
            : isCompleted
                ? (localeCode == 'id' ? 'Selesai' : 'Completed')
                : isPartial
                    ? (progressPercent <= 0
                        ? (localeCode == 'id'
                            ? 'Sedang berlangsung'
                            : 'In progress')
                        : '$progressPercent%')
                    : activityStatusLabel(
                        status: visualStatus, localeCode: localeCode);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white,
            Color(0xFFF1F3FF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheduleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            summaryText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: 120,
                      height: 48,
                      decoration: BoxDecoration(
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.25),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      displayStatusText,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: displayStatusText.length > 12 ? 32 : 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                if (isPartial) ...<Widget>[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: progressRate,
                          backgroundColor: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.2),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        streakText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayStatusText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityAiInsightSection extends StatelessWidget {
  const _ActivityAiInsightSection({
    required this.data,
    required this.localeCode,
  });

  final _ActivityAiInsightData data;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = localeCode == 'id';

    String displayCautionText = data.caution;
    if (displayCautionText.startsWith('Hari yang paling sering berat:')) {
      displayCautionText = displayCautionText.replaceAll(
          'Hari yang paling sering berat:', 'Hari paling berat:');
    } else if (displayCautionText.startsWith('The hardest day so far:')) {
      displayCautionText =
          displayCautionText.replaceAll('The hardest day so far:', 'Hardest day:');
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isId ? 'INSIGHT AKTIVITAS' : 'ACTIVITY INSIGHT',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: <Widget>[
              _ActivityInsightMetricCard(
                title: data.dayMetricTitle,
                value: data.bestDayLabel,
              ),
              const SizedBox(height: 12),
              _ActivityInsightMetricCard(
                title: data.timeMetricTitle,
                value: data.bestTimeLabel,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 20),
          _ActivityInsightSuggestion(
            icon: Icons.lightbulb_outline_rounded,
            title: isId ? 'Rekomendasi' : 'Recommendation',
            body: data.recommendation,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _ActivityInsightSuggestion(
            icon: Icons.warning_amber_rounded,
            title: isId ? 'Perhatian' : 'Caution',
            body: displayCautionText,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

class _ActivityInsightMetricCard extends StatelessWidget {
  const _ActivityInsightMetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityInsightSuggestion extends StatelessWidget {
  const _ActivityInsightSuggestion({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubActivityChip extends StatelessWidget {
  const _SubActivityChip({
    required this.label,
    this.isSummary = false,
  });

  final String label;
  final bool isSummary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSummary
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSummary
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSummary
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
          fontWeight: isSummary ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivityDayPatternStat {
  const _ActivityDayPatternStat({
    required this.weekday,
    required this.scheduled,
    required this.completed,
    required this.incomplete,
  });

  final int weekday;
  final int scheduled;
  final int completed;
  final int incomplete;

  double get completionRate {
    if (scheduled == 0) {
      return 0;
    }
    return completed / scheduled;
  }
}

class _ActivityAiInsightData {
  const _ActivityAiInsightData({
    required this.heroLine,
    required this.headline,
    required this.body,
    required this.dayMetricTitle,
    required this.timeMetricTitle,
    required this.bestDayLabel,
    required this.bestTimeLabel,
    required this.caution,
    required this.recommendation,
  });

  final String heroLine;
  final String headline;
  final String body;
  final String dayMetricTitle;
  final String timeMetricTitle;
  final String bestDayLabel;
  final String bestTimeLabel;
  final String caution;
  final String recommendation;
}

class _ScheduledDaySnapshot {
  const _ScheduledDaySnapshot({
    required this.date,
    required this.isScheduled,
    required this.isCompleted,
    required this.countsTowardWeeklyCompletion,
    required this.progressRate,
    required this.visualState,
  });

  final DateTime date;
  final bool isScheduled;
  final bool isCompleted;
  final bool countsTowardWeeklyCompletion;
  final double progressRate;
  final WeeklyProgressDayVisualState visualState;
}

class _GalleryPhotoCandidate {
  const _GalleryPhotoCandidate({
    required this.dateKey,
    required this.paths,
    this.logNote,
  });

  final String dateKey;
  final List<String> paths;
  final String? logNote;

  String? get bestNote {
    final String? trimmed = logNote?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
 