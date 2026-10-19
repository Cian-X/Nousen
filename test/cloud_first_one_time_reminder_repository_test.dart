import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_agenda_notes_backend.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_first_one_time_reminder_repository.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_reminders_backend.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_sync_failures.dart';
import 'package:nousen/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Biarkan microtask/timer nol terproses (ack tracker async).
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
  const _SetCall(this.docId, this.data);

  final String docId;
  final Map<String, dynamic> data;
}

class _FakeRemindersBackend implements CloudRemindersBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  final List<String> watchUids = <String>[];
  final Map<String, StreamController<List<CloudReminderDoc>>>
  _watchControllers = <String, StreamController<List<CloudReminderDoc>>>{};

  Completer<void>? gate;
  Object? failWith;

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(docId, data));
    final Completer<void>? pending = gate;
    if (pending != null) {
      await pending.future;
    }
    final Object? error = failWith;
    if (error != null) {
      failWith = null;
      throw error;
    }
  }

  @override
  Stream<List<CloudReminderDoc>> watchVisible(String uid) {
    watchUids.add(uid);
    return _watchControllers
        .putIfAbsent(
          uid,
          () => StreamController<List<CloudReminderDoc>>.broadcast(),
        )
        .stream;
  }

  void push(String uid, List<CloudReminderDoc> docs) {
    _watchControllers[uid]?.add(docs);
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    return setCalls.map((_SetCall call) => call.data).toList();
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async {
    for (final _SetCall call in setCalls.reversed) {
      if (call.docId == docId) {
        return call.data;
      }
    }
    return null;
  }

  Future<void> dispose() async {
    for (final StreamController<List<CloudReminderDoc>> controller
        in _watchControllers.values) {
      await controller.close();
    }
  }
}

class _FakeNotesBackend implements CloudAgendaNotesBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  final List<String> watchUids = <String>[];
  final Map<String, StreamController<List<CloudAgendaNoteDoc>>>
  _watchControllers = <String, StreamController<List<CloudAgendaNoteDoc>>>{};

  Completer<void>? gate;
  Object? failWith;

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(docId, data));
    final Completer<void>? pending = gate;
    if (pending != null) {
      await pending.future;
    }
    final Object? error = failWith;
    if (error != null) {
      failWith = null;
      throw error;
    }
  }

  @override
  Stream<List<CloudAgendaNoteDoc>> watchVisible(String uid) {
    watchUids.add(uid);
    return _watchControllers
        .putIfAbsent(
          uid,
          () => StreamController<List<CloudAgendaNoteDoc>>.broadcast(),
        )
        .stream;
  }

  void push(String uid, List<CloudAgendaNoteDoc> docs) {
    _watchControllers[uid]?.add(docs);
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    return setCalls.map((_SetCall call) => call.data).toList();
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async {
    for (final _SetCall call in setCalls.reversed) {
      if (call.docId == docId) {
        return call.data;
      }
    }
    return null;
  }

  Future<void> dispose() async {
    for (final StreamController<List<CloudAgendaNoteDoc>> controller
        in _watchControllers.values) {
      await controller.close();
    }
  }
}

class _FakeMirror implements OneTimeReminderRepository {
  final List<OneTimeReminderModel> reminders = <OneTimeReminderModel>[];
  final List<AgendaNoteModel> notes = <AgendaNoteModel>[];
  final List<String> calls = <String>[];

  @override
  Stream<List<OneTimeReminderModel>> watchAll() {
    calls.add('watchAll');
    return Stream<List<OneTimeReminderModel>>.value(
      List<OneTimeReminderModel>.of(reminders),
    );
  }

  @override
  Future<List<OneTimeReminderModel>> getAll() async {
    calls.add('getAll');
    return List<OneTimeReminderModel>.of(reminders);
  }

  @override
  Future<OneTimeReminderModel?> getById(String id) async {
    calls.add('getById:$id');
    for (final OneTimeReminderModel item in reminders) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(OneTimeReminderModel reminder) async {
    calls.add('upsert:${reminder.id}');
    reminders.removeWhere(
      (OneTimeReminderModel item) => item.id == reminder.id,
    );
    reminders.add(reminder);
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    reminders.removeWhere((OneTimeReminderModel item) => item.id == id);
  }

  @override
  Stream<List<AgendaNoteModel>> watchNotes(String reminderId) {
    calls.add('watchNotes:$reminderId');
    return Stream<List<AgendaNoteModel>>.value(
      notes
          .where((AgendaNoteModel note) => note.reminderId == reminderId)
          .toList(),
    );
  }

  @override
  Future<void> upsertNote(AgendaNoteModel note) async {
    calls.add('upsertNote:${note.id}');
    notes.removeWhere((AgendaNoteModel item) => item.id == note.id);
    notes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    calls.add('deleteNote:$id');
    notes.removeWhere((AgendaNoteModel item) => item.id == id);
  }
}

OneTimeReminderModel _reminder(
  String id, {
  DateTime? scheduledAt,
  String title = 'Agenda',
}) {
  final DateTime base = DateTime(2026, 10, 19, 9);
  return OneTimeReminderModel(
    id: id,
    title: title,
    iconKey: 'book',
    scheduledAt: scheduledAt ?? base,
    categoryId: 'study',
    description: '  deskripsi  ',
    subActivities: const <String>['  baca  ', ''],
    completedSubActivities: const <String>[],
    preReminderMinutes: 10,
    isNotificationEnabled: true,
    isCompleted: false,
    createdAt: base.subtract(const Duration(days: 1)),
    updatedAt: base,
  );
}

AgendaNoteModel _note(
  String id,
  String reminderId, {
  List<String> photoPaths = const <String>[],
  DateTime? createdAt,
}) {
  final DateTime base = DateTime(2026, 10, 19, 10);
  return AgendaNoteModel(
    id: id,
    reminderId: reminderId,
    text: 'catatan $id',
    photoPaths: photoPaths,
    createdAt: createdAt ?? base,
    updatedAt: createdAt ?? base,
  );
}

CloudReminderDoc _cloudReminderDoc(
  OneTimeReminderModel reminder, {
  bool pending = false,
  bool deleted = false,
}) {
  return CloudReminderDoc(
    id: reminder.id,
    data: <String, dynamic>{
      ...CloudFirstOneTimeReminderRepository.reminderToMap(reminder),
      'deleted': deleted,
    },
    hasPendingWrites: pending,
  );
}

CloudAgendaNoteDoc _cloudNoteDoc(
  AgendaNoteModel note, {
  bool pending = false,
  bool deleted = false,
}) {
  return CloudAgendaNoteDoc(
    id: note.id,
    data: <String, dynamic>{
      ...CloudFirstOneTimeReminderRepository.noteToMap(note),
      'deleted': deleted,
    },
    hasPendingWrites: pending,
  );
}

void main() {
  group('S3 cloud-first reminder', () {
    late _FakeAuthState auth;
    late _FakeRemindersBackend backend;
    late _FakeMirror mirror;
    late OneTimeReminderSyncFailures failures;
    late CloudFirstOneTimeReminderRepository repo;

    setUp(() {
      auth = _FakeAuthState()..uid = 'u1';
      backend = _FakeRemindersBackend();
      mirror = _FakeMirror();
      failures = OneTimeReminderSyncFailures();
      repo = CloudFirstOneTimeReminderRepository(
        authState: auth,
        mirror: mirror,
        remindersBackend: backend,
        failures: failures,
      );
    });

    tearDown(() async {
      failures.dispose();
      await auth.dispose();
      await backend.dispose();
    });

    test('upsert: cloud map skema v2 + mirror Isar segera', () async {
      final OneTimeReminderModel reminder = _reminder('r1');

      await repo.upsert(reminder);
      await _flush();

      expect(backend.setCalls, hasLength(1));
      final _SetCall call = backend.setCalls.single;
      expect(call.docId, 'r1');
      expect(call.data['id'], 'r1');
      expect(call.data['title'], 'Agenda');
      expect(call.data['description'], 'deskripsi');
      expect(call.data['subActivities'], <String>['baca']);
      expect(call.data['deleted'], isFalse);
      expect(call.data['deletedAt'], isNull);
      expect(call.data['schemaVersion'], 2);
      expect(call.data['updatedAt'], isA<FieldValue>());
      expect(call.data['clientUpdatedAt'], isA<String>());
      expect(mirror.reminders.single.id, 'r1');
      expect(failures.byReminder.value, isEmpty);
    });

    test('getById: dokumen hidup → model; tombstone → null', () async {
      await repo.upsert(_reminder('r1'));
      final OneTimeReminderModel? live = await repo.getById('r1');
      expect(live?.id, 'r1');
      expect(live?.description, 'deskripsi');

      await repo.delete('r1');
      expect(await repo.getById('r1'), isNull);
    });

    test('delete: tombstone (bukan hard delete) + mirror hapus', () async {
      mirror.reminders.add(_reminder('r1'));

      await repo.delete('r1');
      await _flush();

      final _SetCall call = backend.setCalls.single;
      expect(call.docId, 'r1');
      expect(call.data['id'], 'r1');
      expect(call.data['deleted'], isTrue);
      expect(call.data['deletedAt'], isA<FieldValue>());
      expect(call.data['updatedAt'], isA<FieldValue>());
      expect(call.data['schemaVersion'], 2);
      expect(mirror.reminders, isEmpty);
    });

    test(
      'tulis non-blocking: mirror selesai walau ack server ditahan',
      () async {
        final Completer<void> gate = Completer<void>();
        backend.gate = gate;

        final Stopwatch watch = Stopwatch()..start();
        await repo.upsert(_reminder('r1'));
        watch.stop();

        expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
        expect(mirror.reminders.single.id, 'r1');

        gate.complete();
        await _flush();
      },
    );

    test('reject server: failure per-reminder + event, mirror tetap; retry '
        'sukses membersihkan', () async {
      final List<OneTimeReminderSyncFailure> events =
          <OneTimeReminderSyncFailure>[];
      final StreamSubscription<OneTimeReminderSyncFailure> sub = failures.events
          .listen(events.add);
      addTearDown(sub.cancel);

      backend.failWith = Exception('permission-denied');
      await repo.upsert(_reminder('r1'));
      await _flush();

      expect(events, hasLength(1));
      expect(events.single.target, OneTimeReminderSyncTarget.reminder);
      expect(events.single.operation, OneTimeReminderSyncOperation.save);
      expect(
        failures.byReminder.value['r1']?.message,
        contains('permission-denied'),
      );
      expect(mirror.reminders.single.id, 'r1');

      await repo.upsert(_reminder('r1', title: 'Retry'));
      await _flush();

      expect(failures.byReminder.value, isEmpty);
    });

    test('watchAll: baca cloud, filter tombstone, urut scheduledAt', () async {
      final List<List<OneTimeReminderModel>> emissions =
          <List<OneTimeReminderModel>>[];
      final StreamSubscription<List<OneTimeReminderModel>> sub = repo
          .watchAll()
          .listen(emissions.add);
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();

      backend.push('u1', <CloudReminderDoc>[
        _cloudReminderDoc(
          _reminder('r2', scheduledAt: DateTime(2026, 10, 19, 11)),
        ),
        _cloudReminderDoc(_reminder('r1')),
        _cloudReminderDoc(_reminder('r3'), deleted: true),
      ]);
      await _flush();

      expect(emissions.last.map((OneTimeReminderModel r) => r.id), <String>[
        'r1',
        'r2',
      ]);
      // Baca TIDAK memakai mirror (cloud-first).
      expect(
        mirror.calls.where((String call) => call.startsWith('get')).toList(),
        isEmpty,
      );
    });

    test('watchPendingIds: hanya hasPendingWrites', () async {
      final List<Set<String>> emissions = <Set<String>>[];
      final StreamSubscription<Set<String>> sub = repo
          .watchReminderPendingIds()
          .listen(emissions.add);
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();

      backend.push('u1', <CloudReminderDoc>[
        _cloudReminderDoc(_reminder('r1'), pending: true),
        _cloudReminderDoc(_reminder('r2')),
      ]);
      await _flush();

      expect(emissions.last, <String>{'r1'});
    });

    test('sesi: logout→login re-subscribe listen Firestore', () async {
      final List<List<OneTimeReminderModel>> emissions =
          <List<OneTimeReminderModel>>[];
      final StreamSubscription<List<OneTimeReminderModel>> sub = repo
          .watchAll()
          .listen(emissions.add);
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();
      auth.emit(null);
      await _flush();
      expect(emissions.last, isEmpty);

      auth.emit('u1');
      await _flush();
      expect(backend.watchUids, <String>['u1', 'u1']);

      backend.push('u1', <CloudReminderDoc>[
        _cloudReminderDoc(_reminder('r2')),
      ]);
      await _flush();
      expect(emissions.last.single.id, 'r2');
    });

    test(
      'tanpa login: baca/tulis cloud melempar StateError, tanpa efek',
      () async {
        auth.uid = null;

        await expectLater(repo.getAll(), throwsStateError);
        await expectLater(repo.upsert(_reminder('r1')), throwsStateError);
        await expectLater(repo.delete('r1'), throwsStateError);
        expect(backend.setCalls, isEmpty);
        expect(mirror.calls, isEmpty);
      },
    );

    test('flag reminder OFF: delegasi penuh ke mirror Isar', () async {
      final CloudFirstOneTimeReminderRepository localOnly =
          CloudFirstOneTimeReminderRepository(
            authState: auth,
            mirror: mirror,
            notesBackend: null,
          );
      mirror.reminders.add(_reminder('r1'));

      expect(await localOnly.getAll(), hasLength(1));
      expect(localOnly.remindersCloudEnabled, isFalse);

      await localOnly.upsert(_reminder('r2'));
      await localOnly.delete('r1');

      expect(mirror.calls, contains('upsert:r2'));
      expect(mirror.calls, contains('delete:r1'));
      expect(await localOnly.watchReminderPendingIds().first, isEmpty);
    });
  });

  group('S3 cloud-first agenda notes', () {
    late _FakeAuthState auth;
    late _FakeNotesBackend backend;
    late _FakeMirror mirror;
    late OneTimeReminderSyncFailures failures;
    late CloudFirstOneTimeReminderRepository repo;

    setUp(() {
      auth = _FakeAuthState()..uid = 'u1';
      backend = _FakeNotesBackend();
      mirror = _FakeMirror();
      failures = OneTimeReminderSyncFailures();
      repo = CloudFirstOneTimeReminderRepository(
        authState: auth,
        mirror: mirror,
        notesBackend: backend,
        failures: failures,
      );
    });

    tearDown(() async {
      failures.dispose();
      await auth.dispose();
      await backend.dispose();
    });

    test(
      'upsertNote: photoPaths TIDAK ke cloud, mirror menyimpan lokal',
      () async {
        final AgendaNoteModel note = _note(
          'n1',
          'r1',
          photoPaths: <String>['/lokal/a.jpg'],
        );

        await repo.upsertNote(note);
        await _flush();

        final _SetCall call = backend.setCalls.single;
        expect(call.docId, 'n1');
        expect(call.data['reminderId'], 'r1');
        expect(call.data.containsKey('photoPaths'), isFalse);
        expect(call.data['deleted'], isFalse);
        expect(call.data['schemaVersion'], 2);
        expect(call.data['updatedAt'], isA<FieldValue>());
        expect(mirror.notes.single.photoPaths, <String>['/lokal/a.jpg']);
      },
    );

    test('watchNotes: filter reminder/deleted, urut createdAt, overlay '
        'photoPaths lokal', () async {
      mirror.notes.add(_note('n1', 'r1', photoPaths: <String>['/lokal/a.jpg']));
      final List<List<AgendaNoteModel>> emissions = <List<AgendaNoteModel>>[];
      final StreamSubscription<List<AgendaNoteModel>> sub = repo
          .watchNotes('r1')
          .listen(emissions.add);
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();

      backend.push('u1', <CloudAgendaNoteDoc>[
        _cloudNoteDoc(_note('n2', 'r1', createdAt: DateTime(2026, 10, 19, 11))),
        _cloudNoteDoc(_note('n1', 'r1')),
        _cloudNoteDoc(_note('n3', 'r2')),
        _cloudNoteDoc(_note('n4', 'r1'), deleted: true),
      ]);
      await _flush();
      await _flush();

      final List<AgendaNoteModel> notes = emissions.last;
      expect(notes.map((AgendaNoteModel n) => n.id), <String>['n1', 'n2']);
      expect(notes.first.photoPaths, <String>['/lokal/a.jpg']);
      expect(notes.last.photoPaths, isEmpty);
    });

    test('deleteNote: tombstone + mirror hapus', () async {
      mirror.notes.add(_note('n1', 'r1'));

      await repo.deleteNote('n1');
      await _flush();

      final _SetCall call = backend.setCalls.single;
      expect(call.docId, 'n1');
      expect(call.data['deleted'], isTrue);
      expect(call.data['schemaVersion'], 2);
      expect(mirror.notes, isEmpty);
    });

    test('reject note: failure byNote/target note + event', () async {
      final List<OneTimeReminderSyncFailure> events =
          <OneTimeReminderSyncFailure>[];
      final StreamSubscription<OneTimeReminderSyncFailure> sub = failures.events
          .listen(events.add);
      addTearDown(sub.cancel);

      backend.failWith = Exception('rules-denied');
      await repo.upsertNote(_note('n1', 'r1'));
      await _flush();

      expect(events.single.target, OneTimeReminderSyncTarget.note);
      expect(failures.byNote.value['n1']?.message, contains('rules-denied'));
      expect(failures.byReminder.value, isEmpty);
    });

    test('watchNotePendingIds: hanya hasPendingWrites', () async {
      final List<Set<String>> emissions = <Set<String>>[];
      final StreamSubscription<Set<String>> sub = repo
          .watchNotePendingIds()
          .listen(emissions.add);
      addTearDown(sub.cancel);

      auth.emit('u1');
      await _flush();

      backend.push('u1', <CloudAgendaNoteDoc>[
        _cloudNoteDoc(_note('n1', 'r1'), pending: true),
        _cloudNoteDoc(_note('n2', 'r1')),
      ]);
      await _flush();

      expect(emissions.last, <String>{'n1'});
    });

    test('flag notes OFF: delegasi penuh ke mirror Isar', () async {
      final CloudFirstOneTimeReminderRepository localOnly =
          CloudFirstOneTimeReminderRepository(authState: auth, mirror: mirror);
      mirror.notes.add(_note('n1', 'r1'));

      final List<AgendaNoteModel> notes = await localOnly
          .watchNotes('r1')
          .first;
      expect(notes.single.id, 'n1');

      await localOnly.upsertNote(_note('n2', 'r1'));
      expect(mirror.calls, contains('upsertNote:n2'));
      expect(await localOnly.watchNotePendingIds().first, isEmpty);
    });
  });
}
