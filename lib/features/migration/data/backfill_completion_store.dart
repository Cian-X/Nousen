import 'dart:convert';
import 'dart:io';

import 'package:nousen/features/migration/domain/backfill_completion.dart';

/// Penyimpan marker login-first backfill per uid (durable lintas restart).
abstract class BackfillCompletionStore {
  /// Null bila uid belum pernah menyelesaikan backfill (atau marker rusak).
  Future<BackfillCompletion?> load(String uid);

  /// Simpan/ubin marker uid. Aman dipanggil berulang (idempoten).
  Future<void> markCompleted(BackfillCompletion completion);
}

/// Marker JSON di `<appDocuments>/migration/backfill_completion.json`.
///
/// Bentuk file:
/// ```json
/// {"storeVersion": 1, "uids": {"<uid>": {"completedAt": "...", "version": 1}}}
/// ```
///
/// File rusak / versi tidak dikenal diperlakukan sebagai "belum ada marker"
/// sehingga login berikutnya menjalankan full rescan (backfill idempoten).
class FileBackfillCompletionStore implements BackfillCompletionStore {
  FileBackfillCompletionStore({
    required Future<Directory> Function() baseDirectoryProvider,
  }) : _baseDirectoryProvider = baseDirectoryProvider;

  final Future<Directory> Function() _baseDirectoryProvider;

  static const int storeVersion = 1;
  static const String _fileName = 'backfill_completion.json';

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

  Future<Map<String, Object?>> _readUids() async {
    final File file = await _file();
    if (!await file.exists()) {
      return <String, Object?>{};
    }
    try {
      final String raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return <String, Object?>{};
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, Object?>{};
      }
      if (decoded['storeVersion'] != storeVersion) {
        return <String, Object?>{};
      }
      final Object? rawUids = decoded['uids'];
      if (rawUids is! Map) {
        return <String, Object?>{};
      }
      return rawUids.cast<String, Object?>();
    } catch (_) {
      // Marker rusak tidak boleh memblokir retry backfill.
      return <String, Object?>{};
    }
  }

  @override
  Future<BackfillCompletion?> load(String uid) async {
    final Map<String, Object?> uids = await _readUids();
    return BackfillCompletion.fromJson(uid, uids[uid]);
  }

  @override
  Future<void> markCompleted(BackfillCompletion completion) async {
    final Map<String, Object?> uids = await _readUids();
    uids[completion.uid] = completion.toJson();
    final File file = await _file();
    await file.writeAsString(
      jsonEncode(<String, Object?>{'storeVersion': storeVersion, 'uids': uids}),
      flush: true,
    );
  }
}
