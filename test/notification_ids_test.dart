import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/core/utils/notification_ids.dart';

void main() {
  test('notification IDs are deterministic and unique across type/day', () {
    const String activityId = 'activity-123';

    final int mainMon = notificationIdFor(activityId, NotificationType.main, 1);
    final int mainTue = notificationIdFor(activityId, NotificationType.main, 2);
    final int preStartMon = notificationIdFor(
      activityId,
      NotificationType.preStart,
      1,
    );
    final int morningMon = notificationIdFor(
      activityId,
      NotificationType.morning,
      1,
    );
    final int endMon = notificationIdFor(
      activityId,
      NotificationType.endOfDay,
      1,
    );
    final int rule = threeDayRuleNotificationId(activityId);
    final int oneTime = oneTimeReminderNotificationId('one-time-1');
    final int oneTimePre = oneTimePreReminderNotificationId('one-time-1');

    expect(mainMon, notificationIdFor(activityId, NotificationType.main, 1));
    expect(mainMon, isNot(mainTue));
    expect(mainMon, isNot(preStartMon));
    expect(mainMon, isNot(morningMon));
    expect(mainMon, isNot(endMon));
    expect(mainMon, isNot(rule));
    expect(oneTime, oneTimeReminderNotificationId('one-time-1'));
    expect(oneTime, isNot(oneTimePre));
    expect(mainMon, isNot(oneTime));
  });
}
