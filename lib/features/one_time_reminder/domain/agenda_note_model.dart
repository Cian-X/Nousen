class AgendaNoteModel {
  const AgendaNoteModel({
    required this.id,
    required this.reminderId,
    required this.text,
    this.photoPaths = const <String>[],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reminderId;
  final String text;
  final List<String> photoPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgendaNoteModel copyWith({
    String? id,
    String? reminderId,
    String? text,
    List<String>? photoPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgendaNoteModel(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      text: text ?? this.text,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AgendaMilestone {
  const AgendaMilestone({
    required this.label,
    required this.date,
    required this.done,
  });

  final String label;
  final DateTime date;
  final bool done;
}
