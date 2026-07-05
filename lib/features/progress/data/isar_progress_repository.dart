import 'package:isar/isar.dart';
import 'package:liburan_create/features/progress/data/progress_entry_entity.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/progress/domain/progress_repository.dart';

class IsarProgressRepository implements ProgressRepository {
  IsarProgressRepository(this._isar);

  final Isar _isar;

  @override
  Stream<List<ProgressEntryModel>> watchAll() {
    return _isar.progressEntryEntitys.where().watch(fireImmediately: true).map((
      List<ProgressEntryEntity> entries,
    ) {
      final List<ProgressEntryModel> models = entries
          .map((ProgressEntryEntity item) => item.toDomain())
          .toList();
      models.sort((ProgressEntryModel a, ProgressEntryModel b) {
        return b.dateKey.compareTo(a.dateKey);
      });
      return models;
    });
  }

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) {
    return _isar.progressEntryEntitys
        .filter()
        .activityIdEqualTo(activityId)
        .watch(fireImmediately: true)
        .map((List<ProgressEntryEntity> entries) {
          final List<ProgressEntryModel> models = entries
              .map((ProgressEntryEntity item) => item.toDomain())
              .toList();
          models.sort((ProgressEntryModel a, ProgressEntryModel b) {
            return b.dateKey.compareTo(a.dateKey);
          });
          return models;
        });
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) {
    return _isar.progressEntryEntitys
        .filter()
        .dateKeyEqualTo(dateKey)
        .watch(fireImmediately: true)
        .map((List<ProgressEntryEntity> entries) {
          final List<ProgressEntryModel> models = entries
              .map((ProgressEntryEntity item) => item.toDomain())
              .toList();
          models.sort((ProgressEntryModel a, ProgressEntryModel b) {
            return a.activityId.compareTo(b.activityId);
          });
          return models;
        });
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) {
    return _isar.progressEntryEntitys
        .filter()
        .dateKeyBetween(fromDateKey, toDateKey)
        .watch(fireImmediately: true)
        .map((List<ProgressEntryEntity> entries) {
          final List<ProgressEntryModel> models = entries
              .map((ProgressEntryEntity item) => item.toDomain())
              .toList();
          models.sort((ProgressEntryModel a, ProgressEntryModel b) {
            return a.dateKey.compareTo(b.dateKey);
          });
          return models;
        });
  }

  @override
  Future<List<ProgressEntryModel>> getAll() async {
    final List<ProgressEntryEntity> entities = await _isar.progressEntryEntitys
        .where()
        .findAll();
    return entities.map((ProgressEntryEntity item) => item.toDomain()).toList();
  }

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async {
    final ProgressEntryEntity? entity = await _isar.progressEntryEntitys
        .filter()
        .activityIdEqualTo(activityId)
        .dateKeyEqualTo(dateKey)
        .findFirst();
    return entity?.toDomain();
  }

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    final ProgressEntryEntity entity = progressEntityFromDomain(entry);
    await _isar.writeTxn(() async {
      await _isar.progressEntryEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    final List<ProgressEntryEntity> entities = await _isar.progressEntryEntitys
        .filter()
        .activityIdEqualTo(activityId)
        .findAll();
    if (entities.isEmpty) {
      return;
    }
    final List<Id> ids = entities
        .map((ProgressEntryEntity item) => item.isarId)
        .toList();
    await _isar.writeTxn(() async {
      await _isar.progressEntryEntitys.deleteAll(ids);
    });
  }
}
