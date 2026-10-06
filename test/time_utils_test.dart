import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/core/utils/time_utils.dart';

void main() {
  test('formatMinutesAsTime formats HH:mm', () {
    expect(formatMinutesAsTime(0), '00:00');
    expect(formatMinutesAsTime(75), '01:15');
    expect(formatMinutesAsTime(1439), '23:59');
  });

  group('nextRoundedQuarterMinutes', () {
    int at(int hour, int minute) =>
        nextRoundedQuarterMinutes(DateTime(2026, 10, 5, hour, minute));

    test('membulatkan naik ke kelipatan 15 menit', () {
      expect(at(21, 31), 21 * 60 + 45);
      expect(at(21, 1), 21 * 60 + 15);
      expect(at(8, 30), 8 * 60 + 30);
    });

    test('tepat di kelipatan tidak berubah', () {
      expect(at(21, 45), 21 * 60 + 45);
      expect(at(0, 0), 0);
    });

    test('batas jam dan tengah malam bergulir', () {
      expect(at(21, 46), 22 * 60);
      expect(at(23, 50), 0);
    });
  });
}
