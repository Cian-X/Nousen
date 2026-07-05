import 'package:isar/isar.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

part 'progress_entry_entity.g.dart';

@collection
class ProgressEntryEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String activityId;

  @Index()
  late String dateKey;

  late String statusKey;
  late int subCompleted;
  late int subTotal;
  late bool isCompleted;
  late List<String> completedSubActivities;
  late List<String> photoPaths;
  String? photoPath;
  String? photoNote;
  String? notes;
  DateTime? completedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}

extension ProgressEntryEntityMapper on ProgressEntryEntity {
  ProgressEntryModel toDomain() {
    final List<String> normalizedPhotoPaths = photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    if (normalizedPhotoPaths.isEmpty &&
        photoPath != null &&
        photoPath!.trim().isNotEmpty) {
      normalizedPhotoPaths.add(photoPath!.trim());
    }
    final List<String> normalizedCompletedSubs = completedSubActivities
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    final int effectiveSubCompleted = subCompleted > 0
        ? subCompleted
        : normalizedCompletedSubs.length;
    final int effectiveSubTotal = subTotal >= effectiveSubCompleted
        ? subTotal
        : effectiveSubCompleted;

    return ProgressEntryModel(
      id: id,
      activityId: activityId,
      dateKey: dateKey,
      status: activityDayStatusFromStorage(
        statusKey,
        fallbackCompleted: isCompleted,
      ),
      subCompleted: effectiveSubCompleted,
      subTotal: effectiveSubTotal,
      completedSubActivities: normalizedCompletedSubs,
      photoPaths: normalizedPhotoPaths,
      photoPath: normalizedPhotoPaths.isEmpty
          ? null
          : normalizedPhotoPaths.first,
      photoNote: photoNote,
      notes: notes,
      completionTime: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

ProgressEntryEntity progressEntityFromDomain(ProgressEntryModel model) {
  final ProgressEntryEntity entity = ProgressEntryEntity()
    ..id = model.id
    ..activityId = model.activityId
    ..dateKey = model.dateKey
    ..statusKey = model.statusKey
    ..subCompleted = model.subCompleted
    ..subTotal = model.subTotal
    ..isCompleted = model.isCompleted
    ..completedSubActivities = model.completedSubActivities
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList()
    ..photoPaths = model.photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList()
    ..photoPath = model.photoPaths.isNotEmpty
        ? model.photoPaths.first
        : model.photoPath
    ..photoNote = model.photoNote
    ..notes = model.notes
    ..completedAt = model.effectiveCompletionTime
    ..createdAt = model.createdAt
    ..updatedAt = model.updatedAt;
  return entity;
}
