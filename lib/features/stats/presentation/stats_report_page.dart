import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/core/constants/ai_demo_config.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/features/stats/domain/stats_view_models.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

enum _DayIntensity { high, medium, rest }

class _MatrixDay {
  const _MatrixDay({required this.date, required this.intensity});

  final DateTime date;
  final _DayIntensity intensity;
}

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
  final List<PeriodActivityStat> periodActivityStats;
  final DateTime start;
  final DateTime end;
  final int totalScheduled;
  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = localeCode == 'id';
    final DateTime today = dateOnly(DateTime.now());
    final DateTime windowStart = today.subtract(const Duration(days: 29));
    final List<DailyStat> days = ref
        .watch(globalScheduledStatsCalculatorProvider)
        .getDailyStats(windowStart, today);
    final Map<String, DailyStat> byKey = <String, DailyStat>{
      for (final DailyStat d in days) dateKeyFromDate(dateOnly(d.date)): d,
    };

    final List<_MatrixDay> cells = <_MatrixDay>[];
    for (int i = 0; i < 30; i++) {
      final DateTime date = windowStart.add(Duration(days: i));
      final DailyStat? stat = byKey[dateKeyFromDate(date)];
      final double rate = stat?.completionRate ?? 0;
      final int completed = stat?.totalCompleted ?? 0;
      final _DayIntensity intensity;
      if (completed > 0 && rate >= 0.8) {
        intensity = _DayIntensity.high;
      } else if (completed > 0) {
        intensity = _DayIntensity.medium;
      } else {
        intensity = _DayIntensity.rest;
      }
      cells.add(_MatrixDay(date: date, intensity: intensity));
    }

    final int activeDays = cells
        .where((_MatrixDay c) => c.intensity != _DayIntensity.rest)
        .length;
    final int activePercent = ((activeDays / 30) * 100).round();

    final Map<int, List<double>> ratesByWeekday = <int, List<double>>{};
    for (final _MatrixDay cell in cells) {
      final DailyStat? stat = byKey[dateKeyFromDate(cell.date)];
      if (stat == null || stat.isNeutral || stat.totalScheduled == 0) {
        continue;
      }
      ratesByWeekday
          .putIfAbsent(cell.date.weekday, () => <double>[])
          .add(stat.completionRate);
    }
    final List<MapEntry<int, double>> averaged = ratesByWeekday.entries
        .map(
          (e) => MapEntry<int, double>(
            e.key,
            e.value.reduce((a, b) => a + b) / e.value.length,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final String peakLabel = averaged
        .take(2)
        .map((e) => weekdayShortLabel(e.key, localeCode))
        .join(' & ');

    final List<DateTime> activeDates = cells
        .where((_MatrixDay c) => c.intensity != _DayIntensity.rest)
        .map((_MatrixDay c) => c.date)
        .toList();
    double? averageGap;
    if (activeDates.length >= 2) {
      int totalGap = 0;
      for (int i = 1; i < activeDates.length; i++) {
        totalGap += activeDates[i].difference(activeDates[i - 1]).inDays;
      }
      averageGap = totalGap / (activeDates.length - 1);
    }

    int weekendScheduled = 0;
    int weekendCompleted = 0;
    int weekdayScheduled = 0;
    int weekdayCompleted = 0;
    for (final _MatrixDay cell in cells) {
      final DailyStat? stat = byKey[dateKeyFromDate(cell.date)];
      if (stat == null || stat.totalScheduled == 0) {
        continue;
      }
      final bool isWeekend =
          cell.date.weekday == DateTime.saturday ||
          cell.date.weekday == DateTime.sunday;
      if (isWeekend) {
        weekendScheduled += stat.totalScheduled;
        weekendCompleted += stat.totalCompleted;
      } else {
        weekdayScheduled += stat.totalScheduled;
        weekdayCompleted += stat.totalCompleted;
      }
    }
    final double? weekendRate = weekendScheduled == 0
        ? null
        : weekendCompleted / weekendScheduled;
    final double? weekdayRate = weekdayScheduled == 0
        ? null
        : weekdayCompleted / weekdayScheduled;

    final int leadingBlanks = (windowStart.weekday - 1) % 7;
    final bool mlEnabled = AiDemoConfig.onDeviceMlEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isId ? 'Matriks Konsistensi' : 'Consistency Matrix',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                icon: NousenNavIcon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            isId ? 'Evaluasi performa 30 hari' : '30-day performance review',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Container(
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'AKTIVITAS HARIAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.05,
                              color: Color(0xFF3B7BD6),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Distribusi Ritme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isId
                            ? '$activeDays/30 hari aktif'
                            : '$activeDays/30 active days',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          for (int w = 1; w <= 7; w++)
                            Expanded(
                              child: Center(
                                child: Text(
                                  weekdayShortLabel(w, localeCode),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: leadingBlanks + cells.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (index < leadingBlanks) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                            );
                          }
                          final _MatrixDay cell =
                              cells[index - leadingBlanks];
                          final Color bg;
                          final Color fg;
                          switch (cell.intensity) {
                            case _DayIntensity.high:
                              bg = const Color(0xFF3B7BD6);
                              fg = Colors.white;
                            case _DayIntensity.medium:
                              bg = const Color(0xFF93C5FD);
                              fg = const Color(0xFF3B7BD6);
                            case _DayIntensity.rest:
                              bg = const Color(0xFFE2E8F0);
                              fg = const Color(0xFF94A3B8);
                          }
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cell.date.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Text(
                            isId ? 'Intensitas' : 'Intensity',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const Spacer(),
                          _LegendDot(
                            color: const Color(0xFFE2E8F0),
                            label: isId ? 'Rehat' : 'Rest',
                          ),
                          const SizedBox(width: 12),
                          _LegendDot(
                            color: const Color(0xFF93C5FD),
                            label: isId ? 'Sedang' : 'Medium',
                          ),
                          const SizedBox(width: 12),
                          _LegendDot(
                            color: const Color(0xFF3B7BD6),
                            label: isId ? 'Tinggi' : 'High',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MatrixMetricPill(
                        icon: Icons.check_circle_rounded,
                        iconColor: const Color(0xFF3B7BD6),
                        title: '$activeDays ${isId ? 'Hari' : 'days'}'
                            ' ($activePercent%)',
                        subtitle: isId ? 'Konsisten Aktif' : 'Actively consistent',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MatrixMetricPill(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFD97706),
                        title: peakLabel.isEmpty
                            ? (isId ? 'Belum ada pola' : 'No pattern yet')
                            : peakLabel,
                        subtitle: isId ? 'Ritme Puncak' : 'Peak rhythm',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              NousenNavIcon(
                Icons.insights_rounded,
                size: 18,
                color: Color(0xFF3B7BD6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isId
                      ? 'Evaluasi & Catatan${mlEnabled ? ' AI' : ''}'
                      : 'Evaluation & Notes${mlEnabled ? ' AI' : ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Text(
                'DATA AKTUAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MatrixEvalCard(
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            title: isId ? 'Ketahanan Ritme' : 'Rhythm resilience',
            badge: '$activeDays/30',
            badgeBg: const Color(0xFFECFDF5),
            badgeColor: const Color(0xFF059669),
            body: averageGap == null
                ? (isId
                      ? 'Belum cukup sesi aktif untuk mengukur jeda ritme.'
                      : 'Not enough active sessions to measure rhythm gaps.')
                : (isId
                      ? 'Rata-rata jeda ${averageGap.toStringAsFixed(1)} hari antar sesi aktif dalam 30 hari terakhir.'
                      : 'Average gap of ${averageGap.toStringAsFixed(1)} days between active sessions in the last 30 days.'),
          ),
          const SizedBox(height: 12),
          _MatrixEvalCard(
            icon: Icons.schedule_rounded,
            iconBg: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFD97706),
            title: isId ? 'Pola Akhir Pekan' : 'Weekend pattern',
            badge: (weekendRate == null || weekdayRate == null)
                ? null
                : '${((weekendRate - weekdayRate) * 100).round()}%',
            badgeBg: (weekendRate ?? 0) >= (weekdayRate ?? 0)
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFFFBEB),
            badgeColor: (weekendRate ?? 0) >= (weekdayRate ?? 0)
                ? const Color(0xFF059669)
                : const Color(0xFFD97706),
            body: (weekendRate == null || weekdayRate == null)
                ? (isId
                      ? 'Belum ada data akhir pekan atau hari kerja untuk dibandingkan.'
                      : 'No weekend or weekday data to compare yet.')
                : (isId
                      ? 'Akhir pekan ${(weekendRate * 100).round()}% vs hari kerja ${(weekdayRate * 100).round()}% dari sesi terjadwal yang selesai.'
                      : 'Weekends ${(weekendRate * 100).round()}% vs weekdays ${(weekdayRate * 100).round()} of scheduled sessions done.'),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _MatrixMetricPill extends StatelessWidget {
  const _MatrixMetricPill({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: NousenNavIcon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
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

class _MatrixEvalCard extends StatelessWidget {
  const _MatrixEvalCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.body,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? badge;
  final Color badgeBg;
  final Color badgeColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    final String? badgeText = badge;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: NousenNavIcon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF475569),
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
