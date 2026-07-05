import 'package:isar/isar.dart';
import 'package:liburan_create/features/activity/data/activity_entity.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/activity/domain/activity_repository.dart';

class IsarActivityRepository implements ActivityRepository {
  IsarActivityRepository(this._isar);

  final Isar _isar;

  @override
  Stream<List<ActivityModel>> watchAll() {
    return _isar.activityEntitys.where().watch(fireImmediately: true).map((
      List<ActivityEntity> entities,
    ) {
      final List<ActivityModel> models = entities
          .map((ActivityEntity item) => item.toDomain())
          .toList();
      models.sort(
        (ActivityModel a, ActivityModel b) => a.title.compareTo(b.title),
      );
      return models;
    });
  }

  @override
  Future<List<ActivityModel>> getAll() async {
    final List<ActivityEntity> entities = await _isar.activityEntitys
        .where()
        .findAll();
    final List<ActivityModel> models = entities
        .map((ActivityEntity item) => item.toDomain())
        .toList();
    models.sort(
      (ActivityModel a, ActivityModel b) => a.title.compareTo(b.title),
    );
    return models;
  }

  @override
  Future<ActivityModel?> getById(String id) async {
    final ActivityEntity? entity = await _isar.activityEntitys
        .filter()
        .idEqualTo(id)
        .findFirst();
    return entity?.toDomain();
  }

  @override
  Future<void> upsert(ActivityModel activity) async {
    final ActivityEntity entity = activityEntityFromDomain(activity);
    await _isar.writeTxn(() async {
      await _isar.activityEntitys.put(entity);
    });
  }

  @override
  Future<void> delete(String id) async {
    final ActivityEntity? entity = await _isar.activityEntitys
        .filter()
        .idEqualTo(id)
        .findFirst();
    if (entity == null) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.activityEntitys.delete(entity.isarId);
    });
  }
}
