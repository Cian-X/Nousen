import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/one_time_reminder_detail_page.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/l10n/app_localizations.dart';

class _FakeReminderRepository implements OneTimeReminderRepository {
  _FakeReminderRepository(this.items);

  final List<OneTimeReminderModel> items;

  @override
  Stream<List<OneTimeReminderModel>> watchAll() =>
      Stream<List<OneTimeReminderModel>>.value(items);

  @override
  Future<List<OneTimeReminderModel>> getAll() async => items;

  @override
  Future<OneTimeReminderModel?> getById(String id) async {
    for (final OneTimeReminderModel item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(OneTimeReminderModel reminder) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<AgendaNoteModel>> watchNotes(String reminderId) =>
      Stream<List<AgendaNoteModel>>.value(const <AgendaNoteModel>[]);

  @override
  Future<void> upsertNote(AgendaNoteModel note) async {}

  @override
  Future<void> deleteNote(String id) async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    await initializeDateFormatting('en');
  });

  OneTimeReminderModel reminder({
    required String id,
    DateTime? at,
    List<String> subs = const <String>[],
    List<String> doneSubs = const <String>[],
    bool isCompleted = false,
  }) {
    final DateTime now = DateTime.now();
    final DateTime base = at ?? now;
    return OneTimeReminderModel(
      id: id,
      title: 'Rapat $id',
      iconKey: 'calendar',
      scheduledAt: base,
      subActivities: subs,
      completedSubActivities: doneSubs,
      preReminderMinutes: 0,
      isNotificationEnabled: true,
      isCompleted: isCompleted,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    List<OneTimeReminderModel> items,
    String id,
  ) async {
    const AppSettingsModel settings = AppSettingsModel(
      morningReminderMinutes: 420,
      endOfDayReminderMinutes: 1260,
      localeCode: 'id',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          settingsStreamProvider.overrideWith(
            (Ref ref) => Stream<AppSettingsModel>.value(settings),
          ),
          oneTimeReminderRepositoryProvider.overrideWithValue(
            _FakeReminderRepository(items),
          ),
          oneTimeRemindersStreamProvider.overrideWith(
            (Ref ref) => Stream<List<OneTimeReminderModel>>.value(items),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates:
              AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: OneTimeReminderDetailPage(
            args: OneTimeReminderDetailArgs(reminderId: id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tanpa sub dan belum selesai menampilkan 0 persen', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, <OneTimeReminderModel>[
      reminder(id: 'r1'),
    ], 'r1');

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Rapat r1'), findsOneWidget);
  });

  testWidgets('semua sub selesai menampilkan 100 persen biru', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, <OneTimeReminderModel>[
      reminder(
        id: 'r1',
        subs: const <String>['a', 'b'],
        doneSubs: const <String>['a', 'b'],
        isCompleted: true,
      ),
    ], 'r1');

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Selesai'), findsWidgets);
  });

  testWidgets('terlewat menampilkan status merah', (
    WidgetTester tester,
  ) async {
    final DateTime past =
        DateTime.now().subtract(const Duration(days: 2));
    await pumpDetail(tester, <OneTimeReminderModel>[
      reminder(
        id: 'r1',
        at: DateTime(past.year, past.month, past.day, 10),
      ),
    ], 'r1');

    expect(find.text('Terlewat'), findsWidgets,
        reason: 'coba dump: ${tester.widgetList<Text>(find.byType(Text)).map((Text w) => w.data).where((String? s) => s != null && s.isNotEmpty).take(12).toList()}');
  });
}
