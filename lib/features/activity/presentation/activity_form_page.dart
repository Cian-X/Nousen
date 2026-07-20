import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/activity/application/activity_day_recommendation_engine.dart';
import 'package:liburan_create/features/activity/application/activity_form_ml_service.dart';
import 'package:liburan_create/features/activity/application/activity_time_sync_engine.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';
import 'package:liburan_create/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class CreateActivityPage extends ConsumerStatefulWidget {
  const CreateActivityPage({super.key, this.args});

  final CreateActivityArgs? args;

  @override
  ConsumerState<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends ConsumerState<CreateActivityPage> {
  static const SmartActivityAdvisor _smartAdvisor = SmartActivityAdvisor();
  static const ActivityDayRecommendationEngine _dayRecommendationEngine =
      ActivityDayRecommendationEngine();
  static const ActivityTimeSyncEngine _timeSyncEngine =
      ActivityTimeSyncEngine();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subActivityController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final Uuid _uuid = const Uuid();
  static const List<int> _preReminderOptions = <int>[0, 5, 10, 15, 30, 60];

  late Set<int> _selectedDays;
  late List<String> _subActivities;
  late int _timeMinutes;
  late int _preReminderMinutes;
  late bool _isNotificationEnabled;

  SmartActivitySuggestion? _geminiSuggestion;
  String? _geminiAnalyzedTitle;
  String? _geminiError;
  bool _geminiCanRetry = false;
  bool _isGeminiLoading = false;
  bool _saving = false;
  bool _aiSuggestionDismissed = false;

  ActivityModel? get _existingActivity => widget.args?.activity;

  bool get _canSubmitForm =>
      _titleController.text.trim().isNotEmpty && _selectedDays.isNotEmpty;

  void _handleTitleChanged() {
    if (!mounted) {
      return;
    }
    if (_geminiSuggestion != null || _geminiError != null) {
      _geminiSuggestion = null;
      _geminiAnalyzedTitle = null;
      _geminiError = null;
      _geminiCanRetry = false;
      _isGeminiLoading = false;
    }
    _aiSuggestionDismissed = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final ActivityModel? existingActivity = _existingActivity;
    _titleController.text = existingActivity?.title ?? '';
    _selectedDays =
        (existingActivity?.selectedDays.toSet() ??
        <int>{DateTime.now().weekday});
    _subActivities = List<String>.from(
      existingActivity?.subActivities ?? <String>[],
    );
    final int fallbackMinutes = _nextRoundedTimeMinutes();
    _timeMinutes = existingActivity?.timeMinutes ?? fallbackMinutes;
    _preReminderMinutes = existingActivity?.preReminderMinutes ?? 0;
    _isNotificationEnabled = existingActivity?.isNotificationEnabled ?? true;
    _titleController.addListener(_handleTitleChanged);
    _titleFocusNode.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleTitleChanged);
    _titleController.dispose();
    _subActivityController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  int _nextRoundedTimeMinutes() {
    final DateTime now = DateTime.now();
    int minute = ((now.minute + 14) ~/ 15) * 15;
    int hour = now.hour;
    if (minute == 60) {
      minute = 0;
      hour = (hour + 1) % 24;
    }
    return timeOfDayToMinutes(hour, minute);
  }

  AppSettingsModel _fallbackSettings() {
    return AppSettingsModel(
      morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
      endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
      localeCode: AppConstants.localeId,
    );
  }

  SmartActivitySuggestion? _resolveNormalizedSuggestion({
    required String localeCode,
  }) {
    final SmartActivitySuggestion? localSuggestion = _smartAdvisor.analyze(
      _titleController.text,
      localeCode: localeCode,
    );
    final SmartActivitySuggestion? baseSuggestion =
        _geminiSuggestion ?? localSuggestion;
    return baseSuggestion == null
        ? null
        : (baseSuggestion.localPlan == null && localSuggestion?.localPlan != null
              ? baseSuggestion.copyWith(localPlan: localSuggestion!.localPlan)
              : baseSuggestion);
  }

  SmartActivitySuggestion? _resolveDayAwareSuggestion({
    required SmartActivitySuggestion? normalizedSuggestion,
    required AppSettingsModel settings,
    required List<ActivityModel> existingActivities,
    required String localeCode,
  }) {
    return normalizedSuggestion == null
        ? null
        : _dayRecommendationEngine.synchronize(
            suggestion: normalizedSuggestion,
            settings: settings,
            existingActivities: existingActivities,
            localeCode: localeCode,
            editingActivityId: _existingActivity?.id,
          );
  }

  SmartActivitySuggestion? _resolveSmartSuggestion({
    required SmartActivitySuggestion? dayAwareSuggestion,
    required AppSettingsModel settings,
    required List<ActivityModel> existingActivities,
    required String localeCode,
    ActivityFormMlPrediction? mlPrediction,
  }) {
    if (dayAwareSuggestion == null) {
      return null;
    }

    SmartActivitySuggestion seededSuggestion = dayAwareSuggestion;
    final bool isHybridActive = _isCreateHybridActive(
      suggestion: dayAwareSuggestion,
      prediction: mlPrediction,
    );
    if (isHybridActive && mlPrediction?.predictedTimeMinutes != null) {
      seededSuggestion = seededSuggestion.copyWith(
        recommendedTimeMinutes: mlPrediction!.predictedTimeMinutes,
      );
    }

    final SmartActivitySuggestion synchronizedSuggestion =
        _timeSyncEngine.synchronize(
          suggestion: seededSuggestion,
          selectedDays: dayAwareSuggestion.recommendedDays.isNotEmpty
              ? dayAwareSuggestion.recommendedDays
              : _selectedDays,
          existingActivities: existingActivities,
          settings: settings,
          localeCode: localeCode,
          editingActivityId: _existingActivity?.id,
        );

    if (!isHybridActive || mlPrediction == null) {
      return synchronizedSuggestion;
    }

    return _applyHybridSuggestionCopy(
      suggestion: synchronizedSuggestion,
      settings: settings,
      existingActivities: existingActivities,
      localeCode: localeCode,
      mlPrediction: mlPrediction,
    );
  }

  ActivityFormMlRequest? _buildActivityFormMlRequest({
    required String trimmedTitle,
    required SmartActivitySuggestion? suggestion,
    required AppSettingsModel settings,
  }) {
    if (trimmedTitle.isEmpty || suggestion == null) {
      return null;
    }
    if (suggestion.type != SmartActivityType.action || suggestion.needsTitleDetail) {
      return null;
    }

    final List<WeeklyRoutineDayProfile> routineDays = settings
        .normalizedWeeklyRoutine
        .where(_isStructuredRoutineDay)
        .toList(growable: false);
    final List<int> routineStarts = routineDays
        .map((WeeklyRoutineDayProfile item) => item.startMinutes)
        .whereType<int>()
        .toList(growable: false);
    final List<int> routineEnds = routineDays
        .map((WeeklyRoutineDayProfile item) => item.endMinutes)
        .whereType<int>()
        .toList(growable: false);
    final int avgRoutineStart = _averageMinutes(routineStarts, fallback: 8 * 60);
    final int avgRoutineEnd = _averageMinutes(routineEnds, fallback: 17 * 60);
    final bool hasRoutineDays = routineDays.isNotEmpty;

    return ActivityFormMlRequest(
      activityTitle: trimmedTitle,
      recommendedTimeMinutes:
          suggestion.recommendedTimeMinutes ?? _timeMinutes,
      userWakeUpMinutes:
          settings.wakeUpMinutes ??
          _estimatedWakeUpMinutes(
            avgRoutineStart,
            hasRoutineDays: hasRoutineDays,
          ),
      userSleepMinutes:
          settings.sleepMinutes ??
          _estimatedSleepMinutes(
            avgRoutineEnd,
            hasRoutineDays: hasRoutineDays,
          ),
      numWorkdays: routineDays.length,
      avgRoutineStartMinutes: avgRoutineStart,
      avgRoutineEndMinutes: avgRoutineEnd,
    );
  }

  bool _isStructuredRoutineDay(WeeklyRoutineDayProfile day) {
    if (day.startMinutes != null || day.endMinutes != null) {
      return day.kind != WeeklyRoutineDayKind.off;
    }
    return switch (day.kind) {
      WeeklyRoutineDayKind.work ||
      WeeklyRoutineDayKind.college ||
      WeeklyRoutineDayKind.school ||
      WeeklyRoutineDayKind.custom => true,
      _ => false,
    };
  }

  int _averageMinutes(List<int> values, {required int fallback}) {
    if (values.isEmpty) {
      return fallback;
    }
    final int total = values.fold<int>(0, (int sum, int item) => sum + item);
    return total ~/ values.length;
  }

  int _estimatedWakeUpMinutes(
    int averageRoutineStart, {
    required bool hasRoutineDays,
  }) {
    if (!hasRoutineDays) {
      return 6 * 60;
    }
    return (averageRoutineStart - 90).clamp(5 * 60, 10 * 60);
  }

  int _estimatedSleepMinutes(
    int averageRoutineEnd, {
    required bool hasRoutineDays,
  }) {
    if (!hasRoutineDays) {
      return 22 * 60 + 30;
    }
    return (averageRoutineEnd + 5 * 60).clamp(20 * 60, 23 * 60 + 59);
  }

  bool _hasMeaningfulScheduleContext(
    AppSettingsModel settings,
    List<ActivityModel> existingActivities,
  ) {
    return settings.hasConfiguredWeeklyRoutine ||
        settings.hasExtraActivitiesNote ||
        existingActivities.isNotEmpty;
  }

  bool _isCreateHybridActive({
    required SmartActivitySuggestion? suggestion,
    required ActivityFormMlPrediction? prediction,
  }) {
    return suggestion != null &&
        suggestion.type == SmartActivityType.action &&
        !suggestion.needsTitleDetail &&
        prediction != null;
  }

  SmartActivitySuggestion _applyHybridSuggestionCopy({
    required SmartActivitySuggestion suggestion,
    required AppSettingsModel settings,
    required List<ActivityModel> existingActivities,
    required String localeCode,
    required ActivityFormMlPrediction mlPrediction,
  }) {
    final int? timeMinutes = suggestion.recommendedTimeMinutes;
    final String? formattedTime = timeMinutes == null
        ? null
        : formatMinutesAsTime(timeMinutes);
    final bool hasContext = _hasMeaningfulScheduleContext(
      settings,
      existingActivities,
    );
    return suggestion.copyWith(
      reason: _buildHybridReason(
        localeCode: localeCode,
        hasContext: hasContext,
        isSuitable: mlPrediction.isSuitable,
        formattedTime: formattedTime,
      ),
    );
  }

  String _buildHybridReason({
    required String localeCode,
    required bool hasContext,
    required bool isSuitable,
    required String? formattedTime,
  }) {
    final String timePart = formattedTime == null
        ? ''
        : (localeCode == 'id'
              ? ' di sekitar $formattedTime'
              : ' around $formattedTime');
    if (localeCode == 'id') {
      if (isSuitable) {
        return hasContext
            ? 'Model baca ritmemu cukup masuk. Jam awal dicoba$timePart lalu dicek lagi dengan rutinitas dan aktivitas lain.'
            : 'Model baca pola umumnya cukup masuk. Jam awal dicoba$timePart lalu tetap dirapikan dengan aturan lokal.';
      }
      return hasContext
          ? 'Model baca ritmemu masih agak padat. Jam awal digeser$timePart lalu tetap disaring supaya tidak bentrok.'
          : 'Model belum melihat pola yang benar-benar ideal. Jam yang lebih aman dicoba$timePart sambil tetap menjaga ritme umum aktivitas ini.';
    }

    if (isSuitable) {
      return hasContext
          ? 'The model sees a decent fit. The first time is tried$timePart, then checked again against your routine and other activities.'
          : 'The model sees a decent general fit. The first time is tried$timePart, then refined with the local rules.';
    }
    return hasContext
        ? 'The model reads your rhythm as a bit crowded. The first time is shifted$timePart, then filtered again to avoid clashes.'
        : 'The model does not see a clearly ideal pattern yet. A safer time is tried$timePart while keeping the general activity rhythm sensible.';
  }

  String _suggestionSourceForTitle(
    String trimmedTitle, {
    required bool usedMl,
  }) {
    if (usedMl) {
      return _geminiSuggestion != null && _geminiAnalyzedTitle == trimmedTitle
          ? 'hybrid_gemini'
          : 'hybrid_local';
    }
    return _geminiSuggestion != null && _geminiAnalyzedTitle == trimmedTitle
        ? 'gemini'
        : 'local';
  }

  String? _suggestionBadgeLabel({
    required String localeCode,
    required bool isHybridActive,
    required bool isGeminiActiveForTitle,
  }) {
    if (isHybridActive) {
      return localeCode == 'id' ? 'Saran pintar' : 'Smart suggestion';
    }
    if (isGeminiActiveForTitle) {
      return 'Gemini';
    }
    return null;
  }

  Future<void> _logRecommendationSave({
    required String title,
    required SmartActivitySuggestion? suggestion,
    required AppSettingsModel settings,
    required String source,
  }) async {
    if (suggestion == null) {
      return;
    }
    await ref.read(aiFeedbackLogServiceProvider).logRecommendationSave(
      title: title,
      suggestion: suggestion,
      source: source,
      finalTimeMinutes: _timeMinutes,
      finalSelectedDays: _selectedDays.toList()..sort(),
      settings: settings,
    );
  }

  ThemeData _pickerTheme(BuildContext context) {
    final ThemeData base = Theme.of(context);
    final Color softSurface = base.colorScheme.surface.withValues(alpha: 0.98);
    final Color softPrimaryTint = base.colorScheme.primary.withValues(
      alpha: 0.12,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primaryContainer: softPrimaryTint,
        onPrimaryContainer: base.colorScheme.onSurface.withValues(alpha: 0.9),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: softSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      datePickerTheme: base.datePickerTheme.copyWith(
        backgroundColor: softSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        headerBackgroundColor: softPrimaryTint,
        headerForegroundColor: base.colorScheme.onSurface.withValues(
          alpha: 0.88,
        ),
      ),
      timePickerTheme: base.timePickerTheme.copyWith(
        backgroundColor: softSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        hourMinuteColor: softPrimaryTint,
        dialBackgroundColor: base.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.62),
        dayPeriodColor: base.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.62,
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    final TimeOfDay initial = TimeOfDay(
      hour: _timeMinutes ~/ 60,
      minute: _timeMinutes % 60,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      helpText: localeCode == 'id' ? 'Masukkan waktu' : 'Enter time',
      hourLabelText: localeCode == 'id' ? 'Jam' : 'Hour',
      minuteLabelText: localeCode == 'id' ? 'Menit' : 'Minute',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _pickerTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _timeMinutes = timeOfDayToMinutes(picked.hour, picked.minute);
    });
  }

  Future<void> _pickPreReminder() async {
    final AppLocalizations t = AppLocalizations.of(context)!;
    int draftMinutes = _preReminderMinutes;
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final double maxHeight = MediaQuery.sizeOf(context).height * 0.72;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t.preReminderLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.86,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._preReminderOptions.map((int minutes) {
                          final bool selected = minutes == draftMinutes;
                          final String label = minutes == 0
                              ? t.preReminderOff
                              : t.preReminderMinutesValue(minutes);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setSheetState(() {
                                      draftMinutes = minutes;
                                    });
                                  },
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 46,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              label,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: selected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                          alpha: selected
                                                              ? 0.9
                                                              : 0.78,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            switchInCurve: Curves.easeOut,
                                            switchOutCurve: Curves.easeIn,
                                            transitionBuilder:
                                                (
                                                  Widget child,
                                                  Animation<double> animation,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: SizeTransition(
                                                      sizeFactor: animation,
                                                      axis: Axis.horizontal,
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                            child: selected
                                                ? Icon(
                                                    Icons.check_rounded,
                                                    key: const ValueKey<String>(
                                                      'selected',
                                                    ),
                                                    size: 18,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  )
                                                : const SizedBox(
                                                    key: ValueKey<String>(
                                                      'unselected',
                                                    ),
                                                    width: 18,
                                                    height: 18,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pop(draftMinutes),
                            child: Text(t.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _preReminderMinutes = picked;
    });
  }

  Future<void> _save() async {
    final AppLocalizations t = AppLocalizations.of(context)!;
    if (_saving) {
      return;
    }
    final String title = _titleController.text.trim();
    if (title.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.formValidationMessage)));
      return;
    }

    final AppSettingsModel settings =
        ref.read(settingsStreamProvider).value ?? _fallbackSettings();
    final String localeCode = settings.localeCode;
    final List<ActivityModel> existingActivities =
        ref.read(activitiesStreamProvider).value ?? const <ActivityModel>[];

    setState(() {
      _saving = true;
    });

    try {
      final SmartActivitySuggestion? normalizedSuggestion =
          _resolveNormalizedSuggestion(localeCode: localeCode);
      final SmartActivitySuggestion? dayAwareSuggestion =
          _resolveDayAwareSuggestion(
            normalizedSuggestion: normalizedSuggestion,
            settings: settings,
            existingActivities: existingActivities,
            localeCode: localeCode,
          );
      final ActivityFormMlRequest? mlRequest = _buildActivityFormMlRequest(
        trimmedTitle: title,
        suggestion: dayAwareSuggestion ?? normalizedSuggestion,
        settings: settings,
      );
      ActivityFormMlPrediction? mlPrediction;
      if (mlRequest != null) {
        try {
          mlPrediction = await ref.read(
            activityFormMlPredictionProvider(mlRequest).future,
          );
        } catch (_) {
          mlPrediction = null;
        }
      }
      final SmartActivitySuggestion? resolvedSuggestion =
          _resolveSmartSuggestion(
            dayAwareSuggestion: dayAwareSuggestion,
            settings: settings,
            existingActivities: existingActivities,
            localeCode: localeCode,
            mlPrediction: mlPrediction,
          );
      final bool usedHybrid = _isCreateHybridActive(
        suggestion: dayAwareSuggestion,
        prediction: mlPrediction,
      );

      final DateTime now = DateTime.now();
      final ActivityModel? existing = _existingActivity;
      final List<int> normalizedSelectedDays = _selectedDays.toList()..sort();
      final Set<int> nextDaySet = normalizedSelectedDays.toSet();
      final Set<int> previousDaySet = (existing?.selectedDays ?? const <int>[])
          .toSet();
      final bool scheduleChanged =
          existing == null ||
          nextDaySet.length != previousDaySet.length ||
          nextDaySet.any((int day) => !previousDaySet.contains(day));
      final DateTime effectiveScheduleUpdatedAt = scheduleChanged
          ? now
          : (existing.scheduleUpdatedAt ?? existing.createdAt);
      final ActivityModel model = ActivityModel(
        id: existing?.id ?? _uuid.v4(),
        title: title,
        selectedDays: normalizedSelectedDays,
        subActivities: _normalizedSubActivities(_subActivities),
        timeMinutes: _timeMinutes,
        weeklyGoal: normalizedSelectedDays.length,
        preReminderMinutes: _preReminderMinutes,
        isNotificationEnabled: _isNotificationEnabled,
        enableMorningReminder: existing?.enableMorningReminder ?? false,
        enableEndOfDayReminder: existing?.enableEndOfDayReminder ?? false,
        enablePhotoProgress: existing?.enablePhotoProgress ?? false,
        lastThreeDayRuleNotifiedDate: existing?.lastThreeDayRuleNotifiedDate,
        createdAt: existing?.createdAt ?? now,
        updatedAt: scheduleChanged ? now : existing.updatedAt,
        scheduleUpdatedAt: effectiveScheduleUpdatedAt,
      );
      unawaited(
        _logRecommendationSave(
          title: title,
          suggestion: resolvedSuggestion,
          settings: settings,
          source: _suggestionSourceForTitle(title, usedMl: usedHybrid),
        ),
      );
      await ref.read(activityActionsProvider).saveActivity(model);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeCode == 'id'
                ? 'Gagal menyimpan aktivitas. Coba lagi sebentar.'
                : 'Failed to save the activity. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _analyzeWithGemini() async {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.formValidationMessage)));
      return;
    }

    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    final geminiService = ref.read(geminiActivityServiceProvider);

    if (!geminiService.isConfigured) {
      setState(() {
        _geminiError = geminiService.setupHint;
        _geminiCanRetry = false;
      });
      return;
    }

    setState(() {
      _isGeminiLoading = true;
      _geminiError = null;
      _geminiCanRetry = false;
    });

    try {
      final SmartActivitySuggestion suggestion = await geminiService
          .analyzeActivityTitle(title: title, localeCode: localeCode);
      if (!mounted) {
        return;
      }
      if (_titleController.text.trim() != title) {
        setState(() {
          _isGeminiLoading = false;
        });
        return;
      }
      setState(() {
        _geminiSuggestion = suggestion;
        _geminiAnalyzedTitle = title;
        _isGeminiLoading = false;
        _geminiError = null;
        _geminiCanRetry = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isGeminiLoading = false;
        _geminiError = geminiService.friendlyErrorMessage(
          error,
          localeCode: localeCode,
        );
        _geminiCanRetry = geminiService.isRetryableError(error);
      });
    }
  }

  void _applySuggestedTitle(String value) {
    final String nextTitle = value.trim();
    if (nextTitle.isEmpty) {
      return;
    }
    _titleController.value = TextEditingValue(
      text: nextTitle,
      selection: TextSelection.collapsed(offset: nextTitle.length),
    );
    _titleFocusNode.requestFocus();
  }

  bool _sameSelectedDays(Iterable<int> suggestedDays) {
    final Set<int> suggested = suggestedDays.toSet();
    return suggested.length == _selectedDays.length &&
        suggested.containsAll(_selectedDays);
  }

  Future<void> _showApplySuggestionOptions(
    SmartActivitySuggestion suggestion, {
    required String localeCode,
  }) async {
    final bool canApplyTime =
        suggestion.recommendedTimeMinutes != null &&
        suggestion.recommendedTimeMinutes != _timeMinutes;
    final bool canApplyDays =
        suggestion.recommendedDays.isNotEmpty &&
        !_sameSelectedDays(suggestion.recommendedDays);

    if (!canApplyTime && !canApplyDays) {
      return;
    }

    if (canApplyTime && !canApplyDays) {
      setState(() {
        _timeMinutes = suggestion.recommendedTimeMinutes!;
      });
      return;
    }

    if (!canApplyTime && canApplyDays) {
      setState(() {
        _selectedDays = suggestion.recommendedDays.toSet();
      });
      return;
    }

    final _SuggestionApplyMode? picked = await showModalBottomSheet<
      _SuggestionApplyMode
    >(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  localeCode == 'id'
                      ? 'Terapkan rekomendasi'
                      : 'Apply recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _SuggestionApplyOptionTile(
                  label: localeCode == 'id' ? 'Jam saja' : 'Time only',
                  icon: Icons.schedule_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SuggestionApplyMode.timeOnly),
                ),
                const SizedBox(height: 10),
                _SuggestionApplyOptionTile(
                  label: localeCode == 'id' ? 'Hari saja' : 'Days only',
                  icon: Icons.date_range_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SuggestionApplyMode.daysOnly),
                ),
                const SizedBox(height: 10),
                _SuggestionApplyOptionTile(
                  label: localeCode == 'id' ? 'Hari & jam' : 'Days & time',
                  icon: Icons.event_available_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(_SuggestionApplyMode.both),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      switch (picked) {
        case _SuggestionApplyMode.timeOnly:
          _timeMinutes = suggestion.recommendedTimeMinutes!;
          break;
        case _SuggestionApplyMode.daysOnly:
          _selectedDays = suggestion.recommendedDays.toSet();
          break;
        case _SuggestionApplyMode.both:
          _timeMinutes = suggestion.recommendedTimeMinutes!;
          _selectedDays = suggestion.recommendedDays.toSet();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final settings = ref.watch(settingsStreamProvider).value ?? _fallbackSettings();
    final String localeCode = settings.localeCode;
    final geminiService = ref.read(geminiActivityServiceProvider);
    final List<ActivityModel> existingActivities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final String trimmedTitle = _titleController.text.trim();
    final SmartActivitySuggestion? normalizedSuggestion =
        _resolveNormalizedSuggestion(localeCode: localeCode);
    final SmartActivitySuggestion? dayAwareSuggestion =
        _resolveDayAwareSuggestion(
          normalizedSuggestion: normalizedSuggestion,
          settings: settings,
          existingActivities: existingActivities,
          localeCode: localeCode,
        );
    final ActivityFormMlRequest? activityFormMlRequest =
        _buildActivityFormMlRequest(
          trimmedTitle: trimmedTitle,
          suggestion: dayAwareSuggestion ?? normalizedSuggestion,
          settings: settings,
        );
    final ActivityFormMlPrediction? activityFormMlPrediction =
        activityFormMlRequest == null
        ? null
        : ref
              .watch(activityFormMlPredictionProvider(activityFormMlRequest))
              .valueOrNull;
    final SmartActivitySuggestion? smartSuggestion = _resolveSmartSuggestion(
      dayAwareSuggestion: dayAwareSuggestion,
      settings: settings,
      existingActivities: existingActivities,
      localeCode: localeCode,
      mlPrediction: activityFormMlPrediction,
    );
    final bool isGeminiActiveForTitle =
        _geminiSuggestion != null && _geminiAnalyzedTitle == trimmedTitle;
    final bool isHybridSuggestionActive = _isCreateHybridActive(
      suggestion: dayAwareSuggestion,
      prediction: activityFormMlPrediction,
    );
    final String? suggestionBadgeLabel = _suggestionBadgeLabel(
      localeCode: localeCode,
      isHybridActive: isHybridSuggestionActive,
      isGeminiActiveForTitle: isGeminiActiveForTitle,
    );
    final bool showLocalUnknownState =
        trimmedTitle.isNotEmpty &&
        smartSuggestion == null &&
        _geminiError == null;
    final bool showAiSection =
        (smartSuggestion != null && !_aiSuggestionDismissed) ||
        _geminiError != null ||
        showLocalUnknownState;
    final String titleHint = localeCode == 'id'
        ? 'Contoh: Belajar'
        : 'Example: Study';
    final TextStyle? titleInputStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      height: 1.15,
      color: theme.colorScheme.onSurface,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          _existingActivity != null ? t.editActivity : t.createActivity,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
                disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: (_canSubmitForm && !_saving) ? _save : null,
              child: Text(
                _saving ? t.saving : (_existingActivity != null ? t.save : (localeCode == 'id' ? 'Simpan Aktivitas' : 'Save Activity')),
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          final bool isLarge = constraints.maxWidth >= 1100;
          final ThemeData theme = Theme.of(context);
          final double sidePadding = isWide ? AppSpacing.lg : AppSpacing.md;
          final double contentMaxWidth = isLarge ? 980 : 760;
          final double contentWidth = constraints.maxWidth < contentMaxWidth
              ? constraints.maxWidth
              : contentMaxWidth;
          const double elementGap = 7;
          const double fieldGap = 12;
          const double sectionGap = 18;
          const double topContentGap = 0;
          final TextStyle? sectionLabelStyle = theme.textTheme.labelSmall
              ?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
              );
          final TextStyle? smallLabelStyle = theme.textTheme.labelSmall
              ?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
              );

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  topContentGap,
                  sidePadding,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      localeCode == 'id' ? 'Informasi dasar' : 'Basic info',
                      style: sectionLabelStyle,
                    ),
                    const SizedBox(height: fieldGap),
                    Text(t.activityTitle, style: smallLabelStyle),
                    const SizedBox(height: elementGap),
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      style: titleInputStyle,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: titleHint,
                        hintStyle: titleInputStyle?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        suffixIcon:
                            geminiService.isConfigured &&
                                trimmedTitle.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _TitleFieldGeminiButton(
                                  label: isGeminiActiveForTitle
                                      ? (localeCode == 'id'
                                            ? 'Refresh'
                                            : 'Refresh')
                                      : 'Gemini',
                                  isLoading: _isGeminiLoading,
                                  onTap: _isGeminiLoading
                                      ? null
                                      : _analyzeWithGemini,
                                ),
                              )
                            : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    if (showAiSection) ...<Widget>[
                      const SizedBox(height: fieldGap),
                      Text(
                        localeCode == 'id' ? 'Saran AI' : 'AI suggestion',
                        style: smallLabelStyle,
                      ),
                    ],
                    if (_geminiError != null) ...<Widget>[
                      const SizedBox(height: 8),
                      _GeminiErrorCard(
                        localeCode: localeCode,
                        message: _geminiError!,
                        canRetry: _geminiCanRetry,
                        isLoading: _isGeminiLoading,
                        onRetry: _isGeminiLoading ? null : _analyzeWithGemini,
                      ),
                    ],
                    if (smartSuggestion != null && !_aiSuggestionDismissed) ...<Widget>[
                      const SizedBox(height: elementGap),
                      _SmartActivitySuggestionCard(
                        localeCode: localeCode,
                        suggestion: smartSuggestion,
                        isGeminiResult: isGeminiActiveForTitle,
                        sourceBadgeLabel: suggestionBadgeLabel,
                        formattedTime:
                            smartSuggestion.recommendedTimeMinutes == null
                            ? null
                            : formatMinutesAsTime(
                                smartSuggestion.recommendedTimeMinutes!,
                              ),
                        currentTimeMinutes: _timeMinutes,
                        currentSelectedDays: _selectedDays,
                        onApplySuggestion: () => _showApplySuggestionOptions(
                          smartSuggestion,
                          localeCode: localeCode,
                        ),
                        onSuggestedTitleTap: _applySuggestedTitle,
                        onDismiss: () {
                          setState(() {
                            _aiSuggestionDismissed = true;
                          });
                        },
                      ),
                    ],
                    if (showLocalUnknownState) ...<Widget>[
                      const SizedBox(height: elementGap),
                      _AiUnavailableHintCard(
                        localeCode: localeCode,
                        canUseGemini: geminiService.isConfigured,
                      ),
                    ],
                    const SizedBox(height: fieldGap),
                    Text(t.subActivitiesLabel, style: smallLabelStyle),
                    const SizedBox(height: elementGap),
                     Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _subActivityController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addSubActivity(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              hintText: localeCode == 'id'
                                  ? 'Tambah sub-aktivitas...'
                                  : 'Add sub-activity...',
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonalIcon(
                          onPressed: _addSubActivity,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: Text(
                            localeCode == 'id' ? 'Tambah' : 'Add',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (_subActivities.isNotEmpty) ...<Widget>[
                      const SizedBox(height: elementGap),
                      Wrap(
                        spacing: elementGap,
                        runSpacing: elementGap,
                        children: _subActivities.map((String sub) {
                          return InputChip(
                            label: Text(sub),
                            onDeleted: () {
                              setState(() {
                                _subActivities.remove(sub);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: fieldGap),
                    Text(
                      localeCode == 'id' ? 'Jadwal' : 'Schedule',
                      style: sectionLabelStyle,
                    ),
                    const SizedBox(height: fieldGap),
                    Text(
                      localeCode == 'id' ? 'Pilih hari' : 'Choose days',
                      style: smallLabelStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _CustomSegmentedDayPicker(
                      selectedDays: _selectedDays,
                      localeCode: localeCode,
                      onChanged: (Set<int> newDays) {
                        setState(() {
                          _selectedDays = newDays;
                        });
                      },
                    ),
                    const SizedBox(height: fieldGap),
                    Text(
                      localeCode == 'id' ? 'Pilih waktu' : 'Choose time',
                      style: smallLabelStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ScheduleInlineItem(
                      icon: Icons.schedule_rounded,
                      value: formatMinutesAsTime(_timeMinutes),
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: sectionGap),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.notifications_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    localeCode == 'id' ? 'Notifikasi' : 'Notification',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _isNotificationEnabled,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isNotificationEnabled = value;
                                  });
                                },
                                activeThumbColor: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                          if (_isNotificationEnabled) ...[
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _pickPreReminder,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      _preReminderMinutes == 0
                                          ? t.preReminderOff
                                          : t.preReminderMinutesValue(_preReminderMinutes),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Icon(
                                      Icons.expand_more_rounded,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addSubActivity() {
    final String value = _subActivityController.text.trim();
    if (value.isEmpty) {
      return;
    }
    final bool exists = _subActivities.any(
      (String item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) {
      _subActivityController.clear();
      return;
    }
    setState(() {
      _subActivities.add(value);
      _subActivityController.clear();
    });
  }

  List<String> _normalizedSubActivities(List<String> values) {
    final Set<String> seen = <String>{};
    final List<String> result = <String>[];
    for (final String item in values) {
      final String clean = item.trim();
      if (clean.isEmpty) {
        continue;
      }
      final String lower = clean.toLowerCase();
      if (seen.contains(lower)) {
        continue;
      }
      seen.add(lower);
      result.add(clean);
    }
    return result;
  }
}

class _SmartActivitySuggestionCard extends StatelessWidget {
  const _SmartActivitySuggestionCard({
    required this.localeCode,
    required this.suggestion,
    required this.isGeminiResult,
    required this.currentTimeMinutes,
    required this.currentSelectedDays,
    required this.onApplySuggestion,
    required this.onSuggestedTitleTap,
    required this.onDismiss,
    this.sourceBadgeLabel,
    this.formattedTime,
  });

  final String localeCode;
  final SmartActivitySuggestion suggestion;
  final bool isGeminiResult;
  final String? sourceBadgeLabel;
  final String? formattedTime;
  final int currentTimeMinutes;
  final Set<int> currentSelectedDays;
  final VoidCallback onApplySuggestion;
  final ValueChanged<String> onSuggestedTitleTap;
  final VoidCallback onDismiss;

  bool get _isRecommendedTimeAlreadyUsed =>
      suggestion.recommendedTimeMinutes != null &&
      suggestion.recommendedTimeMinutes == currentTimeMinutes;

  bool get _isRecommendedDaysAlreadyUsed {
    if (suggestion.recommendedDays.isEmpty) {
      return true;
    }
    final Set<int> recommended = suggestion.recommendedDays.toSet();
    return recommended.length == currentSelectedDays.length &&
        recommended.containsAll(currentSelectedDays);
  }

  bool get _canApplyAnyRecommendation {
    final bool canApplyTime =
        suggestion.recommendedTimeMinutes != null &&
        !_isRecommendedTimeAlreadyUsed;
    final bool canApplyDays =
        suggestion.recommendedDays.isNotEmpty && !_isRecommendedDaysAlreadyUsed;
    return canApplyTime || canApplyDays;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isAvoidance = suggestion.type == SmartActivityType.avoidance;
    final bool needsTitleDetail = suggestion.needsTitleDetail;

    final String cardTitle = needsTitleDetail
        ? (localeCode == 'id' ? 'Gunakan judul yang lebih spesifik?' : 'Use a more specific title?')
        : (isAvoidance
            ? (localeCode == 'id' ? 'Fokus pengingat' : 'Tracking focus')
            : (localeCode == 'id' ? 'Saran waktu terbaik' : 'Best time recommendation'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  cardTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (sourceBadgeLabel != null || isGeminiResult) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sourceBadgeLabel ?? 'GEMINI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAvoidance) ...<Widget>[
            _SuggestionLine(
              title: localeCode == 'id' ? 'Pantauan harian' : 'Daily tracking',
              body: suggestion.tracking ?? '',
            ),
            const SizedBox(height: 10),
            _SuggestionLine(
              title: localeCode == 'id' ? 'Catatan singkat' : 'Quick insight',
              body: suggestion.insight ?? '',
            ),
          ] else ...<Widget>[
            if (needsTitleDetail && suggestion.detailPrompt != null) ...<Widget>[
              Text(
                suggestion.detailPrompt!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.38,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
              if (suggestion.suggestedTitles.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestion.suggestedTitles
                      .map(
                        (String item) => GestureDetector(
                          onTap: () => onSuggestedTitleTap(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ] else ...<Widget>[
              Text(
                formattedTime ?? '--:--',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: 0.96,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if ((suggestion.reason ?? '').trim().isNotEmpty)
                Text(
                  suggestion.reason!.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.38,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              if (suggestion.localPlan != null ||
                  suggestion.recommendedDays.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (suggestion.localPlan != null) ...[
                      _SuggestionMetaChip(
                        label: localeCode == 'id' ? 'Frekuensi' : 'Frequency',
                        value: _frequencyLabel(
                          suggestion.localPlan!,
                          localeCode: localeCode,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (suggestion.recommendedDays.isNotEmpty)
                      _SuggestionMetaChip(
                        label: localeCode == 'id' ? 'Hari' : 'Days',
                        value: _weekdayCompactRanges(
                          suggestion.recommendedDays,
                          localeCode: localeCode,
                        ),
                      ),
                  ],
                ),
              ],
              if (suggestion.recommendedTimeMinutes != null ||
                  suggestion.recommendedDays.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _canApplyAnyRecommendation ? onApplySuggestion : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      !_canApplyAnyRecommendation
                          ? (localeCode == 'id' ? 'Dipakai' : 'In use')
                          : (localeCode == 'id' ? 'Gunakan' : 'Use'),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

enum _SuggestionApplyMode { timeOnly, daysOnly, both }

class _SuggestionApplyOptionTile extends StatelessWidget {
  const _SuggestionApplyOptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionMetaChip extends StatelessWidget {
  const _SuggestionMetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
          height: 1.35,
        ),
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _AiUnavailableHintCard extends StatelessWidget {
  const _AiUnavailableHintCard({
    required this.localeCode,
    required this.canUseGemini,
  });

  final String localeCode;
  final bool canUseGemini;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localeCode == 'id'
                ? 'Belum ada saran otomatis'
                : 'Automatic suggestion unavailable',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canUseGemini
                ? (localeCode == 'id'
                      ? 'Aktivitas ini belum dikenali oleh saran lokal. Untuk analisis yang lebih spesifik, gunakan tombol Gemini di sisi kanan kolom judul.'
                      : 'This activity is not recognized by the local suggestion engine yet. For a more specific analysis, use the Gemini button on the right side of the title field.')
                : (localeCode == 'id'
                      ? 'Aktivitas ini belum dikenali oleh saran lokal. Coba gunakan judul yang lebih spesifik agar sistem bisa memberi saran yang relevan.'
                      : 'This activity is not recognized by the local suggestion engine yet. Try a more specific title so the system can provide a relevant suggestion.'),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeminiErrorCard extends StatelessWidget {
  const _GeminiErrorCard({
    required this.localeCode,
    required this.message,
    required this.canRetry,
    required this.isLoading,
    required this.onRetry,
  });

  final String localeCode;
  final String message;
  final bool canRetry;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localeCode == 'id' ? 'Gemini belum tersedia' : 'Gemini is unavailable',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (canRetry) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: isLoading ? null : onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(
                  localeCode == 'id' ? 'Coba lagi' : 'Retry',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _TitleFieldGeminiButton extends StatelessWidget {
  const _TitleFieldGeminiButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionLine extends StatelessWidget {
  const _SuggestionLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

String _frequencyLabel(
  SmartActivityLocalPlan plan, {
  required String localeCode,
}) {
  if (plan.dayStrategy == SmartActivityDayStrategy.daily) {
    return localeCode == 'id' ? 'Setiap hari' : 'Every day';
  }

  if (plan.minSessionsPerWeek == plan.maxSessionsPerWeek) {
    return localeCode == 'id'
        ? '${plan.maxSessionsPerWeek}x seminggu'
        : '${plan.maxSessionsPerWeek}x a week';
  }

  return localeCode == 'id'
      ? '${plan.minSessionsPerWeek}-${plan.maxSessionsPerWeek}x seminggu'
      : '${plan.minSessionsPerWeek}-${plan.maxSessionsPerWeek}x a week';
}

String _weekdayCompactRanges(
  List<int> weekdays, {
  required String localeCode,
}) {
  final List<int> uniqueSorted = weekdays.toSet().toList()..sort();
  if (uniqueSorted.isEmpty) {
    return '-';
  }

  if (uniqueSorted.length == 7) {
    return localeCode == 'id' ? 'Setiap hari' : 'Every day';
  }

  const Set<int> workdays = <int>{1, 2, 3, 4, 5};
  const Set<int> weekend = <int>{6, 7};
  final Set<int> selected = uniqueSorted.toSet();

  if (selected.length == 5 && selected.containsAll(workdays)) {
    return localeCode == 'id' ? 'Hari kerja' : 'Weekdays';
  }

  if (selected.length == 2 && selected.containsAll(weekend)) {
    return localeCode == 'id' ? 'Akhir pekan' : 'Weekend';
  }

  if (selected.length == 6) {
    final List<int> missing = <int>[1, 2, 3, 4, 5, 6, 7]
        .where((int day) => !selected.contains(day))
        .toList(growable: false);
    if (missing.length == 1) {
      final String missingLabel = _weekdayFullLabel(missing.first, localeCode);
      return localeCode == 'id'
          ? 'Setiap hari kecuali $missingLabel'
          : 'Every day except $missingLabel';
    }
  }

  final List<String> segments = <String>[];
  int rangeStart = uniqueSorted.first;
  int previous = uniqueSorted.first;

  for (int index = 1; index < uniqueSorted.length; index++) {
    final int current = uniqueSorted[index];
    if (current == previous + 1) {
      previous = current;
      continue;
    }
    segments.add(
      _weekdayRangeSegment(
        start: rangeStart,
        end: previous,
        localeCode: localeCode,
      ),
    );
    rangeStart = current;
    previous = current;
  }

  segments.add(
    _weekdayRangeSegment(
      start: rangeStart,
      end: previous,
      localeCode: localeCode,
    ),
  );

  return segments.join(', ');
}

String _weekdayRangeSegment({
  required int start,
  required int end,
  required String localeCode,
}) {
  if (start == end) {
    return _weekdayFullLabel(start, localeCode);
  }
  return '${_weekdayFullLabel(start, localeCode)} - ${_weekdayFullLabel(end, localeCode)}';
}

String _weekdayFullLabel(int weekday, String localeCode) {
  const List<String> idLabels = <String>[
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const List<String> enLabels = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final int safeIndex = weekday < 1 ? 0 : weekday > 7 ? 6 : weekday - 1;
  return localeCode == 'id' ? idLabels[safeIndex] : enLabels[safeIndex];
}

class _CustomSegmentedDayPicker extends StatelessWidget {
  const _CustomSegmentedDayPicker({
    required this.selectedDays,
    required this.localeCode,
    required this.onChanged,
  });

  final Set<int> selectedDays;
  final String localeCode;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool allSelected = selectedDays.length == 7;
    final List<int> items = <int>[0, ...allWeekdays]; // 0 represents 'All'

    bool isSelected(int val) =>
        val == 0 ? allSelected : selectedDays.contains(val);

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final int val = items[index];
          final bool selected = isSelected(val);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (val == 0) {
                  if (allSelected) {
                    onChanged(<int>{DateTime.now().weekday});
                  } else {
                    onChanged(allWeekdays.toSet());
                  }
                } else {
                  final Set<int> next = Set<int>.from(selectedDays);
                  if (next.contains(val)) {
                    if (next.length > 1) {
                      next.remove(val);
                    }
                  } else {
                    next.add(val);
                  }
                  onChanged(next);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: val == 0
                      ? Icon(
                          selected ? Icons.check_rounded : Icons.done_all_rounded,
                          size: 20,
                          color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        )
                      : selected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : Text(
                              weekdayShortLabel(val, localeCode),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleInlineItem extends StatelessWidget {
  const _ScheduleInlineItem({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

