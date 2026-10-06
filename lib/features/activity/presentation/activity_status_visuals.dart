import 'package:flutter/material.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/features/activity/domain/activity_daily_progress_status.dart';

IconData activityStatusIcon(ActivityDailyProgressStatus status) {
  return switch (status) {
    ActivityDailyProgressStatus.done => Icons.check_circle,
    ActivityDailyProgressStatus.partial => Icons.timelapse,
    ActivityDailyProgressStatus.missed => Icons.cancel,
    ActivityDailyProgressStatus.skipped => Icons.skip_next,
    ActivityDailyProgressStatus.future => Icons.radio_button_unchecked,
  };
}

Color activityStatusColor({
  required ThemeData theme,
  required ActivityDailyProgressStatus status,
}) {
  return switch (status) {
    ActivityDailyProgressStatus.done => theme.habitColors.completed,
    ActivityDailyProgressStatus.partial => theme.habitColors.pending,
    ActivityDailyProgressStatus.missed => theme.habitColors.missed,
    ActivityDailyProgressStatus.skipped => theme.habitColors.inactive,
    ActivityDailyProgressStatus.future => theme.habitColors.inactive,
  };
}

String activityStatusLabel({
  required ActivityDailyProgressStatus status,
  required String localeCode,
}) {
  final bool isId = localeCode == 'id';
  return switch (status) {
    ActivityDailyProgressStatus.done => isId ? 'Selesai' : 'Done',
    ActivityDailyProgressStatus.partial => isId ? 'Sebagian' : 'Partial',
    ActivityDailyProgressStatus.missed => isId ? 'Terlewat' : 'Missed',
    ActivityDailyProgressStatus.skipped => isId ? 'Dilewati' : 'Skipped',
    ActivityDailyProgressStatus.future => isId ? 'Belum mulai' : 'Future',
  };
}
