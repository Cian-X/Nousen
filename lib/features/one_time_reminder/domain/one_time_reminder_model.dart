class OneTimeReminderModel {
  const OneTimeReminderModel({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.scheduledAt,
    this.scheduledEndAt,
    this.categoryId = 'other',
    this.description = '',
    this.subActivities = const <String>[],
    this.completedSubActivities = const <String>[],
    required this.preReminderMinutes,
    required this.isNotificationEnabled,
    required this.isCompleted,
    this.isSkipped = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String iconKey;
  final DateTime scheduledAt;
  final DateTime? scheduledEndAt;
  final String categoryId;
  final String description;
  final List<String> subActivities;
  final List<String> completedSubActivities;
  final int preReminderMinutes;
  final bool isNotificationEnabled;
  final bool isCompleted;
  final bool isSkipped;
  final DateTime createdAt;
  final DateTime updatedAt;

  OneTimeReminderModel copyWith({
    String? id,
    String? title,
    String? iconKey,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
    bool clearScheduledEndAt = false,
    String? categoryId,
    String? description,
    List<String>? subActivities,
    List<String>? completedSubActivities,
    int? preReminderMinutes,
    bool? isNotificationEnabled,
    bool? isCompleted,
    bool? isSkipped,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OneTimeReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      scheduledEndAt: clearScheduledEndAt
          ? null
          : (scheduledEndAt ?? this.scheduledEndAt),
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      subActivities: subActivities ?? this.subActivities,
      completedSubActivities:
          completedSubActivities ?? this.completedSubActivities,
      preReminderMinutes: preReminderMinutes ?? this.preReminderMinutes,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      isSkipped: isSkipped ?? this.isSkipped,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
