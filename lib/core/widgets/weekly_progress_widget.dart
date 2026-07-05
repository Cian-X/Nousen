import 'package:flutter/material.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';

enum WeeklyProgressDayVisualState {
  complete,
  partial,
  missed,
  pending,
  future,
  notScheduled,
}

@immutable
class WeeklyProgressDayData {
  const WeeklyProgressDayData({
    required this.date,
    required this.progress,
    required this.state,
    this.tooltip,
  });

  final DateTime date;
  final double progress;
  final WeeklyProgressDayVisualState state;
  final String? tooltip;

  double get normalizedProgress => progress.clamp(0.0, 1.0).toDouble();
}

WeeklyProgressDayVisualState resolveWeeklyProgressVisualStateFromCounts({
  required DateTime date,
  required DateTime today,
  required int totalScheduled,
  required int totalCompleted,
}) {
  final DateTime day = dateOnly(date);
  final DateTime todayDate = dateOnly(today);
  if (day.isAfter(todayDate)) {
    return WeeklyProgressDayVisualState.future;
  }
  if (totalScheduled <= 0) {
    return WeeklyProgressDayVisualState.notScheduled;
  }
  if (totalCompleted >= totalScheduled) {
    return WeeklyProgressDayVisualState.complete;
  }
  if (totalCompleted > 0) {
    return WeeklyProgressDayVisualState.partial;
  }
  return WeeklyProgressDayVisualState.pending;
}

double weeklyProgressBarHeight(double progress) {
  final double normalized = progress.clamp(0.0, 1.0).toDouble();
  if (normalized <= 0) {
    return 4;
  }
  if (normalized <= 0.30) {
    return 12;
  }
  if (normalized <= 0.70) {
    return 20;
  }
  if (normalized < 1) {
    return 28;
  }
  return 36;
}

Color weeklyProgressBarColor({
  required ThemeData theme,
  required WeeklyProgressDayVisualState state,
}) {
  return switch (state) {
    WeeklyProgressDayVisualState.complete => theme.colorScheme.primary,
    WeeklyProgressDayVisualState.partial => const Color(0xFFF59E0B),
    WeeklyProgressDayVisualState.missed => const Color(0xFFEF4444),
    WeeklyProgressDayVisualState.pending => const Color(0xFF9CA3AF),
    WeeklyProgressDayVisualState.future => const Color(0xFFD1D5DB),
    WeeklyProgressDayVisualState.notScheduled => const Color(0xFFF3F4F6),
  };
}

class WeeklyProgressWidget extends StatelessWidget {
  const WeeklyProgressWidget({
    super.key,
    required this.days,
    required this.localeCode,
  });

  final List<WeeklyProgressDayData> days;
  final String localeCode;

  static const double _maxBarHeight = 36;
  static const double _barWidth = 10;
  static const double _baselineWidth = 14;
  static const double _baselineHeight = 3;
  static const double _baselineGap = 4;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (days.isEmpty) {
      return SizedBox(
        height: 88,
        child: Center(
          child: Text(
            '-',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(days.length, (int index) {
          final WeeklyProgressDayData day = days[index];
          final double targetHeight = weeklyProgressBarHeight(
            day.normalizedProgress,
          );
          final Color barColor = weeklyProgressBarColor(
            theme: theme,
            state: day.state,
          );
          final Color baselineColor = _baselineColor(theme, day.state);
          final Color labelColor = _labelColor(theme, day.state);
          final Widget content = Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              SizedBox(
                height: _maxBarHeight + _baselineGap + _baselineHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: targetHeight),
                      duration: Duration(milliseconds: 260 + (index * 24)),
                      curve: Curves.easeOut,
                      builder:
                          (BuildContext context, double animatedHeight, _) {
                            return Container(
                              width: _barWidth,
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: _baselineGap),
                    Container(
                      width: _baselineWidth,
                      height: _baselineHeight,
                      decoration: BoxDecoration(
                        color: baselineColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                weekdayShortLabel(day.date.weekday, localeCode),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: day.tooltip == null || day.tooltip!.trim().isEmpty
                  ? content
                  : Tooltip(message: day.tooltip, child: content),
            ),
          );
        }),
      ),
    );
  }

  Color _baselineColor(ThemeData theme, WeeklyProgressDayVisualState state) {
    if (state == WeeklyProgressDayVisualState.notScheduled) {
      return const Color(0xFFF3F4F6);
    }
    if (state == WeeklyProgressDayVisualState.future) {
      return const Color(0xFFF3F4F6);
    }
    return theme.colorScheme.onSurface.withValues(alpha: 0.1);
  }

  Color _labelColor(ThemeData theme, WeeklyProgressDayVisualState state) {
    return switch (state) {
      WeeklyProgressDayVisualState.notScheduled =>
        theme.colorScheme.onSurface.withValues(alpha: 0.32),
      WeeklyProgressDayVisualState.future =>
        theme.colorScheme.onSurface.withValues(alpha: 0.56),
      WeeklyProgressDayVisualState.pending =>
        theme.colorScheme.onSurface.withValues(alpha: 0.64),
      _ => theme.colorScheme.onSurface.withValues(alpha: 0.8),
    };
  }
}
