import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/schedule_agenda_page.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    await initializeDateFormatting('en');
  });

  OneTimeReminderModel reminder({
    required String id,
    required String title,
    required DateTime at,
    List<String> subs = const <String>[],
    List<String> doneSubs = const <String>[],
    bool isCompleted = false,
  }) {
    final DateTime now = DateTime.now();
    return OneTimeReminderModel(
      id: id,
      title: title,
      iconKey: 'calendar',
      scheduledAt: at,
      subActivities: subs,
      completedSubActivities: doneSubs,
      preReminderMinutes: 0,
      isNotificationEnabled: true,
      isCompleted: isCompleted,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpAgenda(
    WidgetTester tester,
    List<OneTimeReminderModel> items,
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
          oneTimeRemindersStreamProvider.overrideWith(
            (Ref ref) => Stream<List<OneTimeReminderModel>>.value(items),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ScheduleAgendaPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  DateTime atToday(int hour, [int minute = 0]) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  testWidgets('kartu tanpa ikon status, progres sub terlihat', (
    WidgetTester tester,
  ) async {
    await pumpAgenda(tester, <OneTimeReminderModel>[
      reminder(
        id: 'r1',
        title: 'Rapat',
        at: atToday(11),
        subs: const <String>['a', 'b'],
      ),
      reminder(id: 'r2', title: 'Joging', at: atToday(12)),
    ]);

    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.text('2 sub aktivitas'), findsOneWidget);
    expect(find.text('Agenda terjadwal'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
  });

  testWidgets('chevron membuka checklist sub', (
    WidgetTester tester,
  ) async {
    await pumpAgenda(tester, <OneTimeReminderModel>[
      reminder(
        id: 'r1',
        title: 'Rapat',
        at: atToday(11),
        subs: const <String>['a', 'b'],
      ),
    ]);

    expect(find.text('a'), findsNothing);
    await tester.ensureVisible(find.byIcon(Icons.expand_more_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.expand_less_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_less_rounded));
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
  });

  testWidgets('checkbox ikut warna status tiap kondisi', (
    WidgetTester tester,
  ) async {
    DateTime atDays(int offset, int hour) {
      final DateTime now = DateTime.now();
      final DateTime base = DateTime(now.year, now.month, now.day);
      return base.add(Duration(days: offset, hours: hour));
    }

    DateTime todayAt(int hour) {
      final DateTime now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour);
    }

    await pumpAgenda(tester, <OneTimeReminderModel>[
      reminder(
        id: 'done',
        title: 'Selesai',
        at: todayAt(7),
        subs: const <String>['x'],
        doneSubs: const <String>['x'],
        isCompleted: true,
      ),
      reminder(
        id: 'future',
        title: 'Nanti',
        at: atDays(1, 10),
        subs: const <String>['y'],
      ),
    ]);

    Future<Color?> expandedCheckboxColor() async {
      await tester.ensureVisible(find.byIcon(Icons.expand_more_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
      await tester.pumpAndSettle();
      final Checkbox box =
          tester.widget<Checkbox>(find.byType(Checkbox).first);
      return box.activeColor;
    }

    expect(await expandedCheckboxColor(), const Color(0xFF1A5BAD));

    final DateTime futureDay = atDays(1, 10).copyWith();
    final Finder dayCell =
        find.text('${DateTime(futureDay.year, futureDay.month, futureDay.day).day}');
    await tester.ensureVisible(dayCell.first);
    await tester.pumpAndSettle();
    await tester.tap(dayCell.first);
    await tester.pumpAndSettle();
    expect(await expandedCheckboxColor(), const Color(0xFF585F6A));
  });
}
