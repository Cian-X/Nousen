import 'dart:math' as math;

import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/domain/activity_daily_progress_status.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

enum HomeAiActionType { addActivity, openStats, none }
enum HomeAiBriefSource { local, ml }

class HomeAiBrief {
  const HomeAiBrief({
    required this.headline,
    required this.insight,
    required this.suggestion,
    required this.actionType,
    this.source = HomeAiBriefSource.local,
  });

  final String headline;
  final String insight;
  final String suggestion;
  final HomeAiActionType actionType;
  final HomeAiBriefSource source;
}

class HomeAiBriefEngine {
  const HomeAiBriefEngine() : _advisor = const SmartActivityAdvisor();

  final SmartActivityAdvisor _advisor;

  HomeAiBrief build({
    required DateTime now,
    required DateTime selectedDate,
    required bool selectedIsToday,
    required String localeCode,
    required List<ActivityModel> allActivities,
    required List<ActivityModel> selectedActivities,
    required Map<String, ProgressEntryModel> selectedProgressByActivity,
    required List<ProgressEntryModel> allProgressEntries,
  }) {
    final _BehaviorProfile profile = _buildBehaviorProfile(
      now: now,
      localeCode: localeCode,
      allActivities: allActivities,
      allProgressEntries: allProgressEntries,
    );
    final DateTime today = dateOnly(now);
    final bool selectedIsPast = dateOnly(selectedDate).isBefore(today);
    final bool selectedIsFuture = dateOnly(selectedDate).isAfter(today);
    final List<ActivityModel> activeSelectedActivities = selectedActivities
        .where((ActivityModel activity) => _isActivityActiveOnDate(activity, selectedDate))
        .toList(growable: false);
    final _SelectedDaySnapshot snapshot = _buildSelectedDaySnapshot(
      now: now,
      selectedDate: selectedDate,
      activeActivities: activeSelectedActivities,
      selectedProgressByActivity: selectedProgressByActivity,
    );
    final ActivityModel? nextActivity = _resolveNextActivity(
      now: now,
      selectedDate: selectedDate,
      selectedIsToday: selectedIsToday,
      selectedActivities: activeSelectedActivities,
      selectedProgressByActivity: selectedProgressByActivity,
    );

    if (snapshot.scheduledCount == 0) {
      return _buildEmptyBrief(
        localeCode: localeCode,
        selectedIsToday: selectedIsToday,
        selectedDate: selectedDate,
        selectedIsPast: selectedIsPast,
        selectedIsFuture: selectedIsFuture,
        profile: profile,
      );
    }

    if (selectedIsPast) {
      return _buildPastBrief(
        localeCode: localeCode,
        selectedDate: selectedDate,
        snapshot: snapshot,
        profile: profile,
      );
    }

    if (selectedIsFuture) {
      return _buildUpcomingBrief(
        localeCode: localeCode,
        selectedDate: selectedDate,
        nextActivity: activeSelectedActivities.first,
        snapshot: snapshot,
        profile: profile,
      );
    }

    if (snapshot.doneCount >= snapshot.scheduledCount && snapshot.scheduledCount > 0) {
      return _buildCompletedBrief(
        localeCode: localeCode,
        snapshot: snapshot,
        profile: profile,
      );
    }

    if (nextActivity != null) {
      final int nextMinutes = nextActivity.timeMinutes;
      final DateTime scheduledAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        nextMinutes ~/ 60,
        nextMinutes % 60,
      );
      final int minutesUntil = scheduledAt.difference(now).inMinutes;
      if (minutesUntil >= -20 && minutesUntil <= 90) {
        return _buildFocusBrief(
          localeCode: localeCode,
          nextActivity: nextActivity,
          minutesUntil: minutesUntil,
          snapshot: snapshot,
          profile: profile,
        );
      }
    }

    if (snapshot.scheduledCount <= 2 || snapshot.remainingCount <= 1) {
      return _buildLightBrief(
        localeCode: localeCode,
        snapshot: snapshot,
        profile: profile,
        nextActivity: nextActivity,
      );
    }

    if (snapshot.scheduledCount >= 4 ||
        snapshot.remainingCount >= 3 ||
        snapshot.missedCount > 0) {
      return _buildBusyBrief(
        localeCode: localeCode,
        snapshot: snapshot,
        profile: profile,
        nextActivity: nextActivity,
      );
    }

    return _buildSteadyBrief(
      localeCode: localeCode,
      snapshot: snapshot,
      profile: profile,
      nextActivity: nextActivity,
    );
  }

  bool _isActivityActiveOnDate(ActivityModel activity, DateTime selectedDate) {
    final DateTime scheduleActiveFrom = dateOnly(
      activity.scheduleUpdatedAt ?? activity.createdAt,
    );
    return !dateOnly(selectedDate).isBefore(scheduleActiveFrom);
  }

  _SelectedDaySnapshot _buildSelectedDaySnapshot({
    required DateTime now,
    required DateTime selectedDate,
    required List<ActivityModel> activeActivities,
    required Map<String, ProgressEntryModel> selectedProgressByActivity,
  }) {
    int doneCount = 0;
    int partialCount = 0;
    int missedCount = 0;
    int skippedCount = 0;
    int pendingCount = 0;
    final List<String> doneTitles = <String>[];
    final List<String> partialTitles = <String>[];
    final List<String> missedTitles = <String>[];
    final List<String> skippedTitles = <String>[];
    final List<String> pendingTitles = <String>[];

    for (final ActivityModel activity in activeActivities) {
      final ProgressEntryModel? progress = selectedProgressByActivity[activity.id];
      final ActivityDailyProgressStatus status = resolveActivityDailyProgressStatus(
        scheduledDate: selectedDate,
        today: now,
        scheduleUpdatedAt: activity.scheduleUpdatedAt ?? activity.createdAt,
        subActivities: activity.subActivities,
        scheduledTimeMinutes: activity.timeMinutes,
        entry: progress,
      );

      switch (status) {
        case ActivityDailyProgressStatus.done:
          doneCount += 1;
          doneTitles.add(activity.title);
        case ActivityDailyProgressStatus.partial:
          partialCount += 1;
          partialTitles.add(activity.title);
        case ActivityDailyProgressStatus.missed:
          missedCount += 1;
          missedTitles.add(activity.title);
        case ActivityDailyProgressStatus.skipped:
          skippedCount += 1;
          skippedTitles.add(activity.title);
        case ActivityDailyProgressStatus.future:
          pendingCount += 1;
          pendingTitles.add(activity.title);
      }
    }

    return _SelectedDaySnapshot(
      scheduledCount: activeActivities.length,
      doneCount: doneCount,
      partialCount: partialCount,
      missedCount: missedCount,
      skippedCount: skippedCount,
      pendingCount: pendingCount,
      firstActivity: activeActivities.isEmpty ? null : activeActivities.first,
      lastActivity: activeActivities.isEmpty ? null : activeActivities.last,
      doneTitles: doneTitles,
      partialTitles: partialTitles,
      missedTitles: missedTitles,
      skippedTitles: skippedTitles,
      pendingTitles: pendingTitles,
    );
  }

  _BehaviorProfile _buildBehaviorProfile({
    required DateTime now,
    required String localeCode,
    required List<ActivityModel> allActivities,
    required List<ProgressEntryModel> allProgressEntries,
  }) {
    if (allActivities.isEmpty || allProgressEntries.isEmpty) {
      return const _BehaviorProfile();
    }

    final DateTime today = dateOnly(now);
    final DateTime windowStart = today.subtract(const Duration(days: 29));
    final Map<String, ProgressEntryModel> progressByKey =
        <String, ProgressEntryModel>{
          for (final ProgressEntryModel entry in allProgressEntries)
            '${entry.activityId}|${entry.dateKey}': entry,
        };

    final Map<int, int> scheduledByWeekday = <int, int>{};
    final Map<int, int> completedByWeekday = <int, int>{};
    final Map<String, int> completedByTimeSegment = <String, int>{};
    final Map<String, int> completedByFamily = <String, int>{};
    final Map<String, int> missedByActivityTitle = <String, int>{};

    DateTime cursor = windowStart;
    while (!cursor.isAfter(today)) {
      for (final ActivityModel activity in allActivities) {
        if (cursor.isBefore(dateOnly(activity.createdAt)) ||
            !activity.selectedDays.contains(cursor.weekday)) {
          continue;
        }

        final String key = '${activity.id}|${dateKeyFromDate(cursor)}';
        final ProgressEntryModel? entry = progressByKey[key];
        if (entry?.isSkipped == true) {
          continue;
        }

        scheduledByWeekday[cursor.weekday] =
            (scheduledByWeekday[cursor.weekday] ?? 0) + 1;

        if (entry?.isCompleted == true) {
          completedByWeekday[cursor.weekday] =
              (completedByWeekday[cursor.weekday] ?? 0) + 1;
          final String segmentKey = _timeSegmentKey(activity.timeMinutes);
          completedByTimeSegment[segmentKey] =
              (completedByTimeSegment[segmentKey] ?? 0) + 1;
          final String familyLabel = _familyLabelForActivity(
            activity.title,
            localeCode: localeCode,
          );
          completedByFamily[familyLabel] =
              (completedByFamily[familyLabel] ?? 0) + 1;
        } else {
          missedByActivityTitle[activity.title] =
              (missedByActivityTitle[activity.title] ?? 0) + 1;
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    int? bestWeekday;
    double bestRate = -1;
    for (final MapEntry<int, int> item in scheduledByWeekday.entries) {
      if (item.value <= 0) {
        continue;
      }
      final double rate = (completedByWeekday[item.key] ?? 0) / item.value;
      if (rate > bestRate) {
        bestRate = rate;
        bestWeekday = item.key;
      }
    }

    final String? bestTimeSegmentKey = _mostFrequentKey(completedByTimeSegment);
    final String? bestFamilyLabel = _mostFrequentKey(completedByFamily);
    final String? mostMissedActivityTitle = _mostFrequentKey(
      missedByActivityTitle,
    );

    return _BehaviorProfile(
      hasHistory: scheduledByWeekday.isNotEmpty,
      bestWeekday: bestWeekday,
      bestWeekdayLabel: bestWeekday == null
          ? null
          : _weekdayFullLabel(bestWeekday, localeCode),
      bestTimeSegmentKey: bestTimeSegmentKey,
      bestTimeSegmentLabel: bestTimeSegmentKey == null
          ? null
          : _timeSegmentLabel(bestTimeSegmentKey, localeCode),
      bestFamilyLabel: bestFamilyLabel,
      mostMissedActivityTitle: mostMissedActivityTitle,
    );
  }

  String _familyLabelForActivity(String title, {required String localeCode}) {
    final SmartActivitySuggestion? suggestion = _advisor.analyze(
      title,
      localeCode: localeCode,
    );
    return suggestion?.familyLabel ??
        (localeCode == 'id' ? 'Rutinitas' : 'Routine');
  }

  String? _mostFrequentKey(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
    }
    String? bestKey;
    int bestCount = -1;
    for (final MapEntry<String, int> item in counts.entries) {
      if (item.value > bestCount) {
        bestKey = item.key;
        bestCount = item.value;
      }
    }
    return bestKey;
  }

  String _timeSegmentKey(int timeMinutes) {
    final int hour = (timeMinutes ~/ 60) % 24;
    if (hour < 11) {
      return 'morning';
    }
    if (hour < 15) {
      return 'midday';
    }
    if (hour < 19) {
      return 'evening';
    }
    return 'night';
  }

  String _timeSegmentLabel(String segmentKey, String localeCode) {
    switch (segmentKey) {
      case 'morning':
        return localeCode == 'id' ? 'pagi hari' : 'the morning';
      case 'midday':
        return localeCode == 'id' ? 'siang hari' : 'midday';
      case 'evening':
        return localeCode == 'id' ? 'sore hari' : 'late afternoon';
      case 'night':
      default:
        return localeCode == 'id' ? 'malam hari' : 'the evening';
    }
  }

  String _weekdayFullLabel(int weekday, String localeCode) {
    const List<String> id = <String>[
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const List<String> en = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final List<String> labels = localeCode == 'id' ? id : en;
    if (weekday < 1 || weekday > 7) {
      return labels.first;
    }
    return labels[weekday - 1];
  }

  ActivityModel? _resolveNextActivity({
    required DateTime now,
    required DateTime selectedDate,
    required bool selectedIsToday,
    required List<ActivityModel> selectedActivities,
    required Map<String, ProgressEntryModel> selectedProgressByActivity,
  }) {
    if (selectedActivities.isEmpty) {
      return null;
    }

    if (!selectedIsToday) {
      return selectedActivities.first;
    }

    final int nowMinutes = (now.hour * 60) + now.minute;
    ActivityModel? fallbackUnfinished;

    for (final ActivityModel activity in selectedActivities) {
      final ProgressEntryModel? progress = selectedProgressByActivity[activity.id];
      if (progress?.isCompleted == true || progress?.isSkipped == true) {
        continue;
      }
      fallbackUnfinished ??= activity;
      if (activity.timeMinutes >= nowMinutes) {
        return activity;
      }
    }

    return fallbackUnfinished;
  }

  HomeAiBrief _buildEmptyBrief({
    required String localeCode,
    required bool selectedIsToday,
    required DateTime selectedDate,
    required bool selectedIsPast,
    required bool selectedIsFuture,
    required _BehaviorProfile profile,
  }) {
    final String dayLabel = _weekdayFullLabel(
      selectedDate.weekday,
      localeCode,
    );
    final String headline = selectedIsToday
        ? (localeCode == 'id'
              ? 'Hari ini kosong'
              : 'No schedule for today')
        : (localeCode == 'id'
              ? '$dayLabel kosong'
              : 'No schedule for $dayLabel yet');

    final String insight = localeCode == 'id'
        ? _buildEmptyInsightId(
            selectedIsToday: selectedIsToday,
            selectedIsPast: selectedIsPast,
            selectedIsFuture: selectedIsFuture,
            dayLabel: dayLabel,
            profile: profile,
            selectedWeekday: selectedDate.weekday,
          )
        : _buildEmptyInsightEn(
            selectedIsToday: selectedIsToday,
            selectedIsPast: selectedIsPast,
            selectedIsFuture: selectedIsFuture,
            dayLabel: dayLabel,
            profile: profile,
            selectedWeekday: selectedDate.weekday,
          );

    return HomeAiBrief(
      headline: headline,
      insight: insight,
      suggestion: localeCode == 'id'
          ? 'Belum ada langkah berikutnya'
          : 'No next step yet',
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildUpcomingBrief({
    required String localeCode,
    required DateTime selectedDate,
    required ActivityModel nextActivity,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
  }) {
    final String dayLabel = _weekdayFullLabel(
      selectedDate.weekday,
      localeCode,
    );
    final String firstTime = formatMinutesAsTime(nextActivity.timeMinutes);
    final String insight = localeCode == 'id'
        ? _buildUpcomingInsightId(
            dayLabel: dayLabel,
            snapshot: snapshot,
            nextActivity: nextActivity,
            firstTime: firstTime,
            profile: profile,
            selectedWeekday: selectedDate.weekday,
          )
        : _buildUpcomingInsightEn(
            dayLabel: dayLabel,
            snapshot: snapshot,
            nextActivity: nextActivity,
            firstTime: firstTime,
            profile: profile,
            selectedWeekday: selectedDate.weekday,
          );

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? snapshot.scheduledCount == 1
                ? '$dayLabel punya 1 aktivitas'
                : '$dayLabel sudah punya ${snapshot.scheduledCount} aktivitas'
          : snapshot.scheduledCount == 1
          ? '$dayLabel has 1 activity'
          : '$dayLabel has ${snapshot.scheduledCount} activities',
      insight: insight,
      suggestion: _upcomingLabel(
        localeCode: localeCode,
        activity: nextActivity,
        selectedDate: selectedDate,
      ),
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildCompletedBrief({
    required String localeCode,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
  }) {
    final String insight = localeCode == 'id'
        ? _buildCompletedInsightId(snapshot: snapshot, profile: profile)
        : _buildCompletedInsightEn(snapshot: snapshot, profile: profile);

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? 'Hari ini selesai dengan rapi'
          : 'Today finished cleanly',
      insight: insight,
      suggestion: localeCode == 'id'
          ? 'Semua aktivitas sudah selesai'
          : 'All activities are finished',
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildPastBrief({
    required String localeCode,
    required DateTime selectedDate,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
  }) {
    final String dayLabel = _weekdayFullLabel(
      selectedDate.weekday,
      localeCode,
    );
    final String insight = localeCode == 'id'
        ? _buildPastInsight(
            dayLabel: dayLabel,
            snapshot: snapshot,
            profile: profile,
            selectedWeekday: selectedDate.weekday,
          )
        : _buildPastInsightEn(
            dayLabel: dayLabel,
            snapshot: snapshot,
            profile: profile,
            selectedWeekday: selectedDate.weekday,
          );

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? _pastHeadlineId(dayLabel, snapshot)
          : _pastHeadlineEn(dayLabel, snapshot),
      insight: insight,
      suggestion: localeCode == 'id'
          ? 'Hari itu sudah lewat'
          : 'That day has passed',
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildFocusBrief({
    required String localeCode,
    required ActivityModel nextActivity,
    required int minutesUntil,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
  }) {
    final String insight = localeCode == 'id'
        ? _buildTodayInsight(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
            focusMinutesUntil: minutesUntil,
          )
        : _buildTodayInsightEn(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
            focusMinutesUntil: minutesUntil,
          );

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? minutesUntil <= 0
                ? 'Saatnya ${nextActivity.title}'
                : '${nextActivity.title} jadi fokus berikutnya'
          : minutesUntil <= 0
          ? 'It is time for ${nextActivity.title}'
          : '${nextActivity.title} is up next',
      insight: insight,
      suggestion: _focusLabel(
        localeCode: localeCode,
        activity: nextActivity,
        minutesUntil: minutesUntil,
      ),
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildLightBrief({
    required String localeCode,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required ActivityModel? nextActivity,
  }) {
    final String insight = localeCode == 'id'
        ? _buildTodayInsight(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
          )
        : _buildTodayInsightEn(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
          );

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? _todayHeadlineId(snapshot)
          : _todayHeadlineEn(snapshot),
      insight: insight,
      suggestion: _nextLabel(
        localeCode: localeCode,
        activity: nextActivity,
      ),
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildBusyBrief({
    required String localeCode,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required ActivityModel? nextActivity,
  }) {
    final String insight = localeCode == 'id'
        ? _buildTodayInsight(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
          )
        : _buildTodayInsightEn(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
          );

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? _todayHeadlineId(snapshot)
          : _todayHeadlineEn(snapshot),
      insight: insight,
      suggestion: _nextLabel(
        localeCode: localeCode,
        activity: nextActivity,
      ),
      actionType: HomeAiActionType.none,
    );
  }

  HomeAiBrief _buildSteadyBrief({
    required String localeCode,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required ActivityModel? nextActivity,
  }) {
    final String insight = localeCode == 'id'
        ? _buildTodayInsight(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
          )
        : _buildTodayInsightEn(
            snapshot: snapshot,
            profile: profile,
            focusActivity: nextActivity,
          );

    return HomeAiBrief(
      headline: localeCode == 'id'
          ? _todayHeadlineId(snapshot)
          : _todayHeadlineEn(snapshot),
      insight: insight,
      suggestion: _nextLabel(
        localeCode: localeCode,
        activity: nextActivity,
      ),
      actionType: HomeAiActionType.none,
    );
  }

  String _upcomingLabel({
    required String localeCode,
    required ActivityModel activity,
    required DateTime selectedDate,
  }) {
    final String dayLabel = _weekdayFullLabel(
      selectedDate.weekday,
      localeCode,
    );
    final String timeLabel = formatMinutesAsTime(activity.timeMinutes);
    return localeCode == 'id'
        ? 'Pertama di $dayLabel: ${activity.title} | $timeLabel'
        : 'First on $dayLabel: ${activity.title} | $timeLabel';
  }

  String _focusLabel({
    required String localeCode,
    required ActivityModel activity,
    required int minutesUntil,
  }) {
    if (minutesUntil <= 0) {
      return localeCode == 'id'
          ? 'Saat ini: ${activity.title}'
          : 'Now: ${activity.title}';
    }
    return localeCode == 'id'
        ? 'Berikutnya: ${activity.title} | ${formatMinutesAsTime(activity.timeMinutes)}'
        : 'Next: ${activity.title} | ${formatMinutesAsTime(activity.timeMinutes)}';
  }

  String _nextLabel({
    required String localeCode,
    required ActivityModel? activity,
  }) {
    if (activity == null) {
      return localeCode == 'id'
          ? 'Belum ada langkah berikutnya'
          : 'No next step yet';
    }
    return localeCode == 'id'
        ? 'Berikutnya: ${activity.title} | ${formatMinutesAsTime(activity.timeMinutes)}'
        : 'Next: ${activity.title} | ${formatMinutesAsTime(activity.timeMinutes)}';
  }

  String _buildEmptyInsightId({
    required bool selectedIsToday,
    required bool selectedIsPast,
    required bool selectedIsFuture,
    required String dayLabel,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    if (selectedIsPast) {
      return '$dayLabel tidak punya aktivitas terjadwal.';
    }

    final String base = selectedIsToday
        ? 'Belum ada aktivitas terjadwal.'
        : '$dayLabel belum punya aktivitas terjadwal.';

    if (selectedIsToday && profile.bestTimeSegmentLabel != null) {
      return '$base Waktu ternyamannya biasanya ${profile.bestTimeSegmentLabel}.';
    }
    if (selectedIsFuture && profile.bestWeekday == selectedWeekday) {
      return '$base $dayLabel biasanya cukup stabil buatmu.';
    }
    return base;
  }

  String _buildEmptyInsightEn({
    required bool selectedIsToday,
    required bool selectedIsPast,
    required bool selectedIsFuture,
    required String dayLabel,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    if (selectedIsPast) {
      return 'There were no activities on $dayLabel.';
    }

    final String base = selectedIsToday
        ? 'There is no schedule for today.'
        : '$dayLabel is still empty.';

    if (selectedIsToday && profile.bestTimeSegmentLabel != null) {
      return '$base You are usually most comfortable around ${profile.bestTimeSegmentLabel}.';
    }
    if (selectedIsFuture && profile.bestWeekday == selectedWeekday) {
      return '$base $dayLabel is usually one of your more stable days.';
    }
    return base;
  }

  String _buildUpcomingInsightId({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
    required ActivityModel nextActivity,
    required String firstTime,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    final String starterTitle = snapshot.firstActivity?.title ?? nextActivity.title;
    final String base = snapshot.scheduledCount == 1
        ? '$dayLabel dimulai ${nextActivity.title} pukul $firstTime.'
        : '$dayLabel punya ${snapshot.scheduledCount} aktivitas, mulai $starterTitle pukul $firstTime.';
    final String personal = _personalQualifierId(
      profile: profile,
      referenceActivity: nextActivity,
      selectedWeekday: selectedWeekday,
    );
    return _joinInsightParts(<String>[
      base,
      personal.isEmpty ? '' : _asSentence(personal),
    ]);
  }

  String _buildUpcomingInsightEn({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
    required ActivityModel nextActivity,
    required String firstTime,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    final String starterTitle = snapshot.firstActivity?.title ?? nextActivity.title;
    final String base = snapshot.scheduledCount == 1
        ? '$dayLabel starts with ${nextActivity.title} at $firstTime.'
        : '$dayLabel has ${snapshot.scheduledCount} activities, starting with $starterTitle at $firstTime.';
    final String personal = _personalQualifierEn(
      profile: profile,
      referenceActivity: nextActivity,
      selectedWeekday: selectedWeekday,
    );
    return _joinInsightParts(<String>[
      base,
      personal.isEmpty ? '' : _asSentence(personal),
    ]);
  }

  String _buildCompletedInsightId({
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
  }) {
    final String base = snapshot.scheduledCount == 1 && snapshot.doneTitles.isNotEmpty
        ? '${snapshot.doneTitles.first} sudah selesai.'
        : 'Semua ${snapshot.scheduledCount} aktivitas hari ini selesai.';
    final String personal = _personalQualifierId(
      profile: profile,
      referenceActivity: snapshot.firstActivity,
    );
    return _joinInsightParts(<String>[
      base,
      personal.isEmpty
          ? 'Hari ini sudah beres.'
          : _asSentence(personal),
    ]);
  }

  String _buildCompletedInsightEn({
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
  }) {
    final String base = snapshot.scheduledCount == 1 && snapshot.doneTitles.isNotEmpty
        ? '${snapshot.doneTitles.first} is done.'
        : 'All ${snapshot.scheduledCount} activities are done today.';
    final String personal = _personalQualifierEn(
      profile: profile,
      referenceActivity: snapshot.firstActivity,
    );
    return _joinInsightParts(<String>[
      base,
      personal.isEmpty
          ? 'Today is wrapped up.'
          : _asSentence(personal),
    ]);
  }

  String _buildTodayInsight({
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    ActivityModel? focusActivity,
    int? focusMinutesUntil,
  }) {
    return _joinInsightParts(<String>[
      _buildTodayConditionId(
        snapshot: snapshot,
        focusActivity: focusActivity,
        focusMinutesUntil: focusMinutesUntil,
      ),
      _buildTodayFollowUpId(
        snapshot: snapshot,
        profile: profile,
        focusActivity: focusActivity,
        focusMinutesUntil: focusMinutesUntil,
      ),
    ]);
  }

  String _buildTodayInsightEn({
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    ActivityModel? focusActivity,
    int? focusMinutesUntil,
  }) {
    return _joinInsightParts(<String>[
      _buildTodayConditionEn(
        snapshot: snapshot,
        focusActivity: focusActivity,
        focusMinutesUntil: focusMinutesUntil,
      ),
      _buildTodayFollowUpEn(
        snapshot: snapshot,
        profile: profile,
        focusActivity: focusActivity,
        focusMinutesUntil: focusMinutesUntil,
      ),
    ]);
  }

  String _buildPastInsight({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    final String condition = snapshot.scheduledCount == 1
        ? _buildSinglePastConditionId(dayLabel: dayLabel, snapshot: snapshot)
        : _buildPastSummaryId(dayLabel: dayLabel, snapshot: snapshot);
    final String personal = _buildPastPersonalId(
      dayLabel: dayLabel,
      snapshot: snapshot,
      profile: profile,
      selectedWeekday: selectedWeekday,
    );
    return _joinInsightParts(<String>[
      condition,
      personal,
    ]);
  }

  String _buildPastInsightEn({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    final String condition = snapshot.scheduledCount == 1
        ? _buildSinglePastConditionEn(dayLabel: dayLabel, snapshot: snapshot)
        : _buildPastSummaryEn(dayLabel: dayLabel, snapshot: snapshot);
    final String personal = _buildPastPersonalEn(
      dayLabel: dayLabel,
      snapshot: snapshot,
      profile: profile,
      selectedWeekday: selectedWeekday,
    );
    return _joinInsightParts(<String>[
      condition,
      personal,
    ]);
  }

  String _buildStatusDistribution({
    required int doneCount,
    required int partialCount,
    required int missedCount,
    required int skippedCount,
    required int pendingCount,
    required String localeCode,
    required String pendingLabel,
    required String missedLabel,
  }) {
    final String phrase = _buildStatusDistributionPhrase(
      doneCount: doneCount,
      partialCount: partialCount,
      missedCount: missedCount,
      skippedCount: skippedCount,
      pendingCount: pendingCount,
      localeCode: localeCode,
      pendingLabel: pendingLabel,
      missedLabel: missedLabel,
    );
    if (phrase.isEmpty) {
      return localeCode == 'id'
          ? 'Belum ada progres yang tercatat.'
          : 'No progress has been recorded yet.';
    }
    return '$phrase.';
  }

  String _buildStatusDistributionPhrase({
    required int doneCount,
    required int partialCount,
    required int missedCount,
    required int skippedCount,
    required int pendingCount,
    required String localeCode,
    required String pendingLabel,
    required String missedLabel,
  }) {
    final List<String> parts = <String>[];
    if (doneCount > 0) {
      parts.add(localeCode == 'id' ? '$doneCount selesai' : '$doneCount done');
    }
    if (partialCount > 0) {
      parts.add(
        localeCode == 'id'
            ? '$partialCount hampir selesai'
            : '$partialCount nearly complete',
      );
    }
    if (pendingCount > 0) {
      parts.add('$pendingCount $pendingLabel');
    }
    if (missedCount > 0) {
      parts.add('$missedCount $missedLabel');
    }
    if (skippedCount > 0) {
      parts.add(
        localeCode == 'id' ? '$skippedCount dilewati' : '$skippedCount skipped',
      );
    }
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first;
    }
    final String last = parts.removeLast();
    final String joinWord = localeCode == 'id' ? 'dan' : 'and';
    return '${parts.join(', ')}, $joinWord $last';
  }

  String _buildTodayConditionId({
    required _SelectedDaySnapshot snapshot,
    ActivityModel? focusActivity,
    int? focusMinutesUntil,
  }) {
    if (snapshot.scheduledCount == 1) {
      if (snapshot.doneTitles.isNotEmpty) {
        return '${snapshot.doneTitles.first} sudah selesai untuk hari ini.';
      }
      if (snapshot.partialTitles.isNotEmpty) {
        return '${snapshot.partialTitles.first} sudah dikerjakan, tapi belum tuntas.';
      }
      if (snapshot.missedTitles.isNotEmpty) {
        return '${snapshot.missedTitles.first} sudah lewat tanpa progres hari ini.';
      }
      if (focusActivity != null && focusMinutesUntil != null && focusMinutesUntil <= 0) {
        return '${focusActivity.title} sudah masuk waktunya sekarang.';
      }
      if (focusActivity != null) {
        return '${focusActivity.title} baru dijadwalkan pukul ${formatMinutesAsTime(focusActivity.timeMinutes)}.';
      }
      if (snapshot.pendingTitles.isNotEmpty) {
        return '${snapshot.pendingTitles.first} jadi satu-satunya aktivitas hari ini.';
      }
    }

    if (snapshot.doneCount == 0 && snapshot.pendingCount == snapshot.scheduledCount) {
      return 'Ada ${snapshot.scheduledCount} aktivitas dan belum ada yang mulai.';
    }
    if (snapshot.missedCount > 0) {
      return 'Ada ${snapshot.missedCount} aktivitas yang terlewat hari ini.';
    }
    if (snapshot.partialCount > 0) {
      return 'Ada ${snapshot.partialCount} aktivitas yang belum tuntas.';
    }
    if (snapshot.doneCount > 0 && snapshot.remainingCount > 0) {
      return '${snapshot.doneCount} dari ${snapshot.scheduledCount} aktivitas sudah selesai.';
    }
    return 'Hari ini ada ${snapshot.scheduledCount} aktivitas.';
  }

  String _buildTodayConditionEn({
    required _SelectedDaySnapshot snapshot,
    ActivityModel? focusActivity,
    int? focusMinutesUntil,
  }) {
    if (snapshot.scheduledCount == 1) {
      if (snapshot.doneTitles.isNotEmpty) {
        return '${snapshot.doneTitles.first} is already done for today.';
      }
      if (snapshot.partialTitles.isNotEmpty) {
        return '${snapshot.partialTitles.first} is underway, but not finished yet.';
      }
      if (snapshot.missedTitles.isNotEmpty) {
        return '${snapshot.missedTitles.first} has already slipped past without progress.';
      }
      if (focusActivity != null && focusMinutesUntil != null && focusMinutesUntil <= 0) {
        return '${focusActivity.title} is already due now.';
      }
      if (focusActivity != null) {
        return '${focusActivity.title} is scheduled at ${formatMinutesAsTime(focusActivity.timeMinutes)}.';
      }
      if (snapshot.pendingTitles.isNotEmpty) {
        return '${snapshot.pendingTitles.first} is the only activity waiting today.';
      }
    }

    if (snapshot.doneCount == 0 && snapshot.pendingCount == snapshot.scheduledCount) {
      return 'There are ${snapshot.scheduledCount} activities and none have started.';
    }
    if (snapshot.missedCount > 0) {
      return '${snapshot.missedCount} activities have already been missed today.';
    }
    if (snapshot.partialCount > 0) {
      return '${snapshot.partialCount} activities are still unfinished.';
    }
    if (snapshot.doneCount > 0 && snapshot.remainingCount > 0) {
      return '${snapshot.doneCount} of ${snapshot.scheduledCount} activities are done.';
    }
    return 'There are ${snapshot.scheduledCount} activities today.';
  }

  String _buildTodayFollowUpId({
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    ActivityModel? focusActivity,
    int? focusMinutesUntil,
  }) {
    final String personal = _personalQualifierId(
      profile: profile,
      referenceActivity: focusActivity ?? snapshot.firstActivity,
      referenceTitle: snapshot.missedTitles.isNotEmpty ? snapshot.missedTitles.first : null,
      emphasizeMissed: snapshot.missedTitles.isNotEmpty,
    );

    if (focusActivity != null) {
      final String lead = focusMinutesUntil != null && focusMinutesUntil <= 0
          ? '${focusActivity.title} perlu diperhatikan sekarang'
          : 'Terdekat ${focusActivity.title} pukul ${formatMinutesAsTime(focusActivity.timeMinutes)}';
      return personal.isEmpty ? '$lead.' : '$lead, dan $personal.';
    }

    final String reaction = snapshot.missedCount > 0
        ? 'Masih ada jadwal yang tertinggal'
        : snapshot.partialCount > 0
        ? 'Masih ada aktivitas yang belum tuntas'
        : snapshot.doneCount > 0 && snapshot.remainingCount > 0
        ? 'Ritme hari ini sudah jalan'
        : snapshot.pendingCount == snapshot.scheduledCount
        ? 'Hari ini masih cukup longgar'
        : 'Ritmenya masih rapi';
    return personal.isEmpty ? '$reaction.' : '$reaction. ${_asSentence(personal)}';
  }

  String _buildTodayFollowUpEn({
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    ActivityModel? focusActivity,
    int? focusMinutesUntil,
  }) {
    final String personal = _personalQualifierEn(
      profile: profile,
      referenceActivity: focusActivity ?? snapshot.firstActivity,
      referenceTitle: snapshot.missedTitles.isNotEmpty ? snapshot.missedTitles.first : null,
      emphasizeMissed: snapshot.missedTitles.isNotEmpty,
    );

    if (focusActivity != null) {
      final String lead = focusMinutesUntil != null && focusMinutesUntil <= 0
          ? '${focusActivity.title} needs attention now'
          : 'Nearest is ${focusActivity.title} at ${formatMinutesAsTime(focusActivity.timeMinutes)}';
      return personal.isEmpty ? '$lead.' : '$lead, and $personal.';
    }

    final String reaction = snapshot.missedCount > 0
        ? 'There are still missed activities'
        : snapshot.partialCount > 0
        ? 'There are still unfinished activities'
        : snapshot.doneCount > 0 && snapshot.remainingCount > 0
        ? 'Today is already moving'
        : snapshot.pendingCount == snapshot.scheduledCount
        ? 'Today is still fairly open'
        : 'The rhythm is still in a good place';
    return personal.isEmpty ? '$reaction.' : '$reaction. ${_asSentence(personal)}';
  }

  String _buildSinglePastConditionId({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
  }) {
    if (snapshot.doneTitles.isNotEmpty) {
      return '${snapshot.doneTitles.first} pada $dayLabel selesai.';
    }
    if (snapshot.partialTitles.isNotEmpty) {
      return '${snapshot.partialTitles.first} pada $dayLabel belum tuntas.';
    }
    if (snapshot.missedTitles.isNotEmpty) {
      return '${snapshot.missedTitles.first} pada $dayLabel tidak dikerjakan.';
    }
    if (snapshot.skippedTitles.isNotEmpty) {
      return '${snapshot.skippedTitles.first} pada $dayLabel dilewati.';
    }
    return 'Pada $dayLabel ada 1 aktivitas yang tidak punya progres.';
  }

  String _buildSinglePastConditionEn({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
  }) {
    if (snapshot.doneTitles.isNotEmpty) {
      return '${snapshot.doneTitles.first} on $dayLabel was completed.';
    }
    if (snapshot.partialTitles.isNotEmpty) {
      return '${snapshot.partialTitles.first} on $dayLabel was left unfinished.';
    }
    if (snapshot.missedTitles.isNotEmpty) {
      return '${snapshot.missedTitles.first} on $dayLabel was not done.';
    }
    if (snapshot.skippedTitles.isNotEmpty) {
      return '${snapshot.skippedTitles.first} on $dayLabel was skipped.';
    }
    return 'There was 1 activity on $dayLabel without progress.';
  }

  String _buildPastSummaryId({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
  }) {
    if (snapshot.doneCount == snapshot.scheduledCount) {
      return '$dayLabel punya ${snapshot.scheduledCount} aktivitas, semuanya selesai.';
    }
    if (snapshot.doneCount == 0 && snapshot.missedCount == snapshot.scheduledCount) {
      return '$dayLabel punya ${snapshot.scheduledCount} aktivitas, semuanya terlewat.';
    }
    if (snapshot.doneCount > 0 && snapshot.remainingCount > 0) {
      return '$dayLabel punya ${snapshot.scheduledCount} aktivitas, ${snapshot.doneCount} selesai.';
    }
    if (snapshot.partialCount > 0) {
      return '$dayLabel punya ${snapshot.scheduledCount} aktivitas, ${snapshot.partialCount} belum tuntas.';
    }
    return '$dayLabel punya ${snapshot.scheduledCount} aktivitas.';
  }

  String _buildPastSummaryEn({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
  }) {
    if (snapshot.doneCount == snapshot.scheduledCount) {
      return 'On $dayLabel, all ${snapshot.scheduledCount} activities were completed.';
    }
    if (snapshot.doneCount == 0 && snapshot.missedCount == snapshot.scheduledCount) {
      return 'On $dayLabel, ${snapshot.scheduledCount} activities were not done.';
    }
    if (snapshot.doneCount > 0 && snapshot.remainingCount > 0) {
      return 'On $dayLabel, ${snapshot.doneCount} of ${snapshot.scheduledCount} activities were completed.';
    }
    if (snapshot.partialCount > 0) {
      return 'On $dayLabel, ${snapshot.partialCount} activities were left unfinished.';
    }
    return 'There were ${snapshot.scheduledCount} activities on $dayLabel.';
  }

  String _buildPastPersonalId({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    final String personal = _personalQualifierId(
      profile: profile,
      referenceActivity: snapshot.firstActivity,
      referenceTitle: snapshot.missedTitles.isNotEmpty ? snapshot.missedTitles.first : null,
      selectedWeekday: selectedWeekday,
      emphasizeMissed: snapshot.missedTitles.isNotEmpty,
    );
    if (personal.isEmpty) {
      return '';
    }
    if (profile.bestWeekday == selectedWeekday &&
        snapshot.doneCount != snapshot.scheduledCount) {
      return 'Biasanya $dayLabel lebih stabil buatmu.';
    }
    return _asSentence(personal);
  }

  String _buildPastPersonalEn({
    required String dayLabel,
    required _SelectedDaySnapshot snapshot,
    required _BehaviorProfile profile,
    required int selectedWeekday,
  }) {
    final String personal = _personalQualifierEn(
      profile: profile,
      referenceActivity: snapshot.firstActivity,
      referenceTitle: snapshot.missedTitles.isNotEmpty ? snapshot.missedTitles.first : null,
      selectedWeekday: selectedWeekday,
      emphasizeMissed: snapshot.missedTitles.isNotEmpty,
    );
    if (personal.isEmpty) {
      return '';
    }
    if (profile.bestWeekday == selectedWeekday &&
        snapshot.doneCount != snapshot.scheduledCount) {
      return '$dayLabel is usually more stable for you than this.';
    }
    return _asSentence(personal);
  }

  String _personalQualifierId({
    required _BehaviorProfile profile,
    ActivityModel? referenceActivity,
    String? referenceTitle,
    int? selectedWeekday,
    bool emphasizeMissed = false,
  }) {
    if (!profile.hasHistory) {
      return '';
    }

    final String? resolvedTitle = referenceTitle ?? referenceActivity?.title;
    if (emphasizeMissed &&
        resolvedTitle != null &&
        profile.mostMissedActivityTitle == resolvedTitle) {
      return '$resolvedTitle memang sering tertunda buatmu';
    }
    if (referenceActivity != null &&
        profile.bestTimeSegmentKey != null &&
        profile.bestTimeSegmentKey == _timeSegmentKey(referenceActivity.timeMinutes)) {
      return 'jam seperti ini biasanya paling nyaman buatmu';
    }
    if (referenceActivity != null &&
        profile.bestFamilyLabel != null &&
        profile.bestFamilyLabel ==
            _familyLabelForActivity(referenceActivity.title, localeCode: 'id')) {
      return 'aktivitas seperti ini biasanya paling konsisten buatmu';
    }
    if (selectedWeekday != null && profile.bestWeekday == selectedWeekday) {
      return '${_weekdayFullLabel(selectedWeekday, 'id')} biasanya cukup stabil buatmu';
    }
    if (profile.bestTimeSegmentLabel != null) {
      return 'kamu biasanya nyaman di ${profile.bestTimeSegmentLabel}';
    }
    if (profile.bestFamilyLabel != null) {
      return '${profile.bestFamilyLabel} biasanya paling stabil buatmu';
    }
    return '';
  }

  String _personalQualifierEn({
    required _BehaviorProfile profile,
    ActivityModel? referenceActivity,
    String? referenceTitle,
    int? selectedWeekday,
    bool emphasizeMissed = false,
  }) {
    if (!profile.hasHistory) {
      return '';
    }

    final String? resolvedTitle = referenceTitle ?? referenceActivity?.title;
    if (emphasizeMissed &&
        resolvedTitle != null &&
        profile.mostMissedActivityTitle == resolvedTitle) {
      return '$resolvedTitle is often the one you postpone most';
    }
    if (referenceActivity != null &&
        profile.bestTimeSegmentKey != null &&
        profile.bestTimeSegmentKey == _timeSegmentKey(referenceActivity.timeMinutes)) {
      return 'this time window is usually the most comfortable for you';
    }
    if (referenceActivity != null &&
        profile.bestFamilyLabel != null &&
        profile.bestFamilyLabel ==
            _familyLabelForActivity(referenceActivity.title, localeCode: 'en')) {
      return 'activities like this are usually the most consistent for you';
    }
    if (selectedWeekday != null && profile.bestWeekday == selectedWeekday) {
      return '${_weekdayFullLabel(selectedWeekday, 'en')} is usually a stable day for you';
    }
    if (profile.bestTimeSegmentLabel != null) {
      return 'you are usually most comfortable around ${profile.bestTimeSegmentLabel}';
    }
    if (profile.bestFamilyLabel != null) {
      return '${profile.bestFamilyLabel} is usually your most stable pattern';
    }
    return '';
  }

  String _joinInsightParts(List<String> parts) {
    const int maxLength = 88;
    final List<String> normalized = parts
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) {
      return '';
    }

    String result = normalized.first;
    for (int i = 1; i < normalized.length; i++) {
      final String candidate = '$result ${normalized[i]}';
      if (candidate.length > maxLength) {
        break;
      }
      result = candidate;
    }

    if (result.length <= maxLength) {
      return result;
    }
    final String shortened = result.substring(0, maxLength - 1).trimRight();
    return '$shortened...';
  }

  String _asSentence(String phrase) {
    final String trimmed = phrase.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}.';
  }

  String _todayHeadlineId(_SelectedDaySnapshot snapshot) {
    if (snapshot.missedCount > 0) {
      return 'Hari ini ada yang terlewat';
    }
    if (snapshot.partialCount > 0) {
      return 'Hari ini belum sepenuhnya beres';
    }
    if (snapshot.doneCount > 0 && snapshot.remainingCount > 0) {
      return 'Hari ini sedang berjalan';
    }
    if (snapshot.pendingCount == snapshot.scheduledCount) {
      return 'Hari ini siap dimulai';
    }
    return 'Hari ini berjalan cukup rapi';
  }

  String _todayHeadlineEn(_SelectedDaySnapshot snapshot) {
    if (snapshot.missedCount > 0) {
      return 'Something was missed today';
    }
    if (snapshot.partialCount > 0) {
      return 'Today is not fully complete yet';
    }
    if (snapshot.doneCount > 0 && snapshot.remainingCount > 0) {
      return 'Today is already in motion';
    }
    if (snapshot.pendingCount == snapshot.scheduledCount) {
      return 'Today is ready to start';
    }
    return 'Today is moving along well';
  }

  String _pastHeadlineId(String dayLabel, _SelectedDaySnapshot snapshot) {
    if (snapshot.doneCount == snapshot.scheduledCount) {
      return '$dayLabel selesai dengan rapi';
    }
    if (snapshot.doneCount == 0 &&
        snapshot.partialCount == 0 &&
        snapshot.missedCount == snapshot.scheduledCount) {
      return '$dayLabel tidak berjalan';
    }
    if (snapshot.partialCount > 0 || snapshot.missedCount > 0) {
      return '$dayLabel belum tuntas';
    }
    return 'Ringkasan $dayLabel';
  }

  String _pastHeadlineEn(String dayLabel, _SelectedDaySnapshot snapshot) {
    if (snapshot.doneCount == snapshot.scheduledCount) {
      return '$dayLabel finished cleanly';
    }
    if (snapshot.doneCount == 0 &&
        snapshot.partialCount == 0 &&
        snapshot.missedCount == snapshot.scheduledCount) {
      return '$dayLabel did not really happen';
    }
    if (snapshot.partialCount > 0 || snapshot.missedCount > 0) {
      return '$dayLabel was left unfinished';
    }
    return '$dayLabel recap';
  }

}

class _BehaviorProfile {
  const _BehaviorProfile({
    this.hasHistory = false,
    this.bestWeekday,
    this.bestWeekdayLabel,
    this.bestTimeSegmentKey,
    this.bestTimeSegmentLabel,
    this.bestFamilyLabel,
    this.mostMissedActivityTitle,
  });

  final bool hasHistory;
  final int? bestWeekday;
  final String? bestWeekdayLabel;
  final String? bestTimeSegmentKey;
  final String? bestTimeSegmentLabel;
  final String? bestFamilyLabel;
  final String? mostMissedActivityTitle;
}

class _SelectedDaySnapshot {
  const _SelectedDaySnapshot({
    required this.scheduledCount,
    required this.doneCount,
    required this.partialCount,
    required this.missedCount,
    required this.skippedCount,
    required this.pendingCount,
    required this.firstActivity,
    required this.lastActivity,
    required this.doneTitles,
    required this.partialTitles,
    required this.missedTitles,
    required this.skippedTitles,
    required this.pendingTitles,
  });

  final int scheduledCount;
  final int doneCount;
  final int partialCount;
  final int missedCount;
  final int skippedCount;
  final int pendingCount;
  final ActivityModel? firstActivity;
  final ActivityModel? lastActivity;
  final List<String> doneTitles;
  final List<String> partialTitles;
  final List<String> missedTitles;
  final List<String> skippedTitles;
  final List<String> pendingTitles;

  int get remainingCount =>
      math.max(0, scheduledCount - doneCount - skippedCount);
}
