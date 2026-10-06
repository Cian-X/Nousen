import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';
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

  Future<void> skipReminder({
    required OneTimeReminderModel reminder,
  }) async {
    final OneTimeReminderModel updated = reminder.copyWith(
      isSkipped: true,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    await _scheduler.cancelOneTimeReminder(reminder.id);
  }

  Future<void> toggleSubActivity({
    required OneTimeReminderModel reminder,
    required String subActivity,
    required bool completed,
  }) async {
    if (!reminder.subActivities.contains(subActivity)) {
      return;
    }
    final Set<String> done = reminder.completedSubActivities.toSet();
    if (completed) {
      done.add(subActivity);
    } else {
      done.remove(subActivity);
    }
    final List<String> orderedDone = reminder.subActivities
        .where((String item) => done.contains(item))
        .toList();
    final OneTimeReminderModel updated = reminder.copyWith(
      completedSubActivities: orderedDone,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
  }

  Future<void> saveNote({
    required String reminderId,
    required String text,
    List<String> photoPaths = const <String>[],
    String? noteId,
  }) async {
    final String trimmed = text.trim();
    final List<String> photos = photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    if (trimmed.isEmpty && photos.isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    if (noteId == null) {
      await _repository.upsertNote(
        AgendaNoteModel(
          id: _uuid.v4(),
          reminderId: reminderId,
          text: trimmed,
          photoPaths: photos,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }
    final List<AgendaNoteModel> existing = await _repository
        .watchNotes(reminderId)
        .first;
    for (final AgendaNoteModel note in existing) {
      if (note.id == noteId) {
        await _repository.upsertNote(
          note.copyWith(text: trimmed, photoPaths: photos, updatedAt: now),
        );
        return;
      }
    }
  }

  Future<void> deleteNote({required String noteId}) async {
    await _repository.deleteNote(noteId);
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
