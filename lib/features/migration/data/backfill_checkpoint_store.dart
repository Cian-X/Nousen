import 'dart:convert';
import 'dart:io';

/// Penyimpan checkpoint backfill (resume lintas app-restart).
abstract class BackfillCheckpointStore {
  /// Null bila belum ada checkpoint.
  Future<Map<String, Object?>?> load();

  Future<void> save(Map<String, Object?> data);
}

/// Checkpoint JSON di `<appDocuments>/migration/backfill_checkpoint.json`.
///
/// Checkpoint dipartisi per uid; bila uid di file berbeda dengan uid run,
/// checkpoint lama diabaikan (mulai dari nol) dan file akan ditimpa saat
/// persist pertama. Aman karena sink memakai `createDoc` atomik
/// (create-if-absent) — tulis ulang tidak pernah menimpa dokumen cloud.
class FileBackfillCheckpointStore implements BackfillCheckpointStore {
  FileBackfillCheckpointStore({
    required Future<Directory> Function() baseDirectoryProvider,
  }) : _baseDirectoryProvider = baseDirectoryProvider;

  final Future<Directory> Function() _baseDirectoryProvider;

  static const String _fileName = 'backfill_checkpoint.json';

  Future<File> _file() async {
    final Directory base = await _baseDirectoryProvider();
    final Directory dir = Directory(
      '${base.path}${Platform.pathSeparator}migration',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<Map<String, Object?>?> load() async {
    final File file = await _file();
    if (!await file.exists()) {
      return null;
    }
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return decoded.cast<String, Object?>();
  }

  @override
  Future<void> save(Map<String, Object?> data) async {
    final File file = await _file();
    await file.writeAsString(jsonEncode(data), flush: true);
  }
}
