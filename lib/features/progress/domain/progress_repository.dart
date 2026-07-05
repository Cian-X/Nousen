import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

abstract class ProgressRepository {
  Stream<List<ProgressEntryModel>> watchAll();

  Stream<List<ProgressEntryModel>> watchByActivity(String activityId);

  Stream<List<ProgressEntryModel>> watchByDate(String dateKey);

  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  });

  Future<List<ProgressEntryModel>> getAll();

  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  });

  Future<void> upsert(ProgressEntryModel entry);

  Future<void> deleteByActivity(String activityId);
}
