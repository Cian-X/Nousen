import 'dart:convert';

/// Koleksi Isar yang ikut archive JSON penuh S6.0.
///
/// Urutan deklarasi = urutan capture (deterministik).
enum IsarArchiveCollection {
  settings('settings'),
  activities('activities'),
  reminders('reminders'),
  agendaNotes('agendaNotes'),
  progress('progress');

  const IsarArchiveCollection(this.key);

  /// Nama koleksi di JSON archive.
  final String key;

  static IsarArchiveCollection? tryParse(String key) {
    for (final IsarArchiveCollection collection in values) {
      if (collection.key == key) {
        return collection;
      }
    }
    return null;
  }
}

/// Snapshot JSON penuh seluruh koleksi Isar.
///
/// Dipakai HANYA untuk validasi synthetic/scratch (lihat
/// [IsarArchiveService] dan `IsarArchiveSource.isSynthetic`). Archive ini
/// tidak menulis apa pun ke Isar/Firestore — murni capture + encode JSON.
class IsarArchive {
  IsarArchive({
    required DateTime capturedAtUtc,
    required this.sourceLabel,
    required this.databaseName,
    required Map<IsarArchiveCollection, List<Map<String, Object?>>> collections,
  }) : capturedAtUtc = capturedAtUtc.toUtc(),
       collections =
           Map<IsarArchiveCollection, List<Map<String, Object?>>>.unmodifiable(
             <IsarArchiveCollection, List<Map<String, Object?>>>{
               for (final IsarArchiveCollection collection
                   in IsarArchiveCollection.values)
                 collection: List<Map<String, Object?>>.unmodifiable(
                   (collections[collection] ?? const <Map<String, Object?>>[])
                       .map(
                         (Map<String, Object?> doc) =>
                             Map<String, Object?>.unmodifiable(
                               Map<String, Object?>.from(doc),
                             ),
                       ),
                 ),
             },
           );

  /// Versi format archive JSON (bukan versi skema data aplikasi).
  static const int schemaVersion = 1;

  final DateTime capturedAtUtc;

  /// Label audit sumber (mis. `s6-scratch-2026-10-22`).
  final String sourceLabel;

  /// Nama database Isar sumber (wajib berprefix scratch).
  final String databaseName;

  final Map<IsarArchiveCollection, List<Map<String, Object?>>> collections;

  int countOf(IsarArchiveCollection collection) =>
      collections[collection]?.length ?? 0;

  int get totalDocuments => IsarArchiveCollection.values.fold(
    0,
    (int sum, IsarArchiveCollection collection) => sum + countOf(collection),
  );

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'capturedAt': capturedAtUtc.toIso8601String(),
      'sourceLabel': sourceLabel,
      'databaseName': databaseName,
      'collections': <String, Object?>{
        for (final IsarArchiveCollection collection
            in IsarArchiveCollection.values)
          collection.key: collections[collection],
      },
    };
  }

  String encode({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Parse archive dari JSON. Ketat: versi skema, semua koleksi wajib ada,
  /// tiap dokumen wajib punya `isarId` int unik dalam koleksinya.
  factory IsarArchive.fromJson(Map<String, Object?> json) {
    final Object? rawVersion = json['schemaVersion'];
    if (rawVersion is! int || rawVersion != schemaVersion) {
      throw FormatException(
        'versi archive tidak didukung: $rawVersion (harus $schemaVersion)',
      );
    }

    final Object? rawCapturedAt = json['capturedAt'];
    final DateTime? capturedAt = rawCapturedAt is String
        ? DateTime.tryParse(rawCapturedAt)
        : null;
    if (capturedAt == null) {
      throw const FormatException('capturedAt tidak valid');
    }

    final Object? rawSourceLabel = json['sourceLabel'];
    if (rawSourceLabel is! String || rawSourceLabel.trim().isEmpty) {
      throw const FormatException('sourceLabel tidak valid');
    }
    final Object? rawDatabaseName = json['databaseName'];
    if (rawDatabaseName is! String || rawDatabaseName.trim().isEmpty) {
      throw const FormatException('databaseName tidak valid');
    }

    final Object? rawCollections = json['collections'];
    if (rawCollections is! Map) {
      throw const FormatException('collections harus berupa object');
    }

    final Map<IsarArchiveCollection, List<Map<String, Object?>>> parsed =
        <IsarArchiveCollection, List<Map<String, Object?>>>{};
    for (final MapEntry<Object?, Object?> entry in rawCollections.entries) {
      final Object? rawKey = entry.key;
      if (rawKey is! String) {
        throw const FormatException('key koleksi harus string');
      }
      final IsarArchiveCollection? collection = IsarArchiveCollection.tryParse(
        rawKey,
      );
      if (collection == null) {
        throw FormatException('koleksi tidak dikenal: $rawKey');
      }
      final Object? rawDocs = entry.value;
      if (rawDocs is! List) {
        throw FormatException('koleksi $rawKey harus berupa array');
      }

      final List<Map<String, Object?>> docs = <Map<String, Object?>>[];
      final Set<int> seenIsarIds = <int>{};
      for (final Object? rawDoc in rawDocs) {
        if (rawDoc is! Map) {
          throw FormatException('dokumen $rawKey harus berupa object');
        }
        final Map<String, Object?> doc = <String, Object?>{};
        for (final MapEntry<Object?, Object?> field in rawDoc.entries) {
          final Object? key = field.key;
          if (key is! String) {
            throw FormatException('field $rawKey harus string key');
          }
          doc[key] = field.value;
        }
        final Object? isarId = doc['isarId'];
        if (isarId is! int) {
          throw FormatException('dokumen $rawKey tanpa isarId int');
        }
        if (!seenIsarIds.add(isarId)) {
          throw FormatException('isarId duplikat di $rawKey: $isarId');
        }
        docs.add(doc);
      }
      parsed[collection] = docs;
    }

    for (final IsarArchiveCollection collection
        in IsarArchiveCollection.values) {
      if (!parsed.containsKey(collection)) {
        throw FormatException('koleksi wajib hilang: ${collection.key}');
      }
    }

    return IsarArchive(
      capturedAtUtc: capturedAt,
      sourceLabel: rawSourceLabel,
      databaseName: rawDatabaseName,
      collections: parsed,
    );
  }
}
