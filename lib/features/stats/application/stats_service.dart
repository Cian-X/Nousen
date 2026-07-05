import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';

class StatsService {
  GlobalStats buildGlobalStats({
    required List<ActivityModel> activities,
    required List<ProgressEntryModel> progressEntries,
    DateTime? now,
  }) {
    final DateTime today = dateOnly(now ?? DateTime.now());
    final DateTime weekStart = today.subtract(
      Duration(days: today.weekday - 1),
    );
    final Map<String, ProgressEntryModel> progressByActivityAndDate =
        <String, ProgressEntryModel>{};

    for (final ProgressEntryModel entry in progressEntries) {
      progressByActivityAndDate['${entry.activityId}|${entry.dateKey}'] = entry;
    }

    int totalScheduled = 0;
    int totalCompleted = 0;
    final List<ActivityBreakdown> breakdowns = <ActivityBreakdown>[];

    for (final ActivityModel activity in activities) {
      int scheduled = 0;
      int completed = 0;

      DateTime cursor = dateOnly(activity.createdAt);
      while (!cursor.isAfter(today)) {
        if (activity.selectedDays.contains(cursor.weekday)) {
          final String key = '${activity.id}|${dateKeyFromDate(cursor)}';
          final ProgressEntryModel? entry = progressByActivityAndDate[key];
          if (entry?.isSkipped == true) {
            cursor = cursor.add(const Duration(days: 1));
            continue;
          }
          scheduled++;
          if (entry?.isCompleted == true) {
            completed++;
          }
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      final int streak = _activityStreak(
        activity: activity,
        today: today,
        progressByKey: progressByActivityAndDate,
      );

      totalScheduled += scheduled;
      totalCompleted += completed;
      breakdowns.add(
        ActivityBreakdown(
          activity: activity,
          completedCount: completed,
          scheduledCount: scheduled,
          currentStreak: streak,
        ),
      );
    }

    final List<DailyCompletionPoint> last7Days = _buildLast7DayPoints(
      activities: activities,
      progressByKey: progressByActivityAndDate,
      today: today,
    );
    final List<HeatmapDayPoint> last28Days = _buildLast28DayPoints(
      activities: activities,
      progressByKey: progressByActivityAndDate,
      today: today,
    );

    final int globalStreak = _buildGlobalStreak(
      activities: activities,
      today: today,
      progressByKey: progressByActivityAndDate,
    );
    final StatsInsights insights = _buildInsights(
      activities: activities,
      progressEntries: progressEntries,
      breakdowns: breakdowns,
      progressByKey: progressByActivityAndDate,
      weekStart: weekStart,
    );

    breakdowns.sort((ActivityBreakdown a, ActivityBreakdown b) {
      return a.activity.title.compareTo(b.activity.title);
    });

    return GlobalStats(
      totalActivities: activities.length,
      totalCompleted: totalCompleted,
      totalScheduled: totalScheduled,
      globalStreak: globalStreak,
      last7Days: last7Days,
      last28Days: last28Days,
      breakdowns: breakdowns,
      insights: insights,
    );
  }

  int _activityStreak({
    required ActivityModel activity,
    required DateTime today,
    required Map<String, ProgressEntryModel> progressByKey,
  }) {
    int streak = 0;
    DateTime cursor = today;

    for (int i = 0; i < 365; i++) {
      if (!activity.selectedDays.contains(cursor.weekday)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      final String key = '${activity.id}|${dateKeyFromDate(cursor)}';
      final ProgressEntryModel? entry = progressByKey[key];
      if (entry?.isSkipped == true) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (entry?.isCompleted == true) {
        streak++;
      } else {
        break;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _buildGlobalStreak({
    required List<ActivityModel> activities,
    required DateTime today,
    required Map<String, ProgressEntryModel> progressByKey,
  }) {
    int streak = 0;
    DateTime cursor = today;

    for (int i = 0; i < 365; i++) {
      int scheduled = 0;
      int completed = 0;

      for (final ActivityModel activity in activities) {
        if (!activity.selectedDays.contains(cursor.weekday)) {
          continue;
        }
        if (cursor.isBefore(dateOnly(activity.createdAt))) {
          continue;
        }

        final String key = '${activity.id}|${dateKeyFromDate(cursor)}';
        final ProgressEntryModel? entry = progressByKey[key];
        if (entry?.isSkipped == true) {
          continue;
        }
        scheduled++;
        if (entry?.isCompleted == true) {
          completed++;
        }
      }

      if (scheduled == 0) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (completed == scheduled) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      break;
    }

    return streak;
  }

  List<DailyCompletionPoint> _buildLast7DayPoints({
    required List<ActivityModel> activities,
    required Map<String, ProgressEntryModel> progressByKey,
    required DateTime today,
  }) {
    final List<DailyCompletionPoint> points = <DailyCompletionPoint>[];
    for (int offset = 6; offset >= 0; offset--) {
      final DateTime day = today.subtract(Duration(days: offset));
      int scheduled = 0;
      int completed = 0;

      for (final ActivityModel activity in activities) {
        if (!activity.selectedDays.contains(day.weekday)) {
          continue;
        }
        if (day.isBefore(dateOnly(activity.createdAt))) {
          continue;
        }

        final String key = '${activity.id}|${dateKeyFromDate(day)}';
        final ProgressEntryModel? entry = progressByKey[key];
        if (entry?.isSkipped == true) {
          continue;
        }
        scheduled++;
        if (entry?.isCompleted == true) {
          completed++;
        }
      }

      points.add(
        DailyCompletionPoint(
          date: day,
          completedCount: completed,
          scheduledCount: scheduled,
        ),
      );
    }
    return points;
  }

  List<HeatmapDayPoint> _buildLast28DayPoints({
    required List<ActivityModel> activities,
    required Map<String, ProgressEntryModel> progressByKey,
    required DateTime today,
  }) {
    final List<HeatmapDayPoint> points = <HeatmapDayPoint>[];
    for (int offset = 27; offset >= 0; offset--) {
      final DateTime day = today.subtract(Duration(days: offset));
      int scheduled = 0;
      int completed = 0;

      for (final ActivityModel activity in activities) {
        if (!activity.selectedDays.contains(day.weekday)) {
          continue;
        }
        if (day.isBefore(dateOnly(activity.createdAt))) {
          continue;
        }

        final String key = '${activity.id}|${dateKeyFromDate(day)}';
        final ProgressEntryModel? entry = progressByKey[key];
        if (entry?.isSkipped == true) {
          continue;
        }
        scheduled++;
        if (entry?.isCompleted == true) {
          completed++;
        }
      }

      points.add(
        HeatmapDayPoint(
          date: day,
          completedCount: completed,
          scheduledCount: scheduled,
        ),
      );
    }
    return points;
  }

  ({int scheduled, int completed}) _countGlobalInRange({
    required List<ActivityModel> activities,
    required DateTime from,
    required DateTime to,
    required Map<String, ProgressEntryModel> progressByKey,
  }) {
    int scheduled = 0;
    int completed = 0;
    DateTime cursor = dateOnly(from);
    final DateTime end = dateOnly(to);

    while (!cursor.isAfter(end)) {
      for (final ActivityModel activity in activities) {
        if (cursor.isBefore(dateOnly(activity.createdAt)) ||
            !activity.selectedDays.contains(cursor.weekday)) {
          continue;
        }

        final String key = '${activity.id}|${dateKeyFromDate(cursor)}';
        final ProgressEntryModel? entry = progressByKey[key];
        if (entry?.isSkipped == true) {
          continue;
        }
        scheduled++;
        if (entry?.isCompleted == true) {
          completed++;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return (scheduled: scheduled, completed: completed);
  }

  StatsInsights _buildInsights({
    required List<ActivityModel> activities,
    required List<ProgressEntryModel> progressEntries,
    required List<ActivityBreakdown> breakdowns,
    required Map<String, ProgressEntryModel> progressByKey,
    required DateTime weekStart,
  }) {
    final Map<String, ActivityModel> activityById = <String, ActivityModel>{
      for (final ActivityModel activity in activities) activity.id: activity,
    };
    final Map<int, int> hourFrequency = <int, int>{};

    for (final ProgressEntryModel entry in progressEntries) {
      if (!entry.isCompleted) {
        continue;
      }
      final ActivityModel? activity = activityById[entry.activityId];
      if (activity == null) {
        continue;
      }
      final int minutes = activity.timeMinutes;
      hourFrequency[minutes] = (hourFrequency[minutes] ?? 0) + 1;
    }

    int? bestHourMinutes;
    int bestHourCount = -1;
    for (final MapEntry<int, int> item in hourFrequency.entries) {
      if (item.value > bestHourCount) {
        bestHourMinutes = item.key;
        bestHourCount = item.value;
      }
    }

    String? mostMissedActivityTitle;
    int mostMissedCount = 0;
    for (final ActivityBreakdown breakdown in breakdowns) {
      final int missed = breakdown.scheduledCount - breakdown.completedCount;
      if (missed > mostMissedCount) {
        mostMissedCount = missed;
        mostMissedActivityTitle = breakdown.activity.title;
      }
    }
    if (mostMissedCount <= 0) {
      mostMissedActivityTitle = null;
    }

    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final DateTime previousWeekStart = weekStart.subtract(
      const Duration(days: 7),
    );
    final DateTime previousWeekEnd = weekStart.subtract(
      const Duration(days: 1),
    );

    final ({int scheduled, int completed}) thisWeek = _countGlobalInRange(
      activities: activities,
      from: weekStart,
      to: weekEnd,
      progressByKey: progressByKey,
    );
    final ({int scheduled, int completed}) previousWeek = _countGlobalInRange(
      activities: activities,
      from: previousWeekStart,
      to: previousWeekEnd,
      progressByKey: progressByKey,
    );

    final double thisWeekRate = thisWeek.scheduled == 0
        ? 0
        : thisWeek.completed / thisWeek.scheduled;
    final double previousWeekRate = previousWeek.scheduled == 0
        ? 0
        : previousWeek.completed / previousWeek.scheduled;

    return StatsInsights(
      bestHourMinutes: bestHourMinutes,
      mostMissedActivityTitle: mostMissedActivityTitle,
      mostMissedCount: mostMissedCount,
      thisWeekRate: thisWeekRate,
      previousWeekRate: previousWeekRate,
    );
  }
}

class GlobalScheduledStatsCalculator {
  GlobalScheduledStatsCalculator({
    required List<ActivityModel> activities,
    required List<ProgressEntryModel> progressEntries,
    List<OneTimeReminderModel> oneTimeReminders =
        const <OneTimeReminderModel>[],
  }) : _activities = activities,
       _oneTimeReminders = oneTimeReminders,
       _progressByActivityAndDate = <String, ProgressEntryModel>{
         for (final ProgressEntryModel entry in progressEntries)
           '${entry.activityId}|${entry.dateKey}': entry,
       };

  final List<ActivityModel> _activities;
  final List<OneTimeReminderModel> _oneTimeReminders;
  final Map<String, ProgressEntryModel> _progressByActivityAndDate;

  List<DailyStat> getDailyStats(DateTime start, DateTime end) {
    final _DateRange range = _normalizeRange(start, end);
    final List<DailyStat> stats = <DailyStat>[];
    DateTime cursor = range.start;

    while (!cursor.isAfter(range.end)) {
      final ({int scheduled, int completed}) counts = _countAtDate(cursor);
      final bool isNeutral = counts.scheduled == 0;
      final double completionRate = isNeutral
          ? 0
          : counts.completed / counts.scheduled;

      stats.add(
        DailyStat(
          date: cursor,
          totalScheduled: counts.scheduled,
          totalCompleted: counts.completed,
          completionRate: completionRate,
          isNeutral: isNeutral,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return stats;
  }

  double getGlobalCompletionRate(DateTime start, DateTime end) {
    final List<DailyStat> dailyStats = getDailyStats(start, end);
    int sumScheduled = 0;
    int sumCompleted = 0;

    for (final DailyStat stat in dailyStats) {
      sumScheduled += stat.totalScheduled;
      sumCompleted += stat.totalCompleted;
    }

    if (sumScheduled == 0) {
      return 0;
    }

    return sumCompleted / sumScheduled;
  }

  ({int scheduled, int completed}) _countAtDate(DateTime date) {
    int scheduled = 0;
    int completed = 0;

    for (final ActivityModel activity in _activities) {
      if (date.isBefore(dateOnly(activity.createdAt)) ||
          !activity.selectedDays.contains(date.weekday)) {
        continue;
      }

      final String key = '${activity.id}|${dateKeyFromDate(date)}';
      final ProgressEntryModel? entry = _progressByActivityAndDate[key];
      if (entry?.isSkipped == true) {
        continue;
      }
      scheduled++;
      if (entry?.isCompleted == true) {
        completed++;
      }
    }

    for (final OneTimeReminderModel reminder in _oneTimeReminders) {
      if (!_isSameDay(reminder.scheduledAt, date)) {
        continue;
      }
      scheduled++;
      if (reminder.isCompleted) {
        completed++;
      }
    }

    return (scheduled: scheduled, completed: completed);
  }
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

_DateRange _normalizeRange(DateTime start, DateTime end) {
  final DateTime normalizedStart = dateOnly(start);
  final DateTime normalizedEnd = dateOnly(end);
  if (!normalizedStart.isAfter(normalizedEnd)) {
    return _DateRange(start: normalizedStart, end: normalizedEnd);
  }
  return _DateRange(start: normalizedEnd, end: normalizedStart);
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
