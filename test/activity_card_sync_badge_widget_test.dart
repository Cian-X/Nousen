import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/presentation/activity_card_sync_badge.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';

const String _activityPendingMsg = 'Activity waiting to sync to cloud';
const String _progressPendingMsg = 'Waiting to sync progress to cloud';

/// Widget test badge GABUNGAN kartu/header aktivitas (temuan device
/// 2026-10-19: dua ikon amber dari domain berbeda terlihat duplikat).
void main() {
  late ActivitySyncFailures activityFailures;
  late ProgressSyncFailures progressFailures;

  setUp(() {
    activityFailures = ActivitySyncFailures();
    progressFailures = ProgressSyncFailures();
  });

  tearDown(() {
    activityFailures.dispose();
    progressFailures.dispose();
  });

  Future<void> pumpBadge(
    WidgetTester tester, {
    String activityId = 'a1',
    String? entryId = 'p1',
    Set<String> activityPending = const <String>{},
    Set<String> progressPending = const <String>{},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          activityPendingIdsProvider.overrideWith(
            (Ref ref) => Stream<Set<String>>.value(activityPending),
          ),
          progressPendingIdsProvider.overrideWith(
            (Ref ref) => Stream<Set<String>>.value(progressPending),
          ),
          activitySyncFailuresProvider.overrideWithValue(activityFailures),
          progressSyncFailuresProvider.overrideWithValue(progressFailures),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityCardSyncBadge(
              activityId: activityId,
              entryId: entryId,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder amberIcon() => find.byIcon(Icons.cloud_upload_outlined);
  Finder redIcon() => find.byIcon(Icons.cloud_off_outlined);

  String tooltipMessage(WidgetTester tester) {
    expect(find.byType(Tooltip), findsOneWidget);
    return tester.widget<Tooltip>(find.byType(Tooltip)).message ?? '';
  }

  testWidgets('synced: tanpa ikon & tanpa tooltip', (WidgetTester tester) async {
    await pumpBadge(tester);

    expect(amberIcon(), findsNothing);
    expect(redIcon(), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('pending aktivitas → satu ikon amber + tooltip domain aktivitas',
      (WidgetTester tester) async {
    await pumpBadge(tester, activityPending: <String>{'a1'});

    expect(amberIcon(), findsOneWidget);
    expect(redIcon(), findsNothing);
    expect(tooltipMessage(tester), _activityPendingMsg);
  });

  testWidgets('pending progres milik entri → amber + tooltip domain progres',
      (WidgetTester tester) async {
    await pumpBadge(tester, progressPending: <String>{'p1'});

    expect(amberIcon(), findsOneWidget);
    expect(tooltipMessage(tester), _progressPendingMsg);
  });

  testWidgets('pending aktivitas + progres: tetap SATU ikon; tooltip memuat '
      'dua domain', (WidgetTester tester) async {
    await pumpBadge(
      tester,
      activityPending: <String>{'a1'},
      progressPending: <String>{'p1'},
    );

    expect(amberIcon(), findsOneWidget);
    expect(
      tooltipMessage(tester),
      '$_activityPendingMsg\n$_progressPendingMsg',
    );
  });

  testWidgets('pending milik kartu/entri lain → tanpa ikon',
      (WidgetTester tester) async {
    await pumpBadge(
      tester,
      activityPending: <String>{'a2'},
      progressPending: <String>{'p2'},
    );

    expect(amberIcon(), findsNothing);
    expect(redIcon(), findsNothing);
  });

  testWidgets('gagal tulis aktivitas → merah; PRIORITAS di atas pending '
      '(tetap satu ikon)', (WidgetTester tester) async {
    activityFailures.record(
      activityId: 'a1',
      operation: ActivitySyncOperation.save,
      error: StateError('rules tolak'),
    );
    await pumpBadge(
      tester,
      activityPending: <String>{'a1'},
      progressPending: <String>{'p1'},
    );

    expect(redIcon(), findsOneWidget);
    expect(amberIcon(), findsNothing);
    expect(tooltipMessage(tester), contains('Activity cloud sync failed'));
    expect(tooltipMessage(tester), contains('rules tolak'));
  });

  testWidgets('gagal tulis entri progres → merah + tooltip domain progres',
      (WidgetTester tester) async {
    progressFailures.record(
      entryId: 'p1',
      operation: ProgressSyncOperation.save,
      error: StateError('permission-denied'),
    );
    await pumpBadge(tester);

    expect(redIcon(), findsOneWidget);
    expect(tooltipMessage(tester), contains('Cloud progress sync failed'));
    expect(tooltipMessage(tester), contains('permission-denied'));
  });

  testWidgets('gagal pembersihan progres (deleteByActivity) → merah walau '
      'entryId null', (WidgetTester tester) async {
    progressFailures.recordActivity(
      activityId: 'a1',
      operation: ProgressSyncOperation.delete,
      error: StateError('rules tolak hapus'),
    );
    await pumpBadge(tester, entryId: null);

    expect(redIcon(), findsOneWidget);
    expect(tooltipMessage(tester), contains('rules tolak hapus'));
  });

  testWidgets('entryId null: status pending progres tidak berlaku',
      (WidgetTester tester) async {
    await pumpBadge(tester, entryId: null, progressPending: <String>{'p1'});

    expect(amberIcon(), findsNothing);
    expect(redIcon(), findsNothing);
  });

  testWidgets('rekam kegagalan setelah render → merah; clear → ikon hilang '
      '(listenable hidup)', (WidgetTester tester) async {
    await pumpBadge(tester);
    expect(redIcon(), findsNothing);

    activityFailures.record(
      activityId: 'a1',
      operation: ActivitySyncOperation.delete,
      error: StateError('rules tolak'),
    );
    await tester.pump();
    expect(redIcon(), findsOneWidget);

    activityFailures.clear('a1');
    await tester.pump();
    expect(redIcon(), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });
}
