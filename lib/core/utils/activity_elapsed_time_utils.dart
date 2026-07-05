class ActivityElapsedTimeState {
  const ActivityElapsedTimeState({
    required this.hasStarted,
    required this.elapsedMinutes,
    required this.isFixed,
  });

  final bool hasStarted;
  final int elapsedMinutes;
  final bool isFixed;
}

ActivityElapsedTimeState resolveActivityElapsedTimeState({
  required DateTime scheduledAt,
  required DateTime now,
  DateTime? completionTime,
}) {
  final DateTime effectiveEnd = completionTime ?? now;
  final int rawElapsedMinutes = effectiveEnd.difference(scheduledAt).inMinutes;
  return ActivityElapsedTimeState(
    hasStarted: completionTime != null || !now.isBefore(scheduledAt),
    elapsedMinutes: rawElapsedMinutes < 0 ? 0 : rawElapsedMinutes,
    isFixed: completionTime != null,
  );
}

String formatElapsedMinutesLabel(int elapsedMinutes) {
  final int safeMinutes = elapsedMinutes < 0 ? 0 : elapsedMinutes;
  return '${safeMinutes}m';
}
