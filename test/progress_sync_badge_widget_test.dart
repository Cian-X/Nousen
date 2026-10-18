import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/presentation/progress_sync_badge.dart';

Future<void> _pumpBadge(
  WidgetTester tester, {
  required String? entryId,
  required Set<String> pending,
  required ProgressSyncFailures tracker,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        progressPendingIdsProvider.overrideWith(
          (Ref ref) => Stream<Set<String>>.value(pending),
        ),
        progressSyncFailuresProvider.overrideWithValue(tracker),
      ],
      child: MaterialApp(
        home: Scaffold(body: ProgressSyncBadge(entryId: entryId)),
      ),
    ),
  );
}

Future<void> _pumpDeleteBadge(
  WidgetTester tester, {
  required String activityId,
  required ProgressSyncFailures tracker,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        progressSyncFailuresProvider.overrideWithValue(tracker),
      ],
      child: MaterialApp(
        home: Scaffold(body: ProgressDeleteBadge(activityId: activityId)),
      ),
    ),
  );
}

void main() {
  testWidgets('pending milik entry → ikon cloud_upload; entry lain / null → '
      'tanpa ikon', (WidgetTester tester) async {
    final ProgressSyncFailures tracker = ProgressSyncFailures();
    addTearDown(tracker.dispose);

    await _pumpBadge(
      tester,
      entryId: 'p1',
      pending: <String>{'p1'},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(
      find.byTooltip('Waiting to sync progress to cloud'),
      findsOneWidget,
    );

    await _pumpBadge(
      tester,
      entryId: 'p2',
      pending: <String>{'p1'},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);

    await _pumpBadge(
      tester,
      entryId: null,
      pending: <String>{'p1'},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
  });

  testWidgets('reject server → ikon cloud_off + tooltip pesan (non-silent)', (
    WidgetTester tester,
  ) async {
    final ProgressSyncFailures tracker = ProgressSyncFailures();
    addTearDown(tracker.dispose);

    await _pumpBadge(
      tester,
      entryId: 'p1',
      pending: const <String>{},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);

    tracker.record(
      entryId: 'p1',
      operation: ProgressSyncOperation.save,
      error: StateError('rules tolak'),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(
      find.byTooltip('Cloud progress sync failed: Bad state: rules tolak'),
      findsOneWidget,
    );
  });

  testWidgets('failed menang atas pending; clear → kembali pending; synced → '
      'tanpa ikon (badge hilang)', (WidgetTester tester) async {
    final ProgressSyncFailures tracker = ProgressSyncFailures();
    addTearDown(tracker.dispose);
    // Pending digerakkan lewat stream (seperti metadata Firestore berubah),
    // bukan re-pump dengan override berbeda — riverpod tidak me-reset state
    // override pada pumpWidget ulang.
    final StreamController<Set<String>> pendingCtrl =
        StreamController<Set<String>>.broadcast();
    addTearDown(pendingCtrl.close);
    tracker.record(
      entryId: 'p1',
      operation: ProgressSyncOperation.delete,
      error: StateError('permission-denied'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          progressPendingIdsProvider.overrideWith(
            (Ref ref) => pendingCtrl.stream,
          ),
          progressSyncFailuresProvider.overrideWithValue(tracker),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgressSyncBadge(entryId: 'p1')),
        ),
      ),
    );
    pendingCtrl.add(<String>{'p1'});
    await tester.pumpAndSettle();
    // Failed menang atas pending.
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);

    tracker.clear('p1');
    await tester.pumpAndSettle();
    // Status gagal dibersihkan, tetapi tulis masih menunggu ack SDK.
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

    pendingCtrl.add(const <String>{});
    await tester.pumpAndSettle();
    // Synced (ack datang, metadata bersih) → tidak ada ikon.
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
  });

  testWidgets('delete reject → badge activity-scoped terlihat walau baris '
      'entri sudah terhapus; activity lain tanpa ikon', (
    WidgetTester tester,
  ) async {
    final ProgressSyncFailures tracker = ProgressSyncFailures();
    addTearDown(tracker.dispose);
    // Di alur nyata baris progres sudah terhapus saat reject datang —
    // badge ini tidak bergantung pada baris/per-entry state sama sekali.
    tracker.recordActivity(
      activityId: 'a1',
      operation: ProgressSyncOperation.delete,
      error: StateError('permission-denied'),
    );

    await _pumpDeleteBadge(tester, activityId: 'a1', tracker: tracker);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(
      find.byTooltip('Cloud progress sync failed: Bad state: permission-denied'),
      findsOneWidget,
    );

    await _pumpDeleteBadge(tester, activityId: 'a2', tracker: tracker);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
  });

  testWidgets('retry delete sukses (clearActivity) → badge hilang', (
    WidgetTester tester,
  ) async {
    final ProgressSyncFailures tracker = ProgressSyncFailures();
    addTearDown(tracker.dispose);

    await _pumpDeleteBadge(tester, activityId: 'a1', tracker: tracker);
    tracker.recordActivity(
      activityId: 'a1',
      operation: ProgressSyncOperation.delete,
      error: StateError('permission-denied'),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    tracker.clearActivity('a1');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
  });
}
