class ActivityModel {
  const ActivityModel({
    required this.id,
    required this.title,
    required this.selectedDays,
    required this.subActivities,
    required this.timeMinutes,
    required this.weeklyGoal,
    required this.preReminderMinutes,
    required this.isNotificationEnabled,
    required this.enableMorningReminder,
    required this.enableEndOfDayReminder,
    required this.enablePhotoProgress,
    required this.lastThreeDayRuleNotifiedDate,
    required this.createdAt,
    required this.updatedAt,
    this.scheduleUpdatedAt,
  });

  final String id;
  final String title;
  final List<int> selectedDays;
  final List<String> subActivities;
  final int timeMinutes;
  final int weeklyGoal;
  final int preReminderMinutes;
  final bool isNotificationEnabled;
  final bool enableMorningReminder;
  final bool enableEndOfDayReminder;
  final bool enablePhotoProgress;
  final String? lastThreeDayRuleNotifiedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduleUpdatedAt;

  ActivityModel copyWith({
    String? id,
    String? title,
    List<int>? selectedDays,
    List<String>? subActivities,
    int? timeMinutes,
    int? weeklyGoal,
    int? preReminderMinutes,
    bool? isNotificationEnabled,
    bool? enableMorningReminder,
    bool? enableEndOfDayReminder,
    bool? enablePhotoProgress,
    String? lastThreeDayRuleNotifiedDate,
    bool clearThreeDayRuleDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduleUpdatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      selectedDays: selectedDays ?? this.selectedDays,
      subActivities: subActivities ?? this.subActivities,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      preReminderMinutes: preReminderMinutes ?? this.preReminderMinutes,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      enableMorningReminder:
          enableMorningReminder ?? this.enableMorningReminder,
      enableEndOfDayReminder:
          enableEndOfDayReminder ?? this.enableEndOfDayReminder,
      enablePhotoProgress: enablePhotoProgress ?? this.enablePhotoProgress,
      lastThreeDayRuleNotifiedDate: clearThreeDayRuleDate
          ? null
          : (lastThreeDayRuleNotifiedDate ?? this.lastThreeDayRuleNotifiedDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduleUpdatedAt: scheduleUpdatedAt ?? this.scheduleUpdatedAt,
    );
  }
}
