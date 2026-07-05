enum ActivityDayStatus { done, notDone, skipped }

extension ActivityDayStatusX on ActivityDayStatus {
  String get storageKey => switch (this) {
    ActivityDayStatus.done => 'done',
    ActivityDayStatus.notDone => 'not_done',
    ActivityDayStatus.skipped => 'skipped',
  };
}

ActivityDayStatus activityDayStatusFromStorage(
  String? raw, {
  bool fallbackCompleted = false,
}) {
  return switch ((raw ?? '').trim().toLowerCase()) {
    'done' => ActivityDayStatus.done,
    'skipped' => ActivityDayStatus.skipped,
    'not_done' => ActivityDayStatus.notDone,
    _ => fallbackCompleted ? ActivityDayStatus.done : ActivityDayStatus.notDone,
  };
}

class ProgressEntryModel {
  const ProgressEntryModel({
    required this.id,
    required this.activityId,
    required this.dateKey,
    required this.status,
    required this.subCompleted,
    required this.subTotal,
    required this.completedSubActivities,
    required this.photoPaths,
    required this.photoPath,
    required this.photoNote,
    required this.notes,
    this.completionTime,
    @Deprecated('Use completionTime instead') this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(
         completionTime == null || completedAt == null,
         'Use completionTime only.',
       );

  final String id;
  final String activityId;
  final String dateKey;
  final ActivityDayStatus status;
  final int subCompleted;
  final int subTotal;
  final List<String> completedSubActivities;
  final List<String> photoPaths;
  final String? photoPath;
  final String? photoNote;
  final String? notes;
  final DateTime? completionTime;
  @Deprecated('Use completionTime instead')
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == ActivityDayStatus.done;
  bool get isSkipped => status == ActivityDayStatus.skipped;
  String get statusKey => status.storageKey;
  DateTime get date => DateTime.parse(dateKey);
  // ignore: deprecated_member_use_from_same_package
  DateTime? get effectiveCompletionTime => completionTime ?? completedAt;

  ProgressEntryModel copyWith({
    String? id,
    String? activityId,
    String? dateKey,
    ActivityDayStatus? status,
    int? subCompleted,
    int? subTotal,
    List<String>? completedSubActivities,
    List<String>? photoPaths,
    String? photoPath,
    bool clearPhotoPath = false,
    bool clearPhotoPaths = false,
    String? photoNote,
    bool clearPhotoNote = false,
    String? notes,
    bool clearNotes = false,
    DateTime? completionTime,
    bool clearCompletionTime = false,
    @Deprecated('Use completionTime instead') DateTime? completedAt,
    @Deprecated('Use clearCompletionTime instead')
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressEntryModel(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      dateKey: dateKey ?? this.dateKey,
      status: status ?? this.status,
      subCompleted: subCompleted ?? this.subCompleted,
      subTotal: subTotal ?? this.subTotal,
      completedSubActivities:
          completedSubActivities ?? this.completedSubActivities,
      photoPaths: clearPhotoPaths
          ? const <String>[]
          : (photoPaths ?? this.photoPaths),
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      photoNote: clearPhotoNote ? null : (photoNote ?? this.photoNote),
      notes: clearNotes ? null : (notes ?? this.notes),
      completionTime: clearCompletionTime || clearCompletedAt
          ? null
          : (completionTime ?? completedAt ?? effectiveCompletionTime),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
