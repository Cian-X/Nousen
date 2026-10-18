import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/presentation/activity_sync_badge.dart';

Future<void> _pumpBadge(
  WidgetTester tester, {
  required String activityId,
  required Set<String> pending,
  required ActivitySyncFailures tracker,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        activityPendingIdsProvider.overrideWith(
          (Ref ref) => Stream<Set<String>>.value(pending),
        ),
        activitySyncFailuresProvider.overrideWithValue(tracker),
      ],
      child: MaterialApp(
        home: Scaffold(body: ActivitySyncBadge(activityId: activityId)),
      ),
    ),
  );
}

void main() {
  testWidgets('pending milik activity → ikon cloud_upload; activity lain → '
      'tanpa ikon', (WidgetTester tester) async {
    final ActivitySyncFailures tracker = ActivitySyncFailures();
    addTearDown(tracker.dispose);

    await _pumpBadge(
      tester,
      activityId: 'a1',
      pending: <String>{'a1'},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(find.byTooltip('Waiting to sync to cloud'), findsOneWidget);

    await _pumpBadge(
      tester,
      activityId: 'a2',
      pending: <String>{'a1'},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
  });

  testWidgets('reject server → ikon cloud_off + tooltip pesan (non-silent)', (
    WidgetTester tester,
  ) async {
    final ActivitySyncFailures tracker = ActivitySyncFailures();
    addTearDown(tracker.dispose);

    await _pumpBadge(
      tester,
      activityId: 'a1',
      pending: const <String>{},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);

    tracker.record(
      activityId: 'a1',
      operation: ActivitySyncOperation.save,
      error: StateError('rules tolak'),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(
      find.byTooltip('Cloud sync failed: Bad state: rules tolak'),
      findsOneWidget,
    );
  });

  testWidgets('ack sukses membersihkan status failed (badge hilang)', (
    WidgetTester tester,
  ) async {
    final ActivitySyncFailures tracker = ActivitySyncFailures();
    addTearDown(tracker.dispose);
    tracker.record(
      activityId: 'a1',
      operation: ActivitySyncOperation.delete,
      error: StateError('permission-denied'),
    );

    await _pumpBadge(
      tester,
      activityId: 'a1',
      pending: const <String>{},
      tracker: tracker,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    tracker.clear('a1');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
  });
}
