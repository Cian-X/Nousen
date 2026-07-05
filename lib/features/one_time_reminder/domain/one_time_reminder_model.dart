class OneTimeReminderModel {
  const OneTimeReminderModel({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.scheduledAt,
    required this.preReminderMinutes,
    required this.isNotificationEnabled,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String iconKey;
  final DateTime scheduledAt;
  final int preReminderMinutes;
  final bool isNotificationEnabled;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  OneTimeReminderModel copyWith({
    String? id,
    String? title,
    String? iconKey,
    DateTime? scheduledAt,
    int? preReminderMinutes,
    bool? isNotificationEnabled,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OneTimeReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      preReminderMinutes: preReminderMinutes ?? this.preReminderMinutes,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
