import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Reminder Schedule'**
  String get appName;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @homeSegmentActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get homeSegmentActivities;

  /// No description provided for @homeSegmentSchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get homeSegmentSchedules;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @todayActivities.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activities'**
  String get todayActivities;

  /// No description provided for @emptyActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities yet. Add one to get started.'**
  String get emptyActivities;

  /// No description provided for @photoTracking.
  ///
  /// In en, this message translates to:
  /// **'Photo tracking on'**
  String get photoTracking;

  /// No description provided for @notScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled today'**
  String get notScheduledToday;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'{completedCount}/{taskCount} tasks completed today'**
  String todaySummary(int taskCount, int completedCount);

  /// No description provided for @globalStreakValue.
  ///
  /// In en, this message translates to:
  /// **'Global streak: {days} days'**
  String globalStreakValue(int days);

  /// No description provided for @createActivity.
  ///
  /// In en, this message translates to:
  /// **'Create activity'**
  String get createActivity;

  /// No description provided for @editActivity.
  ///
  /// In en, this message translates to:
  /// **'Edit activity'**
  String get editActivity;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity title'**
  String get activityTitle;

  /// No description provided for @activityTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Morning Workout'**
  String get activityTitleHint;

  /// No description provided for @selectedDays.
  ///
  /// In en, this message translates to:
  /// **'Selected days'**
  String get selectedDays;

  /// No description provided for @scheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled time'**
  String get scheduledTime;

  /// No description provided for @weeklyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get weeklyGoalLabel;

  /// No description provided for @weeklyGoalHint.
  ///
  /// In en, this message translates to:
  /// **'How many completions per week?'**
  String get weeklyGoalHint;

  /// No description provided for @weeklyGoalValue.
  ///
  /// In en, this message translates to:
  /// **'{count} times / week'**
  String weeklyGoalValue(int count);

  /// No description provided for @preReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre-start reminder'**
  String get preReminderLabel;

  /// No description provided for @preReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Select reminder offset'**
  String get preReminderHint;

  /// No description provided for @preReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get preReminderOff;

  /// No description provided for @preReminderMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before start'**
  String preReminderMinutesValue(int minutes);

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @enableMorningReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable morning reminder'**
  String get enableMorningReminder;

  /// No description provided for @enableEndOfDayReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable end-of-day reminder'**
  String get enableEndOfDayReminder;

  /// No description provided for @enablePhotoProgress.
  ///
  /// In en, this message translates to:
  /// **'Enable photo progress'**
  String get enablePhotoProgress;

  /// No description provided for @formValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please fill title and choose at least one day.'**
  String get formValidationMessage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @activityDetail.
  ///
  /// In en, this message translates to:
  /// **'Activity detail'**
  String get activityDetail;

  /// No description provided for @activityNotFound.
  ///
  /// In en, this message translates to:
  /// **'Activity not found.'**
  String get activityNotFound;

  /// No description provided for @deleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete activity'**
  String get deleteActivity;

  /// No description provided for @deleteActivityConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteActivityConfirm(String title);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRate;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly progress'**
  String get weeklyProgress;

  /// No description provided for @completeToday.
  ///
  /// In en, this message translates to:
  /// **'Complete today'**
  String get completeToday;

  /// No description provided for @oneTapComplete.
  ///
  /// In en, this message translates to:
  /// **'One tap completion'**
  String get oneTapComplete;

  /// No description provided for @subActivitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-activities'**
  String get subActivitiesLabel;

  /// No description provided for @subActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Leg day'**
  String get subActivityHint;

  /// No description provided for @addSubActivity.
  ///
  /// In en, this message translates to:
  /// **'Add sub'**
  String get addSubActivity;

  /// No description provided for @subActivitiesProgress.
  ///
  /// In en, this message translates to:
  /// **'Sub completed: {completed}/{total}'**
  String subActivitiesProgress(int completed, int total);

  /// No description provided for @checklistConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist confirmation'**
  String get checklistConfirmTitle;

  /// No description provided for @checklistConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure this status is correct and should be changed?'**
  String get checklistConfirmMessage;

  /// No description provided for @checklistConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, change'**
  String get checklistConfirmAction;

  /// No description provided for @journalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal notes'**
  String get journalNotesTitle;

  /// No description provided for @journalAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get journalAddNote;

  /// No description provided for @journalEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get journalEditNote;

  /// No description provided for @journalDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get journalDeleteNote;

  /// No description provided for @journalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete note on {date}?'**
  String journalDeleteConfirm(String date);

  /// No description provided for @journalNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get journalNoteSaved;

  /// No description provided for @journalNoteLockedDeleteFirst.
  ///
  /// In en, this message translates to:
  /// **'A note already exists for that date. Delete it first if you want to replace it.'**
  String get journalNoteLockedDeleteFirst;

  /// No description provided for @journalNoteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted.'**
  String get journalNoteDeleted;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get journalEmpty;

  /// No description provided for @journalNotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved notes'**
  String journalNotesCount(int count);

  /// No description provided for @noteDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Note date'**
  String get noteDateLabel;

  /// No description provided for @noteInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write your note...'**
  String get noteInputHint;

  /// No description provided for @comparisonTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress timeline'**
  String get comparisonTimelineTitle;

  /// No description provided for @comparisonFilter7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get comparisonFilter7d;

  /// No description provided for @comparisonFilter30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get comparisonFilter30d;

  /// No description provided for @comparisonFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get comparisonFilterAll;

  /// No description provided for @comparisonEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data available for comparison yet.'**
  String get comparisonEmpty;

  /// No description provided for @comparisonTapPhotoCompare.
  ///
  /// In en, this message translates to:
  /// **'Tap photo to pick 2 photos for comparison'**
  String get comparisonTapPhotoCompare;

  /// No description provided for @comparisonNoPreviousPhoto.
  ///
  /// In en, this message translates to:
  /// **'No previous photo to compare yet.'**
  String get comparisonNoPreviousPhoto;

  /// No description provided for @comparisonPhotoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo comparison'**
  String get comparisonPhotoDialogTitle;

  /// No description provided for @comparisonCurrentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Current photo'**
  String get comparisonCurrentPhoto;

  /// No description provided for @comparisonPreviousPhoto.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get comparisonPreviousPhoto;

  /// No description provided for @comparisonFirstSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection 1'**
  String get comparisonFirstSelection;

  /// No description provided for @comparisonSecondSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection 2'**
  String get comparisonSecondSelection;

  /// No description provided for @comparisonNeedTwoPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos to compare.'**
  String get comparisonNeedTwoPhotos;

  /// No description provided for @comparisonPhotoSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe thumbnails to view more, tap to open full screen.'**
  String get comparisonPhotoSwipeHint;

  /// No description provided for @photoUploadCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload comment'**
  String get photoUploadCommentTitle;

  /// No description provided for @comparisonTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Compare with'**
  String get comparisonTargetLabel;

  /// No description provided for @comparisonTargetPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get comparisonTargetPrevious;

  /// No description provided for @comparisonTarget1Week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get comparisonTarget1Week;

  /// No description provided for @comparisonTarget2Weeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get comparisonTarget2Weeks;

  /// No description provided for @comparisonTarget1Month.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get comparisonTarget1Month;

  /// No description provided for @comparisonTargetCustomDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get comparisonTargetCustomDate;

  /// No description provided for @comparisonDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select comparison date'**
  String get comparisonDatePickerHelp;

  /// No description provided for @closeDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeDialogAction;

  /// No description provided for @photoDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select photo date'**
  String get photoDatePickerHelp;

  /// No description provided for @viewAllPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAllPhotoAction;

  /// No description provided for @photoUploadOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload options'**
  String get photoUploadOptionsTitle;

  /// No description provided for @photoCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo comment (optional)'**
  String get photoCommentLabel;

  /// No description provided for @photoCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short review for this photo...'**
  String get photoCommentHint;

  /// No description provided for @photoCommentApplyAll.
  ///
  /// In en, this message translates to:
  /// **'This comment will be applied to all selected photos.'**
  String get photoCommentApplyAll;

  /// No description provided for @deletePhotoComment.
  ///
  /// In en, this message translates to:
  /// **'Delete photo comment'**
  String get deletePhotoComment;

  /// No description provided for @deletePhotoCommentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete uploaded photo comment on {date}?'**
  String deletePhotoCommentConfirm(String date);

  /// No description provided for @photoCommentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo upload comment deleted.'**
  String get photoCommentDeleted;

  /// No description provided for @photoBatchImported.
  ///
  /// In en, this message translates to:
  /// **'{count} photos saved on {startDate}.'**
  String photoBatchImported(int count, String startDate);

  /// No description provided for @testerModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tester mode'**
  String get testerModeTitle;

  /// No description provided for @testerModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate quick sample history so timeline/statistics can be tested instantly without waiting for day changes.'**
  String get testerModeDescription;

  /// No description provided for @testerSeed14Days.
  ///
  /// In en, this message translates to:
  /// **'Seed 14 days'**
  String get testerSeed14Days;

  /// No description provided for @testerSeed30Days.
  ///
  /// In en, this message translates to:
  /// **'Seed 30 days'**
  String get testerSeed30Days;

  /// No description provided for @testerSeedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Generate sample data for last {days} days for this activity?'**
  String testerSeedConfirm(int days);

  /// No description provided for @testerSeedResult.
  ///
  /// In en, this message translates to:
  /// **'{count} sample entries added.'**
  String testerSeedResult(int count);

  /// No description provided for @progressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Progress photos'**
  String get progressPhotos;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete progress photo on {date}?'**
  String deletePhotoConfirm(String date);

  /// No description provided for @photoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted.'**
  String get photoDeleted;

  /// No description provided for @historyLog.
  ///
  /// In en, this message translates to:
  /// **'History log'**
  String get historyLog;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistoryYet;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// No description provided for @noPhotoYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get noPhotoYet;

  /// No description provided for @dataImmutableWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Save confirmation'**
  String get dataImmutableWarningTitle;

  /// No description provided for @noteSaveWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'A note can only be saved once per date. After saving, it cannot be edited (only deleted). Continue?'**
  String get noteSaveWarningMessage;

  /// No description provided for @photoSaveWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Uploaded photos and upload comments cannot be edited after saving (only deleted). Continue?'**
  String get photoSaveWarningMessage;

  /// No description provided for @overallCompletion.
  ///
  /// In en, this message translates to:
  /// **'Overall completion'**
  String get overallCompletion;

  /// No description provided for @last7DaysChart.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7DaysChart;

  /// No description provided for @last28DaysHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Last 28 days heatmap'**
  String get last28DaysHeatmap;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto insights'**
  String get insightsTitle;

  /// No description provided for @insightBestTimeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for best time insight yet.'**
  String get insightBestTimeEmpty;

  /// No description provided for @insightBestTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Most consistent time: {time}'**
  String insightBestTimeValue(String time);

  /// No description provided for @insightMostMissedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No frequently missed activity yet.'**
  String get insightMostMissedEmpty;

  /// No description provided for @insightMostMissedValue.
  ///
  /// In en, this message translates to:
  /// **'Most missed: {title} ({count}x)'**
  String insightMostMissedValue(String title, int count);

  /// No description provided for @insightTrendValue.
  ///
  /// In en, this message translates to:
  /// **'Weekly trend: {sign}{percent}%'**
  String insightTrendValue(String sign, String percent);

  /// No description provided for @weeklyGoalProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'This week goal: {completed}/{goal}'**
  String weeklyGoalProgressLabel(int completed, int goal);

  /// No description provided for @breakdownPerActivity.
  ///
  /// In en, this message translates to:
  /// **'Per-activity breakdown'**
  String get breakdownPerActivity;

  /// No description provided for @reminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings'**
  String get reminderSettings;

  /// No description provided for @morningReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Morning reminder time'**
  String get morningReminderTime;

  /// No description provided for @endOfDayReminderTime.
  ///
  /// In en, this message translates to:
  /// **'End-of-day reminder time'**
  String get endOfDayReminderTime;

  /// No description provided for @testNotificationNow.
  ///
  /// In en, this message translates to:
  /// **'Send test notification now'**
  String get testNotificationNow;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification has been sent.'**
  String get testNotificationSent;

  /// No description provided for @notificationHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification health'**
  String get notificationHealthTitle;

  /// No description provided for @healthStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device health status unavailable.'**
  String get healthStatusUnavailable;

  /// No description provided for @timezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Active timezone'**
  String get timezoneLabel;

  /// No description provided for @scheduleModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduling mode'**
  String get scheduleModeLabel;

  /// No description provided for @notificationsPermissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get notificationsPermissionLabel;

  /// No description provided for @exactAlarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm'**
  String get exactAlarmLabel;

  /// No description provided for @batteryOptimizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Ignoring battery optimization'**
  String get batteryOptimizationLabel;

  /// No description provided for @statusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get statusOn;

  /// No description provided for @statusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get statusOff;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @openNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get openNotificationSettings;

  /// No description provided for @openExactAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Open exact alarm settings'**
  String get openExactAlarmSettings;

  /// No description provided for @openBatterySettings.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get openBatterySettings;

  /// No description provided for @openAutoStartSettings.
  ///
  /// In en, this message translates to:
  /// **'Open auto-start settings'**
  String get openAutoStartSettings;

  /// No description provided for @refreshHealthStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshHealthStatus;

  /// No description provided for @openedNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Opening notification settings.'**
  String get openedNotificationSettings;

  /// No description provided for @openedExactAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Opening exact alarm settings.'**
  String get openedExactAlarmSettings;

  /// No description provided for @openedBatterySettings.
  ///
  /// In en, this message translates to:
  /// **'Opening battery settings.'**
  String get openedBatterySettings;

  /// No description provided for @openedAutoStartSettings.
  ///
  /// In en, this message translates to:
  /// **'Opening auto-start / app settings.'**
  String get openedAutoStartSettings;

  /// No description provided for @cannotOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Cannot open settings on this device.'**
  String get cannotOpenSettings;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupRestoreTitle;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @chooseBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get chooseBackupFile;

  /// No description provided for @noBackupFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No backup files found yet.'**
  String get noBackupFilesFound;

  /// No description provided for @importBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import will overwrite current data. Continue?'**
  String get importBackupConfirm;

  /// No description provided for @backupShareText.
  ///
  /// In en, this message translates to:
  /// **'Reminder Schedule backup'**
  String get backupShareText;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported: {path}'**
  String backupExported(String path);

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully.'**
  String get backupImported;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageId.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageId;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @addRecurringActivity.
  ///
  /// In en, this message translates to:
  /// **'Recurring activity'**
  String get addRecurringActivity;

  /// No description provided for @addRecurringActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily/weekly schedule'**
  String get addRecurringActivitySubtitle;

  /// No description provided for @addOneTimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Specific schedule'**
  String get addOneTimeReminder;

  /// No description provided for @addOneTimeReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time date and time reminder'**
  String get addOneTimeReminderSubtitle;

  /// No description provided for @oneTimeRemindersSection.
  ///
  /// In en, this message translates to:
  /// **'Specific schedules'**
  String get oneTimeRemindersSection;

  /// No description provided for @oneTimeRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No specific schedules yet.'**
  String get oneTimeRemindersEmpty;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @createOneTimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Create specific schedule'**
  String get createOneTimeReminder;

  /// No description provided for @editOneTimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit specific schedule'**
  String get editOneTimeReminder;

  /// No description provided for @oneTimeReminderDetail.
  ///
  /// In en, this message translates to:
  /// **'Specific schedule detail'**
  String get oneTimeReminderDetail;

  /// No description provided for @oneTimeReminderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Specific schedule not found.'**
  String get oneTimeReminderNotFound;

  /// No description provided for @deleteOneTimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete specific schedule'**
  String get deleteOneTimeReminder;

  /// No description provided for @deleteOneTimeReminderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteOneTimeReminderConfirm(String title);

  /// No description provided for @oneTimeTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder title'**
  String get oneTimeTitleLabel;

  /// No description provided for @oneTimeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Pay electricity bill'**
  String get oneTimeTitleHint;

  /// No description provided for @oneTimeDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get oneTimeDateLabel;

  /// No description provided for @oneTimeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get oneTimeTimeLabel;

  /// No description provided for @oneTimeValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter reminder title.'**
  String get oneTimeValidationMessage;

  /// No description provided for @oneTimeStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get oneTimeStatusDone;

  /// No description provided for @oneTimeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get oneTimeStatusPending;

  /// No description provided for @oneTimeStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Schedule missed'**
  String get oneTimeStatusMissed;

  /// No description provided for @oneTimeMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get oneTimeMarkDone;

  /// No description provided for @oneTimeDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This schedule is completed.'**
  String get oneTimeDoneSubtitle;

  /// No description provided for @oneTimePendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark this when you complete it.'**
  String get oneTimePendingSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
