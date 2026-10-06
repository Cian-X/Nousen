import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/schedule_agenda_page.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    await initializeDateFormatting('en');
  });
  testWidgets('range header renders two formatted dates, not code', (
    WidgetTester tester,
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
            (Ref ref) => Stream.value(const []),
          ),
        ],
        child: const MaterialApp(home: ScheduleAgendaPage()),
      ),
    );
    await tester.pumpAndSettle();

    final List<String> texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text w) => w.data ?? '')
        .toList();
    expect(
      texts.any(
        (String s) =>
            s.contains('formatDateShort') || s.contains('days.last'),
      ),
      isFalse,
      reason: 'Header must show formatted dates, not code.',
    );
    expect(
      texts.any((String s) => s.contains(' \u2013 ')),
      isTrue,
      reason: 'Header must render the date range separator.',
    );
  });
}
