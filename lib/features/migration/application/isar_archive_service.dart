import 'package:nousen/features/migration/data/isar_archive_source.dart';
import 'package:nousen/features/migration/domain/isar_archive.dart';

/// Capture archive JSON penuh seluruh koleksi Isar.
///
/// Batas S6.0:
/// - HANYA membaca sumber yang menyatakan dirinya synthetic/scratch
///   ([IsarArchiveSource.isSynthetic] true). Sumber lain ditolak dengan
///   [StateError] SEBELUM satu baris pun dibaca.
/// - Tidak menulis ke Isar/Firestore/file. Hasilnya [IsarArchive] yang bisa
///   di-encode ke JSON oleh pemanggil (uji/scratch harness).
/// - Tidak dipanggil otomatis oleh aplikasi (tidak ada wiring di provider /
///   main).
///
/// Idempoten: capture berulang pada data sama menghasilkan koleksi yang sama
/// (urutan dokumen mengikuti `isarId`).
class IsarArchiveService {
  IsarArchiveService({
    required IsarArchiveSource source,
    DateTime Function()? now,
  }) : _source = source,
       _now = now ?? DateTime.now;

  final IsarArchiveSource _source;
  final DateTime Function() _now;

  /// Guard eksplisit: archive penuh TIDAK boleh menyentuh data live.
  Future<void> assertSyntheticOnly() async {
    if (!_source.isSynthetic) {
      throw StateError(
        'S6.0 archive hanya untuk synthetic/scratch '
        '(sumber "${_source.sourceLabel}" tidak synthetic)',
      );
    }
  }

  /// Baca semua koleksi dan bangun [IsarArchive].
  ///
  /// Validasi per dokumen:
  /// - wajib punya `isarId` int;
  /// - `isarId` unik di dalam koleksi.
  Future<IsarArchive> capture() async {
    await assertSyntheticOnly();

    final Map<IsarArchiveCollection, List<Map<String, Object?>>> collections =
        <IsarArchiveCollection, List<Map<String, Object?>>>{};
    for (final IsarArchiveCollection collection
        in IsarArchiveCollection.values) {
      final List<Map<String, Object?>> docs = await _source.readAll(collection);
      final Set<int> seenIsarIds = <int>{};
      for (final Map<String, Object?> doc in docs) {
        final Object? isarId = doc['isarId'];
        if (isarId is! int) {
          throw FormatException('${collection.key}: dokumen tanpa isarId int');
        }
        if (!seenIsarIds.add(isarId)) {
          throw FormatException('${collection.key}: isarId duplikat ($isarId)');
        }
      }
      collections[collection] = docs;
    }

    return IsarArchive(
      capturedAtUtc: _now().toUtc(),
      sourceLabel: _source.sourceLabel,
      databaseName: _source.databaseName,
      collections: collections,
    );
  }
}
