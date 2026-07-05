import 'dart:math' as math;

import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/application/user_availability_note_parser.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';

class ActivityTimeSyncEngine {
  const ActivityTimeSyncEngine()
    : _advisor = const SmartActivityAdvisor(),
      _noteParser = const UserAvailabilityNoteParser();

  final SmartActivityAdvisor _advisor;
  final UserAvailabilityNoteParser _noteParser;

  SmartActivitySuggestion synchronize({
    required SmartActivitySuggestion suggestion,
    required Iterable<int> selectedDays,
    required List<ActivityModel> existingActivities,
    required AppSettingsModel settings,
    required String localeCode,
    String? editingActivityId,
  }) {
    SmartActivitySuggestion workingSuggestion = suggestion;
    if (workingSuggestion.type != SmartActivityType.action ||
        workingSuggestion.needsTitleDetail) {
      return workingSuggestion;
    }

    final List<int> normalizedDays =
        selectedDays.where((int day) => day >= 1 && day <= 7).toSet().toList()
          ..sort();
    if (normalizedDays.isEmpty) {
      return workingSuggestion;
    }

    final SmartActivityRoutinePlacement routinePlacement =
        workingSuggestion.localPlan?.routinePlacement ??
        SmartActivityRoutinePlacement.none;
    final Map<int, _RoutineWindow> routineWindowsByDay = _buildRoutineWindows(
      settings,
      targetDays: normalizedDays.toSet(),
    );

    final List<_ScheduledBlock> scheduledBlocks = existingActivities
        .where(
          (ActivityModel activity) =>
              activity.id != editingActivityId &&
              activity.selectedDays.any(normalizedDays.contains),
        )
        .map(
          (ActivityModel activity) => _ScheduledBlock(
            title: activity.title.trim(),
            selectedDays: activity.selectedDays.toSet(),
            startMinutes: activity.timeMinutes,
            timing: _timingForExistingActivity(
              activity,
              localeCode: localeCode,
            ),
            ),
        )
        .toList();
    if (routinePlacement == SmartActivityRoutinePlacement.none) {
      scheduledBlocks.addAll(
        _buildRoutineBlocks(
          settings,
          targetDays: normalizedDays.toSet(),
          localeCode: localeCode,
        ),
      );
    }
    scheduledBlocks.addAll(
      _buildExtraBusyBlocks(
        settings.extraActivitiesNote,
        fallbackWeekdays: _activeRoutineDays(settings),
        localeCode: localeCode,
      ),
    );
    final Map<int, List<_ScheduledBlock>> blocksByDay = _groupBlocksByDay(
      normalizedDays,
      scheduledBlocks,
    );
    workingSuggestion = _applyContextualBaseline(
      suggestion: workingSuggestion,
      selectedDays: normalizedDays,
      settings: settings,
      localeCode: localeCode,
      routinePlacement: routinePlacement,
      routineWindowsByDay: routineWindowsByDay,
      blocksByDay: blocksByDay,
    );

    final int? baseTimeMinutes = workingSuggestion.recommendedTimeMinutes;
    if (baseTimeMinutes == null) {
      return workingSuggestion;
    }

    final _ActivityTiming newTiming = _timingForSuggestion(workingSuggestion);
    final bool baseViolatesRoutinePlacement = _violatesRoutinePlacement(
      candidateStartMinutes: baseTimeMinutes,
      selectedDays: normalizedDays,
      newTiming: newTiming,
      routinePlacement: routinePlacement,
      routineWindowsByDay: routineWindowsByDay,
    );
    final List<_ConflictHit> hardBaseConflicts = _collectHardOverlapConflicts(
      baseTimeMinutes: baseTimeMinutes,
      selectedDays: normalizedDays,
      newTiming: newTiming,
      blocksByDay: blocksByDay,
    );
    final List<_ConflictHit> baseConflicts = _collectConflicts(
      baseTimeMinutes: baseTimeMinutes,
      selectedDays: normalizedDays,
      newTiming: newTiming,
      blocksByDay: blocksByDay,
    );
    final List<_ConflictHit> effectiveBaseConflicts = hardBaseConflicts.isNotEmpty
        ? hardBaseConflicts
        : baseConflicts;
    if (effectiveBaseConflicts.isEmpty && !baseViolatesRoutinePlacement) {
      return workingSuggestion;
    }

    final _ResolvedRecommendation? resolved = _findBestFreeSlot(
      baseTimeMinutes: baseTimeMinutes,
      selectedDays: normalizedDays,
      newTiming: newTiming,
      blocksByDay: blocksByDay,
      baseConflicts: effectiveBaseConflicts,
      routinePlacement: routinePlacement,
      routineWindowsByDay: routineWindowsByDay,
    );
    if (resolved == null || resolved.timeMinutes == baseTimeMinutes) {
      return workingSuggestion;
    }

    return workingSuggestion.copyWith(
      recommendedTimeMinutes: resolved.timeMinutes,
      reason: _buildAdjustedReason(
        baseReason: workingSuggestion.reason,
        localeCode: localeCode,
        baseTimeMinutes: baseTimeMinutes,
        resolved: resolved,
      ),
    );
  }

  SmartActivitySuggestion _applyContextualBaseline({
    required SmartActivitySuggestion suggestion,
    required List<int> selectedDays,
    required AppSettingsModel settings,
    required String localeCode,
    required SmartActivityRoutinePlacement routinePlacement,
    required Map<int, _RoutineWindow> routineWindowsByDay,
    required Map<int, List<_ScheduledBlock>> blocksByDay,
  }) {
    final SmartActivityLocalPlan? plan = suggestion.localPlan;
    if (plan == null) {
      return suggestion;
    }

    final int contextualTime = _resolveContextualBaseTime(
      suggestion: suggestion,
      selectedDays: selectedDays,
      settings: settings,
      routinePlacement: routinePlacement,
      routineWindowsByDay: routineWindowsByDay,
      blocksByDay: blocksByDay,
    );
    final bool hasNoUserContext =
        !settings.hasConfiguredWeeklyRoutine &&
        !settings.hasExtraActivitiesNote &&
        blocksByDay.values.every((List<_ScheduledBlock> items) => items.isEmpty);
    final bool timeChanged =
        contextualTime != suggestion.recommendedTimeMinutes;
    if (!timeChanged && !hasNoUserContext) {
      return suggestion;
    }

    return suggestion.copyWith(
      recommendedTimeMinutes: contextualTime,
      reason: _buildContextualBaseReason(
        suggestion: suggestion,
        localeCode: localeCode,
        settings: settings,
        timeMinutes: contextualTime,
        hasRoutineContext: routineWindowsByDay.isNotEmpty,
        routinePlacement: routinePlacement,
      ),
    );
  }

  bool _shouldUseNeutralBaseline({
    required SmartActivitySuggestion suggestion,
    required AppSettingsModel settings,
    required List<ActivityModel> existingActivities,
  }) {
    return suggestion.type == SmartActivityType.action &&
        !suggestion.needsTitleDetail &&
        suggestion.recommendedTimeMinutes != null &&
        !settings.hasConfiguredWeeklyRoutine &&
        !settings.hasExtraActivitiesNote &&
        existingActivities.isEmpty;
  }

  SmartActivitySuggestion _applyNeutralBaseline(
    SmartActivitySuggestion suggestion, {
    required String localeCode,
  }) {
    final SmartActivityLocalPlan? plan = suggestion.localPlan;
    if (plan == null) {
      return suggestion;
    }

    final int neutralTime = _neutralTimeForPlan(plan);
    if (neutralTime == suggestion.recommendedTimeMinutes) {
      return suggestion.copyWith(
        reason: _buildNeutralReason(
          suggestion: suggestion,
          localeCode: localeCode,
          timeMinutes: neutralTime,
        ),
      );
    }

    return suggestion.copyWith(
      recommendedTimeMinutes: neutralTime,
      reason: _buildNeutralReason(
        suggestion: suggestion,
        localeCode: localeCode,
        timeMinutes: neutralTime,
      ),
    );
  }

  int _neutralTimeForPlan(SmartActivityLocalPlan plan) {
    final List<SmartActivityTimeWindow> windows = plan.preferredTimeWindows;
    if (windows.isEmpty) {
      return 9 * 60;
    }

    int? best;
    for (final SmartActivityTimeWindow window in windows) {
      final int candidate = switch (window) {
        SmartActivityTimeWindow.earlyMorning => 6 * 60,
        SmartActivityTimeWindow.morning => 8 * 60 + 30,
        SmartActivityTimeWindow.midday => 12 * 60 + 30,
        SmartActivityTimeWindow.afternoon => 16 * 60,
        SmartActivityTimeWindow.evening => 18 * 60 + 30,
        SmartActivityTimeWindow.night => 21 * 60,
      };
      best ??= candidate;
      if (candidate < best) {
        best = candidate;
      }
    }

    return best ?? 9 * 60;
  }

  String _buildNeutralReason({
    required SmartActivitySuggestion suggestion,
    required String localeCode,
    required int timeMinutes,
  }) {
    final SmartActivityLocalPlan? plan = suggestion.localPlan;
    final String timeLabel = formatMinutesAsTime(timeMinutes);
    final SmartActivityTimeWindow? primaryWindow =
        (plan == null || plan.preferredTimeWindows.isEmpty)
        ? null
        : plan.preferredTimeWindows.first;

    if (localeCode != 'id') {
      final String windowLabel = switch (primaryWindow) {
        SmartActivityTimeWindow.earlyMorning => 'early morning',
        SmartActivityTimeWindow.morning => 'morning',
        SmartActivityTimeWindow.midday => 'midday',
        SmartActivityTimeWindow.afternoon => 'late afternoon',
        SmartActivityTimeWindow.evening => 'evening',
        SmartActivityTimeWindow.night => 'night',
        null => 'a neutral time',
      };
      return 'Your routine has not been set yet, so the recommendation is temporarily placed at $timeLabel in the $windowLabel as a neutral starting point.';
    }

    final String windowLabel = switch (primaryWindow) {
      SmartActivityTimeWindow.earlyMorning => 'awal pagi',
      SmartActivityTimeWindow.morning => 'pagi',
      SmartActivityTimeWindow.midday => 'tengah hari',
      SmartActivityTimeWindow.afternoon => 'sore',
      SmartActivityTimeWindow.evening => 'menjelang malam',
      SmartActivityTimeWindow.night => 'malam',
      null => 'waktu netral',
    };
    return 'Karena rutinitas utamamu belum diatur, rekomendasi sementara dipasang di pukul $timeLabel pada $windowLabel sebagai titik mulai yang netral.';
  }

  int _resolveContextualBaseTime({
    required SmartActivitySuggestion suggestion,
    required List<int> selectedDays,
    required AppSettingsModel settings,
    required SmartActivityRoutinePlacement routinePlacement,
    required Map<int, _RoutineWindow> routineWindowsByDay,
    required Map<int, List<_ScheduledBlock>> blocksByDay,
  }) {
    final SmartActivityLocalPlan? plan = suggestion.localPlan;
    if (plan == null) {
      return suggestion.recommendedTimeMinutes ?? 9 * 60;
    }
    final List<SmartActivityTimeWindow> windows = plan.preferredTimeWindows;
    if (windows.isEmpty) {
      return suggestion.recommendedTimeMinutes ?? 9 * 60;
    }
    final bool hasNoUserContext =
        !settings.hasConfiguredWeeklyRoutine &&
        !settings.hasExtraActivitiesNote &&
        blocksByDay.values.every((List<_ScheduledBlock> items) => items.isEmpty);
    if (hasNoUserContext) {
      return _neutralTimeForPlan(plan);
    }

    final _ActivityTiming timing = _timingForSuggestion(suggestion);
    final _RoutineBounds routineBounds = _summarizeRoutineBounds(
      selectedDays: selectedDays,
      routineWindowsByDay: routineWindowsByDay,
    );
    final int? representativeBreakMidpoint = _representativeBreakMidpoint(
      settings,
      selectedDays,
    );
    final List<int> candidates = <int>[];

    for (final SmartActivityTimeWindow window in windows) {
      final int anchoredCandidate = _contextualCandidateForWindow(
        window: window,
        plan: plan,
        timing: timing,
        routinePlacement: routinePlacement,
        routineBounds: routineBounds,
        breakMidpoint: representativeBreakMidpoint,
      );
      if (!candidates.contains(anchoredCandidate)) {
        candidates.add(anchoredCandidate);
      }
    }

    if (candidates.isEmpty) {
      return suggestion.recommendedTimeMinutes ?? 9 * 60;
    }

    for (final int candidate in candidates) {
      if (_violatesRoutinePlacement(
        candidateStartMinutes: candidate,
        selectedDays: selectedDays,
        newTiming: timing,
        routinePlacement: routinePlacement,
        routineWindowsByDay: routineWindowsByDay,
      )) {
        continue;
      }
      final List<_ConflictHit> hardConflicts = _collectHardOverlapConflicts(
        baseTimeMinutes: candidate,
        selectedDays: selectedDays,
        newTiming: timing,
        blocksByDay: blocksByDay,
      );
      if (hardConflicts.isEmpty) {
        return candidate;
      }
    }

    return candidates.first;
  }

  int _contextualCandidateForWindow({
    required SmartActivityTimeWindow window,
    required SmartActivityLocalPlan plan,
    required _ActivityTiming timing,
    required SmartActivityRoutinePlacement routinePlacement,
    required _RoutineBounds routineBounds,
    required int? breakMidpoint,
  }) {
    int candidate = _windowAnchorMinutes(window);

    switch (routinePlacement) {
      case SmartActivityRoutinePlacement.beforeStart:
        if (routineBounds.hasRoutine) {
          final int earliestStart = routineBounds.earliestStart!;
          candidate = math.min(
            candidate,
            earliestStart - timing.durationMinutes - _leadGapMinutes(plan),
          );
        }
        break;
      case SmartActivityRoutinePlacement.duringRoutine:
        if (breakMidpoint != null) {
          candidate = breakMidpoint - (timing.durationMinutes ~/ 2);
        } else if (routineBounds.hasRoutine) {
          final int earliestStart = routineBounds.earliestStart!;
          final int latestEnd = routineBounds.latestEnd!;
          final int midpoint =
              (earliestStart + latestEnd) ~/ 2;
          candidate = midpoint - (timing.durationMinutes ~/ 2);
        }
        break;
      case SmartActivityRoutinePlacement.afterEnd:
        if (routineBounds.hasRoutine) {
          final int latestEnd = routineBounds.latestEnd!;
          candidate = math.max(
            candidate,
            latestEnd + _afterRoutineGapMinutes(plan),
          );
        }
        break;
      case SmartActivityRoutinePlacement.outsideRoutine:
        if (routineBounds.hasRoutine) {
          final int earliestStart = routineBounds.earliestStart!;
          final int latestEnd = routineBounds.latestEnd!;
          if (_isLateWindow(window)) {
            candidate = math.max(candidate, latestEnd + 30);
          } else {
            candidate = earliestStart - timing.durationMinutes - 15;
          }
        }
        break;
      case SmartActivityRoutinePlacement.none:
      case SmartActivityRoutinePlacement.anytime:
        break;
    }

    return _normalizeCandidateMinutes(candidate);
  }

  int _windowAnchorMinutes(SmartActivityTimeWindow window) {
    return switch (window) {
      SmartActivityTimeWindow.earlyMorning => 6 * 60,
      SmartActivityTimeWindow.morning => 8 * 60,
      SmartActivityTimeWindow.midday => 12 * 60 + 30,
      SmartActivityTimeWindow.afternoon => 16 * 60,
      SmartActivityTimeWindow.evening => 18 * 60 + 30,
      SmartActivityTimeWindow.night => 21 * 60,
    };
  }

  int _normalizeCandidateMinutes(int rawMinutes) {
    final int clamped = rawMinutes.clamp(
      _earliestCandidateMinutes,
      _latestCandidateMinutes,
    ) as int;
    return ((clamped / 5).round()) * 5;
  }

  int _leadGapMinutes(SmartActivityLocalPlan plan) {
    return switch (plan.effortLevel) {
      SmartActivityEffortLevel.high => 30,
      SmartActivityEffortLevel.medium => 20,
      SmartActivityEffortLevel.low => 15,
    };
  }

  int _afterRoutineGapMinutes(SmartActivityLocalPlan plan) {
    return switch (plan.effortLevel) {
      SmartActivityEffortLevel.high => 60,
      SmartActivityEffortLevel.medium => 45,
      SmartActivityEffortLevel.low => 30,
    };
  }

  bool _isLateWindow(SmartActivityTimeWindow window) {
    return window == SmartActivityTimeWindow.evening ||
        window == SmartActivityTimeWindow.night;
  }

  _RoutineBounds _summarizeRoutineBounds({
    required List<int> selectedDays,
    required Map<int, _RoutineWindow> routineWindowsByDay,
  }) {
    int? earliestStart;
    int? latestEnd;
    for (final int day in selectedDays) {
      final _RoutineWindow? routine = routineWindowsByDay[day];
      if (routine == null) {
        continue;
      }
      earliestStart = earliestStart == null
          ? routine.startMinutes
          : math.min(earliestStart, routine.startMinutes);
      latestEnd = latestEnd == null
          ? routine.endMinutes
          : math.max(latestEnd, routine.endMinutes);
    }

    return _RoutineBounds(
      earliestStart: earliestStart,
      latestEnd: latestEnd,
    );
  }

  int? _representativeBreakMidpoint(
    AppSettingsModel settings,
    List<int> selectedDays,
  ) {
    final List<int> midpoints = <int>[];
    for (final WeeklyRoutineDayProfile day in settings.normalizedWeeklyRoutine) {
      if (!selectedDays.contains(day.weekday)) {
        continue;
      }
      final int? restStart = day.restStartMinutes;
      final int? restEnd = day.restEndMinutes;
      if (restStart == null || restEnd == null || restEnd <= restStart) {
        continue;
      }
      midpoints.add((restStart + restEnd) ~/ 2);
    }
    if (midpoints.isEmpty) {
      return null;
    }
    final int total = midpoints.fold(0, (int sum, int item) => sum + item);
    return total ~/ midpoints.length;
  }

  String _buildContextualBaseReason({
    required SmartActivitySuggestion suggestion,
    required String localeCode,
    required AppSettingsModel settings,
    required int timeMinutes,
    required bool hasRoutineContext,
    required SmartActivityRoutinePlacement routinePlacement,
  }) {
    final bool noContext =
        !settings.hasConfiguredWeeklyRoutine &&
        !settings.hasExtraActivitiesNote;
    if (noContext) {
      return _buildNeutralReason(
        suggestion: suggestion,
        localeCode: localeCode,
        timeMinutes: timeMinutes,
      );
    }

    final String timeLabel = formatMinutesAsTime(timeMinutes);
    if (localeCode != 'id') {
      return switch (routinePlacement) {
        SmartActivityRoutinePlacement.beforeStart =>
          'This time is placed at $timeLabel so it stays before your main routine begins.',
        SmartActivityRoutinePlacement.duringRoutine =>
          'This time is placed at $timeLabel so it still fits naturally into the middle of your day.',
        SmartActivityRoutinePlacement.afterEnd =>
          'This time is placed at $timeLabel so it starts after your main routine is done.',
        SmartActivityRoutinePlacement.outsideRoutine =>
          'This time is placed at $timeLabel so it stays outside your main routine block.',
        SmartActivityRoutinePlacement.none ||
        SmartActivityRoutinePlacement.anytime =>
          hasRoutineContext
              ? 'This time is placed at $timeLabel because it is the most natural slot from the preferred time windows that still fits your day.'
              : 'This time is placed at $timeLabel as the most natural starting point from the preferred time windows.',
      };
    }

    return switch (routinePlacement) {
      SmartActivityRoutinePlacement.beforeStart =>
        'Waktu $timeLabel dipilih agar aktivitas ini tetap muat sebelum rutinitas utamamu dimulai.',
      SmartActivityRoutinePlacement.duringRoutine =>
        'Waktu $timeLabel dipilih agar aktivitas ini tetap terasa alami di tengah harimu.',
      SmartActivityRoutinePlacement.afterEnd =>
        'Waktu $timeLabel dipilih supaya aktivitas ini dimulai setelah rutinitas utamamu selesai.',
      SmartActivityRoutinePlacement.outsideRoutine =>
        'Waktu $timeLabel dipilih agar aktivitas ini tetap berada di luar blok rutinitas utamamu.',
      SmartActivityRoutinePlacement.none ||
      SmartActivityRoutinePlacement.anytime =>
        hasRoutineContext
            ? 'Waktu $timeLabel dipilih dari slot yang paling masuk akal di antara jam umum aktivitas ini, lalu disesuaikan dengan ritme harimu.'
            : 'Waktu $timeLabel dipakai sebagai titik mulai yang paling umum untuk aktivitas ini.',
    };
  }

  Map<int, List<_ScheduledBlock>> _groupBlocksByDay(
    List<int> selectedDays,
    List<_ScheduledBlock> scheduledBlocks,
  ) {
    final Map<int, List<_ScheduledBlock>> blocksByDay =
        <int, List<_ScheduledBlock>>{
          for (final int day in selectedDays) day: <_ScheduledBlock>[],
        };

    for (final _ScheduledBlock block in scheduledBlocks) {
      for (final int day in block.selectedDays) {
        final List<_ScheduledBlock>? bucket = blocksByDay[day];
        if (bucket != null) {
          bucket.add(block);
        }
      }
    }

    for (final List<_ScheduledBlock> dayBlocks in blocksByDay.values) {
      dayBlocks.sort(
        (_ScheduledBlock a, _ScheduledBlock b) =>
            a.startMinutes.compareTo(b.startMinutes),
      );
    }

    return blocksByDay;
  }

  List<_ConflictHit> _collectConflicts({
    required int baseTimeMinutes,
    required List<int> selectedDays,
    required _ActivityTiming newTiming,
    required Map<int, List<_ScheduledBlock>> blocksByDay,
  }) {
    final List<_ConflictHit> conflicts = <_ConflictHit>[];
    for (final int day in selectedDays) {
      final List<_ScheduledBlock> dayBlocks =
          blocksByDay[day] ?? const <_ScheduledBlock>[];
      for (final _ScheduledBlock block in dayBlocks) {
        final _ConflictHit? conflict = _detectConflict(
          candidateStartMinutes: baseTimeMinutes,
          day: day,
          newTiming: newTiming,
          existingBlock: block,
        );
        if (conflict != null) {
          conflicts.add(conflict);
        }
      }
    }
    return conflicts;
  }

  List<_ConflictHit> _collectHardOverlapConflicts({
    required int baseTimeMinutes,
    required List<int> selectedDays,
    required _ActivityTiming newTiming,
    required Map<int, List<_ScheduledBlock>> blocksByDay,
  }) {
    final int candidateEndMinutes = baseTimeMinutes + newTiming.durationMinutes;
    final List<_ConflictHit> conflicts = <_ConflictHit>[];

    for (final int day in selectedDays) {
      final List<_ScheduledBlock> dayBlocks =
          blocksByDay[day] ?? const <_ScheduledBlock>[];
      for (final _ScheduledBlock block in dayBlocks) {
        final int blockStart = block.startMinutes;
        final int blockEnd = block.startMinutes + block.timing.durationMinutes;
        final bool overlaps =
            baseTimeMinutes < blockEnd && candidateEndMinutes > blockStart;
        if (!overlaps) {
          continue;
        }
        conflicts.add(
          _ConflictHit(
            day: day,
            conflictingTitle: block.title,
            nextCandidateMinutes: blockEnd,
          ),
        );
      }
    }

    return conflicts;
  }

  _ResolvedRecommendation? _findBestFreeSlot({
    required int baseTimeMinutes,
    required List<int> selectedDays,
    required _ActivityTiming newTiming,
    required Map<int, List<_ScheduledBlock>> blocksByDay,
    required List<_ConflictHit> baseConflicts,
    required SmartActivityRoutinePlacement routinePlacement,
    required Map<int, _RoutineWindow> routineWindowsByDay,
  }) {
    _ResolvedRecommendation? best;

    for (
      int candidate = _earliestCandidateMinutes;
      candidate <= _latestCandidateMinutes;
      candidate += 5
    ) {
      if (candidate + newTiming.durationMinutes > _dayMinutes) {
        continue;
      }
      if (_violatesRoutinePlacement(
        candidateStartMinutes: candidate,
        selectedDays: selectedDays,
        newTiming: newTiming,
        routinePlacement: routinePlacement,
        routineWindowsByDay: routineWindowsByDay,
      )) {
        continue;
      }

      final List<_ConflictHit> hardConflicts = _collectHardOverlapConflicts(
        baseTimeMinutes: candidate,
        selectedDays: selectedDays,
        newTiming: newTiming,
        blocksByDay: blocksByDay,
      );
      if (hardConflicts.isNotEmpty) {
        continue;
      }

      final List<_ConflictHit> conflicts = _collectConflicts(
        baseTimeMinutes: candidate,
        selectedDays: selectedDays,
        newTiming: newTiming,
        blocksByDay: blocksByDay,
      );
      if (conflicts.isNotEmpty) {
        continue;
      }

      final double score = _scoreCandidate(
        candidateStartMinutes: candidate,
        baseTimeMinutes: baseTimeMinutes,
        selectedDays: selectedDays,
        newTiming: newTiming,
        blocksByDay: blocksByDay,
      );
      final _ResolvedRecommendation resolved = _ResolvedRecommendation(
        timeMinutes: candidate,
        conflict: _primaryConflict(baseConflicts),
        score: score,
      );

      if (_isBetterCandidate(
        resolved,
        best,
        baseTimeMinutes: baseTimeMinutes,
      )) {
        best = resolved;
      }
    }

    return best;
  }

  bool _violatesRoutinePlacement({
    required int candidateStartMinutes,
    required List<int> selectedDays,
    required _ActivityTiming newTiming,
    required SmartActivityRoutinePlacement routinePlacement,
    required Map<int, _RoutineWindow> routineWindowsByDay,
  }) {
    if (routinePlacement == SmartActivityRoutinePlacement.none ||
        routinePlacement == SmartActivityRoutinePlacement.anytime) {
      return false;
    }

    final int candidateEndMinutes =
        candidateStartMinutes + newTiming.durationMinutes;
    for (final int day in selectedDays) {
      final _RoutineWindow? routine = routineWindowsByDay[day];
      if (routine == null) {
        continue;
      }

      switch (routinePlacement) {
        case SmartActivityRoutinePlacement.none:
        case SmartActivityRoutinePlacement.anytime:
          break;
        case SmartActivityRoutinePlacement.beforeStart:
          if (candidateEndMinutes > routine.startMinutes) {
            return true;
          }
          break;
        case SmartActivityRoutinePlacement.duringRoutine:
          if (candidateStartMinutes < routine.startMinutes ||
              candidateEndMinutes > routine.endMinutes) {
            return true;
          }
          break;
        case SmartActivityRoutinePlacement.afterEnd:
          if (candidateStartMinutes < routine.endMinutes) {
            return true;
          }
          break;
        case SmartActivityRoutinePlacement.outsideRoutine:
          if (!(candidateEndMinutes <= routine.startMinutes ||
              candidateStartMinutes >= routine.endMinutes)) {
            return true;
          }
          break;
      }
    }

    return false;
  }

  double _scoreCandidate({
    required int candidateStartMinutes,
    required int baseTimeMinutes,
    required List<int> selectedDays,
    required _ActivityTiming newTiming,
    required Map<int, List<_ScheduledBlock>> blocksByDay,
  }) {
    double score = (candidateStartMinutes - baseTimeMinutes).abs() * 1.8;

    for (final int day in selectedDays) {
      final _DayNeighbors neighbors = _findNeighborsForDay(
        candidateStartMinutes: candidateStartMinutes,
        dayBlocks: blocksByDay[day] ?? const <_ScheduledBlock>[],
      );

      if (neighbors.previous != null) {
        final _ScheduledBlock previous = neighbors.previous!;
        final int minimumGapEnd =
            previous.startMinutes +
            previous.timing.durationMinutes +
            _gapBetween(previous.timing, newTiming);
        final int extraGap = candidateStartMinutes - minimumGapEnd;
        score += math.min(extraGap / 6, 14);
        score -= _flowPairBonus(previous.timing.familyKey, newTiming.familyKey);
      } else {
        score += 2;
      }

      if (neighbors.next != null) {
        final _ScheduledBlock next = neighbors.next!;
        final int latestSafeStart =
            next.startMinutes -
            _gapBetween(newTiming, next.timing) -
            newTiming.durationMinutes;
        final int extraGap = latestSafeStart - candidateStartMinutes;
        score += math.min(extraGap / 6, 14);
        score -= _flowPairBonus(newTiming.familyKey, next.timing.familyKey);
      } else {
        score += 2;
      }
    }

    return score / math.max(1, selectedDays.length);
  }

  _DayNeighbors _findNeighborsForDay({
    required int candidateStartMinutes,
    required List<_ScheduledBlock> dayBlocks,
  }) {
    _ScheduledBlock? previous;
    _ScheduledBlock? next;

    for (final _ScheduledBlock block in dayBlocks) {
      if (block.startMinutes <= candidateStartMinutes) {
        previous = block;
        continue;
      }
      next = block;
      break;
    }

    return _DayNeighbors(previous: previous, next: next);
  }

  _ConflictHit? _primaryConflict(List<_ConflictHit> conflicts) {
    if (conflicts.isEmpty) {
      return null;
    }
    _ConflictHit best = conflicts.first;
    for (final _ConflictHit conflict in conflicts.skip(1)) {
      if (conflict.nextCandidateMinutes > best.nextCandidateMinutes) {
        best = conflict;
      }
    }
    return best;
  }

  bool _isBetterCandidate(
    _ResolvedRecommendation candidate,
    _ResolvedRecommendation? currentBest, {
    required int baseTimeMinutes,
  }) {
    if (currentBest == null) {
      return true;
    }

    final double scoreDelta = candidate.score - currentBest.score;
    if (scoreDelta < -0.01) {
      return true;
    }
    if (scoreDelta > 0.01) {
      return false;
    }

    final int candidateDistance = (candidate.timeMinutes - baseTimeMinutes)
        .abs();
    final int currentDistance = (currentBest.timeMinutes - baseTimeMinutes)
        .abs();
    if (candidateDistance != currentDistance) {
      return candidateDistance < currentDistance;
    }

    return candidate.timeMinutes < currentBest.timeMinutes;
  }

  _ConflictHit? _detectConflict({
    required int candidateStartMinutes,
    required int day,
    required _ActivityTiming newTiming,
    required _ScheduledBlock existingBlock,
  }) {
    final int candidateEndMinutes =
        candidateStartMinutes + newTiming.durationMinutes;
    final int existingStartMinutes = existingBlock.startMinutes;
    final int existingEndMinutes =
        existingStartMinutes + existingBlock.timing.durationMinutes;

    final int gapIfNewFirst = _gapBetween(newTiming, existingBlock.timing);
    if (candidateEndMinutes + gapIfNewFirst <= existingStartMinutes) {
      return null;
    }

    final int gapIfExistingFirst = _gapBetween(existingBlock.timing, newTiming);
    if (existingEndMinutes + gapIfExistingFirst <= candidateStartMinutes) {
      return null;
    }

    return _ConflictHit(
      day: day,
      conflictingTitle: existingBlock.title,
      nextCandidateMinutes: existingEndMinutes + gapIfExistingFirst,
    );
  }

  List<_ScheduledBlock> _buildExtraBusyBlocks(
    String? rawNote, {
    required Set<int> fallbackWeekdays,
    required String localeCode,
  }) {
    final List<UserBusyWindow> windows = _noteParser.parseWithFallback(
      rawNote,
      fallbackWeekdays: fallbackWeekdays,
    );
    if (windows.isEmpty) {
      return const <_ScheduledBlock>[];
    }

    final SmartActivitySuggestion? inferred = _advisor.analyze(
      rawNote ?? '',
      localeCode: localeCode,
    );
    final _ActivityTiming timing = inferred == null
        ? const _ActivityTiming(
            familyKey: 'produktif',
            durationMinutes: 120,
            gapAfterMinutes: 10,
          )
        : _timingForSuggestion(inferred);

    return windows
        .map(
          (UserBusyWindow window) => _ScheduledBlock(
            title: (window.label).trim().isEmpty
                ? (localeCode == 'id' ? 'Aktivitas lain' : 'Other activity')
                : window.label.trim(),
            selectedDays: window.weekdays,
            startMinutes: window.startMinutes,
            timing: _ActivityTiming(
              familyKey: timing.familyKey,
              durationMinutes: math.max(
                timing.durationMinutes,
                window.endMinutes - window.startMinutes,
              ),
              gapAfterMinutes: timing.gapAfterMinutes,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<_ScheduledBlock> _buildRoutineBlocks(
    AppSettingsModel settings, {
    required Set<int> targetDays,
    required String localeCode,
  }) {
    final List<_ScheduledBlock> blocks = <_ScheduledBlock>[];
    for (final WeeklyRoutineDayProfile day in settings.normalizedWeeklyRoutine) {
      if (!targetDays.contains(day.weekday)) {
        continue;
      }

      final int? occupiedStart = day.departureMinutes ?? day.startMinutes;
      final int? occupiedEnd = day.returnMinutes ?? day.endMinutes;
      if (occupiedStart == null ||
          occupiedEnd == null ||
          occupiedEnd <= occupiedStart) {
        continue;
      }

      final String title = _routineLabel(day.kind, localeCode: localeCode);
      if (title.isEmpty) {
        continue;
      }

      blocks.add(
        _ScheduledBlock(
          title: title,
          selectedDays: <int>{day.weekday},
          startMinutes: occupiedStart,
          timing: _ActivityTiming(
            familyKey: 'kerja',
            durationMinutes: occupiedEnd - occupiedStart,
            gapAfterMinutes: 0,
          ),
        ),
      );
    }
    return blocks;
  }

  Map<int, _RoutineWindow> _buildRoutineWindows(
    AppSettingsModel settings, {
    required Set<int> targetDays,
  }) {
    final Map<int, _RoutineWindow> windows = <int, _RoutineWindow>{};
    for (final WeeklyRoutineDayProfile day in settings.normalizedWeeklyRoutine) {
      if (!targetDays.contains(day.weekday)) {
        continue;
      }

      final int? occupiedStart = day.departureMinutes ?? day.startMinutes;
      final int? occupiedEnd = day.returnMinutes ?? day.endMinutes;
      if (occupiedStart == null ||
          occupiedEnd == null ||
          occupiedEnd <= occupiedStart) {
        continue;
      }

      windows[day.weekday] = _RoutineWindow(
        startMinutes: occupiedStart,
        endMinutes: occupiedEnd,
      );
    }
    return windows;
  }

  Set<int> _activeRoutineDays(AppSettingsModel settings) {
    final Set<int> active = settings.normalizedWeeklyRoutine
        .where((day) => day.kind != WeeklyRoutineDayKind.off)
        .map((day) => day.weekday)
        .toSet();
    return active.isEmpty ? <int>{1, 2, 3, 4, 5, 6, 7} : active;
  }

  String _routineLabel(
    WeeklyRoutineDayKind kind, {
    required String localeCode,
  }) {
    final bool isId = localeCode == 'id';
    return switch (kind) {
      WeeklyRoutineDayKind.off => '',
      WeeklyRoutineDayKind.work => isId ? 'Jam kerja' : 'Work hours',
      WeeklyRoutineDayKind.college => isId ? 'Jam kuliah' : 'College hours',
      WeeklyRoutineDayKind.school => isId ? 'Jam sekolah' : 'School hours',
      WeeklyRoutineDayKind.flexible => isId ? 'Rutinitas utama' : 'Main routine',
      WeeklyRoutineDayKind.custom => isId ? 'Rutinitas utama' : 'Main routine',
      WeeklyRoutineDayKind.unspecified => isId ? 'Rutinitas utama' : 'Main routine',
    };
  }

  _ActivityTiming _timingForExistingActivity(
    ActivityModel activity, {
    required String localeCode,
  }) {
    final SmartActivitySuggestion? inferred = _advisor.analyze(
      activity.title,
      localeCode: localeCode,
    );
    if (inferred != null) {
      return _timingForSuggestion(inferred);
    }

    return _ActivityTiming(
      familyKey: 'umum',
      durationMinutes: 20,
      gapAfterMinutes: 5,
    );
  }

  _ActivityTiming _timingForSuggestion(SmartActivitySuggestion suggestion) {
    final String familyKey = _familyKeyFromSuggestion(suggestion);

    switch (familyKey) {
      case 'olahraga':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 45,
          gapAfterMinutes: 15,
        );
      case 'hidrasi':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 5,
          gapAfterMinutes: 5,
        );
      case 'makan':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 20,
          gapAfterMinutes: 10,
        );
      case 'perawatan-diri':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 15,
          gapAfterMinutes: 5,
        );
      case 'kesehatan':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 10,
          gapAfterMinutes: 5,
        );
      case 'tidur':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 30,
          gapAfterMinutes: 10,
        );
      case 'rehat':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 20,
          gapAfterMinutes: 5,
        );
      case 'belajar':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 60,
          gapAfterMinutes: 10,
        );
      case 'kerja':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 60,
          gapAfterMinutes: 10,
        );
      case 'rumah':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 30,
          gapAfterMinutes: 10,
        );
      case 'sosial':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 45,
          gapAfterMinutes: 10,
        );
      case 'hiburan':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 45,
          gapAfterMinutes: 10,
        );
      case 'produktif':
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 45,
          gapAfterMinutes: 10,
        );
      default:
        return _ActivityTiming(
          familyKey: familyKey,
          durationMinutes: 20,
          gapAfterMinutes: 5,
        );
    }
  }

  String _familyKeyFromSuggestion(SmartActivitySuggestion suggestion) {
    final String source = [
      suggestion.familyLabel,
      suggestion.keyword,
      suggestion.category.name,
    ].join(' ').toLowerCase();

    if (_containsAny(source, <String>[
      'olahraga',
      'exercise',
      'workout',
      'gym',
      'lari',
      'jogging',
      'renang',
      'swim',
    ])) {
      return 'olahraga';
    }
    if (_containsAny(source, <String>[
      'hidrasi',
      'hydration',
      'minum air',
      'air putih',
    ])) {
      return 'hidrasi';
    }
    if (_containsAny(source, <String>[
      'makan',
      'meal',
      'sarapan',
      'breakfast',
      'lunch',
      'dinner',
    ])) {
      return 'makan';
    }
    if (_containsAny(source, <String>[
      'perawatan diri',
      'self care',
      'mandi',
      'skincare',
      'groom',
    ])) {
      return 'perawatan-diri';
    }
    if (_containsAny(source, <String>['tidur', 'sleep', 'nap'])) {
      return 'tidur';
    }
    if (_containsAny(source, <String>[
      'rehat',
      'rest',
      'istirahat',
      'meditasi',
      'meditation',
    ])) {
      return 'rehat';
    }
    if (_containsAny(source, <String>[
      'belajar',
      'study',
      'kursus',
      'reading',
      'baca',
    ])) {
      return 'belajar';
    }
    if (_containsAny(source, <String>[
      'kerja',
      'work',
      'meeting',
      'kelas',
      'kuliah',
      'school',
    ])) {
      return 'kerja';
    }
    if (_containsAny(source, <String>[
      'rumah',
      'home',
      'bersih',
      'laundry',
      'beberes',
    ])) {
      return 'rumah';
    }
    if (_containsAny(source, <String>[
      'sosial',
      'social',
      'teman',
      'keluarga',
    ])) {
      return 'sosial';
    }
    if (_containsAny(source, <String>[
      'hiburan',
      'leisure',
      'nonton',
      'game',
      'film',
    ])) {
      return 'hiburan';
    }
    if (_containsAny(source, <String>['kesehatan', 'health'])) {
      return 'kesehatan';
    }
    if (_containsAny(source, <String>['produktif', 'productive'])) {
      return 'produktif';
    }
    return 'umum';
  }

  int _gapBetween(_ActivityTiming earlier, _ActivityTiming later) {
    if (earlier.familyKey == 'makan' && later.familyKey == 'olahraga') {
      return 40;
    }
    if (earlier.familyKey == 'olahraga' && later.familyKey == 'makan') {
      return 15;
    }
    return earlier.gapAfterMinutes;
  }

  double _flowPairBonus(String earlierFamily, String laterFamily) {
    switch ('$earlierFamily->$laterFamily') {
      case 'olahraga->perawatan-diri':
        return 14;
      case 'olahraga->makan':
        return 10;
      case 'perawatan-diri->makan':
        return 10;
      case 'makan->kerja':
      case 'makan->belajar':
      case 'makan->rumah':
      case 'makan->sosial':
        return 12;
      case 'kerja->makan':
      case 'belajar->makan':
      case 'rumah->makan':
        return 8;
      case 'perawatan-diri->kerja':
      case 'perawatan-diri->belajar':
      case 'perawatan-diri->sosial':
        return 9;
      case 'kerja->rehat':
      case 'belajar->rehat':
      case 'rumah->rehat':
        return 9;
      case 'kerja->hiburan':
      case 'belajar->hiburan':
        return 7;
      case 'hiburan->tidur':
      case 'rehat->tidur':
      case 'kerja->tidur':
      case 'belajar->tidur':
        return 10;
      case 'makan->olahraga':
        return 5;
      default:
        return 0;
    }
  }

  String _buildAdjustedReason({
    required String? baseReason,
    required String localeCode,
    required int baseTimeMinutes,
    required _ResolvedRecommendation resolved,
  }) {
    final _ConflictHit? conflict = resolved.conflict;
    if (conflict == null) {
      return baseReason ?? '';
    }

    final String baseTimeLabel = formatMinutesAsTime(baseTimeMinutes);
    final String adjustedTimeLabel = formatMinutesAsTime(resolved.timeMinutes);
    final String dayLabel = weekdayShortLabel(conflict.day, localeCode);
    final String blockingTitle = _compactConflictLabel(
      conflict.conflictingTitle,
      localeCode: localeCode,
    );

    final String adjustment = localeCode == 'id'
        ? 'Pada hari $dayLabel, pukul $baseTimeLabel sudah digunakan untuk $blockingTitle. Karena itu, rekomendasi waktu disesuaikan menjadi pukul $adjustedTimeLabel agar memanfaatkan slot yang masih tersedia, tetap selaras dengan alur aktivitas, dan memiliki jeda yang aman.'
        : 'On $dayLabel, $baseTimeLabel is already used for $blockingTitle. The recommendation was adjusted to $adjustedTimeLabel to keep the schedule organized and maintain a safer gap.';

    final String trimmedBaseReason = (baseReason ?? '').trim();
    if (trimmedBaseReason.isEmpty) {
      return adjustment;
    }
    return '$trimmedBaseReason $adjustment';
  }

  bool _containsAny(String source, List<String> patterns) {
    for (final String pattern in patterns) {
      if (source.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  String _compactConflictLabel(
    String raw, {
    required String localeCode,
  }) {
    final String fallback = localeCode == 'id'
        ? 'aktivitas lain'
        : 'another activity';
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    final String lower = trimmed.toLowerCase();
    int cutIndex = lower.indexOf(' jam ');
    if (cutIndex < 0) {
      final RegExpMatch? match = RegExp(
        r'\b([01]?\d|2[0-3])[.:]([0-5]?\d)\b',
      ).firstMatch(lower);
      if (match != null) {
        cutIndex = match.start;
      }
    }

    String label = cutIndex > 0 ? trimmed.substring(0, cutIndex).trim() : trimmed;
    label = label.replaceFirst(
      RegExp(r'^(aku|saya)\s+', caseSensitive: false),
      '',
    ).trim();
    if (label.isEmpty) {
      return fallback;
    }
    if (label.length > 28) {
      return '${label.substring(0, 28).trim()}...';
    }
    return label;
  }

  static const int _earliestCandidateMinutes = 5 * 60;
  static const int _dayMinutes = 24 * 60;
  static const int _latestCandidateMinutes = 23 * 60 + 55;
}

class _ScheduledBlock {
  const _ScheduledBlock({
    required this.title,
    required this.selectedDays,
    required this.startMinutes,
    required this.timing,
  });

  final String title;
  final Set<int> selectedDays;
  final int startMinutes;
  final _ActivityTiming timing;
}

class _ActivityTiming {
  const _ActivityTiming({
    required this.familyKey,
    required this.durationMinutes,
    required this.gapAfterMinutes,
  });

  final String familyKey;
  final int durationMinutes;
  final int gapAfterMinutes;
}

class _ConflictHit {
  const _ConflictHit({
    required this.day,
    required this.conflictingTitle,
    required this.nextCandidateMinutes,
  });

  final int day;
  final String conflictingTitle;
  final int nextCandidateMinutes;
}

class _DayNeighbors {
  const _DayNeighbors({required this.previous, required this.next});

  final _ScheduledBlock? previous;
  final _ScheduledBlock? next;
}

class _ResolvedRecommendation {
  const _ResolvedRecommendation({
    required this.timeMinutes,
    required this.conflict,
    required this.score,
  });

  final int timeMinutes;
  final _ConflictHit? conflict;
  final double score;
}

class _RoutineWindow {
  const _RoutineWindow({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;
}

class _RoutineBounds {
  const _RoutineBounds({
    required this.earliestStart,
    required this.latestEnd,
  });

  final int? earliestStart;
  final int? latestEnd;

  bool get hasRoutine => earliestStart != null && latestEnd != null;
}
