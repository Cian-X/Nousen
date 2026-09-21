import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';

part 'app_settings_entity.g.dart';

@collection
class AppSettingsEntity {
  Id id = 1;

  late int morningReminderMinutes;
  late int endOfDayReminderMinutes;
  late String localeCode;
  late bool notificationsEnabled;
  String? profileName;
  String? profileAvatarPath;
  String? weeklyRoutineJson;
  int? wakeUpMinutes;
  int? sleepMinutes;
  int? usualBreakStartMinutes;
  int? usualBreakEndMinutes;
  bool? hasSeededData;
}

extension AppSettingsEntityMapper on AppSettingsEntity {
  AppSettingsModel toDomain() {
    final _DecodedSettingsPayload payload = _decodeSettingsPayload(
      weeklyRoutineJson,
    );
    return AppSettingsModel(
      morningReminderMinutes: morningReminderMinutes,
      endOfDayReminderMinutes: endOfDayReminderMinutes,
      localeCode: localeCode,
      notificationsEnabled: notificationsEnabled,
      notificationVibration: payload.notificationVibration,
      profileName: profileName,
      extraActivitiesNote: payload.extraActivitiesNote,
      profileAvatarPath: profileAvatarPath,
      weeklyRoutine: payload.routine,
      wakeUpMinutes: wakeUpMinutes,
      sleepMinutes: sleepMinutes,
      usualBreakStartMinutes: usualBreakStartMinutes,
      usualBreakEndMinutes: usualBreakEndMinutes,
      hasSeededData: payload.hasSeededData,
    );
  }
}

AppSettingsEntity settingsEntityFromDomain(AppSettingsModel model) {
  final AppSettingsEntity entity = AppSettingsEntity()
    ..id = 1
    ..morningReminderMinutes = model.morningReminderMinutes
    ..endOfDayReminderMinutes = model.endOfDayReminderMinutes
    ..localeCode = model.localeCode
    ..notificationsEnabled = model.notificationsEnabled
    ..profileName = model.profileName
    ..profileAvatarPath = model.profileAvatarPath
    ..weeklyRoutineJson = _encodeSettingsPayload(
      model.weeklyRoutine,
      model.extraActivitiesNote,
      model.hasSeededData,
      model.notificationVibration,
    )
    ..wakeUpMinutes = model.wakeUpMinutes
    ..sleepMinutes = model.sleepMinutes
    ..usualBreakStartMinutes = model.usualBreakStartMinutes
    ..usualBreakEndMinutes = model.usualBreakEndMinutes;
  return entity;
}

AppSettingsModel defaultSettingsModel() {
  return const AppSettingsModel(
    morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
    endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
    localeCode: AppConstants.localeId,
    notificationsEnabled: true,
  );
}

String? _encodeSettingsPayload(
  List<WeeklyRoutineDayProfile> routine,
  String? extraActivitiesNote,
  bool hasSeededData,
  bool notificationVibration,
) {
  final List<WeeklyRoutineDayProfile> normalized = normalizeWeeklyRoutine(routine);
  final String? trimmedNote = _normalizeNullableString(extraActivitiesNote);
  if (normalized.every((WeeklyRoutineDayProfile day) => day.kind == WeeklyRoutineDayKind.unspecified) &&
      trimmedNote == null &&
      !hasSeededData &&
      notificationVibration == true) {
    return null;
  }
  return jsonEncode(<String, dynamic>{
    'routine': normalized
        .map((WeeklyRoutineDayProfile day) => day.toJson())
        .toList(growable: false),
    'extraActivitiesNote': trimmedNote,
    'hasSeededData': hasSeededData,
    'notificationVibration': notificationVibration,
  });
}

_DecodedSettingsPayload _decodeSettingsPayload(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const _DecodedSettingsPayload(
      routine: kDefaultWeeklyRoutine,
      extraActivitiesNote: null,
      hasSeededData: false,
      notificationVibration: true,
    );
  }

  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is List) {
      return _DecodedSettingsPayload(
        routine: _decodeWeeklyRoutineEntries(decoded),
        extraActivitiesNote: null,
        hasSeededData: false,
        notificationVibration: true,
      );
    }
    if (decoded is Map) {
      final Object? rawRoutine = decoded['routine'];
      final Object? rawExtraActivitiesNote = decoded['extraActivitiesNote'];
      final Object? rawHasSeededData = decoded['hasSeededData'];
      final Object? rawNotificationVibration = decoded['notificationVibration'];
      return _DecodedSettingsPayload(
        routine: _decodeWeeklyRoutineEntries(rawRoutine),
        extraActivitiesNote: _normalizeNullableString(
          rawExtraActivitiesNote?.toString(),
        ),
        hasSeededData: rawHasSeededData == true,
        notificationVibration: rawNotificationVibration is bool ? rawNotificationVibration : true,
      );
    }
    return const _DecodedSettingsPayload(
      routine: kDefaultWeeklyRoutine,
      extraActivitiesNote: null,
      hasSeededData: false,
      notificationVibration: true,
    );
  } catch (_) {
    return const _DecodedSettingsPayload(
      routine: kDefaultWeeklyRoutine,
      extraActivitiesNote: null,
      hasSeededData: false,
      notificationVibration: true,
    );
  }
}

List<WeeklyRoutineDayProfile> _decodeWeeklyRoutineEntries(Object? raw) {
  if (raw is! List) {
    return kDefaultWeeklyRoutine;
  }

  final List<WeeklyRoutineDayProfile> routine = raw
      .whereType<Map>()
      .map(
        (Map item) => WeeklyRoutineDayProfile.fromJson(
          item.map(
            (Object? key, Object? value) =>
                MapEntry<String, dynamic>('${key ?? ''}', value),
          ),
        ),
      )
      .toList(growable: false);
  return normalizeWeeklyRoutine(routine);
}

String? _normalizeNullableString(String? raw) {
  final String trimmed = (raw ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _DecodedSettingsPayload {
  const _DecodedSettingsPayload({
    required this.routine,
    required this.extraActivitiesNote,
    required this.hasSeededData,
    this.notificationVibration = true,
  });

  final List<WeeklyRoutineDayProfile> routine;
  final String? extraActivitiesNote;
  final bool hasSeededData;
  final bool notificationVibration;
}
