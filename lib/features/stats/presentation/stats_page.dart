import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/application/stats_ml_service.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  _StatsFilterMode _selectedFilter = _StatsFilterMode.last7;
  DateTimeRange? _customRange;
  static const double _heroToInsightSpacing = 16;
  static const double _insightToPatternSpacing = 18;
  static const double _patternToStatusSpacing = 18;
  static const double _statusToActivitySpacing = 16;

  String _periodLabel(String localeCode, DateTime start, DateTime end) {
    if (_selectedFilter == _StatsFilterMode.last7) {
      return localeCode == 'id' ? '7 Hari' : '7 Days';
    }

    return '${formatDateShort(start, localeCode)} - ${formatDateShort(end, localeCode)}';
  }

  ({DateTime start, DateTime end}) _resolveActiveRange() {
    final DateTime today = dateOnly(DateTime.now());
    if (_selectedFilter == _StatsFilterMode.custom && _customRange != null) {
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

    if (!mounted) {
      return;
    }
    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _StatsDateRangeSheet(
          initialRange: initialRange,
          firstDate: DateTime(today.year - 5, 1, 1),
          lastDate: DateTime(today.year + 1, 12, 31),
          localeCode: localeCode,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _customRange = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
      _selectedFilter = _StatsFilterMode.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final List<ActivityModel> activities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final List<ProgressEntryModel> progressEntries =
        ref.watch(allProgressStreamProvider).value ??
        const <ProgressEntryModel>[];
    final GlobalStats globalStats = ref.watch(globalStatsProvider);
    final calculator = ref.watch(globalScheduledStatsCalculatorProvider);
    final ({DateTime start, DateTime end}) activeRange = _resolveActiveRange();
    final DateTime start = activeRange.start;
    final DateTime end = activeRange.end;
    final int periodDays = end.difference(start).inDays + 1;
    final List<DailyStat> dailyStats = calculator.getDailyStats(start, end);
    final double globalRate = calculator.getGlobalCompletionRate(start, end);
    final DateTime previousEnd = start.subtract(const Duration(days: 1));
    final DateTime previousStart = previousEnd.subtract(
      Duration(days: periodDays - 1),
    );
    final double previousGlobalRate = calculator.getGlobalCompletionRate(
      previousStart,
      previousEnd,
    );
    final int totalScheduled = dailyStats.fold<int>(
      0,
      (int sum, DailyStat item) => sum + item.totalScheduled,
    );
    final int totalCompleted = dailyStats.fold<int>(
      0,
      (int sum, DailyStat item) => sum + item.totalCompleted,
    );
    final int overallPercent = (globalRate * 100).round();
    final double averageDailyCompletionRate = _computeAverageDailyRate(
      dailyStats,
    );
    final bool hasActiveScheduleInPeriod = dailyStats.any(
      (DailyStat item) => item.totalScheduled > 0,
    );
    final List<_PeriodActivityStat> periodActivityStats =
        _buildPeriodActivityStats(
          activities: activities,
          progressEntries: progressEntries,
          start: start,
          end: end,
        );
    final List<_TimeBucketStat> timeBucketStats = _buildTimeBucketStats(
      periodActivityStats,
      localeCode: localeCode,
    );
    final _StatsAiSummaryData summary = _buildStatsAiSummary(
      localeCode: localeCode,
      currentStats: dailyStats,
      periodActivityStats: periodActivityStats,
      timeBucketStats: timeBucketStats,
      averageDailyRate: averageDailyCompletionRate,
      currentGlobalRate: globalRate,
      previousGlobalRate: previousGlobalRate,
      hasActiveScheduleInPeriod: hasActiveScheduleInPeriod,
    );

    final List<_HighlightCardData> dayHighlights = _buildDayHighlights(
      dailyStats: dailyStats,
      localeCode: localeCode,
    );
    final _HighlightCardData? timeHighlight = _buildTimeHighlight(
      timeBucketStats,
      localeCode: localeCode,
    );
    final List<_HighlightCardData> fallbackMainInsightCards =
        <_HighlightCardData>[
          if (dayHighlights.isNotEmpty) dayHighlights.first,
          if (timeHighlight != null)
            timeHighlight
          else if (dayHighlights.length > 1)
            dayHighlights[1],
        ];
    final StatsMlRequest? statsMlRequest = _buildStatsMlRequest(
      periodActivityStats: periodActivityStats,
      globalStats: globalStats,
    );
    final StatsMlInsight? statsMlInsight = statsMlRequest == null
        ? null
        : ref.watch(statsMlInsightProvider(statsMlRequest)).valueOrNull;
    final List<_HighlightCardData> mainInsightCards = _resolveMainInsightCards(
      mlInsight: statsMlInsight,
      mlRequest: statsMlRequest,
      fallbackCards: fallbackMainInsightCards,
      localeCode: localeCode,
    );
    final _ActivityHighlightsData activityHighlights = _buildActivityHighlights(
      periodActivityStats,
      localeCode: localeCode,
    );
    final String periodLabel = _periodLabel(localeCode, start, end);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isId ? 'Statistik' : 'Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
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

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    24,
                    sidePadding,
                    AppSpacing.screenPadding,
                  ),
                  children: <Widget>[
                    _StatsHeroSection(
                      percent: overallPercent,
                      rate: globalRate,
                      totalCompleted: totalCompleted,
                      totalScheduled: totalScheduled,
                      periodLabel: periodLabel,
                      onPeriodTap: _pickCustomRange,
                      onReportTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isId
                                  ? 'Laporan detail sedang disiapkan.'
                                  : 'The detailed report is being prepared.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: _heroToInsightSpacing),
                    _StatsSmartSummarySection(
                      summary: summary,
                      activityHighlights: activityHighlights,
                      activityStats: periodActivityStats,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _StatsRangePreset { last7, last30, thisMonth, custom }

class _StatsDateRangeSheet extends StatefulWidget {
  const _StatsDateRangeSheet({
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
  State<_StatsDateRangeSheet> createState() => _StatsDateRangeSheetState();
}

class _StatsDateRangeSheetState extends State<_StatsDateRangeSheet> {
  late DateTime _start;
  late DateTime _end;
  late DateTime _visibleMonth;
  late _StatsRangePreset _preset;
  bool _selectingEnd = false;

  bool get _isId => widget.localeCode == 'id';

  @override
  void initState() {
    super.initState();
    _start = dateOnly(widget.initialRange.start);
    _end = dateOnly(widget.initialRange.end);
    _visibleMonth = DateTime(_end.year, _end.month);
    _preset = _detectPreset(_start, _end);
  }

  _StatsRangePreset _detectPreset(DateTime start, DateTime end) {
    final DateTime today = dateOnly(DateTime.now());
    if (_sameDay(end, today) && end.difference(start).inDays == 6) {
      return _StatsRangePreset.last7;
    }
    if (_sameDay(end, today) && end.difference(start).inDays == 29) {
      return _StatsRangePreset.last30;
    }
    if (start.day == 1 &&
        end.year == start.year &&
        end.month == start.month &&
        end.day == DateTime(start.year, start.month + 1, 0).day) {
      return _StatsRangePreset.thisMonth;
    }
    return _StatsRangePreset.custom;
  }

  void _selectPreset(_StatsRangePreset preset) {
    final DateTime today = dateOnly(DateTime.now());
    setState(() {
      _preset = preset;
      _selectingEnd = false;
      switch (preset) {
        case _StatsRangePreset.last7:
          _start = today.subtract(const Duration(days: 6));
          _end = today;
        case _StatsRangePreset.last30:
          _start = today.subtract(const Duration(days: 29));
          _end = today;
        case _StatsRangePreset.thisMonth:
          _start = DateTime(today.year, today.month);
          _end = DateTime(today.year, today.month + 1, 0);
        case _StatsRangePreset.custom:
          _selectingEnd = true;
      }
      _visibleMonth = DateTime(_end.year, _end.month);
    });
  }

  void _selectDay(DateTime day) {
    final DateTime selected = dateOnly(day);
    if (selected.isBefore(widget.firstDate) ||
        selected.isAfter(widget.lastDate)) {
      return;
    }
    setState(() {
      _preset = _StatsRangePreset.custom;
      if (!_selectingEnd) {
        _start = selected;
        _end = selected;
        _selectingEnd = true;
      } else if (selected.isBefore(_start)) {
        _end = _start;
        _start = selected;
        _selectingEnd = false;
      } else {
        _end = selected;
        _selectingEnd = false;
      }
    });
  }

  void _changeMonth(int offset) {
    final DateTime next = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final DateTime firstMonth = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );
    final DateTime lastMonth = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );
    if (next.isBefore(firstMonth) || next.isAfter(lastMonth)) {
      return;
    }
    setState(() => _visibleMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final int dayCount = _end.difference(_start).inDays + 1;
    final String rangeLabel =
        '${formatDateShort(_start, widget.localeCode)} - '
        '${formatDateShort(_end, widget.localeCode)}';

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: <Widget>[
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _isId ? 'Pilih periode' : 'Select period',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _isId ? 'Tutup' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.date_range_rounded, color: accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            rangeLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _isId
                                ? '$dayCount hari dipilih'
                                : '$dayCount days selected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _StatsRangePreset.values
                      .map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_presetLabel(preset)),
                            selected: _preset == preset,
                            showCheckmark: false,
                            selectedColor: accent,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerLowest,
                            side: BorderSide(
                              color: _preset == preset
                                  ? accent
                                  : theme.colorScheme.outlineVariant,
                            ),
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: _preset == preset
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onSelected: (_) => _selectPreset(preset),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: _isId ? 'Bulan sebelumnya' : 'Previous month',
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat(
                        'MMMM yyyy',
                        widget.localeCode,
                      ).format(_visibleMonth),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _isId ? 'Bulan berikutnya' : 'Next month',
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              _WeekdayHeader(isId: _isId),
              Expanded(
                child: _RangeCalendarGrid(
                  visibleMonth: _visibleMonth,
                  start: _start,
                  end: _end,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  accent: accent,
                  onDayTap: _selectDay,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(DateTimeRange(start: _start, end: _end)),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isId ? 'Terapkan periode' : 'Apply period'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _presetLabel(_StatsRangePreset preset) {
    return switch (preset) {
      _StatsRangePreset.last7 => _isId ? '7 Hari' : '7 Days',
      _StatsRangePreset.last30 => _isId ? '30 Hari' : '30 Days',
      _StatsRangePreset.thisMonth => _isId ? 'Bulan Ini' : 'This Month',
      _StatsRangePreset.custom => 'Custom',
    };
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.isId});

  final bool isId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> labels = isId
        ? const <String>['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
        : const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels
          .map((label) {
            return Expanded(
              child: SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _RangeCalendarGrid extends StatelessWidget {
  const _RangeCalendarGrid({
    required this.visibleMonth,
    required this.start,
    required this.end,
    required this.firstDate,
    required this.lastDate,
    required this.accent,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final DateTime start;
  final DateTime end;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accent;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime monthStart = DateTime(visibleMonth.year, visibleMonth.month);
    final DateTime gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (BuildContext context, int index) {
        final DateTime day = gridStart.add(Duration(days: index));
        final bool inVisibleMonth = day.month == visibleMonth.month;
        final bool enabled =
            !day.isBefore(dateOnly(firstDate)) &&
            !day.isAfter(dateOnly(lastDate));
        final bool isStart = _isSameDate(day, start);
        final bool isEnd = _isSameDate(day, end);
        final bool isEndpoint = isStart || isEnd;
        final bool inRange =
            !day.isBefore(dateOnly(start)) && !day.isAfter(dateOnly(end));

        return InkWell(
          onTap: enabled ? () => onDayTap(day) : null,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: inRange ? accent.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.horizontal(
                left: isStart ? const Radius.circular(8) : Radius.zero,
                right: isEnd ? const Radius.circular(8) : Radius.zero,
              ),
            ),
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEndpoint ? accent : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isEndpoint
                        ? Colors.white
                        : enabled && inVisibleMonth
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontWeight: isEndpoint ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

_StatsAiSummaryData _buildStatsAiSummary({
  required String localeCode,
  required List<DailyStat> currentStats,
  required List<_PeriodActivityStat> periodActivityStats,
  required List<_TimeBucketStat> timeBucketStats,
  required double averageDailyRate,
  required double currentGlobalRate,
  required double previousGlobalRate,
  required bool hasActiveScheduleInPeriod,
}) {
  final bool isId = localeCode == 'id';
  final List<DailyStat> activeDays = currentStats
      .where((DailyStat item) => item.totalScheduled > 0)
      .toList(growable: false);
  if (!hasActiveScheduleInPeriod || activeDays.isEmpty) {
    return _StatsAiSummaryData(
      eyebrow: isId ? 'Ringkasan pintar' : 'Smart overview',
      headline: isId
          ? 'Data minggu ini masih tipis'
          : 'Not enough data in this period',
      body: isId
          ? 'Selesaikan beberapa aktivitas dulu biar pola globalmu mulai kebaca.'
          : 'Complete a few activities first so your overall pattern can start to emerge.',
    );
  }

  final DailyStat best =
      ([...activeDays]..sort((DailyStat a, DailyStat b) {
            final int byRate = b.completionRate.compareTo(a.completionRate);
            if (byRate != 0) {
              return byRate;
            }
            return b.totalCompleted.compareTo(a.totalCompleted);
          }))
          .first;
  final String bestDayLabel = _weekdayLongLabel(best.date.weekday, localeCode);
  final int bestPercent = (best.completionRate * 100).round();

  final _TimeBucketStat? strongestTime = timeBucketStats.isEmpty
      ? null
      : ([...timeBucketStats]..sort((_TimeBucketStat a, _TimeBucketStat b) {
              final int byRate = b.completionRate.compareTo(a.completionRate);
              if (byRate != 0) {
                return byRate;
              }
              return b.completed.compareTo(a.completed);
            }))
            .first;

  final _PeriodActivityStat? strugglingActivity = _findStrugglingActivity(
    periodActivityStats,
  );
  final int averagePercent = (averageDailyRate * 100).round();
  final int deltaPercent =
      ((currentGlobalRate - previousGlobalRate).abs() * 100).round();

  String headline;
  String body;
  if (currentGlobalRate >= 0.85) {
    headline = isId ? 'Ritmemu lagi stabil' : 'Your rhythm looks stable';
    body = isId
        ? 'Puncaknya ada di $bestDayLabel ($bestPercent%)${strongestTime == null ? '' : ', dan paling enak dijaga saat ${strongestTime.label.toLowerCase()}.'}'
        : 'Your peak lands on $bestDayLabel ($bestPercent%)${strongestTime == null ? '.' : ', and ${strongestTime.label.toLowerCase()} works best for you.'}';
  } else if (currentGlobalRate >= 0.55) {
    headline = isId
        ? 'Minggu ini lumayan terjaga'
        : 'This week is fairly steady';
    body = isId
        ? 'Hari terkuatmu $bestDayLabel, dengan rata-rata $averagePercent% di hari aktif.'
        : 'Your strongest day is $bestDayLabel, with an average of $averagePercent% on active days.';
  } else {
    headline = isId
        ? 'Minggu ini masih perlu dirapikan'
        : 'This week still needs some tuning';
    body = strugglingActivity != null
        ? (isId
              ? '${strugglingActivity.activity.title} paling sering tertunda. ${strongestTime == null ? '' : 'Coba dorong ke ${strongestTime.label.toLowerCase()}.'}'
              : '${strugglingActivity.activity.title} is getting postponed the most. ${strongestTime == null ? '' : 'Try moving it to ${strongestTime.label.toLowerCase()}.'}')
        : (isId
              ? 'Hari terbaikmu tetap $bestDayLabel, tapi ritme minggu ini masih belum stabil.'
              : 'Your best day is still $bestDayLabel, but the weekly rhythm is not stable yet.');
  }

  final String? support = previousGlobalRate > 0
      ? (isId
            ? (currentGlobalRate >= previousGlobalRate
                  ? 'Naik $deltaPercent% dari periode sebelumnya.'
                  : 'Turun $deltaPercent% dari periode sebelumnya.')
            : (currentGlobalRate >= previousGlobalRate
                  ? 'Up $deltaPercent% from the previous period.'
                  : 'Down $deltaPercent% from the previous period.'))
      : null;

  return _StatsAiSummaryData(
    eyebrow: isId ? 'Ringkasan pintar' : 'Smart overview',
    headline: headline,
    body: body,
    support: support,
  );
}

double _computeAverageDailyRate(List<DailyStat> stats) {
  final List<DailyStat> activeDays = stats
      .where((DailyStat item) => !item.isNeutral)
      .toList();
  if (activeDays.isEmpty) {
    return 0;
  }

  final double totalRate = activeDays.fold<double>(
    0,
    (double sum, DailyStat item) => sum + item.completionRate,
  );
  return totalRate / activeDays.length;
}

List<_PeriodActivityStat> _buildPeriodActivityStats({
  required List<ActivityModel> activities,
  required List<ProgressEntryModel> progressEntries,
  required DateTime start,
  required DateTime end,
}) {
  final Map<String, ProgressEntryModel> progressByActivityAndDate =
      <String, ProgressEntryModel>{
        for (final ProgressEntryModel entry in progressEntries)
          '${entry.activityId}|${entry.dateKey}': entry,
      };
  final List<_PeriodActivityStat> stats = <_PeriodActivityStat>[];

  for (final ActivityModel activity in activities) {
    int scheduled = 0;
    int completed = 0;
    DateTime cursor = dateOnly(start);
    final DateTime activityStart = dateOnly(activity.createdAt);

    while (!cursor.isAfter(end)) {
      if (!cursor.isBefore(activityStart) &&
          activity.selectedDays.contains(cursor.weekday)) {
        final ProgressEntryModel? entry =
            progressByActivityAndDate['${activity.id}|${dateKeyFromDate(cursor)}'];
        if (entry?.isSkipped != true) {
          scheduled++;
          if (entry?.isCompleted == true) {
            completed++;
          }
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (scheduled > 0) {
      stats.add(
        _PeriodActivityStat(
          activity: activity,
          scheduled: scheduled,
          completed: completed,
        ),
      );
    }
  }

  return stats;
}

List<_TimeBucketStat> _buildTimeBucketStats(
  List<_PeriodActivityStat> activityStats, {
  required String localeCode,
}) {
  final Map<String, _TimeBucketStat> buckets = <String, _TimeBucketStat>{};
  for (final _PeriodActivityStat stat in activityStats) {
    final _TimeBucketStat seed = _timeBucketForMinutes(
      stat.activity.timeMinutes,
      localeCode: localeCode,
    );
    final _TimeBucketStat previous =
        buckets[seed.key] ??
        _TimeBucketStat(
          key: seed.key,
          label: seed.label,
          scheduled: 0,
          completed: 0,
        );
    buckets[seed.key] = previous.copyWith(
      scheduled: previous.scheduled + stat.scheduled,
      completed: previous.completed + stat.completed,
    );
  }
  return buckets.values
      .where((_TimeBucketStat item) => item.scheduled > 0)
      .toList(growable: false);
}

List<_HighlightCardData> _buildDayHighlights({
  required List<DailyStat> dailyStats,
  required String localeCode,
}) {
  final List<DailyStat> activeDays = dailyStats
      .where((DailyStat item) => item.totalScheduled > 0)
      .toList(growable: false);
  if (activeDays.isEmpty) {
    return <_HighlightCardData>[
      _HighlightCardData(
        title: localeCode == 'id' ? 'Hari terpadat' : 'Busiest day',
        value: '-',
        detail: localeCode == 'id'
            ? 'Belum ada jadwal aktif di periode ini.'
            : 'No active schedule in this period yet.',
        icon: Icons.calendar_today_rounded,
      ),
    ];
  }

  final DailyStat busiestDay =
      ([...activeDays]..sort((DailyStat a, DailyStat b) {
            final int byScheduled = b.totalScheduled.compareTo(
              a.totalScheduled,
            );
            if (byScheduled != 0) {
              return byScheduled;
            }
            return b.totalCompleted.compareTo(a.totalCompleted);
          }))
          .first;

  return <_HighlightCardData>[
    _HighlightCardData(
      title: localeCode == 'id' ? 'Hari paling sibuk' : 'Busiest day',
      value: _weekdayLongLabel(busiestDay.date.weekday, localeCode),
      detail: localeCode == 'id'
          ? '${busiestDay.totalScheduled} aktivitas terjadwal.'
          : '${busiestDay.totalScheduled} activities were scheduled.',
      icon: Icons.event_note_rounded,
    ),
  ];
}

_HighlightCardData? _buildTimeHighlight(
  List<_TimeBucketStat> timeBucketStats, {
  required String localeCode,
}) {
  if (timeBucketStats.isEmpty) {
    return null;
  }

  final _TimeBucketStat strongest =
      ([...timeBucketStats]..sort((_TimeBucketStat a, _TimeBucketStat b) {
            final int byRate = b.completionRate.compareTo(a.completionRate);
            if (byRate != 0) {
              return byRate;
            }
            return b.completed.compareTo(a.completed);
          }))
          .first;

  return _HighlightCardData(
    title: localeCode == 'id' ? 'Slot paling efektif' : 'Best time slot',
    value: strongest.label,
    detail: localeCode == 'id'
        ? '${(strongest.completionRate * 100).round()}% selesai di slot ini.'
        : '${(strongest.completionRate * 100).round()}% completed in this slot.',
    icon: Icons.schedule_rounded,
  );
}

StatsMlRequest? _buildStatsMlRequest({
  required List<_PeriodActivityStat> periodActivityStats,
  required GlobalStats globalStats,
}) {
  final List<_PeriodActivityStat> candidates = periodActivityStats
      .where((_PeriodActivityStat item) => item.scheduled > 0)
      .toList(growable: false);
  if (candidates.isEmpty) {
    return null;
  }

  candidates.sort((_PeriodActivityStat a, _PeriodActivityStat b) {
    final int byScheduled = b.scheduled.compareTo(a.scheduled);
    if (byScheduled != 0) {
      return byScheduled;
    }
    final int byCompleted = b.completed.compareTo(a.completed);
    if (byCompleted != 0) {
      return byCompleted;
    }
    return a.activity.title.compareTo(b.activity.title);
  });

  final _PeriodActivityStat dominant = candidates.first;
  int streak = 0;
  for (final ActivityBreakdown breakdown in globalStats.breakdowns) {
    if (breakdown.activity.id == dominant.activity.id) {
      streak = breakdown.currentStreak;
      break;
    }
  }

  return StatsMlRequest(
    dominantActivityTitle: dominant.activity.title,
    totalScheduled: dominant.scheduled,
    totalCompleted: dominant.completed,
    streak: streak,
  );
}

List<_HighlightCardData> _resolveMainInsightCards({
  required StatsMlInsight? mlInsight,
  required StatsMlRequest? mlRequest,
  required List<_HighlightCardData> fallbackCards,
  required String localeCode,
}) {
  if (mlRequest != null && !_hasReliableStatsMlSignal(mlRequest)) {
    return fallbackCards.take(2).toList(growable: false);
  }

  final List<_HighlightCardData> cards = <_HighlightCardData>[];
  if (mlInsight != null && mlRequest != null) {
    cards.addAll(
      _buildMlInsightCards(
        insight: mlInsight,
        request: mlRequest,
        localeCode: localeCode,
      ),
    );
  } else if (mlRequest != null) {
    cards.add(
      _buildThinMlSignalCard(request: mlRequest, localeCode: localeCode),
    );
  }

  for (final _HighlightCardData fallback in fallbackCards) {
    if (cards.length >= 2) {
      break;
    }
    cards.add(fallback);
  }
  return cards.take(2).toList(growable: false);
}

bool _hasReliableStatsMlSignal(StatsMlRequest request) {
  if (request.totalScheduled < 4) {
    return false;
  }
  return request.completionRate > 0 || request.streak > 0;
}

_HighlightCardData _buildThinMlSignalCard({
  required StatsMlRequest request,
  required String localeCode,
}) {
  final bool isId = localeCode == 'id';
  return _HighlightCardData(
    title: isId ? 'Sinyal ML' : 'ML signal',
    value: isId ? 'Belum cukup data' : 'Not enough data yet',
    detail: isId
        ? 'Butuh lebih banyak jadwal aktif untuk membaca pola ${request.dominantActivityTitle.toLowerCase()}.'
        : 'More active schedule data is needed to read ${request.dominantActivityTitle.toLowerCase()}.',
    icon: Icons.insights_rounded,
  );
}

List<_HighlightCardData> _buildMlInsightCards({
  required StatsMlInsight insight,
  required StatsMlRequest request,
  required String localeCode,
}) {
  final bool isId = localeCode == 'id';
  final List<_HighlightCardData> cards = <_HighlightCardData>[];
  if (insight.isConsistent != null) {
    cards.add(
      _HighlightCardData(
        title: isId ? 'Konsistensi ritme' : 'Rhythm consistency',
        value: insight.isConsistent!
            ? (isId ? 'Mulai stabil' : 'Starting to stabilize')
            : (isId ? 'Masih berubah' : 'Still fluctuating'),
        detail: insight.isConsistent!
            ? (isId
                  ? '${insight.referenceActivityTitle} mulai menunjukkan pola yang lebih rapi.'
                  : '${insight.referenceActivityTitle} is starting to show a steadier pattern.')
            : (isId
                  ? '${insight.referenceActivityTitle} masih butuh ritme yang lebih konsisten.'
                  : '${insight.referenceActivityTitle} still needs a more consistent rhythm.'),
        icon: Icons.show_chart_rounded,
      ),
    );
  }

  if (insight.effectiveSlotKey != null) {
    final String slotLabel = _slotLabel(insight.effectiveSlotKey!, localeCode);
    cards.add(
      _HighlightCardData(
        title: isId ? 'Slot yang disarankan' : 'Suggested slot',
        value: slotLabel,
        detail: isId
            ? 'Prediksi lokal menyarankan menjaga aktivitas dominanmu di slot ini.'
            : 'Local prediction suggests keeping your dominant activity in this slot.',
        icon: Icons.schedule_rounded,
      ),
    );
  }

  return cards;
}

String _slotLabel(String slotKey, String localeCode) {
  final bool isId = localeCode == 'id';
  switch (slotKey) {
    case 'morning':
      return isId ? 'Pagi' : 'Morning';
    case 'midday':
      return isId ? 'Siang' : 'Midday';
    case 'afternoon':
      return isId ? 'Sore' : 'Afternoon';
    default:
      return isId ? 'Malam' : 'Night';
  }
}

_ActivityHighlightsData _buildActivityHighlights(
  List<_PeriodActivityStat> activityStats, {
  required String localeCode,
}) {
  if (activityStats.isEmpty) {
    return _ActivityHighlightsData(
      strongestTitle: '-',
      strongestDetail: localeCode == 'id'
          ? 'Belum ada aktivitas aktif di periode ini.'
          : 'No active activities in this period.',
      strugglingTitle: '-',
      strugglingDetail: localeCode == 'id'
          ? 'Belum ada data aktivitas yang tertunda.'
          : 'No delayed activity data yet.',
    );
  }

  final List<_PeriodActivityStat> sortedByStrength = [...activityStats]
    ..sort((_PeriodActivityStat a, _PeriodActivityStat b) {
      final int byRate = b.completionRate.compareTo(a.completionRate);
      if (byRate != 0) {
        return byRate;
      }
      return b.completed.compareTo(a.completed);
    });
  final _PeriodActivityStat strongest = sortedByStrength.first;
  final _PeriodActivityStat? struggling = _findStrugglingActivity(
    activityStats,
  );

  return _ActivityHighlightsData(
    strongestTitle: strongest.activity.title,
    strongestDetail: localeCode == 'id'
        ? '${strongest.completed}/${strongest.scheduled} selesai, paling stabil di periode ini.'
        : '${strongest.completed}/${strongest.scheduled} completed, the most stable in this period.',
    strugglingTitle: struggling?.activity.title ?? '-',
    strugglingDetail: struggling == null
        ? (localeCode == 'id'
              ? 'Belum ada aktivitas yang benar-benar tertinggal.'
              : 'No activity is clearly lagging behind yet.')
        : (localeCode == 'id'
              ? '${struggling.incomplete} kali belum selesai pada periode ini.'
              : '${struggling.incomplete} incomplete occurrences in this period.'),
  );
}

_PeriodActivityStat? _findStrugglingActivity(List<_PeriodActivityStat> stats) {
  final List<_PeriodActivityStat> candidates = stats
      .where((_PeriodActivityStat item) => item.incomplete > 0)
      .toList(growable: false);
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((_PeriodActivityStat a, _PeriodActivityStat b) {
    final int byIncomplete = b.incomplete.compareTo(a.incomplete);
    if (byIncomplete != 0) {
      return byIncomplete;
    }
    return a.completionRate.compareTo(b.completionRate);
  });
  return candidates.first;
}

_TimeBucketStat _timeBucketForMinutes(
  int minutes, {
  required String localeCode,
}) {
  if (minutes >= 5 * 60 && minutes < 12 * 60) {
    return _TimeBucketStat(
      key: 'morning',
      label: localeCode == 'id' ? 'Pagi' : 'Morning',
      scheduled: 0,
      completed: 0,
    );
  }
  if (minutes >= 12 * 60 && minutes < 15 * 60) {
    return _TimeBucketStat(
      key: 'midday',
      label: localeCode == 'id' ? 'Siang' : 'Midday',
      scheduled: 0,
      completed: 0,
    );
  }
  if (minutes >= 15 * 60 && minutes < 18 * 60) {
    return _TimeBucketStat(
      key: 'afternoon',
      label: localeCode == 'id' ? 'Sore' : 'Afternoon',
      scheduled: 0,
      completed: 0,
    );
  }
  return _TimeBucketStat(
    key: 'night',
    label: localeCode == 'id' ? 'Malam' : 'Night',
    scheduled: 0,
    completed: 0,
  );
}

String _weekdayLongLabel(int weekday, String localeCode) {
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

enum _StatsFilterMode { last7, custom }



class _StatsHeroSection extends StatelessWidget {
  const _StatsHeroSection({
    required this.percent,
    required this.rate,
    required this.totalCompleted,
    required this.totalScheduled,
    required this.periodLabel,
    required this.onPeriodTap,
    required this.onReportTap,
  });

  final int percent;
  final double rate;
  final int totalCompleted;
  final int totalScheduled;
  final String periodLabel;
  final VoidCallback onPeriodTap;
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Decorative blue blur in top right
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Row with title and picker button
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      isId
                          ? 'COMPLETION RATE GLOBAL'
                          : 'GLOBAL COMPLETION RATE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.74,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onPeriodTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            periodLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row with rate value and report button
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '$percent%',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: onReportTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            isId ? 'Lihat Laporan Lengkap' : 'View Full Report',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsSmartSummarySection extends StatelessWidget {
  const _StatsSmartSummarySection({
    required this.summary,
    required this.activityHighlights,
    required this.activityStats,
  });

  final _StatsAiSummaryData summary;
  final _ActivityHighlightsData activityHighlights;
  final List<_PeriodActivityStat> activityStats;

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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary.eyebrow,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Nous',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.76),
              height: 1.4,
              fontSize: 14,
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
          if (activityStats.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              isId ? 'PERFORMA AKTIVITAS' : 'ACTIVITY PERFORMANCE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Column(
            children: <Widget>[
              _ActivityHighlightRow(
                title: isId ? 'STABIL' : 'STABLE',
                value: activityHighlights.strongestTitle,
                detail: activityHighlights.strongestDetail,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _ActivityHighlightRow(
                title: isId ? 'PERINGATAN' : 'WARNING',
                value: activityHighlights.strugglingTitle,
                detail: activityHighlights.strugglingDetail,
                color: const Color(0xFFBA1A1A),
                isWarning: true,
              ),
            ],
          ),
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
    final Color surfaceColor = isWarning
        ? const Color(0xFFFFF7F7)
        : const Color(0xFFF1F3FF);
    final Color borderColor = isWarning
        ? const Color(0xFFFAD7D9)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.15);
    final Color iconBgColor = color.withValues(alpha: 0.12);
    final IconData icon = isWarning
        ? Icons.warning_amber_rounded
        : Icons.verified_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isWarning ? color : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isWarning
                        ? color.withValues(alpha: 0.78)
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.64,
                          ),
                    height: 1.3,
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

class _AdditionalSummarySection extends StatelessWidget {
  const _AdditionalSummarySection({
    required this.totalScheduled,
    required this.totalCompleted,
    required this.averageDailyRate,
  });

  final int totalScheduled;
  final int totalCompleted;
  final double averageDailyRate;

  @override
  Widget build(BuildContext context) {
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final int averagePercent = (averageDailyRate * 100).round();
    final int incomplete = (totalScheduled - totalCompleted).clamp(
      0,
      totalScheduled,
    );

    final List<({String label, String value})> metrics =
        <({String label, String value})>[
          (label: isId ? 'Terjadwal' : 'Scheduled', value: '$totalScheduled'),
          (label: isId ? 'Selesai' : 'Completed', value: '$totalCompleted'),
          (label: isId ? 'Belum selesai' : 'Incomplete', value: '$incomplete'),
          (
            label: isId ? 'Rata-rata harian' : 'Daily average',
            value: '$averagePercent%',
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            isId ? 'Statistik Aktivitas' : 'Activity Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics.map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: _SummaryCell(label: item.label, value: item.value),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsAiSummaryData {
  const _StatsAiSummaryData({
    required this.eyebrow,
    required this.headline,
    required this.body,
    this.support,
  });

  final String eyebrow;
  final String headline;
  final String body;
  final String? support;
}

class _ActivityHighlightsData {
  const _ActivityHighlightsData({
    required this.strongestTitle,
    required this.strongestDetail,
    required this.strugglingTitle,
    required this.strugglingDetail,
  });

  final String strongestTitle;
  final String strongestDetail;
  final String strugglingTitle;
  final String strugglingDetail;
}

class _HighlightCardData {
  const _HighlightCardData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
}

class _PeriodActivityStat {
  const _PeriodActivityStat({
    required this.activity,
    required this.scheduled,
    required this.completed,
  });

  final ActivityModel activity;
  final int scheduled;
  final int completed;

  int get incomplete => (scheduled - completed).clamp(0, scheduled);

  double get completionRate {
    if (scheduled == 0) {
      return 0;
    }
    return completed / scheduled;
  }
}

class _TimeBucketStat {
  const _TimeBucketStat({
    required this.key,
    required this.label,
    required this.scheduled,
    required this.completed,
  });

  final String key;
  final String label;
  final int scheduled;
  final int completed;

  double get completionRate {
    if (scheduled == 0) {
      return 0;
    }
    return completed / scheduled;
  }

  _TimeBucketStat copyWith({int? scheduled, int? completed}) {
    return _TimeBucketStat(
      key: key,
      label: label,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }
}
