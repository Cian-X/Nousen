import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

enum ActivityProgressState { notStarted, partial, complete }

class ActivityProgressSummary {
  const ActivityProgressSummary({
    required this.completedSubActivities,
    required this.completedSubCount,
    required this.totalSubCount,
    required this.parentCompleted,
    required this.rate,
    required this.percent,
    required this.state,
  });

  final List<String> completedSubActivities;
  final int completedSubCount;
  final int totalSubCount;
  final bool parentCompleted;
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
      parentCompleted: false,
      rate: 0,
      percent: 0,
      state: ActivityProgressState.notStarted,
    );
  }

  if (subActivities.isEmpty) {
    final bool parentCompleted = entry?.status == ActivityDayStatus.done;
    final double rate = parentCompleted ? 1 : 0;
    final int percent = (rate * 100).round();
    return ActivityProgressSummary(
      completedSubActivities: const <String>[],
      completedSubCount: 0,
      totalSubCount: 0,
      parentCompleted: parentCompleted,
      rate: rate,
      percent: percent,
      state: _resolveActivityProgressState(percent),
    );
  }

  // Model induk-sebagai-unit: induk dihitung 1 unit + tiap sub 1 unit.
  // Sub selesai TIDAK otomatis menuntaskan induk; 100% hanya bila
  // induk dan semua sub selesai.
  final bool parentCompleted = entry?.status == ActivityDayStatus.done;
  final List<String> completedSubActivities = normalizeCompletedSubActivities(
    completedValues: entry?.completedSubActivities ?? const <String>[],
    subActivities: subActivities,
  );
  final int completedSubCount = completedSubActivities.length;
  final int totalSubCount = subActivities.length;
  final int doneUnits =
      (parentCompleted ? 1 : 0) + completedSubCount;
  final int totalUnits = 1 + totalSubCount;
  final double rawRate = (doneUnits / totalUnits).clamp(0.0, 1.0).toDouble();
  final int percent = (rawRate * 100).round();
  final double rate = percent / 100;

  return ActivityProgressSummary(
    completedSubActivities: completedSubActivities,
    completedSubCount: completedSubCount,
    totalSubCount: totalSubCount,
    parentCompleted: parentCompleted,
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
