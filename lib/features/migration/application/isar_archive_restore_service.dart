import 'package:nousen/features/migration/data/isar_archive_source.dart';
import 'package:nousen/features/migration/data/isar_archive_target.dart';
import 'package:nousen/features/migration/domain/isar_archive.dart';

/// Hasil restore archive S6.0.
class IsarArchiveRestoreReport {
  IsarArchiveRestoreReport({
    required this.databaseName,
    required this.checksum,
    required Map<IsarArchiveCollection, int> counts,
  }) : counts = Map<IsarArchiveCollection, int>.unmodifiable(counts);

  final String databaseName;
  final String checksum;
  final Map<IsarArchiveCollection, int> counts;

  int get totalDocuments =>
      counts.values.fold(0, (int sum, int count) => sum + count);
}

/// Restore archive JSON ke target Isar scratch.
///
/// Urutan guard (S6.0):
/// 1. target wajib menyatakan dirinya scratch DAN nama database-nya berprefix
///    [kS6ScratchIsarNamePrefix]. Target produksi `reminder_schedule_v2`
///    ditolak sebelum satu pun koleksi dibaca/ditulis.
/// 2. JSON diparse + divalidasi ketat (schema v2, lima koleksi, `isarId`
///    unik, `counts`, `checksum` SHA-256) sebelum mutation.
/// 3. archive wajib berasal dari database scratch.
/// 4. target wajib kosong. Restore TIDAK menimpa/menghapus data; restore
///    ulang ke target yang sudah terisi ditolak (explicitly safe repeat).
/// 5. penulisan kelima koleksi dilakukan oleh [IsarArchiveTarget.writeAll]
///    dalam satu transaksi; kegagalan satu dokumen = rollback total.
/// 6. jumlah dokumen target diverifikasi ulang setelah commit.
///
/// Tidak ada pembacaan Firestore, file archive, atau database produksi.
class IsarArchiveRestoreService {
  const IsarArchiveRestoreService();

  Future<IsarArchiveRestoreReport> restoreJson(
    String encoded, {
    required IsarArchiveTarget target,
  }) async {
    if (!target.isScratch) {
      throw StateError(
        'restore S6.0 hanya ke target scratch '
        '(target "${target.databaseName}" bukan scratch)',
      );
    }
    try {
      validateS6ScratchDatabaseName(target.databaseName);
    } on ArgumentError {
      throw StateError(
        'restore S6.0 hanya ke DB berprefix '
        '"$kS6ScratchIsarNamePrefix" '
        '(target "${target.databaseName}" ditolak)',
      );
    }

    final IsarArchive archive = IsarArchive.decode(encoded);
    try {
      validateS6ScratchDatabaseName(archive.databaseName);
    } on ArgumentError {
      throw FormatException(
        'archive berasal dari DB non-scratch: ${archive.databaseName}',
      );
    }

    final Map<IsarArchiveCollection, int> before = await target
        .countDocuments();
    final int existing = before.values.fold(
      0,
      (int sum, int count) => sum + count,
    );
    if (existing != 0) {
      throw StateError(
        'target "${target.databaseName}" tidak kosong ($existing dokumen); '
        'restore hanya ke DB scratch baru',
      );
    }

    await target.writeAll(archive);

    final Map<IsarArchiveCollection, int> after = await target.countDocuments();
    if (!_countsMatch(after, archive)) {
      throw StateError(
        'jumlah dokumen setelah restore tidak cocok dengan archive '
        '(target: $after, archive: ${archive.counts})',
      );
    }

    return IsarArchiveRestoreReport(
      databaseName: target.databaseName,
      checksum: archive.checksum,
      counts: after,
    );
  }
}

bool _countsMatch(Map<IsarArchiveCollection, int> actual, IsarArchive archive) {
  if (actual.length != IsarArchiveCollection.values.length) {
    return false;
  }
  for (final IsarArchiveCollection collection in IsarArchiveCollection.values) {
    if (actual[collection] != archive.countOf(collection)) {
      return false;
    }
  }
  return true;
}
