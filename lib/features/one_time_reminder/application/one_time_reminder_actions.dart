import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:liburan_create/features/settings/domain/settings_repository.dart';
import 'package:liburan_create/services/notification_scheduler.dart';
import 'package:uuid/uuid.dart';

class OneTimeReminderActions {
  OneTimeReminderActions({
    required OneTimeReminderRepository repository,
    required SettingsRepository settingsRepository,
    required NotificationScheduler scheduler,
    Uuid? uuid,
  }) : _repository = repository,
       _settingsRepository = settingsRepository,
       _scheduler = scheduler,
       _uuid = uuid ?? const Uuid();

  final OneTimeReminderRepository _repository;
  final SettingsRepository _settingsRepository;
  final NotificationScheduler _scheduler;
  final Uuid _uuid;

  Future<void> saveReminder(OneTimeReminderModel reminder) async {
    final DateTime now = DateTime.now();
    final OneTimeReminderModel normalized = reminder.copyWith(updatedAt: now);
    await _repository.upsert(normalized);
    final settings = await _settingsRepository.get();
    await _scheduler.rescheduleOneTimeReminder(normalized, settings);
  }

  Future<void> deleteReminder(OneTimeReminderModel reminder) async {
    await _repository.delete(reminder.id);
    await _scheduler.cancelOneTimeReminder(reminder.id);
  }

  Future<void> toggleCompletion({
    required OneTimeReminderModel reminder,
    required bool completed,
  }) async {
    final OneTimeReminderModel updated = reminder.copyWith(
      isCompleted: completed,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    final settings = await _settingsRepository.get();
    await _scheduler.rescheduleOneTimeReminder(updated, settings);
  }

  Future<void> bootstrapReschedule() async {
    final List<OneTimeReminderModel> reminders = await _repository.getAll();
    final settings = await _settingsRepository.get();
    await _scheduler.rescheduleOneTimeReminders(reminders, settings);
  }

  OneTimeReminderModel buildNewDraft() {
    final DateTime now = DateTime.now();
    final DateTime rounded = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      ((now.minute + 14) ~/ 15) * 15,
    );

    final DateTime next = rounded.isAfter(now)
        ? rounded
        : rounded.add(const Duration(minutes: 15));

    return OneTimeReminderModel(
      id: _uuid.v4(),
      title: '',
      iconKey: 'calendar',
      scheduledAt: next,
      preReminderMinutes: 0,
      isNotificationEnabled: true,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
