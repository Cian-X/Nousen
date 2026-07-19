import 'package:flutter/material.dart'; // Keep this for IconData
import 'package:liburan_create/features/activity/domain/activity_model.dart'; // For ActivityModel

class StatsAiSummaryData { // Renamed
  const StatsAiSummaryData({
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

class ActivityHighlightsData { // Renamed
  const ActivityHighlightsData({
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

class HighlightCardData { // Renamed
  const HighlightCardData({
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

class PeriodActivityStat { // Renamed
  const PeriodActivityStat({
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

  PeriodActivityStat copyWith({
    int? scheduled,
    int? completed,
  }) {
    return PeriodActivityStat(
      activity: activity,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }
}

class TimeBucketStat { // Renamed
  const TimeBucketStat({
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

  TimeBucketStat copyWith({
    int? scheduled,
    int? completed,
  }) {
    return TimeBucketStat(
      key: key,
      label: label,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }
}
