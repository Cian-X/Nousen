import 'package:liburan_create/features/settings/domain/app_settings_model.dart';

abstract class SettingsRepository {
  Stream<AppSettingsModel> watch();

  Future<AppSettingsModel> get();

  Future<void> save(AppSettingsModel settings);
}
