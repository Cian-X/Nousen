import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/progress/data/dual_write_progress_repository.dart';
import 'package:nousen/features/progress/data/firestore_progress_repository.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

class _FakeAuthState implements CloudAuthState {
  String? uid;

  @override
  String? get currentUid => uid;

  @override
  Stream<String?> uidChanges() => Stream<String?>.value(uid);
}

/// Lokal in-memory: meniru Isar untuk keperluan tes tulis/baca.
class _FakeLocalRepo implements ProgressRepository {
  final Map<String, ProgressEntryModel> store = <String, ProgressEntryModel>{};

  @override
  Stream<List<ProgressEntryModel>> watchAll() =>
      Stream<List<ProgressEntryModel>>.value(store.values.toList());

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) =>
      Stream<List<ProgressEntryModel>>.value(
        store.values.where((e) => e.activityId == activityId).toList(),
      );

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) =>
      Stream<List<ProgressEntryModel>>.value(
        store.values.where((e) => e.dateKey == dateKey).toList(),
      );

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) =>
      Stream<List<ProgressEntryModel>>.value(
        store.values
            .where((e) =>
                e.dateKey.compareTo(fromDateKey) >= 0 &&
                e.dateKey.compareTo(toDateKey) <= 0)
            .toList(),
      );

  @override
  Future<List<ProgressEntryModel>> getAll() async =>
      store.values.toList();

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async {
    for (final ProgressEntryModel e in store.values) {
      if (e.activityId == activityId && e.dateKey == dateKey) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    store[entry.id] = entry;
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    store.removeWhere((_, e) => e.activityId == activityId);
  }
}

/// Cloud fake: dapat dibuat gagal untuk menguji semantik kegagalan.
class _FakeCloudRepo implements ProgressRepository {
  final Map<String, ProgressEntryModel> store = <String, ProgressEntryModel>{};
  bool failWrites = false;
  int writeCalls = 0;

  @override
  Stream<List<ProgressEntryModel>> watchAll() =>
      Stream<List<ProgressEntryModel>>.value(store.values.toList());

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) =>
      Stream<List<ProgressEntryModel>>.value(const []);

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) =>
      Stream<List<ProgressEntryModel>>.value(const []);

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) =>
      Stream<List<ProgressEntryModel>>.value(const []);

  @override
  Future<List<ProgressEntryModel>> getAll() async =>
      store.values.toList();

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async =>
      null;

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    writeCalls++;
    if (failWrites) {
      throw StateError('cloud down');
    }
    store[entry.id] = entry;
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    writeCalls++;
    if (failWrites) {
      throw StateError('cloud down');
    }
    store.removeWhere((_, e) => e.activityId == activityId);
  }
}

ProgressEntryModel _entry({String id = 'e1'}) {
  final DateTime now = DateTime(2026, 10, 9, 10);
  return ProgressEntryModel(
    id: id,
    activityId: 'a1',
    dateKey: '2026-10-09',
    status: ActivityDayStatus.notDone,
    subCompleted: 0,
    subTotal: 0,
    completedSubActivities: const <String>[],
    photoPaths: const <String>[],
    photoPath: null,
    photoNote: null,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('DualWriteProgressRepository', () {
    test('baca selalu dari lokal, bukan cloud', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      await local.upsert(_entry());

      expect(await repo.getAll(), hasLength(1));
      expect(cloud.store, isEmpty);
    });

    test('login: tulis ke lokal dan cloud, status synced', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      await repo.upsert(_entry());

      expect(local.store.containsKey('e1'), isTrue);
      expect(cloud.store.containsKey('e1'), isTrue);
      expect(repo.syncState.value.status, CloudWriteStatus.synced);
    });

    test('logout: hanya lokal, status skippedOffline', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = null;
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      await repo.upsert(_entry());

      expect(local.store.containsKey('e1'), isTrue);
      expect(cloud.writeCalls, 0);
      expect(
        repo.syncState.value.status,
        CloudWriteStatus.skippedOffline,
      );
    });

    test('cloud gagal: lokal tetap tersimpan, status failed berisi pesan', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo()..failWrites = true;
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      // Tidak melempar: kegagalan cloud tidak merusak tulis lokal.
      await repo.upsert(_entry());

      expect(local.store.containsKey('e1'), isTrue);
      expect(repo.syncState.value.status, CloudWriteStatus.failed);
      expect(repo.syncState.value.message, isNotNull);
    });

    test('delete merambat ke kedua store saat login', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      await repo.upsert(_entry());

      await repo.deleteByActivity('a1');

      expect(local.store, isEmpty);
      expect(cloud.store, isEmpty);
      expect(repo.syncState.value.status, CloudWriteStatus.synced);
    });

    test('gagal login di tengah jalan tidak merusak data lama', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      await repo.upsert(_entry(id: 'lama'));
      cloud.failWrites = true;
      auth.uid = null;

      await repo.upsert(_entry(id: 'baru'));

      expect(local.store.containsKey('lama'), isTrue);
      expect(local.store.containsKey('baru'), isTrue);
      expect(
        repo.syncState.value.status,
        CloudWriteStatus.skippedOffline,
      );
    });

    test('restoreFromCloud tarik entry cloud ke lokal', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      // Simulasi: ada data di cloud tapi lokal kosong (install ulang).
      cloud.store['c1'] = _entry(id: 'c1');
      cloud.store['c2'] = _entry(id: 'c2');

      final int restored = await repo.restoreFromCloud();

      expect(restored, 2);
      expect(local.store.containsKey('c1'), isTrue);
      expect(local.store.containsKey('c2'), isTrue);
    });

    test('restoreFromCloud skip entry yang sudah ada di lokal', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = 'u1';
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );
      // Lokal sudah punya e1, cloud juga punya e1 + c2.
      await local.upsert(_entry(id: 'e1'));
      cloud.store['e1'] = _entry(id: 'e1');
      cloud.store['c2'] = _entry(id: 'c2');

      final int restored = await repo.restoreFromCloud();

      expect(restored, 1); // Hanya c2 yang baru.
      expect(local.store.length, 2);
    });

    test('restoreFromCloud tanpa login mengembalikan 0', () async {
      final _FakeLocalRepo local = _FakeLocalRepo();
      final _FakeCloudRepo cloud = _FakeCloudRepo();
      final _FakeAuthState auth = _FakeAuthState()..uid = null;
      final DualWriteProgressRepository repo = DualWriteProgressRepository(
        local: local,
        authState: auth,
        cloudFactory: (_) => cloud,
      );

      final int restored = await repo.restoreFromCloud();

      expect(restored, 0);
    });
  });

  group('FirestoreProgressRepository mapping', () {
    test('toMap/fromMap round-trip menjaga field sinkron', () {
      final ProgressEntryModel original = _entry();
      final ProgressEntryModel restored =
          FirestoreProgressRepository.fromMap(
        FirestoreProgressRepository.toMap(original),
      );
      expect(restored.id, original.id);
      expect(restored.activityId, original.activityId);
      expect(restored.dateKey, original.dateKey);
      expect(restored.status, original.status);
      expect(restored.subCompleted, original.subCompleted);
      expect(restored.subTotal, original.subTotal);
      expect(restored.notes, original.notes);
    });

    test('toMap tidak membawa path foto lokal perangkat', () {
      final Map<String, dynamic> map =
          FirestoreProgressRepository.toMap(_entry());
      expect(map.containsKey('photoPaths'), isFalse);
      expect(map.containsKey('photoPath'), isFalse);
    });
  });
}
