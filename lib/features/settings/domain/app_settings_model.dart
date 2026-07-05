import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';

class AppSettingsModel {
  const AppSettingsModel({
    required this.morningReminderMinutes,
    required this.endOfDayReminderMinutes,
    required this.localeCode,
    this.notificationsEnabled = true,
    this.profileName,
    this.extraActivitiesNote,
    this.profileAvatarPath,
    this.weeklyRoutine = kDefaultWeeklyRoutine,
    this.wakeUpMinutes,
    this.sleepMinutes,
    this.usualBreakStartMinutes,
    this.usualBreakEndMinutes,
  });

  final int morningReminderMinutes;
  final int endOfDayReminderMinutes;
  final String localeCode;
  final bool notificationsEnabled;
  final String? profileName;
  final String? extraActivitiesNote;
  final String? profileAvatarPath;
  final List<WeeklyRoutineDayProfile> weeklyRoutine;
  final int? wakeUpMinutes;
  final int? sleepMinutes;
  final int? usualBreakStartMinutes;
  final int? usualBreakEndMinutes;

  AppSettingsModel copyWith({
    int? morningReminderMinutes,
    int? endOfDayReminderMinutes,
    String? localeCode,
    bool? notificationsEnabled,
    String? profileName,
    bool clearProfileName = false,
    String? extraActivitiesNote,
    bool clearExtraActivitiesNote = false,
    String? profileAvatarPath,
    bool clearProfileAvatarPath = false,
    List<WeeklyRoutineDayProfile>? weeklyRoutine,
    int? wakeUpMinutes,
    bool clearWakeUpMinutes = false,
    int? sleepMinutes,
    bool clearSleepMinutes = false,
    int? usualBreakStartMinutes,
    bool clearUsualBreakStartMinutes = false,
    int? usualBreakEndMinutes,
    bool clearUsualBreakEndMinutes = false,
  }) {
    return AppSettingsModel(
      morningReminderMinutes:
          morningReminderMinutes ?? this.morningReminderMinutes,
      endOfDayReminderMinutes:
          endOfDayReminderMinutes ?? this.endOfDayReminderMinutes,
      localeCode: localeCode ?? this.localeCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      profileName: clearProfileName ? null : (profileName ?? this.profileName),
      extraActivitiesNote: clearExtraActivitiesNote
          ? null
          : (extraActivitiesNote ?? this.extraActivitiesNote),
      profileAvatarPath: clearProfileAvatarPath
          ? null
          : (profileAvatarPath ?? this.profileAvatarPath),
      weeklyRoutine: normalizeWeeklyRoutine(weeklyRoutine ?? this.weeklyRoutine),
      wakeUpMinutes: clearWakeUpMinutes ? null : (wakeUpMinutes ?? this.wakeUpMinutes),
      sleepMinutes: clearSleepMinutes ? null : (sleepMinutes ?? this.sleepMinutes),
      usualBreakStartMinutes: clearUsualBreakStartMinutes
          ? null
          : (usualBreakStartMinutes ?? this.usualBreakStartMinutes),
      usualBreakEndMinutes: clearUsualBreakEndMinutes
          ? null
          : (usualBreakEndMinutes ?? this.usualBreakEndMinutes),
    );
  }

  List<WeeklyRoutineDayProfile> get normalizedWeeklyRoutine =>
      normalizeWeeklyRoutine(weeklyRoutine);

  WeeklyRoutineDayProfile routineForWeekday(int weekday) {
    return normalizedWeeklyRoutine.firstWhere(
      (WeeklyRoutineDayProfile item) => item.weekday == weekday,
      orElse: () => WeeklyRoutineDayProfile(weekday: weekday),
    );
  }

  bool get hasConfiguredWeeklyRoutine => normalizedWeeklyRoutine.any(
    (WeeklyRoutineDayProfile item) =>
        item.kind != WeeklyRoutineDayKind.unspecified,
  );

  bool get hasExtraActivitiesNote =>
      (extraActivitiesNote ?? '').trim().isNotEmpty;

  bool get hasConfiguredTimeHabits =>
      wakeUpMinutes != null ||
      sleepMinutes != null ||
      usualBreakStartMinutes != null ||
      usualBreakEndMinutes != null;

  bool get needsInitialUserSetup {
    final String trimmedName = (profileName ?? '').trim();
    return trimmedName.isEmpty;
  }
}
