import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/core/widgets/weekly_progress_widget.dart';

void main() {
  group('weeklyProgressBarHeight', () {
    test('maps progress thresholds to fixed heights', () {
      expect(weeklyProgressBarHeight(0), 4);
      expect(weeklyProgressBarHeight(0.01), 12);
      expect(weeklyProgressBarHeight(0.30), 12);
      expect(weeklyProgressBarHeight(0.31), 20);
      expect(weeklyProgressBarHeight(0.70), 20);
      expect(weeklyProgressBarHeight(0.71), 28);
      expect(weeklyProgressBarHeight(0.99), 28);
      expect(weeklyProgressBarHeight(1), 36);
    });
  });

  group('resolveWeeklyProgressVisualStateFromCounts', () {
    final DateTime today = DateTime(2026, 3, 7);

    test('marks future dates as future', () {
      expect(
        resolveWeeklyProgressVisualStateFromCounts(
          date: DateTime(2026, 3, 8),
          today: today,
          totalScheduled: 2,
          totalCompleted: 0,
        ),
        WeeklyProgressDayVisualState.future,
      );
    });

    test('marks no scheduled activity as not scheduled', () {
      expect(
        resolveWeeklyProgressVisualStateFromCounts(
          date: DateTime(2026, 3, 6),
          today: today,
          totalScheduled: 0,
          totalCompleted: 0,
        ),
        WeeklyProgressDayVisualState.notScheduled,
      );
    });

    test('marks scheduled zero completion as pending', () {
      expect(
        resolveWeeklyProgressVisualStateFromCounts(
          date: DateTime(2026, 3, 6),
          today: today,
          totalScheduled: 3,
          totalCompleted: 0,
        ),
        WeeklyProgressDayVisualState.pending,
      );
    });

    test('marks partial completion as partial', () {
      expect(
        resolveWeeklyProgressVisualStateFromCounts(
          date: DateTime(2026, 3, 6),
          today: today,
          totalScheduled: 4,
          totalCompleted: 2,
        ),
        WeeklyProgressDayVisualState.partial,
      );
    });

    test('marks full completion as complete', () {
      expect(
        resolveWeeklyProgressVisualStateFromCounts(
          date: DateTime(2026, 3, 6),
          today: today,
          totalScheduled: 2,
          totalCompleted: 2,
        ),
        WeeklyProgressDayVisualState.complete,
      );
    });
  });

  group('weeklyProgressBarColor', () {
    test('matches global stats gray and light gray colors', () {
      final ThemeData theme = ThemeData();

      expect(
        weeklyProgressBarColor(
          theme: theme,
          state: WeeklyProgressDayVisualState.pending,
        ),
        const Color(0xFF9CA3AF),
      );
      expect(
        weeklyProgressBarColor(
          theme: theme,
          state: WeeklyProgressDayVisualState.future,
        ),
        const Color(0xFFD1D5DB),
      );
      expect(
        weeklyProgressBarColor(
          theme: theme,
          state: WeeklyProgressDayVisualState.notScheduled,
        ),
        const Color(0xFFF3F4F6),
      );
    });
  });
}
