import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/migration/application/isar_archive_service.dart';
import 'package:nousen/features/migration/data/isar_archive_source.dart';
import 'package:nousen/features/migration/domain/isar_archive.dart';

class _FakeArchiveSource implements IsarArchiveSource {
  _FakeArchiveSource({
    this.isSynthetic = true,
    Map<IsarArchiveCollection, List<Map<String, Object?>>>? docs,
  }) : _docs = docs ?? <IsarArchiveCollection, List<Map<String, Object?>>>{};

  @override
  final bool isSynthetic;

  @override
  String get sourceLabel => 'unit-test';

  @override
  String get databaseName => 'nousen_s6_scratch_unit';

  final Map<IsarArchiveCollection, List<Map<String, Object?>>> _docs;

  final Map<IsarArchiveCollection, int> readCalls =
      <IsarArchiveCollection, int>{};

  @override
  Future<List<Map<String, Object?>>> readAll(
    IsarArchiveCollection collection,
  ) async {
    readCalls[collection] = (readCalls[collection] ?? 0) + 1;
    return (_docs[collection] ?? const <Map<String, Object?>>[])
        .map((Map<String, Object?> doc) => Map<String, Object?>.from(doc))
        .toList(growable: false);
  }
}

Map<String, Object?> _doc(int isarId, {String? id}) {
  return <String, Object?>{
    'isarId': isarId,
    'id': id ?? 'doc-$isarId',
    'updatedAt': '2026-10-22T10:00:00.000',
  };
}

void main() {
  group('IsarArchiveService (S6.0)', () {
    test('capture semua koleksi + capturedAt UTC dari clock', () async {
      final _FakeArchiveSource source = _FakeArchiveSource(
        docs: <IsarArchiveCollection, List<Map<String, Object?>>>{
          IsarArchiveCollection.settings: <Map<String, Object?>>[_doc(1)],
          IsarArchiveCollection.activities: <Map<String, Object?>>[
            _doc(2, id: 'a2'),
            _doc(1, id: 'a1'),
          ],
          IsarArchiveCollection.progress: <Map<String, Object?>>[_doc(7)],
        },
      );
      final IsarArchiveService service = IsarArchiveService(
        source: source,
        now: () => DateTime.utc(2026, 10, 22, 12, 30),
      );

      final IsarArchive archive = await service.capture();

      expect(archive.capturedAtUtc, DateTime.utc(2026, 10, 22, 12, 30));
      expect(archive.sourceLabel, 'unit-test');
      expect(archive.databaseName, 'nousen_s6_scratch_unit');
      expect(archive.countOf(IsarArchiveCollection.settings), 1);
      expect(archive.countOf(IsarArchiveCollection.activities), 2);
      expect(archive.countOf(IsarArchiveCollection.reminders), 0);
      expect(archive.countOf(IsarArchiveCollection.agendaNotes), 0);
      expect(archive.countOf(IsarArchiveCollection.progress), 1);
      expect(archive.totalDocuments, 4);
      // Semua koleksi dibaca sekali, walau kosong.
      expect(source.readCalls.length, IsarArchiveCollection.values.length);
    });

    test(
      'guard: sumber non-synthetic ditolak sebelum membaca apa pun',
      () async {
        final _FakeArchiveSource source = _FakeArchiveSource(
          isSynthetic: false,
        );
        final IsarArchiveService service = IsarArchiveService(source: source);

        await expectLater(service.capture(), throwsA(isA<StateError>()));
        expect(source.readCalls, isEmpty);
      },
    );

    test('capture menolak dokumen tanpa isarId dan isarId duplikat', () async {
      final _FakeArchiveSource missingId = _FakeArchiveSource(
        docs: <IsarArchiveCollection, List<Map<String, Object?>>>{
          IsarArchiveCollection.activities: <Map<String, Object?>>[
            <String, Object?>{'id': 'tanpa-isar-id'},
          ],
        },
      );
      await expectLater(
        IsarArchiveService(source: missingId).capture(),
        throwsA(isA<FormatException>()),
      );

      final _FakeArchiveSource duplicate = _FakeArchiveSource(
        docs: <IsarArchiveCollection, List<Map<String, Object?>>>{
          IsarArchiveCollection.activities: <Map<String, Object?>>[
            _doc(4, id: 'a1'),
            _doc(4, id: 'a2'),
          ],
        },
      );
      await expectLater(
        IsarArchiveService(source: duplicate).capture(),
        throwsA(isA<FormatException>()),
      );
    });

    test('encode → decode roundtrip mempertahankan koleksi & data', () async {
      final _FakeArchiveSource source = _FakeArchiveSource(
        docs: <IsarArchiveCollection, List<Map<String, Object?>>>{
          IsarArchiveCollection.settings: <Map<String, Object?>>[
            <String, Object?>{'isarId': 1, 'localeCode': 'id'},
          ],
          IsarArchiveCollection.activities: <Map<String, Object?>>[
            <String, Object?>{
              'isarId': 3,
              'id': 'a3',
              'selectedDays': <int>[1, 3],
            },
          ],
          IsarArchiveCollection.reminders: <Map<String, Object?>>[
            <String, Object?>{'isarId': 2, 'id': 'r2', 'title': 'Minum air'},
          ],
          IsarArchiveCollection.agendaNotes: <Map<String, Object?>>[
            <String, Object?>{
              'isarId': 9,
              'id': 'n9',
              'photoPaths': <String>['/local/photo.jpg'],
            },
          ],
          IsarArchiveCollection.progress: <Map<String, Object?>>[
            <String, Object?>{
              'isarId': 5,
              'id': 'p5',
              'photoPaths': <String>[],
            },
          ],
        },
      );
      final IsarArchive archive = await IsarArchiveService(
        source: source,
        now: () => DateTime.utc(2026, 10, 22),
      ).capture();

      final String encoded = archive.encode();
      final Object? decoded = jsonDecode(encoded);
      final IsarArchive restored = IsarArchive.fromJson(
        (decoded as Map).cast<String, Object?>(),
      );

      expect(restored.capturedAtUtc, archive.capturedAtUtc);
      expect(restored.sourceLabel, archive.sourceLabel);
      expect(restored.databaseName, archive.databaseName);
      expect(restored.totalDocuments, archive.totalDocuments);
      expect(
        restored.collections[IsarArchiveCollection.activities]!.single['id'],
        'a3',
      );
      expect(
        restored
            .collections[IsarArchiveCollection.agendaNotes]!
            .single['photoPaths'],
        <String>['/local/photo.jpg'],
      );
      expect(restored.encode(), encoded);
    });

    test('fromJson ketat: versi, koleksi wajib, dan isarId duplikat', () {
      final Map<String, Object?> base = <String, Object?>{
        'schemaVersion': IsarArchive.schemaVersion,
        'capturedAt': '2026-10-22T00:00:00.000Z',
        'sourceLabel': 'unit-test',
        'databaseName': 'nousen_s6_scratch_unit',
        'collections': <String, Object?>{
          for (final IsarArchiveCollection collection
              in IsarArchiveCollection.values)
            collection.key: <Object?>[],
        },
      };

      expect(
        () => IsarArchive.fromJson(<String, Object?>{
          ...base,
          'schemaVersion': 999,
        }),
        throwsA(isA<FormatException>()),
      );

      final Map<String, Object?> missingSource = <String, Object?>{...base}
        ..remove('sourceLabel');
      expect(
        () => IsarArchive.fromJson(missingSource),
        throwsA(isA<FormatException>()),
      );

      final Map<String, Object?> missingCollection = <String, Object?>{
        ...base,
        'collections': <String, Object?>{'settings': <Object?>[]},
      };
      expect(
        () => IsarArchive.fromJson(missingCollection),
        throwsA(isA<FormatException>()),
      );

      final Map<String, Object?> unknownCollection = <String, Object?>{
        ...base,
        'collections': <String, Object?>{
          ...(base['collections']! as Map).cast<String, Object?>(),
          'unknown': <Object?>[],
        },
      };
      expect(
        () => IsarArchive.fromJson(unknownCollection),
        throwsA(isA<FormatException>()),
      );

      final Map<String, Object?> duplicate = <String, Object?>{
        ...base,
        'collections': <String, Object?>{
          ...(base['collections']! as Map).cast<String, Object?>(),
          'activities': <Object?>[
            <String, Object?>{'isarId': 1},
            <String, Object?>{'isarId': 1},
          ],
        },
      };
      expect(
        () => IsarArchive.fromJson(duplicate),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('validateS6ScratchDatabaseName', () {
    test('menerima prefix scratch dan menolak DB produksi', () {
      expect(
        () => validateS6ScratchDatabaseName('nousen_s6_scratch_owner'),
        returnsNormally,
      );
      expect(
        () => validateS6ScratchDatabaseName('reminder_schedule_v2'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
