import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/core/utils/activity_elapsed_time_utils.dart';

void main() {
  test('running activity shows elapsed time after scheduled start', () {
    final DateTime scheduledAt = DateTime(2026, 3, 11, 14, 0);
    final DateTime now = DateTime(2026, 3, 11, 14, 55);

    final ActivityElapsedTimeState state = resolveActivityElapsedTimeState(
      scheduledAt: scheduledAt,
      now: now,
    );

    expect(state.hasStarted, isTrue);
    expect(state.isFixed, isFalse);
    expect(state.elapsedMinutes, 55);
    expect(formatElapsedMinutesLabel(state.elapsedMinutes), '55m');
  });

  test(
    'completed activity keeps fixed elapsed duration from completion time',
    () {
      final DateTime scheduledAt = DateTime(2026, 3, 11, 14, 0);
      final DateTime now = DateTime(2026, 3, 11, 14, 55);
      final DateTime completionTime = DateTime(2026, 3, 11, 14, 37);

      final ActivityElapsedTimeState state = resolveActivityElapsedTimeState(
        scheduledAt: scheduledAt,
        now: now,
        completionTime: completionTime,
      );

      expect(state.hasStarted, isTrue);
      expect(state.isFixed, isTrue);
      expect(state.elapsedMinutes, 37);
      expect(formatElapsedMinutesLabel(state.elapsedMinutes), '37m');
    },
  );

  test('activity before start does not start elapsed timer yet', () {
    final DateTime scheduledAt = DateTime(2026, 3, 11, 14, 0);
    final DateTime now = DateTime(2026, 3, 11, 13, 45);

    final ActivityElapsedTimeState state = resolveActivityElapsedTimeState(
      scheduledAt: scheduledAt,
      now: now,
    );

    expect(state.hasStarted, isFalse);
    expect(state.isFixed, isFalse);
    expect(state.elapsedMinutes, 0);
  });

  test('completion before scheduled start clamps elapsed time to zero', () {
    final DateTime scheduledAt = DateTime(2026, 3, 11, 14, 0);
    final DateTime now = DateTime(2026, 3, 11, 14, 30);
    final DateTime completionTime = DateTime(2026, 3, 11, 13, 55);

    final ActivityElapsedTimeState state = resolveActivityElapsedTimeState(
      scheduledAt: scheduledAt,
      now: now,
      completionTime: completionTime,
    );

    expect(state.hasStarted, isTrue);
    expect(state.isFixed, isTrue);
    expect(state.elapsedMinutes, 0);
  });
}
