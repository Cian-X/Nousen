// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';
import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/settings/data/isar_settings_repository.dart';

class DataSeederService {
  final Isar isar;
  final IsarSettingsRepository settingsRepository;

  DataSeederService({
    required this.isar,
    required this.settingsRepository,
  });

  Future<bool> seedAllFromJson() async {
    // Cek apakah sudah pernah di-seed
    final settings = await settingsRepository.get();
    if (settings.hasSeededData) {
      print('Data already seeded, skipping');
      return false;
    }

    try {
      // Seed activities first
      final bool activitiesOk = await _seedActivities();
      // Then seed progress entries
      final bool progressOk = await _seedProgressEntries();
      // Tandai selesai hanya bila KEDUA bagian benar-benar terseed;
      // bila aset hilang dan dilewati, biarkan false agar dicoba lagi
      // saat aset tersedia (tidak mengunci state seeded palsu).
      if (activitiesOk && progressOk) {
        await _markAsSeeded();
      }
      print('Data seeding completed successfully');
      return true;
    } catch (e) {
      print('Error during data seeding: $e');
      rethrow;
    }
  }

  /// true bila seeding jalan (walau 0 baris); false bila aset hilang.
  Future<bool> _seedActivities() async {
    try {
      final jsonString = await rootBundle.loadString('assets/ai/catalog_activities.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final List<ActivityEntity> entities = <ActivityEntity>[];
      for (final json in jsonList) {
        final Map<String, dynamic> item = json as Map<String, dynamic>;
        final entity = ActivityEntity()
          ..id = item['id'] as String
          ..title = item['title'] as String
          ..selectedDays = <int>[]
          ..subActivities = <String>[]
          ..timeMinutes = item['duration'] != null ? (item['duration'] as int) : 30
          ..weeklyGoal = 1
          ..preReminderMinutes = 15
          ..isNotificationEnabled = true
          ..enableMorningReminder = false
          ..enableEndOfDayReminder = false
          ..enablePhotoProgress = false
          ..lastThreeDayRuleNotifiedDate = null
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        entities.add(entity);
      }

      await isar.writeTxn(() => isar.activityEntitys.putAll(entities));
      print('Seeded ${entities.length} activities');
      return true;
    } catch (e) {
      // Aset seeder opsional (tidak dibundel rilis): lewati tanpa crash.
      print('Skip seeding activities (aset tidak tersedia): $e');
      return false;
    }
  }

  /// true bila seeding jalan; false bila aset hilang.
  Future<bool> _seedProgressEntries() async {
    try {
      final jsonString = await rootBundle.loadString('assets/ai/progress_entries.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final List<ProgressEntryEntity> entities = <ProgressEntryEntity>[];
      for (final json in jsonList) {
        final Map<String, dynamic> item = json as Map<String, dynamic>;
        final entity = ProgressEntryEntity()
          ..id = (item['id'] as String?) ?? '${item['user_id']}_${item['activity_id']}_${item['date_key']}'
          ..activityId = item['activity_id'] as String
          ..dateKey = item['date_key'] as String
          ..statusKey = item['status'] as String? ?? 'pending'
          ..subCompleted = 1
          ..subTotal = 1
          ..isCompleted = (item['status'] as String? ?? 'pending') == 'completed'
          ..completedSubActivities = <String>[]
          ..photoPaths = <String>[]
          ..photoPath = null
          ..photoNote = null
          ..notes = null
          ..completedAt = null
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        entities.add(entity);
      }

      await isar.writeTxn(() => isar.progressEntryEntitys.putAll(entities));
      print('Seeded ${entities.length} progress entries');
      return true;
    } catch (e) {
      // Aset seeder opsional (tidak dibundel rilis): lewati tanpa crash.
      print('Skip seeding progress entries (aset tidak tersedia): $e');
      return false;
    }
  }

  Future<void> _markAsSeeded() async {
    final existing = await settingsRepository.get();
    final updated = existing.copyWith(hasSeededData: true);
    await settingsRepository.save(updated);
    print('Marked as seeded');
  }
}
