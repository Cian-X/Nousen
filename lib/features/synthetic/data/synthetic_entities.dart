import 'package:isar/isar.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

part 'synthetic_entities.g.dart';

@collection
class SyntheticActivityEntity {
  Id id = Isar.autoIncrement;

  String activityId;
  String name;
  String category;
  String description;
  bool isAnomali;
  int frequency;
  int durationMinutes;
  int scheduledTimeMinutes;
  int difficultyLevel;
  int estimatedEnergyCost;
  double estimatedFinancialCost;
  List<String> requiredResources;
  String personaJob;
  String personaTrait;
  String scheduleType;

  SyntheticActivityEntity({
    required this.activityId,
    required this.name,
    required this.category,
    required this.description,
    required this.isAnomali,
    required this.frequency,
    required this.durationMinutes,
    required this.scheduledTimeMinutes,
    required this.difficultyLevel,
    required this.estimatedEnergyCost,
    required this.estimatedFinancialCost,
    required this.requiredResources,
    required this.personaJob,
    required this.personaTrait,
    required this.scheduleType,
  });
}

extension SyntheticActivityEntityToDomain on SyntheticActivityEntity {
  ActivityModel toDomain() {
    return ActivityModel(
      id: activityId,
      title: name,
      selectedDays: [],
      subActivities: [description],
      timeMinutes: durationMinutes,
      weeklyGoal: frequency,
      preReminderMinutes: 0,
      isNotificationEnabled: true,
      enableMorningReminder: false,
      enableEndOfDayReminder: false,
      enablePhotoProgress: true,
      lastThreeDayRuleNotifiedDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      scheduleUpdatedAt: DateTime.now(),
    );
  }
}

@collection
class SyntheticProgressEntryEntity {
  Id id = Isar.autoIncrement;

  String activityId;
  String dateKey;
  String status;
  int subCompleted;
  int subTotal;
  List<String> completedSubActivities;
  List<String> photoPaths;
  String? photoPath;
  String? photoNote;
  String? notes;
  int? scheduledTimeMinutes;
  int? actualStartTimeMinutes;
  int? scheduledDurationMinutes;
  int? actualDurationMinutes;
  int postponeCount;
  bool isAnomali;
  String? personaJob;
  String? personaTrait;
  DateTime createdAt;
  DateTime updatedAt;

  SyntheticProgressEntryEntity({
    required this.activityId,
    required this.dateKey,
    required this.status,
    required this.subCompleted,
    required this.subTotal,
    required this.completedSubActivities,
    required this.photoPaths,
    this.photoPath,
    this.photoNote,
    this.notes,
    this.scheduledTimeMinutes,
    this.actualStartTimeMinutes,
    this.scheduledDurationMinutes,
    this.actualDurationMinutes,
    required this.postponeCount,
    required this.isAnomali,
    this.personaJob,
    this.personaTrait,
    required this.createdAt,
    required this.updatedAt,
  });
}

extension SyntheticProgressEntryEntityToDomain on SyntheticProgressEntryEntity {
  ProgressEntryModel toDomain() {
    return ProgressEntryModel(
      id: activityId + '_' + dateKey,
      activityId: activityId,
      dateKey: dateKey,
      status: activityDayStatusFromStorage(status, fallbackCompleted: status == 'completed'),
      subCompleted: subCompleted,
      subTotal: subTotal,
      completedSubActivities: completedSubActivities,
      photoPaths: photoPaths,
      photoPath: photoPath,
      photoNote: photoNote,
      notes: notes,
      completionTime: actualStartTimeMinutes != null
          ? DateTime.parse(dateKey).copyWith(
              hour: actualStartTimeMinutes! ~/ 60,
              minute: actualStartTimeMinutes! % 60,
            )
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
