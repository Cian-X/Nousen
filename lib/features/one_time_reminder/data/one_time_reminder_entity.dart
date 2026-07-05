import 'package:isar/isar.dart';
import 'package:liburan_create/core/utils/activity_icon_utils.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';

part 'one_time_reminder_entity.g.dart';

@collection
class OneTimeReminderEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  late String title;
  String? iconKey;
  late DateTime scheduledAt;
  late int preReminderMinutes;
  late bool isNotificationEnabled;
  late bool isCompleted;
  late DateTime createdAt;
  late DateTime updatedAt;
}

extension OneTimeReminderEntityMapper on OneTimeReminderEntity {
  OneTimeReminderModel toDomain() {
    return OneTimeReminderModel(
      id: id,
      title: title,
      iconKey: normalizeActivityIconKey(iconKey),
      scheduledAt: scheduledAt,
      preReminderMinutes: preReminderMinutes,
      isNotificationEnabled: isNotificationEnabled,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

OneTimeReminderEntity oneTimeReminderEntityFromDomain(
  OneTimeReminderModel model,
) {
  final OneTimeReminderEntity entity = OneTimeReminderEntity()
    ..id = model.id
    ..title = model.title
    ..iconKey = normalizeActivityIconKey(model.iconKey)
    ..scheduledAt = model.scheduledAt
    ..preReminderMinutes = model.preReminderMinutes
    ..isNotificationEnabled = model.isNotificationEnabled
    ..isCompleted = model.isCompleted
    ..createdAt = model.createdAt
    ..updatedAt = model.updatedAt;
  return entity;
}
