import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

enum ActivityProgressState { notStarted, partial, complete }

class ActivityProgressSummary {
  const ActivityProgressSummary({
    required this.completedSubActivities,
    required this.completedSubCount,
    required this.totalSubCount,
    required this.rate,
    required this.percent,
    required this.state,
  });

  final List<String> completedSubActivities;
  final int completedSubCount;
  final int totalSubCount;
  final double rate;
  final int percent;
  final ActivityProgressState state;

  bool get isComplete => state == ActivityProgressState.complete;
  bool get isPartial => state == ActivityProgressState.partial;
}

ActivityProgressSummary resolveActivityProgressSummary({
  required List<String> subActivities,
  ProgressEntryModel? entry,
}) {
  if (entry?.status == ActivityDayStatus.skipped) {
    return const ActivityProgressSummary(
      completedSubActivities: <String>[],
      completedSubCount: 0,
      totalSubCount: 0,
      rate: 0,
      percent: 0,
      state: ActivityProgressState.notStarted,
    );
  }

  if (subActivities.isEmpty) {
    final double rate = entry?.status == ActivityDayStatus.done ? 1 : 0;
    final int percent = (rate * 100).round();
    return ActivityProgressSummary(
      completedSubActivities: const <String>[],
      completedSubCount: 0,
      totalSubCount: 0,
      rate: rate,
      percent: percent,
      state: _resolveActivityProgressState(percent),
    );
  }

  final List<String> completedSubActivities = normalizeCompletedSubActivities(
    completedValues: entry?.completedSubActivities ?? const <String>[],
    subActivities: subActivities,
  );
  final int completedSubCount = completedSubActivities.length;
  final int totalSubCount = subActivities.length;
  final double rawRate = totalSubCount == 0
      ? 0
      : (completedSubCount / totalSubCount).clamp(0.0, 1.0).toDouble();
  final int percent = (rawRate * 100).round();
  final double rate = percent / 100;

  return ActivityProgressSummary(
    completedSubActivities: completedSubActivities,
    completedSubCount: completedSubCount,
    totalSubCount: totalSubCount,
    rate: rate,
    percent: percent,
    state: _resolveActivityProgressState(percent),
  );
}

List<String> normalizeCompletedSubActivities({
  required List<String> completedValues,
  required List<String> subActivities,
}) {
  if (subActivities.isEmpty) {
    return const <String>[];
  }
  final Set<String> completedSet = completedValues.toSet();
  return subActivities
      .where((String item) => completedSet.contains(item))
      .toList();
}

String activityProgressStateLabel({
  required ActivityProgressState state,
  required String localeCode,
}) {
  final bool isId = localeCode == 'id';
  return switch (state) {
    ActivityProgressState.notStarted => isId ? 'Belum mulai' : 'Not started',
    ActivityProgressState.partial => isId ? 'Sebagian' : 'Partial',
    ActivityProgressState.complete => isId ? 'Selesai' : 'Done',
  };
}

ActivityProgressState _resolveActivityProgressState(int percent) {
  if (percent >= 100) {
    return ActivityProgressState.complete;
  }
  if (percent > 0) {
    return ActivityProgressState.partial;
  }
  return ActivityProgressState.notStarted;
}
