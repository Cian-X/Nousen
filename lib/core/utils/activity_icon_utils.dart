import 'package:flutter/material.dart';

class ActivityIconOption {
  const ActivityIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

const String defaultActivityIconKey = 'checklist';

const List<ActivityIconOption> activityIconOptions = <ActivityIconOption>[
  ActivityIconOption(
    key: 'checklist',
    icon: Icons.verified_rounded,
    label: 'Checklist',
  ),
  ActivityIconOption(
    key: 'fitness',
    icon: Icons.sports_gymnastics_rounded,
    label: 'Fitness',
  ),
  ActivityIconOption(
    key: 'study',
    icon: Icons.auto_stories_rounded,
    label: 'Study',
  ),
  ActivityIconOption(key: 'work', icon: Icons.work_rounded, label: 'Work'),
  ActivityIconOption(
    key: 'coding',
    icon: Icons.terminal_rounded,
    label: 'Coding',
  ),
  ActivityIconOption(key: 'walk', icon: Icons.hiking_rounded, label: 'Walk'),
  ActivityIconOption(
    key: 'sleep',
    icon: Icons.nights_stay_rounded,
    label: 'Sleep',
  ),
  ActivityIconOption(
    key: 'water',
    icon: Icons.water_drop_rounded,
    label: 'Hydration',
  ),
  ActivityIconOption(
    key: 'food',
    icon: Icons.lunch_dining_rounded,
    label: 'Meal',
  ),
  ActivityIconOption(
    key: 'meditation',
    icon: Icons.self_improvement_rounded,
    label: 'Meditation',
  ),
  ActivityIconOption(key: 'music', icon: Icons.piano_rounded, label: 'Music'),
  ActivityIconOption(
    key: 'heart',
    icon: Icons.favorite_rounded,
    label: 'Wellbeing',
  ),
];

String normalizeActivityIconKey(String? key) {
  final String normalized = key?.trim() ?? '';
  if (normalized.isEmpty) {
    return defaultActivityIconKey;
  }
  for (final ActivityIconOption option in activityIconOptions) {
    if (option.key == normalized) {
      return normalized;
    }
  }
  return defaultActivityIconKey;
}

IconData resolveActivityIcon(String? key) {
  final String normalized = normalizeActivityIconKey(key);
  for (final ActivityIconOption option in activityIconOptions) {
    if (option.key == normalized) {
      return option.icon;
    }
  }
  return Icons.verified_rounded;
}
