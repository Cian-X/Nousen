import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';

/// Satu baris lokal (Isar) siap dikonversi ke dokumen Firestore.
class BackfillLocalRow {
  const BackfillLocalRow({
    required this.isarId,
    required this.docId,
    required this.buildData,
  });

  /// Primary key Isar — dipakai untuk urutan proses (urut menaik); BUKAN
  /// penentu skip — setiap run backfill memverifikasi ulang semua baris.
  final int isarId;

  /// Doc id di Firestore. Untuk `settings` selalu `app`
  /// ([BackfillEntityKind.fixedDocId]); entitas lain memakai id entitas.
  final String docId;

  /// Builder map dokumen; `serverTs` = nilai waktu server dari sink
  /// (`FieldValue.serverTimestamp()` di produksi, sentinel di tes).
  final Map<String, Object?> Function(Object serverTs) buildData;
}

/// Statistik per entitas selama satu run backfill.
class BackfillEntityReport {
  BackfillEntityReport({required this.kind});

  final BackfillEntityKind kind;

  /// Jumlah dokumen baru yang ditulis.
  int pushed = 0;

  /// Jumlah dokumen dilewati karena sudah ada di cloud (tidak ditimpa).
  int skippedExisting = 0;

  /// isarId tertinggi yang terlihat pada pass terakhir (info progres
  /// kumulatif; bukan penentu skip — tiap run full rescan).
  int lastIsarId = 0;

  /// True bila pass terakhir entitas ini selesai tanpa error (info saja;
  /// bukan penentu skip — tiap run full rescan).
  bool done = false;
}

/// Hasil satu run [BackfillService].
class BackfillReport {
  BackfillReport({required this.uid, required this.entities});

  /// Run batal karena belum login (uid null): tidak ada tulis apa pun.
  factory BackfillReport.noAuth() =>
      BackfillReport(uid: null, entities: const <BackfillEntityReport>[]);

  final String? uid;
  final List<BackfillEntityReport> entities;

  bool get abortedNoAuth => uid == null;

  int get totalPushed =>
      entities.fold(0, (int sum, BackfillEntityReport e) => sum + e.pushed);

  int get totalSkippedExisting => entities.fold(
    0,
    (int sum, BackfillEntityReport e) => sum + e.skippedExisting,
  );

  bool get allDone =>
      entities.isNotEmpty && entities.every((BackfillEntityReport e) => e.done);
}
