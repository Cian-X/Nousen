import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/activity/data/dual_write_activity_repository.dart';
import 'package:nousen/features/activity/data/firestore_activity_repository.dart';
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

class _FakeCloudRepo implements ActivityRepository {
  final Map<String, ActivityModel> store = <String, ActivityModel>{};
  bool failWrites = false;
  int writeCalls = 0;

  @override
  Stream<List<ActivityModel>> watchAll() =>
      Stream<List<ActivityModel>>.value(store.values.toList());

  @override
  Future<List<ActivityModel>> getAll() async => store.values.toList();

  @override
  Future<ActivityModel?> getById(String id) async => store[id];

  @override
  Future<void> upsert(ActivityModel activity) async {
    writeCalls++;
    if (failWrites) throw StateError('cloud down');
    store[activity.id] = activity;
  }

  @override
  Future<void> delete(String id) async {
    writeCalls++;
    if (failWrites) throw StateError('cloud down');
    store.remove(id);
  }
}

ActivityModel _activity({String id = 'a1'}) {
  final DateTime now = DateTime(2026, 10, 14, 10);
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
  group('DualWriteActivityRepository', () {
    test('baca selalu dari lokal', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = 'u1';
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      await local.upsert(_activity());

      expect(await repo.getAll(), hasLength(1));
      expect(cloud.store, isEmpty);
    });

    test('login: tulis ke lokal dan cloud', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = 'u1';
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      await repo.upsert(_activity());

      expect(local.store.containsKey('a1'), isTrue);
      expect(cloud.store.containsKey('a1'), isTrue);
    });

    test('logout: hanya lokal', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = null;
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      await repo.upsert(_activity());

      expect(local.store.containsKey('a1'), isTrue);
      expect(cloud.writeCalls, 0);
    });

    test('cloud gagal: lokal tetap tersimpan', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo()..failWrites = true;
      final auth = _FakeAuthState()..uid = 'u1';
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      await repo.upsert(_activity());

      expect(local.store.containsKey('a1'), isTrue);
    });

    test('delete merambat ke kedua store', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = 'u1';
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      await repo.upsert(_activity());

      await repo.delete('a1');

      expect(local.store, isEmpty);
      expect(cloud.store, isEmpty);
    });

    test('restoreFromCloud tarik activity cloud ke lokal', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = 'u1';
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      cloud.store['c1'] = _activity(id: 'c1');
      cloud.store['c2'] = _activity(id: 'c2');

      final int restored = await repo.restoreFromCloud();

      expect(restored, 2);
      expect(local.store.containsKey('c1'), isTrue);
      expect(local.store.containsKey('c2'), isTrue);
    });

    test('restoreFromCloud skip yang sudah ada di lokal', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = 'u1';
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      await local.upsert(_activity(id: 'a1'));
      cloud.store['a1'] = _activity(id: 'a1');
      cloud.store['c2'] = _activity(id: 'c2');

      final int restored = await repo.restoreFromCloud();

      expect(restored, 1);
      expect(local.store.length, 2);
    });

    test('restoreFromCloud tanpa login return 0', () async {
      final local = _FakeLocalRepo();
      final cloud = _FakeCloudRepo();
      final auth = _FakeAuthState()..uid = null;
      final repo = DualWriteActivityRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      final int restored = await repo.restoreFromCloud();

      expect(restored, 0);
    });
  });

  group('FirestoreActivityRepository mapping', () {
    test('toMap/fromMap round-trip', () {
      final original = _activity();
      final restored = FirestoreActivityRepository.fromMap(
        FirestoreActivityRepository.toMap(original),
      );
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.selectedDays, original.selectedDays);
      expect(restored.subActivities, original.subActivities);
      expect(restored.timeMinutes, original.timeMinutes);
      expect(restored.weeklyGoal, original.weeklyGoal);
      expect(restored.category, original.category);
      expect(restored.family, original.family);
    });
  });
}
