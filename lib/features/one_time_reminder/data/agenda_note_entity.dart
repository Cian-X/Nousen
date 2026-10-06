import 'package:isar/isar.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';

part 'agenda_note_entity.g.dart';

@collection
class AgendaNoteEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String reminderId;

  late String text;
  List<String>? photoPaths;
  late DateTime createdAt;
  late DateTime updatedAt;
}

extension AgendaNoteEntityMapper on AgendaNoteEntity {
  AgendaNoteModel toDomain() {
    return AgendaNoteModel(
      id: id,
      reminderId: reminderId,
      text: text,
      photoPaths: (photoPaths ?? const <String>[])
          .where((String item) => item.trim().isNotEmpty)
          .toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

AgendaNoteEntity agendaNoteEntityFromDomain(AgendaNoteModel model) {
  final AgendaNoteEntity entity = AgendaNoteEntity()
    ..id = model.id
    ..reminderId = model.reminderId
    ..text = model.text
    ..photoPaths = model.photoPaths
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList()
    ..createdAt = model.createdAt
    ..updatedAt = model.updatedAt;
  return entity;
}
