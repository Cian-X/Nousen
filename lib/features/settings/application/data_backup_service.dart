import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:liburan_create/core/utils/activity_icon_utils.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/features/activity/data/activity_entity.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/activity/domain/activity_repository.dart';
import 'package:liburan_create/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:liburan_create/features/progress/data/progress_entry_entity.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/progress/domain/progress_repository.dart';
import 'package:liburan_create/features/settings/data/app_settings_entity.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/settings_repository.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DataBackupService {
  DataBackupService({
    required Isar isar,
    required ActivityRepository activityRepository,
    required OneTimeReminderRepository oneTimeReminderRepository,
    required ProgressRepository progressRepository,
    required SettingsRepository settingsRepository,
  }) : _isar = isar,
       _activityRepository = activityRepository,
       _oneTimeReminderRepository = oneTimeReminderRepository,
       _progressRepository = progressRepository,
       _settingsRepository = settingsRepository;

  final Isar _isar;
  final ActivityRepository _activityRepository;
  final OneTimeReminderRepository _oneTimeReminderRepository;
  final ProgressRepository _progressRepository;
  final SettingsRepository _settingsRepository;

  Future<String> exportBackupFile() async {
    final AppSettingsModel settings = await _settingsRepository.get();
    final List<ActivityModel> activities = await _activityRepository.getAll();
    final List<OneTimeReminderModel> oneTimeReminders =
        await _oneTimeReminderRepository.getAll();
    final List<ProgressEntryModel> progressEntries = await _progressRepository
        .getAll();

    final Map<String, dynamic> payload = <String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': _settingsToJson(settings),
      'activities': activities.map(_activityToJson).toList(),
      'oneTimeReminders': oneTimeReminders.map(_oneTimeToJson).toList(),
      'progressEntries': progressEntries.map(_progressToJson).toList(),
    };

    final Directory root = await getApplicationDocumentsDirectory();
    final Directory backupDir = Directory(p.join(root.path, 'backups'));
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final DateTime now = DateTime.now();
    final String filename =
        'reminder_schedule_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.json';
    final File file = File(p.join(backupDir.path, filename));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file.path;
  }

  Future<List<String>> listBackupFiles() async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory backupDir = Directory(p.join(root.path, 'backups'));
    if (!backupDir.existsSync()) {
      return <String>[];
    }

    final List<FileSystemEntity> entities = backupDir.listSync();
    final List<File> files =
        entities
            .whereType<File>()
            .where((File item) => item.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((File a, File b) {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          });
    return files.map((File item) => item.path).toList();
  }

  Future<void> importBackupFile(String path) async {
    final File file = File(path);
    final String raw = await file.readAsString();
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format');
    }

    final AppSettingsModel settings = _parseSettings(decoded['settings']);
    final List<ActivityModel> activities = _parseActivities(
      decoded['activities'],
    );
    final List<OneTimeReminderModel> oneTimeReminders = _parseOneTimeReminders(
      decoded['oneTimeReminders'],
    );
    final Set<String> activityIds = activities
        .map((ActivityModel item) => item.id)
        .toSet();
    final List<ProgressEntryModel> progressEntries =
        _parseProgressEntries(decoded['progressEntries']).where((
          ProgressEntryModel item,
        ) {
          return activityIds.contains(item.activityId);
        }).toList();

    await _isar.writeTxn(() async {
      await _isar.progressEntryEntitys.clear();
      await _isar.activityEntitys.clear();
      await _isar.oneTimeReminderEntitys.clear();
      await _isar.appSettingsEntitys.clear();

      await _isar.appSettingsEntitys.put(settingsEntityFromDomain(settings));
      if (activities.isNotEmpty) {
        await _isar.activityEntitys.putAll(
          activities.map(activityEntityFromDomain).toList(),
        );
      }
      if (oneTimeReminders.isNotEmpty) {
        await _isar.oneTimeReminderEntitys.putAll(
          oneTimeReminders.map(oneTimeReminderEntityFromDomain).toList(),
        );
      }
      if (progressEntries.isNotEmpty) {
        await _isar.progressEntryEntitys.putAll(
          progressEntries.map(progressEntityFromDomain).toList(),
        );
      }
    });
  }

  Map<String, dynamic> _settingsToJson(AppSettingsModel settings) {
    return <String, dynamic>{
      'morningReminderMinutes': settings.morningReminderMinutes,
      'endOfDayReminderMinutes': settings.endOfDayReminderMinutes,
      'localeCode': settings.localeCode,
      'notificationsEnabled': settings.notificationsEnabled,
      'profileName': settings.profileName,
      'extraActivitiesNote': settings.extraActivitiesNote,
      'profileAvatarPath': settings.profileAvatarPath,
      'weeklyRoutine': settings.weeklyRoutine
          .map((WeeklyRoutineDayProfile day) => day.toJson())
          .toList(growable: false),
      'wakeUpMinutes': settings.wakeUpMinutes,
      'sleepMinutes': settings.sleepMinutes,
      'usualBreakStartMinutes': settings.usualBreakStartMinutes,
      'usualBreakEndMinutes': settings.usualBreakEndMinutes,
    };
  }

  Map<String, dynamic> _activityToJson(ActivityModel activity) {
    return <String, dynamic>{
      'id': activity.id,
      'title': activity.title,
      'selectedDays': activity.selectedDays,
      'subActivities': activity.subActivities,
      'timeMinutes': activity.timeMinutes,
      'weeklyGoal': activity.weeklyGoal,
      'preReminderMinutes': activity.preReminderMinutes,
      'isNotificationEnabled': activity.isNotificationEnabled,
      'enableMorningReminder': activity.enableMorningReminder,
      'enableEndOfDayReminder': activity.enableEndOfDayReminder,
      'enablePhotoProgress': activity.enablePhotoProgress,
      'lastThreeDayRuleNotifiedDate': activity.lastThreeDayRuleNotifiedDate,
      'createdAt': activity.createdAt.toIso8601String(),
      'updatedAt': activity.updatedAt.toIso8601String(),
      'scheduleUpdatedAt': activity.scheduleUpdatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _progressToJson(ProgressEntryModel entry) {
    return <String, dynamic>{
      'id': entry.id,
      'activityId': entry.activityId,
      'dateKey': entry.dateKey,
      'status': entry.statusKey,
      'isCompleted': entry.isCompleted,
      'subCompleted': entry.subCompleted,
      'subTotal': entry.subTotal,
      'completedSubActivities': entry.completedSubActivities,
      'photoPaths': entry.photoPaths,
      'photoPath': entry.photoPath,
      'photoNote': entry.photoNote,
      'notes': entry.notes,
      'completionTime': entry.effectiveCompletionTime?.toIso8601String(),
      'completedAt': entry.effectiveCompletionTime?.toIso8601String(),
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _oneTimeToJson(OneTimeReminderModel reminder) {
    return <String, dynamic>{
      'id': reminder.id,
      'title': reminder.title,
      'iconKey': reminder.iconKey,
      'scheduledAt': reminder.scheduledAt.toIso8601String(),
      'preReminderMinutes': reminder.preReminderMinutes,
      'isNotificationEnabled': reminder.isNotificationEnabled,
      'isCompleted': reminder.isCompleted,
      'createdAt': reminder.createdAt.toIso8601String(),
      'updatedAt': reminder.updatedAt.toIso8601String(),
    };
  }

  AppSettingsModel _parseSettings(Object? raw) {
    if (raw is! Map) {
      return defaultSettingsModel();
    }

    final int morningReminderMinutes = _asInt(
      raw['morningReminderMinutes'],
      fallback: AppConstants.defaultMorningReminderMinutes,
    );
    final int endOfDayReminderMinutes = _asInt(
      raw['endOfDayReminderMinutes'],
      fallback: AppConstants.defaultEndOfDayReminderMinutes,
    );
    final String localeCode = _asString(
      raw['localeCode'],
      fallback: AppConstants.localeId,
    );
    final bool notificationsEnabled = _asBool(
      raw['notificationsEnabled'],
      fallback: true,
    );
    final String? profileName = _asNullableString(raw['profileName']);
    final String? extraActivitiesNote = _asNullableString(
      raw['extraActivitiesNote'],
    );
    final String? profileAvatarPath = _asNullableString(
      raw['profileAvatarPath'],
    );
    final List<WeeklyRoutineDayProfile> weeklyRoutine = _parseWeeklyRoutine(
      raw['weeklyRoutine'],
    );
    final int? wakeUpMinutes = _asNullableInt(raw['wakeUpMinutes']);
    final int? sleepMinutes = _asNullableInt(raw['sleepMinutes']);
    final int? usualBreakStartMinutes = _asNullableInt(
      raw['usualBreakStartMinutes'],
    );
    final int? usualBreakEndMinutes = _asNullableInt(
      raw['usualBreakEndMinutes'],
    );

    return AppSettingsModel(
      morningReminderMinutes: morningReminderMinutes,
      endOfDayReminderMinutes: endOfDayReminderMinutes,
      localeCode: localeCode,
      notificationsEnabled: notificationsEnabled,
      profileName: profileName,
      extraActivitiesNote: extraActivitiesNote,
      profileAvatarPath: profileAvatarPath,
      weeklyRoutine: weeklyRoutine,
      wakeUpMinutes: wakeUpMinutes,
      sleepMinutes: sleepMinutes,
      usualBreakStartMinutes: usualBreakStartMinutes,
      usualBreakEndMinutes: usualBreakEndMinutes,
    );
  }

  List<WeeklyRoutineDayProfile> _parseWeeklyRoutine(Object? raw) {
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

  List<ActivityModel> _parseActivities(Object? raw) {
    if (raw is! List) {
      return <ActivityModel>[];
    }

    final List<ActivityModel> activities = <ActivityModel>[];
    for (final Object? item in raw) {
      if (item is! Map) {
        continue;
      }

      final String id = _asString(item['id'], fallback: '');
      final String title = _asString(item['title'], fallback: '');
      if (id.isEmpty || title.isEmpty) {
        continue;
      }

      final List<int> selectedDays = _asIntList(
        item['selectedDays'],
      ).where((int value) => value >= 1 && value <= 7).toSet().toList()..sort();
      if (selectedDays.isEmpty) {
        continue;
      }

      final int weeklyGoalFallback = selectedDays.length;
      final int weeklyGoal = _asInt(
        item['weeklyGoal'],
        fallback: weeklyGoalFallback,
      ).clamp(1, selectedDays.length);
      final DateTime now = DateTime.now();

      activities.add(
        ActivityModel(
          id: id,
          title: title,
          selectedDays: selectedDays,
          subActivities: _asStringList(item['subActivities']),
          timeMinutes: _asInt(item['timeMinutes'], fallback: 540),
          weeklyGoal: weeklyGoal,
          preReminderMinutes: _asInt(item['preReminderMinutes'], fallback: 0),
          isNotificationEnabled: _asBool(
            item['isNotificationEnabled'],
            fallback: true,
          ),
          enableMorningReminder: _asBool(
            item['enableMorningReminder'],
            fallback: false,
          ),
          enableEndOfDayReminder: _asBool(
            item['enableEndOfDayReminder'],
            fallback: false,
          ),
          enablePhotoProgress: _asBool(
            item['enablePhotoProgress'],
            fallback: false,
          ),
          lastThreeDayRuleNotifiedDate: _asNullableString(
            item['lastThreeDayRuleNotifiedDate'],
          ),
          createdAt: _asDateTime(item['createdAt']) ?? now,
          updatedAt: _asDateTime(item['updatedAt']) ?? now,
          scheduleUpdatedAt:
              _asDateTime(item['scheduleUpdatedAt']) ??
              _asDateTime(item['createdAt']) ??
              now,
        ),
      );
    }

    return activities;
  }

  List<ProgressEntryModel> _parseProgressEntries(Object? raw) {
    if (raw is! List) {
      return <ProgressEntryModel>[];
    }

    final List<ProgressEntryModel> entries = <ProgressEntryModel>[];
    for (final Object? item in raw) {
      if (item is! Map) {
        continue;
      }

      final String id = _asString(item['id'], fallback: '');
      final String activityId = _asString(item['activityId'], fallback: '');
      final String dateKey = _asString(item['dateKey'], fallback: '');
      if (id.isEmpty || activityId.isEmpty || dateKey.isEmpty) {
        continue;
      }

      final DateTime now = DateTime.now();
      final List<String> photoPaths = _asStringList(item['photoPaths']);
      final String? legacyPhotoPath = _asNullableString(item['photoPath']);
      final List<String> normalizedPhotoPaths = <String>[
        ...photoPaths.where((String value) => value.trim().isNotEmpty),
      ];
      if (normalizedPhotoPaths.isEmpty &&
          legacyPhotoPath != null &&
          legacyPhotoPath.trim().isNotEmpty) {
        normalizedPhotoPaths.add(legacyPhotoPath.trim());
      }

      entries.add(
        ProgressEntryModel(
          id: id,
          activityId: activityId,
          dateKey: dateKey,
          status: activityDayStatusFromStorage(
            _asNullableString(item['status']),
            fallbackCompleted: _asBool(item['isCompleted'], fallback: false),
          ),
          subCompleted: _asInt(
            item['subCompleted'],
            fallback: _asStringList(item['completedSubActivities']).length,
          ),
          subTotal: _asInt(item['subTotal'], fallback: 0),
          completedSubActivities: _asStringList(item['completedSubActivities']),
          photoPaths: normalizedPhotoPaths,
          photoPath: normalizedPhotoPaths.isEmpty
              ? null
              : normalizedPhotoPaths.first,
          photoNote: _asNullableString(item['photoNote']),
          notes: _asNullableString(item['notes']),
          completionTime:
              _asDateTime(item['completionTime']) ??
              _asDateTime(item['completedAt']),
          createdAt: _asDateTime(item['createdAt']) ?? now,
          updatedAt: _asDateTime(item['updatedAt']) ?? now,
        ),
      );
    }

    return entries;
  }

  List<OneTimeReminderModel> _parseOneTimeReminders(Object? raw) {
    if (raw is! List) {
      return <OneTimeReminderModel>[];
    }

    final List<OneTimeReminderModel> reminders = <OneTimeReminderModel>[];
    for (final Object? item in raw) {
      if (item is! Map) {
        continue;
      }

      final String id = _asString(item['id'], fallback: '');
      final String title = _asString(item['title'], fallback: '');
      final DateTime? scheduledAt = _asDateTime(item['scheduledAt']);
      if (id.isEmpty || title.isEmpty || scheduledAt == null) {
        continue;
      }

      final DateTime now = DateTime.now();
      reminders.add(
        OneTimeReminderModel(
          id: id,
          title: title,
          iconKey: normalizeActivityIconKey(_asNullableString(item['iconKey'])),
          scheduledAt: scheduledAt,
          preReminderMinutes: _asInt(item['preReminderMinutes'], fallback: 0),
          isNotificationEnabled: _asBool(
            item['isNotificationEnabled'],
            fallback: true,
          ),
          isCompleted: _asBool(item['isCompleted'], fallback: false),
          createdAt: _asDateTime(item['createdAt']) ?? now,
          updatedAt: _asDateTime(item['updatedAt']) ?? now,
        ),
      );
    }

    return reminders;
  }

  int _asInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  int? _asNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }

  bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
    return fallback;
  }

  String _asString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  String? _asNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  List<int> _asIntList(Object? value) {
    if (value is! List) {
      return <int>[];
    }
    return value
        .map((Object? item) => _asInt(item, fallback: -1))
        .where((int item) => item >= 0)
        .toList();
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) {
      return <String>[];
    }
    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
