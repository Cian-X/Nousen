import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/core/widgets/checklist_confirm_dialog.dart';
import 'package:liburan_create/features/activity/domain/activity_daily_progress_status.dart';
import 'package:liburan_create/features/activity/presentation/activity_status_visuals.dart';
import 'package:liburan_create/features/activity/domain/activity_progress_summary.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/home/application/home_ai_brief_engine.dart';
import 'package:liburan_create/features/home/application/home_ml_service.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/presentation/settings_page.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/l10n/app_localizations.dart';

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  static const HomeAiBriefEngine _homeAiBriefEngine = HomeAiBriefEngine();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startMinuteTicker();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startMinuteTicker() {
    _countdownTimer?.cancel();
    final DateTime now = DateTime.now();
    final int msToNextMinute = ((60 - now.second) * 1000) - now.millisecond;
    _countdownTimer = Timer(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  Future<void> _openActivityForm() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.createActivity,
      arguments: const CreateActivityArgs(),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  Future<void> _openStatsSummary() async {
    await Navigator.of(context).pushNamed(AppRoutes.activitySummary);
  }

  int _countCompletedSubActivities(
    ProgressEntryModel? progressEntry,
    List<String> subActivities,
  ) {
    return normalizeCompletedSubActivities(
      completedValues:
          progressEntry?.completedSubActivities ?? const <String>[],
      subActivities: subActivities,
    ).length;
  }

  double _computeTodayHeroProgress(List<_ActivityTileData> activityItems) {
    if (activityItems.isEmpty) {
      return 0;
    }
    double totalProgress = 0;
    for (final _ActivityTileData item in activityItems) {
      final List<String> subActivities = item.activity.subActivities;
      if (subActivities.isEmpty) {
        totalProgress += item.isCompleted ? 1 : 0;
        continue;
      }
      final int completedSub = _countCompletedSubActivities(
        item.progressEntry,
        subActivities,
      );
      totalProgress += completedSub / subActivities.length;
    }
    return (totalProgress / activityItems.length).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSettingsModel settings =
        ref.watch(settingsStreamProvider).value ??
        const AppSettingsModel(
          morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
          endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
          localeCode: AppConstants.localeId,
        );
    final String localeCode = settings.localeCode;

    final DateTime now = DateTime.now();
    final DateTime today = dateOnly(now);
    final int selectedWeekday = ref.watch(homeSelectedWeekdayProvider);

    final String profileName = _resolvedHomeProfileName(settings.profileName);
    final String contextualGreeting = _contextualGreeting(
      localeCode: localeCode,
      hour: now.hour,
      profileName: profileName,
    );
    final bool selectedIsToday = selectedWeekday == today.weekday;
    final DateTime selectedDate = today.add(
      Duration(days: selectedWeekday - today.weekday),
    );
    final String selectedDateKey = dateKeyFromDate(selectedDate);

    final List<ActivityModel> allActivities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final List<ProgressEntryModel> historicalProgress =
        ref.watch(allProgressStreamProvider).value ??
        const <ProgressEntryModel>[];
    final List<ProgressEntryModel> allProgress =
        ref.watch(progressByDateProvider(selectedDateKey)).value ??
        const <ProgressEntryModel>[];
    final Map<String, ProgressEntryModel> selectedProgressByActivity =
        <String, ProgressEntryModel>{
          for (final ProgressEntryModel entry in allProgress)
            if (entry.dateKey == selectedDateKey) entry.activityId: entry,
        };

    final List<ActivityModel> filteredActivities =
        allActivities.where((ActivityModel activity) {
          return activity.selectedDays.contains(selectedWeekday);
        }).toList()..sort((ActivityModel a, ActivityModel b) {
          return a.timeMinutes.compareTo(b.timeMinutes);
        });

    final List<_ActivityTileData> activityItems = <_ActivityTileData>[];
    bool focusAssigned = false;
    for (final ActivityModel activity in filteredActivities) {
      final ProgressEntryModel? progress =
          selectedProgressByActivity[activity.id];
      final DateTime scheduleUpdatedAt =
          activity.scheduleUpdatedAt ?? activity.createdAt;
      final ActivityDailyProgressStatus status =
          resolveActivityDailyProgressStatus(
            scheduledDate: selectedDate,
            today: now,
            scheduleUpdatedAt: scheduleUpdatedAt,
            subActivities: activity.subActivities,
            scheduledTimeMinutes: activity.timeMinutes,
            entry: progress,
          );
      final bool isFocus =
          !focusAssigned &&
          (!selectedIsToday ||
              (status != ActivityDailyProgressStatus.done &&
                  status != ActivityDailyProgressStatus.skipped));
      if (isFocus) {
        focusAssigned = true;
      }
      activityItems.add(
        _ActivityTileData(
          activity: activity,
          scheduledDate: selectedDate,
          progressEntry: progress,
          status: status,
          isFocus: isFocus,
        ),
      );
    }
    final bool hasActivities = activityItems.isNotEmpty;

    final int skippedCount = activityItems
        .where((item) => item.isSkipped)
        .length;
    final int effectiveScheduledCount = math.max(
      0,
      activityItems.length - skippedCount,
    );
    final int completedCount = activityItems
        .where((item) => item.isCompleted)
        .length;
    final int scheduledCount = effectiveScheduledCount;
    _ActivityTileData? focusItem;
    for (final _ActivityTileData item in activityItems) {
      if (item.isFocus) {
        focusItem = item;
        break;
      }
    }

    final String selectedDayLabel =
        toBeginningOfSentenceCase(
          DateFormat('EEEE', localeCode).format(selectedDate),
        ) ??
        weekdayShortLabel(selectedWeekday, localeCode);
    // Warna indikator untuk card insight HS
    final Color heroProgressColor;
    if (scheduledCount <= 0) {
      heroProgressColor = activityStatusColor(
        theme: theme,
        status: ActivityDailyProgressStatus.future,
      );
    } else if (completedCount <= 0) {
      heroProgressColor = activityStatusColor(
        theme: theme,
        status: selectedDate.isBefore(today)
            ? ActivityDailyProgressStatus.missed
            : ActivityDailyProgressStatus.future,
      );
    } else if (completedCount < scheduledCount) {
      heroProgressColor = activityStatusColor(
        theme: theme,
        status: ActivityDailyProgressStatus.partial,
      );
    } else {
      heroProgressColor = activityStatusColor(
        theme: theme,
        status: ActivityDailyProgressStatus.done,
      );
    }

    final _HeroMascotMood heroMascotMood = _heroMascotMood(
      isToday: selectedIsToday,
      selectedDate: selectedDate,
      today: today,
      completedCount: completedCount,
      scheduledCount: scheduledCount,
    );
    final Color heroMascotColor = _heroMascotColor(
      theme: theme,
      mood: heroMascotMood,
    );

    final String todayHeroTitle = localeCode == 'id' ? 'HARI INI' : 'TODAY';
    final String todayHeroMain = '$completedCount / $scheduledCount';
    final double todayHeroProgress = selectedIsToday
        ? _computeTodayHeroProgress(
            activityItems.where((item) => !item.isSkipped).toList(),
          )
        : 0;
    final String nonTodayHeroTitle = localeCode == 'id' ? 'JADWAL' : 'SCHEDULE';
    final String nonTodayHeroValue = selectedDayLabel;
    final String todayHeroSummary = scheduledCount <= 0
        ? ''
        : (localeCode == 'id'
              ? '$completedCount dari $scheduledCount selesai'
              : '$completedCount of $scheduledCount completed');
    final String nonTodayHeroSummary = filteredActivities.isEmpty
        ? ''
        : (localeCode == 'id'
              ? '${filteredActivities.length} aktivitas terjadwal'
              : '${filteredActivities.length} activities scheduled');
    final HomeAiBrief baseHomeAiBrief = _homeAiBriefEngine.build(
      now: now,
      selectedDate: selectedDate,
      selectedIsToday: selectedIsToday,
      localeCode: localeCode,
      allActivities: allActivities,
      selectedActivities: filteredActivities,
      selectedProgressByActivity: selectedProgressByActivity,
      allProgressEntries: historicalProgress,
    );
    final GlobalStats globalStats = ref.watch(globalStatsProvider);
    final HomeMlRequest? homeMlRequest = _buildHomeMlRequest(
      selectedIsToday: selectedIsToday,
      focusItem: focusItem,
      scheduledCount: scheduledCount,
      globalStats: globalStats,
    );
    final HomeMlPrediction? homeMlPrediction = homeMlRequest == null
        ? null
        : ref.watch(homeMlPredictionProvider(homeMlRequest)).valueOrNull;
    final HomeAiBrief homeAiBrief = _blendHomeBriefWithMl(
      baseBrief: baseHomeAiBrief,
      prediction: homeMlPrediction,
      request: homeMlRequest,
      localeCode: localeCode,
    );
    final _HeroActionCue? heroActionCue = _buildHeroActionCue(
      localeCode: localeCode,
      now: now,
      selectedIsToday: selectedIsToday,
      focusItem: focusItem,
    );

    // HeroMascotMood for non-today cards (fallback)
    final _HeroMascotMood nonTodayHeroMascotMood = _HeroMascotMood.neutral;
    final Color nonTodayHeroMascotColor = _heroMascotColor(
      theme: theme,
      mood: nonTodayHeroMascotMood,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openActivityForm,
        tooltip: localeCode == 'id' ? 'Tambah aktivitas' : 'Add activity',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              context: context,
              icon: Icons.home_rounded,
              label: localeCode == 'id' ? 'Beranda' : 'Home',
              isSelected: true,
              onTap: () {},
            ),
            _buildNavItem(
              context: context,
              icon: Icons.insights_rounded,
              label: localeCode == 'id' ? 'Analitik' : 'Analytics',
              isSelected: false,
              onTap: _openStatsSummary,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today_rounded,
              label: localeCode == 'id' ? 'Jadwal' : 'Schedule',
              isSelected: false,
              onTap: () {
                // Stays on home list
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person_rounded,
              label: localeCode == 'id' ? 'Profil' : 'Profile',
              isSelected: false,
              onTap: _openSettings,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 700;
            final bool isLarge = constraints.maxWidth >= 1100;
            final double sidePadding = isWide ? 24 : 16;
            final double contentMaxWidth = isLarge ? 980 : 760;
            final double contentWidth = constraints.maxWidth < contentMaxWidth
                ? constraints.maxWidth
                : contentMaxWidth;

            return Stack(
              children: <Widget>[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 260,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          theme.colorScheme.primary.withValues(alpha: 0.06),
                          theme.colorScheme.surface.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
              child: SizedBox(
                width: contentWidth,
                child: ListView.builder(
                  cacheExtent: 720,
                  padding: EdgeInsets.only(bottom: AppSpacing.screenPadding),
                  itemCount: hasActivities ? activityItems.length + 2 : 2,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return RepaintBoundary(
                        child: _HomeTopContent(
                          profileName: profileName,
                          contextualGreeting: contextualGreeting,
                          todayDate: today,
                          heroTitle: selectedIsToday
                              ? todayHeroTitle
                              : nonTodayHeroTitle,
                          heroValue: selectedIsToday
                              ? todayHeroMain
                              : nonTodayHeroValue,
                          heroSummary: selectedIsToday
                              ? todayHeroSummary
                              : nonTodayHeroSummary,
                          heroActionCue: heroActionCue,
                          heroProgress: todayHeroProgress,
                          heroProgressColor: heroProgressColor,
                          heroMascotMood: heroMascotMood,
                          heroMascotColor: heroMascotColor,
                          showHeroProgress: selectedIsToday,
                          selectedWeekday: selectedWeekday,
                          localeCode: localeCode,
                          brief: homeAiBrief,
                          sidePadding: sidePadding,
                          currentStreak: globalStats.globalStreak,
                          onDaySelected: (int weekday) {
                            ref
                                    .read(homeSelectedWeekdayProvider.notifier)
                                    .state =
                                weekday;
                          },
                          onSettingsTap: _openSettings,
                        ),
                      );
                    }

                    if (!hasActivities) {
                      return Padding(
                        key: ValueKey<String>(
                          'activity-empty-$selectedWeekday',
                        ),
                        padding: EdgeInsets.only(
                          top: 18,
                          left: sidePadding,
                          right: sidePadding,
                        ),
                        child: RepaintBoundary(
                          child: _EmptyActivitiesPanel(
                            localeCode: localeCode,
                            onAddTap: _openActivityForm,
                          ),
                        ),
                      );
                    }

                    if (hasActivities && index == activityItems.length + 1) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: 32, // Sesuaikan jarak agar lebih ke atas
                          bottom: 32,
                          left: sidePadding,
                          right: sidePadding,
                        ),
                        child: Text(
                          localeCode == 'id'
                              ? 'Tekan + untuk menambah aktivitas'
                              : 'Tap + to add an activity',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    final int itemIndex = index - 1;
                    final _ActivityTileData item = activityItems[itemIndex];
                    return Padding(
                      key: ValueKey<String>(
                        '$selectedDateKey-${item.activity.id}',
                      ),
                      padding: EdgeInsets.only(
                        top: itemIndex == 0 ? 0 : 10,
                        left: sidePadding,
                        right: sidePadding,
                      ),
                      child: RepaintBoundary(
                        child: _ActivityCard(
                          item: item,
                          canToggleToday: selectedIsToday,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            ],
            );
          },
        ),
      ),
    );
  }

  String _resolvedHomeProfileName(String? rawName) {
    final String trimmed = (rawName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Pengguna';
    }
    return trimmed;
  }

  String _contextualGreeting({
    required String localeCode,
    required int hour,
    required String profileName,
  }) {
    if (localeCode == 'id') {
      if (hour < 11) {
        return 'Selamat pagi, $profileName';
      } else if (hour < 15) {
        return 'Selamat siang, $profileName';
      } else if (hour < 18) {
        return 'Selamat sore, $profileName';
      }
      return 'Selamat malam, $profileName';
    }
    if (hour < 12) {
      return 'Good morning, $profileName';
    } else if (hour < 17) {
      return 'Good afternoon, $profileName';
    }
    return 'Good evening, $profileName';
  }

  _HeroActionCue? _buildHeroActionCue({
    required String localeCode,
    required DateTime now,
    required bool selectedIsToday,
    required _ActivityTileData? focusItem,
  }) {
    if (focusItem == null) {
      return null;
    }

    final ActivityModel activity = focusItem.activity;
    final DateTime scheduledAt = DateTime(
      focusItem.scheduledDate.year,
      focusItem.scheduledDate.month,
      focusItem.scheduledDate.day,
      activity.timeMinutes ~/ 60,
      activity.timeMinutes % 60,
    );

    final String timeLabel = formatMinutesAsTime(activity.timeMinutes);

    if (!selectedIsToday) {
      return _HeroActionCue(
        label: localeCode == 'id'
            ? 'Pertama: ${activity.title}'
            : 'First: ${activity.title}',
        countdown: formatMinutesAsTime(activity.timeMinutes),
        timeLabel: timeLabel,
      );
    }

    final int minutesUntil = scheduledAt.difference(now).inMinutes;
    final String label;
    if (minutesUntil > 0) {
      label = localeCode == 'id'
          ? 'Berikutnya: ${activity.title}'
          : 'Next: ${activity.title}';
    } else if (minutesUntil >= -20) {
      label = localeCode == 'id'
          ? 'Saat ini: ${activity.title}'
          : 'Now: ${activity.title}';
    } else {
      label = localeCode == 'id'
          ? 'Terdekat: ${activity.title}'
          : 'Closest: ${activity.title}';
    }

    return _HeroActionCue(
      label: label,
      countdown: _formatHeroCountdown(
        localeCode: localeCode,
        minutesUntil: minutesUntil,
      ),
      timeLabel: timeLabel,
    );
  }

  String _formatHeroCountdown({
    required String localeCode,
    required int minutesUntil,
  }) {
    if (minutesUntil == 0) {
      return localeCode == 'id' ? 'Sekarang' : 'Now';
    }

    final int safeMinutes = minutesUntil.abs();
    final int hours = safeMinutes ~/ 60;
    final int minutes = safeMinutes % 60;
    final String value = hours > 0 ? '${hours}j ${minutes}m' : '${minutes}m';

    if (minutesUntil > 0) {
      return localeCode == 'id' ? '$value lagi' : '$value left';
    }
    return '+$value';
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

HomeMlRequest? _buildHomeMlRequest({
  required bool selectedIsToday,
  required _ActivityTileData? focusItem,
  required int scheduledCount,
  required GlobalStats globalStats,
}) {
  if (!selectedIsToday || focusItem == null || scheduledCount <= 0) {
    return null;
  }

  ActivityBreakdown? breakdown;
  for (final ActivityBreakdown item in globalStats.breakdowns) {
    if (item.activity.id == focusItem.activity.id) {
      breakdown = item;
      break;
    }
  }

  final int totalScheduled = breakdown?.scheduledCount ?? 0;
  final int totalCompleted = breakdown?.completedCount ?? 0;
  final double completionRate = totalScheduled <= 0
      ? 0
      : totalCompleted / totalScheduled;

  return HomeMlRequest(
    activityTitle: focusItem.activity.title,
    weekday: focusItem.scheduledDate.weekday - 1,
    isWeekend: focusItem.scheduledDate.weekday >= 6 ? 1 : 0,
    streak: breakdown?.currentStreak ?? 0,
    completionRate: completionRate,
    scheduledTimeMinutes: focusItem.activity.timeMinutes,
    numActivitiesToday: scheduledCount,
    totalScheduled: totalScheduled,
    totalCompleted: totalCompleted,
  );
}

bool _hasReliableHomeMlSignal(HomeMlRequest request) {
  if (request.totalScheduled < 2) {
    return false;
  }
  if (request.totalCompleted <= 0 && request.streak <= 0) {
    return false;
  }
  return true;
}

HomeAiBrief _blendHomeBriefWithMl({
  required HomeAiBrief baseBrief,
  required HomeMlPrediction? prediction,
  required HomeMlRequest? request,
  required String localeCode,
}) {
  if (prediction == null ||
      request == null ||
      !_hasReliableHomeMlSignal(request)) {
    return baseBrief;
  }

  final String activityTitle = prediction.referenceActivityTitle;
  final String timeLabel = formatMinutesAsTime(request.scheduledTimeMinutes);

  if (prediction.likelyComplete) {
    return HomeAiBrief(
      headline: baseBrief.headline,
      insight: localeCode == 'id'
          ? 'Prediksi hari ini cukup positif. $activityTitle punya peluang selesai kalau ritmemu tetap dijaga di sekitar $timeLabel.'
          : 'Today looks fairly positive. $activityTitle has a good chance to finish if you protect the rhythm around $timeLabel.',
      suggestion: localeCode == 'id'
          ? 'Jaga fokus utama di $activityTitle'
          : 'Keep your main focus on $activityTitle',
      actionType: baseBrief.actionType,
      source: HomeAiBriefSource.ml,
    );
  }

  return HomeAiBrief(
    headline: baseBrief.headline,
    insight: localeCode == 'id'
        ? 'Prediksi hari ini masih agak berat. $activityTitle lebih aman kalau dijalani ringan dan tidak didorong terlalu mepet.'
        : 'Today still looks a bit heavy. $activityTitle will be safer if you keep it light and avoid pushing it too late.',
    suggestion: localeCode == 'id'
        ? 'Turunkan target $activityTitle jadi versi kecil dulu'
        : 'Scale $activityTitle down to a smaller target first',
    actionType: baseBrief.actionType,
    source: HomeAiBriefSource.ml,
  );
}

class _HeroActionCue {
  const _HeroActionCue({
    required this.label,
    required this.countdown,
    required this.timeLabel,
  });

  final String label;
  final String countdown;
  final String timeLabel;
}

enum _HeroMascotMood { happy, encouraging, disappointed, neutral }

class _HeroReactionMascot extends StatelessWidget {
  const _HeroReactionMascot({
    required this.mood,
    required this.color,
  });

  final _HeroMascotMood mood;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isHappy = mood == _HeroMascotMood.happy;
    final bool isEncouraging = mood == _HeroMascotMood.encouraging;
    final bool isDisappointed = mood == _HeroMascotMood.disappointed;
    final double offsetY = isHappy ? -3 : (isDisappointed ? 2 : 0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      tween: Tween<double>(begin: 0.92, end: 1),
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(Icons.face_rounded, size: 35, color: color),
            Positioned(
              bottom: 6,
              child: Icon(
                isHappy
                    ? Icons.sentiment_very_satisfied_rounded
                    : isEncouraging
                    ? Icons.sentiment_satisfied_alt_rounded
                    : isDisappointed
                    ? Icons.sentiment_dissatisfied_rounded
                    : Icons.sentiment_neutral_rounded,
                size: 20,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_HeroMascotMood _heroMascotMood({
  required bool isToday,
  required DateTime selectedDate,
  required DateTime today,
  required int completedCount,
  required int scheduledCount,
}) {
  if (scheduledCount <= 0) {
    return _HeroMascotMood.neutral;
  }
  if (completedCount >= scheduledCount) {
    return _HeroMascotMood.happy;
  }
  if (selectedDate.isBefore(today) && completedCount <= 0) {
    return _HeroMascotMood.disappointed;
  }
  if (completedCount > 0 || isToday) {
    return _HeroMascotMood.encouraging;
  }
  return _HeroMascotMood.neutral;
}

Color _heroMascotColor({
  required ThemeData theme,
  required _HeroMascotMood mood,
}) {
  return switch (mood) {
    _HeroMascotMood.happy => theme.colorScheme.primary,
    _HeroMascotMood.encouraging => const Color(0xFFF59E0B),
    _HeroMascotMood.disappointed => theme.colorScheme.error,
    _HeroMascotMood.neutral => theme.colorScheme.onSurfaceVariant,
  };
}


class _TodayHeroCard extends StatelessWidget {
  const _TodayHeroCard({
    required this.localeCode,
    required this.title,
    required this.value,
    required this.summary,
    required this.actionCue,
    required this.progress,
    required this.progressColor,
    required this.brief,
    this.showProgress = true,
    required this.heroMascotMood,
    required this.heroMascotColor,
  });

  final String localeCode;
  final String title;
  final String value;
  final String summary;
  final _HeroActionCue? actionCue;
  final double progress;
  final Color progressColor;
  final HomeAiBrief brief;
  final bool showProgress;
  final _HeroMascotMood heroMascotMood;
  final Color heroMascotColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double progressValue = progress.clamp(0, 1).toDouble();
    final bool isMlBrief = brief.source == HomeAiBriefSource.ml;

    return Container(
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // bg-white
        borderRadius: BorderRadius.circular(16), // rounded-xl
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x141A5BAD), // soft elevation
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _HeroReactionMascot(
                mood: heroMascotMood,
                color: heroMascotColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  brief.headline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20, // headline-md
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  brief.source == HomeAiBriefSource.ml
                      ? (localeCode == 'id' ? 'ML' : 'ML')
                      : (localeCode == 'id' ? 'AI' : 'AI'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(
                      0xFF00458E,
                    ), // text-on-primary-fixed-variant
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            brief.insight,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14, // body-md
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (BuildContext context) {
                        final bool isFractionValue =
                            showProgress && value.contains('/');
                        if (!isFractionValue) {
                          return Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: progressColor,
                            ),
                          );
                        }

                        final List<String> parts = value.split('/');
                        final String left = parts.first.trim();
                        final String right = parts.length > 1
                            ? parts.last.trim()
                            : '0';
                        final bool allDone = left == right && right != '0';
                        final String statusText = allDone
                            ? (localeCode == 'id'
                                  ? 'Semua aktivitas selesai'
                                  : 'All activities done')
                            : (localeCode == 'id'
                                  ? '$left dari $right selesai'
                                  : '$left of $right done');

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: progressColor,
                                ),
                                text: '$left / $right',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: progressColor.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (actionCue != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 178),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          () {
                            if (actionCue!.label.contains(': ')) {
                              return actionCue!.label
                                  .split(': ')[0]
                                  .toUpperCase();
                            }
                            return localeCode == 'id' ? 'BERIKUTNYA' : 'NEXT';
                          }(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          () {
                            if (actionCue!.label.contains(': ')) {
                              return actionCue!.label.split(': ')[1];
                            }
                            return actionCue!.label;
                          }(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: actionCue!.timeLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: ' \u2022 ',
                                style: TextStyle(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: actionCue!.countdown,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (showProgress)
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints barConstraints) {
                  final double width = barConstraints.maxWidth * progressValue;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: width,
                      height: 4,
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeTopContent extends StatelessWidget {
  const _HomeTopContent({
    required this.profileName,
    required this.contextualGreeting,
    required this.todayDate,
    required this.heroTitle,
    required this.heroValue,
    required this.heroSummary,
    required this.heroActionCue,
    required this.heroProgress,
    required this.heroProgressColor,
    required this.heroMascotMood,
    required this.heroMascotColor,
    required this.showHeroProgress,
    required this.selectedWeekday,
    required this.localeCode,
    required this.brief,
    required this.sidePadding,
    required this.onDaySelected,
    required this.onSettingsTap,
    required this.currentStreak,
  });

  final String profileName;
  final String contextualGreeting;
  final DateTime todayDate;
  final String heroTitle;
  final String heroValue;
  final String heroSummary;
  final _HeroActionCue? heroActionCue;
  final double heroProgress;
  final Color heroProgressColor;
  final _HeroMascotMood heroMascotMood;
  final Color heroMascotColor;
  final bool showHeroProgress;
  final int selectedWeekday;
  final String localeCode;
  final HomeAiBrief brief;
  final double sidePadding;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onSettingsTap;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String formattedDate = DateFormat(
      'EEEE, d MMMM',
      localeCode,
    ).format(todayDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      contextualGreeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Text(
                          toBeginningOfSentenceCase(formattedDate) ?? formattedDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        if (currentStreak > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: theme.colorScheme.tertiary, // Use tertiary for a "fire" color
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentStreak.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettingsTap,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                icon: Icon(
                  Icons.settings_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: _TodayHeroCard(
            localeCode: localeCode,
            title: heroTitle,
            value: heroValue,
            summary: heroSummary,
            actionCue: heroActionCue,
            progress: heroProgress,
            progressColor: heroProgressColor,
            brief: brief,
            heroMascotMood: heroMascotMood,
            heroMascotColor: heroMascotColor,
            showProgress: showHeroProgress,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: _HomeDaySelector(
            selectedWeekday: selectedWeekday,
            localeCode: localeCode,
            selectedDayColor: heroProgressColor,
            onSelected: onDaySelected,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding + 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                localeCode == 'id'
                    ? 'AKTIVITAS TERJADWAL'
                    : 'SCHEDULED ACTIVITIES',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _HomeDaySelector extends StatelessWidget {
  const _HomeDaySelector({
    required this.selectedWeekday,
    required this.localeCode,
    required this.selectedDayColor,
    required this.onSelected,
  });

  final int selectedWeekday;
  final String localeCode;
  final Color selectedDayColor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int selectedIndex = allWeekdays
        .indexOf(selectedWeekday)
        .clamp(0, allWeekdays.length - 1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double itemWidth = constraints.maxWidth / allWeekdays.length;
          return SizedBox(
            height: 36,
            child: Stack(
              children: <Widget>[
                // Titik meluncur (sliding dot)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * itemWidth,
                  bottom: 0,
                  width: itemWidth,
                  height: 6,
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: allWeekdays
                      .map((int day) {
                        final bool selected = selectedWeekday == day;
                        return SizedBox(
                          width: itemWidth,
                          child: GestureDetector(
                            onTap: () => onSelected(day),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    weekdayShortLabel(day, localeCode),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: selected
                                              ? selectedDayColor
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityTileData {
  const _ActivityTileData({
    required this.activity,
    required this.scheduledDate,
    required this.status,
    required this.isFocus,
    this.progressEntry,
  });

  final ActivityModel activity;
  final DateTime scheduledDate;
  final ProgressEntryModel? progressEntry;
  final ActivityDailyProgressStatus status;
  final bool isFocus;

  bool get isCompleted => status == ActivityDailyProgressStatus.done;
  bool get isSkipped => status == ActivityDailyProgressStatus.skipped;
}

class _ActivityCard extends ConsumerStatefulWidget {
  const _ActivityCard({required this.item, required this.canToggleToday});

  final _ActivityTileData item;
  final bool canToggleToday;

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  bool _isExpanded = false;

  IconData _getActivityIcon(String title) {
    final String t = title.toLowerCase();
    if (t.contains('game') ||
        t.contains('main') ||
        t.contains('play') ||
        t.contains('esport')) {
      return Icons.sports_esports_rounded;
    }
    if (t.contains('belajar') ||
        t.contains('buku') ||
        t.contains('read') ||
        t.contains('study') ||
        t.contains('modul') ||
        t.contains('kuliah')) {
      return Icons.menu_book_rounded;
    }
    if (t.contains('olahraga') ||
        t.contains('gym') ||
        t.contains('lari') ||
        t.contains('jogging') ||
        t.contains('sehat') ||
        t.contains('sport') ||
        t.contains('fit')) {
      return Icons.fitness_center_rounded;
    }
    if (t.contains('makan') ||
        t.contains('sarapan') ||
        t.contains('lunch') ||
        t.contains('dinner') ||
        t.contains('malam') ||
        t.contains('siang')) {
      return Icons.restaurant_rounded;
    }
    if (t.contains('minum') ||
        t.contains('air') ||
        t.contains('hidrasi') ||
        t.contains('drink') ||
        t.contains('water')) {
      return Icons.local_drink_rounded;
    }
    if (t.contains('tidur') ||
        t.contains('begadang') ||
        t.contains('istirahat') ||
        t.contains('sleep') ||
        t.contains('rest')) {
      return Icons.bedtime_rounded;
    }
    if (t.contains('kerja') ||
        t.contains('coding') ||
        t.contains('rapat') ||
        t.contains('meeting') ||
        t.contains('tugas') ||
        t.contains('work')) {
      return Icons.work_rounded;
    }
    if (t.contains('sosial') ||
        t.contains('chat') ||
        t.contains('teman') ||
        t.contains('keluarga') ||
        t.contains('nongkrong') ||
        t.contains('ngobrol') ||
        t.contains('call') ||
        t.contains('telpon')) {
      return Icons.people_rounded;
    }
    return Icons.event_note_rounded;
  }

  Color _subActivityCompletedColor({
    required ThemeData theme,
    required ActivityDailyProgressStatus activityStatus,
  }) {
    return activityStatusColor(theme: theme, status: activityStatus);
  }

  Color _subActivityIncompleteColor({
    required ThemeData theme,
    required ActivityDailyProgressStatus activityStatus,
  }) {
    return switch (activityStatus) {
      ActivityDailyProgressStatus.partial ||
      ActivityDailyProgressStatus.missed => const Color(0xFFBA1A1A),
      ActivityDailyProgressStatus.skipped ||
      ActivityDailyProgressStatus.future =>
        theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ActivityDailyProgressStatus.done => activityStatusColor(
        theme: theme,
        status: activityStatus,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final _ActivityTileData item = widget.item;
    final bool canToggleToday = widget.canToggleToday;
    final bool isExpanded = _isExpanded;
    final AppLocalizations t = AppLocalizations.of(context)!;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ThemeData theme = Theme.of(context);
    final ActivityModel activity = item.activity;
    final ProgressEntryModel? entry = item.progressEntry;
    final ActivityDailyProgressStatus dailyStatus = item.status;

    final List<String> completedSubActivities = normalizeCompletedSubActivities(
      completedValues: entry?.completedSubActivities ?? const <String>[],
      subActivities: activity.subActivities,
    );
    final int subTotal = activity.subActivities.length;

    final bool highlightFocus =
        item.isFocus && !item.isCompleted && !item.isSkipped;
    final Color borderColor = highlightFocus
        ? theme.colorScheme.primary.withValues(alpha: 0.24)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    final Color cardBg = highlightFocus
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
        : theme.colorScheme.surface; // bg-white

    return Opacity(
      opacity: item.isCompleted ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: highlightFocus ? 1.5 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: highlightFocus
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : const Color(0x141A5BAD), // soft-elevation
                blurRadius: highlightFocus ? 24 : 20,
                spreadRadius: highlightFocus ? 0 : -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.activityDetail,
                arguments: ActivityDetailArgs(
                  activityId: activity.id,
                  scheduledDate: widget.item.scheduledDate,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Left: Circle Icon (Checklist toggle on click)
                      GestureDetector(
                        onTap: canToggleToday
                            ? () async {
                                final bool confirmed =
                                    await showChecklistConfirmDialog(
                                      context: context,
                                      title: t.checklistConfirmTitle,
                                      message: t.checklistConfirmMessage,
                                      cancelLabel: t.cancel,
                                      confirmLabel: t.checklistConfirmAction,
                                    );
                                if (!confirmed) {
                                  return;
                                }
                                await ref
                                    .read(activityActionsProvider)
                                    .toggleTodayCompletion(
                                      activity: activity,
                                      completed:
                                          dailyStatus !=
                                          ActivityDailyProgressStatus.done,
                                    );
                              }
                            : null,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: activityStatusColor(
                              theme: theme,
                              status: dailyStatus,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getActivityIcon(activity.title),
                              color: activityStatusColor(
                                theme: theme,
                                status: dailyStatus,
                              ),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Middle: Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              activity.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                decoration: null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.subActivities.isNotEmpty
                                  ? activity.subActivities.join(', ')
                                  : (localeCode == 'id'
                                        ? 'Rutinitas harian'
                                        : 'Daily routine'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right: Time & Period Label / Chevron
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (subTotal == 0) ...[
                                Text(
                                  '',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                formatMinutesAsTime(activity.timeMinutes),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (subTotal > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                  size: 24,
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 32),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // Expandable subtasks checklist
                  if (subTotal > 0 && isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: activity.subActivities.map((
                          String subActivity,
                        ) {
                          final bool checked = completedSubActivities.contains(
                            subActivity,
                          );
                          Future<void> toggleSub(bool next) async {
                            final bool confirmed =
                                await showChecklistConfirmDialog(
                                  context: context,
                                  title: t.checklistConfirmTitle,
                                  message: t.checklistConfirmMessage,
                                  cancelLabel: t.cancel,
                                  confirmLabel: t.checklistConfirmAction,
                                );
                            if (!confirmed) {
                              return;
                            }
                            await ref
                                .read(activityActionsProvider)
                                .toggleTodaySubActivity(
                                  activity: activity,
                                  subActivity: subActivity,
                                  completed: next,
                                );
                          }

                          final Color completedColor =
                              _subActivityCompletedColor(
                                theme: theme,
                                activityStatus: dailyStatus,
                              );
                          final Color incompleteColor =
                              _subActivityIncompleteColor(
                                theme: theme,
                                activityStatus: dailyStatus,
                              );
                          final Color subIndicatorColor = checked
                              ? completedColor
                              : incompleteColor;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: canToggleToday
                                ? () => toggleSub(!checked)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: checked,
                                      checkColor: Colors.transparent,
                                      activeColor: completedColor,
                                      side: BorderSide(
                                        color: subIndicatorColor,
                                        width: 2,
                                      ),
                                      onChanged: canToggleToday
                                          ? (bool? next) =>
                                                toggleSub(next ?? false)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subActivity,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 13,
                                            color: subIndicatorColor,
                                            fontWeight: checked
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyActivitiesPanel extends StatelessWidget {
  const _EmptyActivitiesPanel({
    required this.localeCode,
    required this.onAddTap,
  });

  final String localeCode;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              localeCode == 'id'
                  ? 'Tidak ada aktivitas hari ini.'
                  : 'No activities today.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localeCode == 'id'
                  ? 'Hari terasa ringan. Mau tambah target kecil?'
                  : 'The day feels light. Add a small target?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                localeCode == 'id' ? 'Tambah aktivitas' : 'Add activity',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
