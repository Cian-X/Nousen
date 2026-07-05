import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/activity/application/activity_notification_copy_service.dart';
import 'package:liburan_create/features/activity/application/three_day_rule_service.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/activity/domain/activity_repository.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/progress/domain/progress_repository.dart';
import 'package:liburan_create/features/settings/domain/settings_repository.dart';
import 'package:liburan_create/services/notification_scheduler.dart';
import 'package:uuid/uuid.dart';

class ActivityActions {
  ActivityActions({
    required ActivityRepository activityRepository,
    required ProgressRepository progressRepository,
    required SettingsRepository settingsRepository,
    required NotificationScheduler scheduler,
    required ThreeDayRuleService threeDayRuleService,
    required ActivityNotificationCopyService notificationCopyService,
    Uuid? uuid,
  }) : _activityRepository = activityRepository,
       _progressRepository = progressRepository,
       _settingsRepository = settingsRepository,
       _scheduler = scheduler,
       _threeDayRuleService = threeDayRuleService,
       _notificationCopyService = notificationCopyService,
       _uuid = uuid ?? const Uuid();

  final ActivityRepository _activityRepository;
  final ProgressRepository _progressRepository;
  final SettingsRepository _settingsRepository;
  final NotificationScheduler _scheduler;
  final ThreeDayRuleService _threeDayRuleService;
  final ActivityNotificationCopyService _notificationCopyService;
  final Uuid _uuid;

  Future<void> saveActivity(ActivityModel activity) async {
    final List<String> normalizedSubActivities = _normalizedSubActivities(
      activity.subActivities,
    );
    final ActivityModel normalized = activity.copyWith(
      selectedDays: activity.selectedDays.toSet().toList()..sort(),
      subActivities: normalizedSubActivities,
      scheduleUpdatedAt: activity.scheduleUpdatedAt ?? activity.createdAt,
    );

    await _activityRepository.upsert(normalized);
    await _refreshActivityNotifications(normalized);
  }

  Future<void> deleteActivity(ActivityModel activity) async {
    await _activityRepository.delete(activity.id);
    await _progressRepository.deleteByActivity(activity.id);
    await _scheduler.cancelAllForActivity(activity.id);
  }

  Future<void> toggleTodayCompletion({
    required ActivityModel activity,
    required bool completed,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = dateOnly(now);

    if (!activity.selectedDays.contains(today.weekday)) {
      return;
    }

    final String dateKey = dateKeyFromDate(today);
    final ProgressEntryModel base = await _getOrCreateEntry(
      activityId: activity.id,
      dateKey: dateKey,
      subTotal: activity.subActivities.length,
      now: now,
    );
    final List<String> nextCompletedSubActivities =
        activity.subActivities.isEmpty
        ? _normalizeCompletedSubActivities(
            base.completedSubActivities,
            activity.subActivities,
          )
        : completed
        ? List<String>.from(activity.subActivities)
        : const <String>[];
    final int nextSubTotal = activity.subActivities.length;
    final int nextSubCompleted = nextCompletedSubActivities.length;

    final ProgressEntryModel updated = base.copyWith(
      completedSubActivities: nextCompletedSubActivities,
      status: completed ? ActivityDayStatus.done : ActivityDayStatus.notDone,
      subCompleted: nextSubCompleted,
      subTotal: nextSubTotal,
      completionTime: completed ? now : null,
      clearCompletionTime: !completed,
      updatedAt: now,
    );

    await _progressRepository.upsert(updated);

    final settings = await _settingsRepository.get();
    if (completed) {
      await _scheduler.suppressTodayEndOfDay(
        activity: activity,
        settings: settings,
        today: today,
      );
    }
    await _refreshActivityNotifications(activity);

    final List<ActivityModel> allActivities = await _activityRepository
        .getAll();
    await _threeDayRuleService.evaluateAll(allActivities, now: now);
  }

  Future<void> skipToday({
    required ActivityModel activity,
    String? note,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = dateOnly(now);
    if (!activity.selectedDays.contains(today.weekday)) {
      return;
    }

    final String dateKey = dateKeyFromDate(today);
    final ProgressEntryModel base = await _getOrCreateEntry(
      activityId: activity.id,
      dateKey: dateKey,
      subTotal: activity.subActivities.length,
      now: now,
    );
    final String? normalizedNote = note?.trim();

    final ProgressEntryModel updated = base.copyWith(
      status: ActivityDayStatus.skipped,
      completedSubActivities: const <String>[],
      subCompleted: 0,
      subTotal: activity.subActivities.length,
      notes: (normalizedNote != null && normalizedNote.isNotEmpty)
          ? normalizedNote
          : base.notes,
      clearCompletionTime: true,
      updatedAt: now,
    );
    await _progressRepository.upsert(updated);
    await _refreshActivityNotifications(activity);

    final List<ActivityModel> allActivities = await _activityRepository
        .getAll();
    await _threeDayRuleService.evaluateAll(allActivities, now: now);
  }

  Future<void> toggleTodaySubActivity({
    required ActivityModel activity,
    required String subActivity,
    required bool completed,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = dateOnly(now);
    if (!activity.selectedDays.contains(today.weekday)) {
      return;
    }
    if (!activity.subActivities.contains(subActivity)) {
      return;
    }

    final String dateKey = dateKeyFromDate(today);
    final ProgressEntryModel base = await _getOrCreateEntry(
      activityId: activity.id,
      dateKey: dateKey,
      subTotal: activity.subActivities.length,
      now: now,
    );

    final Set<String> completedSet = _normalizeCompletedSubActivities(
      base.completedSubActivities,
      activity.subActivities,
    ).toSet();
    if (completed) {
      completedSet.add(subActivity);
    } else {
      completedSet.remove(subActivity);
    }

    final List<String> orderedCompleted = activity.subActivities
        .where((String item) => completedSet.contains(item))
        .toList();
    final bool allDone =
        activity.subActivities.isNotEmpty &&
        orderedCompleted.length == activity.subActivities.length;
    final int subTotal = activity.subActivities.length;
    final int subCompleted = orderedCompleted.length;
    final ActivityDayStatus nextStatus = allDone
        ? ActivityDayStatus.done
        : ActivityDayStatus.notDone;

    final ProgressEntryModel updated = base.copyWith(
      completedSubActivities: orderedCompleted,
      status: nextStatus,
      subCompleted: subCompleted,
      subTotal: subTotal,
      completionTime: allDone ? now : null,
      clearCompletionTime: !allDone,
      updatedAt: now,
    );
    await _progressRepository.upsert(updated);

    if (allDone) {
      final settings = await _settingsRepository.get();
      await _scheduler.suppressTodayEndOfDay(
        activity: activity,
        settings: settings,
        today: today,
      );
    }
    await _refreshActivityNotifications(activity);

    final List<ActivityModel> allActivities = await _activityRepository
        .getAll();
    await _threeDayRuleService.evaluateAll(allActivities, now: now);
  }

  Future<String?> upsertPhotoForToday({
    required ActivityModel activity,
    required String photoPath,
    String? notes,
  }) async {
    return upsertPhotoForDate(
      activity: activity,
      date: DateTime.now(),
      photoPath: photoPath,
      notes: notes,
    );
  }

  Future<String?> upsertPhotoForDate({
    required ActivityModel activity,
    required DateTime date,
    required String photoPath,
    String? notes,
  }) async {
    final DateTime now = DateTime.now();
    final String dateKey = dateKeyFromDate(date);
    final ProgressEntryModel base = await _getOrCreateEntry(
      activityId: activity.id,
      dateKey: dateKey,
      subTotal: activity.subActivities.length,
      now: now,
    );

    final List<String> mergedPhotoPaths = <String>[
      ...base.photoPaths.where((String item) => item.trim().isNotEmpty),
    ];
    if (mergedPhotoPaths.isEmpty &&
        base.photoPath != null &&
        base.photoPath!.trim().isNotEmpty) {
      mergedPhotoPaths.add(base.photoPath!.trim());
    }
    if (!mergedPhotoPaths.contains(photoPath)) {
      mergedPhotoPaths.add(photoPath);
    }

    final String? normalizedNotes = notes?.trim();
    final bool hasExistingPhotoNote =
        base.photoNote != null && base.photoNote!.trim().isNotEmpty;
    final bool canSetPhotoNote =
        normalizedNotes != null &&
        normalizedNotes.isNotEmpty &&
        !hasExistingPhotoNote;
    final ProgressEntryModel updated = base.copyWith(
      photoPaths: mergedPhotoPaths,
      photoPath: mergedPhotoPaths.isEmpty ? null : mergedPhotoPaths.first,
      photoNote: canSetPhotoNote ? normalizedNotes : base.photoNote,
      updatedAt: now,
    );

    await _progressRepository.upsert(updated);
    return null;
  }

  Future<void> removePhotoFromEntry({required ProgressEntryModel entry}) async {
    final bool hasAnyPhoto =
        (entry.photoPath != null && entry.photoPath!.trim().isNotEmpty) ||
        entry.photoPaths.isNotEmpty;
    if (!hasAnyPhoto) {
      return;
    }

    final ProgressEntryModel updated = entry.copyWith(
      clearPhotoPath: true,
      clearPhotoPaths: true,
      clearPhotoNote: true,
      updatedAt: DateTime.now(),
    );
    await _progressRepository.upsert(updated);
  }

  Future<void> removePhotoPathFromEntry({
    required ProgressEntryModel entry,
    required String photoPath,
  }) async {
    final String normalizedPath = photoPath.trim();
    if (normalizedPath.isEmpty) {
      return;
    }

    final List<String> basePaths = entry.photoPaths.isNotEmpty
        ? List<String>.from(entry.photoPaths)
        : <String>[
            if (entry.photoPath != null && entry.photoPath!.trim().isNotEmpty)
              entry.photoPath!.trim(),
          ];
    if (basePaths.isEmpty || !basePaths.contains(normalizedPath)) {
      return;
    }

    final List<String> nextPaths = basePaths
      ..removeWhere((String item) => item == normalizedPath);
    final bool hasPhotoComment =
        entry.photoNote != null && entry.photoNote!.trim().isNotEmpty;
    final ProgressEntryModel updated = entry.copyWith(
      photoPaths: nextPaths,
      photoPath: nextPaths.isEmpty ? null : nextPaths.first,
      clearPhotoPath: nextPaths.isEmpty,
      clearPhotoNote: hasPhotoComment,
      updatedAt: DateTime.now(),
    );
    await _progressRepository.upsert(updated);
  }

  Future<bool> upsertNoteForDate({
    required ActivityModel activity,
    required DateTime date,
    required String notes,
  }) async {
    final DateTime now = DateTime.now();
    final String dateKey = dateKeyFromDate(date);
    final ProgressEntryModel base = await _getOrCreateEntry(
      activityId: activity.id,
      dateKey: dateKey,
      subTotal: activity.subActivities.length,
      now: now,
    );

    final String normalizedNotes = notes.trim();
    if (normalizedNotes.isEmpty) {
      return false;
    }
    if (base.notes != null && base.notes!.trim().isNotEmpty) {
      return false;
    }
    final ProgressEntryModel updated = base.copyWith(
      notes: normalizedNotes,
      updatedAt: now,
    );
    await _progressRepository.upsert(updated);
    return true;
  }

  Future<void> removeNoteFromEntry({required ProgressEntryModel entry}) async {
    if (entry.notes == null || entry.notes!.trim().isEmpty) {
      return;
    }

    final ProgressEntryModel updated = entry.copyWith(
      clearNotes: true,
      updatedAt: DateTime.now(),
    );
    await _progressRepository.upsert(updated);
  }

  Future<void> removePhotoNoteFromEntry({
    required ProgressEntryModel entry,
  }) async {
    if (entry.photoNote == null || entry.photoNote!.trim().isEmpty) {
      return;
    }

    final ProgressEntryModel updated = entry.copyWith(
      clearPhotoNote: true,
      updatedAt: DateTime.now(),
    );
    await _progressRepository.upsert(updated);
  }

  Future<int> seedSampleHistory({
    required ActivityModel activity,
    int days = 14,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = dateOnly(now);
    final DateTime createdDate = dateOnly(activity.createdAt);
    int inserted = 0;

    for (int offset = 0; offset < days; offset++) {
      final DateTime day = today.subtract(Duration(days: offset));
      if (day.isBefore(createdDate)) {
        continue;
      }
      if (!activity.selectedDays.contains(day.weekday)) {
        continue;
      }

      final String dateKey = dateKeyFromDate(day);
      final ProgressEntryModel? existing = await _progressRepository
          .getByActivityAndDate(activityId: activity.id, dateKey: dateKey);
      if (existing != null) {
        continue;
      }

      final bool completed = offset % 3 != 0;
      final List<String> completedSubs = completed
          ? List<String>.from(activity.subActivities)
          : const <String>[];
      final ProgressEntryModel entry = ProgressEntryModel(
        id: _uuid.v4(),
        activityId: activity.id,
        dateKey: dateKey,
        status: completed ? ActivityDayStatus.done : ActivityDayStatus.notDone,
        subCompleted: completedSubs.length,
        subTotal: activity.subActivities.length,
        completedSubActivities: completedSubs,
        photoPaths: const <String>[],
        photoPath: null,
        photoNote: null,
        notes: completed
            ? 'Simulasi: progres terasa lebih baik dari sebelumnya.'
            : 'Simulasi: hari ini kelewat, lanjut lagi besok.',
        completionTime: completed
            ? DateTime(day.year, day.month, day.day, now.hour, now.minute)
            : null,
        createdAt: now,
        updatedAt: now,
      );
      await _progressRepository.upsert(entry);
      inserted++;
    }

    final List<ActivityModel> allActivities = await _activityRepository
        .getAll();
    await _threeDayRuleService.evaluateAll(allActivities, now: now);
    return inserted;
  }

  Future<void> bootstrapRescheduleAndEvaluate() async {
    final List<ActivityModel> activities = await _activityRepository.getAll();
    final settings = await _settingsRepository.get();
    final List<ProgressEntryModel> allProgress = await _progressRepository.getAll();
    final Map<String, Map<int, ActivityReminderCopy>> reminderCopiesByActivity =
        <String, Map<int, ActivityReminderCopy>>{
          for (final ActivityModel activity in activities)
            activity.id: <int, ActivityReminderCopy>{
              for (final int weekday in activity.selectedDays.toSet())
                weekday: _notificationCopyService.build(
                  activity: activity,
                  entries: allProgress
                      .where((ProgressEntryModel entry) =>
                          entry.activityId == activity.id)
                      .toList(),
                  localeCode: settings.localeCode,
                  weekday: weekday,
                  preReminderMinutes: activity.preReminderMinutes,
                ),
            },
        };
    await _scheduler.rescheduleAllActivities(
      activities,
      settings,
      reminderCopiesByActivity,
    );
    await _threeDayRuleService.evaluateAll(activities);
  }

  Future<void> evaluateThreeDayRuleOnly() async {
    final List<ActivityModel> activities = await _activityRepository.getAll();
    await _threeDayRuleService.evaluateAll(activities);
  }

  Future<ProgressEntryModel> _getOrCreateEntry({
    required String activityId,
    required String dateKey,
    required int subTotal,
    required DateTime now,
  }) async {
    final ProgressEntryModel? existing = await _progressRepository
        .getByActivityAndDate(activityId: activityId, dateKey: dateKey);
    if (existing != null) {
      if (subTotal > 0 && existing.subTotal == 0) {
        return existing.copyWith(subTotal: subTotal);
      }
      return existing;
    }
    return ProgressEntryModel(
      id: _uuid.v4(),
      activityId: activityId,
      dateKey: dateKey,
      status: ActivityDayStatus.notDone,
      subCompleted: 0,
      subTotal: subTotal,
      completedSubActivities: const <String>[],
      photoPaths: const <String>[],
      photoPath: null,
      photoNote: null,
      notes: null,
      completionTime: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<String> _normalizedSubActivities(List<String> values) {
    final Set<String> seen = <String>{};
    final List<String> normalized = <String>[];
    for (final String item in values) {
      final String clean = item.trim();
      if (clean.isEmpty) {
        continue;
      }
      final String key = clean.toLowerCase();
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      normalized.add(clean);
    }
    return normalized;
  }

  List<String> _normalizeCompletedSubActivities(
    List<String> completedValues,
    List<String> subActivities,
  ) {
    if (subActivities.isEmpty) {
      return const <String>[];
    }
    final Set<String> completedSet = completedValues.toSet();
    return subActivities
        .where((String item) => completedSet.contains(item))
        .toList();
  }

  Future<void> _refreshActivityNotifications(ActivityModel activity) async {
    final settings = await _settingsRepository.get();
    final List<ProgressEntryModel> allProgress = await _progressRepository.getAll();
    final List<ProgressEntryModel> entries = allProgress
        .where((ProgressEntryModel entry) => entry.activityId == activity.id)
        .toList();
    final Map<int, ActivityReminderCopy> copiesByWeekday =
        <int, ActivityReminderCopy>{
          for (final int weekday in activity.selectedDays.toSet())
            weekday: _notificationCopyService.build(
              activity: activity,
              entries: entries,
              localeCode: settings.localeCode,
              weekday: weekday,
              preReminderMinutes: activity.preReminderMinutes,
            ),
        };
    await _scheduler.rescheduleAllForActivity(
      activity,
      settings,
      copiesByWeekday: copiesByWeekday,
    );
  }
}
