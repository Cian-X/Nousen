import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';

abstract class OneTimeReminderRepository {
  Stream<List<OneTimeReminderModel>> watchAll();

  Future<List<OneTimeReminderModel>> getAll();

  Future<OneTimeReminderModel?> getById(String id);

  Future<void> upsert(OneTimeReminderModel reminder);

  Future<void> delete(String id);

  Stream<List<AgendaNoteModel>> watchNotes(String reminderId);

  Future<void> upsertNote(AgendaNoteModel note);

  Future<void> deleteNote(String id);
}
