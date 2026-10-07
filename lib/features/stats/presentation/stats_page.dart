import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/constants/ai_demo_config.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_category.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/features/stats/domain/stats_view_models.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  static const double _heroToInsightSpacing = 16;

  ({DateTime start, DateTime end}) _resolveActiveRange() {
    // Current Monday–Sunday week (dynamic from today)
    return currentWeekRange();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final List<ActivityModel> activities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final List<ProgressEntryModel> progressEntries =
        ref.watch(allProgressStreamProvider).value ??
        const <ProgressEntryModel>[];
    final calculator = ref.watch(globalScheduledStatsCalculatorProvider);
    final activeRange = _resolveActiveRange();
    final DateTime start = activeRange.start;
    final DateTime end = activeRange.end;

    final List<DailyStat> dailyStats = calculator.getDailyStats(start, end);
    final double globalRate = calculator.getGlobalCompletionRate(start, end);

    final int totalScheduled = dailyStats.fold<int>(
      0,
      (sum, item) => sum + item.totalScheduled,
    );
    final int totalCompleted = dailyStats.fold<int>(
      0,
      (sum, item) => sum + item.totalCompleted,
    );
    final int overallPercent = (globalRate * 100).round();

    final List<PeriodActivityStat> periodActivityStats =
        _buildPeriodActivityStats(
          activities: activities,
          progressEntries: progressEntries,
          start: start,
          end: end,
        );
    final double previousGlobalRate = calculator.getGlobalCompletionRate(
      start.subtract(const Duration(days: 7)),
      start.subtract(const Duration(days: 1)),
    );
    final Map<String, _CategorySlice> categoryDistribution =
        _buildCategoryDistribution(periodActivityStats);
    final int distributionCompleted = categoryDistribution.values.fold<int>(
      0,
      (int sum, _CategorySlice item) => sum + item.completed,
    );
    final _PeakInfo peakInfo = _buildPeakInfo(dailyStats, localeCode);

    final StatsAiSummaryData summary = _buildStatsAiSummary(
      localeCode: localeCode,
      currentStats: dailyStats,
      periodActivityStats: periodActivityStats,
      timeBucketStats: _buildTimeBucketStats(
        periodActivityStats,
        localeCode: localeCode,
      ),
      averageDailyRate: _computeAverageDailyRate(dailyStats),
      currentGlobalRate: globalRate,
      previousGlobalRate: previousGlobalRate,
      hasActiveScheduleInPeriod: dailyStats.any(
        (item) => item.totalScheduled > 0,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leadingWidth: 64,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      icon: NousenNavIcon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Text(localeCode == 'id' ? 'Statistik' : 'Statistics'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            StatsHeroSection(
              percent: overallPercent,
              rate: globalRate,
              previousRate: previousGlobalRate,
              activeCount: periodActivityStats.length,
              totalCompleted: totalCompleted,
              totalScheduled: totalScheduled,
              statsMascotMood: _statsMascotMood(
                rate: globalRate,
                totalScheduled: totalScheduled,
              ),
              statsMascotColor: _statsMascotColor(
                theme: theme,
                mood: _statsMascotMood(
                  rate: globalRate,
                  totalScheduled: totalScheduled,
                ),
              ),
              statsSummaryHeadline: summary.headline,
              statsSummaryBody: summary.body,
              statsSummarySupport: summary.support,
              hasScheduledActivities: dailyStats.any(
                (item) => item.totalScheduled > 0,
              ),
              isId: localeCode == 'id',
            ),
            const SizedBox(height: _heroToInsightSpacing),
            if (distributionCompleted > 0) ...<Widget>[
              _CategoryDistributionSection(
                distribution: categoryDistribution,
                totalCompleted: distributionCompleted,
                localeCode: localeCode,
              ),
              const SizedBox(height: _heroToInsightSpacing),
            ],
            _MatrixEntrySection(
              peakLabel: peakInfo.dayLabels,
              activeDays: peakInfo.activeDays,
              localeCode: localeCode,
              mlEnabled: AiDemoConfig.onDeviceMlEnabled,
              onOpenReport: () => Navigator.of(context).pushNamed(
                AppRoutes.statsReport,
                arguments: <String, dynamic>{
                  'dailyStats': dailyStats,
                  'periodActivityStats': periodActivityStats,
                  'start': start,
                  'end': end,
                  'totalScheduled': totalScheduled,
                  'localeCode': localeCode,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, _CategorySlice> _buildCategoryDistribution(
    List<PeriodActivityStat> stats,
  ) {
    final Map<String, _CategorySlice> result = <String, _CategorySlice>{};
    for (final String id in ActivityCategory.values) {
      int scheduled = 0;
      int completed = 0;
      for (final PeriodActivityStat stat in stats) {
        if (ActivityCategory.safeId(stat.activity.category) != id) {
          continue;
        }
        scheduled += stat.scheduled;
        completed += stat.completed;
      }
      if (scheduled > 0) {
        result[id] = _CategorySlice(scheduled: scheduled, completed: completed);
      }
    }
    return result;
  }

  _PeakInfo _buildPeakInfo(List<DailyStat> stats, String localeCode) {
    final Map<int, List<double>> ratesByWeekday = <int, List<double>>{};
    int activeDays = 0;
    for (final DailyStat item in stats) {
      if (item.isNeutral || item.totalScheduled == 0) {
        continue;
      }
      activeDays++;
      ratesByWeekday
          .putIfAbsent(item.date.weekday, () => <double>[])
          .add(item.completionRate);
    }
    if (ratesByWeekday.isEmpty) {
      return const _PeakInfo(dayLabels: '', activeDays: 0);
    }
    final List<MapEntry<int, double>> averaged = ratesByWeekday.entries
        .map(
          (MapEntry<int, List<double>> e) => MapEntry<int, double>(
            e.key,
            e.value.reduce((a, b) => a + b) / e.value.length,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final String labels = averaged
        .take(2)
        .map((e) => weekdayShortLabel(e.key, localeCode))
        .join(' & ');
    return _PeakInfo(dayLabels: labels, activeDays: activeDays);
  }

  double _computeAverageDailyRate(List<DailyStat> stats) {
    final activeDays = stats.where((item) => !item.isNeutral).toList();
    if (activeDays.isEmpty) return 0;
    return activeDays.fold<double>(
          0,
          (sum, item) => sum + item.completionRate,
        ) /
        activeDays.length;
  }

  List<PeriodActivityStat> _buildPeriodActivityStats({
    required List<ActivityModel> activities,
    required List<ProgressEntryModel> progressEntries,
    required DateTime start,
    required DateTime end,
  }) {
    final Map<String, ProgressEntryModel> progressMap = {
      for (final entry in progressEntries)
        '${entry.activityId}|${entry.dateKey}': entry,
    };
    final List<PeriodActivityStat> stats = [];
    for (final activity in activities) {
      int scheduled = 0, completed = 0;
      DateTime cursor = dateOnly(start);
      while (!cursor.isAfter(end)) {
        if (activity.selectedDays.contains(cursor.weekday)) {
          final entry =
              progressMap['${activity.id}|${dateKeyFromDate(cursor)}'];
          if (entry?.isSkipped != true) {
            scheduled++;
            if (entry?.isCompleted == true) completed++;
          }
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      if (scheduled > 0) {
        stats.add(
          PeriodActivityStat(
            activity: activity,
            scheduled: scheduled,
            completed: completed,
          ),
        );
      }
    }
    return stats;
  }

  List<TimeBucketStat> _buildTimeBucketStats(
    List<PeriodActivityStat> activityStats, {
    required String localeCode,
  }) {
    final Map<String, TimeBucketStat> buckets = {};
    for (final stat in activityStats) {
      final seed = _timeBucketForMinutes(
        stat.activity.timeMinutes,
        localeCode: localeCode,
      );
      final prev =
          buckets[seed.key] ??
          TimeBucketStat(
            key: seed.key,
            label: seed.label,
            scheduled: 0,
            completed: 0,
          );
      buckets[seed.key] = prev.copyWith(
        scheduled: prev.scheduled + stat.scheduled,
        completed: prev.completed + stat.completed,
      );
    }
    return buckets.values.where((item) => item.scheduled > 0).toList();
  }

  StatsAiSummaryData _buildStatsAiSummary({
    required String localeCode,
    required List<DailyStat> currentStats,
    required List<PeriodActivityStat> periodActivityStats,
    required List<TimeBucketStat> timeBucketStats,
    required double averageDailyRate,
    required double currentGlobalRate,
    required double previousGlobalRate,
    required bool hasActiveScheduleInPeriod,
  }) {
    final bool isId = localeCode == 'id';
    String headline;
    String body;
    String? support;

    if (!hasActiveScheduleInPeriod) {
      headline = isId ? 'Belum ada aktivitas' : 'No activities yet';
      body = isId
          ? 'Tambahkan jadwal aktivitas untuk melihat statistik Anda di sini.'
          : 'Add some scheduled activities to see your stats here.';
    } else if (currentGlobalRate >= 0.8) {
      headline = isId ? 'Performa sangat baik!' : 'Excellent performance!';
      body = isId
          ? 'Terus pertahankan konsistensi Anda. Luar biasa!'
          : 'Keep up the great work and consistency!';
    } else if (currentGlobalRate > 0) {
      headline = isId ? 'Butuh sedikit dorongan' : 'Needs a little push';
      body = isId
          ? 'Coba tingkatkan progres Anda hari ini.'
          : 'Try to improve your progress today.';
      if (currentGlobalRate < previousGlobalRate) {
        support = isId
            ? 'Performa sedikit menurun dibandingkan periode sebelumnya.'
            : 'Slight decrease in performance compared to previous period.';
      }
    } else {
      headline = isId ? 'Data minggu ini masih tipis' : 'Not enough data';
      body = isId
          ? 'Selesaikan beberapa aktivitas dulu.'
          : 'Complete activities first.';
    }

    return StatsAiSummaryData(
      eyebrow: isId ? 'Ringkasan pintar' : 'Smart overview',
      headline: headline,
      body: body,
      support: support,
    );
  }

  StatsMascotMood _statsMascotMood({
    required double rate,
    required int totalScheduled,
  }) => StatsMascotMood.neutral;
  Color _statsMascotColor({
    required ThemeData theme,
    required StatsMascotMood mood,
  }) => theme.colorScheme.primary;

  ({String key, String label}) _timeBucketForMinutes(
    int minutes, {
    required String localeCode,
  }) {
    final bool isId = localeCode == 'id';
    final String key;
    if (minutes >= 5 * 60 && minutes < 11 * 60) {
      key = 'morning';
    } else if (minutes >= 11 * 60 && minutes < 15 * 60) {
      key = 'midday';
    } else if (minutes >= 15 * 60 && minutes < 18 * 60) {
      key = 'afternoon';
    } else {
      key = 'night';
    }

    final String label = switch (key) {
      'morning' => isId ? 'Pagi' : 'Morning',
      'midday' => isId ? 'Siang' : 'Midday',
      'afternoon' => isId ? 'Sore' : 'Afternoon',
      _ => isId ? 'Malam' : 'Night',
    };

    return (key: key, label: label);
  }
}

enum StatsMascotMood { neutral, happy, excited, concerned }

enum StatsFilterMode { currentWeek, custom }

class _CategorySlice {
  const _CategorySlice({required this.scheduled, required this.completed});

  final int scheduled;
  final int completed;

  double get rate => scheduled == 0 ? 0 : completed / scheduled;
}

class _PeakInfo {
  const _PeakInfo({required this.dayLabels, required this.activeDays});

  final String dayLabels;
  final int activeDays;
}

class StatsDateRangeSheet extends StatefulWidget {
  const StatsDateRangeSheet({
    super.key,
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    required this.localeCode,
  });

  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String localeCode;

  @override
  State<StatsDateRangeSheet> createState() => _StatsDateRangeSheetState();
}

class _StatsDateRangeSheetState extends State<StatsDateRangeSheet> {
  late DateTimeRange _range;

  bool get _isId => widget.localeCode == 'id';

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  Future<void> _pickCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDateRange: _range,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _range = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
    });
  }

  void _setPreset(Duration duration) {
    final DateTime today = dateOnly(DateTime.now());
    setState(() {
      _range = DateTimeRange(start: today.subtract(duration), end: today);
    });
  }

  void _setPresetToCurrentWeek() {
    final ({DateTime start, DateTime end}) week = currentWeekRange();
    setState(() {
      _range = DateTimeRange(start: week.start, end: week.end);
    });
  }

  String _formatRange() {
    return '${formatDateShort(_range.start, widget.localeCode)} - ${formatDateShort(_range.end, widget.localeCode)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _isId ? 'Pilih rentang tanggal' : 'Choose a date range',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(_formatRange(), style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: Text(_isId ? 'Minggu Ini' : 'This Week'),
                    onPressed: () => _setPresetToCurrentWeek(),
                  ),
                  ActionChip(
                    label: Text(_isId ? '30 hari' : '30 days'),
                    onPressed: () => _setPreset(const Duration(days: 29)),
                  ),
                  ActionChip(
                    label: Text(_isId ? 'Bulan ini' : 'This month'),
                    onPressed: () {
                      final DateTime today = dateOnly(DateTime.now());
                      setState(() {
                        _range = DateTimeRange(
                          start: DateTime(today.year, today.month),
                          end: DateTime(today.year, today.month + 1, 0),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _pickCustomRange,
                child: Text(_isId ? 'Pilih manual' : 'Pick manually'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_range),
                child: Text(_isId ? 'Gunakan rentang ini' : 'Use this range'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsReactionMascot extends StatelessWidget {
  const StatsReactionMascot({
    super.key,
    required this.mood,
    required this.color,
  });

  final StatsMascotMood mood;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (mood) {
      StatsMascotMood.excited => Icons.celebration_rounded,
      StatsMascotMood.happy => Icons.sentiment_satisfied_alt_rounded,
      StatsMascotMood.concerned => Icons.warning_amber_rounded,
      StatsMascotMood.neutral => Icons.auto_awesome_rounded,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: NousenNavIcon(icon, color: color, size: 28),
    );
  }
}

class StatsHeroSection extends StatelessWidget {
  const StatsHeroSection({
    super.key,
    required this.percent,
    required this.rate,
    required this.previousRate,
    required this.activeCount,
    required this.totalCompleted,
    required this.totalScheduled,
    required this.statsMascotMood,
    required this.statsMascotColor,
    required this.statsSummaryHeadline,
    required this.statsSummaryBody,
    required this.statsSummarySupport,
    required this.hasScheduledActivities,
    required this.isId,
  });

  final int percent;
  final double rate;
  final double previousRate;
  final int activeCount;
  final int totalCompleted;
  final int totalScheduled;
  final StatsMascotMood statsMascotMood;
  final Color statsMascotColor;
  final String statsSummaryHeadline;
  final String statsSummaryBody;
  final String? statsSummarySupport;
  final bool hasScheduledActivities;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool showTrend = previousRate > 0;
    final int trendPoints = ((rate - previousRate) * 100).round();
    final bool trendUp = trendPoints >= 0;
    // Warna ring mengikuti status performa agregat, mirror Detail Aktivitas:
    // tanpa jadwal → abu-abu; ≥80% → biru; parsial → amber; 0% → merah.
    final Color statusColor;
    if (totalScheduled <= 0) {
      statusColor = theme.habitColors.inactive;
    } else if (rate >= 0.8) {
      statusColor = theme.habitColors.completed;
    } else if (rate > 0) {
      statusColor = theme.habitColors.pending;
    } else {
      statusColor = theme.habitColors.missed;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  isId ? 'PERFORMA KESELURUHAN' : 'OVERALL PERFORMANCE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              if (showTrend)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendUp
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      NousenNavIcon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: trendUp
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isId
                            ? '${trendUp ? '+' : ''}$trendPoints% vs periode lalu'
                            : '${trendUp ? '+' : ''}$trendPoints% vs prev period',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendUp
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: CircularProgressIndicator(
                        value: percent.clamp(0, 100) / 100,
                        strokeWidth: 10,
                        backgroundColor:
                            statusColor.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(statusColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'TARGET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isId
                          ? '/100 poin konsistensi'
                          : '/100 consistency points',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalCompleted / $totalScheduled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatsReactionMascot(
                mood: statsMascotMood,
                color: statsMascotColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroMiniStat(
                  icon: Icons.assignment_rounded,
                  iconColor: const Color(0xFF2563EB),
                  label: isId ? 'Aktivitas' : 'Activities',
                  value: '$activeCount',
                  sub: isId ? 'Terdaftar aktif' : 'Active',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniStat(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF1A5BAD),
                  label: isId ? 'Selesai' : 'Done',
                  value: '$totalCompleted',
                  sub: isId ? 'Sesi tuntas' : 'Sessions',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniStat(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF6366F1),
                  label: isId ? 'Terjadwal' : 'Scheduled',
                  value: '$totalScheduled',
                  sub: isId ? 'Slot sesi' : 'Slots',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            statsSummaryHeadline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statsSummaryBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (statsSummarySupport != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              statsSummarySupport!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!hasScheduledActivities) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              isId
                  ? 'Belum ada jadwal aktif di rentang ini.'
                  : 'No active schedule in this range yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              NousenNavIcon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDistributionSection extends StatelessWidget {
  const _CategoryDistributionSection({
    required this.distribution,
    required this.totalCompleted,
    required this.localeCode,
  });

  final Map<String, _CategorySlice> distribution;
  final int totalCompleted;
  final String localeCode;

  static Color _colorFor(String id) {
    return switch (id) {
      ActivityCategory.work => const Color(0xFFE76F51),
      ActivityCategory.learning => const Color(0xFF6C63FF),
      ActivityCategory.health => const Color(0xFF2A9D8F),
      ActivityCategory.personal => const Color(0xFFE9A23B),
      _ => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isId = localeCode == 'id';
    final List<MapEntry<String, _CategorySlice>> entries = distribution.entries
        .where((e) => e.value.completed > 0)
        .toList()
      ..sort((a, b) => b.value.completed.compareTo(a.value.completed));
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    MapEntry<String, _CategorySlice>? best;
    for (final e in distribution.entries) {
      if (e.value.scheduled == 0) {
        continue;
      }
      if (best == null || e.value.rate > best.value.rate) {
        best = e;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isId ? 'Distribusi & Keseimbangan' : 'Distribution & Balance',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isId
                ? 'Rasio penyelesaian antar kategori'
                : 'Completion ratio across categories',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: <Widget>[
                ...entries.map(
                  (MapEntry<String, _CategorySlice> e) => Expanded(
                    flex: (((e.value.completed / totalCompleted) * 100)
                            .round())
                        .clamp(4, 100),
                    child: Container(
                      height: 10,
                      color: _colorFor(e.key),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final int pct =
                ((e.value.completed / totalCompleted) * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _colorFor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          ActivityCategory.labelOf(e.key, localeCode),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isId
                              ? '${e.value.completed} sesi terlaksana'
                              : '${e.value.completed} sessions done',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (best != null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  NousenNavIcon(
                    Icons.lightbulb_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isId
                          ? 'Kategori ${ActivityCategory.labelOf(best.key, localeCode)} menunjukkan konsistensi tertinggi.'
                          : '${ActivityCategory.labelOf(best.key, localeCode)} shows the highest consistency.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatrixEntrySection extends StatelessWidget {
  const _MatrixEntrySection({
    required this.peakLabel,
    required this.activeDays,
    required this.localeCode,
    required this.mlEnabled,
    required this.onOpenReport,
  });

  final String peakLabel;
  final int activeDays;
  final String localeCode;
  final bool mlEnabled;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = localeCode == 'id';
    final String title =
        isId ? 'Matriks & Evaluasi${mlEnabled ? ' AI' : ''}' : 'Matrix & Evaluation${mlEnabled ? ' AI' : ''}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: NousenNavIcon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isId
                ? 'Ringkasan konsistensi dan tren puncak dari data aktual.'
                : 'Consistency overview and peak trends from actual data.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF1F5F9),
                width: 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                NousenNavIcon(
                  Icons.insights_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    peakLabel.isEmpty
                        ? (isId
                              ? 'Belum ada data performa.'
                              : 'No performance data yet.')
                        : (isId
                              ? 'Puncak performa: $peakLabel ($activeDays hari aktif)'
                              : 'Peak performance: $peakLabel ($activeDays active days)'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.habitColors.primaryAction,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onOpenReport,
              child: Text(
                isId
                    ? 'Buka Detail Matriks & Insight'
                    : 'Open Matrix & Insight Details',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
