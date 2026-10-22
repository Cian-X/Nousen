import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/migration/application/login_backfill_coordinator.dart';
import 'package:nousen/features/migration/data/backfill_completion_store.dart';
import 'package:nousen/features/migration/data/backfill_models.dart';
import 'package:nousen/features/migration/domain/backfill_completion.dart';
import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';

class _MemoryCompletionStore implements BackfillCompletionStore {
  final Map<String, BackfillCompletion> saved = <String, BackfillCompletion>{};
  int loadCalls = 0;
  int markCalls = 0;
  bool throwOnLoad = false;

  @override
  Future<BackfillCompletion?> load(String uid) async {
    loadCalls++;
    if (throwOnLoad) {
      throw StateError('store rusak');
    }
    return saved[uid];
  }

  @override
  Future<void> markCompleted(BackfillCompletion completion) async {
    markCalls++;
    saved[completion.uid] = completion;
  }
}

BackfillReport _report(String uid, {bool allDone = true}) {
  return BackfillReport(
    uid: uid,
    entities: <BackfillEntityReport>[
      BackfillEntityReport(kind: BackfillEntityKind.activities)..done = allDone,
    ],
  );
}

void main() {
  group('LoginBackfillCoordinator (S6.0)', () {
    test('login pertama menjalankan backfill dan menyimpan marker', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore();
      final List<String> calls = <String>[];

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async {
          calls.add(uid);
          return _report(uid);
        },
        completions: store,
        now: () => DateTime.utc(2026, 10, 22, 8),
      );

      final LoginBackfillResult result = await coordinator.onLogin('uid-1');

      expect(result.status, LoginBackfillStatus.completed);
      expect(result.isCompleted, isTrue);
      expect(calls, <String>['uid-1']);
      expect(store.markCalls, 1);
      expect(store.saved['uid-1']!.version, loginBackfillVersion);
      expect(
        store.saved['uid-1']!.completedAtUtc,
        DateTime.utc(2026, 10, 22, 8),
      );
    });

    test('login kedua uid sama: marker valid → skip tanpa run', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore()
        ..saved['uid-1'] = BackfillCompletion(
          uid: 'uid-1',
          completedAtUtc: DateTime.utc(2026, 10, 21),
        );
      final List<String> calls = <String>[];

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async {
          calls.add(uid);
          return _report(uid);
        },
        completions: store,
      );

      final LoginBackfillResult result = await coordinator.onLogin('uid-1');

      expect(result.status, LoginBackfillStatus.skippedCompleted);
      expect(calls, isEmpty);
      expect(store.markCalls, 0);
    });

    test('marker versi lama menjalankan ulang backfill', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore()
        ..saved['uid-1'] = BackfillCompletion(
          uid: 'uid-1',
          completedAtUtc: DateTime.utc(2026, 10, 21),
          version: loginBackfillVersion - 1,
        );
      final List<String> calls = <String>[];

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async {
          calls.add(uid);
          return _report(uid);
        },
        completions: store,
      );

      final LoginBackfillResult result = await coordinator.onLogin('uid-1');

      expect(result.status, LoginBackfillStatus.completed);
      expect(calls, <String>['uid-1']);
      expect(store.saved['uid-1']!.version, loginBackfillVersion);
    });

    test('tanpa login: skip dan store tidak disentuh', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore();
      final List<String> calls = <String>[];

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async {
          calls.add(uid);
          return _report(uid);
        },
        completions: store,
      );

      for (final String? uid in <String?>[null, '', '   ']) {
        final LoginBackfillResult result = await coordinator.onLogin(uid);
        expect(result.status, LoginBackfillStatus.skippedNoAuth);
      }
      expect(calls, isEmpty);
      expect(store.loadCalls, 0);
    });

    test(
      'gagal: marker tidak disimpan, retry berikutnya menjalankan ulang',
      () async {
        final _MemoryCompletionStore store = _MemoryCompletionStore();
        int attempts = 0;

        final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
          runBackfill: (String uid) async {
            attempts++;
            if (attempts == 1) {
              throw StateError('jaringan putus');
            }
            return _report(uid);
          },
          completions: store,
        );

        final LoginBackfillResult failed = await coordinator.onLogin('uid-1');
        expect(failed.status, LoginBackfillStatus.failed);
        expect(failed.error, isA<StateError>());
        expect(store.markCalls, 0);
        expect(store.saved, isEmpty);

        final LoginBackfillResult retried = await coordinator.onLogin('uid-1');
        expect(retried.status, LoginBackfillStatus.completed);
        expect(attempts, 2);
        expect(store.markCalls, 1);
      },
    );

    test('report tidak allDone: failed dan marker tidak disimpan', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore();

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async => _report(uid, allDone: false),
        completions: store,
      );

      final LoginBackfillResult result = await coordinator.onLogin('uid-1');

      expect(result.status, LoginBackfillStatus.failed);
      expect(store.markCalls, 0);
    });

    test('report uid berbeda: failed dan marker tidak disimpan', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore();

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async => _report('uid-lain'),
        completions: store,
      );

      final LoginBackfillResult result = await coordinator.onLogin('uid-1');

      expect(result.status, LoginBackfillStatus.failed);
      expect(store.markCalls, 0);
    });

    test(
      'single-flight: panggilan bersamaan uid sama hanya run sekali',
      () async {
        final _MemoryCompletionStore store = _MemoryCompletionStore();
        final Completer<BackfillReport> completer = Completer<BackfillReport>();
        int calls = 0;

        final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
          runBackfill: (String uid) {
            calls++;
            return completer.future;
          },
          completions: store,
        );

        final Future<LoginBackfillResult> first = coordinator.onLogin('uid-1');
        final Future<LoginBackfillResult> second = coordinator.onLogin('uid-1');
        expect(identical(first, second), isTrue);

        completer.complete(_report('uid-1'));
        final List<LoginBackfillResult> results = await Future.wait(
          <Future<LoginBackfillResult>>[first, second],
        );

        expect(calls, 1);
        expect(results[0].status, LoginBackfillStatus.completed);
        expect(results[1].status, LoginBackfillStatus.completed);
        expect(store.markCalls, 1);
      },
    );

    test(
      'uid berbeda dijalankan terpisah dengan marker masing-masing',
      () async {
        final _MemoryCompletionStore store = _MemoryCompletionStore();
        final List<String> calls = <String>[];

        final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
          runBackfill: (String uid) async {
            calls.add(uid);
            return _report(uid);
          },
          completions: store,
        );

        await coordinator.onLogin('uid-a');
        await coordinator.onLogin('uid-b');

        expect(calls, <String>['uid-a', 'uid-b']);
        expect(store.saved.keys.toSet(), <String>{'uid-a', 'uid-b'});
      },
    );

    test('store gagal dibaca: failed tanpa menjalankan backfill', () async {
      final _MemoryCompletionStore store = _MemoryCompletionStore()
        ..throwOnLoad = true;
      final List<String> calls = <String>[];

      final LoginBackfillCoordinator coordinator = LoginBackfillCoordinator(
        runBackfill: (String uid) async {
          calls.add(uid);
          return _report(uid);
        },
        completions: store,
      );

      final LoginBackfillResult result = await coordinator.onLogin('uid-1');

      expect(result.status, LoginBackfillStatus.failed);
      expect(calls, isEmpty);
    });
  });

  group('FileBackfillCompletionStore', () {
    test('markCompleted → load roundtrip, uid lain tetap tersimpan', () async {
      final Directory dir = await Directory.systemTemp.createTemp(
        'nousen_s6_completion',
      );
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final FileBackfillCompletionStore store = FileBackfillCompletionStore(
        baseDirectoryProvider: () async => dir,
      );

      expect(await store.load('uid-1'), isNull);

      await store.markCompleted(
        BackfillCompletion(
          uid: 'uid-1',
          completedAtUtc: DateTime.utc(2026, 10, 22, 9),
        ),
      );
      await store.markCompleted(
        BackfillCompletion(
          uid: 'uid-2',
          completedAtUtc: DateTime.utc(2026, 10, 22, 10),
          version: 2,
        ),
      );

      final BackfillCompletion? first = await store.load('uid-1');
      final BackfillCompletion? second = await store.load('uid-2');
      expect(first, isNotNull);
      expect(first!.uid, 'uid-1');
      expect(first.version, loginBackfillVersion);
      expect(first.completedAtUtc, DateTime.utc(2026, 10, 22, 9));
      expect(second, isNotNull);
      expect(second!.version, 2);
      expect(await store.load('uid-3'), isNull);

      final File file = File(
        '${dir.path}${Platform.pathSeparator}migration'
        '${Platform.pathSeparator}backfill_completion.json',
      );
      expect(await file.exists(), isTrue);
    });

    test(
      'file rusak/versi asing diperlakukan sebagai belum ada marker',
      () async {
        final Directory dir = await Directory.systemTemp.createTemp(
          'nousen_s6_completion_corrupt',
        );
        addTearDown(() async {
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        });

        final Directory migrationDir = Directory(
          '${dir.path}${Platform.pathSeparator}migration',
        );
        await migrationDir.create(recursive: true);
        final File file = File(
          '${migrationDir.path}${Platform.pathSeparator}'
          'backfill_completion.json',
        );

        await file.writeAsString('{bukan json');
        final FileBackfillCompletionStore store = FileBackfillCompletionStore(
          baseDirectoryProvider: () async => dir,
        );
        expect(await store.load('uid-1'), isNull);

        await file.writeAsString(
          jsonEncode(<String, Object?>{
            'storeVersion': 999,
            'uids': <String, Object?>{'uid-1': <String, Object?>{}},
          }),
        );
        expect(await store.load('uid-1'), isNull);
      },
    );
  });
}
