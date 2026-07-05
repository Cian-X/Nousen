import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_progress_summary.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

enum ActivityDailyProgressStatus { done, partial, missed, skipped, future }

ActivityDailyProgressStatus resolveActivityDailyProgressStatus({
  required DateTime scheduledDate,
  required DateTime today,
  required DateTime scheduleUpdatedAt,
  List<String> subActivities = const <String>[],
  int? scheduledTimeMinutes,
  ProgressEntryModel? entry,
}) {
  final DateTime day = dateOnly(scheduledDate);
  final DateTime todayDate = dateOnly(today);
  final DateTime scheduleActiveFrom = dateOnly(scheduleUpdatedAt);

  // Priority:
  // 1) FUTURE, 2) SKIPPED, 3) DONE, 4) PARTIAL, 5) MISSED
  if (day.isAfter(todayDate) || day.isBefore(scheduleActiveFrom)) {
    return ActivityDailyProgressStatus.future;
  }

  if (entry?.status == ActivityDayStatus.skipped) {
    return ActivityDailyProgressStatus.skipped;
  }
  final ActivityProgressSummary progress = resolveActivityProgressSummary(
    subActivities: subActivities,
    entry: entry,
  );
  if (progress.isComplete) {
    return ActivityDailyProgressStatus.done;
  }
  if (progress.isPartial) {
    return ActivityDailyProgressStatus.partial;
  }
  if (day.isBefore(todayDate)) {
    return ActivityDailyProgressStatus.missed;
  }
  if (scheduledTimeMinutes != null && day == todayDate) {
    final int nowMinutes = today.hour * 60 + today.minute;
    if (nowMinutes >= scheduledTimeMinutes) {
      return ActivityDailyProgressStatus.partial;
    }
  }
  return ActivityDailyProgressStatus.future;
}
