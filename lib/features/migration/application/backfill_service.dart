import 'package:nousen/features/migration/data/backfill_checkpoint_store.dart';
import 'package:nousen/features/migration/data/backfill_models.dart';
import 'package:nousen/features/migration/data/backfill_sink.dart';
import 'package:nousen/features/migration/data/backfill_local_source.dart';
import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';

/// Backfill Isar → Firestore (S0): idempoten, resumable, tidak menimpa
/// dokumen cloud yang sudah ada.
///
/// Sifat:
/// - **Idempoten & bebas race**: tiap baris ditulis lewat satu operasi
///   atomik [BackfillSink.createDoc] (create-if-absent); dokumen yang sudah
///   ada dilewati (dihitung `skippedExisting`), tidak pernah ditimpa. Dua
///   perangkat yang menjalankan backfill bersamaan aman — penulis kedua
///   otomatis kalah dan terhitung skip (temuan QC S0; lihat tes "dua device").
/// - **Full rescan tiap run**: TIDAK ada baris yang dilewati berdasarkan
///   `isarId` — setiap run memverifikasi SEMUA baris lokal via `createDoc`
///   (idempoten), sehingga baris baru yang muncul terlambat di bawah
///   kursor checkpoint lama tetap tertangkap (temuan QC ronde 2; trade-off
///   biaya di README §12 butir 4). Kursor `lastIsarId` + status `done`
///   tetap dipersist ke [BackfillCheckpointStore] (setiap [persistEvery]
///   baris dan di akhir tiap entitas) hanya sebagai informasi progres
///   kumulatif — bukan penentu skip.
/// - **Tanpa auth = batal**: uid null → run berhenti tanpa tulis apa pun.
/// - **Tidak dijalankan otomatis**: S0 hanya tooling; pemanggilan manual
///   (uji coba) di luar scope produksi.
class BackfillService {
  BackfillService({
    required BackfillSink sink,
    required BackfillLocalSource source,
    required BackfillCheckpointStore checkpoints,
    this.persistEvery = 50,
    this.log,
  }) : _sink = sink,
       _source = source,
       _checkpoints = checkpoints;

  final BackfillSink _sink;
  final BackfillLocalSource _source;
  final BackfillCheckpointStore _checkpoints;

  /// Frekuensi persist checkpoint (jumlah baris diproses antar-persist).
  final int persistEvery;

  /// Logger opsional untuk mencatat skip/konflik (S0: debugPrint).
  final void Function(String message)? log;

  static const int checkpointVersion = 1;

  Map<BackfillEntityKind, BackfillEntityReport> _reports =
      <BackfillEntityKind, BackfillEntityReport>{};

  /// Jalankan backfill sekali. Aman dipanggil ulang: idempoten, dan tiap
  /// run memverifikasi ulang SEMUA baris (full rescan).
  Future<BackfillReport> run() async {
    final String? uid = _sink.uid;
    if (uid == null || uid.trim().isEmpty) {
      _emit('[backfill] dibatalkan: belum login Firebase (uid null)');
      return BackfillReport.noAuth();
    }

    _restore(await _checkpoints.load(), uid);

    for (final BackfillEntityKind kind in BackfillEntityKind.values) {
      await _runKind(kind, uid);
    }

    return BackfillReport(
      uid: uid,
      entities: _reports.values.toList(growable: false),
    );
  }

  void _restore(Map<String, Object?>? raw, String uid) {
    _reports = <BackfillEntityKind, BackfillEntityReport>{
      for (final BackfillEntityKind kind in BackfillEntityKind.values)
        kind: BackfillEntityReport(kind: kind),
    };
    if (raw == null || raw['uid'] != uid) {
      // Checkpoint milik uid lain (atau rusak) → mulai dari nol.
      return;
    }
    final Map<String, Object?> entities =
        (raw['entities'] as Map?)?.cast<String, Object?>() ??
        const <String, Object?>{};
    for (final BackfillEntityKind kind in BackfillEntityKind.values) {
      final Map<String, Object?>? saved = (entities[kind.name] as Map?)
          ?.cast<String, Object?>();
      if (saved == null) {
        continue;
      }
      _reports[kind]!
        ..lastIsarId = (saved['lastIsarId'] as num?)?.toInt() ?? 0
        ..pushed = (saved['pushed'] as num?)?.toInt() ?? 0
        ..skippedExisting = (saved['skippedExisting'] as num?)?.toInt() ?? 0
        ..done = saved['done'] == true;
    }
  }

  Future<void> _runKind(BackfillEntityKind kind, String uid) async {
    final BackfillEntityReport report = _reports[kind]!;

    final List<BackfillLocalRow> rows = (await _source.readAll(kind)).toList()
      ..sort(
        (BackfillLocalRow a, BackfillLocalRow b) =>
            a.isarId.compareTo(b.isarId),
      );
    _emit(
      '[backfill] ${kind.name}: ${rows.length} baris lokal, '
      'full rescan (verifikasi create-if-absent untuk SEMUA baris)',
    );

    // Full rescan tiap run: TIDAK ada skip berbasis `isarId`. Setiap baris
    // diverifikasi lewat [BackfillSink.createDoc] yang atomik (idempoten),
    // jadi baris lama yang sudah ada di cloud terhitung `skippedExisting`,
    // sementara baris baru yang muncul terlambat — termasuk yang
    // ber-`isarId` DI BAWAH kursor checkpoint lama — tetap dibuat (temuan
    // QC ronde 2). Aman untuk crash (rerun = verifikasi ulang penuh),
    // isarId duplikat (dedup via `docId`), dan dokumen cloud yang sudah
    // ada (tidak pernah ditimpa).
    int sincePersist = 0;
    for (final BackfillLocalRow row in rows) {
      final bool created = await _sink.createDoc(
        kind,
        row.docId,
        row.buildData(_sink.serverTimestamp()),
      );
      if (created) {
        report.pushed++;
      } else {
        report.skippedExisting++;
        _emit(
          '[backfill] ${kind.name}: SKIP ${row.docId} '
          '(dokumen cloud sudah ada, tidak ditimpa)',
        );
      }

      // Kursor = isarId tertinggi yang terlihat (info progres kumulatif).
      if (row.isarId > report.lastIsarId) {
        report.lastIsarId = row.isarId;
      }
      sincePersist++;
      if (sincePersist >= persistEvery) {
        await _persist(uid);
        sincePersist = 0;
      }
    }

    report.done = true;
    await _persist(uid);
    _emit(
      '[backfill] ${kind.name}: selesai '
      '(pushed=${report.pushed}, skipExisting=${report.skippedExisting})',
    );
  }

  Future<void> _persist(String uid) async {
    await _checkpoints.save(<String, Object?>{
      'version': checkpointVersion,
      'uid': uid,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'entities': <String, Object?>{
        for (final BackfillEntityReport report in _reports.values)
          report.kind.name: <String, Object?>{
            'lastIsarId': report.lastIsarId,
            'pushed': report.pushed,
            'skippedExisting': report.skippedExisting,
            'done': report.done,
          },
      },
    });
  }

  void _emit(String message) {
    log?.call(message);
  }
}
