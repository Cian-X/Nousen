import 'package:liburan_create/features/activity/domain/activity_model.dart';

abstract class ActivityRepository {
  Stream<List<ActivityModel>> watchAll();

  Future<List<ActivityModel>> getAll();

  Future<ActivityModel?> getById(String id);

  Future<void> upsert(ActivityModel activity);

  Future<void> delete(String id);
}
