import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Akses dokumen cloud progress (skema v1 — sama dengan dual-write) — seam
/// tipis antara `CloudFirstProgressRepository` dan Firestore.
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
/// Catatan skema: dokumen progress TIDAK memakai field `deleted`/tombstone
/// (skema v1 yang sudah dipakai dual-write); `deleteByActivity` = query per
/// activityId lalu batch hard delete, sama seperti
/// `FirestoreProgressRepository`.
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

  /// Hapus semua dokumen progress milik [activityId] (batch, hard delete).
  Future<void> deleteByActivity(String uid, String activityId);
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
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid)
        .where('activityId', isEqualTo: activityId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    return snap.docs.first.data();
  }

  @override
  Future<void> deleteByActivity(String uid, String activityId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid)
        .where('activityId', isEqualTo: activityId)
        .get();
    final WriteBatch batch = _firestore.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
