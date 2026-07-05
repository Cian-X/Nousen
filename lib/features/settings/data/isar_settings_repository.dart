import 'package:isar/isar.dart';
import 'package:liburan_create/features/settings/data/app_settings_entity.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/settings_repository.dart';

class IsarSettingsRepository implements SettingsRepository {
  IsarSettingsRepository(this._isar);

  final Isar _isar;

  @override
  Stream<AppSettingsModel> watch() {
    return _isar.appSettingsEntitys
        .where()
        .watch(fireImmediately: true)
        .asyncMap((_) => get());
  }

  @override
  Future<AppSettingsModel> get() async {
    AppSettingsEntity? entity = await _isar.appSettingsEntitys.get(1);
    if (entity != null) {
      return entity.toDomain();
    }

    final AppSettingsModel defaults = defaultSettingsModel();
    entity = settingsEntityFromDomain(defaults);
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.put(entity!);
    });
    return defaults;
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    final AppSettingsEntity entity = settingsEntityFromDomain(settings);
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.put(entity);
    });
  }
}
