import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/features/stats/domain/stats_view_models.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  StatsFilterMode _selectedFilter = StatsFilterMode.last7;
  DateTimeRange? _customRange;
  static const double _heroToInsightSpacing = 16;

  String _periodLabel(String localeCode, DateTime start, DateTime end) {
    if (_selectedFilter == StatsFilterMode.last7) {
      return localeCode == 'id' ? '7 Hari' : '7 Days';
    }
    return '${formatDateShort(start, localeCode)} - ${formatDateShort(end, localeCode)}';
  }

  ({DateTime start, DateTime end}) _resolveActiveRange() {
    final DateTime today = dateOnly(DateTime.now());
    if (_selectedFilter == StatsFilterMode.custom && _customRange != null) {
      return (
        start: dateOnly(_customRange!.start),
        end: dateOnly(_customRange!.end),
      );
    }
    return (start: today.subtract(const Duration(days: 6)), end: today);
  }

  Future<void> _pickCustomRange() async {
    final DateTime today = dateOnly(DateTime.now());
    final DateTimeRange initialRange =
        _customRange ??
        DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );

    if (!mounted) return;
    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatsDateRangeSheet(
          initialRange: initialRange,
          firstDate: DateTime(today.year - 5, 1, 1),
          lastDate: DateTime(today.year + 1, 12, 31),
          localeCode: localeCode,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _customRange = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
      _selectedFilter = StatsFilterMode.custom;
    });
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
      previousGlobalRate: calculator.getGlobalCompletionRate(
        start.subtract(const Duration(days: 7)),
        start.subtract(const Duration(days: 1)),
      ),
      hasActiveScheduleInPeriod: dailyStats.any(
        (item) => item.totalScheduled > 0,
      ),
    );

    final ActivityHighlightsData activityHighlights = _buildActivityHighlights(
      periodActivityStats,
      localeCode: localeCode,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(localeCode == 'id' ? 'Statistik' : 'Statistics'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            StatsHeroSection(
              percent: overallPercent,
              rate: globalRate,
              totalCompleted: totalCompleted,
              totalScheduled: totalScheduled,
              periodLabel: _periodLabel(localeCode, start, end),
              onPeriodTap: _pickCustomRange,
              onReportTap: () => Navigator.of(context).pushNamed(
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
            StatsSmartSummarySection(
              summary: summary,
              activityHighlights: activityHighlights,
              activityStats: periodActivityStats,
            ),
          ],
        ),
      ),
    );
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

  ActivityHighlightsData _buildActivityHighlights(
    List<PeriodActivityStat> stats, {
    required String localeCode,
  }) {
    String strongestTitle = '-';
    String strongestDetail = '-';
    String strugglingTitle = '-';
    String strugglingDetail = '-';

    if (stats.isNotEmpty) {
      final List<PeriodActivityStat> sortedStats = [...stats]
        ..sort((a, b) => b.completionRate.compareTo(a.completionRate));
      final PeriodActivityStat strongest = sortedStats.first;
      final PeriodActivityStat struggling = sortedStats.last;

      strongestTitle = strongest.activity.title;
      strongestDetail = localeCode == 'id'
          ? '${(strongest.completionRate * 100).round()}% selesai'
          : '${(strongest.completionRate * 100).round()}% completed';

      strugglingTitle = struggling.activity.title;
      strugglingDetail = localeCode == 'id'
          ? '${(struggling.completionRate * 100).round()}% selesai'
          : '${(struggling.completionRate * 100).round()}% completed';
    }

    return ActivityHighlightsData(
      strongestTitle: strongestTitle,
      strongestDetail: strongestDetail,
      strugglingTitle: strugglingTitle,
      strugglingDetail: strugglingDetail,
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
                    label: Text(_isId ? '7 hari' : '7 days'),
                    onPressed: () => _setPreset(const Duration(days: 6)),
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
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class StatsHeroSection extends StatelessWidget {
  const StatsHeroSection({
    super.key,
    required this.percent,
    required this.rate,
    required this.totalCompleted,
    required this.totalScheduled,
    required this.periodLabel,
    required this.onPeriodTap,
    required this.onReportTap,
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
  final int totalCompleted;
  final int totalScheduled;
  final String periodLabel;
  final VoidCallback onPeriodTap;
  final VoidCallback onReportTap;
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isId ? 'STATISTIK HARI INI' : 'TODAY\'S STATS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.72,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percent%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
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
          Text(
            periodLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onPeriodTap,
                  child: Text(isId ? 'Ganti rentang' : 'Change range'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onReportTap,
                  child: Text(isId ? 'Lihat laporan' : 'View report'),
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: rate.clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class StatsSmartSummarySection extends StatelessWidget {
  const StatsSmartSummarySection({
    super.key,
    required this.summary,
    required this.activityHighlights,
    required this.activityStats,
  });

  final StatsAiSummaryData summary;
  final ActivityHighlightsData activityHighlights;
  final List<PeriodActivityStat> activityStats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = Localizations.localeOf(context).languageCode == 'id';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            summary.eyebrow,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.headline,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (summary.support != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              summary.support!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (activityStats.isNotEmpty) ...<Widget>[
            Text(
              isId ? 'Sorotan aktivitas' : 'Activity highlights',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _ActivityHighlightRow(
              title: isId ? 'Terkuat' : 'Strongest',
              value: activityHighlights.strongestTitle,
              detail: activityHighlights.strongestDetail,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _ActivityHighlightRow(
              title: isId ? 'Perlu perhatian' : 'Needs attention',
              value: activityHighlights.strugglingTitle,
              detail: activityHighlights.strugglingDetail,
              color: const Color(0xFFBA1A1A),
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityHighlightRow extends StatelessWidget {
  const _ActivityHighlightRow({
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    this.isWarning = false,
  });

  final String title;
  final String value;
  final String detail;
  final Color color;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF7F7) : const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFAD7D9)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.verified_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
