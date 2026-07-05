import 'package:isar/isar.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';

part 'activity_entity.g.dart';

@collection
class ActivityEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  late String title;
  late List<int> selectedDays;
  late List<String> subActivities;
  late int timeMinutes;
  late int weeklyGoal;
  late int preReminderMinutes;
  late bool isNotificationEnabled;
  late bool enableMorningReminder;
  late bool enableEndOfDayReminder;
  late bool enablePhotoProgress;
  String? lastThreeDayRuleNotifiedDate;
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? scheduleUpdatedAt;
}

extension ActivityEntityMapper on ActivityEntity {
  ActivityModel toDomain() {
    return ActivityModel(
      id: id,
      title: title,
      selectedDays: selectedDays.toList()..sort(),
      subActivities: subActivities
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(),
      timeMinutes: timeMinutes,
      weeklyGoal: weeklyGoal,
      preReminderMinutes: preReminderMinutes,
      isNotificationEnabled: isNotificationEnabled,
      enableMorningReminder: enableMorningReminder,
      enableEndOfDayReminder: enableEndOfDayReminder,
      enablePhotoProgress: enablePhotoProgress,
      lastThreeDayRuleNotifiedDate: lastThreeDayRuleNotifiedDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      scheduleUpdatedAt: scheduleUpdatedAt ?? createdAt,
    );
  }
}

ActivityEntity activityEntityFromDomain(ActivityModel model) {
  final ActivityEntity entity = ActivityEntity()
    ..id = model.id
    ..title = model.title
    ..selectedDays = (model.selectedDays.toSet().toList()..sort())
    ..subActivities = model.subActivities
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList()
    ..timeMinutes = model.timeMinutes
    ..weeklyGoal = model.weeklyGoal
    ..preReminderMinutes = model.preReminderMinutes
    ..isNotificationEnabled = model.isNotificationEnabled
    ..enableMorningReminder = model.enableMorningReminder
    ..enableEndOfDayReminder = model.enableEndOfDayReminder
    ..enablePhotoProgress = model.enablePhotoProgress
    ..lastThreeDayRuleNotifiedDate = model.lastThreeDayRuleNotifiedDate
    ..createdAt = model.createdAt
    ..updatedAt = model.updatedAt
    ..scheduleUpdatedAt = model.scheduleUpdatedAt;
  return entity;
}
