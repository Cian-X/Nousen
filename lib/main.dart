import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:liburan_create/app/app.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/data/activity_entity.dart';
import 'package:liburan_create/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:liburan_create/features/progress/data/progress_entry_entity.dart';
import 'package:liburan_create/features/settings/data/app_settings_entity.dart';
import 'package:liburan_create/features/popup_assist/presentation/popup_assist_bubble.dart';
import 'package:liburan_create/services/notification_action.dart';
import 'package:liburan_create/services/notification_scheduler.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _handleNotificationResponse(NotificationResponse response) async {
  final String? actionId = response.actionId;
  if (actionId != null && NotificationActionId.fromValue(actionId) == null) {
    return;
  }
  final String? rawPayload = response.payload;
  if (rawPayload == null || rawPayload.isEmpty) {
    return;
  }
  try {
    final Object? decoded = jsonDecode(rawPayload);
    if (decoded is! Map) {
      return;
    }
    final String? activityId = decoded['activityId']?.toString();
    if (activityId == null || activityId.isEmpty || activityId == 'debug-test') {
      return;
    }
    appNavigatorKey.currentState?.pushNamed(
      AppRoutes.activityDetail,
      arguments: ActivityDetailArgs(
        activityId: activityId,
        notificationAction: actionId,
      ),
    );
  } catch (_) {
    return;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SmartActivityAdvisor.initializeProfiles();

  final directory = await getApplicationDocumentsDirectory();
  final Isar isar = await Isar.open(
    <CollectionSchema<dynamic>>[
      ActivityEntitySchema,
      OneTimeReminderEntitySchema,
      ProgressEntryEntitySchema,
      AppSettingsEntitySchema,
    ],
    directory: directory.path,
    name: 'reminder_schedule_v2',
  );

  final NotificationScheduler scheduler = NotificationScheduler();
  await scheduler.initialize(onTap: _handleNotificationResponse);

  runApp(
    ProviderScope(
      overrides: <Override>[
        isarProvider.overrideWithValue(isar),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const ReminderScheduleApp(),
    ),
  );

  final NotificationAppLaunchDetails? launchDetails =
      await scheduler.launchDetails();
  final NotificationResponse? launchResponse =
      launchDetails?.notificationResponse;
  if (launchDetails?.didNotificationLaunchApp == true &&
      launchResponse != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationResponse(launchResponse);
    });
  }
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PopUpAssistBubbleApp());
}
