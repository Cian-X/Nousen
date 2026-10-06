import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';

enum AgendaVisualState { done, ongoing, missed, upcoming, skipped }

/// Status visual kartu agenda dari waktu aktual.
///
/// Model induk-sebagai-unit: induk 1 unit + tiap sub 1 unit. Selesai
/// ([AgendaVisualState.done]) hanya bila induk DAN semua sub selesai;
/// sub selesai tidak otomatis menuntaskan induk.
bool isAgendaOverallComplete(OneTimeReminderModel item) {
  if (!item.isCompleted) {
    return false;
  }
  return item.subActivities.every(
    (String sub) => item.completedSubActivities.contains(sub),
  );
}

/// Persen progres induk + sub: (induk + sub selesai) / (1 + total sub).
int resolveAgendaProgressPercent(OneTimeReminderModel item) {
  final int totalSubs = item.subActivities.length;
  if (totalSubs == 0) {
    return item.isCompleted ? 100 : 0;
  }
  final int doneSubs = item.subActivities
      .where((String sub) => item.completedSubActivities.contains(sub))
      .length;
  final int doneUnits = (item.isCompleted ? 1 : 0) + doneSubs;
  return ((doneUnits / (1 + totalSubs)) * 100).round().clamp(0, 100);
}

AgendaVisualState resolveAgendaVisualState(
  OneTimeReminderModel item,
  DateTime now,
) {
  if (isAgendaOverallComplete(item)) {
    return AgendaVisualState.done;
  }
  if (item.isSkipped) {
    return AgendaVisualState.skipped;
  }
  final DateTime? end = item.scheduledEndAt;
  final bool started = !now.isBefore(item.scheduledAt);
  final bool withinEnd = end != null
      ? now.isBefore(end)
      : dateOnly(now) == dateOnly(item.scheduledAt);
  if (started && withinEnd) {
    return AgendaVisualState.ongoing;
  }
  if (now.isAfter(end ?? item.scheduledAt)) {
    return AgendaVisualState.missed;
  }
  return AgendaVisualState.upcoming;
}

/// Tonggak faktual agenda untuk Timeline Progres: dibuat, dijadwalkan,
/// dan selesai (hanya bila benar selesai). Semua dari field nyata.
List<AgendaMilestone> buildAgendaMilestones(
  OneTimeReminderModel item, {
  required DateTime now,
  required bool idLabel,
}) {
  final List<AgendaMilestone> milestones = <AgendaMilestone>[
    AgendaMilestone(
      label: idLabel ? 'Dibuat' : 'Created',
      date: item.createdAt,
      done: true,
    ),
    AgendaMilestone(
      label: idLabel ? 'Dijadwalkan' : 'Scheduled',
      date: item.scheduledAt,
      done: !now.isBefore(item.scheduledAt),
    ),
  ];
  if (isAgendaOverallComplete(item)) {
    milestones.add(
      AgendaMilestone(
        label: idLabel ? 'Selesai' : 'Completed',
        date: item.updatedAt,
        done: true,
      ),
    );
  }
  return milestones;
}
