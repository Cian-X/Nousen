import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';
import 'package:nousen/features/settings/data/cloud_first_settings_repository.dart';
import 'package:nousen/features/settings/data/cloud_settings_backend.dart';
import 'package:nousen/features/settings/data/settings_sync_failures.dart';
import 'package:nousen/features/settings/domain/app_settings_model.dart';
import 'package:nousen/features/settings/domain/settings_repository.dart';
import 'package:nousen/features/settings/domain/weekly_routine_models.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeAuthState implements CloudAuthState {
  String? uid;

  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();

  @override
  String? get currentUid => uid;

  @override
  Stream<String?> uidChanges() => _changes.stream;

  void emit(String? next) {
    uid = next;
    _changes.add(next);
  }

  Future<void> dispose() => _changes.close();
}

class _SetCall {
  const _SetCall(this.uid, this.data);

  final String uid;
  final Map<String, dynamic> data;
}

class _FakeSettingsBackend implements CloudSettingsBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  final List<String> getCalls = <String>[];
  final List<String> watchUids = <String>[];
  final StreamController<CloudSettingsDoc?> _watch =
      StreamController<CloudSettingsDoc?>.broadcast();

  Map<String, dynamic>? data;
  Completer<void>? gate;
  Completer<void>? getGate;
  Object? failWith;
  Object? getFailWith;

  @override
  Future<void> setDoc(String uid, Map<String, dynamic> data) async {
    setCalls.add(_SetCall(uid, data));
    final Completer<void>? pending = gate;
    if (pending != null) {
      await pending.future;
    }
    final Object? error = failWith;
    if (error != null) {
      failWith = null;
      throw error;
    }
    this.data = data;
  }

  @override
  Stream<CloudSettingsDoc?> watchDoc(String uid) {
    watchUids.add(uid);
    return _watch.stream;
  }

  void push(Map<String, dynamic>? data, {bool pending = false}) {
    _watch.add(
      data == null
          ? null
          : CloudSettingsDoc(data: data, hasPendingWrites: pending),
    );
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid) async {
    getCalls.add(uid);
    final Completer<void>? pending = getGate;
    if (pending != null) {
      await pending.future;
    }
    final Object? error = getFailWith;
    if (error != null) {
      getFailWith = null;
      throw error;
    }
    return data;
  }

  Future<void> dispose() => _watch.close();
}

class _FakeLocalSettings implements SettingsRepository {
  _FakeLocalSettings(this.stored);

  AppSettingsModel stored;
  int getCalls = 0;
  final List<AppSettingsModel> saves = <AppSettingsModel>[];
  StreamController<AppSettingsModel>? _watch;

  @override
  Stream<AppSettingsModel> watch() {
    final StreamController<AppSettingsModel> controller = _watch ??=
        StreamController<AppSettingsModel>.broadcast();
    scheduleMicrotask(() => controller.add(stored));
    return controller.stream;
  }

  @override
  Future<AppSettingsModel> get() async {
    getCalls += 1;
    return stored;
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    stored = settings;
    saves.add(settings);
    _watch?.add(settings);
  }

  Future<void> dispose() async {
    await _watch?.close();
  }
}

AppSettingsModel _settings({
  String? profileName = 'Lokal',
  String localeCode = 'id',
  String? avatarPath = '/lokal/avatar.png',
  bool notificationsEnabled = true,
  bool notificationVibration = true,
  String? extraNote,
  bool hasSeededData = false,
}) {
  return AppSettingsModel(
    morningReminderMinutes: 420,
    endOfDayReminderMinutes: 1260,
    localeCode: localeCode,
    notificationsEnabled: notificationsEnabled,
    notificationVibration: notificationVibration,
    profileName: profileName,
    extraActivitiesNote: extraNote,
    profileAvatarPath: avatarPath,
    weeklyRoutine: normalizeWeeklyRoutine(const <WeeklyRoutineDayProfile>[
      WeeklyRoutineDayProfile(
        weekday: 1,
        kind: WeeklyRoutineDayKind.work,
        startMinutes: 480,
        endMinutes: 1020,
      ),
    ]),
    wakeUpMinutes: 390,
    sleepMinutes: 1350,
    hasSeededData: hasSeededData,
  );
}

void main() {
  group('S3 cloud-first settings', () {
    late _FakeAuthState auth;
    late _FakeSettingsBackend backend;
    late _FakeLocalSettings local;
    late SettingsSyncFailures failures;
    late CloudFirstSettingsRepository repo;

    setUp(() {
      auth = _FakeAuthState()..uid = 'u1';
      backend = _FakeSettingsBackend();
      local = _FakeLocalSettings(_settings());
      failures = SettingsSyncFailures();
      repo = CloudFirstSettingsRepository(
        backend: backend,
        authState: auth,
        mirror: local,
        failures: failures,
        cloudGetTimeout: const Duration(milliseconds: 200),
      );
    });

    tearDown(() async {
      failures.dispose();
      await auth.dispose();
      await backend.dispose();
      await local.dispose();
    });

    test(
      'save: dokumen settings/app tanpa path avatar + mirror segera',
      () async {
        final AppSettingsModel settings = _settings(
          profileName: 'Nama',
          avatarPath: '/lokal/avatar.png',
          extraNote: 'catatan ekstra',
          hasSeededData: true,
          notificationVibration: false,
        );

        await repo.save(settings);
        await _flush();

        final _SetCall call = backend.setCalls.single;
        expect(call.uid, 'u1');
        expect(call.data['id'], 'app');
        expect(call.data['profileName'], 'Nama');
        expect(call.data['morningReminderMinutes'], 420);
        expect(call.data['notificationsEnabled'], isTrue);
        expect(call.data.containsKey('profileAvatarPath'), isFalse);
        expect(call.data['deleted'], isFalse);
        expect(call.data['deletedAt'], isNull);
        expect(call.data['schemaVersion'], 2);
        expect(call.data['updatedAt'], isA<FieldValue>());
        expect(call.data['clientUpdatedAt'], isA<String>());

        final DecodedSettingsPayload payload = decodeSettingsPayload(
          call.data['weeklyRoutineJson'] as String?,
        );
        expect(payload.extraActivitiesNote, 'catatan ekstra');
        expect(payload.hasSeededData, isTrue);
        expect(payload.notificationVibration, isFalse);
        expect(payload.routine.first.kind, WeeklyRoutineDayKind.work);

        expect(local.saves.single.profileName, 'Nama');
        expect(local.saves.single.profileAvatarPath, '/lokal/avatar.png');
        expect(failures.byApp.value, isNull);
      },
    );

    test(
      'tulis non-blocking: mirror selesai walau ack server ditahan',
      () async {
        final Completer<void> gate = Completer<void>();
        backend.gate = gate;

        final Stopwatch watch = Stopwatch()..start();
        await repo.save(_settings());
        watch.stop();

        expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
        expect(local.saves, hasLength(1));

        gate.complete();
        await _flush();
      },
    );

    test('reject server: failure + event, mirror tetap; retry sukses '
        'membersihkan', () async {
      final List<SettingsSyncFailure> events = <SettingsSyncFailure>[];
      final StreamSubscription<SettingsSyncFailure> sub = failures.events
          .listen(events.add);
      addTearDown(sub.cancel);

      backend.failWith = Exception('permission-denied');
      await repo.save(_settings());
      await _flush();

      expect(events, hasLength(1));
      expect(events.single.operation, SettingsSyncOperation.save);
      expect(failures.byApp.value?.message, contains('permission-denied'));
      expect(local.saves, hasLength(1));

      await repo.save(_settings(profileName: 'Retry'));
      await _flush();

      expect(failures.byApp.value, isNull);
    });

    test('get login: cloud authoritative + overlay avatar lokal', () async {
      backend.data = CloudFirstSettingsRepository.settingsToMap(
        _settings(
          profileName: 'Cloud',
          localeCode: 'en',
          avatarPath: '/cloud/avatar.png',
          notificationsEnabled: false,
        ),
      );

      final AppSettingsModel result = await repo.get();

      expect(result.profileName, 'Cloud');
      expect(result.localeCode, 'en');
      expect(result.notificationsEnabled, isFalse);
      expect(result.profileAvatarPath, '/lokal/avatar.png');
      expect(backend.getCalls, <String>['u1']);
    });

    test('get logged out: langsung lokal tanpa panggil cloud', () async {
      auth.uid = null;

      final AppSettingsModel result = await repo.get();

      expect(result.profileName, 'Lokal');
      expect(backend.getCalls, isEmpty);
    });

    test(
      'get timeout/error cloud: fallback lokal (bootstrap tidak hang)',
      () async {
        backend.getGate = Completer<void>();

        final Stopwatch watch = Stopwatch()..start();
        final AppSettingsModel result = await repo.get();
        watch.stop();

        expect(result.profileName, 'Lokal');
        expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
        backend.getGate!.complete();
      },
    );

    test('watch login: cloud menang untuk preferensi, field lokal tetap '
        'dari mirror', () async {
      final List<AppSettingsModel> emissions = <AppSettingsModel>[];
      final StreamSubscription<AppSettingsModel> sub = repo.watch().listen(
        emissions.add,
      );
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();
      backend.push(
        CloudFirstSettingsRepository.settingsToMap(
          _settings(
            profileName: 'Cloud',
            localeCode: 'en',
            avatarPath: '/cloud/avatar.png',
          ),
        ),
      );
      await _flush();

      expect(emissions.last.profileName, 'Cloud');
      expect(emissions.last.localeCode, 'en');
      expect(emissions.last.profileAvatarPath, '/lokal/avatar.png');

      // Perubahan field lokal (avatar) tetap langsung terlihat walau cloud
      // tidak berubah.
      await local.save(local.stored.copyWith(profileAvatarPath: '/baru.png'));
      await _flush();
      expect(emissions.last.profileAvatarPath, '/baru.png');
      expect(emissions.last.profileName, 'Cloud');
    });

    test('sesi: logout → lokal; login → cloud (listen baru)', () async {
      final List<AppSettingsModel> emissions = <AppSettingsModel>[];
      final StreamSubscription<AppSettingsModel> sub = repo.watch().listen(
        emissions.add,
      );
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();
      backend.push(
        CloudFirstSettingsRepository.settingsToMap(
          _settings(profileName: 'Cloud'),
        ),
      );
      await _flush();
      expect(emissions.last.profileName, 'Cloud');

      auth.emit(null);
      await _flush();
      expect(emissions.last.profileName, 'Lokal');

      auth.emit('u1');
      await _flush();
      expect(backend.watchUids, <String>['u1', 'u1']);

      backend.push(
        CloudFirstSettingsRepository.settingsToMap(
          _settings(profileName: 'Cloud 2'),
        ),
      );
      await _flush();
      expect(emissions.last.profileName, 'Cloud 2');
    });

    test('watchPendingIds: {app} hanya saat hasPendingWrites', () async {
      final List<Set<String>> emissions = <Set<String>>[];
      final StreamSubscription<Set<String>> sub = repo.watchPendingIds().listen(
        emissions.add,
      );
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();

      backend.push(
        CloudFirstSettingsRepository.settingsToMap(_settings()),
        pending: true,
      );
      await _flush();
      expect(emissions.last, <String>{'app'});

      backend.push(CloudFirstSettingsRepository.settingsToMap(_settings()));
      await _flush();
      expect(emissions.last, isEmpty);
    });

    test('save logged out: hanya mirror, tidak ada tulisan cloud', () async {
      auth.uid = null;

      await repo.save(_settings(profileName: 'Lokal saja'));

      expect(backend.setCalls, isEmpty);
      expect(local.saves.single.profileName, 'Lokal saja');
    });

    test('schema dari cloud: profileAvatarPath tidak pernah diambil dari '
        'dokumen', () async {
      final Map<String, dynamic> doc =
          CloudFirstSettingsRepository.settingsToMap(_settings());
      doc['profileAvatarPath'] = '/dari/cloud.png';

      final AppSettingsModel result =
          CloudFirstSettingsRepository.settingsFromMap(
            doc,
            local: _settings(avatarPath: '/lokal.png'),
          );

      expect(result.profileAvatarPath, '/lokal.png');
    });
  });
}
