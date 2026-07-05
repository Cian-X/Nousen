import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/features/activity/domain/activity_daily_progress_status.dart';
import 'package:liburan_create/features/activity/domain/activity_progress_summary.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

void main() {
  group('resolveActivityProgressSummary', () {
    test('calculates percentage from completed sub-activities', () {
      final List<({int completed, int total, int expectedPercent})> cases =
          <({int completed, int total, int expectedPercent})>[
            (completed: 1, total: 2, expectedPercent: 50),
            (completed: 1, total: 3, expectedPercent: 33),
            (completed: 2, total: 3, expectedPercent: 67),
            (completed: 2, total: 4, expectedPercent: 50),
            (completed: 3, total: 5, expectedPercent: 60),
            (completed: 5, total: 5, expectedPercent: 100),
          ];

      for (final ({int completed, int total, int expectedPercent}) item
          in cases) {
        final List<String> subActivities = List<String>.generate(
          item.total,
          (int index) => 'sub-$index',
        );
        final ActivityProgressSummary summary = resolveActivityProgressSummary(
          subActivities: subActivities,
          entry: _entry(
            completedSubActivities: subActivities.take(item.completed).toList(),
            subCompleted: item.completed,
            subTotal: item.total,
          ),
        );

        expect(summary.completedSubCount, item.completed);
        expect(summary.totalSubCount, item.total);
        expect(summary.percent, item.expectedPercent);
        expect(summary.rate, closeTo(item.expectedPercent / 100, 0.0001));
        expect(
          summary.state,
          item.expectedPercent == 100
              ? ActivityProgressState.complete
              : ActivityProgressState.partial,
        );
      }
    });

    test('uses main activity status when there are no sub-activities', () {
      final ActivityProgressSummary notDone = resolveActivityProgressSummary(
        subActivities: const <String>[],
        entry: _entry(status: ActivityDayStatus.notDone),
      );
      final ActivityProgressSummary done = resolveActivityProgressSummary(
        subActivities: const <String>[],
        entry: _entry(status: ActivityDayStatus.done),
      );

      expect(notDone.rate, 0);
      expect(notDone.percent, 0);
      expect(notDone.state, ActivityProgressState.notStarted);
      expect(done.rate, 1);
      expect(done.percent, 100);
      expect(done.state, ActivityProgressState.complete);
    });

    test('maps 0 percent to not started state', () {
      final ActivityProgressSummary summary = resolveActivityProgressSummary(
        subActivities: const <String>['makan', 'minum', 'mandi'],
        entry: _entry(),
      );

      expect(summary.rate, 0);
      expect(summary.percent, 0);
      expect(summary.state, ActivityProgressState.notStarted);
    });
  });

  group('resolveActivityDailyProgressStatus', () {
    test('derives partial state from completed sub-activity list', () {
      final ActivityDailyProgressStatus status =
          resolveActivityDailyProgressStatus(
            scheduledDate: DateTime(2026, 3, 9),
            today: DateTime(2026, 3, 9),
            scheduleUpdatedAt: DateTime(2026, 3, 1),
            subActivities: const <String>['makan', 'minum', 'mandi'],
            entry: _entry(
              completedSubActivities: const <String>['makan'],
              subCompleted: 0,
              subTotal: 0,
            ),
          );

      expect(status, ActivityDailyProgressStatus.partial);
    });
  });
}

ProgressEntryModel _entry({
  ActivityDayStatus status = ActivityDayStatus.notDone,
  List<String> completedSubActivities = const <String>[],
  int subCompleted = 0,
  int subTotal = 0,
}) {
  final DateTime now = DateTime(2026, 3, 9, 10);
  return ProgressEntryModel(
    id: 'entry-1',
    activityId: 'activity-1',
    dateKey: '2026-03-09',
    status: status,
    subCompleted: subCompleted,
    subTotal: subTotal,
    completedSubActivities: completedSubActivities,
    photoPaths: const <String>[],
    photoPath: null,
    photoNote: null,
    notes: null,
    completionTime: status == ActivityDayStatus.done ? now : null,
    createdAt: now,
    updatedAt: now,
  );
}
