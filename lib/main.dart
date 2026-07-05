import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:liburan_create/app/app.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/data/activity_entity.dart';
import 'package:liburan_create/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:liburan_create/features/progress/data/progress_entry_entity.dart';
import 'package:liburan_create/features/settings/data/app_settings_entity.dart';
import 'package:liburan_create/services/notification_scheduler.dart';
import 'package:path_provider/path_provider.dart';

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
  await scheduler.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        isarProvider.overrideWithValue(isar),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const ReminderScheduleApp(),
    ),
  );
}
