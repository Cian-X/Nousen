enum NotificationActionId {
  openActivity('open_activity'),
  postponeTenMinutes('postpone_ten_minutes'),
  skipToday('skip_today');

  const NotificationActionId(this.value);

  final String value;

  static NotificationActionId? fromValue(String? value) {
    for (final NotificationActionId action in values) {
      if (action.value == value) {
        return action;
      }
    }
    return null;
  }
}
