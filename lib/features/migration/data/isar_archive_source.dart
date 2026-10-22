import 'package:isar/isar.dart';
import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/migration/domain/isar_archive.dart';
import 'package:nousen/features/one_time_reminder/data/agenda_note_entity.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';

/// Prefix nama database Isar yang diizinkan untuk archive S6.0.
///
/// S6.0 HANYA untuk validasi synthetic/scratch. Database produksi
/// (`reminder_schedule_v2`) sengaja ditolak oleh
/// [validateS6ScratchDatabaseName] agar archive penuh tidak pernah membaca
/// data owner/user asli tanpa gate terpisah.
const String kS6ScratchIsarNamePrefix = 'nousen_s6_scratch';

/// Guard nama database untuk [IsarScratchArchiveSource].
///
/// Melempar [ArgumentError] bila [databaseName] bukan database scratch S6.
void validateS6ScratchDatabaseName(String databaseName) {
  if (!databaseName.startsWith(kS6ScratchIsarNamePrefix)) {
    throw ArgumentError.value(
      databaseName,
      'databaseName',
      'S6.0 archive hanya boleh membaca DB scratch berprefix '
          '"$kS6ScratchIsarNamePrefix" (DB produksi ditolak)',
    );
  }
}

/// Sumber data archive (Isar scratch di produksi; fake in-memory di tes).
abstract class IsarArchiveSource {
  /// True hanya untuk sumber synthetic/scratch. [IsarArchiveService] menolak
  /// capture bila false.
  bool get isSynthetic;

  /// Label sumber untuk audit di JSON archive.
  String get sourceLabel;

  /// Nama database Isar sumber.
  String get databaseName;

  /// Semua dokumen satu koleksi, URUT `isarId` menaik, tiap dokumen wajib
  /// memuat field `isarId` bertipe int.
  Future<List<Map<String, Object?>>> readAll(IsarArchiveCollection collection);
}

/// Implementasi Isar untuk database scratch.
///
/// Konstruktor menolak database selain prefix [kS6ScratchIsarNamePrefix].
/// Pembuatan DB scratch + pengisian data synthetic berada di luar S6.0
/// (tidak dijalankan otomatis; lihat README §17).
class IsarScratchArchiveSource implements IsarArchiveSource {
  IsarScratchArchiveSource({required Isar isar, required this.label})
    : _isar = isar {
    validateS6ScratchDatabaseName(isar.name);
  }

  final Isar _isar;

  /// Label audit, mis. `s6-scratch-2026-10-22`.
  final String label;

  @override
  bool get isSynthetic => true;

  @override
  String get sourceLabel => label;

  @override
  String get databaseName => _isar.name;

  @override
  Future<List<Map<String, Object?>>> readAll(
    IsarArchiveCollection collection,
  ) async {
    final List<Map<String, Object?>> docs = switch (collection) {
      IsarArchiveCollection.settings => await _readSettings(),
      IsarArchiveCollection.activities => await _readActivities(),
      IsarArchiveCollection.reminders => await _readReminders(),
      IsarArchiveCollection.agendaNotes => await _readAgendaNotes(),
      IsarArchiveCollection.progress => await _readProgress(),
    };
    docs.sort(
      (Map<String, Object?> a, Map<String, Object?> b) =>
          (a['isarId']! as int).compareTo(b['isarId']! as int),
    );
    return docs;
  }

  Future<List<Map<String, Object?>>> _readSettings() async {
    final AppSettingsEntity? entity = await _isar.appSettingsEntitys.get(1);
    if (entity == null) {
      return const <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[
      <String, Object?>{
        'isarId': entity.id,
        'morningReminderMinutes': entity.morningReminderMinutes,
        'endOfDayReminderMinutes': entity.endOfDayReminderMinutes,
        'localeCode': entity.localeCode,
        'notificationsEnabled': entity.notificationsEnabled,
        'profileName': entity.profileName,
        'profileAvatarPath': entity.profileAvatarPath,
        'weeklyRoutineJson': entity.weeklyRoutineJson,
        'wakeUpMinutes': entity.wakeUpMinutes,
        'sleepMinutes': entity.sleepMinutes,
        'usualBreakStartMinutes': entity.usualBreakStartMinutes,
        'usualBreakEndMinutes': entity.usualBreakEndMinutes,
        'hasSeededData': entity.hasSeededData,
      },
    ];
  }

  Future<List<Map<String, Object?>>> _readActivities() async {
    final List<ActivityEntity> entities = await _isar.activityEntitys
        .where()
        .findAll();
    return entities
        .map(
          (ActivityEntity e) => <String, Object?>{
            'isarId': e.isarId,
            'id': e.id,
            'title': e.title,
            'category': e.category,
            'selectedDays': e.selectedDays.toList(growable: false),
            'subActivities': e.subActivities.toList(growable: false),
            'timeMinutes': e.timeMinutes,
            'weeklyGoal': e.weeklyGoal,
            'preReminderMinutes': e.preReminderMinutes,
            'isNotificationEnabled': e.isNotificationEnabled,
            'enableMorningReminder': e.enableMorningReminder,
            'enableEndOfDayReminder': e.enableEndOfDayReminder,
            'enablePhotoProgress': e.enablePhotoProgress,
            'lastThreeDayRuleNotifiedDate': e.lastThreeDayRuleNotifiedDate,
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
            'scheduleUpdatedAt': e.scheduleUpdatedAt?.toIso8601String(),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _readReminders() async {
    final List<OneTimeReminderEntity> entities = await _isar
        .oneTimeReminderEntitys
        .where()
        .findAll();
    return entities
        .map(
          (OneTimeReminderEntity e) => <String, Object?>{
            'isarId': e.isarId,
            'id': e.id,
            'title': e.title,
            'iconKey': e.iconKey,
            'scheduledAt': e.scheduledAt.toIso8601String(),
            'scheduledEndAt': e.scheduledEndAt?.toIso8601String(),
            'categoryId': e.categoryId,
            'description': e.description,
            'subActivities': e.subActivities?.toList(growable: false),
            'completedSubActivities': e.completedSubActivities?.toList(
              growable: false,
            ),
            'preReminderMinutes': e.preReminderMinutes,
            'isNotificationEnabled': e.isNotificationEnabled,
            'isCompleted': e.isCompleted,
            'isSkipped': e.isSkipped,
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _readAgendaNotes() async {
    final List<AgendaNoteEntity> entities = await _isar.agendaNoteEntitys
        .where()
        .findAll();
    return entities
        .map(
          (AgendaNoteEntity e) => <String, Object?>{
            'isarId': e.isarId,
            'id': e.id,
            'reminderId': e.reminderId,
            'text': e.text,
            'photoPaths': e.photoPaths?.toList(growable: false),
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _readProgress() async {
    final List<ProgressEntryEntity> entities = await _isar.progressEntryEntitys
        .where()
        .findAll();
    return entities
        .map(
          (ProgressEntryEntity e) => <String, Object?>{
            'isarId': e.isarId,
            'id': e.id,
            'activityId': e.activityId,
            'dateKey': e.dateKey,
            'statusKey': e.statusKey,
            'subCompleted': e.subCompleted,
            'subTotal': e.subTotal,
            'isCompleted': e.isCompleted,
            'completedSubActivities': e.completedSubActivities.toList(
              growable: false,
            ),
            'photoPaths': e.photoPaths.toList(growable: false),
            'photoPath': e.photoPath,
            'photoNote': e.photoNote,
            'notes': e.notes,
            'completedAt': e.completedAt?.toIso8601String(),
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
          },
        )
        .toList(growable: false);
  }
}
