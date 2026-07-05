import 'package:isar/isar.dart';
import 'package:liburan_create/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_repository.dart';

class IsarOneTimeReminderRepository implements OneTimeReminderRepository {
  IsarOneTimeReminderRepository(this._isar);

  final Isar _isar;

  @override
  Stream<List<OneTimeReminderModel>> watchAll() {
    return _isar.oneTimeReminderEntitys
        .where()
        .watch(fireImmediately: true)
        .map((List<OneTimeReminderEntity> entities) {
          final List<OneTimeReminderModel> items = entities
              .map((OneTimeReminderEntity item) => item.toDomain())
              .toList();
          items.sort((OneTimeReminderModel a, OneTimeReminderModel b) {
            return a.scheduledAt.compareTo(b.scheduledAt);
          });
          return items;
        });
  }

  @override
  Future<List<OneTimeReminderModel>> getAll() async {
    final List<OneTimeReminderEntity> entities = await _isar
        .oneTimeReminderEntitys
        .where()
        .findAll();
    final List<OneTimeReminderModel> items = entities
        .map((OneTimeReminderEntity item) => item.toDomain())
        .toList();
    items.sort((OneTimeReminderModel a, OneTimeReminderModel b) {
      return a.scheduledAt.compareTo(b.scheduledAt);
    });
    return items;
  }

  @override
  Future<OneTimeReminderModel?> getById(String id) async {
    final OneTimeReminderEntity? entity = await _isar.oneTimeReminderEntitys
        .filter()
        .idEqualTo(id)
        .findFirst();
    return entity?.toDomain();
  }

  @override
  Future<void> upsert(OneTimeReminderModel reminder) async {
    final OneTimeReminderEntity entity = oneTimeReminderEntityFromDomain(
      reminder,
    );
    await _isar.writeTxn(() async {
      await _isar.oneTimeReminderEntitys.put(entity);
    });
  }

  @override
  Future<void> delete(String id) async {
    final OneTimeReminderEntity? entity = await _isar.oneTimeReminderEntitys
        .filter()
        .idEqualTo(id)
        .findFirst();
    if (entity == null) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.oneTimeReminderEntitys.delete(entity.isarId);
    });
  }
}
