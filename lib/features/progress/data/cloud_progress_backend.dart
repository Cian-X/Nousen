import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nousen/features/progress/data/firestore_progress_repository.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';

/// Satu dokumen progress cloud + metadata local-queue Firestore (S2).
///
/// [hasPendingWrites] adalah satu-satunya sinyal "local queue" yang
/// dipisahkan dari ack server oleh FlutterFire:
/// - `true`  = perubahan sudah masuk cache lokal SDK (antrean tulis) tetapi
///   BELUM dikonfirmasi server;
/// - `false` = dokumen mencerminkan state yang sudah dikonfirmasi server.
/// SDK tidak menyediakan Future terpisah untuk "queued lokal" (lihat
/// README §13.6) — metadata inilah yang dipakai status pending UI.
class CloudProgressDoc {
  const CloudProgressDoc({
    required this.id,
    required this.data,
    required this.hasPendingWrites,
  });

  final String id;
  final Map<String, dynamic> data;
  final bool hasPendingWrites;
}

/// Akses dokumen cloud progress (skema v2) — seam tipis antara
/// `CloudFirstProgressRepository` dan Firestore.
///
/// Path: `/users/{uid}/progress/{entryId}` (sesuai `firestore.rules`
/// owner-only).
///
/// Alasan seam (mengikuti `CloudActivitiesBackend` S1):
/// `cloud_firestore` tidak bisa dijalankan headless di mesin dev
/// (platform: android/ios/macos/web), sehingga operasi Firestore dibungkus
/// di sini agar repository + mirror Isar bisa dites unit dengan backend
/// fake — tanpa mengubah perilaku produksi.
///
/// Skema v2 (subset `backfill_mappers.progressBackfillMap`, README
/// dokumentasi progress v2):
/// - `updatedAt` = `FieldValue.serverTimestamp()` (LWW memakai jam server;
///   rules v2 `updatedAt == request.time`);
/// - `clientUpdatedAt` = jam device terakhir diff audit (ISO 8601);
/// - `deleted: false` + `deletedAt: null` saat hidup;
/// - hapus = TOMBSTONE (`deleted: true, deletedAt: serverTimestamp()`) —
///   hard delete tidak pernah dikirim (rules v2 `allow delete: false`).
///
/// Kompatibel baca terhadap dokumen v1 lama: field `deleted` yang TIDAK ADA
/// berarti hidup (lihat [isProgressDocAlive]) — tanpa migration/backfill.
abstract class CloudProgressBackend {
  /// Merge-set dokumen di `/users/{uid}/progress/{docId}`
  /// (create dan update lewat jalur yang sama).
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data);

  /// Semua dokumen progress + metadata pending (`hasPendingWrites`).
  ///
  /// Satu query kanonik per uid dipakai untuk: baca (watchAll/`getAll`),
  /// status pending per-entry, dan filter turunan di repository
  /// (byActivity/byDate/byDateRange) — mirror pola `watchVisible` S1.
  Stream<List<CloudProgressDoc>> watchAll(String uid);

  /// Semua dokumen progress, sekali baca (untuk `getAll`).
  Future<List<Map<String, dynamic>>> queryAll(String uid);

  /// Dokumen progress untuk (activityId, dateKey), atau null bila tidak ada.
  Future<Map<String, dynamic>?> getByActivityAndDate(
    String uid, {
    required String activityId,
    required String dateKey,
  });

  /// Hapus (tombstone) semua dokumen progress milik [activityId] — batch
  /// merge-set `{deleted: true, deletedAt: serverTimestamp(), updatedAt:
  /// serverTimestamp()}`, TANPA hard delete (rules v2 melarang delete).
  Future<void> deleteByActivity(String uid, String activityId);
}

/// Encode dokumen progress skema v2 dari model domain.
///
/// Dasar = `FirestoreProgressRepository.toMap` (field v1 tetap ikut agar
/// `fromMap` kompatibel & dokumen lawas dapat di-overwrite penuh), plus:
/// - `clientUpdatedAt` (audit jam device);
/// - `updatedAt` = server timestamp (bukan ISO string);
/// - `deleted: false`, `deletedAt: null`, `schemaVersion: 2`.
Map<String, dynamic> progressCloudDocMap(ProgressEntryModel e) {
  return <String, dynamic>{
    ...FirestoreProgressRepository.toMap(e),
    'clientUpdatedAt': e.updatedAt.toIso8601String(),
    'updatedAt': FieldValue.serverTimestamp(),
    'deleted': false,
    'deletedAt': null,
    'schemaVersion': 2,
  };
}

/// Map tombstone (hapus) untuk satu dokumen progress.
///
/// `updatedAt` + `deletedAt` = server timestamp (kontrak rules v2: setiap
/// update wajib `updatedAt == request.time`).
Map<String, dynamic> progressTombstoneMap() {
  return <String, dynamic>{
    'deleted': true,
    'deletedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Dokumen progress dianggap hidup bila tidak bertanda tombstone.
///
/// Field `deleted` TIDAK ADA (dokumen v1 lawas / hasil backfill tanpa
/// verifikasi) = hidup. Nilai pile `false` juga hidup; `true` = tombstone.
bool isProgressDocAlive(Map<String, dynamic> data) {
  return data['deleted'] != true;
}

/// Implementasi produksi di atas `FirebaseFirestore`.
class FirestoreCloudProgressBackend implements CloudProgressBackend {
  FirestoreCloudProgressBackend(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('progress');

  @override
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data) {
    return _col(uid).doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<CloudProgressDoc>> watchAll(String uid) {
    // includeMetadataChanges WAJIB: transisi pending→acked (perubahan
    // metadata saja) TIDAK memicu snapshot secara default — tanpa ini
    // badge pending menempel selamanya (temuan uji device S2).
    return _col(uid).snapshots(includeMetadataChanges: true).map(
          (QuerySnapshot<Map<String, dynamic>> s) => s.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    CloudProgressDoc(
                      id: d.id,
                      data: d.data(),
                      hasPendingWrites: d.metadata.hasPendingWrites,
                    ),
              )
              .toList(),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> queryAll(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getByActivityAndDate(
    String uid, {
    required String activityId,
    required String dateKey,
  }) async {
    // Tanpa limit: id entry bukan deterministik per (activityId, dateKey),
    // jadi pasangan yang sama bisa punya beberapa dokumen (mis. entry lama
    // ter-tombstone lalu dibuat ulang). Pilih dokumen PERTAMA yang hidup —
    // tombstone dibuang, bukan dibalikkan ke model.
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid)
        .where('activityId', isEqualTo: activityId)
        .where('dateKey', isEqualTo: dateKey)
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
      if (isProgressDocAlive(d.data())) {
        return d.data();
      }
    }
    return null;
  }

  @override
  Future<void> deleteByActivity(String uid, String activityId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid)
        .where('activityId', isEqualTo: activityId)
        .get();
    if (snap.docs.isEmpty) {
      return;
    }
    final Map<String, dynamic> tombstone = progressTombstoneMap();
    for (var start = 0; start < snap.docs.length; start += _batchChunk) {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> chunk =
          snap.docs.sublist(start, (start + _batchChunk).clamp(0, snap.docs.length));
      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in chunk) {
        // Tombstone via merge-set: field lain tetap ada di dokumen
        // (riwayat audit), dan rules v2 menerima update dengan
        // `updatedAt == request.time`. Hard delete DILARANG rules.
        batch.set(doc.reference, tombstone, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  /// Batas ukuran batch Firestore (500) dengan margin aman.
  static const int _batchChunk = 450;
}
