import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/core/migration/migration_flags.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_agenda_notes_backend.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_first_one_time_reminder_repository.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_reminders_backend.dart';
import 'package:nousen/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:nousen/features/settings/data/cloud_first_settings_repository.dart';
import 'package:nousen/features/settings/data/cloud_settings_backend.dart';
import 'package:nousen/features/settings/domain/app_settings_model.dart';
import 'package:nousen/features/settings/domain/settings_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

class _FakeAuthState implements CloudAuthState {
  String? uid = 'u1';

  @override
  String? get currentUid => uid;

  @override
  Stream<String?> uidChanges() => Stream<String?>.value(uid);
}

class _SetCall {
  const _SetCall(this.docId, this.data);

  final String docId;
  final Map<String, dynamic> data;
}

class _FakeRemindersBackend implements CloudRemindersBackend {
  final List<_SetCall> setCalls = <_SetCall>[];

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(docId, data));
  }

  @override
  Stream<List<CloudReminderDoc>> watchVisible(String uid) =>
      const Stream<List<CloudReminderDoc>>.empty();

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async =>
      const <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async => null;
}

class _FakeNotesBackend implements CloudAgendaNotesBackend {
  final List<_SetCall> setCalls = <_SetCall>[];

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(docId, data));
  }

  @override
  Stream<List<CloudAgendaNoteDoc>> watchVisible(String uid) =>
      const Stream<List<CloudAgendaNoteDoc>>.empty();

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async =>
      const <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async => null;
}

class _FakeSettingsBackend implements CloudSettingsBackend {
  final List<_SetCall> setCalls = <_SetCall>[];

  @override
  Future<void> setDoc(String uid, Map<String, dynamic> data) async {
    setCalls.add(_SetCall('app', data));
  }

  @override
  Stream<CloudSettingsDoc?> watchDoc(String uid) =>
      Stream<CloudSettingsDoc?>.value(null);

  @override
  Future<Map<String, dynamic>?> getDoc(String uid) async => null;
}

class _FakeLocalReminder implements OneTimeReminderRepository {
  final List<OneTimeReminderModel> reminders = <OneTimeReminderModel>[];
  final List<AgendaNoteModel> notes = <AgendaNoteModel>[];

  @override
  Stream<List<OneTimeReminderModel>> watchAll() =>
      Stream<List<OneTimeReminderModel>>.value(reminders);

  @override
  Future<List<OneTimeReminderModel>> getAll() async => reminders;

  @override
  Future<OneTimeReminderModel?> getById(String id) async => null;

  @override
  Future<void> upsert(OneTimeReminderModel reminder) async {
    reminders.removeWhere(
      (OneTimeReminderModel item) => item.id == reminder.id,
    );
    reminders.add(reminder);
  }

  @override
  Future<void> delete(String id) async {
    reminders.removeWhere((OneTimeReminderModel item) => item.id == id);
  }

  @override
  Stream<List<AgendaNoteModel>> watchNotes(String reminderId) =>
      Stream<List<AgendaNoteModel>>.value(
        notes
            .where((AgendaNoteModel note) => note.reminderId == reminderId)
            .toList(),
      );

  @override
  Future<void> upsertNote(AgendaNoteModel note) async {
    notes.removeWhere((AgendaNoteModel item) => item.id == note.id);
    notes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    notes.removeWhere((AgendaNoteModel item) => item.id == id);
  }
}

class _FakeLocalSettings implements SettingsRepository {
  AppSettingsModel stored = _settings();

  @override
  Stream<AppSettingsModel> watch() => Stream<AppSettingsModel>.value(stored);

  @override
  Future<AppSettingsModel> get() async => stored;

  @override
  Future<void> save(AppSettingsModel settings) async {
    stored = settings;
  }
}

OneTimeReminderModel _reminder() {
  final DateTime now = DateTime(2026, 10, 19, 9);
  return OneTimeReminderModel(
    id: 'r1',
    title: 'Agenda',
    iconKey: 'book',
    scheduledAt: now,
    preReminderMinutes: 10,
    isNotificationEnabled: true,
    isCompleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

AgendaNoteModel _note() {
  final DateTime now = DateTime(2026, 10, 19, 10);
  return AgendaNoteModel(
    id: 'n1',
    reminderId: 'r1',
    text: 'catatan',
    photoPaths: const <String>['/lokal/foto.jpg'],
    createdAt: now,
    updatedAt: now,
  );
}

AppSettingsModel _settings() {
  return const AppSettingsModel(
    morningReminderMinutes: 420,
    endOfDayReminderMinutes: 1260,
    localeCode: 'id',
    profileAvatarPath: '/lokal/avatar.png',
  );
}

void main() {
  group('Wiring S3 (reminders/notes/settings)', () {
    late _FakeAuthState auth;
    late _FakeRemindersBackend remindersBackend;
    late _FakeNotesBackend notesBackend;
    late _FakeSettingsBackend settingsBackend;
    late _FakeLocalReminder localReminder;
    late _FakeLocalSettings localSettings;

    setUp(() {
      auth = _FakeAuthState();
      remindersBackend = _FakeRemindersBackend();
      notesBackend = _FakeNotesBackend();
      settingsBackend = _FakeSettingsBackend();
      localReminder = _FakeLocalReminder();
      localSettings = _FakeLocalSettings();
    });

    ProviderContainer buildContainer({MigrationFlags? flags}) {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          cloudAuthStateProvider.overrideWithValue(auth),
          cloudRemindersBackendProvider.overrideWithValue(remindersBackend),
          cloudAgendaNotesBackendProvider.overrideWithValue(notesBackend),
          cloudSettingsBackendProvider.overrideWithValue(settingsBackend),
          oneTimeReminderLocalRepositoryProvider.overrideWithValue(
            localReminder,
          ),
          settingsLocalRepositoryProvider.overrideWithValue(localSettings),
          if (flags != null) migrationFlagsProvider.overrideWithValue(flags),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('default build mengikuti dart-define; tanpa define → jalur lama', () {
      final ProviderContainer container = buildContainer();
      final MigrationFlags flags = MigrationFlags.fromEnvironment;

      final OneTimeReminderRepository reminderRepo = container.read(
        oneTimeReminderRepositoryProvider,
      );
      if (flags.cloudFirstReminders || flags.cloudFirstNotes) {
        expect(reminderRepo, isA<CloudFirstOneTimeReminderRepository>());
      } else {
        expect(identical(reminderRepo, localReminder), isTrue);
      }

      final SettingsRepository settingsRepo = container.read(
        settingsRepositoryProvider,
      );
      if (flags.cloudFirstSettings) {
        expect(settingsRepo, isA<CloudFirstSettingsRepository>());
      } else {
        expect(identical(settingsRepo, localSettings), isTrue);
      }
    });

    test(
      'flag reminders ON saja: reminder ke cloud, catatan tetap Isar',
      () async {
        final ProviderContainer container = buildContainer(
          flags: const MigrationFlags(cloudFirstReminders: true),
        );
        final OneTimeReminderRepository repo = container.read(
          oneTimeReminderRepositoryProvider,
        );
        expect(repo, isA<CloudFirstOneTimeReminderRepository>());
        final CloudFirstOneTimeReminderRepository cloud =
            repo as CloudFirstOneTimeReminderRepository;
        expect(cloud.remindersCloudEnabled, isTrue);
        expect(cloud.notesCloudEnabled, isFalse);

        await repo.upsert(_reminder());
        expect(remindersBackend.setCalls, hasLength(1));
        expect(localReminder.reminders.single.id, 'r1');

        await repo.upsertNote(_note());
        expect(notesBackend.setCalls, isEmpty);
        expect(localReminder.notes.single.id, 'n1');
      },
    );

    test('flag notes ON saja: catatan ke cloud, reminder tetap Isar', () async {
      final ProviderContainer container = buildContainer(
        flags: const MigrationFlags(cloudFirstNotes: true),
      );
      final OneTimeReminderRepository repo = container.read(
        oneTimeReminderRepositoryProvider,
      );
      final CloudFirstOneTimeReminderRepository cloud =
          repo as CloudFirstOneTimeReminderRepository;
      expect(cloud.remindersCloudEnabled, isFalse);
      expect(cloud.notesCloudEnabled, isTrue);

      await repo.upsertNote(_note());
      expect(notesBackend.setCalls, hasLength(1));
      expect(
        notesBackend.setCalls.single.data.containsKey('photoPaths'),
        isFalse,
      );
      expect(localReminder.notes.single.photoPaths, <String>[
        '/lokal/foto.jpg',
      ]);

      await repo.upsert(_reminder());
      expect(remindersBackend.setCalls, isEmpty);
      expect(localReminder.reminders.single.id, 'r1');
    });

    test(
      'flag settings ON: save ke cloud + mirror; OFF: hanya lokal',
      () async {
        final ProviderContainer on = buildContainer(
          flags: const MigrationFlags(cloudFirstSettings: true),
        );
        final SettingsRepository cloudRepo = on.read(
          settingsRepositoryProvider,
        );
        expect(cloudRepo, isA<CloudFirstSettingsRepository>());

        await cloudRepo.save(_settings());
        expect(settingsBackend.setCalls, hasLength(1));
        expect(settingsBackend.setCalls.single.data['id'], 'app');

        final ProviderContainer off = buildContainer(
          flags: MigrationFlags.disabled,
        );
        final SettingsRepository localRepo = off.read(
          settingsRepositoryProvider,
        );
        expect(identical(localRepo, localSettings), isTrue);
        await localRepo.save(_settings());
        expect(settingsBackend.setCalls, hasLength(1));
      },
    );

    test('failures repo cloud-first terhubung ke provider bersama', () {
      final ProviderContainer container = buildContainer(
        flags: const MigrationFlags(
          cloudFirstReminders: true,
          cloudFirstNotes: true,
          cloudFirstSettings: true,
        ),
      );

      final CloudFirstOneTimeReminderRepository? reminders = container.read(
        cloudFirstOneTimeReminderRepositoryProvider,
      );
      expect(reminders, isNotNull);
      expect(
        identical(
          reminders!.failures,
          container.read(oneTimeReminderSyncFailuresProvider),
        ),
        isTrue,
      );

      final CloudFirstSettingsRepository? settings = container.read(
        cloudFirstSettingsRepositoryProvider,
      );
      expect(settings, isNotNull);
      expect(
        identical(
          settings!.failures,
          container.read(settingsSyncFailuresProvider),
        ),
        isTrue,
      );
    });

    test('flag OFF: accessor null + pending provider tidak aktif', () {
      final ProviderContainer container = buildContainer(
        flags: MigrationFlags.disabled,
      );

      expect(
        container.read(cloudFirstOneTimeReminderRepositoryProvider),
        isNull,
      );
      expect(container.read(cloudFirstSettingsRepositoryProvider), isNull);
      expect(container.read(reminderPendingIdsProvider).value, isNull);
      expect(container.read(notePendingIdsProvider).value, isNull);
      expect(container.read(settingsPendingIdsProvider).value, isNull);
    });
  });
}
