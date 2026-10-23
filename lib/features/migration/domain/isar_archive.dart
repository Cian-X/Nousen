import 'dart:convert';

import 'package:crypto/crypto.dart';

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
  ///
  /// v2 menambahkan `counts` dan `checksum` (SHA-256) untuk integritas.
  static const int schemaVersion = 2;

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

  /// Jumlah dokumen per koleksi. Ikut ditulis ke JSON dan divalidasi ketat
  /// saat parse (harus sama dengan panjang array koleksi).
  Map<String, int> get counts => <String, int>{
    for (final IsarArchiveCollection collection in IsarArchiveCollection.values)
      collection.key: countOf(collection),
  };

  /// SHA-256 dari payload archive kanonik (tanpa field `checksum` itu sendiri).
  ///
  /// Map diurutkan berdasarkan key sebelum di-hash agar checksum stabil
  /// terhadap urutan field. Checksum mendeteksi archive terpotong, field
  /// berubah, atau metadata yang diubah tanpa recompute.
  String get checksum => _sha256(_canonicalJson(_checksumPayload()));

  Map<String, Object?> _checksumPayload() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'capturedAt': capturedAtUtc.toIso8601String(),
      'sourceLabel': sourceLabel,
      'databaseName': databaseName,
      'counts': counts,
      'collections': <String, Object?>{
        for (final IsarArchiveCollection collection
            in IsarArchiveCollection.values)
          collection.key: collections[collection],
      },
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{..._checksumPayload(), 'checksum': checksum};
  }

  String encode({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Parse archive dari string JSON. Lihat [IsarArchive.fromJson].
  factory IsarArchive.decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw FormatException('JSON archive tidak valid: ${error.message}');
    }
    if (decoded is! Map) {
      throw const FormatException('archive harus berupa object');
    }
    final Map<String, Object?> json = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in decoded.entries) {
      final Object? key = entry.key;
      if (key is! String) {
        throw const FormatException('key archive harus string');
      }
      json[key] = entry.value;
    }
    return IsarArchive.fromJson(json);
  }

  /// Parse archive dari JSON. Ketat: versi skema, semua koleksi wajib ada,
  /// tiap dokumen wajib punya `isarId` int unik dalam koleksinya, `counts`
  /// harus cocok dengan panjang koleksi, dan `checksum` harus cocok.
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

    final Map<String, int> actualCounts = <String, int>{
      for (final IsarArchiveCollection collection
          in IsarArchiveCollection.values)
        collection.key: parsed[collection]!.length,
    };
    final Map<String, int> providedCounts = _parseCounts(json['counts']);
    if (!_intMapsEqual(providedCounts, actualCounts)) {
      throw FormatException(
        'counts tidak cocok dengan isi koleksi: '
        '$providedCounts != $actualCounts',
      );
    }

    final IsarArchive archive = IsarArchive(
      capturedAtUtc: capturedAt,
      sourceLabel: rawSourceLabel,
      databaseName: rawDatabaseName,
      collections: parsed,
    );

    final Object? rawChecksum = json['checksum'];
    if (rawChecksum is! String || rawChecksum.trim().isEmpty) {
      throw const FormatException('checksum tidak valid');
    }
    if (archive.checksum != rawChecksum) {
      throw const FormatException('checksum tidak cocok dengan isi archive');
    }
    return archive;
  }
}

Map<String, int> _parseCounts(Object? rawCounts) {
  if (rawCounts is! Map) {
    throw const FormatException('counts harus berupa object');
  }
  final Map<String, int> counts = <String, int>{};
  for (final MapEntry<Object?, Object?> entry in rawCounts.entries) {
    final Object? key = entry.key;
    final Object? value = entry.value;
    if (key is! String || value is! int || value < 0) {
      throw const FormatException('counts harus map string -> int >= 0');
    }
    counts[key] = value;
  }
  return counts;
}

bool _intMapsEqual(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<String, int> entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final List<String> keys = <String>[];
    for (final Object? key in value.keys) {
      if (key is! String) {
        throw const FormatException('checksum: key map harus string');
      }
      keys.add(key);
    }
    keys.sort();
    return <String, Object?>{
      for (final String key in keys) key: _canonicalJson(value[key]),
    };
  }
  if (value is List) {
    return value.map(_canonicalJson).toList(growable: false);
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw FormatException('checksum: tipe tidak didukung ${value.runtimeType}');
}

String _sha256(Object? canonicalPayload) =>
    sha256.convert(utf8.encode(jsonEncode(canonicalPayload))).toString();
