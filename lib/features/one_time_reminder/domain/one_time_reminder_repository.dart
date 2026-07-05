import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';

abstract class OneTimeReminderRepository {
  Stream<List<OneTimeReminderModel>> watchAll();

  Future<List<OneTimeReminderModel>> getAll();

  Future<OneTimeReminderModel?> getById(String id);

  Future<void> upsert(OneTimeReminderModel reminder);

  Future<void> delete(String id);
}
