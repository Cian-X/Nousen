import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/schedule_agenda_page.dart';

void main() {
  group('agendaWindowStart', () {
    test('hari ini selalu menjadi awal jendela', () {
      final DateTime today = dateOnly(DateTime(2026, 10, 9, 15, 30));
      expect(agendaWindowStart(today), DateTime(2026, 10, 9));
    });

    test('awal jendela mengikuti tanggal perangkat, bukan Senin', () {
      // Jumat: awal tetap Jumat, bukan Senin minggu itu.
      final DateTime friday = dateOnly(DateTime(2026, 10, 9));
      expect(friday.weekday, DateTime.friday);
      expect(agendaWindowStart(friday), friday);
    });
  });

  group('agendaWindowDays', () {
    test('tepat 14 hari berurutan', () {
      final List<DateTime> days =
          agendaWindowDays(dateOnly(DateTime(2026, 10, 9)));
      expect(days.length, 14);
      for (int i = 1; i < days.length; i++) {
        expect(
          days[i].difference(days[i - 1]),
          const Duration(days: 1),
          reason: 'hari ke-$i harus tepat sehari setelah sebelumnya',
        );
      }
    });

    test('indeks pertama hari ini, terakhir hari ini + 13', () {
      final DateTime today = dateOnly(DateTime(2026, 10, 9));
      final List<DateTime> days = agendaWindowDays(today);
      expect(days.first, today);
      expect(days.last, today.add(const Duration(days: 13)));
    });

    test('benar melewati batas bulan dan tahun', () {
      final List<DateTime> days =
          agendaWindowDays(dateOnly(DateTime(2026, 12, 25)));
      expect(days.first, DateTime(2026, 12, 25));
      expect(days.last, DateTime(2027, 1, 7));
      expect(days.length, 14);
    });

    test('bergeser otomatis saat hari berganti', () {
      final List<DateTime> before =
          agendaWindowDays(dateOnly(DateTime(2026, 10, 9)));
      final List<DateTime> after =
          agendaWindowDays(dateOnly(DateTime(2026, 10, 10)));
      expect(after.first, before.first.add(const Duration(days: 1)));
      expect(after.last, before.last.add(const Duration(days: 1)));
    });
  });
}
