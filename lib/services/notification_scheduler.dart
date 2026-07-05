import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:liburan_create/core/utils/notification_ids.dart';
import 'package:liburan_create/features/activity/application/activity_notification_copy_service.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapHandler = Future<void> Function(String? payload);

class NotificationScheduler {
  NotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  AndroidScheduleMode _androidScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;
  String _activeTimezone = 'UTC';
  bool _canScheduleExact = false;
  bool _notificationsEnabled = true;

  String get activeTimezone => _activeTimezone;
  bool get canScheduleExact => _canScheduleExact;
  bool get notificationsEnabled => _notificationsEnabled;
  String get effectiveScheduleMode => _androidScheduleMode.name;

  Future<void> initialize({NotificationTapHandler? onTap}) async {
    tz.initializeTimeZones();
    await _syncTimezoneFromDevice();

    if (_initialized) {
      return;
    }

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (onTap != null) {
          await onTap(response.payload);
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
    await refreshCapabilities();
  }

  Future<void> refreshCapabilities() async {
    await _syncTimezoneFromDevice();
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    _notificationsEnabled =
        await androidPlugin?.areNotificationsEnabled() ?? true;
    _canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    _androidScheduleMode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> rescheduleAllActivities(
    List<ActivityModel> activities,
    AppSettingsModel settings,
    Map<String, Map<int, ActivityReminderCopy>>? reminderCopiesByActivity,
  ) async {
    for (final ActivityModel activity in activities) {
      await rescheduleAllForActivity(
        activity,
        settings,
        copiesByWeekday: reminderCopiesByActivity?[activity.id],
      );
    }
  }

  Future<void> rescheduleOneTimeReminders(
    List<OneTimeReminderModel> reminders,
    AppSettingsModel settings,
  ) async {
    for (final OneTimeReminderModel reminder in reminders) {
      await rescheduleOneTimeReminder(reminder, settings);
    }
  }

  Future<void> rescheduleAllForActivity(
    ActivityModel activity,
    AppSettingsModel settings,
    {Map<int, ActivityReminderCopy>? copiesByWeekday}
  ) async {
    await initialize();
    await cancelAllForActivity(activity.id);

    if (!settings.notificationsEnabled ||
        !activity.isNotificationEnabled ||
        activity.selectedDays.isEmpty) {
      return;
    }

    for (final int weekday in activity.selectedDays.toSet()) {
      final ActivityReminderCopy? weekdayCopy = copiesByWeekday?[weekday];
      if (activity.preReminderMinutes > 0) {
        final ({int weekday, int minutes}) reminderSlot = _shiftEarlier(
          weekday: weekday,
          minutes: activity.timeMinutes,
          shiftMinutes: activity.preReminderMinutes,
        );
        await _scheduleWeekly(
          activityId: activity.id,
          weekday: reminderSlot.weekday,
          minutes: reminderSlot.minutes,
          type: NotificationType.preStart,
          title: activity.title,
          body: weekdayCopy?.preStartBody ??
              'Mulai dalam ${activity.preReminderMinutes} menit',
        );
      }

      await _scheduleWeekly(
        activityId: activity.id,
        weekday: weekday,
        minutes: activity.timeMinutes,
        type: NotificationType.main,
        title: activity.title,
        body: weekdayCopy?.mainBody ?? 'Waktunya memulai aktivitas',
      );

      if (activity.enableMorningReminder) {
        await _scheduleWeekly(
          activityId: activity.id,
          weekday: weekday,
          minutes: settings.morningReminderMinutes,
          type: NotificationType.morning,
          title: activity.title,
          body: weekdayCopy?.morningBody ?? 'Pengingat pagi',
        );
      }

      if (activity.enableEndOfDayReminder) {
        await _scheduleWeekly(
          activityId: activity.id,
          weekday: weekday,
          minutes: settings.endOfDayReminderMinutes,
          type: NotificationType.endOfDay,
          title: activity.title,
          body: weekdayCopy?.endOfDayBody ?? 'Penutup hari: cek progress',
        );
      }
    }
  }

  Future<void> rescheduleOneTimeReminder(
    OneTimeReminderModel reminder,
    AppSettingsModel settings,
  ) async {
    await initialize();
    await cancelOneTimeReminder(reminder.id);

    if (!settings.notificationsEnabled ||
        !reminder.isNotificationEnabled ||
        reminder.isCompleted) {
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledAt = tz.TZDateTime.from(
      reminder.scheduledAt,
      tz.local,
    );
    if (!scheduledAt.isAfter(now)) {
      return;
    }

    if (reminder.preReminderMinutes > 0) {
      final tz.TZDateTime preAt = scheduledAt.subtract(
        Duration(minutes: reminder.preReminderMinutes),
      );
      if (preAt.isAfter(now)) {
        await _scheduleOneTime(
          id: oneTimePreReminderNotificationId(reminder.id),
          title: reminder.title,
          body: 'Mulai dalam ${reminder.preReminderMinutes} menit',
          scheduleAt: preAt,
          payload: _oneTimePayload(reminder.id, 'pre-start'),
        );
      }
    }

    await _scheduleOneTime(
      id: oneTimeReminderNotificationId(reminder.id),
      title: reminder.title,
      body: 'Waktunya jadwal yang kamu tentukan',
      scheduleAt: scheduledAt,
      payload: _oneTimePayload(reminder.id, 'one-time'),
    );
  }

  Future<void> suppressTodayEndOfDay({
    required ActivityModel activity,
    required AppSettingsModel settings,
    required DateTime today,
  }) async {
    final int weekday = today.weekday;
    if (!settings.notificationsEnabled ||
        !activity.isNotificationEnabled ||
        !activity.enableEndOfDayReminder ||
        !activity.selectedDays.contains(weekday)) {
      return;
    }

    final int id = notificationIdFor(
      activity.id,
      NotificationType.endOfDay,
      weekday,
    );
    await _plugin.cancel(id);

    final tz.TZDateTime scheduleAt = _nextWeekdayTime(
      weekday: weekday,
      minutes: settings.endOfDayReminderMinutes,
      from: today.add(const Duration(days: 1)),
    );

    await _zonedScheduleWithFallback(
      id: id,
      title: activity.title,
      body: 'Penutup hari: cek progress',
      scheduleAt: scheduleAt,
      payload: _payload(activity.id, NotificationType.endOfDay.name),
    );
  }

  Future<void> cancelAllForActivity(String activityId) async {
    await initialize();
    for (final NotificationType type in NotificationType.values) {
      if (type == NotificationType.threeDayRule) {
        await _plugin.cancel(threeDayRuleNotificationId(activityId));
        continue;
      }

      for (int weekday = 1; weekday <= 7; weekday++) {
        final int id = notificationIdFor(activityId, type, weekday);
        final int legacyOneShotId = (id | 0x04000000) & 0x7fffffff;
        await _plugin.cancel(id);
        await _plugin.cancel(legacyOneShotId);
      }
    }
  }

  Future<void> cancelOneTimeReminder(String reminderId) async {
    await initialize();
    await _plugin.cancel(oneTimeReminderNotificationId(reminderId));
    await _plugin.cancel(oneTimePreReminderNotificationId(reminderId));
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> triggerThreeDayRuleNow(ActivityModel activity) async {
    await initialize();
    await _plugin.show(
      threeDayRuleNotificationId(activity.id),
      'Aturan 3 Hari',
      'Sudah 3 jadwal terlewat untuk ${activity.title}. Yuk mulai lagi pelan-pelan hari ini.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'three_day_rule',
          'Aturan 3 Hari',
          channelDescription: 'Pengingat lembut saat 3 jadwal terlewat',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFFB300),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _payload(activity.id, NotificationType.threeDayRule.name),
    );
  }

  Future<void> showTestNotificationNow() async {
    await initialize();
    await _plugin.show(
      notificationIdFor('debug-test', NotificationType.main, 0),
      'Jadwal Aktivitas',
      'Notifikasi test berhasil.',
      _notificationDetails(),
      payload: _payload('debug-test', 'manual'),
    );
  }

  Future<void> _scheduleWeekly({
    required String activityId,
    required int weekday,
    required int minutes,
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    final int id = notificationIdFor(activityId, type, weekday);
    final tz.TZDateTime scheduleAt = _nextWeekdayTime(
      weekday: weekday,
      minutes: minutes,
      from: DateTime.now(),
    );
    await _plugin.cancel(id);

    await _zonedScheduleWithFallback(
      id: id,
      title: title,
      body: body,
      scheduleAt: scheduleAt,
      payload: _payload(activityId, type.name),
    );
  }

  Future<void> _scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduleAt,
    required String payload,
  }) async {
    await _plugin.cancel(id);
    await _zonedScheduleOneTimeWithFallback(
      id: id,
      title: title,
      body: body,
      scheduleAt: scheduleAt,
      payload: payload,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'activity_reminders',
        'Activity reminders',
        channelDescription: 'Weekly schedule reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _oneTimeNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'one_time_reminders',
        'One-time reminders',
        channelDescription: 'Date and time specific reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduleAt,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduleAt,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
      _androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduleAt,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
      _androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  Future<void> _zonedScheduleOneTimeWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduleAt,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduleAt,
        _oneTimeNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      _androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduleAt,
        _oneTimeNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      _androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  String _payload(String activityId, String type) {
    return jsonEncode(<String, String>{'activityId': activityId, 'type': type});
  }

  String _oneTimePayload(String reminderId, String type) {
    return jsonEncode(<String, String>{'reminderId': reminderId, 'type': type});
  }

  Future<void> _syncTimezoneFromDevice() async {
    String? rawName;
    try {
      rawName = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      rawName = null;
    }

    final Duration offset = DateTime.now().timeZoneOffset;
    final tz.Location location = _resolveLocation(
      rawName: rawName,
      offset: offset,
    );
    tz.setLocalLocation(location);
    _activeTimezone = location.name;
  }

  tz.Location _resolveLocation({
    required String? rawName,
    required Duration offset,
  }) {
    final List<String> candidates = <String>[
      if (rawName != null && rawName.trim().isNotEmpty) rawName.trim(),
      if (rawName != null && rawName.trim().isNotEmpty)
        rawName.trim().replaceAll(' ', '_'),
    ];

    for (final String candidate in candidates) {
      try {
        return tz.getLocation(candidate);
      } catch (_) {
        // Continue with fallback chain.
      }
    }

    switch (offset.inHours) {
      case 7:
        return tz.getLocation('Asia/Jakarta');
      case 8:
        return tz.getLocation('Asia/Makassar');
      case 9:
        return tz.getLocation('Asia/Jayapura');
      default:
        final int hours = offset.inHours.abs();
        final String sign = offset.isNegative ? '+' : '-';
        final String etcGmt = 'Etc/GMT$sign$hours';
        try {
          return tz.getLocation(etcGmt);
        } catch (_) {
          return tz.getLocation('UTC');
        }
    }
  }

  ({int weekday, int minutes}) _shiftEarlier({
    required int weekday,
    required int minutes,
    required int shiftMinutes,
  }) {
    int shiftedWeekday = weekday;
    int shiftedMinutes = minutes - shiftMinutes;

    while (shiftedMinutes < 0) {
      shiftedMinutes += 1440;
      shiftedWeekday -= 1;
      if (shiftedWeekday < 1) {
        shiftedWeekday = 7;
      }
    }

    return (weekday: shiftedWeekday, minutes: shiftedMinutes);
  }

  tz.TZDateTime _nextWeekdayTime({
    required int weekday,
    required int minutes,
    required DateTime from,
  }) {
    final tz.TZDateTime reference = tz.TZDateTime.from(from, tz.local);
    final int hour = (minutes ~/ 60) % 24;
    final int minute = minutes % 60;

    tz.TZDateTime candidate = tz.TZDateTime(
      tz.local,
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );

    while (candidate.weekday != weekday ||
        !candidate.isAfter(tz.TZDateTime.now(tz.local))) {
      candidate = candidate.add(const Duration(days: 1));
      candidate = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day,
        hour,
        minute,
      );
    }

    return candidate;
  }
}
