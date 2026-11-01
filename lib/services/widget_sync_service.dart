import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:nousen/core/utils/date_utils.dart';
import 'package:nousen/core/utils/time_utils.dart';
import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/one_time_reminder/data/agenda_note_entity.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_first_one_time_reminder_repository.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/progress/data/cloud_progress_backend.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';

@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) {
    return;
  }
  await WidgetSyncService.handleBackgroundAction(uri);
}

class _ScheduleItem {
  const _ScheduleItem({
    required this.id,
    required this.title,
    required this.timeMinutes,
    required this.type,
    required this.isCompleted,
    required this.subActivities,
    required this.completedSubActivities,
  });

  final String id;
  final String title;
  final int timeMinutes;
  final String type; // 'activity' | 'reminder'
  final bool isCompleted;
  final List<String> subActivities;
  final List<String> completedSubActivities;
}

class WidgetSyncService {
  const WidgetSyncService._();

  static const String appWidgetProvider = 'NousenAppWidgetProvider';

  static Future<void> updateWidget({
    required List<ActivityModel> activities,
    required List<ProgressEntryModel> todayProgress,
    required List<OneTimeReminderModel> todayReminders,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final int todayWeekday = now.weekday;
      final int currentMinutes = now.hour * 60 + now.minute;
      final String todayDateKey = dateKeyFromDate(now);

      final List<_ScheduleItem> allItems = <_ScheduleItem>[];

      // 1. Aktivitas harian hari ini
      for (final ActivityModel a in activities) {
        if (!a.selectedDays.contains(todayWeekday)) {
          continue;
        }
        final ProgressEntryModel? progress = todayProgress
            .where((ProgressEntryModel p) => p.activityId == a.id)
            .firstOrNull;
        final bool isDone = progress != null &&
            (progress.status == ActivityDayStatus.done ||
                progress.status == ActivityDayStatus.skipped);
        final List<String> completedSubs =
            progress?.completedSubActivities ?? const <String>[];

        allItems.add(
          _ScheduleItem(
            id: a.id,
            title: a.title,
            timeMinutes: a.timeMinutes,
            type: 'activity',
            isCompleted: isDone,
            subActivities: a.subActivities,
            completedSubActivities: completedSubs,
          ),
        );
      }

      // 2. Agenda satu kali hari ini
      for (final OneTimeReminderModel r in todayReminders) {
        if (!isSameDay(r.scheduledAt, now)) {
          continue;
        }
        final bool isDone = r.isCompleted || r.isSkipped;
        final int rMinutes = r.scheduledAt.hour * 60 + r.scheduledAt.minute;

        allItems.add(
          _ScheduleItem(
            id: r.id,
            title: r.title,
            timeMinutes: rMinutes,
            type: 'reminder',
            isCompleted: isDone,
            subActivities: r.subActivities,
            completedSubActivities: r.completedSubActivities,
          ),
        );
      }

      // Sort chronological untuk Idle view
      allItems.sort(
        (_ScheduleItem a, _ScheduleItem b) =>
            a.timeMinutes.compareTo(b.timeMinutes),
      );

      // Cek Active Stack (jadwal yang sudah tiba jamnya dan belum selesai 100%)
      final List<_ScheduleItem> activeStack = allItems
          .where(
            (_ScheduleItem item) =>
                item.timeMinutes <= currentMinutes && !item.isCompleted,
          )
          .toList();

      // Prioritas LIFO (jadwal yang paling baru aktif berada di posisi teratas)
      activeStack.sort(
        (_ScheduleItem a, _ScheduleItem b) =>
            b.timeMinutes.compareTo(a.timeMinutes),
      );

      if (activeStack.isNotEmpty) {
        // === MODE AKTIF (Menyorot jadwal terbaru yang belum tuntas) ===
        final _ScheduleItem activeItem = activeStack.first;
        final int totalPending =
            allItems.where((_ScheduleItem i) => !i.isCompleted).length;

        await HomeWidget.saveWidgetData<String>('widget_mode', 'active');
        await HomeWidget.saveWidgetData<String>(
          'widget_header_info',
          '$totalPending tugas tersisa',
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_active_title',
          activeItem.title,
        );
        final String subtitle = activeItem.subActivities.isNotEmpty
            ? '${activeItem.subActivities.length} sub aktivitas'
            : (activeItem.type == 'reminder'
                ? 'Agenda terjadwal'
                : 'Rutinitas harian');
        await HomeWidget.saveWidgetData<String>(
          'widget_active_subtitle',
          subtitle,
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_active_time',
          formatMinutesAsTime(activeItem.timeMinutes),
        );
        await HomeWidget.saveWidgetData<bool>(
          'widget_active_done',
          activeItem.isCompleted,
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_active_uri',
          'nousen://toggle?type=${activeItem.type}&id=${activeItem.id}&dateKey=$todayDateKey',
        );

        final int subCount = min(3, activeItem.subActivities.length);
        await HomeWidget.saveWidgetData<int>(
          'widget_active_sub_count',
          subCount,
        );

        for (int i = 0; i < subCount; i++) {
          final String subTitle = activeItem.subActivities[i];
          final bool subDone =
              activeItem.completedSubActivities.contains(subTitle);
          await HomeWidget.saveWidgetData<String>(
            'widget_active_sub_${i}_title',
            subTitle,
          );
          await HomeWidget.saveWidgetData<bool>(
            'widget_active_sub_${i}_done',
            subDone,
          );
          await HomeWidget.saveWidgetData<String>(
            'widget_active_sub_${i}_uri',
            'nousen://toggle-sub?type=${activeItem.type}&id=${activeItem.id}&subIndex=$i&dateKey=$todayDateKey',
          );
        }
      } else {
        // === MODE IDLE (List aktivitas & agenda hari ini) ===
        final int totalPending =
            allItems.where((_ScheduleItem i) => !i.isCompleted).length;
        final String headerInfo = totalPending > 0
            ? '$totalPending tugas tersisa'
            : 'Semua selesai!';

        await HomeWidget.saveWidgetData<String>('widget_mode', 'idle');
        await HomeWidget.saveWidgetData<String>(
          'widget_header_info',
          headerInfo,
        );

        // Section counts for headers
        final int agendaCount =
            allItems.where((_ScheduleItem i) => i.type == 'reminder').length;
        final int activityCount =
            allItems.where((_ScheduleItem i) => i.type == 'activity').length;
        await HomeWidget.saveWidgetData<int>(
          'widget_idle_agenda_count',
          agendaCount,
        );
        await HomeWidget.saveWidgetData<int>(
          'widget_idle_activity_count',
          activityCount,
        );

        // Sort: agenda first, then activities; within each group sort by time
        allItems.sort(
          (_ScheduleItem a, _ScheduleItem b) {
            // reminder (agenda) before activity
            final int typeCompare = a.type == b.type
                ? 0
                : (a.type == 'reminder' ? -1 : 1);
            if (typeCompare != 0) return typeCompare;
            return a.timeMinutes.compareTo(b.timeMinutes);
          },
        );

        final int itemCount = min(4, allItems.length);
        await HomeWidget.saveWidgetData<int>(
          'widget_idle_item_count',
          itemCount,
        );

        for (int i = 0; i < itemCount; i++) {
          final _ScheduleItem item = allItems[i];
          await HomeWidget.saveWidgetData<String>(
            'widget_idle_item_${i}_title',
            item.title,
          );
          final String subtitle = item.type == 'reminder'
              ? 'Agenda terjadwal'
              : (item.subActivities.isNotEmpty
                    ? '${item.subActivities.length} sub aktivitas'
                    : 'Rutinitas harian');
          await HomeWidget.saveWidgetData<String>(
            'widget_idle_item_${i}_subtitle',
            subtitle,
          );
          await HomeWidget.saveWidgetData<String>(
            'widget_idle_item_${i}_time',
            formatMinutesAsTime(item.timeMinutes),
          );
          await HomeWidget.saveWidgetData<bool>(
            'widget_idle_item_${i}_done',
            item.isCompleted,
          );
          await HomeWidget.saveWidgetData<String>(
            'widget_idle_item_${i}_uri',
            'nousen://toggle?type=${item.type}&id=${item.id}&dateKey=$todayDateKey',
          );
          await HomeWidget.saveWidgetData<String>(
            'widget_idle_item_${i}_type',
            item.type,
          );
        }
      }

      await HomeWidget.updateWidget(
        name: appWidgetProvider,
        androidName: appWidgetProvider,
      );
    } catch (_) {
      // Non-fatal widget sync
    }
  }

  static Future<void> updateWidgetFromIsar(Isar isar) async {
    try {
      final now = DateTime.now();
      final todayDateKey = dateKeyFromDate(now);

      final actEntities = await isar.activityEntitys.where().findAll();
      final progressEntities = await isar.progressEntryEntitys
          .filter()
          .dateKeyEqualTo(todayDateKey)
          .findAll();
      final reminderEntities =
          await isar.oneTimeReminderEntitys.where().findAll();

      final activities = actEntities.map((e) => e.toDomain()).toList();
      final todayProgress = progressEntities.map((e) => e.toDomain()).toList();
      final todayReminders = reminderEntities.map((e) => e.toDomain()).toList();

      await updateWidget(
        activities: activities,
        todayProgress: todayProgress,
        todayReminders: todayReminders,
      );
    } catch (_) {
      // Non-fatal
    }
  }

  static Future<void> handleBackgroundAction(Uri uri) async {
    try {
      final String type = uri.queryParameters['type'] ?? '';
      final String id = uri.queryParameters['id'] ?? '';
      final String action = uri.host; // 'toggle' or 'toggle-sub'
      final int subIndex =
          int.tryParse(uri.queryParameters['subIndex'] ?? '') ?? -1;

      // Handle refresh (midnight / timezone change)
      if (uri.scheme == 'nousen' && uri.host == 'widget_action') {
        final directory = await getApplicationDocumentsDirectory();
        final Isar isar = Isar.getInstance('reminder_schedule_v2') ??
            await Isar.open(
              <CollectionSchema<dynamic>>[
                ActivityEntitySchema,
                OneTimeReminderEntitySchema,
                AgendaNoteEntitySchema,
                ProgressEntryEntitySchema,
                AppSettingsEntitySchema,
              ],
              directory: directory.path,
              name: 'reminder_schedule_v2',
              inspector: false,
            );
        await updateWidgetFromIsar(isar);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final Isar isar = Isar.getInstance('reminder_schedule_v2') ??
          await Isar.open(
            <CollectionSchema<dynamic>>[
              ActivityEntitySchema,
              OneTimeReminderEntitySchema,
              AgendaNoteEntitySchema,
              ProgressEntryEntitySchema,
              AppSettingsEntitySchema,
            ],
            directory: directory.path,
            name: 'reminder_schedule_v2',
            inspector: false,
          );

      final DateTime now = DateTime.now();
      final String todayDateKey = dateKeyFromDate(now);

      if (type == 'reminder') {
        final OneTimeReminderEntity? reminder = await isar
            .oneTimeReminderEntitys
            .filter()
            .idEqualTo(id)
            .findFirst();
        if (reminder != null) {
          if (action == 'toggle-sub') {
            final List<String> subs =
                reminder.subActivities ?? const <String>[];
            if (subIndex >= 0 && subIndex < subs.length) {
              final String subTitle = subs[subIndex];
              final Set<String> done =
                  (reminder.completedSubActivities ?? const <String>[]).toSet();
              if (done.contains(subTitle)) {
                done.remove(subTitle);
              } else {
                done.add(subTitle);
              }
              reminder.completedSubActivities = done.toList();
              if (done.length >= subs.length && subs.isNotEmpty) {
                reminder.isCompleted = true;
              } else {
                reminder.isCompleted = false;
              }
            }
          } else {
            final bool nextDone = !reminder.isCompleted;
            reminder.isCompleted = nextDone;
            if (nextDone) {
              reminder.completedSubActivities = List<String>.from(
                reminder.subActivities ?? const <String>[],
              );
            } else {
              reminder.completedSubActivities = const <String>[];
            }
          }
          reminder.updatedAt = now;
          await isar.writeTxn(() async {
            await isar.oneTimeReminderEntitys.put(reminder);
          });

          // Sync to Firestore
          await _syncReminderToFirestore(reminder);
        }
      } else if (type == 'activity') {
        final ActivityEntity? activity =
            await isar.activityEntitys.filter().idEqualTo(id).findFirst();
        if (activity != null) {
          ProgressEntryEntity? progress = await isar.progressEntryEntitys
              .filter()
              .activityIdEqualTo(id)
              .dateKeyEqualTo(todayDateKey)
              .findFirst();

          progress ??= ProgressEntryEntity()
            ..id = const Uuid().v4()
            ..activityId = id
            ..dateKey = todayDateKey
            ..statusKey = ActivityDayStatus.notDone.storageKey
            ..isCompleted = false
            ..subCompleted = 0
            ..subTotal = activity.subActivities.length
            ..completedSubActivities = const <String>[]
            ..photoPaths = const <String>[]
            ..notes = ''
            ..createdAt = now
            ..updatedAt = now;

          if (action == 'toggle-sub') {
            final List<String> subs = activity.subActivities;
            if (subIndex >= 0 && subIndex < subs.length) {
              final String subTitle = subs[subIndex];
              final Set<String> done =
                  (progress.completedSubActivities).toSet();
              if (done.contains(subTitle)) {
                done.remove(subTitle);
              } else {
                done.add(subTitle);
              }
              progress.completedSubActivities = done.toList();
              progress.subCompleted = done.length;
              if (done.length >= subs.length && subs.isNotEmpty) {
                progress.statusKey = ActivityDayStatus.done.storageKey;
                progress.isCompleted = true;
              } else {
                progress.statusKey = ActivityDayStatus.notDone.storageKey;
                progress.isCompleted = false;
              }
            }
          } else {
            final bool isCurrentlyDone =
                progress.statusKey == ActivityDayStatus.done.storageKey;
            if (isCurrentlyDone) {
              progress.statusKey = ActivityDayStatus.notDone.storageKey;
              progress.isCompleted = false;
              progress.completedSubActivities = const <String>[];
              progress.subCompleted = 0;
            } else {
              progress.statusKey = ActivityDayStatus.done.storageKey;
              progress.isCompleted = true;
              progress.completedSubActivities = List<String>.from(
                activity.subActivities,
              );
              progress.subCompleted = activity.subActivities.length;
            }
          }
          progress.updatedAt = now;
          await isar.writeTxn(() async {
            await isar.progressEntryEntitys.put(progress!);
          });

          // Sync to Firestore
          await _syncProgressToFirestore(progress);
        }
      }

      await updateWidgetFromIsar(isar);
    } catch (_) {
      // Non-fatal
    }
  }

  /// Sync progress entry to Firestore (best-effort in background).
  static Future<void> _syncProgressToFirestore(
    ProgressEntryEntity progress,
  ) async {
    try {
      await Firebase.initializeApp();
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // WAJIB memakai kontrak cloud-first: FieldValue.serverTimestamp(),
      // tombstone state, schemaVersion, serta seluruh field model.
      final ProgressEntryModel model = progress.toDomain();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(progress.id)
          .set(progressCloudDocMap(model), SetOptions(merge: true));
    } catch (error, stackTrace) {
      // Jangan gagalkan toggle lokal; log tetap diperlukan untuk diagnosis
      // reject rules/payload dari background isolate.
      debugPrint('[widget-sync] progress Firestore gagal: $error\n$stackTrace');
    }
  }

  /// Sync reminder to Firestore (best-effort in background).
  static Future<void> _syncReminderToFirestore(
    OneTimeReminderEntity reminder,
  ) async {
    try {
      await Firebase.initializeApp();
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Jangan buat payload manual: field scheduledAt, updatedAt server,
      // deleted/schemaVersion harus persis sama dengan jalur app cloud-first.
      final OneTimeReminderModel model = reminder.toDomain();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminders')
          .doc(reminder.id)
          .set(
            CloudFirstOneTimeReminderRepository.reminderToMap(model),
            SetOptions(merge: true),
          );
    } catch (error, stackTrace) {
      debugPrint('[widget-sync] reminder Firestore gagal: $error\n$stackTrace');
    }
  }
}
