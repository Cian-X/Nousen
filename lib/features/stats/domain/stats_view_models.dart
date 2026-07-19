import 'package:liburan_create/features/activity/domain/activity_model.dart';

class _StatsAiSummaryData {
  const _StatsAiSummaryData({
    required this.eyebrow,
    required this.headline,
    required this.body,
    this.support,
  });

  final String eyebrow;
  final String headline;
  final String body;
  final String? support;
}

class _ActivityHighlightsData {
  const _ActivityHighlightsData({
    required this.strongestTitle,
    required this.strongestDetail,
    required this.strugglingTitle,
    required this.strugglingDetail,
  });

  final String strongestTitle;
  final String strongestDetail;
  final String strugglingTitle;
  final String strugglingDetail;
}

class _HighlightCardData {
  const _HighlightCardData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
}

class _PeriodActivityStat {
  const _PeriodActivityStat({
    required this.activity,
    required this.scheduled,
    required this.completed,
  });

  final ActivityModel activity;
  final int scheduled;
  final int completed;

  int get incomplete => scheduled - completed;

  double get completionRate {
    if (scheduled == 0) return 0;
    return completed / scheduled;
  }

  _PeriodActivityStat copyWith({
    int? scheduled,
    int? completed,
  }) {
    return _PeriodActivityStat(
      activity: activity,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }
}

class _TimeBucketStat {
  const _TimeBucketStat({
    required this.key,
    required this.label,
    required this.scheduled,
    required this.completed,
  });

  final String key;
  final String label;
  final int scheduled;
  final int completed;

  double get completionRate {
    if (scheduled == 0) return 0;
    return completed / scheduled;
  }

  _TimeBucketStat copyWith({
    int? scheduled,
    int? completed,
  }) {
    return _TimeBucketStat(
      key: key,
      label: label,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }
}
