import 'package:liburan_create/features/activity/domain/activity_model.dart';

class DailyStat {
  const DailyStat({
    required this.date,
    required this.totalScheduled,
    required this.totalCompleted,
    required this.completionRate,
    required this.isNeutral,
  });

  final DateTime date;
  final int totalScheduled;
  final int totalCompleted;
  final double completionRate;
  final bool isNeutral;
}

class DailyCompletionPoint {
  const DailyCompletionPoint({
    required this.date,
    required this.completedCount,
    required this.scheduledCount,
  });

  final DateTime date;
  final int completedCount;
  final int scheduledCount;

  double get completionRate {
    if (scheduledCount == 0) {
      return 0;
    }
    return completedCount / scheduledCount;
  }
}

class HeatmapDayPoint {
  const HeatmapDayPoint({
    required this.date,
    required this.completedCount,
    required this.scheduledCount,
  });

  final DateTime date;
  final int completedCount;
  final int scheduledCount;

  double get completionRate {
    if (scheduledCount == 0) {
      return 0;
    }
    return completedCount / scheduledCount;
  }
}

class ActivityBreakdown {
  const ActivityBreakdown({
    required this.activity,
    required this.completedCount,
    required this.scheduledCount,
    required this.currentStreak,
  });

  final ActivityModel activity;
  final int completedCount;
  final int scheduledCount;
  final int currentStreak;

  double get completionRate {
    if (scheduledCount == 0) {
      return 0;
    }
    return completedCount / scheduledCount;
  }
}

class StatsInsights {
  const StatsInsights({
    required this.bestHourMinutes,
    required this.mostMissedActivityTitle,
    required this.mostMissedCount,
    required this.thisWeekRate,
    required this.previousWeekRate,
  });

  final int? bestHourMinutes;
  final String? mostMissedActivityTitle;
  final int mostMissedCount;
  final double thisWeekRate;
  final double previousWeekRate;

  double get weekDeltaRate => thisWeekRate - previousWeekRate;

  bool get isImproving => weekDeltaRate >= 0;

  bool get hasMostMissed =>
      mostMissedActivityTitle != null && mostMissedCount > 0;
}

class GlobalStats {
  const GlobalStats({
    required this.totalActivities,
    required this.totalCompleted,
    required this.totalScheduled,
    required this.globalStreak,
    required this.last7Days,
    required this.last28Days,
    required this.breakdowns,
    required this.insights,
  });

  final int totalActivities;
  final int totalCompleted;
  final int totalScheduled;
  final int globalStreak;
  final List<DailyCompletionPoint> last7Days;
  final List<HeatmapDayPoint> last28Days;
  final List<ActivityBreakdown> breakdowns;
  final StatsInsights insights;

  double get overallCompletionRate {
    if (totalScheduled == 0) {
      return 0;
    }
    return totalCompleted / totalScheduled;
  }
}
