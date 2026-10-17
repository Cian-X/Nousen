import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/core/migration/migration_flags.dart';
import 'package:nousen/features/activity/data/cloud_activities_backend.dart';
import 'package:nousen/features/activity/data/cloud_first_activity_repository.dart';
import 'package:nousen/features/activity/data/dual_write_activity_repository.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

class _FakeAuthState implements CloudAuthState {
  String? uid;

  @override
  String? get currentUid => uid;

  @override
  Stream<String?> uidChanges() => Stream<String?>.value(uid);
}

class _SetCall {
  _SetCall(this.docId, this.data);

  final String docId;
  final Map<String, dynamic> data;
}

class _FakeBackend implements CloudActivitiesBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  List<Map<String, dynamic>> queryResults = <Map<String, dynamic>>[];

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(docId, Map<String, dynamic>.from(data)));
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    return queryResults;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchVisible(String uid) {
    return Stream<List<Map<String, dynamic>>>.value(queryResults);
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async => null;
}

class _FakeLocalRepo implements ActivityRepository {
  final Map<String, ActivityModel> store = <String, ActivityModel>{};

  @override
  Stream<List<ActivityModel>> watchAll() =>
      Stream<List<ActivityModel>>.value(store.values.toList());

  @override
  Future<List<ActivityModel>> getAll() async => store.values.toList();

  @override
  Future<ActivityModel?> getById(String id) async => store[id];

  @override
  Future<void> upsert(ActivityModel activity) async {
    store[activity.id] = activity;
  }

  @override
  Future<void> delete(String id) async {
    store.remove(id);
  }
}

ActivityModel _activity({String id = 'a1'}) {
  final DateTime now = DateTime(2026, 10, 17, 10);
  return ActivityModel(
    id: id,
    title: 'Test Activity',
    selectedDays: const <int>[1, 2, 3],
    subActivities: const <String>['sub1'],
    timeMinutes: 30,
    weeklyGoal: 3,
    preReminderMinutes: 15,
    isNotificationEnabled: true,
    enableMorningReminder: false,
    enableEndOfDayReminder: false,
    enablePhotoProgress: false,
    lastThreeDayRuleNotifiedDate: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Wiring activityRepositoryProvider (S1)', () {
    late _FakeBackend backend;
    late _FakeLocalRepo local;
    late _FakeAuthState auth;

    setUp(() {
      backend = _FakeBackend();
      local = _FakeLocalRepo();
      auth = _FakeAuthState()..uid = 'u1';
    });

    ProviderContainer buildContainer({MigrationFlags? flags}) {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          cloudActivitiesBackendProvider.overrideWithValue(backend),
          activityLocalRepositoryProvider.overrideWithValue(local),
          cloudAuthStateProvider.overrideWithValue(auth),
          if (flags != null) migrationFlagsProvider.overrideWithValue(flags),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'default build mengikuti dart-define: tanpa define → dual-write, '
      'dengan define → cloud-first',
      () {
        // Jalur default (tanpa override flag) — ini yang dipakai APK owner.
        final ActivityRepository picked = buildContainer().read(
          activityRepositoryProvider,
        );

        if (MigrationFlags.fromEnvironment.cloudFirstActivities) {
          expect(picked, isA<CloudFirstActivityRepository>());
        } else {
          expect(picked, isA<DualWriteActivityRepository>());
        }
      },
    );

    test('flag ON: CRUD lewat provider → cloud primer + mirror Isar hidup', () async {
      final ActivityRepository picked = buildContainer(
        flags: const MigrationFlags(cloudFirstActivities: true),
      ).read(activityRepositoryProvider);
      expect(picked, isA<CloudFirstActivityRepository>());

      await picked.upsert(_activity());
      expect(backend.setCalls, hasLength(1));
      expect(backend.setCalls.single.data['deleted'], isFalse);
      expect(local.store.containsKey('a1'), isTrue);

      backend.queryResults = <Map<String, dynamic>>[
        <String, dynamic>{'id': 'a1', 'title': 'Test Activity', 'deleted': false},
      ];
      final List<ActivityModel> all = await picked.getAll();
      expect(all.map((ActivityModel a) => a.id), contains('a1'));

      await picked.delete('a1');
      expect(backend.setCalls.last.data['deleted'], isTrue);
      expect(local.store, isEmpty);
    });

    test(
      'flag OFF: jalur lama — tulis ke lokal; cloud dilewati saat uid null',
      () async {
        auth.uid = null;
        final ActivityRepository picked = buildContainer(
          flags: MigrationFlags.disabled,
        ).read(activityRepositoryProvider);
        expect(picked, isA<DualWriteActivityRepository>());

        await picked.upsert(_activity());

        expect(local.store.containsKey('a1'), isTrue);
        expect(backend.setCalls, isEmpty);
      },
    );
  });
}
