import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/application/stats_service.dart';

void main() {
  ActivityModel activity({required String id}) {
    final DateTime now = DateTime(2026, 10, 5, 8);
    return ActivityModel(
      id: id,
      title: 'A $id',
      selectedDays: const <int>[1, 2, 3, 4, 5, 6, 7],
      subActivities: const <String>[],
      timeMinutes: 480,
      weeklyGoal: 7,
      preReminderMinutes: 0,
      isNotificationEnabled: false,
      enableMorningReminder: false,
      enableEndOfDayReminder: false,
      enablePhotoProgress: false,
      lastThreeDayRuleNotifiedDate: null,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: now,
    );
  }

  ProgressEntryModel entry({
    required String activityId,
    required String dateKey,
    required ActivityDayStatus status,
  }) {
    final DateTime now = DateTime(2026, 10, 5, 8);
    return ProgressEntryModel(
      id: '$activityId-$dateKey',
      activityId: activityId,
      dateKey: dateKey,
      status: status,
      subCompleted: 0,
      subTotal: 0,
      completedSubActivities: const <String>[],
      photoPaths: const <String>[],
      photoPath: null,
      photoNote: null,
      notes: null,
      completionTime: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('GlobalScheduledStatsCalculator tanpa Agenda', () {
    test('menghitung hanya aktivitas', () {
      final GlobalScheduledStatsCalculator calculator =
          GlobalScheduledStatsCalculator(
            activities: <ActivityModel>[activity(id: 'a')],
            progressEntries: <ProgressEntryModel>[
              entry(
                activityId: 'a',
                dateKey: '2026-10-05',
                status: ActivityDayStatus.done,
              ),
            ],
          );

      final double rate = calculator.getGlobalCompletionRate(
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 5),
      );

      expect(rate, 1.0);
    });

    test('tanpa aktivitas hasilnya nol walau ada tanggal', () {
      final GlobalScheduledStatsCalculator calculator =
          GlobalScheduledStatsCalculator(
            activities: <ActivityModel>[],
            progressEntries: <ProgressEntryModel>[],
          );

      expect(
        calculator.getGlobalCompletionRate(
          DateTime(2026, 10, 5),
          DateTime(2026, 10, 5),
        ),
        0,
      );
    });
  });
}
