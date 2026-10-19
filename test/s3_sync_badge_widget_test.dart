import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_sync_failures.dart';
import 'package:nousen/features/one_time_reminder/presentation/one_time_reminder_sync_badge.dart';
import 'package:nousen/features/one_time_reminder/presentation/one_time_reminder_sync_messages.dart';
import 'package:nousen/features/settings/data/settings_sync_failures.dart';
import 'package:nousen/features/settings/presentation/settings_sync_badge.dart';
import 'package:nousen/features/settings/presentation/settings_sync_messages.dart';

void main() {
  group('S3 sync badge reminder/note', () {
    late OneTimeReminderSyncFailures failures;

    setUp(() {
      failures = OneTimeReminderSyncFailures();
    });

    tearDown(() {
      failures.dispose();
    });

    Future<void> pumpReminder(
      WidgetTester tester, {
      required Set<String> pending,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            reminderPendingIdsProvider.overrideWith(
              (Ref ref) => Stream<Set<String>>.value(pending),
            ),
            oneTimeReminderSyncFailuresProvider.overrideWithValue(failures),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ReminderSyncBadge(reminderId: 'r1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pumpNote(
      WidgetTester tester, {
      required Set<String> pending,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            notePendingIdsProvider.overrideWith(
              (Ref ref) => Stream<Set<String>>.value(pending),
            ),
            oneTimeReminderSyncFailuresProvider.overrideWithValue(failures),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AgendaNoteSyncBadge(noteId: 'n1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('synced → tanpa ikon', (WidgetTester tester) async {
      await pumpReminder(tester, pending: const <String>{});
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('pending → awan panah amber + tooltip', (
      WidgetTester tester,
    ) async {
      await pumpReminder(tester, pending: const <String>{'r1'});
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.byTooltip('Waiting to sync agenda to cloud'), findsOneWidget);
    });

    testWidgets('failed → awan silang merah + tooltip server', (
      WidgetTester tester,
    ) async {
      failures.recordReminder(
        reminderId: 'r1',
        operation: OneTimeReminderSyncOperation.save,
        error: Exception('permission-denied'),
      );
      await pumpReminder(tester, pending: const <String>{});
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Tooltip &&
              (widget.message ?? '').startsWith('Cloud agenda sync failed:'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('note pending + failed memakai status note, bukan reminder', (
      WidgetTester tester,
    ) async {
      await pumpNote(tester, pending: const <String>{'n1'});
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.byTooltip('Waiting to sync note to cloud'), findsOneWidget);

      failures.recordNote(
        noteId: 'n1',
        operation: OneTimeReminderSyncOperation.delete,
        error: Exception('rules-denied'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(failures.byReminder.value, isEmpty);
    });
  });

  group('S3 sync badge settings', () {
    late SettingsSyncFailures failures;

    setUp(() {
      failures = SettingsSyncFailures();
    });

    tearDown(() {
      failures.dispose();
    });

    testWidgets('pending → {app}; failed → awan silang', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsPendingIdsProvider.overrideWith(
              (Ref ref) => Stream<Set<String>>.value(<String>{'app'}),
            ),
            settingsSyncFailuresProvider.overrideWithValue(failures),
          ],
          child: const MaterialApp(home: Scaffold(body: SettingsSyncBadge())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(
        find.byTooltip('Waiting to sync settings to cloud'),
        findsOneWidget,
      );

      failures.record(error: Exception('permission-denied'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Tooltip &&
              (widget.message ?? '').startsWith('Cloud settings sync failed:'),
        ),
        findsOneWidget,
      );
    });
  });

  group('S3 sync messages', () {
    final DateTime fixedDate = DateTime(2026, 10, 19, 12);

    test('reminder/note snack message membedakan target + operasi', () {
      final OneTimeReminderSyncFailure reminderSave =
          OneTimeReminderSyncFailure(
            id: 'r1',
            target: OneTimeReminderSyncTarget.reminder,
            operation: OneTimeReminderSyncOperation.save,
            message: 'denied',
            at: fixedDate,
          );
      expect(
        oneTimeReminderSyncFailureSnackMessage(
          isId: true,
          failure: reminderSave,
        ),
        contains('agenda'),
      );

      final OneTimeReminderSyncFailure noteDelete = OneTimeReminderSyncFailure(
        id: 'n1',
        target: OneTimeReminderSyncTarget.note,
        operation: OneTimeReminderSyncOperation.delete,
        message: 'denied',
        at: fixedDate,
      );
      final String message = oneTimeReminderSyncFailureSnackMessage(
        isId: false,
        failure: noteDelete,
      );
      expect(message, contains('note'));
      expect(message, contains('delete'));
    });

    test('settings snack message', () {
      final SettingsSyncFailure failure = SettingsSyncFailure(
        operation: SettingsSyncOperation.save,
        message: 'denied',
        at: fixedDate,
      );
      expect(
        settingsSyncFailureSnackMessage(isId: true, failure: failure),
        contains('pengaturan'),
      );
      expect(
        settingsSyncFailureSnackMessage(isId: false, failure: failure),
        contains('settings'),
      );
    });
  });
}
