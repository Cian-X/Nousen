import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/core/utils/time_utils.dart';

void main() {
  test('formatMinutesAsTime formats HH:mm', () {
    expect(formatMinutesAsTime(0), '00:00');
    expect(formatMinutesAsTime(75), '01:15');
    expect(formatMinutesAsTime(1439), '23:59');
  });
}
