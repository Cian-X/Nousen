import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:nousen/core/constants/ai_demo_config.dart';
import 'package:nousen/core/constants/app_constants.dart';
import 'package:nousen/core/migration/migration_flags.dart';
import 'package:nousen/core/utils/date_utils.dart';
import 'package:nousen/features/activity/application/activity_actions.dart';
import 'package:nousen/features/activity/application/activity_detail_ml_service.dart';
import 'package:nousen/features/activity/application/activity_form_ml_service.dart';
import 'package:nousen/features/activity/application/activity_notification_copy_service.dart';
import 'package:nousen/features/activity/application/ai_feedback_log_service.dart';
import 'package:nousen/features/activity/application/three_day_rule_service.dart';
import 'package:nousen/features/activity/data/isar_activity_repository.dart';
import 'package:nousen/features/activity/data/cloud_activities_backend.dart';
import 'package:nousen/features/activity/data/cloud_first_activity_repository.dart';
import 'package:nousen/features/activity/data/dual_write_activity_repository.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/features/one_time_reminder/application/one_time_reminder_actions.dart';
import 'package:nousen/features/one_time_reminder/data/isar_one_time_reminder_repository.dart';
import 'package:nousen/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:nousen/features/progress/data/isar_progress_repository.dart';
import 'package:nousen/features/progress/data/dual_write_progress_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';
import 'package:nousen/features/home/application/home_ml_service.dart';
import 'package:nousen/features/settings/application/data_backup_service.dart';
import 'package:nousen/features/settings/data/isar_settings_repository.dart';
import 'package:nousen/features/settings/domain/app_settings_model.dart';
import 'package:nousen/features/settings/domain/settings_repository.dart';
import 'package:nousen/features/stats/application/stats_service.dart';
import 'package:nousen/features/stats/application/stats_ml_service.dart';
import 'package:nousen/features/stats/domain/stats_models.dart';
import 'package:nousen/services/device_health_service.dart';
import 'package:nousen/services/gemini_activity_service.dart';
import 'package:nousen/services/firebase/firebase_auth_service.dart';
import 'package:nousen/services/image_storage_service.dart';
import 'package:nousen/services/ml/ml_model_encoder_service.dart';
import 'package:nousen/services/ml/ml_model_schema_service.dart';
import 'package:nousen/services/ml/onnx_model_service.dart';
import 'package:nousen/services/notification_scheduler.dart';
import 'package:nousen/services/photo_access_service.dart';

final isarProvider = Provider<Isar>((Ref ref) {
  throw UnimplementedError('isarProvider must be overridden in main');
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((
  Ref ref,
) {
  throw UnimplementedError(
    'notificationSchedulerProvider must be overridden in main',
  );
});

final imageStorageServiceProvider = Provider<ImageStorageService>(
  (Ref ref) => ImageStorageService(),
);

final photoAccessServiceProvider = Provider<PhotoAccessService>(
  (Ref ref) => PhotoAccessService(),
);

final deviceHealthServiceProvider = Provider<DeviceHealthService>(
  (Ref ref) => DeviceHealthService(),
);

final geminiActivityServiceProvider = Provider<GeminiActivityService>(
  (Ref ref) => GeminiActivityService(),
);

/// Layanan Auth Firebase + Google Sign-In (nonaktif bila Firebase belum
/// dikonfigurasi; lihat [FirebaseAuthService]).
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (Ref ref) => FirebaseAuthService(),
);

/// Status login Firebase. Null = belum login / Firebase nonaktif.
final firebaseAuthStateProvider = StreamProvider<User?>((Ref ref) {
  try {
    return ref.watch(firebaseAuthServiceProvider).authStateChanges();
  } on FirebaseNotConfigured {
    return Stream<User?>.value(null);
  }
});

final onnxModelServiceProvider = Provider<OnnxModelService>(
  (Ref ref) => OnnxModelService(),
);

final mlModelSchemaServiceProvider = Provider<MlModelSchemaService>(
  (Ref ref) => const MlModelSchemaService(),
);

final mlModelEncoderServiceProvider = Provider<MlModelEncoderService>(
  (Ref ref) => const MlModelEncoderService(),
);

final activityDetailMlServiceProvider = Provider<ActivityDetailMlService>(
  (Ref ref) => ActivityDetailMlService(
    runtime: ref.watch(onnxModelServiceProvider),
    schemaService: ref.watch(mlModelSchemaServiceProvider),
    encoderService: ref.watch(mlModelEncoderServiceProvider),
  ),
);

final activityFormMlServiceProvider = Provider<ActivityFormMlService>(
  (Ref ref) => ActivityFormMlService(
    runtime: ref.watch(onnxModelServiceProvider),
    schemaService: ref.watch(mlModelSchemaServiceProvider),
    encoderService: ref.watch(mlModelEncoderServiceProvider),
  ),
);

final statsMlServiceProvider = Provider<StatsMlService>(
  (Ref ref) => StatsMlService(
    runtime: ref.watch(onnxModelServiceProvider),
    schemaService: ref.watch(mlModelSchemaServiceProvider),
    encoderService: ref.watch(mlModelEncoderServiceProvider),
  ),
);

final homeMlServiceProvider = Provider<HomeMlService>(
  (Ref ref) => HomeMlService(
    runtime: ref.watch(onnxModelServiceProvider),
    schemaService: ref.watch(mlModelSchemaServiceProvider),
    encoderService: ref.watch(mlModelEncoderServiceProvider),
  ),
);

final aiFeedbackLogServiceProvider = Provider<AiFeedbackLogService>(
  (Ref ref) => const AiFeedbackLogService(),
);

final activityNotificationCopyServiceProvider =
    Provider<ActivityNotificationCopyService>(
      (Ref ref) => const ActivityNotificationCopyService(),
    );

final dataBackupServiceProvider = Provider<DataBackupService>((Ref ref) {
  return DataBackupService(
    isar: ref.watch(isarProvider),
    activityRepository: ref.watch(activityRepositoryProvider),
    oneTimeReminderRepository: ref.watch(oneTimeReminderRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

class NotificationHealthState {
  const NotificationHealthState({
    required this.timezone,
    required this.scheduleMode,
    required this.notificationsEnabled,
    required this.canScheduleExact,
    required this.batteryOptimizationIgnored,
  });

  final String timezone;
  final String scheduleMode;
  final bool notificationsEnabled;
  final bool canScheduleExact;
  final bool? batteryOptimizationIgnored;
}

final notificationHealthProvider = FutureProvider<NotificationHealthState>((
  Ref ref,
) async {
  final NotificationScheduler scheduler = ref.read(
    notificationSchedulerProvider,
  );
  final DeviceHealthService deviceHealth = ref.read(
    deviceHealthServiceProvider,
  );

  await scheduler.initialize();
  await scheduler.refreshCapabilities();
  final bool? batteryIgnored = await deviceHealth
      .isIgnoringBatteryOptimizations();

  return NotificationHealthState(
    timezone: scheduler.activeTimezone,
    scheduleMode: scheduler.effectiveScheduleMode,
    notificationsEnabled: scheduler.notificationsEnabled,
    canScheduleExact: scheduler.canScheduleExact,
    batteryOptimizationIgnored: batteryIgnored,
  );
});

/// Flag migrasi cloud-first. Default = [MigrationFlags.fromEnvironment]:
/// tanpa `--dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true` semua flag mati
/// (perilaku produksi tetap jalur lama Isar/dual-write). APK uji device
/// owner dibangun dengan define tersebut (S1 — lihat README migrasi §13).
final migrationFlagsProvider = Provider<MigrationFlags>(
  (Ref ref) => MigrationFlags.fromEnvironment,
);

/// Sumber lokal activities (Isar).
/// Dipakai jalur produksi (dual-write, primer) dan sebagai mirror
/// cloud-first supaya rollback (flag OFF) tetap melihat data terbaru.
final activityLocalRepositoryProvider = Provider<ActivityRepository>((Ref ref) {
  return IsarActivityRepository(ref.watch(isarProvider));
});

/// Backend dokumen cloud activities (skema v2). Seam tes: bisa diganti
/// fake backend tanpa Firebase asli.
final cloudActivitiesBackendProvider = Provider<CloudActivitiesBackend>((
  Ref ref,
) {
  return FirestoreCloudActivitiesBackend(FirebaseFirestore.instance);
});

/// Status login Firebase — seam tes bersama untuk kedua jalur activity.
final cloudAuthStateProvider = Provider<CloudAuthState>(
  (Ref ref) => FirebaseCloudAuthState(),
);

final activityRepositoryProvider = Provider<ActivityRepository>((Ref ref) {
  final MigrationFlags flags = ref.watch(migrationFlagsProvider);
  return pickCloudFirst<ActivityRepository>(
    cloudFirst: flags.cloudFirstActivities,
    // Jalur cloud-first (S1): Firestore primer + mirror Isar best-effort.
    // Mirror hanya untuk rollback; baca TIDAK pernah dari mirror.
    cloud: () => CloudFirstActivityRepository(
      backend: ref.watch(cloudActivitiesBackendProvider),
      authState: ref.watch(cloudAuthStateProvider),
      mirror: ref.watch(activityLocalRepositoryProvider),
    ),
    // Jalur produksi saat ini: Isar primer + dual-write best-effort.
    fallback: () => DualWriteActivityRepository(
      local: ref.watch(activityLocalRepositoryProvider),
      authState: ref.watch(cloudAuthStateProvider),
    ),
  );
});

final oneTimeReminderRepositoryProvider = Provider<OneTimeReminderRepository>((
  Ref ref,
) {
  return IsarOneTimeReminderRepository(ref.watch(isarProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((Ref ref) {
  // Pilot dual-write: Isar tetap primer untuk baca; tulis diteruskan ke
  // Firestore bila login. Tanpa login/cloud: perilaku identik Isar murni.
  return DualWriteProgressRepository(
    local: IsarProgressRepository(ref.watch(isarProvider)),
    authState: FirebaseCloudAuthState(),
  );
});

/// Akses [DualWriteProgressRepository.syncState] untuk UI sync indicator.
final cloudSyncStateProvider = Provider<ValueNotifier<CloudSyncState>>((
  Ref ref,
) {
  final repo = ref.watch(progressRepositoryProvider);
  if (repo is DualWriteProgressRepository) {
    return repo.syncState;
  }
  // Fallback: selalu skipped jika bukan dual-write.
  return ValueNotifier<CloudSyncState>(
    CloudSyncState(status: CloudWriteStatus.skippedOffline, at: DateTime.now()),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((Ref ref) {
  return IsarSettingsRepository(ref.watch(isarProvider));
});

final threeDayRuleServiceProvider = Provider<ThreeDayRuleService>((Ref ref) {
  return ThreeDayRuleService(
    activityRepository: ref.watch(activityRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});

final activityActionsProvider = Provider<ActivityActions>((Ref ref) {
  return ActivityActions(
    activityRepository: ref.watch(activityRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
    threeDayRuleService: ref.watch(threeDayRuleServiceProvider),
    notificationCopyService: ref.watch(activityNotificationCopyServiceProvider),
  );
});

final oneTimeReminderActionsProvider = Provider<OneTimeReminderActions>((
  Ref ref,
) {
  return OneTimeReminderActions(
    repository: ref.watch(oneTimeReminderRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});

final activitiesStreamProvider = StreamProvider<List<ActivityModel>>((Ref ref) {
  return ref.watch(activityRepositoryProvider).watchAll();
});

final oneTimeRemindersStreamProvider =
    StreamProvider<List<OneTimeReminderModel>>((Ref ref) {
      return ref.watch(oneTimeReminderRepositoryProvider).watchAll();
    });

final agendaNotesStreamProvider =
    StreamProvider.family<List<AgendaNoteModel>, String>((
      Ref ref,
      String reminderId,
    ) {
      return ref
          .watch(oneTimeReminderRepositoryProvider)
          .watchNotes(reminderId);
    });

final allProgressStreamProvider = StreamProvider<List<ProgressEntryModel>>((
  Ref ref,
) {
  return ref.watch(progressRepositoryProvider).watchAll();
});

final progressByDateProvider =
    StreamProvider.family<List<ProgressEntryModel>, String>((
      Ref ref,
      String dateKey,
    ) {
      return ref.watch(progressRepositoryProvider).watchByDate(dateKey);
    });

final progressByActivityProvider =
    StreamProvider.family<List<ProgressEntryModel>, String>((
      Ref ref,
      String activityId,
    ) {
      return ref.watch(progressRepositoryProvider).watchByActivity(activityId);
    });

final settingsStreamProvider = StreamProvider<AppSettingsModel>((Ref ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>((
  Ref ref,
) {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier() : super(const Locale(AppConstants.localeId));

  void setLocale(Locale locale) {
    state = locale;
  }
}

final statsServiceProvider = Provider<StatsService>(
  (Ref ref) => StatsService(),
);

final globalScheduledStatsCalculatorProvider =
    Provider<GlobalScheduledStatsCalculator>((Ref ref) {
      final List<ActivityModel> activities =
          ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
      final List<ProgressEntryModel> progress =
          ref.watch(allProgressStreamProvider).value ??
          const <ProgressEntryModel>[];

      return GlobalScheduledStatsCalculator(
        activities: activities,
        progressEntries: progress,
      );
    });

final globalStatsProvider = Provider<GlobalStats>((Ref ref) {
  final List<ActivityModel> activities =
      ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
  final List<ProgressEntryModel> progress =
      ref.watch(allProgressStreamProvider).value ??
      const <ProgressEntryModel>[];

  return ref
      .watch(statsServiceProvider)
      .buildGlobalStats(activities: activities, progressEntries: progress);
});

final homeGlobalStreakProvider = Provider<int>((Ref ref) {
  final List<ActivityModel> activities =
      ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
  final List<ProgressEntryModel> progress =
      ref.watch(allProgressStreamProvider).value ??
      const <ProgressEntryModel>[];

  return ref
      .watch(statsServiceProvider)
      .computeGlobalStreak(activities: activities, progressEntries: progress);
});

final activityDetailMlPredictionProvider =
    FutureProvider.family<ActivityDetailMlPrediction?, String>((
      Ref ref,
      String activityId,
    ) async {
      if (!AiDemoConfig.onDeviceMlEnabled) {
        return null;
      }

      final List<ActivityModel> activities =
          ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
      ActivityModel? activity;
      for (final ActivityModel item in activities) {
        if (item.id == activityId) {
          activity = item;
          break;
        }
      }
      if (activity == null) {
        return null;
      }

      final List<ProgressEntryModel> entries =
          ref.watch(progressByActivityProvider(activityId)).value ??
          const <ProgressEntryModel>[];
      final GlobalStats stats = ref.watch(globalStatsProvider);
      ActivityBreakdown? breakdown;
      for (final ActivityBreakdown item in stats.breakdowns) {
        if (item.activity.id == activityId) {
          breakdown = item;
          break;
        }
      }

      return ref
          .watch(activityDetailMlServiceProvider)
          .predict(
            activity: activity,
            entries: entries,
            breakdown: breakdown,
            today: dateOnly(DateTime.now()),
          );
    });

final activityFormMlPredictionProvider =
    FutureProvider.family<ActivityFormMlPrediction?, ActivityFormMlRequest>((
      Ref ref,
      ActivityFormMlRequest request,
    ) async {
      if (!AiDemoConfig.onDeviceMlEnabled) {
        return null;
      }
      return ref.watch(activityFormMlServiceProvider).predict(request: request);
    });

final statsMlInsightProvider =
    FutureProvider.family<StatsMlInsight?, StatsMlRequest>((
      Ref ref,
      StatsMlRequest request,
    ) async {
      if (!AiDemoConfig.onDeviceMlEnabled) {
        return null;
      }
      return ref.watch(statsMlServiceProvider).predict(request: request);
    });

final homeMlPredictionProvider =
    FutureProvider.family<HomeMlPrediction?, HomeMlRequest>((
      Ref ref,
      HomeMlRequest request,
    ) async {
      if (!AiDemoConfig.onDeviceMlEnabled) {
        return null;
      }
      return ref.watch(homeMlServiceProvider).predict(request: request);
    });

final appBootstrapProvider = FutureProvider<void>((Ref ref) async {
  final SettingsRepository settingsRepo = ref.watch(settingsRepositoryProvider);
  final AppSettingsModel settings = await settingsRepo.get();

  ref.read(appLocaleProvider.notifier).setLocale(Locale(settings.localeCode));

  // Run heavy notification rescheduling asynchronously in background
  // so app UI opens instantly without waiting for native platform channels.
  unawaited(() async {
    try {
      await ref.read(activityActionsProvider).bootstrapRescheduleAndEvaluate();
      await ref.read(oneTimeReminderActionsProvider).bootstrapReschedule();
    } catch (_) {
      // Ignore background reschedule errors on startup
    }
  }());
});

final homeSelectedWeekdayProvider = StateProvider<int>(
  (Ref ref) => DateTime.now().weekday,
);

class TodayActivityState {
  const TodayActivityState({
    required this.activity,
    required this.progressEntry,
    required this.isScheduledToday,
  });

  final ActivityModel activity;
  final ProgressEntryModel? progressEntry;
  final bool isScheduledToday;

  bool get isCompletedToday => progressEntry?.isCompleted == true;
}

final todayActivitiesProvider = Provider<List<TodayActivityState>>((Ref ref) {
  final DateTime today = dateOnly(DateTime.now());
  final String todayKey = dateKeyFromDate(today);
  final List<ActivityModel> activities =
      ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
  final List<ProgressEntryModel> progress =
      ref.watch(progressByDateProvider(todayKey)).value ??
      const <ProgressEntryModel>[];

  final Map<String, ProgressEntryModel> progressByActivity =
      <String, ProgressEntryModel>{};
  for (final ProgressEntryModel entry in progress) {
    if (entry.dateKey == todayKey) {
      progressByActivity[entry.activityId] = entry;
    }
  }

  final List<TodayActivityState> items = activities.map((
    ActivityModel activity,
  ) {
    return TodayActivityState(
      activity: activity,
      progressEntry: progressByActivity[activity.id],
      isScheduledToday: activity.selectedDays.contains(today.weekday),
    );
  }).toList();

  items.sort((TodayActivityState a, TodayActivityState b) {
    return a.activity.timeMinutes.compareTo(b.activity.timeMinutes);
  });
  return items;
});
