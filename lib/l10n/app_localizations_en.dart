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
  String get homeSegmentActivities => 'Activities';

  @override
  String get homeSegmentSchedules => 'Schedules';

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
  String get weeklyGoalLabel => 'Weekly goal';

  @override
  String get weeklyGoalHint => 'How many completions per week?';

  @override
  String weeklyGoalValue(int count) {
    return '$count times / week';
  }

  @override
  String get preReminderLabel => 'Pre-start reminder';

  @override
  String get preReminderHint => 'Select reminder offset';

  @override
  String get preReminderOff => 'Off';

  @override
  String preReminderMinutesValue(int minutes) {
    return '$minutes minutes before start';
  }

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
  String get subActivitiesLabel => 'Sub-activities';

  @override
  String get subActivityHint => 'Example: Leg day';

  @override
  String get addSubActivity => 'Add sub';

  @override
  String subActivitiesProgress(int completed, int total) {
    return 'Sub completed: $completed/$total';
  }

  @override
  String get checklistConfirmTitle => 'Checklist confirmation';

  @override
  String get checklistConfirmMessage =>
      'Are you sure this status is correct and should be changed?';

  @override
  String get checklistConfirmAction => 'Yes, change';

  @override
  String get journalNotesTitle => 'Journal notes';

  @override
  String get journalAddNote => 'Add note';

  @override
  String get journalEditNote => 'Edit note';

  @override
  String get journalDeleteNote => 'Delete note';

  @override
  String journalDeleteConfirm(String date) {
    return 'Delete note on $date?';
  }

  @override
  String get journalNoteSaved => 'Note saved.';

  @override
  String get journalNoteLockedDeleteFirst =>
      'A note already exists for that date. Delete it first if you want to replace it.';

  @override
  String get journalNoteDeleted => 'Note deleted.';

  @override
  String get journalEmpty => 'No notes yet.';

  @override
  String journalNotesCount(int count) {
    return '$count saved notes';
  }

  @override
  String get noteDateLabel => 'Note date';

  @override
  String get noteInputHint => 'Write your note...';

  @override
  String get comparisonTimelineTitle => 'Progress timeline';

  @override
  String get comparisonFilter7d => '7 days';

  @override
  String get comparisonFilter30d => '30 days';

  @override
  String get comparisonFilterAll => 'All';

  @override
  String get comparisonEmpty => 'No data available for comparison yet.';

  @override
  String get comparisonTapPhotoCompare =>
      'Tap photo to pick 2 photos for comparison';

  @override
  String get comparisonNoPreviousPhoto => 'No previous photo to compare yet.';

  @override
  String get comparisonPhotoDialogTitle => 'Photo comparison';

  @override
  String get comparisonCurrentPhoto => 'Current photo';

  @override
  String get comparisonPreviousPhoto => 'Previous photo';

  @override
  String get comparisonFirstSelection => 'Selection 1';

  @override
  String get comparisonSecondSelection => 'Selection 2';

  @override
  String get comparisonNeedTwoPhotos => 'Add at least 2 photos to compare.';

  @override
  String get comparisonPhotoSwipeHint =>
      'Swipe thumbnails to view more, tap to open full screen.';

  @override
  String get photoUploadCommentTitle => 'Photo upload comment';

  @override
  String get comparisonTargetLabel => 'Compare with';

  @override
  String get comparisonTargetPrevious => 'Previous photo';

  @override
  String get comparisonTarget1Week => '1 week';

  @override
  String get comparisonTarget2Weeks => '2 weeks';

  @override
  String get comparisonTarget1Month => '1 month';

  @override
  String get comparisonTargetCustomDate => 'Pick date';

  @override
  String get comparisonDatePickerHelp => 'Select comparison date';

  @override
  String get closeDialogAction => 'Close';

  @override
  String get photoDatePickerHelp => 'Select photo date';

  @override
  String get viewAllPhotoAction => 'View';

  @override
  String get photoUploadOptionsTitle => 'Photo upload options';

  @override
  String get photoCommentLabel => 'Photo comment (optional)';

  @override
  String get photoCommentHint => 'Write a short review for this photo...';

  @override
  String get photoCommentApplyAll =>
      'This comment will be applied to all selected photos.';

  @override
  String get deletePhotoComment => 'Delete photo comment';

  @override
  String deletePhotoCommentConfirm(String date) {
    return 'Delete uploaded photo comment on $date?';
  }

  @override
  String get photoCommentDeleted => 'Photo upload comment deleted.';

  @override
  String photoBatchImported(int count, String startDate) {
    return '$count photos saved on $startDate.';
  }

  @override
  String get testerModeTitle => 'Tester mode';

  @override
  String get testerModeDescription =>
      'Generate quick sample history so timeline/statistics can be tested instantly without waiting for day changes.';

  @override
  String get testerSeed14Days => 'Seed 14 days';

  @override
  String get testerSeed30Days => 'Seed 30 days';

  @override
  String testerSeedConfirm(int days) {
    return 'Generate sample data for last $days days for this activity?';
  }

  @override
  String testerSeedResult(int count) {
    return '$count sample entries added.';
  }

  @override
  String get progressPhotos => 'Progress photos';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String deletePhotoConfirm(String date) {
    return 'Delete progress photo on $date?';
  }

  @override
  String get photoDeleted => 'Photo deleted.';

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
  String get dataImmutableWarningTitle => 'Save confirmation';

  @override
  String get noteSaveWarningMessage =>
      'A note can only be saved once per date. After saving, it cannot be edited (only deleted). Continue?';

  @override
  String get photoSaveWarningMessage =>
      'Uploaded photos and upload comments cannot be edited after saving (only deleted). Continue?';

  @override
  String get overallCompletion => 'Overall completion';

  @override
  String get statsReportTitle => 'Detailed Report';

  @override
  String get statsReportComingSoon => 'Stats report coming soon...';

  @override
  String get last7DaysChart => 'Last 7 days';

  @override
  String get last28DaysHeatmap => 'Last 28 days heatmap';

  @override
  String get insightsTitle => 'Auto insights';

  @override
  String get insightBestTimeEmpty =>
      'Not enough data for best time insight yet.';

  @override
  String insightBestTimeValue(String time) {
    return 'Most consistent time: $time';
  }

  @override
  String get insightMostMissedEmpty => 'No frequently missed activity yet.';

  @override
  String insightMostMissedValue(String title, int count) {
    return 'Most missed: $title (${count}x)';
  }

  @override
  String insightTrendValue(String sign, String percent) {
    return 'Weekly trend: $sign$percent%';
  }

  @override
  String weeklyGoalProgressLabel(int completed, int goal) {
    return 'This week goal: $completed/$goal';
  }

  @override
  String get breakdownPerActivity => 'Per-activity breakdown';

  @override
  String get reminderSettings => 'Reminder settings';

  @override
  String get morningReminderTime => 'Morning reminder time';

  @override
  String get endOfDayReminderTime => 'End-of-day reminder time';

  @override
  String get testNotificationNow => 'Send test notification now';

  @override
  String get testNotificationSent => 'Test notification has been sent.';

  @override
  String get notificationHealthTitle => 'Notification health';

  @override
  String get healthStatusUnavailable => 'Device health status unavailable.';

  @override
  String get timezoneLabel => 'Active timezone';

  @override
  String get scheduleModeLabel => 'Scheduling mode';

  @override
  String get notificationsPermissionLabel => 'Notification permission';

  @override
  String get exactAlarmLabel => 'Exact alarm';

  @override
  String get batteryOptimizationLabel => 'Ignoring battery optimization';

  @override
  String get statusOn => 'On';

  @override
  String get statusOff => 'Off';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get openNotificationSettings => 'Open notification settings';

  @override
  String get openExactAlarmSettings => 'Open exact alarm settings';

  @override
  String get openBatterySettings => 'Open battery settings';

  @override
  String get openAutoStartSettings => 'Open auto-start settings';

  @override
  String get refreshHealthStatus => 'Refresh status';

  @override
  String get openedNotificationSettings => 'Opening notification settings.';

  @override
  String get openedExactAlarmSettings => 'Opening exact alarm settings.';

  @override
  String get openedBatterySettings => 'Opening battery settings.';

  @override
  String get openedAutoStartSettings => 'Opening auto-start / app settings.';

  @override
  String get cannotOpenSettings => 'Cannot open settings on this device.';

  @override
  String get backupRestoreTitle => 'Backup & restore';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get chooseBackupFile => 'Choose backup file';

  @override
  String get noBackupFilesFound => 'No backup files found yet.';

  @override
  String get importBackupConfirm =>
      'Import will overwrite current data. Continue?';

  @override
  String get backupShareText => 'Reminder Schedule backup';

  @override
  String backupExported(String path) {
    return 'Backup exported: $path';
  }

  @override
  String get backupImported => 'Backup imported successfully.';

  @override
  String get language => 'Language';

  @override
  String get languageId => 'Bahasa Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String get addRecurringActivity => 'Recurring activity';

  @override
  String get addRecurringActivitySubtitle => 'Daily/weekly schedule';

  @override
  String get addOneTimeReminder => 'Specific schedule';

  @override
  String get addOneTimeReminderSubtitle => 'One-time date and time reminder';

  @override
  String get oneTimeRemindersSection => 'Specific schedules';

  @override
  String get oneTimeRemindersEmpty => 'No specific schedules yet.';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get createOneTimeReminder => 'Create specific schedule';

  @override
  String get editOneTimeReminder => 'Edit specific schedule';

  @override
  String get oneTimeReminderDetail => 'Specific schedule detail';

  @override
  String get oneTimeReminderNotFound => 'Specific schedule not found.';

  @override
  String get deleteOneTimeReminder => 'Delete specific schedule';

  @override
  String deleteOneTimeReminderConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get oneTimeTitleLabel => 'Reminder title';

  @override
  String get oneTimeTitleHint => 'Example: Pay electricity bill';

  @override
  String get oneTimeDateLabel => 'Date';

  @override
  String get oneTimeTimeLabel => 'Time';

  @override
  String get oneTimeValidationMessage => 'Please enter reminder title.';

  @override
  String get oneTimeStatusDone => 'Done';

  @override
  String get oneTimeStatusPending => 'Pending';

  @override
  String get oneTimeStatusMissed => 'Schedule missed';

  @override
  String get oneTimeMarkDone => 'Mark as done';

  @override
  String get oneTimeDoneSubtitle => 'This schedule is completed.';

  @override
  String get oneTimePendingSubtitle => 'Mark this when you complete it.';
}
