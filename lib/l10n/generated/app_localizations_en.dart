// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Reminder Schedule';

  @override
  String get homeTab => 'Home';

  @override
  String get statsTab => 'Stats';

  @override
  String get settingsTab => 'Settings';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get todayActivities => 'Today\'s activities';

  @override
  String get emptyActivities => 'No activities yet. Add one to get started.';

  @override
  String get photoTracking => 'Photo tracking on';

  @override
  String get notScheduledToday => 'Not scheduled today';

  @override
  String todaySummary(int taskCount, int completedCount) {
    return '$completedCount/$taskCount tasks completed today';
  }

  @override
  String globalStreakValue(int days) {
    return 'Global streak: $days days';
  }

  @override
  String get createActivity => 'Create activity';

  @override
  String get editActivity => 'Edit activity';

  @override
  String get activityTitle => 'Activity title';

  @override
  String get activityTitleHint => 'Example: Morning Workout';

  @override
  String get selectedDays => 'Selected days';

  @override
  String get scheduledTime => 'Scheduled time';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get enableMorningReminder => 'Enable morning reminder';

  @override
  String get enableEndOfDayReminder => 'Enable end-of-day reminder';

  @override
  String get enablePhotoProgress => 'Enable photo progress';

  @override
  String get formValidationMessage =>
      'Please fill title and choose at least one day.';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get activityDetail => 'Activity detail';

  @override
  String get activityNotFound => 'Activity not found.';

  @override
  String get deleteActivity => 'Delete activity';

  @override
  String deleteActivityConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get completionRate => 'Completion rate';

  @override
  String get currentStreak => 'Current streak';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get weeklyProgress => 'Weekly progress';

  @override
  String get completeToday => 'Complete today';

  @override
  String get oneTapComplete => 'One tap completion';

  @override
  String get progressPhotos => 'Progress photos';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get historyLog => 'History log';

  @override
  String get noHistoryYet => 'No history yet.';

  @override
  String get completed => 'Completed';

  @override
  String get notCompleted => 'Not completed';

  @override
  String get noPhotoYet => 'No photos yet.';

  @override
  String get overallCompletion => 'Overall completion';

  @override
  String get last7DaysChart => 'Last 7 days';

  @override
  String get breakdownPerActivity => 'Per-activity breakdown';

  @override
  String get reminderSettings => 'Reminder settings';

  @override
  String get morningReminderTime => 'Morning reminder time';

  @override
  String get endOfDayReminderTime => 'End-of-day reminder time';

  @override
  String get language => 'Language';

  @override
  String get languageId => 'Bahasa Indonesia';

  @override
  String get languageEn => 'English';
}
