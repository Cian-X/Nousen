import 'package:home_widget/home_widget.dart';
import 'package:nousen/core/utils/time_utils.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';

class WidgetSyncService {
  const WidgetSyncService._();

  static const String appWidgetProvider = 'NousenAppWidgetProvider';

  static Future<void> updateWidget({
    required List<ActivityModel> activities,
    required List<ProgressEntryModel> todayProgress,
    required List<OneTimeReminderModel> todayReminders,
  }) async {
    try {
      final now = DateTime.now();
      final todayWeekday = now.weekday;

      final todayActivities = activities
          .where((a) => a.selectedDays.contains(todayWeekday))
          .toList();

      final completedActivityIds = todayProgress
          .where((p) =>
              p.status == ActivityDayStatus.done ||
              p.status == ActivityDayStatus.skipped)
          .map((p) => p.activityId)
          .toSet();

      final pendingActivities = todayActivities
          .where((a) => !completedActivityIds.contains(a.id))
          .toList();

      final pendingReminders = todayReminders
          .where((r) => !r.isCompleted)
          .toList();

      final totalPending = pendingActivities.length + pendingReminders.length;

      String title = 'Semua aktivitas selesai!';
      String subtitle = 'Bagus sekali! Tidak ada tugas tertunda.';

      if (pendingReminders.isNotEmpty) {
        final nextReminder = pendingReminders.first;
        title = nextReminder.title;
        subtitle = 'Agenda \u2022 ${nextReminder.scheduledAt.hour.toString().padLeft(2, '0')}:${nextReminder.scheduledAt.minute.toString().padLeft(2, '0')}';
      } else if (pendingActivities.isNotEmpty) {
        final nextActivity = pendingActivities.first;
        title = nextActivity.title;
        subtitle = 'Aktivitas \u2022 ${formatMinutesAsTime(nextActivity.timeMinutes)}';
      }

      await HomeWidget.saveWidgetData<String>('widget_title', title);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', subtitle);
      await HomeWidget.saveWidgetData<String>('widget_count', '$totalPending pending');

      await HomeWidget.updateWidget(
        name: appWidgetProvider,
        androidName: appWidgetProvider,
      );
    } catch (_) {
      // Non-fatal widget sync
    }
  }
}
