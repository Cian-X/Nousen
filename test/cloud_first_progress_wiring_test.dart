import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/core/migration/migration_flags.dart';
import 'package:nousen/features/progress/data/cloud_first_progress_repository.dart';
import 'package:nousen/features/progress/data/cloud_progress_backend.dart';
import 'package:nousen/features/progress/data/dual_write_progress_repository.dart';
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

class _SetCall {
  _SetCall(this.docId, this.data);

  final String docId;
  final Map<String, dynamic> data;
}

class _FakeBackend implements CloudProgressBackend {
  final List<_SetCall> setCalls = <_SetCall>[];
  final List<String> deleteCalls = <String>[];
  List<CloudProgressDoc> watchDocs = <CloudProgressDoc>[];

  @override
  Future<void> setDoc(
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) async {
    setCalls.add(_SetCall(docId, Map<String, dynamic>.from(data)));
  }

  @override
  Future<void> deleteByActivity(String uid, String activityId) async {
    deleteCalls.add(activityId);
  }

  @override
  Stream<List<CloudProgressDoc>> watchAll(String uid) {
    return Stream<List<CloudProgressDoc>>.value(watchDocs);
  }

  @override
  Future<List<Map<String, dynamic>>> queryAll(String uid) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> getByActivityAndDate(
    String uid, {
    required String activityId,
    required String dateKey,
  }) async {
    return null;
  }
}

class _FakeLocalRepo implements ProgressRepository {
  final Map<String, ProgressEntryModel> store = <String, ProgressEntryModel>{};

  @override
  Stream<List<ProgressEntryModel>> watchAll() =>
      Stream<List<ProgressEntryModel>>.value(store.values.toList());

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) =>
      Stream<List<ProgressEntryModel>>.value(
        store.values
            .where((ProgressEntryModel e) => e.activityId == activityId)
            .toList(),
      );

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) =>
      Stream<List<ProgressEntryModel>>.value(
        store.values
            .where((ProgressEntryModel e) => e.dateKey == dateKey)
            .toList(),
      );

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) =>
      Stream<List<ProgressEntryModel>>.value(const <ProgressEntryModel>[]);

  @override
  Future<List<ProgressEntryModel>> getAll() async => store.values.toList();

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
    store.removeWhere(
      (_, ProgressEntryModel e) => e.activityId == activityId,
    );
  }
}

ProgressEntryModel _entry({String id = 'p1'}) {
  final DateTime now = DateTime(2026, 10, 18, 10);
  return ProgressEntryModel(
    id: id,
    activityId: 'a1',
    dateKey: '2026-10-18',
    status: ActivityDayStatus.notDone,
    subCompleted: 0,
    subTotal: 2,
    completedSubActivities: const <String>[],
    photoPaths: const <String>[],
    photoPath: null,
    photoNote: null,
    notes: null,
    completionTime: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Wiring progressRepositoryProvider (S2)', () {
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
          cloudProgressBackendProvider.overrideWithValue(backend),
          progressLocalRepositoryProvider.overrideWithValue(local),
          cloudAuthStateProvider.overrideWithValue(auth),
          if (flags != null) migrationFlagsProvider.overrideWithValue(flags),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('default build mengikuti dart-define: tanpa define → dual-write, '
        'dengan define NOUSEN_CLOUD_FIRST_PROGRESS → cloud-first', () {
      // Jalur default (tanpa override flag) — ini yang dipakai APK owner.
      final ProgressRepository picked = buildContainer().read(
        progressRepositoryProvider,
      );

      if (MigrationFlags.fromEnvironment.cloudFirstProgress) {
        expect(picked, isA<CloudFirstProgressRepository>());
      } else {
        expect(picked, isA<DualWriteProgressRepository>());
      }
    });

    test(
      'flag ON: tulis lewat provider → cloud primer (tanpa ack) + mirror '
      'Isar hidup; deleteByActivity → cloud + mirror',
      () async {
        final ProgressRepository picked = buildContainer(
          flags: const MigrationFlags(cloudFirstProgress: true),
        ).read(progressRepositoryProvider);
        expect(picked, isA<CloudFirstProgressRepository>());

        await picked.upsert(_entry());
        expect(backend.setCalls, hasLength(1));
        expect(backend.setCalls.single.docId, 'p1');
        expect(backend.setCalls.single.data['activityId'], 'a1');
        expect(local.store.containsKey('p1'), isTrue);

        await picked.deleteByActivity('a1');
        expect(backend.deleteCalls, <String>['a1']);
        expect(local.store, isEmpty);
      },
    );

    test(
      'flag OFF: jalur lama — tulis ke lokal; cloud dilewati saat uid null',
      () async {
        auth.uid = null;
        final ProgressRepository picked = buildContainer(
          flags: MigrationFlags.disabled,
        ).read(progressRepositoryProvider);
        expect(picked, isA<DualWriteProgressRepository>());

        await picked.upsert(_entry());

        expect(local.store.containsKey('p1'), isTrue);
        expect(backend.setCalls, isEmpty);
      },
    );

    test('flag ON: pending ids dari metadata backend + failures terhubung ke '
        'repo cloud-first', () async {
      final ProviderContainer container = buildContainer(
        flags: const MigrationFlags(cloudFirstProgress: true),
      );
      backend.watchDocs = <CloudProgressDoc>[
        CloudProgressDoc(
          id: 'p1',
          data: <String, dynamic>{'id': 'p1'},
          hasPendingWrites: true,
        ),
        CloudProgressDoc(
          id: 'p2',
          data: <String, dynamic>{'id': 'p2'},
          hasPendingWrites: false,
        ),
      ];

      final Set<String> pending = await container.read(
        progressPendingIdsProvider.future,
      );
      expect(pending, <String>{'p1'});

      final CloudFirstProgressRepository? repo = container.read(
        cloudFirstProgressRepositoryProvider,
      );
      expect(repo, isNotNull);
      expect(
        identical(repo!.failures, container.read(progressSyncFailuresProvider)),
        isTrue,
      );
    });

    test('flag OFF: repo cloud-first null dan pending ids tidak aktif', () {
      final ProviderContainer container = buildContainer(
        flags: MigrationFlags.disabled,
      );

      expect(container.read(cloudFirstProgressRepositoryProvider), isNull);
      expect(container.read(progressPendingIdsProvider).value, isNull);
    });
  });
}
