import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/one_time_reminder/data/agenda_note_entity.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';

/// Mapper draft Isar → dokumen Firestore untuk backfill (S0).
///
/// Aturan umum map S0:
/// - `updatedAt` = waktu server (LWW oleh jam server, bukan jam device);
/// - `clientUpdatedAt` = jam device saat data terakhir diubah (audit);
/// - `deleted: false` + `deletedAt: null` = dokumen hidup (skema tombstone);
/// - `schemaVersion` = versi skema dokumen cloud.
///
/// Field perangkat TIDAK ikut (file lokal tidak berguna di perangkat lain;
/// upload Storage ditunda): `photoPaths`/`photoPath` (progress & agenda
/// notes) dan `profileAvatarPath` (settings). Lihat
/// `docs/firestore-migration/README.md` §Field yang tidak ikut.
///
/// Field yang hilang dari entitas Isar (tidak bisa dipulihkan backfill;
/// gap penyimpanan lama): activity `family`, `tags`, `duration`,
/// `isAnomali` — lihat README §Kehilangan field.
const int backfillSchemaVersion = 2;

Map<String, Object?> activityBackfillMap(
  ActivityEntity e, {
  required Object serverTs,
}) {
  return <String, Object?>{
    'id': e.id,
    'title': e.title,
    'category': e.category,
    'selectedDays': e.selectedDays,
    'subActivities': e.subActivities,
    'timeMinutes': e.timeMinutes,
    'weeklyGoal': e.weeklyGoal,
    'preReminderMinutes': e.preReminderMinutes,
    'isNotificationEnabled': e.isNotificationEnabled,
    'enableMorningReminder': e.enableMorningReminder,
    'enableEndOfDayReminder': e.enableEndOfDayReminder,
    'enablePhotoProgress': e.enablePhotoProgress,
    'lastThreeDayRuleNotifiedDate': e.lastThreeDayRuleNotifiedDate,
    'createdAt': e.createdAt.toIso8601String(),
    'clientUpdatedAt': e.updatedAt.toIso8601String(),
    'scheduleUpdatedAt': e.scheduleUpdatedAt?.toIso8601String(),
    'updatedAt': serverTs,
    'deleted': false,
    'deletedAt': null,
    'schemaVersion': backfillSchemaVersion,
  };
}

Map<String, Object?> reminderBackfillMap(
  OneTimeReminderEntity e, {
  required Object serverTs,
}) {
  return <String, Object?>{
    'id': e.id,
    'title': e.title,
    'iconKey': e.iconKey,
    'scheduledAt': e.scheduledAt.toIso8601String(),
    'scheduledEndAt': e.scheduledEndAt?.toIso8601String(),
    'categoryId': e.categoryId,
    'description': e.description,
    'subActivities': e.subActivities ?? const <String>[],
    'completedSubActivities': e.completedSubActivities ?? const <String>[],
    'preReminderMinutes': e.preReminderMinutes,
    'isNotificationEnabled': e.isNotificationEnabled,
    'isCompleted': e.isCompleted,
    'isSkipped': e.isSkipped ?? false,
    'createdAt': e.createdAt.toIso8601String(),
    'clientUpdatedAt': e.updatedAt.toIso8601String(),
    'updatedAt': serverTs,
    'deleted': false,
    'deletedAt': null,
    'schemaVersion': backfillSchemaVersion,
  };
}

Map<String, Object?> agendaNoteBackfillMap(
  AgendaNoteEntity e, {
  required Object serverTs,
}) {
  return <String, Object?>{
    'id': e.id,
    'reminderId': e.reminderId,
    'text': e.text,
    'createdAt': e.createdAt.toIso8601String(),
    'clientUpdatedAt': e.updatedAt.toIso8601String(),
    'updatedAt': serverTs,
    'deleted': false,
    'deletedAt': null,
    'schemaVersion': backfillSchemaVersion,
  };
}

Map<String, Object?> progressBackfillMap(
  ProgressEntryEntity e, {
  required Object serverTs,
}) {
  return <String, Object?>{
    'id': e.id,
    'activityId': e.activityId,
    'dateKey': e.dateKey,
    'status': _progressStatusKey(e),
    'subCompleted': e.subCompleted,
    'subTotal': e.subTotal,
    'completedSubActivities': e.completedSubActivities,
    'photoNote': e.photoNote,
    'notes': e.notes,
    'completionTime': e.completedAt?.toIso8601String(),
    'createdAt': e.createdAt.toIso8601String(),
    'clientUpdatedAt': e.updatedAt.toIso8601String(),
    'updatedAt': serverTs,
    'deleted': false,
    'deletedAt': null,
    'schemaVersion': backfillSchemaVersion,
  };
}

/// Cermin fallback `ProgressEntryEntityMapper.toDomain`: statusKey kosong +
/// `isCompleted` true dianggap 'done' (data lama).
String _progressStatusKey(ProgressEntryEntity e) {
  final String raw = e.statusKey.trim();
  if (raw.isNotEmpty) {
    return raw;
  }
  return e.isCompleted ? 'done' : 'not_done';
}

Map<String, Object?> settingsBackfillMap(
  AppSettingsEntity e, {
  required Object serverTs,
}) {
  return <String, Object?>{
    'id': 'app',
    'morningReminderMinutes': e.morningReminderMinutes,
    'endOfDayReminderMinutes': e.endOfDayReminderMinutes,
    'localeCode': e.localeCode,
    'notificationsEnabled': e.notificationsEnabled,
    'profileName': e.profileName,
    'weeklyRoutineJson': e.weeklyRoutineJson,
    'wakeUpMinutes': e.wakeUpMinutes,
    'sleepMinutes': e.sleepMinutes,
    'usualBreakStartMinutes': e.usualBreakStartMinutes,
    'usualBreakEndMinutes': e.usualBreakEndMinutes,
    'updatedAt': serverTs,
    'deleted': false,
    'deletedAt': null,
    'schemaVersion': backfillSchemaVersion,
  };
}
