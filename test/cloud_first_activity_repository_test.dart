import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/data/cloud_activities_backend.dart';
import 'package:nousen/features/activity/data/cloud_first_activity_repository.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Biarkan microtask/timer nol terproses (event tracker dipancarkan async).
Future<void> _flush() => Future<void>.delayed(Duration.zero);

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
  final Map<String, Map<String, dynamic>> docs =
      <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>> queryResults = <Map<String, dynamic>>[];
  List<CloudActivityDoc> watchDocs = <CloudActivityDoc>[];
  bool failSets = false;
  bool failReads = false;

  /// Bila diisi, `setDoc` menggantung di gate ini — simulasi offline:
  /// ack server belum datang sampai gate di-complete / di-error.
  Completer<void>? setGate;

  /// Bila true, SETIAP `setDoc` menggantung di gate-nya sendiri
  /// ([setGates]) — simulasi ack out-of-order antar-operasi (ack lama
  /// datang setelah ack operasi terbaru).
  bool gateEachSet = false;
  final List<Completer<void>> setGates = <Completer<void>>[];

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(uid, docId, Map<String, dynamic>.from(data)));
    if (failSets) throw StateError('cloud down');
    if (gateEachSet) {
      final Completer<void> gate = Completer<void>();
      setGates.add(gate);
      await gate.future;
    } else {
      final Completer<void>? gate = setGate;
      if (gate != null) {
        await gate.future;
      }
    }
    docs[docId] = <String, dynamic>{...?docs[docId], ...data};
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    if (failReads) throw StateError('cloud down');
    return queryResults;
  }

  @override
  Stream<List<CloudActivityDoc>> watchVisible(String uid) {
    if (failReads) throw StateError('cloud down');
    return Stream<List<CloudActivityDoc>>.value(watchDocs);
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

  group('CloudFirstActivityRepository (S1b — offline UX: tidak menunggu '
      'ack, mirror segera, status pending/failed)', () {
    test(
      'upsert: cloud diinisiasi (merge set skema v2) + mirror Isar',
      () async {
        final ActivityModel activity = _activity();
        await repo.upsert(activity);

        expect(backend.setCalls, hasLength(1));
        final _SetCall call = backend.setCalls.single;
        expect(call.uid, 'u1');
        expect(call.docId, 'a1');
        expect(call.data['deleted'], isFalse);
        expect(call.data['schemaVersion'], 2);
        expect(call.data['updatedAt'], isA<FieldValue>());
        expect(
          call.data['clientUpdatedAt'],
          activity.updatedAt.toIso8601String(),
        );
        expect(call.data['title'], 'Test Activity');

        expect(mirror.upsertCalls, 1);
        expect(mirror.store['a1']?.title, 'Test Activity');
      },
    );

    test('upsert kedua (edit): cloud dan mirror ikut ter-update', () async {
      await repo.upsert(_activity());
      await repo.upsert(_activity(title: 'Judul Baru'));

      expect(backend.setCalls, hasLength(2));
      expect(backend.setCalls.last.data['title'], 'Judul Baru');
      expect(mirror.upsertCalls, 2);
      expect(mirror.store['a1']?.title, 'Judul Baru');
    });

    test('upsert offline (ack server menggantung): selesai cepat + mirror '
        'sudah ditulis + belum ada status failed', () async {
      backend.setGate = Completer<void>();

      await repo.upsert(_activity()).timeout(const Duration(seconds: 2));

      expect(backend.setCalls, hasLength(1));
      expect(mirror.upsertCalls, 1);
      expect(mirror.store.containsKey('a1'), isTrue);
      expect(repo.failures.byActivity.value, isEmpty);
    });

    test('reject server (rules/auth) → failure tercatat per-activity + event '
        'broadcast (non-silent) + mirror tetap ditulis', () async {
      final List<ActivitySyncFailure> events = <ActivitySyncFailure>[];
      final StreamSubscription<ActivitySyncFailure> sub = repo.failures.events
          .listen(events.add);
      addTearDown(sub.cancel);

      backend.setGate = Completer<void>();
      await repo.upsert(_activity());
      backend.setGate!.completeError(StateError('rules tolak'));
      await _flush();

      expect(events, hasLength(1));
      expect(events.single.activityId, 'a1');
      expect(events.single.operation, ActivitySyncOperation.save);
      expect(events.single.message, contains('rules tolak'));

      final ActivitySyncFailure? failure = repo.failures.byActivity.value['a1'];
      expect(failure, isNotNull);
      expect(failure!.operation, ActivitySyncOperation.save);
      // Mirror tetap ditulis (local-first) walau cloud menolak.
      expect(mirror.store.containsKey('a1'), isTrue);
    });

    test('ack sukses berikutnya membersihkan status failed (sembuh)', () async {
      backend.setGate = Completer<void>();
      await repo.upsert(_activity());
      backend.setGate!.completeError(StateError('rules tolak'));
      await _flush();
      expect(repo.failures.byActivity.value.containsKey('a1'), isTrue);

      backend.setGate = null;
      await repo.upsert(_activity(title: 'Edit Setelah Reject'));
      await _flush();

      expect(repo.failures.byActivity.value, isEmpty);
    });

    test('ack out-of-order (save/save): reject lama tidak menimpa ack sukses '
        'operasi terbaru', () async {
      backend.gateEachSet = true;
      await repo.upsert(_activity());
      await repo.upsert(_activity(title: 'B'));
      expect(backend.setGates, hasLength(2));

      backend.setGates[1].complete(); // B (terbaru) ack sukses dulu
      await _flush();
      expect(repo.failures.byActivity.value, isEmpty);

      backend.setGates[0].completeError(StateError('rules tolak A lama'));
      await _flush();

      expect(
        repo.failures.byActivity.value,
        isEmpty,
        reason: 'reject dari operasi yang sudah digantikan harus diabaikan '
            '(tidak boleh menampilkan failed walau versi terbaru synced)',
      );
    });

    test('ack out-of-order (save/save): ack sukses lama tidak membersihkan '
        'reject operasi terbaru', () async {
      backend.gateEachSet = true;
      await repo.upsert(_activity());
      await repo.upsert(_activity(title: 'B'));

      backend.setGates[1].completeError(StateError('rules tolak B'));
      await _flush();
      expect(repo.failures.byActivity.value.containsKey('a1'), isTrue);

      backend.setGates[0].complete(); // ack A lama telat sukses
      await _flush();

      expect(
        repo.failures.byActivity.value.containsKey('a1'),
        isTrue,
        reason: 'ack sukses lama tidak boleh membersihkan reject operasi '
            'terbaru',
      );
    });

    test('ack out-of-order (save/delete): reject edit lama tidak menimpa '
        'delete terbaru', () async {
      await repo.upsert(_activity());
      backend.gateEachSet = true;

      await repo.upsert(_activity(title: 'Edit'));
      await repo.delete('a1');
      expect(backend.setGates, hasLength(2));

      backend.setGates[1].complete(); // delete (terbaru) ack sukses dulu
      await _flush();

      backend.setGates[0].completeError(StateError('rules tolak edit lama'));
      await _flush();

      expect(
        repo.failures.byActivity.value,
        isEmpty,
        reason: 'reject edit yang sudah digantikan delete tidak boleh muncul',
      );
      expect(mirror.store, isEmpty);
    });

    test('ack out-of-order (delete/save): reject delete terbaru tetap '
        'tercatat walau ack edit lama telat sukses', () async {
      await repo.upsert(_activity());
      backend.gateEachSet = true;

      await repo.upsert(_activity(title: 'Edit'));
      await repo.delete('a1');

      backend.setGates[1].completeError(StateError('permission-denied'));
      await _flush();
      expect(
        repo.failures.byActivity.value['a1']?.operation,
        ActivitySyncOperation.delete,
      );

      backend.setGates[0].complete(); // ack edit lama telat sukses
      await _flush();

      expect(
        repo.failures.byActivity.value['a1']?.operation,
        ActivitySyncOperation.delete,
        reason: 'ack sukses lama tidak boleh membersihkan reject delete '
            'terbaru',
      );
    });

    test('delete: tombstone cloud diinisiasi + mirror LANGSUNG terhapus walau '
        'ack menggantung (rollback flag OFF tidak resurrect)', () async {
      await repo.upsert(_activity());
      backend.setGate = Completer<void>();

      await repo.delete('a1').timeout(const Duration(seconds: 2));

      final _SetCall tombstone = backend.setCalls.last;
      expect(tombstone.docId, 'a1');
      expect(tombstone.data.keys.toSet(), <String>{
        'deleted',
        'deletedAt',
        'updatedAt',
        'schemaVersion',
      });
      expect(tombstone.data['deleted'], isTrue);
      expect(tombstone.data['deletedAt'], isA<FieldValue>());
      expect(tombstone.data['updatedAt'], isA<FieldValue>());
      expect(tombstone.data['schemaVersion'], 2);

      expect(mirror.deleteCalls, 1);
      // Sumber rollback (Isar) sudah kosong → tidak ada resurrect.
      expect(mirror.store, isEmpty);
      expect(repo.failures.byActivity.value, isEmpty);
    });

    test(
      'delete ack reject → failure delete tercatat; mirror tetap terhapus',
      () async {
        await repo.upsert(_activity());
        backend.setGate = Completer<void>();
        await repo.delete('a1');
        backend.setGate!.completeError(StateError('permission-denied'));
        await _flush();

        final ActivitySyncFailure? failure =
            repo.failures.byActivity.value['a1'];
        expect(failure, isNotNull);
        expect(failure!.operation, ActivitySyncOperation.delete);
        expect(mirror.store, isEmpty);
      },
    );

    test('watchPendingIds: hanya hasPendingWrites; deleted difilter', () async {
      backend.watchDocs = <CloudActivityDoc>[
        CloudActivityDoc(
          id: 'a1',
          data: _cloudDoc('a1'),
          hasPendingWrites: true,
        ),
        CloudActivityDoc(
          id: 'a2',
          data: _cloudDoc('a2'),
          hasPendingWrites: false,
        ),
        CloudActivityDoc(
          id: 'a3',
          data: _cloudDoc('a3', deleted: true),
          hasPendingWrites: true,
        ),
      ];

      final Set<String> pending = await repo.watchPendingIds().first;

      expect(pending, <String>{'a1'});
    });

    test(
      'getAll: baca dari cloud, filter deleted, mirror tidak disentuh',
      () async {
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
      },
    );

    test(
      'getById: null saat tidak ada / tombstone; model saat visible',
      () async {
        backend.docs['x1'] = _cloudDoc('x1');
        backend.docs['x2'] = _cloudDoc('x2', deleted: true);

        expect((await repo.getById('x1'))?.id, 'x1');
        expect(await repo.getById('x2'), isNull);
        expect(await repo.getById('tidak-ada'), isNull);
        expect(mirror.readCalls, 0);
      },
    );

    test('watchAll: stream cloud difilter deleted', () async {
      backend.watchDocs = <CloudActivityDoc>[
        CloudActivityDoc(
          id: 'a1',
          data: _cloudDoc('a1'),
          hasPendingWrites: false,
        ),
        CloudActivityDoc(
          id: 'a2',
          data: _cloudDoc('a2', deleted: true),
          hasPendingWrites: false,
        ),
      ];

      final List<ActivityModel> first = await repo.watchAll().first;

      expect(first.map((ActivityModel a) => a.id), <String>['a1']);
    });

    test('cloud invoke langsung error → operasi tetap selesai (mirror jalan) + '
        'failure tercatat', () async {
      backend.failSets = true;

      await repo.upsert(_activity());
      await _flush();

      expect(backend.setCalls, hasLength(1));
      expect(mirror.store.containsKey('a1'), isTrue);
      expect(repo.failures.byActivity.value.containsKey('a1'), isTrue);
    });

    test(
      'mirror upsert gagal → upsert tetap sukses (cloud tetap dikirim)',
      () async {
        mirror.failWrites = true;

        await repo.upsert(_activity());
        await _flush();

        expect(backend.setCalls, hasLength(1));
        expect(mirror.upsertCalls, 1);
        expect(mirror.store, isEmpty);
        expect(repo.failures.byActivity.value, isEmpty);
      },
    );

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
      expect(repo.failures.byActivity.value, isEmpty);
    });

    test('fromFirestoreMap menormalkan Timestamp server ke ISO', () {
      final ActivityModel model =
          CloudFirstActivityRepository.fromFirestoreMap(<String, dynamic>{
            'id': 'x1',
            'title': 'Judul',
            'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 17, 12, 30)),
          });

      expect(model.id, 'x1');
      expect(model.updatedAt, DateTime(2026, 10, 17, 12, 30));
    });
  });

  group('ActivitySyncFailures (S1b)', () {
    test('record → byActivity + event; clear menghapus; event utuh', () async {
      final ActivitySyncFailures tracker = ActivitySyncFailures();
      addTearDown(tracker.dispose);
      final List<ActivitySyncFailure> events = <ActivitySyncFailure>[];
      final StreamSubscription<ActivitySyncFailure> sub = tracker.events.listen(
        events.add,
      );
      addTearDown(sub.cancel);

      tracker.record(
        activityId: 'a1',
        operation: ActivitySyncOperation.save,
        error: StateError('x'),
      );
      tracker.record(
        activityId: 'a1',
        operation: ActivitySyncOperation.delete,
        error: StateError('y'),
      );
      await _flush();

      expect(events, hasLength(2));
      expect(
        tracker.byActivity.value['a1']!.operation,
        ActivitySyncOperation.delete,
      );

      tracker.clear('a1');
      expect(tracker.byActivity.value, isEmpty);
    });

    test('pesan error panjang dipotong', () {
      final ActivitySyncFailures tracker = ActivitySyncFailures();
      addTearDown(tracker.dispose);

      tracker.record(
        activityId: 'a1',
        operation: ActivitySyncOperation.save,
        error: StateError(List<String>.filled(500, 'x').join()),
      );

      final String message = tracker.byActivity.value['a1']!.message;
      expect(message.length, lessThanOrEqualTo(161));
      expect(message.endsWith('…'), isTrue);
    });
  });
}
