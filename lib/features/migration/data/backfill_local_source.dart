import 'package:isar/isar.dart';
import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/migration/data/backfill_mappers.dart';
import 'package:nousen/features/migration/data/backfill_models.dart';
import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';
import 'package:nousen/features/one_time_reminder/data/agenda_note_entity.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';

/// Sumber data lokal untuk backfill (fake in-memory di tes).
abstract class BackfillLocalSource {
  /// Semua baris satu entitas, urut `isarId` menaik (kontrak urutan).
  Future<List<BackfillLocalRow>> readAll(BackfillEntityKind kind);
}

/// Implementasi Isar: baca koleksi lalu bangun baris via
/// [backfill_mappers.dart].
///
/// Skala data personal (ribuan baris) — dibaca penuh per entitas, kursor
/// resume memakai `isarId`. Bila data membesar, ganti ke pembacaan batch
/// tanpa mengubah kontrak [BackfillLocalSource].
class IsarBackfillLocalSource implements BackfillLocalSource {
  IsarBackfillLocalSource(this._isar);

  final Isar _isar;

  @override
  Future<List<BackfillLocalRow>> readAll(BackfillEntityKind kind) {
    return switch (kind) {
      BackfillEntityKind.settings => _readSettings(),
      BackfillEntityKind.activities => _readActivities(),
      BackfillEntityKind.reminders => _readReminders(),
      BackfillEntityKind.agendaNotes => _readAgendaNotes(),
      BackfillEntityKind.progress => _readProgress(),
    };
  }

  Future<List<BackfillLocalRow>> _readSettings() async {
    final AppSettingsEntity? entity = await _isar.appSettingsEntitys.get(1);
    if (entity == null) {
      return const <BackfillLocalRow>[];
    }
    return <BackfillLocalRow>[
      BackfillLocalRow(
        isarId: entity.id,
        docId: BackfillEntityKind.settings.fixedDocId!,
        buildData: (Object serverTs) =>
            settingsBackfillMap(entity, serverTs: serverTs),
      ),
    ];
  }

  Future<List<BackfillLocalRow>> _readActivities() async {
    final List<ActivityEntity> entities = await _isar.activityEntitys
        .where()
        .findAll();
    entities.sort(
      (ActivityEntity a, ActivityEntity b) => a.isarId.compareTo(b.isarId),
    );
    return entities
        .map(
          (ActivityEntity e) => BackfillLocalRow(
            isarId: e.isarId,
            docId: e.id,
            buildData: (Object serverTs) =>
                activityBackfillMap(e, serverTs: serverTs),
          ),
        )
        .toList();
  }

  Future<List<BackfillLocalRow>> _readReminders() async {
    final List<OneTimeReminderEntity> entities = await _isar
        .oneTimeReminderEntitys
        .where()
        .findAll();
    entities.sort(
      (OneTimeReminderEntity a, OneTimeReminderEntity b) =>
          a.isarId.compareTo(b.isarId),
    );
    return entities
        .map(
          (OneTimeReminderEntity e) => BackfillLocalRow(
            isarId: e.isarId,
            docId: e.id,
            buildData: (Object serverTs) =>
                reminderBackfillMap(e, serverTs: serverTs),
          ),
        )
        .toList();
  }

  Future<List<BackfillLocalRow>> _readAgendaNotes() async {
    final List<AgendaNoteEntity> entities = await _isar.agendaNoteEntitys
        .where()
        .findAll();
    entities.sort(
      (AgendaNoteEntity a, AgendaNoteEntity b) => a.isarId.compareTo(b.isarId),
    );
    return entities
        .map(
          (AgendaNoteEntity e) => BackfillLocalRow(
            isarId: e.isarId,
            docId: e.id,
            buildData: (Object serverTs) =>
                agendaNoteBackfillMap(e, serverTs: serverTs),
          ),
        )
        .toList();
  }

  Future<List<BackfillLocalRow>> _readProgress() async {
    final List<ProgressEntryEntity> entities = await _isar.progressEntryEntitys
        .where()
        .findAll();
    entities.sort(
      (ProgressEntryEntity a, ProgressEntryEntity b) =>
          a.isarId.compareTo(b.isarId),
    );
    return entities
        .map(
          (ProgressEntryEntity e) => BackfillLocalRow(
            isarId: e.isarId,
            docId: e.id,
            buildData: (Object serverTs) =>
                progressBackfillMap(e, serverTs: serverTs),
          ),
        )
        .toList();
  }
}
