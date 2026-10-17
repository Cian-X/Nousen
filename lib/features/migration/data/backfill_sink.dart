import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';

/// Tujuan tulis backfill (Firestore di produksi, fake in-memory di tes).
abstract class BackfillSink {
  /// UID Firebase tujuan; null = belum login → backfill harus batal.
  String? get uid;

  /// Tulis dokumen HANYA bila belum ada — satu langkah atomik
  /// (create-if-absent). `true` = dokumen baru dibuat; `false` = dokumen
  /// sudah ada dan TIDAK ditimpa.
  ///
  /// Kontrak atomicity (temuan QC S0): implementasi dilarang memakai pola
  /// cek-dulu-baru-tulis (`get` lalu `set` terpisah). Dua perangkat yang
  /// menjalankan backfill bersamaan harus tetap menghasilkan paling banyak
  /// satu penulis per dokumen. Implementasi Firestore memakai transaksi
  /// (baca + tulis satu transaksi, retry otomatis saat konflik); fake di
  /// tes memakai cek + sisip sinkron tanpa `await` di antaranya.
  Future<bool> createDoc(
    BackfillEntityKind kind,
    String docId,
    Map<String, Object?> data,
  );

  /// Nilai `updatedAt` server: `FieldValue.serverTimestamp()` di Firestore.
  Object serverTimestamp();
}
