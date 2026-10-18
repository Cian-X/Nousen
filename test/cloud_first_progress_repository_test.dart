import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/progress/data/cloud_first_progress_repository.dart';
import 'package:nousen/features/progress/data/cloud_progress_backend.dart';
import 'package:nousen/features/progress/data/firestore_progress_repository.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Biarkan microtask/timer nol terproses (event tracker dipancarkan async).
Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeAuthState implements CloudAuthState {
  String? uid;

  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();

  @override
  String? get currentUid => uid;

  /// Pola `authStateChanges`: emisi awal = sesi saat ini, lalu setiap
  /// transisi login/logout berikutnya.
  @override
  Stream<String?> uidChanges() async* {
    yield uid;
    yield* _changes.stream;
  }

  /// Simulasi transisi sesi berikutnya (logout: null; login: uid baru).
  void emitUidChange(String? next) {
    uid = next;
    _changes.add(next);
  }

  Future<void> close() => _changes.close();
}

class _SetCall {
  _SetCall(this.uid, this.docId, this.data);

  final String uid;
  final String docId;
  final Map<String, dynamic> data;
}

class _FakeBackend implements CloudProgressBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  final List<String> deleteCalls = <String>[];
  final Map<String, Map<String, dynamic>> docs =
      <String, Map<String, dynamic>>{};
  List<CloudProgressDoc> watchDocs = <CloudProgressDoc>[];
  List<Map<String, dynamic>> queryResults = <Map<String, dynamic>>[];
  bool failSets = false;
  bool failDeletes = false;

  /// Bila diisi, `setDoc` menggantung di gate ini — simulasi offline:
  /// ack server belum datang sampai gate di-complete / di-error.
  Completer<void>? setGate;

  /// Bila true, SETIAP `setDoc` menggantung di gate-nya sendiri
  /// ([setGates]) — simulasi ack out-of-order antar-operasi.
  bool gateEachSet = false;
  final List<Completer<void>> setGates = <Completer<void>>[];

  /// Gate untuk `deleteByActivity` (single dan per-call).
  Completer<void>? deleteGate;
  bool gateEachDelete = false;
  final List<Completer<void>> deleteGates = <Completer<void>>[];

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
  Future<void> deleteByActivity(String uid, String activityId) async {
    deleteCalls.add(activityId);
    if (failDeletes) throw StateError('cloud down');
    if (gateEachDelete) {
      final Completer<void> gate = Completer<void>();
      deleteGates.add(gate);
      await gate.future;
    } else {
      final Completer<void>? gate = deleteGate;
      if (gate != null) {
        await gate.future;
      }
    }
    docs.removeWhere((_, Map<String, dynamic> d) =>
        d['activityId'] == activityId);
  }

  /// uid setiap listen cloud dibuat (bukti re-subscribe antar sesi).
  final List<String> watchUids = <String>[];

  /// Data khusus per uid; bila tidak diisi pakai [watchDocs].
  final Map<String, List<CloudProgressDoc>> watchDocsByUid =
      <String, List<CloudProgressDoc>>{};

  /// Bila true, `watchAll` mengembalikan stream yang TIDAK selesai sampai
  /// dibatalkan — pola `snapshots()` Firestore. Dipakai tes ganti sesi:
  /// bug device terjadi karena `asyncExpand` mem-pause source sesi selama
  /// stream konversi hidup, dan stream Firestore tidak pernah selesai.
  bool keepWatchOpen = false;

  /// Controller per listen saat [keepWatchOpen] (indeks = urutan listen).
  final List<StreamController<List<CloudProgressDoc>>> watchControllers =
      <StreamController<List<CloudProgressDoc>>>[];

  @override
  Stream<List<CloudProgressDoc>> watchAll(String uid) {
    watchUids.add(uid);
    final List<CloudProgressDoc> docs = watchDocsByUid[uid] ?? watchDocs;
    if (!keepWatchOpen) {
      return Stream<List<CloudProgressDoc>>.value(docs);
    }
    final StreamController<List<CloudProgressDoc>> controller =
        StreamController<List<CloudProgressDoc>>();
    watchControllers.add(controller);
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(docs);
      }
    });
    return controller.stream;
  }

  @override
  Future<List<Map<String, dynamic>>> queryAll(String uid) async {
    return queryResults;
  }

  @override
  Future<Map<String, dynamic>?> getByActivityAndDate(
    String uid, {
    required String activityId,
    required String dateKey,
  }) async {
    for (final Map<String, dynamic> d in docs.values) {
      if (d['activityId'] == activityId && d['dateKey'] == dateKey) {
        return d;
      }
    }
    return null;
  }
}

class _FakeMirrorRepo implements ProgressRepository {
  final Map<String, ProgressEntryModel> store = <String, ProgressEntryModel>{};
  bool failWrites = false;
  int upsertCalls = 0;
  int deleteByActivityCalls = 0;
  int readCalls = 0;

  @override
  Stream<List<ProgressEntryModel>> watchAll() {
    readCalls++;
    return Stream<List<ProgressEntryModel>>.value(store.values.toList());
  }

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) {
    readCalls++;
    return Stream<List<ProgressEntryModel>>.value(
      store.values
          .where((ProgressEntryModel e) => e.activityId == activityId)
          .toList(),
    );
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) {
    readCalls++;
    return Stream<List<ProgressEntryModel>>.value(
      store.values
          .where((ProgressEntryModel e) => e.dateKey == dateKey)
          .toList(),
    );
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) {
    readCalls++;
    return Stream<List<ProgressEntryModel>>.value(const <ProgressEntryModel>[]);
  }

  @override
  Future<List<ProgressEntryModel>> getAll() async {
    readCalls++;
    return store.values.toList();
  }

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async {
    readCalls++;
    for (final ProgressEntryModel e in store.values) {
      if (e.activityId == activityId && e.dateKey == dateKey) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    upsertCalls++;
    if (failWrites) throw StateError('isar down');
    store[entry.id] = entry;
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    deleteByActivityCalls++;
    if (failWrites) throw StateError('isar down');
    store.removeWhere(
      (_, ProgressEntryModel e) => e.activityId == activityId,
    );
  }
}

ProgressEntryModel _entry({
  String id = 'p1',
  String activityId = 'a1',
  String dateKey = '2026-10-18',
  ActivityDayStatus status = ActivityDayStatus.notDone,
  List<String> completedSub = const <String>[],
}) {
  final DateTime now = DateTime(2026, 10, 18, 10);
  return ProgressEntryModel(
    id: id,
    activityId: activityId,
    dateKey: dateKey,
    status: status,
    subCompleted: completedSub.length,
    subTotal: 2,
    completedSubActivities: completedSub,
    photoPaths: const <String>[],
    photoPath: null,
    photoNote: null,
    notes: null,
    completionTime: null,
    createdAt: now,
    updatedAt: now,
  );
}

CloudProgressDoc _cloudDoc(ProgressEntryModel entry, {bool pending = false}) {
  return CloudProgressDoc(
    id: entry.id,
    data: FirestoreProgressRepository.toMap(entry),
    hasPendingWrites: pending,
  );
}

void main() {
  late _FakeAuthState auth;
  late _FakeBackend backend;
  late _FakeMirrorRepo mirror;
  late CloudFirstProgressRepository repo;

  setUp(() {
    auth = _FakeAuthState()..uid = 'u1';
    addTearDown(auth.close);
    backend = _FakeBackend();
    mirror = _FakeMirrorRepo();
    repo = CloudFirstProgressRepository(
      backend: backend,
      authState: auth,
      mirror: mirror,
    );
  });

  group('CloudFirstProgressRepository (S2 — offline UX: tidak menunggu '
      'ack, mirror segera, status pending/failed per-entry)', () {
    test('upsert: cloud diinisiasi (merge set skema v1) + mirror Isar', () async {
      final ProgressEntryModel entry = _entry(status: ActivityDayStatus.done);
      await repo.upsert(entry);

      expect(backend.setCalls, hasLength(1));
      final _SetCall call = backend.setCalls.single;
      expect(call.uid, 'u1');
      expect(call.docId, 'p1');
      expect(call.data['id'], 'p1');
      expect(call.data['activityId'], 'a1');
      expect(call.data['dateKey'], '2026-10-18');
      expect(call.data['status'], 'done');
      expect(call.data['subTotal'], 2);

      expect(mirror.upsertCalls, 1);
      expect(mirror.store['p1']?.status, ActivityDayStatus.done);
      // Mirror tidak pernah dipakai untuk baca.
      expect(mirror.readCalls, 0);
    });

    test('upsert kedua (edit): cloud dan mirror ikut ter-update', () async {
      await repo.upsert(_entry());
      await repo.upsert(
        _entry(status: ActivityDayStatus.done, completedSub: <String>['x']),
      );

      expect(backend.setCalls, hasLength(2));
      expect(backend.setCalls.last.data['status'], 'done');
      expect(mirror.upsertCalls, 2);
      expect(mirror.store['p1']?.status, ActivityDayStatus.done);
    });

    test('upsert offline (ack server menggantung): selesai cepat + mirror '
        'sudah ditulis + belum ada status failed', () async {
      backend.setGate = Completer<void>();

      await repo.upsert(_entry()).timeout(const Duration(seconds: 2));

      expect(backend.setCalls, hasLength(1));
      expect(mirror.upsertCalls, 1);
      expect(mirror.store.containsKey('p1'), isTrue);
      expect(repo.failures.byEntry.value, isEmpty);
    });

    test('reject server (rules/auth) → failure tercatat per-entry + event '
        'broadcast (non-silent) + mirror tetap ditulis', () async {
      final List<ProgressSyncFailure> events = <ProgressSyncFailure>[];
      final StreamSubscription<ProgressSyncFailure> sub = repo.failures.events
          .listen(events.add);
      addTearDown(sub.cancel);

      backend.setGate = Completer<void>();
      await repo.upsert(_entry());
      backend.setGate!.completeError(StateError('rules tolak'));
      await _flush();

      expect(events, hasLength(1));
      expect(events.single.id, 'p1');
      expect(events.single.operation, ProgressSyncOperation.save);
      expect(events.single.message, contains('rules tolak'));

      final ProgressSyncFailure? failure = repo.failures.byEntry.value['p1'];
      expect(failure, isNotNull);
      expect(failure!.operation, ProgressSyncOperation.save);
      // Mirror tetap ditulis (local-first) walau cloud menolak.
      expect(mirror.store.containsKey('p1'), isTrue);
    });

    test('ack sukses berikutnya membersihkan status failed (sembuh)', () async {
      backend.setGate = Completer<void>();
      await repo.upsert(_entry());
      backend.setGate!.completeError(StateError('rules tolak'));
      await _flush();
      expect(repo.failures.byEntry.value.containsKey('p1'), isTrue);

      backend.setGate = null;
      await repo.upsert(_entry(status: ActivityDayStatus.done));
      await _flush();

      expect(repo.failures.byEntry.value, isEmpty);
    });

    test('ack out-of-order (save/save): reject lama tidak menimpa ack sukses '
        'operasi terbaru', () async {
      backend.gateEachSet = true;
      await repo.upsert(_entry());
      await repo.upsert(_entry(status: ActivityDayStatus.done));
      expect(backend.setGates, hasLength(2));

      backend.setGates[1].complete(); // terbaru ack sukses dulu
      await _flush();
      expect(repo.failures.byEntry.value, isEmpty);

      backend.setGates[0].completeError(StateError('rules tolak lama'));
      await _flush();

      expect(
        repo.failures.byEntry.value,
        isEmpty,
        reason: 'reject dari operasi yang sudah digantikan harus diabaikan',
      );
    });

    test('ack out-of-order (save/save): ack sukses lama tidak membersihkan '
        'reject operasi terbaru', () async {
      backend.gateEachSet = true;
      await repo.upsert(_entry());
      await repo.upsert(_entry(status: ActivityDayStatus.done));

      backend.setGates[1].completeError(StateError('rules tolak terbaru'));
      await _flush();
      expect(repo.failures.byEntry.value.containsKey('p1'), isTrue);

      backend.setGates[0].complete(); // ack lama telat sukses
      await _flush();

      expect(
        repo.failures.byEntry.value.containsKey('p1'),
        isTrue,
        reason: 'ack sukses lama tidak boleh membersihkan reject terbaru',
      );
    });

    test('deleteByActivity: cloud diinisiasi + mirror LANGSUNG terhapus walau '
        'ack menggantung (rollback flag OFF tidak resurrect)', () async {
      await repo.upsert(_entry(id: 'p1', activityId: 'a1'));
      await repo.upsert(_entry(id: 'p2', activityId: 'a1'));
      await repo.upsert(_entry(id: 'p3', activityId: 'a2'));
      backend.deleteGate = Completer<void>();

      await repo
          .deleteByActivity('a1')
          .timeout(const Duration(seconds: 2));

      expect(backend.deleteCalls, <String>['a1']);
      expect(mirror.deleteByActivityCalls, 1);
      // Sumber rollback (Isar) sudah bersih untuk a1; a2 tidak tersentuh.
      expect(mirror.store.containsKey('p1'), isFalse);
      expect(mirror.store.containsKey('p2'), isFalse);
      expect(mirror.store.containsKey('p3'), isTrue);
      expect(repo.failures.byEntry.value, isEmpty);
      expect(repo.failures.byActivity.value, isEmpty);
    });

    test('deleteByActivity reject → failure activity-scoped yang TETAP '
        'terlihat setelah baris lokal terhapus + event (non-silent)', () async {
      final List<ProgressSyncFailure> events = <ProgressSyncFailure>[];
      final StreamSubscription<ProgressSyncFailure> sub = repo.failures.events
          .listen(events.add);
      addTearDown(sub.cancel);

      await repo.upsert(_entry());
      backend.deleteGate = Completer<void>();
      await repo.deleteByActivity('a1');
      backend.deleteGate!.completeError(StateError('permission-denied'));
      await _flush();

      // Baris (cloud-driven & mirror) sudah terhapus — kegagalan tetap
      // tercatat supaya badge activity-scoped bisa menampilkannya.
      expect(mirror.store, isEmpty);
      final ProgressSyncFailure? failure = repo.failures.byActivity.value['a1'];
      expect(failure, isNotNull);
      expect(failure!.id, 'a1');
      expect(failure.operation, ProgressSyncOperation.delete);
      expect(failure.message, contains('permission-denied'));

      expect(events, hasLength(1));
      expect(events.single.id, 'a1');
      expect(events.single.operation, ProgressSyncOperation.delete);

      // Namespace terpisah: tidak mencemari status per-entry.
      expect(repo.failures.byEntry.value, isEmpty);
    });

    test('deleteByActivity retry sukses → status gagal activity-scoped '
        'dibersihkan (sembuh)', () async {
      backend.deleteGate = Completer<void>();
      await repo.deleteByActivity('a1');
      backend.deleteGate!.completeError(StateError('permission-denied'));
      await _flush();
      expect(repo.failures.byActivity.value.containsKey('a1'), isTrue);

      backend.deleteGate = null;
      await repo.deleteByActivity('a1'); // retry user → ack sukses
      await _flush();

      expect(repo.failures.byActivity.value, isEmpty);
    });

    test('deleteByActivity out-of-order: reject lama diabaikan setelah delete '
        'terbaru ack sukses', () async {
      backend.gateEachDelete = true;
      await repo.deleteByActivity('a1');
      await repo.deleteByActivity('a1');
      expect(backend.deleteGates, hasLength(2));

      backend.deleteGates[1].complete(); // delete terbaru ack sukses dulu
      await _flush();
      expect(repo.failures.byActivity.value, isEmpty);

      backend.deleteGates[0].completeError(StateError('rules tolak lama'));
      await _flush();

      expect(
        repo.failures.byActivity.value,
        isEmpty,
        reason: 'reject delete yang sudah digantikan harus diabaikan',
      );
    });

    test('deleteByActivity out-of-order: ack sukses lama tidak membersihkan '
        'reject delete terbaru', () async {
      backend.gateEachDelete = true;
      await repo.deleteByActivity('a1');
      await repo.deleteByActivity('a1');
      expect(backend.deleteGates, hasLength(2));

      backend.deleteGates[1].completeError(StateError('rules tolak terbaru'));
      await _flush();
      expect(repo.failures.byActivity.value.containsKey('a1'), isTrue);

      backend.deleteGates[0].complete(); // ack lama telat sukses
      await _flush();

      expect(
        repo.failures.byActivity.value.containsKey('a1'),
        isTrue,
        reason: 'ack sukses lama tidak boleh membersihkan reject terbaru',
      );
    });

    test('watchPendingIds: hanya hasPendingWrites', () async {
      backend.watchDocs = <CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p1'), pending: true),
        _cloudDoc(_entry(id: 'p2'), pending: false),
        _cloudDoc(_entry(id: 'p3', dateKey: '2026-10-17'), pending: true),
      ];

      final Set<String> pending = await repo.watchPendingIds().first;

      expect(pending, <String>{'p1', 'p3'});
    });

    test('watchAll/watchByActivity/watchByDate/watchByDateRange: dari cloud, '
        'terfilter dan terurut, mirror tidak disentuh', () async {
      backend.watchDocs = <CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p1', activityId: 'a1', dateKey: '2026-10-18')),
        _cloudDoc(_entry(id: 'p2', activityId: 'a1', dateKey: '2026-10-17')),
        _cloudDoc(_entry(id: 'p3', activityId: 'a2', dateKey: '2026-10-18')),
        _cloudDoc(_entry(id: 'p4', activityId: 'a2', dateKey: '2026-10-01')),
      ];

      final List<ProgressEntryModel> all = await repo.watchAll().first;
      expect(
        all.map((ProgressEntryModel e) => e.id),
        <String>['p1', 'p3', 'p2', 'p4'],
        reason: 'urut dateKey desc',
      );

      final List<ProgressEntryModel> byActivity =
          await repo.watchByActivity('a1').first;
      expect(byActivity.map((ProgressEntryModel e) => e.id), <String>['p1', 'p2']);

      final List<ProgressEntryModel> byDate =
          await repo.watchByDate('2026-10-18').first;
      expect(byDate.map((ProgressEntryModel e) => e.id), <String>['p1', 'p3']);

      final List<ProgressEntryModel> byRange = await repo
          .watchByDateRange(
            fromDateKey: '2026-10-17',
            toDateKey: '2026-10-18',
          )
          .first;
      expect(byRange.map((ProgressEntryModel e) => e.id), <String>['p2', 'p1', 'p3']);

      expect(mirror.readCalls, 0);
    });

    test('ganti sesi (logout→login): watchAll re-subscribe ke uid baru — '
        'listen lama dibatalkan, stream baru hidup meski listen lama tidak '
        'pernah selesai (bug uji device S2)', () async {
      backend.keepWatchOpen = true; // pola snapshots(): tidak pernah selesai
      backend.watchDocsByUid['u1'] = <CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p1')),
      ];
      backend.watchDocsByUid['u2'] = <CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p2')),
      ];

      final List<List<ProgressEntryModel>> received =
          <List<ProgressEntryModel>>[];
      final StreamSubscription<List<ProgressEntryModel>> sub =
          repo.watchAll().listen(received.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(received.last.map((ProgressEntryModel e) => e.id), <String>['p1']);

      auth.emitUidChange(null); // logout: sesi berakhir
      await pumpEventQueue();
      expect(
        received.last,
        isEmpty,
        reason: 'tanpa sesi → kosong (bukan data lama / error)',
      );
      expect(
        backend.watchControllers.first.hasListener,
        isFalse,
        reason: 'listen lama dibatalkan saat logout (tanpa listen zombie)',
      );

      auth.emitUidChange('u2'); // login lagi (uid sama maupun akun lain)
      await pumpEventQueue();
      expect(received.last.map((ProgressEntryModel e) => e.id), <String>['p2']);
      expect(
        backend.watchUids,
        <String>['u1', 'u2'],
        reason: 'listen Firestore dibuat ulang untuk uid sesi baru',
      );

      // Listen sesi baru tetap hidup: snapshot berikutnya ikut mengalir.
      backend.watchControllers.last.add(<CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p9')),
      ]);
      await pumpEventQueue();
      expect(received.last.map((ProgressEntryModel e) => e.id), <String>['p9']);
    });

    test('ganti sesi: watchPendingIds re-subscribe — badge pending hidup '
        'lagi setelah login ulang', () async {
      backend.keepWatchOpen = true; // pola snapshots(): tidak pernah selesai
      backend.watchDocsByUid['u1'] = <CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p1'), pending: true),
      ];
      backend.watchDocsByUid['u2'] = <CloudProgressDoc>[
        _cloudDoc(_entry(id: 'p2'), pending: true),
      ];

      final List<Set<String>> received = <Set<String>>[];
      final StreamSubscription<Set<String>> sub =
          repo.watchPendingIds().listen(received.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(received.last, <String>{'p1'});

      auth.emitUidChange(null);
      await pumpEventQueue();
      expect(received.last, isEmpty);
      expect(
        backend.watchControllers.first.hasListener,
        isFalse,
        reason: 'listen lama dibatalkan saat logout (tanpa listen zombie)',
      );

      auth.emitUidChange('u2');
      await pumpEventQueue();
      expect(received.last, <String>{'p2'});
      expect(backend.watchUids, <String>['u1', 'u2']);
    });

    test('getAll: baca dari cloud (queryAll), urut dateKey desc, mirror tidak '
        'disentuh', () async {
      backend.queryResults = <Map<String, dynamic>>[
        FirestoreProgressRepository.toMap(
          _entry(id: 'p2', dateKey: '2026-10-17'),
        ),
        FirestoreProgressRepository.toMap(
          _entry(id: 'p1', dateKey: '2026-10-18'),
        ),
      ];

      final List<ProgressEntryModel> all = await repo.getAll();

      expect(all.map((ProgressEntryModel e) => e.id), <String>['p1', 'p2']);
      expect(mirror.readCalls, 0);
      expect(mirror.upsertCalls, 0);
      expect(mirror.deleteByActivityCalls, 0);
    });

    test('getByActivityAndDate: dari cloud; null bila tidak ada', () async {
      backend.docs['p1'] = FirestoreProgressRepository.toMap(_entry());

      final ProgressEntryModel? found = await repo.getByActivityAndDate(
        activityId: 'a1',
        dateKey: '2026-10-18',
      );
      expect(found?.id, 'p1');

      final ProgressEntryModel? missing = await repo.getByActivityAndDate(
        activityId: 'a1',
        dateKey: '2026-09-01',
      );
      expect(missing, isNull);
      expect(mirror.readCalls, 0);
    });

    test('tanpa login → StateError sebelum efek apa pun (upsert & '
        'deleteByActivity)', () async {
      auth.uid = null;

      await expectLater(repo.upsert(_entry()), throwsStateError);
      await expectLater(repo.deleteByActivity('a1'), throwsStateError);
      expect(() => repo.watchAll(), throwsStateError);

      expect(backend.setCalls, isEmpty);
      expect(backend.deleteCalls, isEmpty);
      expect(mirror.upsertCalls, 0);
      expect(mirror.deleteByActivityCalls, 0);
    });

    test('mirror Isar gagal → operasi tetap selesai; cloud tetap diinisiasi '
        '(local-first tidak menggagalkan antrean cloud)', () async {
      mirror.failWrites = true;

      await repo.upsert(_entry()).timeout(const Duration(seconds: 2));

      expect(backend.setCalls, hasLength(1));
      expect(mirror.upsertCalls, 1);
      expect(repo.failures.byEntry.value, isEmpty);
    });
  });
}
