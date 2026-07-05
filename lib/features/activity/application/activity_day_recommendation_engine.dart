import 'dart:math' as math;

import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/application/user_availability_note_parser.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';

class ActivityDayRecommendationEngine {
  const ActivityDayRecommendationEngine()
    : _noteParser = const UserAvailabilityNoteParser();

  final UserAvailabilityNoteParser _noteParser;

  SmartActivitySuggestion synchronize({
    required SmartActivitySuggestion suggestion,
    required AppSettingsModel settings,
    required List<ActivityModel> existingActivities,
    required String localeCode,
    String? editingActivityId,
  }) {
    if (suggestion.type != SmartActivityType.action || suggestion.needsTitleDetail) {
      return suggestion;
    }

    final SmartActivityLocalPlan? plan = suggestion.localPlan;
    if (plan == null) {
      return suggestion;
    }
    final SmartActivityRoutinePlacement routinePlacement =
        plan.routinePlacement;
    final bool routineCompatible =
        plan.routineCompatible ||
        routinePlacement != SmartActivityRoutinePlacement.none;

    final List<WeeklyRoutineDayProfile> routine = settings.normalizedWeeklyRoutine;
    final Set<int> activeRoutineDays = _activeRoutineDays(routine);
    final Map<int, int> loadByDay = _buildDayLoadMap(
      existingActivities: existingActivities,
      editingActivityId: editingActivityId,
    );
    final Map<int, int> extraBusyLoad = _buildExtraBusyLoad(
      settings.extraActivitiesNote,
      fallbackWeekdays: activeRoutineDays,
    );
    final Map<int, int> extraBusyMinutes = _buildExtraBusyMinutes(
      settings.extraActivitiesNote,
      fallbackWeekdays: activeRoutineDays,
    );
    final Map<int, List<_BusyWindow>> extraBusyWindows = _buildExtraBusyWindows(
      settings.extraActivitiesNote,
      fallbackWeekdays: activeRoutineDays,
    );
    for (final MapEntry<int, int> entry in extraBusyLoad.entries) {
      loadByDay[entry.key] = (loadByDay[entry.key] ?? 0) + entry.value;
    }

    final int targetSessions = _resolveTargetSessions(plan, routine);
    if (targetSessions <= 0) {
      return suggestion;
    }

    final List<_ScoredDay> scoredDays = routine
        .map(
          (WeeklyRoutineDayProfile day) => _ScoredDay(
              weekday: day.weekday,
              score: _scoreDay(
                weekday: day.weekday,
                day: day,
                loadCount: loadByDay[day.weekday] ?? 0,
                extraBusyMinutes: extraBusyMinutes[day.weekday] ?? 0,
                extraBusyWindows:
                    extraBusyWindows[day.weekday] ?? const <_BusyWindow>[],
                plan: plan,
                routineCompatible: routineCompatible,
                routinePlacement: routinePlacement,
              ),
            ),
          )
        .toList(growable: false)
      ..sort((_ScoredDay a, _ScoredDay b) => b.score.compareTo(a.score));

    final double minAcceptableScore = _minimumAcceptableScore(plan);
    final List<_ScoredDay> viableDays = scoredDays
        .where((_ScoredDay item) => item.score >= minAcceptableScore)
        .toList(growable: false);
    final List<_ScoredDay> candidateDays = viableDays.isNotEmpty
        ? viableDays
        : (scoredDays.isEmpty ? const <_ScoredDay>[] : <_ScoredDay>[scoredDays.first]);
    final List<int> recommendedDays = _pickBestDays(
      scoredDays: candidateDays,
      targetSessions: math.min(targetSessions, candidateDays.length),
      minGapDays: plan.minGapDays,
    );
    if (recommendedDays.isEmpty) {
      return suggestion;
    }

    return suggestion.copyWith(
      recommendedDays: recommendedDays,
      clearDayReason: true,
    );
  }

  Map<int, int> _buildDayLoadMap({
    required List<ActivityModel> existingActivities,
    required String? editingActivityId,
  }) {
    final Map<int, int> load = <int, int>{for (int day = 1; day <= 7; day++) day: 0};
    for (final ActivityModel activity in existingActivities) {
      if (activity.id == editingActivityId) {
        continue;
      }
      for (final int day in activity.selectedDays.toSet()) {
        if (day >= 1 && day <= 7) {
          load[day] = (load[day] ?? 0) + 1;
        }
      }
    }
    return load;
  }

  Set<int> _activeRoutineDays(List<WeeklyRoutineDayProfile> routine) {
    final Set<int> active = routine
        .where((WeeklyRoutineDayProfile day) => day.kind != WeeklyRoutineDayKind.off)
        .map((WeeklyRoutineDayProfile day) => day.weekday)
        .toSet();
    return active.isEmpty ? <int>{1, 2, 3, 4, 5, 6, 7} : active;
  }

  Map<int, int> _buildExtraBusyLoad(
    String? extraActivitiesNote, {
    required Set<int> fallbackWeekdays,
  }) {
    final Map<int, int> load = <int, int>{for (int day = 1; day <= 7; day++) day: 0};
    for (final UserBusyWindow window in _noteParser.parseWithFallback(
      extraActivitiesNote,
      fallbackWeekdays: fallbackWeekdays,
    )) {
      for (final int day in window.weekdays) {
        load[day] = (load[day] ?? 0) + 1;
      }
    }
    return load;
  }

  Map<int, int> _buildExtraBusyMinutes(
    String? extraActivitiesNote, {
    required Set<int> fallbackWeekdays,
  }) {
    final Map<int, int> busy = <int, int>{for (int day = 1; day <= 7; day++) day: 0};
    for (final UserBusyWindow window in _noteParser.parseWithFallback(
      extraActivitiesNote,
      fallbackWeekdays: fallbackWeekdays,
    )) {
      final int duration = math.max(0, window.endMinutes - window.startMinutes);
      for (final int day in window.weekdays) {
        busy[day] = (busy[day] ?? 0) + duration;
      }
    }
    return busy;
  }

  Map<int, List<_BusyWindow>> _buildExtraBusyWindows(
    String? extraActivitiesNote, {
    required Set<int> fallbackWeekdays,
  }) {
    final Map<int, List<_BusyWindow>> windows = <int, List<_BusyWindow>>{
      for (int day = 1; day <= 7; day++) day: <_BusyWindow>[],
    };
    for (final UserBusyWindow window in _noteParser.parseWithFallback(
      extraActivitiesNote,
      fallbackWeekdays: fallbackWeekdays,
    )) {
      for (final int day in window.weekdays) {
        windows.putIfAbsent(day, () => <_BusyWindow>[]).add(
          _BusyWindow(
            startMinutes: window.startMinutes,
            endMinutes: window.endMinutes,
          ),
        );
      }
    }
    return windows;
  }

  int _resolveTargetSessions(
    SmartActivityLocalPlan plan,
    List<WeeklyRoutineDayProfile> routine,
  ) {
    if (plan.dayStrategy == SmartActivityDayStrategy.daily) {
      return 7;
    }

    int availableDays = routine
        .where((WeeklyRoutineDayProfile day) => day.kind != WeeklyRoutineDayKind.off)
        .length;
    if (availableDays <= 0) {
      availableDays = 7;
    }

    final int desiredMax = math.min(plan.maxSessionsPerWeek, availableDays);
    final int desiredMin = math.min(plan.minSessionsPerWeek, desiredMax);
    if (plan.dayStrategy == SmartActivityDayStrategy.weekendFriendly && desiredMax >= 3) {
      return math.max(2, desiredMax);
    }
    return desiredMax >= desiredMin ? desiredMax : desiredMin;
  }

  double _scoreDay({
    required int weekday,
    required WeeklyRoutineDayProfile day,
    required int loadCount,
    required int extraBusyMinutes,
    required List<_BusyWindow> extraBusyWindows,
    required SmartActivityLocalPlan plan,
    required bool routineCompatible,
    required SmartActivityRoutinePlacement routinePlacement,
  }) {
    double score = _baseScoreForRoutinePlacement(day.kind, routinePlacement);

    final int occupiedMinutes =
        routinePlacement == SmartActivityRoutinePlacement.none
        ? _occupiedMinutes(day)
        : 0;
    final List<_BusyWindow> busyWindows = _busyWindowsForDay(
      day,
      extraBusyWindows,
      includePrimaryRoutine:
          routinePlacement != SmartActivityRoutinePlacement.duringRoutine &&
          routinePlacement != SmartActivityRoutinePlacement.anytime,
    );
    final int effectiveExtraBusyMinutes = routineCompatible
        ? _busyMinutesInPreferredRanges(extraBusyWindows, plan)
        : extraBusyMinutes;
    final int requiredMinutes = _requiredSessionMinutes(plan);
    final int longestGap = _longestFreeGap(
      busyWindows: busyWindows,
      dayStartMinutes: 5 * 60,
      dayEndMinutes: 24 * 60,
    );
    final int preferredAvailability = _preferredAvailabilityMinutes(
      busyWindows,
      plan,
    );
    final int daytimeAvailability = _availableMinutesInRange(
      busyWindows,
      6 * 60,
      22 * 60,
    );
    final int latestBusyEnd = _latestBusyEnd(busyWindows);
    final int earliestBusyStart = _earliestBusyStart(busyWindows);

    score -= occupiedMinutes / 36;
    score -= loadCount * (routineCompatible ? 4 : 10);
    score -= effectiveExtraBusyMinutes / (routineCompatible ? 40 : 24);

    switch (plan.effortLevel) {
      case SmartActivityEffortLevel.high:
        score -= occupiedMinutes / 28;
        break;
      case SmartActivityEffortLevel.medium:
        score -= occupiedMinutes / 44;
        break;
      case SmartActivityEffortLevel.low:
        score -= occupiedMinutes / 72;
        break;
    }

    if (longestGap < requiredMinutes) {
      score -= 160;
    } else if (preferredAvailability < requiredMinutes) {
      score -= 70;
    } else {
      score += math.min((preferredAvailability - requiredMinutes) / 18, 14);
    }

    if (!routineCompatible &&
        daytimeAvailability < requiredMinutes &&
        day.kind != WeeklyRoutineDayKind.off &&
        day.kind != WeeklyRoutineDayKind.flexible) {
      score -= 60;
    }
    if (!routineCompatible &&
        latestBusyEnd >= 22 * 60 &&
        plan.effortLevel != SmartActivityEffortLevel.low) {
      score -= 26;
    }
    if (!routineCompatible &&
        earliestBusyStart <= 8 * 60 &&
        latestBusyEnd >= 20 * 60) {
      score -= 22;
    }
    if (effectiveExtraBusyMinutes >= 180 && loadCount > 0) {
      score -= 18;
    }

    score += _placementAdjustment(
      day: day,
      routinePlacement: routinePlacement,
    );

    switch (plan.dayStrategy) {
      case SmartActivityDayStrategy.daily:
        score += 14;
        break;
      case SmartActivityDayStrategy.spaced:
        score += weekday.isEven ? 10 : 6;
        break;
      case SmartActivityDayStrategy.workdayFriendly:
        score += weekday <= 5 ? 18 : -10;
        break;
      case SmartActivityDayStrategy.weekendFriendly:
        score += weekday >= 6 ? 22 : weekday == 5 ? 10 : -12;
        break;
      case SmartActivityDayStrategy.flexible:
        score += 8;
        break;
    }

    if (plan.preferredTimeWindows.contains(SmartActivityTimeWindow.morning) ||
        plan.preferredTimeWindows.contains(SmartActivityTimeWindow.earlyMorning)) {
      if (day.departureMinutes != null && day.departureMinutes! <= 8 * 60) {
        score -= 12;
      } else {
        score += 4;
      }
    }

    if (plan.preferredTimeWindows.contains(SmartActivityTimeWindow.evening) ||
        plan.preferredTimeWindows.contains(SmartActivityTimeWindow.night)) {
      if (day.returnMinutes != null && day.returnMinutes! >= 20 * 60) {
        score -= 12;
      } else {
        score += 4;
      }
    }

    return score;
  }

  double _baseScoreForRoutinePlacement(
    WeeklyRoutineDayKind kind,
    SmartActivityRoutinePlacement placement,
  ) {
    switch (placement) {
      case SmartActivityRoutinePlacement.none:
        return switch (kind) {
          WeeklyRoutineDayKind.off => 100,
          WeeklyRoutineDayKind.flexible => 88,
          WeeklyRoutineDayKind.unspecified => 70,
          WeeklyRoutineDayKind.custom => 66,
          WeeklyRoutineDayKind.work => 54,
          WeeklyRoutineDayKind.college => 50,
          WeeklyRoutineDayKind.school => 48,
        };
      case SmartActivityRoutinePlacement.beforeStart:
        return switch (kind) {
          WeeklyRoutineDayKind.off => 94,
          WeeklyRoutineDayKind.flexible => 92,
          WeeklyRoutineDayKind.unspecified => 88,
          WeeklyRoutineDayKind.custom => 86,
          WeeklyRoutineDayKind.work => 84,
          WeeklyRoutineDayKind.college => 82,
          WeeklyRoutineDayKind.school => 80,
        };
      case SmartActivityRoutinePlacement.duringRoutine:
        return switch (kind) {
          WeeklyRoutineDayKind.off => 86,
          WeeklyRoutineDayKind.flexible => 92,
          WeeklyRoutineDayKind.unspecified => 88,
          WeeklyRoutineDayKind.custom => 86,
          WeeklyRoutineDayKind.work => 96,
          WeeklyRoutineDayKind.college => 94,
          WeeklyRoutineDayKind.school => 92,
        };
      case SmartActivityRoutinePlacement.afterEnd:
        return switch (kind) {
          WeeklyRoutineDayKind.off => 94,
          WeeklyRoutineDayKind.flexible => 92,
          WeeklyRoutineDayKind.unspecified => 88,
          WeeklyRoutineDayKind.custom => 86,
          WeeklyRoutineDayKind.work => 84,
          WeeklyRoutineDayKind.college => 82,
          WeeklyRoutineDayKind.school => 80,
        };
      case SmartActivityRoutinePlacement.outsideRoutine:
        return switch (kind) {
          WeeklyRoutineDayKind.off => 100,
          WeeklyRoutineDayKind.flexible => 94,
          WeeklyRoutineDayKind.unspecified => 90,
          WeeklyRoutineDayKind.custom => 88,
          WeeklyRoutineDayKind.work => 86,
          WeeklyRoutineDayKind.college => 84,
          WeeklyRoutineDayKind.school => 82,
        };
      case SmartActivityRoutinePlacement.anytime:
        return switch (kind) {
          WeeklyRoutineDayKind.off => 96,
          WeeklyRoutineDayKind.flexible => 94,
          WeeklyRoutineDayKind.unspecified => 92,
          WeeklyRoutineDayKind.custom => 90,
          WeeklyRoutineDayKind.work => 92,
          WeeklyRoutineDayKind.college => 90,
          WeeklyRoutineDayKind.school => 88,
        };
    }
  }

  double _placementAdjustment({
    required WeeklyRoutineDayProfile day,
    required SmartActivityRoutinePlacement routinePlacement,
  }) {
    final int? routineStart = day.departureMinutes ?? day.startMinutes;
    final int? routineEnd = day.returnMinutes ?? day.endMinutes;
    switch (routinePlacement) {
      case SmartActivityRoutinePlacement.beforeStart:
        if (routineStart == null) {
          return 6;
        }
        if (routineStart <= 6 * 60 + 30) {
          return -18;
        }
        if (routineStart <= 8 * 60) {
          return -6;
        }
        return 8;
      case SmartActivityRoutinePlacement.duringRoutine:
        return day.kind == WeeklyRoutineDayKind.off ? 2 : 10;
      case SmartActivityRoutinePlacement.afterEnd:
        if (routineEnd == null) {
          return 6;
        }
        if (routineEnd >= 21 * 60) {
          return -18;
        }
        if (routineEnd >= 19 * 60) {
          return -6;
        }
        return 8;
      case SmartActivityRoutinePlacement.outsideRoutine:
        return day.kind == WeeklyRoutineDayKind.off ||
                day.kind == WeeklyRoutineDayKind.flexible
            ? 10
            : 4;
      case SmartActivityRoutinePlacement.anytime:
        return 10;
      case SmartActivityRoutinePlacement.none:
        return 0;
    }
  }

  double _minimumAcceptableScore(SmartActivityLocalPlan plan) {
    return switch (plan.effortLevel) {
      SmartActivityEffortLevel.high => 22,
      SmartActivityEffortLevel.medium => 12,
      SmartActivityEffortLevel.low => 6,
    };
  }

  int _occupiedMinutes(WeeklyRoutineDayProfile day) {
    int occupied = 0;
    if (day.startMinutes != null && day.endMinutes != null && day.endMinutes! > day.startMinutes!) {
      occupied += day.endMinutes! - day.startMinutes!;
    }
    if (day.departureMinutes != null && day.startMinutes != null && day.startMinutes! > day.departureMinutes!) {
      occupied += day.startMinutes! - day.departureMinutes!;
    }
    if (day.returnMinutes != null && day.endMinutes != null && day.returnMinutes! > day.endMinutes!) {
      occupied += day.returnMinutes! - day.endMinutes!;
    }
    return occupied;
  }

  List<_BusyWindow> _busyWindowsForDay(
    WeeklyRoutineDayProfile day,
    List<_BusyWindow> extraBusyWindows,
    {required bool includePrimaryRoutine}
  ) {
    final List<_BusyWindow> windows = <_BusyWindow>[...extraBusyWindows];
    if (!includePrimaryRoutine) {
      windows.sort(
        (_BusyWindow a, _BusyWindow b) => a.startMinutes.compareTo(b.startMinutes),
      );
      return _mergeBusyWindows(windows);
    }
    final int? occupiedStart = day.departureMinutes ?? day.startMinutes;
    final int? occupiedEnd = day.returnMinutes ?? day.endMinutes;
    if (occupiedStart != null &&
        occupiedEnd != null &&
        occupiedEnd > occupiedStart) {
      windows.add(
        _BusyWindow(startMinutes: occupiedStart, endMinutes: occupiedEnd),
      );
    }
    windows.sort(
      (_BusyWindow a, _BusyWindow b) => a.startMinutes.compareTo(b.startMinutes),
    );
    return _mergeBusyWindows(windows);
  }

  List<_BusyWindow> _mergeBusyWindows(List<_BusyWindow> windows) {
    if (windows.isEmpty) {
      return const <_BusyWindow>[];
    }
    final List<_BusyWindow> merged = <_BusyWindow>[windows.first];
    for (final _BusyWindow window in windows.skip(1)) {
      final _BusyWindow last = merged.last;
      if (window.startMinutes <= last.endMinutes) {
        merged[merged.length - 1] = _BusyWindow(
          startMinutes: last.startMinutes,
          endMinutes: math.max(last.endMinutes, window.endMinutes),
        );
        continue;
      }
      merged.add(window);
    }
    return merged;
  }

  int _availableMinutesInRange(
    List<_BusyWindow> busyWindows,
    int startMinutes,
    int endMinutes,
  ) {
    int blocked = 0;
    for (final _BusyWindow window in busyWindows) {
      final int overlapStart = math.max(window.startMinutes, startMinutes);
      final int overlapEnd = math.min(window.endMinutes, endMinutes);
      if (overlapEnd > overlapStart) {
        blocked += overlapEnd - overlapStart;
      }
    }
    return math.max(0, (endMinutes - startMinutes) - blocked);
  }

  int _preferredAvailabilityMinutes(
    List<_BusyWindow> busyWindows,
    SmartActivityLocalPlan plan,
  ) {
    int available = 0;
    for (final _TimeWindowRange range in _preferredRanges(plan)) {
      available += _availableMinutesInRange(
        busyWindows,
        range.startMinutes,
        range.endMinutes,
      );
    }
    return available;
  }

  int _busyMinutesInPreferredRanges(
    List<_BusyWindow> busyWindows,
    SmartActivityLocalPlan plan,
  ) {
    int blocked = 0;
    for (final _TimeWindowRange range in _preferredRanges(plan)) {
      for (final _BusyWindow window in busyWindows) {
        final int overlapStart = math.max(window.startMinutes, range.startMinutes);
        final int overlapEnd = math.min(window.endMinutes, range.endMinutes);
        if (overlapEnd > overlapStart) {
          blocked += overlapEnd - overlapStart;
        }
      }
    }
    return blocked;
  }

  int _longestFreeGap({
    required List<_BusyWindow> busyWindows,
    required int dayStartMinutes,
    required int dayEndMinutes,
  }) {
    int longest = 0;
    int cursor = dayStartMinutes;
    for (final _BusyWindow window in busyWindows) {
      if (window.endMinutes <= dayStartMinutes) {
        continue;
      }
      if (window.startMinutes >= dayEndMinutes) {
        break;
      }
      final int freeUntil = math.max(dayStartMinutes, window.startMinutes);
      if (freeUntil > cursor) {
        longest = math.max(longest, freeUntil - cursor);
      }
      cursor = math.max(cursor, math.min(dayEndMinutes, window.endMinutes));
    }
    if (dayEndMinutes > cursor) {
      longest = math.max(longest, dayEndMinutes - cursor);
    }
    return longest;
  }

  int _latestBusyEnd(List<_BusyWindow> busyWindows) {
    if (busyWindows.isEmpty) {
      return 0;
    }
    return busyWindows
        .map((_BusyWindow window) => window.endMinutes)
        .reduce(math.max);
  }

  int _earliestBusyStart(List<_BusyWindow> busyWindows) {
    if (busyWindows.isEmpty) {
      return 24 * 60;
    }
    return busyWindows
        .map((_BusyWindow window) => window.startMinutes)
        .reduce(math.min);
  }

  int _requiredSessionMinutes(SmartActivityLocalPlan plan) {
    return switch (plan.effortLevel) {
      SmartActivityEffortLevel.high => 75,
      SmartActivityEffortLevel.medium => 60,
      SmartActivityEffortLevel.low => 25,
    };
  }

  List<_TimeWindowRange> _preferredRanges(SmartActivityLocalPlan plan) {
    final List<SmartActivityTimeWindow> windows = plan.preferredTimeWindows;
    if (windows.isEmpty) {
      return const <_TimeWindowRange>[
        _TimeWindowRange(startMinutes: 6 * 60, endMinutes: 22 * 60),
      ];
    }

    final Set<String> seen = <String>{};
    final List<_TimeWindowRange> ranges = <_TimeWindowRange>[];
    for (final SmartActivityTimeWindow window in windows) {
      final _TimeWindowRange range = switch (window) {
        SmartActivityTimeWindow.earlyMorning => const _TimeWindowRange(
          startMinutes: 5 * 60,
          endMinutes: 8 * 60,
        ),
        SmartActivityTimeWindow.morning => const _TimeWindowRange(
          startMinutes: 8 * 60,
          endMinutes: 12 * 60,
        ),
        SmartActivityTimeWindow.midday => const _TimeWindowRange(
          startMinutes: 12 * 60,
          endMinutes: 14 * 60,
        ),
        SmartActivityTimeWindow.afternoon => const _TimeWindowRange(
          startMinutes: 14 * 60,
          endMinutes: 18 * 60,
        ),
        SmartActivityTimeWindow.evening => const _TimeWindowRange(
          startMinutes: 18 * 60,
          endMinutes: 21 * 60,
        ),
        SmartActivityTimeWindow.night => const _TimeWindowRange(
          startMinutes: 21 * 60,
          endMinutes: 24 * 60,
        ),
      };
      final String key = '${range.startMinutes}-${range.endMinutes}';
      if (seen.add(key)) {
        ranges.add(range);
      }
    }
    return ranges;
  }

  List<int> _pickBestDays({
    required List<_ScoredDay> scoredDays,
    required int targetSessions,
    required int minGapDays,
  }) {
    final List<int> result = <int>[];
    for (final _ScoredDay day in scoredDays) {
      if (result.length >= targetSessions) {
        break;
      }
      final bool tooClose = result.any(
        (int chosen) => _weekdayDistance(chosen, day.weekday) <= minGapDays,
      );
      if (tooClose) {
        continue;
      }
      result.add(day.weekday);
    }

    if (result.length < math.min(targetSessions, 2)) {
      for (final _ScoredDay day in scoredDays) {
        if (result.contains(day.weekday)) {
          continue;
        }
        result.add(day.weekday);
        if (result.length >= targetSessions) {
          break;
        }
      }
    }

    result.sort();
    return result;
  }

  int _weekdayDistance(int a, int b) {
    final int direct = (a - b).abs();
    return math.min(direct, 7 - direct);
  }

  String suggestedFrequencyLabel(
    SmartActivityLocalPlan plan,
    String localeCode,
  ) {
    final String countLabel = plan.minSessionsPerWeek == plan.maxSessionsPerWeek
        ? '${plan.maxSessionsPerWeek}x'
        : '${plan.minSessionsPerWeek}-${plan.maxSessionsPerWeek}x';
    return localeCode == 'id' ? '$countLabel seminggu' : '$countLabel a week';
  }

}

class _ScoredDay {
  const _ScoredDay({
    required this.weekday,
    required this.score,
  });

  final int weekday;
  final double score;
}

class _BusyWindow {
  const _BusyWindow({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;
}

class _TimeWindowRange {
  const _TimeWindowRange({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;
}
