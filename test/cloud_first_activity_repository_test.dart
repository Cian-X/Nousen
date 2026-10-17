import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/activity/data/cloud_activities_backend.dart';
import 'package:nousen/features/activity/data/cloud_first_activity_repository.dart';
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
  _SetCall(this.uid, this.docId, this.data);

  final String uid;
  final String docId;
  final Map<String, dynamic> data;
}

class _FakeBackend implements CloudActivitiesBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  final Map<String, Map<String, dynamic>> docs = <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>> queryResults = <Map<String, dynamic>>[];
  bool failSets = false;
  bool failReads = false;

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(uid, docId, Map<String, dynamic>.from(data)));
    if (failSets) throw StateError('cloud down');
    docs[docId] = <String, dynamic>{...?docs[docId], ...data};
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    if (failReads) throw StateError('cloud down');
    return queryResults;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchVisible(String uid) {
    if (failReads) throw StateError('cloud down');
    return Stream<List<Map<String, dynamic>>>.value(queryResults);
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async {
    if (failReads) throw StateError('cloud down');
    return docs[docId];
  }
}

class _FakeMirrorRepo implements ActivityRepository {
  final Map<String, ActivityModel> store = <String, ActivityModel>{};
  bool failWrites = false;
  int upsertCalls = 0;
  int deleteCalls = 0;
  int readCalls = 0;

  @override
  Stream<List<ActivityModel>> watchAll() {
    readCalls++;
    return Stream<List<ActivityModel>>.value(store.values.toList());
  }

  @override
  Future<List<ActivityModel>> getAll() async {
    readCalls++;
    return store.values.toList();
  }

  @override
  Future<ActivityModel?> getById(String id) async {
    readCalls++;
    return store[id];
  }

  @override
  Future<void> upsert(ActivityModel activity) async {
    upsertCalls++;
    if (failWrites) throw StateError('isar down');
    store[activity.id] = activity;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    if (failWrites) throw StateError('isar down');
    store.remove(id);
  }
}

ActivityModel _activity({String id = 'a1', String title = 'Test Activity'}) {
  final DateTime now = DateTime(2026, 10, 17, 10);
  return ActivityModel(
    id: id,
    title: title,
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

Map<String, dynamic> _cloudDoc(
  String id, {
  String title = 'Test Activity',
  bool deleted = false,
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'deleted': deleted,
    'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1, 8)),
    'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 17, 9)),
  };
}

void main() {
  late _FakeAuthState auth;
  late _FakeBackend backend;
  late _FakeMirrorRepo mirror;
  late CloudFirstActivityRepository repo;

  setUp(() {
    auth = _FakeAuthState()..uid = 'u1';
    backend = _FakeBackend();
    mirror = _FakeMirrorRepo();
    repo = CloudFirstActivityRepository(
      backend: backend,
      authState: auth,
      mirror: mirror,
    );
  });

  group('CloudFirstActivityRepository (S1 — cloud-first + mirror Isar)', () {
    test('upsert: cloud dulu (merge set skema v2), lalu mirror Isar', () async {
      final ActivityModel activity = _activity();
      await repo.upsert(activity);

      expect(backend.setCalls, hasLength(1));
      final _SetCall call = backend.setCalls.single;
      expect(call.uid, 'u1');
      expect(call.docId, 'a1');
      expect(call.data['deleted'], isFalse);
      expect(call.data['schemaVersion'], 2);
      expect(call.data['updatedAt'], isA<FieldValue>());
      expect(call.data['clientUpdatedAt'], activity.updatedAt.toIso8601String());
      expect(call.data['title'], 'Test Activity');

      expect(mirror.upsertCalls, 1);
      expect(mirror.store['a1']?.title, 'Test Activity');
    });

    test('upsert kedua (edit): cloud dan mirror ikut ter-update', () async {
      await repo.upsert(_activity());
      await repo.upsert(_activity(title: 'Judul Baru'));

      expect(backend.setCalls, hasLength(2));
      expect(backend.setCalls.last.data['title'], 'Judul Baru');
      expect(mirror.upsertCalls, 2);
      expect(mirror.store['a1']?.title, 'Judul Baru');
    });

    test('delete: tombstone cloud dulu, lalu mirror.delete', () async {
      await repo.upsert(_activity());
      await repo.delete('a1');

      final _SetCall tombstone = backend.setCalls.last;
      expect(tombstone.docId, 'a1');
      expect(
        tombstone.data.keys.toSet(),
        <String>{'deleted', 'deletedAt', 'updatedAt', 'schemaVersion'},
      );
      expect(tombstone.data['deleted'], isTrue);
      expect(tombstone.data['deletedAt'], isA<FieldValue>());
      expect(tombstone.data['updatedAt'], isA<FieldValue>());
      expect(tombstone.data['schemaVersion'], 2);

      expect(mirror.deleteCalls, 1);
      expect(mirror.store, isEmpty);
    });

    test('getAll: baca dari cloud, filter deleted, mirror tidak disentuh', () async {
      backend.queryResults = <Map<String, dynamic>>[
        _cloudDoc('a2', title: 'Zebra'),
        _cloudDoc('a1', title: 'Alpha'),
        _cloudDoc('a3', title: 'Ghost', deleted: true),
      ];

      final List<ActivityModel> all = await repo.getAll();

      expect(all.map((ActivityModel a) => a.id), <String>['a1', 'a2']);
      expect(all.first.updatedAt, DateTime(2026, 10, 17, 9));
      expect(all.last.title, 'Zebra');
      expect(mirror.readCalls, 0);
      expect(mirror.upsertCalls, 0);
      expect(mirror.deleteCalls, 0);
    });

    test('getById: null saat tidak ada / tombstone; model saat visible', () async {
      backend.docs['x1'] = _cloudDoc('x1');
      backend.docs['x2'] = _cloudDoc('x2', deleted: true);

      expect((await repo.getById('x1'))?.id, 'x1');
      expect(await repo.getById('x2'), isNull);
      expect(await repo.getById('tidak-ada'), isNull);
      expect(mirror.readCalls, 0);
    });

    test('watchAll: stream cloud difilter deleted', () async {
      backend.queryResults = <Map<String, dynamic>>[
        _cloudDoc('a1'),
        _cloudDoc('a2', deleted: true),
      ];

      final List<ActivityModel> first = await repo.watchAll().first;

      expect(first.map((ActivityModel a) => a.id), <String>['a1']);
    });

    test('cloud upsert gagal → rethrow dan mirror TIDAK ditulis', () async {
      backend.failSets = true;

      await expectLater(repo.upsert(_activity()), throwsStateError);

      expect(mirror.upsertCalls, 0);
      expect(mirror.store, isEmpty);
    });

    test('cloud delete gagal → rethrow dan mirror TIDAK dihapus', () async {
      await repo.upsert(_activity());
      backend.failSets = true;

      await expectLater(repo.delete('a1'), throwsStateError);

      expect(mirror.deleteCalls, 0);
      expect(mirror.store.containsKey('a1'), isTrue);
    });

    test('mirror upsert gagal → upsert tetap sukses (cloud tersimpan)', () async {
      mirror.failWrites = true;

      await repo.upsert(_activity());

      expect(backend.setCalls, hasLength(1));
      expect(mirror.upsertCalls, 1);
      expect(mirror.store, isEmpty);
    });

    test('mirror delete gagal → delete tetap sukses', () async {
      await repo.upsert(_activity());
      mirror.failWrites = true;

      await repo.delete('a1');

      expect(backend.setCalls.last.data['deleted'], isTrue);
      expect(mirror.deleteCalls, 1);
    });

    test('tanpa login: StateError; backend & mirror tidak disentuh', () async {
      auth.uid = null;

      expect(() => repo.watchAll(), throwsStateError);
      await expectLater(repo.getAll(), throwsStateError);
      await expectLater(repo.getById('a1'), throwsStateError);
      await expectLater(repo.upsert(_activity()), throwsStateError);
      await expectLater(repo.delete('a1'), throwsStateError);

      expect(backend.setCalls, isEmpty);
      expect(mirror.upsertCalls, 0);
      expect(mirror.deleteCalls, 0);
      expect(mirror.readCalls, 0);
    });

    test('fromFirestoreMap menormalkan Timestamp server ke ISO', () {
      final ActivityModel model = CloudFirstActivityRepository.fromFirestoreMap(
        <String, dynamic>{
          'id': 'x1',
          'title': 'Judul',
          'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 17, 12, 30)),
        },
      );

      expect(model.id, 'x1');
      expect(model.updatedAt, DateTime(2026, 10, 17, 12, 30));
    });
  });
}
