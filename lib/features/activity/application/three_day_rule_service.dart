import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/activity/domain/activity_repository.dart';
import 'package:liburan_create/features/progress/domain/progress_repository.dart';
import 'package:liburan_create/services/notification_scheduler.dart';

class ThreeDayRuleService {
  ThreeDayRuleService({
    required ActivityRepository activityRepository,
    required ProgressRepository progressRepository,
    required NotificationScheduler scheduler,
  }) : _activityRepository = activityRepository,
       _progressRepository = progressRepository,
       _scheduler = scheduler;

  final ActivityRepository _activityRepository;
  final ProgressRepository _progressRepository;
  final NotificationScheduler _scheduler;

  Future<int> consecutiveMissedDays(
    ActivityModel activity, {
    DateTime? fromDate,
  }) async {
    final DateTime startDate = dateOnly(fromDate ?? DateTime.now());
    final DateTime activityStartDate = dateOnly(activity.createdAt);
    int missed = 0;
    DateTime cursor = startDate;

    for (int i = 0; i < 90; i++) {
      if (cursor.isBefore(activityStartDate)) {
        break;
      }

      final bool isScheduled = activity.selectedDays.contains(cursor.weekday);
      if (!isScheduled) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      final String key = dateKeyFromDate(cursor);
      final entry = await _progressRepository.getByActivityAndDate(
        activityId: activity.id,
        dateKey: key,
      );

      if (entry?.isSkipped == true) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (entry?.isCompleted == true) {
        break;
      }

      missed++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return missed;
  }

  Future<void> evaluateActivity(ActivityModel activity, {DateTime? now}) async {
    final DateTime currentTime = now ?? DateTime.now();
    final String todayKey = dateKeyFromDate(currentTime);
    final int missed = await consecutiveMissedDays(
      activity,
      fromDate: currentTime,
    );

    if (missed < 3 || activity.lastThreeDayRuleNotifiedDate == todayKey) {
      return;
    }

    await _scheduler.triggerThreeDayRuleNow(activity);
    await _activityRepository.upsert(
      activity.copyWith(
        lastThreeDayRuleNotifiedDate: todayKey,
        updatedAt: currentTime,
      ),
    );
  }

  Future<void> evaluateAll(
    List<ActivityModel> activities, {
    DateTime? now,
  }) async {
    for (final ActivityModel activity in activities) {
      await evaluateActivity(activity, now: now);
    }
  }
}
