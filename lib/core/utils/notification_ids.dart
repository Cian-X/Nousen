enum NotificationType { main, preStart, morning, endOfDay, threeDayRule }

int notificationIdFor(String activityId, NotificationType type, int weekday) {
  final int typeCode = switch (type) {
    NotificationType.main => 1,
    NotificationType.preStart => 2,
    NotificationType.morning => 3,
    NotificationType.endOfDay => 4,
    NotificationType.threeDayRule => 5,
  };
  final int normalizedWeekday = (weekday >= 1 && weekday <= 7) ? weekday : 0;
  final int stableHash = _stableIdHash(activityId);

  // 31-bit deterministic ID layout:
  // [type:3 bits][weekday:3 bits][activityHash:20 bits]
  return ((typeCode & 0x7) << 23) |
      ((normalizedWeekday & 0x7) << 20) |
      (stableHash & 0x000FFFFF);
}

int threeDayRuleNotificationId(String activityId) {
  return notificationIdFor(activityId, NotificationType.threeDayRule, 0);
}

int oneTimeReminderNotificationId(String reminderId) {
  // 31-bit deterministic ID layout:
  // [type:3 bits][reserved:3 bits][entityHash:20 bits]
  const int oneTimeTypeCode = 6;
  final int stableHash = _stableIdHash('one-time:$reminderId');
  return ((oneTimeTypeCode & 0x7) << 23) | (stableHash & 0x000FFFFF);
}

int oneTimePreReminderNotificationId(String reminderId) {
  const int oneTimePreTypeCode = 7;
  final int stableHash = _stableIdHash('one-time-pre:$reminderId');
  return ((oneTimePreTypeCode & 0x7) << 23) | (stableHash & 0x000FFFFF);
}

int _stableIdHash(String input) {
  // Simple deterministic rolling hash (FNV-1a variant)
  int hash = 0x811C9DC5;
  for (final int codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
