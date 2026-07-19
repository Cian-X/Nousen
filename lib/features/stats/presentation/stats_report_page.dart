import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart'; // Import this to use _PeriodActivityStat
import 'package:liburan_create/features/stats/domain/stats_view_models.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/l10n/app_localizations.dart';

class StatsReportPage extends ConsumerWidget {
  const StatsReportPage({
    super.key,
    required this.dailyStats,
    required this.periodActivityStats,
    required this.start,
    required this.end,
    required this.totalScheduled,
    required this.localeCode,
  });

  final List<DailyStat> dailyStats;
  final List<_PeriodActivityStat> periodActivityStats;
  final DateTime start;
  final DateTime end;
  final int totalScheduled;
  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    // Filter to last 7 days for weekly stats section
    final List<DailyStat> weeklyStats = dailyStats.length <= 7
        ? dailyStats
        : dailyStats.sublist(dailyStats.length - 7);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.statsReportTitle),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (totalScheduled > 0) ...[
            _WeeklyStatusSection(
              points: weeklyStats,
              localeCode: localeCode,
              totalScheduledForPeriod: totalScheduled,
            ),
            const SizedBox(height: 24),
            _ActivityBreakdownChart(
              stats: periodActivityStats,
              localeCode: localeCode,
            ),
          ] else
            _EmptyStatsReportPanel(localeCode: localeCode),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGETS DARI STATS_PAGE.DART YANG DIPINDAH KE SINI
// =========================================================================

class _ActivityBreakdownChart extends StatelessWidget {
  const _ActivityBreakdownChart({required this.stats, required this.localeCode});
  final List<_PeriodActivityStat> stats;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_PeriodActivityStat> sortedStats = [...stats]
      ..sort((a, b) => b.completionRate.compareTo(a.completionRate));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              AppLocalizations.of(context)!.breakdownPerActivity,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...sortedStats.map((stat) {
            final double progress = stat.completionRate;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        stat.activity.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _statusColor(progress, theme),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _statusColor(double progress, ThemeData theme) {
    if (progress >= 0.8) return theme.colorScheme.primary;
    if (progress >= 0.4) return const Color(0xFFF59E0B);
    return theme.colorScheme.error;
  }
}

class _WeeklyStatusSection extends StatelessWidget {
  const _WeeklyStatusSection({required this.points, required this.localeCode, required this.totalScheduledForPeriod});

  final List<DailyStat> points;
  final String localeCode;
  final int totalScheduledForPeriod;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final DateTime today = dateOnly(DateTime.now());

    // Sort points Sen-Min
    final List<DailyStat> orderedPoints = [...points]
      ..sort(
        (DailyStat a, DailyStat b) => a.date.weekday.compareTo(b.date.weekday),
      );

    // Calculate global completion rate for the period
    final int totalScheduled = orderedPoints.fold<int>(
      0,
      (sum, p) => sum + p.totalScheduled,
    );
    final int totalCompleted = orderedPoints.fold<int>(
      0,
      (sum, p) => sum + p.totalCompleted,
    );
    final double completionRate = totalScheduled > 0
        ? totalCompleted / totalScheduled
        : 0;
    final int completionPercent = (completionRate * 100).round();

    final int activeDays = orderedPoints
        .where((DailyStat p) => p.totalScheduled > 0)
        .length;

    // NEW: Max and Min completion rates for highlighting
    final double maxCompletionRate = orderedPoints.isEmpty
        ? 0
        : orderedPoints
            .where((p) => p.totalScheduled > 0) // Only consider days with scheduled activities
            .map((p) => p.completionRate)
            .fold(0.0, (a, b) => a > b ? a : b);
    final double minCompletionRate = orderedPoints.isEmpty
        ? 1.0
        : orderedPoints
            .where((p) => p.totalScheduled > 0) // Only consider days with scheduled activities
            .map((p) => p.completionRate)
            .fold(1.0, (a, b) => a < b ? a : b);

    // Warna badge header sesuai completion rate
    final Color weekColor;
    if (completionRate == 0 && totalScheduled > 0) {
      // Merah: ada jadwal tapi tidak ada yang selesai
      weekColor = const Color(0xFFBA1A1A);
    } else if (completionRate >= 1.0) {
      // Biru: sempurna
      weekColor = const Color(0xFF1A5BAD);
    } else if (completionRate > 0) {
      // Orange: progres parsial
      weekColor = const Color(0xFFF59E0B);
    } else {
      // Abu-abu/default
      weekColor = theme.colorScheme.outlineVariant;
    }

    // Chart geometry constants
    const double maxBarH = 108.0;
    const double pctLabelH = 14.0;
    const double pctToBarGap = 4.0;
    const double barToDayGap = 10.0;
    const double dayLabelH = 20.0; // enough room for pill
    const double chartH =
        pctLabelH + pctToBarGap + maxBarH + barToDayGap + dayLabelH;
    // 50% reference line sits at this offset from the bottom of the Stack
    const double refLineBottom = barToDayGap + dayLabelH + (maxBarH * 0.5);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Header ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isId ? 'Progres Mingguan' : 'Weekly Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isId
                          ? '$activeDays hari aktif minggu ini'
                          : '$activeDays active days this week',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.42,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: weekColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completionPercent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Chart area ──────────────────────────────────────
          SizedBox(
            height: chartH,
            child: Stack(
              children: <Widget>[
                // 50 % reference dashed line
                Positioned(
                  bottom: refLineBottom,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List<Widget>.generate(14, (int i) {
                      final bool show = i.isEven;
                      return Expanded(
                        child: Container(
                          height: 1,
                          color: show
                              ? theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.28,
                                )
                              : Colors.transparent,
                        ),
                      );
                    }),
                  ),
                ),
                // Bars
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(orderedPoints.length, (
                    int index,
                  ) {
                    final DailyStat point = orderedPoints[index];
                        final double rate = point.completionRate;
                        final bool hasData = point.totalScheduled > 0;
                        final bool isToday = dateOnly(point.date) == today;
                        
                        final bool isMaxDay = hasData && point.completionRate == maxCompletionRate && maxCompletionRate > 0;
                        final bool isMinDay = hasData && point.completionRate == minCompletionRate && minCompletionRate < 0.99 && point.completionRate > 0; // Avoid highlighting 0% completion as min if no data

                        // Warna berdasarkan status proses
                        final Color barColor;
                    if (!hasData) {
                      // Abu-abu: tidak ada jadwal
                      barColor = theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.2,
                      );
                    } else if (rate == 0) {
                      // Merah: dijadwalkan tapi tidak dikerjakan
                      barColor = const Color(0xFFBA1A1A);
                    } else if (rate < 1.0) {
                      // Orange: sudah proses tapi belum selesai
                      barColor = const Color(0xFFF59E0B);
                    } else {
                      // Biru: selesai sempurna (default success)
                      barColor = const Color(0xFF1A5BAD);
                    }

                    // fill: minimum 5% height when data exists
                    final double fillH = rate > 0
                        ? maxBarH * rate.clamp(0.05, 1.0)
                        : (hasData ? 4.0 : 0.0);
                    final int pct = (rate * 100).round();

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isToday ? 1.0 : 2.5,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            // Icon for highlight
                            if (isMaxDay && hasData)
                              Icon(Icons.star_rounded, size: 14, color: barColor)
                            else if (isMinDay && hasData)
                              Icon(Icons.warning_rounded, size: 14, color: barColor)
                            else
                              const SizedBox(height: 14), // placeholder to keep alignment
                            const SizedBox(height: 4), // Small gap between icon and bar
                            // % label
                            SizedBox(
                              height: pctLabelH,
                              child: hasData && rate > 0
                                  ? Text(
                                      '$pct%',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontSize: 9,
                                            fontWeight: isToday
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isToday
                                                ? barColor
                                                : barColor.withValues(
                                                    alpha: 0.68,
                                                  ),
                                          ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: pctToBarGap),

                            // Bar: flat track and solid fill.
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: <Widget>[
                                // Track
                                Container(
                                  width: double.infinity,
                                  height: maxBarH,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? barColor.withValues(alpha: 0.12)
                                        : theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Animated fill
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: fillH,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isMaxDay && hasData
                                        ? Border.all(color: Colors.white, width: 2)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: barToDayGap),
                            // Day label
                            Text(
                              weekdayShortLabel(point.date.weekday, localeCode),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: (isToday || isMaxDay || isMinDay)
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isToday
                                    ? barColor
                                    : (isMaxDay || isMinDay)
                                        ? barColor
                                        : theme.colorScheme.onSurfaceVariant,
                                fontSize: (isToday || isMaxDay || isMinDay)
                                    ? 10
                                    : 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatsReportPanel extends StatelessWidget {
  const _EmptyStatsReportPanel({required this.localeCode});
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            localeCode == 'id'
                ? 'Tidak ada data aktivitas yang terjadwal dalam periode ini.'
                : 'No scheduled activities found in this period.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localeCode == 'id'
                ? 'Silakan pilih periode lain atau tambahkan aktivitas.'
                : 'Please select another period or add activities.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
