import 'package:isar/isar.dart';
import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/migration/data/isar_archive_source.dart';
import 'package:nousen/features/migration/domain/isar_archive.dart';
import 'package:nousen/features/one_time_reminder/data/agenda_note_entity.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';

/// Target penulisan archive S6.0.
///
/// Kontrak keamanan:
/// - [isScratch] wajib true dan [databaseName] wajib berprefix
///   [kS6ScratchIsarNamePrefix]. Target produksi `reminder_schedule_v2`
///   ditolak sebelum koleksi dibaca/ditulis.
/// - [writeAll] hanya boleh INSERT ke target kosong. Implementasi Isar
///   memetakan seluruh dokumen ke entity lebih dulu, lalu menulis kelima
///   koleksi dalam SATU transaksi. Target yang sudah berisi data ditolak.
abstract class IsarArchiveTarget {
  bool get isScratch;

  String get databaseName;

  /// Jumlah dokumen saat ini per koleksi. Dipanggil untuk memastikan target
  /// kosong sebelum mutation dan untuk verifikasi setelah restore.
  Future<Map<IsarArchiveCollection, int>> countDocuments();

  /// Tulis seluruh archive. Wajib tidak menghapus data lama dan wajib gagal
  /// total (tanpa partial write) bila salah satu dokumen tidak valid.
  Future<void> writeAll(IsarArchive archive);
}

/// Target restore untuk Isar scratch S6.0.
///
/// Konstruktor menolak database selain prefix [kS6ScratchIsarNamePrefix].
/// Restore hanya boleh ke database scratch BARU yang masih kosong.
class IsarScratchArchiveTarget implements IsarArchiveTarget {
  IsarScratchArchiveTarget({required Isar isar}) : _isar = isar {
    validateS6ScratchDatabaseName(isar.name);
  }

  final Isar _isar;

  @override
  bool get isScratch => true;

  @override
  String get databaseName => _isar.name;

  @override
  Future<Map<IsarArchiveCollection, int>> countDocuments() => _counts();

  Future<Map<IsarArchiveCollection, int>> _counts() async {
    return <IsarArchiveCollection, int>{
      IsarArchiveCollection.settings: await _isar.appSettingsEntitys.count(),
      IsarArchiveCollection.activities: await _isar.activityEntitys.count(),
      IsarArchiveCollection.reminders: await _isar.oneTimeReminderEntitys
          .count(),
      IsarArchiveCollection.agendaNotes: await _isar.agendaNoteEntitys.count(),
      IsarArchiveCollection.progress: await _isar.progressEntryEntitys.count(),
    };
  }

  @override
  Future<void> writeAll(IsarArchive archive) async {
    if (!archive.databaseName.startsWith(kS6ScratchIsarNamePrefix)) {
      throw FormatException(
        'archive berasal dari DB non-scratch: ${archive.databaseName}',
      );
    }

    // Mapping + validasi field selesai SEBELUM transaksi dimulai. Bila ada
    // field rusak, tidak ada satu pun dokumen yang ditulis.
    final _RestoreBatch batch = _RestoreBatch.fromArchive(archive);

    final bool committed = await _isar.writeTxn(() async {
      final int existing = (await _counts()).values.fold(
        0,
        (int sum, int count) => sum + count,
      );
      if (existing != 0) {
        throw StateError(
          'target "${_isar.name}" tidak kosong ($existing dokumen); '
          'restore hanya ke DB scratch baru',
        );
      }

      await _isar.appSettingsEntitys.putAll(batch.settings);
      await _isar.activityEntitys.putAll(batch.activities);
      await _isar.oneTimeReminderEntitys.putAll(batch.reminders);
      await _isar.agendaNoteEntitys.putAll(batch.agendaNotes);
      await _isar.progressEntryEntitys.putAll(batch.progress);

      final Map<IsarArchiveCollection, int> written = await _counts();
      for (final IsarArchiveCollection collection
          in IsarArchiveCollection.values) {
        if (written[collection] != archive.countOf(collection)) {
          throw StateError(
            'jumlah dokumen ${collection.key} setelah tulis tidak cocok '
            '(target: ${written[collection]}, '
            'archive: ${archive.countOf(collection)}); rollback',
          );
        }
      }
      return true;
    });

    if (!committed) {
      throw StateError('transaksi restore archive gagal (rollback)');
    }
  }
}

class _RestoreBatch {
  const _RestoreBatch({
    required this.settings,
    required this.activities,
    required this.reminders,
    required this.agendaNotes,
    required this.progress,
  });

  factory _RestoreBatch.fromArchive(IsarArchive archive) {
    final List<Map<String, Object?>> settingsDocs =
        archive.collections[IsarArchiveCollection.settings] ??
        const <Map<String, Object?>>[];
    if (settingsDocs.length > 1) {
      throw const FormatException('settings: maksimal satu dokumen');
    }

    final List<AppSettingsEntity> settings = settingsDocs
        .map(_settingsFromDoc)
        .toList(growable: false);
    final List<ActivityEntity> activities = _docs(
      archive,
      IsarArchiveCollection.activities,
    ).map(_activityFromDoc).toList(growable: false);
    final List<OneTimeReminderEntity> reminders = _docs(
      archive,
      IsarArchiveCollection.reminders,
    ).map(_reminderFromDoc).toList(growable: false);
    final List<AgendaNoteEntity> agendaNotes = _docs(
      archive,
      IsarArchiveCollection.agendaNotes,
    ).map(_agendaNoteFromDoc).toList(growable: false);
    final List<ProgressEntryEntity> progress = _docs(
      archive,
      IsarArchiveCollection.progress,
    ).map(_progressFromDoc).toList(growable: false);

    _ensureUniqueIsarIds(
      settings.map((AppSettingsEntity entity) => entity.id),
      IsarArchiveCollection.settings,
    );
    _ensureUniqueIsarIds(
      activities.map((ActivityEntity entity) => entity.isarId),
      IsarArchiveCollection.activities,
    );
    _ensureUniqueIsarIds(
      reminders.map((OneTimeReminderEntity entity) => entity.isarId),
      IsarArchiveCollection.reminders,
    );
    _ensureUniqueIsarIds(
      agendaNotes.map((AgendaNoteEntity entity) => entity.isarId),
      IsarArchiveCollection.agendaNotes,
    );
    _ensureUniqueIsarIds(
      progress.map((ProgressEntryEntity entity) => entity.isarId),
      IsarArchiveCollection.progress,
    );

    _ensureUniqueStringIds(
      activities.map((ActivityEntity entity) => entity.id),
      IsarArchiveCollection.activities,
    );
    _ensureUniqueStringIds(
      reminders.map((OneTimeReminderEntity entity) => entity.id),
      IsarArchiveCollection.reminders,
    );
    _ensureUniqueStringIds(
      agendaNotes.map((AgendaNoteEntity entity) => entity.id),
      IsarArchiveCollection.agendaNotes,
    );
    _ensureUniqueStringIds(
      progress.map((ProgressEntryEntity entity) => entity.id),
      IsarArchiveCollection.progress,
    );

    return _RestoreBatch(
      settings: settings,
      activities: activities,
      reminders: reminders,
      agendaNotes: agendaNotes,
      progress: progress,
    );
  }

  final List<AppSettingsEntity> settings;
  final List<ActivityEntity> activities;
  final List<OneTimeReminderEntity> reminders;
  final List<AgendaNoteEntity> agendaNotes;
  final List<ProgressEntryEntity> progress;
}

List<Map<String, Object?>> _docs(
  IsarArchive archive,
  IsarArchiveCollection collection,
) {
  return archive.collections[collection] ?? const <Map<String, Object?>>[];
}

AppSettingsEntity _settingsFromDoc(Map<String, Object?> doc) {
  final int isarId = _isarId(doc, IsarArchiveCollection.settings);
  if (isarId != 1) {
    throw FormatException('settings.isarId harus 1 (ditemukan $isarId)');
  }
  return AppSettingsEntity()
    ..id = isarId
    ..morningReminderMinutes = _int(
      doc,
      'morningReminderMinutes',
      IsarArchiveCollection.settings,
    )
    ..endOfDayReminderMinutes = _int(
      doc,
      'endOfDayReminderMinutes',
      IsarArchiveCollection.settings,
    )
    ..localeCode = _string(doc, 'localeCode', IsarArchiveCollection.settings)
    ..notificationsEnabled = _bool(
      doc,
      'notificationsEnabled',
      IsarArchiveCollection.settings,
    )
    ..profileName = _nullableString(
      doc,
      'profileName',
      IsarArchiveCollection.settings,
    )
    ..profileAvatarPath = _nullableString(
      doc,
      'profileAvatarPath',
      IsarArchiveCollection.settings,
    )
    ..weeklyRoutineJson = _nullableString(
      doc,
      'weeklyRoutineJson',
      IsarArchiveCollection.settings,
    )
    ..wakeUpMinutes = _nullableInt(
      doc,
      'wakeUpMinutes',
      IsarArchiveCollection.settings,
    )
    ..sleepMinutes = _nullableInt(
      doc,
      'sleepMinutes',
      IsarArchiveCollection.settings,
    )
    ..usualBreakStartMinutes = _nullableInt(
      doc,
      'usualBreakStartMinutes',
      IsarArchiveCollection.settings,
    )
    ..usualBreakEndMinutes = _nullableInt(
      doc,
      'usualBreakEndMinutes',
      IsarArchiveCollection.settings,
    )
    ..hasSeededData = _nullableBool(
      doc,
      'hasSeededData',
      IsarArchiveCollection.settings,
    );
}

ActivityEntity _activityFromDoc(Map<String, Object?> doc) {
  const IsarArchiveCollection collection = IsarArchiveCollection.activities;
  return ActivityEntity()
    ..isarId = _isarId(doc, collection)
    ..id = _nonEmptyString(doc, 'id', collection)
    ..title = _string(doc, 'title', collection)
    ..category = _nullableString(doc, 'category', collection)
    ..selectedDays = _intList(doc, 'selectedDays', collection)
    ..subActivities = _stringList(doc, 'subActivities', collection)
    ..timeMinutes = _int(doc, 'timeMinutes', collection)
    ..weeklyGoal = _int(doc, 'weeklyGoal', collection)
    ..preReminderMinutes = _int(doc, 'preReminderMinutes', collection)
    ..isNotificationEnabled = _bool(doc, 'isNotificationEnabled', collection)
    ..enableMorningReminder = _bool(doc, 'enableMorningReminder', collection)
    ..enableEndOfDayReminder = _bool(doc, 'enableEndOfDayReminder', collection)
    ..enablePhotoProgress = _bool(doc, 'enablePhotoProgress', collection)
    ..lastThreeDayRuleNotifiedDate = _nullableString(
      doc,
      'lastThreeDayRuleNotifiedDate',
      collection,
    )
    ..createdAt = _dateTime(doc, 'createdAt', collection)
    ..updatedAt = _dateTime(doc, 'updatedAt', collection)
    ..scheduleUpdatedAt = _nullableDateTime(
      doc,
      'scheduleUpdatedAt',
      collection,
    );
}

OneTimeReminderEntity _reminderFromDoc(Map<String, Object?> doc) {
  const IsarArchiveCollection collection = IsarArchiveCollection.reminders;
  return OneTimeReminderEntity()
    ..isarId = _isarId(doc, collection)
    ..id = _nonEmptyString(doc, 'id', collection)
    ..title = _string(doc, 'title', collection)
    ..iconKey = _nullableString(doc, 'iconKey', collection)
    ..scheduledAt = _dateTime(doc, 'scheduledAt', collection)
    ..scheduledEndAt = _nullableDateTime(doc, 'scheduledEndAt', collection)
    ..categoryId = _nullableString(doc, 'categoryId', collection)
    ..description = _nullableString(doc, 'description', collection)
    ..subActivities = _nullableStringList(doc, 'subActivities', collection)
    ..completedSubActivities = _nullableStringList(
      doc,
      'completedSubActivities',
      collection,
    )
    ..preReminderMinutes = _int(doc, 'preReminderMinutes', collection)
    ..isNotificationEnabled = _bool(doc, 'isNotificationEnabled', collection)
    ..isCompleted = _bool(doc, 'isCompleted', collection)
    ..isSkipped = _nullableBool(doc, 'isSkipped', collection)
    ..createdAt = _dateTime(doc, 'createdAt', collection)
    ..updatedAt = _dateTime(doc, 'updatedAt', collection);
}

AgendaNoteEntity _agendaNoteFromDoc(Map<String, Object?> doc) {
  const IsarArchiveCollection collection = IsarArchiveCollection.agendaNotes;
  return AgendaNoteEntity()
    ..isarId = _isarId(doc, collection)
    ..id = _nonEmptyString(doc, 'id', collection)
    ..reminderId = _string(doc, 'reminderId', collection)
    ..text = _string(doc, 'text', collection)
    ..photoPaths = _nullableStringList(doc, 'photoPaths', collection)
    ..createdAt = _dateTime(doc, 'createdAt', collection)
    ..updatedAt = _dateTime(doc, 'updatedAt', collection);
}

ProgressEntryEntity _progressFromDoc(Map<String, Object?> doc) {
  const IsarArchiveCollection collection = IsarArchiveCollection.progress;
  return ProgressEntryEntity()
    ..isarId = _isarId(doc, collection)
    ..id = _nonEmptyString(doc, 'id', collection)
    ..activityId = _string(doc, 'activityId', collection)
    ..dateKey = _string(doc, 'dateKey', collection)
    ..statusKey = _string(doc, 'statusKey', collection)
    ..subCompleted = _int(doc, 'subCompleted', collection)
    ..subTotal = _int(doc, 'subTotal', collection)
    ..isCompleted = _bool(doc, 'isCompleted', collection)
    ..completedSubActivities = _stringList(
      doc,
      'completedSubActivities',
      collection,
    )
    ..photoPaths = _stringList(doc, 'photoPaths', collection)
    ..photoPath = _nullableString(doc, 'photoPath', collection)
    ..photoNote = _nullableString(doc, 'photoNote', collection)
    ..notes = _nullableString(doc, 'notes', collection)
    ..completedAt = _nullableDateTime(doc, 'completedAt', collection)
    ..createdAt = _dateTime(doc, 'createdAt', collection)
    ..updatedAt = _dateTime(doc, 'updatedAt', collection);
}

int _isarId(Map<String, Object?> doc, IsarArchiveCollection collection) {
  final int isarId = _int(doc, 'isarId', collection);
  if (isarId <= 0) {
    throw FormatException('${collection.key}.isarId harus > 0 ($isarId)');
  }
  return isarId;
}

String _nonEmptyString(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final String value = _string(doc, key, collection);
  if (value.trim().isEmpty) {
    throw FormatException('${collection.key}.$key tidak boleh kosong');
  }
  return value;
}

String _string(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value is! String) {
    throw FormatException('${collection.key}.$key harus string');
  }
  return value;
}

String? _nullableString(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('${collection.key}.$key harus string/null');
  }
  return value;
}

int _int(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value is! int) {
    throw FormatException('${collection.key}.$key harus int');
  }
  return value;
}

int? _nullableInt(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('${collection.key}.$key harus int/null');
  }
  return value;
}

bool _bool(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value is! bool) {
    throw FormatException('${collection.key}.$key harus bool');
  }
  return value;
}

bool? _nullableBool(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    throw FormatException('${collection.key}.$key harus bool/null');
  }
  return value;
}

DateTime _dateTime(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final String raw = _string(doc, key, collection);
  final DateTime? value = DateTime.tryParse(raw);
  if (value == null) {
    throw FormatException('${collection.key}.$key bukan ISO-8601 valid');
  }
  return value;
}

DateTime? _nullableDateTime(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final String? raw = _nullableString(doc, key, collection);
  if (raw == null) {
    return null;
  }
  final DateTime? value = DateTime.tryParse(raw);
  if (value == null) {
    throw FormatException('${collection.key}.$key bukan ISO-8601 valid');
  }
  return value;
}

List<String> _stringList(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value is! List) {
    throw FormatException('${collection.key}.$key harus array string');
  }
  final List<String> result = <String>[];
  for (final Object? item in value) {
    if (item is! String) {
      throw FormatException('${collection.key}.$key harus array string');
    }
    result.add(item);
  }
  return result;
}

List<String>? _nullableStringList(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value == null) {
    return null;
  }
  return _stringList(doc, key, collection);
}

List<int> _intList(
  Map<String, Object?> doc,
  String key,
  IsarArchiveCollection collection,
) {
  final Object? value = doc[key];
  if (value is! List) {
    throw FormatException('${collection.key}.$key harus array int');
  }
  final List<int> result = <int>[];
  for (final Object? item in value) {
    if (item is! int) {
      throw FormatException('${collection.key}.$key harus array int');
    }
    result.add(item);
  }
  return result;
}

void _ensureUniqueIsarIds(Iterable<int> ids, IsarArchiveCollection collection) {
  final Set<int> seen = <int>{};
  for (final int id in ids) {
    if (!seen.add(id)) {
      throw FormatException('${collection.key}: isarId duplikat ($id)');
    }
  }
}

void _ensureUniqueStringIds(
  Iterable<String> ids,
  IsarArchiveCollection collection,
) {
  final Set<String> seen = <String>{};
  for (final String id in ids) {
    if (!seen.add(id)) {
      throw FormatException('${collection.key}: id duplikat ($id)');
    }
  }
}
