import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/constants/ai_demo_config.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
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
import 'package:liburan_create/services/notification_action.dart';
import 'package:liburan_create/services/photo_access_service.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

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
  static final Set<String> _handledNotificationActions = <String>{};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final List<ActivityModel> activities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final ActivityModel? activity = _findActivity(activities, args.activityId);

    if (activity == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 64,
          leading: (ModalRoute.of(context)?.canPop ?? false)
              ? Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Center(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        icon: NousenNavIcon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          title: Text(t.activityDetail),
        ),
        body: Center(child: Text(t.activityNotFound)),
      );
    }

    final NotificationActionId? notificationAction =
        NotificationActionId.fromValue(args.notificationAction);
    final String notificationActionKey =
        '${activity.id}:${DateTime.now().toIso8601String().substring(0, 10)}:${args.notificationAction}';
    if ((notificationAction == NotificationActionId.skipToday ||
            notificationAction == NotificationActionId.postponeTenMinutes) &&
        _handledNotificationActions.add(notificationActionKey)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) {
          return;
        }
        if (notificationAction == NotificationActionId.skipToday) {
          await ref
              .read(activityActionsProvider)
              .skipToday(activity: activity, note: 'Lewati dari notifikasi');
        } else {
          await ref
              .read(notificationSchedulerProvider)
              .postponeActivityReminder(activity: activity);
        }
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notificationAction == NotificationActionId.skipToday
                  ? 'Aktivitas hari ini dilewati.'
                  : 'Pengingat ditunda 10 menit.',
            ),
          ),
        );
      });
    }

    final List<ProgressEntryModel> entries =
        ref.watch(progressByActivityProvider(activity.id)).value ??
        const <ProgressEntryModel>[];
    final ActivityBreakdown breakdown = ref
        .watch(statsServiceProvider)
        .buildSingleActivityBreakdown(activity: activity, entries: entries);
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
    final int currentStreak = breakdown.currentStreak;
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
    final bool isOnDeviceMlEnabled = AiDemoConfig.onDeviceMlEnabled;
    final _ActivityAiInsightData aiInsight = _buildActivityAiInsightData(
      activity: activity,
      entries: entries,
      breakdown: breakdown,
      localeCode: localeCode,
      today: today,
      mlPrediction: isOnDeviceMlEnabled
          ? ref
                .watch(activityDetailMlPredictionProvider(activity.id))
                .valueOrNull
          : null,
      predictionEnabled: isOnDeviceMlEnabled,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                icon: NousenNavIcon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
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
            icon: NousenNavIcon(
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
                  // Compact header: status pill + schedule + title + streak.
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: activityStatusColor(
                                  theme: theme,
                                  status: headerVisualStatus,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              activityStatusLabel(
                                status: headerVisualStatus,
                                localeCode: localeCode,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          headerScheduleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.02,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      NousenNavIcon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localeCode == 'id'
                            ? 'Streak $currentStreak hari'
                            : 'Streak $currentStreak days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 14,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activityStatusLabel(
                            status: todayVisualStatus,
                            localeCode: localeCode,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Cycle progress ring card (dinamis dari data sesi).
                  _CycleProgressCard(
                    completedSubCount: completedSubCount,
                    totalSubCount: totalSubCount,
                    parentCompleted: todayProgress.parentCompleted,
                    fallbackPercent: headerProgress.percent,
                    localeCode: localeCode,
                    status: todayVisualStatus,
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
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
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
                            t.subActivitiesProgress(
                              completedSubCount,
                              totalSubCount,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
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
                  const SizedBox(height: 12),
                  // AI insight: expander (konten widget yang sudah ada).
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          14,
                          0,
                          14,
                          14,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: NousenNavIcon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF4F46E5),
                            size: 16,
                          ),
                        ),
                        title: Text(
                          localeCode == 'id'
                              ? 'NOUSEN AI: Mempelajari ritme'
                              : 'NOUSEN AI: Learning rhythm',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        children: <Widget>[
                          _ActivityAiInsightSection(
                            data: aiInsight,
                            localeCode: localeCode,
                            activity: activity,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Timeline: navigasi ke halaman perbandingan yang sudah ada.
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: NousenNavIcon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF475569),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    localeCode == 'id'
                                        ? 'Timeline progres'
                                        : 'Progress timeline',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    localeCode == 'id'
                                        ? 'Lihat riwayat & catatan lalu'
                                        : 'View history & past notes',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            NousenNavIcon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        localeCode == 'id'
                            ? 'Progres mingguan'
                            : 'Weekly progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.05,
                          ),
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
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
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
                          timeMinutes: activity.timeMinutes,
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
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
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
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SessionNoteComposer(
                        localeCode: localeCode,
                        onPickPhotos: () => _pickDailyLogPhotoPaths(
                          context: context,
                          ref: ref,
                          localeCode: localeCode,
                        ),
                        onSave:
                            (
                              String note,
                              List<String> photoPaths,
                              List<String> sessionPickedPaths,
                            ) => _saveSessionComposerNote(
                              context: context,
                              ref: ref,
                              t: t,
                              localeCode: localeCode,
                              activity: activity,
                              existingEntry: todayEntry,
                              note: note,
                              photoPaths: photoPaths,
                              sessionPickedPaths: sessionPickedPaths,
                            ),
                      ),
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
      final bool isActiveScheduledDay =
          isScheduledDay &&
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
      final bool countsTowardWeeklyCompletion =
          isActiveScheduledDay &&
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
    required bool predictionEnabled,
  }) {
    final bool isId = localeCode == 'id';
    if (!predictionEnabled) {
      final String unavailable = isId
          ? 'Insight AI belum tersedia karena analisis ML sedang nonaktif.'
          : 'AI insight is unavailable while ML analysis is disabled.';
      return _ActivityAiInsightData(
        heroLine: unavailable,
        headline: isId ? 'Insight belum tersedia' : 'Insight unavailable',
        body: unavailable,
        dayMetricTitle: isId ? 'Pola hari' : 'Day pattern',
        timeMetricTitle: isId ? 'Waktu' : 'Time',
        bestDayLabel: isId ? 'Belum tersedia' : 'Unavailable',
        bestTimeLabel: isId ? 'Belum tersedia' : 'Unavailable',
        caution: unavailable,
        recommendation: unavailable,
        weakestDayLabel: null,
        suggestedTimeMinutes: activity.timeMinutes,
        patternDotsFilled: 0,
        trackerSubtitle: unavailable,
        chancePercent: null,
        predictionAvailable: false,
      );
    }
    final DateTime normalizedToday = dateOnly(today);
    final DateTime scheduleStart = dateOnly(
      activity.scheduleUpdatedAt ?? activity.createdAt,
    );
    final DateTime lookbackStart = normalizedToday.subtract(
      const Duration(days: 27),
    );
    final DateTime start = lookbackStart.isAfter(scheduleStart)
        ? lookbackStart
        : scheduleStart;
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
        final ActivityProgressSummary progress = resolveActivityProgressSummary(
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
    final List<_ActivityDayPatternStat> bestDayCandidates =
        weekdayStats.values
            .where((_ActivityDayPatternStat item) => item.completed > 0)
            .toList()
          ..sort((_ActivityDayPatternStat a, _ActivityDayPatternStat b) {
            final int byRate = b.completionRate.compareTo(a.completionRate);
            if (byRate != 0) {
              return byRate;
            }
            return b.completed.compareTo(a.completed);
          });
    final List<_ActivityDayPatternStat> weakestDayCandidates =
        weekdayStats.values
            .where((_ActivityDayPatternStat item) => item.incomplete > 0)
            .toList()
          ..sort((_ActivityDayPatternStat a, _ActivityDayPatternStat b) {
            final int byIncomplete = b.incomplete.compareTo(a.incomplete);
            if (byIncomplete != 0) {
              return byIncomplete;
            }
            return a.completionRate.compareTo(b.completionRate);
          });

    final _ActivityDayPatternStat? strongestDay = bestDayCandidates.isEmpty
        ? null
        : bestDayCandidates.first;
    final _ActivityDayPatternStat? weakestDay = weakestDayCandidates.isEmpty
        ? null
        : weakestDayCandidates.first;

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
      final String strongestBucket =
          ([...timeBucketCounts.entries]
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
      heroLine = isId
          ? 'Aktivitas ini mulai terbentuk'
          : 'This activity is taking shape';
      headline = isId
          ? 'Aktivitas ini sudah punya pola'
          : 'This activity already has a pattern';
      body = strongestDayLabel != null
          ? (isId
                ? 'Paling sering selesai saat dijalankan di $strongestDayLabel.'
                : 'It gets completed most often on $strongestDayLabel.')
          : (isId
                ? 'Progress-nya sudah mulai kebaca dari beberapa minggu terakhir.'
                : 'Its progress is starting to emerge from the past few weeks.');
    } else {
      heroLine = isId
          ? 'Aktivitas ini belum stabil'
          : 'This activity is not stable yet';
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
    String bestDayLabel =
        strongestDayLabel ??
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
      weakestDayLabel: weakestDayLabel,
      suggestedTimeMinutes:
          mlPrediction?.predictedTimeMinutes ?? activity.timeMinutes,
      patternDotsFilled: completed.clamp(0, 3),
      trackerSubtitle: strongestDay == null
          ? (isId ? '$scheduled sesi tercatat' : '$scheduled sessions logged')
          : (isId
                ? '$completed dari $scheduled selesai'
                : '$completed of $scheduled done'),
      chancePercent: strongestDay == null
          ? null
          : (strongestDay.completionRate * 100).round(),
      predictionAvailable: true,
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

    final _DailyLogUpdateDraft?
    draft = await showModalBottomSheet<_DailyLogUpdateDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final bool canSave =
                saveAsSkipped ||
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        minLines: 4,
                        maxLines: 6,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(hintText: t.noteInputHint),
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
                        icon: NousenNavIcon(Icons.camera_alt_rounded),
                        label: Text(t.addPhoto),
                      ),
                      if (draftPhotoPaths.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: draftPhotoPaths.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 54,
                                              height: 54,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              alignment: Alignment.center,
                                              child: NousenNavIcon(
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
                                        child: NousenNavIcon(
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

    final bool hasDraftChanges =
        draft.note.trim() != initialNote ||
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
      await ref
          .read(activityActionsProvider)
          .skipToday(
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

    final bool allowed = await ref
        .read(photoAccessServiceProvider)
        .ensureAccess(
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
      _DailyLogPhotoSource.gallery =>
        imageStorage.pickAndSaveImagesFromGallery(),
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
                  leading: NousenNavIcon(Icons.photo_camera_outlined),
                  title: Text(isId ? 'Ambil foto dari kamera' : 'Take photo'),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DailyLogPhotoSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: NousenNavIcon(Icons.photo_library_outlined),
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
      noteSaved = await ref
          .read(activityActionsProvider)
          .upsertNoteForDate(
            activity: activity,
            date: targetDate,
            notes: nextNote,
          );
    }

    int savedPhotoCount = 0;
    if (nextPhotoPaths.isNotEmpty &&
        (existingEntry == null || photosChanged || initialPhotoPaths.isEmpty)) {
      for (final String path in nextPhotoPaths) {
        await ref
            .read(activityActionsProvider)
            .upsertPhotoForDate(
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

  Future<bool> _saveSessionComposerNote({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations t,
    required String localeCode,
    required ActivityModel activity,
    required ProgressEntryModel? existingEntry,
    required String note,
    required List<String> photoPaths,
    required List<String> sessionPickedPaths,
  }) async {
    final String initialNote = (existingEntry?.notes ?? '').trim();
    final List<String> initialPhotoPaths = _normalizedPhotoPaths(existingEntry);
    final _DailyLogUpdateDraft draft = _DailyLogUpdateDraft(
      note: note.trim(),
      photoPaths: List<String>.from(photoPaths),
    );
    final bool hasDraftChanges =
        draft.note.trim() != initialNote ||
        !_haveSamePathSet(initialPhotoPaths, draft.photoPaths);
    if (!hasDraftChanges) {
      return false;
    }
    final bool confirm = await _showImmutableSaveWarningDialog(
      context: context,
      title: t.dataImmutableWarningTitle,
      message: draft.photoPaths.isNotEmpty
          ? t.photoSaveWarningMessage
          : t.noteSaveWarningMessage,
      cancelLabel: t.cancel,
      confirmLabel: localeCode == 'id' ? 'Simpan' : 'Save',
    );
    if (!confirm) {
      return false;
    }
    final _DailyLogSaveResult saveResult = await _saveDailyLogUpdateDraft(
      ref: ref,
      activity: activity,
      existingEntry: existingEntry,
      initialNote: initialNote,
      initialPhotoPaths: initialPhotoPaths,
      draft: draft,
    );
    final List<String> unusedSessionPhotos = sessionPickedPaths
        .where((String path) => !saveResult.keptPhotoPaths.contains(path))
        .toList();
    await _cleanupDraftPhotos(ref, unusedSessionPhotos);
    if (!context.mounted) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _buildDailyLogSaveMessage(
            localeCode: localeCode,
            noteProvided: saveResult.noteProvided,
            noteSaved: saveResult.noteSaved,
            savedPhotoCount: saveResult.savedPhotoCount,
          ),
        ),
      ),
    );
    return true;
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

class _SessionNoteComposer extends ConsumerStatefulWidget {
  const _SessionNoteComposer({
    required this.localeCode,
    required this.onPickPhotos,
    required this.onSave,
  });

  final String localeCode;
  final Future<List<String>> Function() onPickPhotos;
  final Future<bool> Function(
    String note,
    List<String> photoPaths,
    List<String> sessionPickedPaths,
  )
  onSave;

  @override
  ConsumerState<_SessionNoteComposer> createState() =>
      _SessionNoteComposerState();
}

class _SessionNoteComposerState extends ConsumerState<_SessionNoteComposer> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _photoPaths = <String>[];
  final Set<String> _sessionPickedPaths = <String>{};
  bool _pickingPhoto = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      (_controller.text.trim().isNotEmpty || _photoPaths.isNotEmpty);

  Future<void> _pickPhoto() async {
    if (_pickingPhoto) {
      return;
    }
    setState(() {
      _pickingPhoto = true;
    });
    try {
      final List<String> picked = await widget.onPickPhotos();
      if (!mounted) {
        return;
      }
      setState(() {
        for (final String path in picked) {
          final String cleanPath = path.trim();
          if (cleanPath.isEmpty) {
            continue;
          }
          _sessionPickedPaths.add(cleanPath);
          if (!_photoPaths.contains(cleanPath)) {
            _photoPaths.add(cleanPath);
          }
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _pickingPhoto = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_canSave) {
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final bool saved = await widget.onSave(
        _controller.text.trim(),
        List<String>.from(_photoPaths),
        _sessionPickedPaths.toList(),
      );
      if (!mounted || !saved) {
        return;
      }
      setState(() {
        _controller.clear();
        _photoPaths.clear();
        _sessionPickedPaths.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isId = widget.localeCode == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              isId ? 'Catatan Sesi' : 'Session Notes',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              isId ? 'Opsional' : 'Optional',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: isId
                      ? 'Tulis refleksi ringkas atau kendala hari ini...'
                      : 'Write a brief reflection or blocker today...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_photoPaths.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoPaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String path = _photoPaths[index];
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
                                  color: const Color(0xFFF1F5F9),
                                  alignment: Alignment.center,
                                  child: NousenNavIcon(
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
                                setState(() {
                                  _photoPaths.removeAt(index);
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: NousenNavIcon(
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _pickingPhoto ? null : _pickPhoto,
                      icon: NousenNavIcon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _canSave ? _submit : null,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isId ? 'Simpan' : 'Save',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                icon: NousenNavIcon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
        title: Text(
          t.comparisonTimelineTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          AppSpacing.screenPadding,
          AppSpacing.cardPadding,
          AppSpacing.screenPadding,
        ),
        children: <Widget>[
          _ComparisonTimelineSection(
            activityId: activityId,
            activityTitle: activityTitle,
            localeCode: localeCode,
          ),
        ],
      ),
    );
  }
}

class _RangeTriggerButton extends StatelessWidget {
  const _RangeTriggerButton({
    required this.localeCode,
    required this.onPickRange,
  });

  final String localeCode;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onPressed: onPickRange,
      icon: NousenNavIcon(
        Icons.date_range_rounded,
        size: 16,
        color: Color(0xFF2563EB),
      ),
      label: Text(
        localeCode == 'id' ? 'Rentang' : 'Range',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _RangeActiveChip extends StatelessWidget {
  const _RangeActiveChip({
    required this.localeCode,
    required this.customStart,
    required this.customEnd,
    required this.onClearRange,
  });

  final String localeCode;
  final DateTime customStart;
  final DateTime customEnd;
  final VoidCallback onClearRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${formatDateShort(customStart, localeCode)} - ${formatDateShort(customEnd, localeCode)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClearRange,
            behavior: HitTestBehavior.opaque,
            child: NousenNavIcon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineWeekStrip extends StatelessWidget {
  const _TimelineWeekStrip({
    required this.entries,
    required this.localeCode,
    required this.selectedDayKey,
    required this.onDaySelected,
    required this.displayDays,
    required this.navigationEnabled,
    required this.onWeekShift,
  });

  final List<ProgressEntryModel> entries;
  final String localeCode;
  final String? selectedDayKey;
  final ValueChanged<String> onDaySelected;
  final List<DateTime> displayDays;
  final bool navigationEnabled;
  final ValueChanged<int> onWeekShift;

  @override
  Widget build(BuildContext context) {
    final DateTime today = dateOnly(DateTime.now());
    final Map<String, ProgressEntryModel> byDate = <String, ProgressEntryModel>{
      for (final ProgressEntryModel e in entries) e.dateKey: e,
    };
    int doneDays = 0;
    final List<Widget> dayNodes = <Widget>[];
    for (final DateTime rawDay in displayDays) {
      final DateTime day = dateOnly(rawDay);
      final String dayKey = dateKeyFromDate(day);
      final bool isSelected = selectedDayKey == dayKey;
      final bool isToday =
          day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
      final bool isFuture = day.isAfter(today);
      final ProgressEntryModel? entry = byDate[dayKey];
      final bool isDone =
          entry != null && entry.status == ActivityDayStatus.done;
      if (isDone) doneDays++;
      final Color textColor = isToday
          ? Colors.white
          : isDone
          ? const Color(0xFF1D4ED8)
          : const Color(0xFF64748B);
      dayNodes.add(
        SizedBox(
          width: 52,
          child: GestureDetector(
            onTap: () => onDaySelected(dayKey),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  weekdayShortLabel(day.weekday, localeCode),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF2563EB)
                        : isDone
                        ? const Color(0xFFDBEAFE)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: const Color(0xFF1D4ED8), width: 2)
                        : (isToday
                              ? Border.all(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.25),
                                  width: 4,
                                )
                              : null),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDone && !isFuture
                        ? const Color(0xFF059669)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final int totalDays = displayDays.length;
    final DateTime firstDay = dateOnly(displayDays.first);
    final DateTime lastDay = dateOnly(displayDays.last);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _WeekNavButton(
              icon: Icons.chevron_left_rounded,
              enabled: navigationEnabled,
              onTap: () => onWeekShift(-1),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    '${formatDateShort(firstDay, localeCode)} - ${formatDateShort(lastDay, localeCode)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localeCode == 'id'
                        ? '$doneDays dari $totalDays hari'
                        : '$doneDays of $totalDays days',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            _WeekNavButton(
              icon: Icons.chevron_right_rounded,
              enabled: navigationEnabled,
              onTap: () => onWeekShift(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: dayNodes),
        ),
      ],
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  const _WeekNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        icon: NousenNavIcon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _ComparisonTimelineSection extends ConsumerStatefulWidget {
  const _ComparisonTimelineSection({
    required this.activityId,
    required this.activityTitle,
    required this.localeCode,
  });

  final String activityId;
  final String activityTitle;
  final String localeCode;

  @override
  ConsumerState<_ComparisonTimelineSection> createState() =>
      _ComparisonTimelineSectionState();
}

class _ComparisonTimelineSectionState
    extends ConsumerState<_ComparisonTimelineSection> {
  static const int _entriesPerPage = 5;

  String? _selectedDayKey;
  int _weekOffset = 0;
  DateTime? _customStart;
  DateTime? _customEnd;

  List<DateTime> _stripDisplayDays(DateTime weekMonday) {
    if (_customStart != null && _customEnd != null) {
      DateTime a = dateOnly(_customStart!);
      DateTime b = dateOnly(_customEnd!);
      if (b.isBefore(a)) {
        final DateTime t = a;
        a = b;
        b = t;
      }
      final int span = b.difference(a).inDays + 1;
      const int maxNodes = 62;
      final int count = span > maxNodes ? maxNodes : span;
      return List<DateTime>.generate(
        count,
        (int i) => a.add(Duration(days: i)),
        growable: false,
      );
    }
    return List<DateTime>.generate(
      7,
      (int i) => weekMonday.add(Duration(days: i)),
      growable: false,
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final DateTime today = dateOnly(DateTime.now());
    final DateTime weekBase = today;
    final DateTime defaultMonday = weekBase
        .subtract(Duration(days: weekBase.weekday - 1))
        .add(Duration(days: _weekOffset * 7));
    // Picker forbids initial dates after today; clamp the default week.
    final DateTime defaultStart = defaultMonday.isAfter(today)
        ? today
        : defaultMonday;
    final DateTime defaultEnd =
        defaultMonday.add(const Duration(days: 6)).isAfter(today)
        ? today
        : defaultMonday.add(const Duration(days: 6));
    final DateTimeRange initialRange =
        (_customStart != null && _customEnd != null)
        ? DateTimeRange(start: _customStart!, end: _customEnd!)
        : DateTimeRange(start: defaultStart, end: defaultEnd);
    // Satu dialog rentang: tap tanggal mulai, tap tanggal akhir, Terapkan.
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: initialRange,
      helpText: isId ? 'Pilih rentang tanggal' : 'Select date range',
      saveText: isId ? 'Terapkan' : 'Apply',
    );
    if (picked == null || !context.mounted) {
      return;
    }
    setState(() {
      _customStart = dateOnly(picked.start);
      _customEnd = dateOnly(picked.end);
      _selectedDayKey = null;
      _pageIndex = 0;
    });
  }

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
    final List<_DailyLogTimelineEntry> orderedLogs = _buildDailyLogEntries(
      orderedEntries,
    );
    final DateTime weekBase = dateOnly(DateTime.now());
    final DateTime weekMonday = weekBase
        .subtract(Duration(days: weekBase.weekday - 1))
        .add(Duration(days: _weekOffset * 7));
    final DateTime weekEnd = weekMonday.add(const Duration(days: 7));
    // Lingkup aktif: rentang kustom bila dipilih, else minggu tampil.
    DateTime scopeStart = weekMonday;
    DateTime scopeEnd = weekEnd;
    if (_customStart != null && _customEnd != null) {
      DateTime a = dateOnly(_customStart!);
      DateTime b = dateOnly(_customEnd!);
      if (b.isBefore(a)) {
        final DateTime t = a;
        a = b;
        b = t;
      }
      scopeStart = a;
      scopeEnd = b.add(const Duration(days: 1));
    }
    bool isInScope(String dateKey) {
      final DateTime day = dateOnly(dateFromKey(dateKey));
      return !day.isBefore(scopeStart) && day.isBefore(scopeEnd);
    }

    final List<_DailyLogTimelineEntry> scopeLogs = orderedLogs
        .where(
          (_DailyLogTimelineEntry logEntry) =>
              (logEntry.logText.isNotEmpty || logEntry.photoPaths.isNotEmpty) &&
              isInScope(logEntry.dateKey),
        )
        .toList();
    final List<_DailyLogTimelineEntry> filteredLogs = _selectedDayKey == null
        ? scopeLogs
        : scopeLogs
              .where(
                (_DailyLogTimelineEntry logEntry) =>
                    logEntry.dateKey == _selectedDayKey,
              )
              .toList();
    final int totalPages = filteredLogs.isEmpty
        ? 1
        : (filteredLogs.length / _entriesPerPage).ceil();
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
    // Metrik real lingkup tampil (tanpa angka karangan).
    final int totalSessions = scopeLogs.length;
    final int doneSessions = scopeLogs
        .where(
          (_DailyLogTimelineEntry log) =>
              log.entry.status == ActivityDayStatus.done,
        )
        .length;
    final int donePercent = totalSessions > 0
        ? ((doneSessions / totalSessions) * 100).round().clamp(0, 100)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Judul + kontrol rentang di pojok kanan.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                widget.activityTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _RangeTriggerButton(
              localeCode: widget.localeCode,
              onPickRange: () => _pickCustomRange(context),
            ),
          ],
        ),
        if (_customStart != null && _customEnd != null) ...<Widget>[
          const SizedBox(height: 8),
          _RangeActiveChip(
            localeCode: widget.localeCode,
            customStart: _customStart!,
            customEnd: _customEnd!,
            onClearRange: () {
              setState(() {
                _customStart = null;
                _customEnd = null;
                _pageIndex = 0;
              });
            },
          ),
        ],
        const SizedBox(height: 12),
        // Metrik terbuka: hanya yang ada datanya.
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$totalSessions',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.localeCode == 'id' ? 'Total Sesi' : 'Total Sessions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$donePercent%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.localeCode == 'id' ? 'Selesai' : 'Completed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Strip kalender mingguan (data real per tanggal).
        _TimelineWeekStrip(
          entries: entries,
          localeCode: widget.localeCode,
          selectedDayKey: _selectedDayKey,
          onDaySelected: (String dateKey) {
            setState(() {
              _selectedDayKey = _selectedDayKey == dateKey ? null : dateKey;
              _pageIndex = 0;
            });
          },
          displayDays: _stripDisplayDays(weekMonday),
          navigationEnabled: _customStart == null,
          onWeekShift: (int delta) {
            setState(() {
              _weekOffset += delta;
              _selectedDayKey = null;
              _pageIndex = 0;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              widget.localeCode == 'id' ? 'Catatan Sesi' : 'Session Notes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              widget.localeCode == 'id'
                  ? '$totalSessions sesi'
                  : '$totalSessions sessions',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredLogs.isEmpty)
          Text(
            _selectedDayKey == null
                ? t.comparisonEmpty
                : (widget.localeCode == 'id'
                      ? 'Belum ada catatan pada tanggal ini.'
                      : 'No notes on this date yet.'),
          )
        else
          ...pagedLogs.asMap().entries.map((
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
          }),
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
                  icon: NousenNavIcon(Icons.chevron_left_rounded),
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
                  icon: NousenNavIcon(Icons.chevron_right_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ],
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
    final ActivityDailyProgressStatus status =
        resolveActivityDailyProgressStatus(
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
                NousenNavIcon(
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
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: localTheme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
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
                        tooltip: widget.localeCode == 'id'
                            ? 'Opsi log'
                            : 'Log options',
                        icon: NousenNavIcon(
                          Icons.more_horiz_rounded,
                          color: localTheme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                        ),
                        onSelected: (_TimelineLogMenuAction action) {
                          WidgetsBinding.instance.addPostFrameCallback((
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
                          });
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
      noteSaved = await ref
          .read(activityActionsProvider)
          .upsertNoteForDate(
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
    final bool hasPhotoNote = (logEntry.entry.photoNote ?? '')
        .trim()
        .isNotEmpty;
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
                          child: NousenNavIcon(Icons.broken_image_rounded),
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
        leadingWidth: 64,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      icon: NousenNavIcon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Text(
          formatDateLong(dateFromKey(widget.dateKey), widget.localeCode),
        ),
        actions: <Widget>[
          if (canCompareAcrossDate)
            IconButton(
              tooltip: t.comparisonPhotoDialogTitle,
              onPressed: _openCompareFromCurrent,
              icon: NousenNavIcon(Icons.compare_arrows_rounded),
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
                  loadingBuilder:
                      (BuildContext context, ImageChunkEvent? event) {
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
                      icon: NousenNavIcon(Icons.compare_arrows_rounded),
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
                                NousenNavIcon(Icons.broken_image_rounded),
                          ),
                        ),
                      ),
                      title: Text(dateLabel),
                      subtitle: Text(
                        '${candidate.paths.length} • $fileName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          Navigator.of(bottomSheetContext).pop(candidate),
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
        leadingWidth: 64,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      icon: NousenNavIcon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              )
            : null,
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
                          logicalCacheHeight: MediaQuery.sizeOf(context).height,
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
    required this.timeMinutes,
  });

  final List<_ScheduledDaySnapshot> days;
  final String localeCode;
  final int timeMinutes;

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
          final DateTime now = DateTime.now();
          final bool dueToday =
              isToday &&
              hasData &&
              rate < 1.0 &&
              (now.hour * 60 + now.minute) >= timeMinutes;

          // Warna mengikuti status tanggal, bukan mentah-anyar rate:
          // masa depan → abu-abu; hari ini belum waktunya → abu-abu;
          // sudah waktunya/parsial → amber; selesai → biru;
          // merah hanya untuk hari lewat yang tak dikerjakan.
          final Color barColor;
          if (!hasData) {
            barColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.2);
          } else {
            barColor = switch (day.visualState) {
              WeeklyProgressDayVisualState.notScheduled => theme
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.2),
              WeeklyProgressDayVisualState.future =>
                theme.habitColors.inactive,
              WeeklyProgressDayVisualState.complete =>
                theme.habitColors.completed,
              WeeklyProgressDayVisualState.partial =>
                theme.habitColors.pending,
              WeeklyProgressDayVisualState.missed =>
                theme.habitColors.missed,
              WeeklyProgressDayVisualState.pending => dueToday
                  ? theme.habitColors.pending
                  : theme.habitColors.inactive,
            };
          }

          final double fillH = rate > 0
              ? maxBarH * rate.clamp(0.05, 1.0)
              : (hasData ? 4.0 : 0.0);
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
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: barColor,
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
                              color: barColor,
                              borderRadius: BorderRadius.circular(12),
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
                                weekdayShortLabel(day.date.weekday, localeCode),
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

class _CycleProgressCard extends StatelessWidget {
  const _CycleProgressCard({
    required this.completedSubCount,
    required this.totalSubCount,
    required this.parentCompleted,
    required this.fallbackPercent,
    required this.localeCode,
    required this.status,
  });

  final int completedSubCount;
  final int totalSubCount;
  final bool parentCompleted;
  final int fallbackPercent;
  final String localeCode;
  final ActivityDailyProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasSubs = totalSubCount > 0;
    // Model induk-sebagai-unit: induk 1 unit + tiap sub 1 unit.
    final int percent = hasSubs
        ? ((((parentCompleted ? 1 : 0) + completedSubCount) / (1 + totalSubCount)) * 100)
              .round()
              .clamp(0, 100)
        : fallbackPercent.clamp(0, 100);
    // Warna mengikuti status tanggal aktual, bukan angka mentah:
    // belum mulai → abu-abu; berlangsung → amber; selesai → biru;
    // merah hanya bila benar terlewat.
    final Color statusColor = switch (status) {
      ActivityDailyProgressStatus.done => theme.habitColors.completed,
      ActivityDailyProgressStatus.partial => theme.habitColors.pending,
      ActivityDailyProgressStatus.missed => theme.habitColors.missed,
      ActivityDailyProgressStatus.skipped ||
      ActivityDailyProgressStatus.future => theme.habitColors.inactive,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 112,
                  height: 112,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 10,
                    backgroundColor:
                        statusColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'TARGET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  localeCode == 'id'
                      ? 'Progres Siklus Aktivitas'
                      : 'Activity Cycle Progress',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSubs
                      ? (localeCode == 'id'
                            ? '$completedSubCount dari $totalSubCount sub-aktivitas selesai'
                            : '$completedSubCount of $totalSubCount sub-activities done')
                      : (localeCode == 'id'
                            ? 'Progres sesi berjalan'
                            : 'Session progress'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (hasSubs) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    children: List<Widget>.generate(
                      totalSubCount,
                      (int i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: i == totalSubCount - 1 ? 0 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: i < completedSubCount
                                ? statusColor
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      growable: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityAiInsightSection extends ConsumerStatefulWidget {
  const _ActivityAiInsightSection({
    required this.data,
    required this.localeCode,
    required this.activity,
  });

  final _ActivityAiInsightData data;
  final String localeCode;
  final ActivityModel activity;

  @override
  ConsumerState<_ActivityAiInsightSection> createState() =>
      _ActivityAiInsightSectionState();
}

class _ActivityAiInsightSectionState
    extends ConsumerState<_ActivityAiInsightSection> {
  bool _applying = false;

  String _bucketLabel(int minutes, String localeCode) {
    final bool isId = localeCode == 'id';
    final String key;
    if (minutes >= 5 * 60 && minutes < 11 * 60) {
      key = 'morning';
    } else if (minutes >= 11 * 60 && minutes < 15 * 60) {
      key = 'midday';
    } else if (minutes >= 15 * 60 && minutes < 18 * 60) {
      key = 'afternoon';
    } else {
      key = 'night';
    }
    return switch (key) {
      'morning' => isId ? 'Pagi' : 'Morning',
      'midday' => isId ? 'Siang' : 'Midday',
      'afternoon' => isId ? 'Sore' : 'Afternoon',
      _ => isId ? 'Malam' : 'Night',
    };
  }

  Future<void> _applySuggestedSchedule() async {
    if (_applying) {
      return;
    }
    setState(() {
      _applying = true;
    });
    try {
      await ref
          .read(activityActionsProvider)
          .saveActivity(
            widget.activity.copyWith(
              timeMinutes: widget.data.suggestedTimeMinutes,
              scheduleUpdatedAt: DateTime.now(),
            ),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.localeCode == 'id'
                ? 'Jadwal diperbarui ke ${formatMinutesAsTime(widget.data.suggestedTimeMinutes)}.'
                : 'Schedule updated to ${formatMinutesAsTime(widget.data.suggestedTimeMinutes)}.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _applying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = widget.localeCode == 'id';
    final _ActivityAiInsightData data = widget.data;
    if (!data.predictionAvailable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          data.body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }

    String displayCautionText = data.caution;
    if (displayCautionText.startsWith('Hari yang paling sering berat:')) {
      displayCautionText = displayCautionText.replaceAll(
        'Hari yang paling sering berat:',
        'Hari paling berat:',
      );
    } else if (displayCautionText.startsWith('The hardest day so far:')) {
      displayCautionText = displayCautionText.replaceAll(
        'The hardest day so far:',
        'Hardest day:',
      );
    }

    final String suggestedBucketLabel = _bucketLabel(
      data.suggestedTimeMinutes,
      widget.localeCode,
    );
    final String suggestedTimeText = formatMinutesAsTime(
      data.suggestedTimeMinutes,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NousenNavIcon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  isId ? 'INSIGHT AKTIVITAS' : 'ACTIVITY INSIGHT',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                if (data.weakestDayLabel != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: NousenNavIcon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isId ? 'Sering tertunda pada' : 'Often delayed on',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          data.weakestDayLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                ],
                Row(
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: NousenNavIcon(
                        Icons.wb_sunny_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  '$suggestedBucketLabel • $suggestedTimeText',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isId ? 'Optimal' : 'Optimal',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isId
                                ? 'Waktu paling produktif'
                                : 'Most productive time',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data.chancePercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFA7F3D0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            NousenNavIcon(
                              Icons.trending_up_rounded,
                              size: 13,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isId
                                  ? 'Peluang ${data.chancePercent}%'
                                  : 'Chance ${data.chancePercent}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: NousenNavIcon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.bestDayLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.trackerSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(3, (int index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: index < data.patternDotsFilled
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isId ? 'CATATAN & ARAHAN' : 'NOTES & GUIDANCE',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: NousenNavIcon(
                        Icons.lightbulb_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: isId ? 'Rekomendasi: ' : 'Recommendation: ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: data.recommendation,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: NousenNavIcon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: isId ? 'Perhatian: ' : 'Caution: ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: displayCautionText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _applying ? null : _applySuggestedSchedule,
              child: _applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            isId
                                ? 'Terapkan Jadwal ke $suggestedBucketLabel ($suggestedTimeText)'
                                : 'Apply schedule to $suggestedBucketLabel ($suggestedTimeText)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        NousenNavIcon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SubActivityChip extends StatelessWidget {
  const _SubActivityChip({required this.label, this.isSummary = false});

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
    required this.weakestDayLabel,
    required this.suggestedTimeMinutes,
    required this.patternDotsFilled,
    required this.trackerSubtitle,
    required this.chancePercent,
    required this.predictionAvailable,
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

  /// Hari dengan hambatan terkuat (null bila belum ada pola). Dinamis.
  final String? weakestDayLabel;

  /// Menit waktu yang disarankan untuk CTA. Dinamis (prediksi ML atau jadwal).
  final int suggestedTimeMinutes;

  /// Jumlah dot terisi pada tracker pola (0-3), dari data selesai aktual.
  final int patternDotsFilled;

  /// Subjudul tracker pola dari hitungan sesi aktual.
  final String trackerSubtitle;

  /// Persen konsistensi hari terbaik (null bila belum ada pola). Dinamis.
  final int? chancePercent;
  final bool predictionAvailable;
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
