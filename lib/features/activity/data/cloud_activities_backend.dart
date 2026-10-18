import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu dokumen cloud + metadata local-queue Firestore.
///
/// [hasPendingWrites] adalah satu-satunya sinyal "local queue" yang
/// dipisahkan dari ack server oleh FlutterFire:
/// - `true`  = perubahan sudah masuk cache lokal SDK (antrean tulis) tetapi
///   BELUM dikonfirmasi server;
/// - `false` = dokumen mencerminkan state yang sudah dikonfirmasi server.
/// SDK tidak menyediakan Future terpisah untuk "queued lokal" (lihat
/// README §13.6) — metadata inilah yang dipakai status pending UI.
class CloudActivityDoc {
  const CloudActivityDoc({
    required this.id,
    required this.data,
    required this.hasPendingWrites,
  });

  final String id;
  final Map<String, dynamic> data;
  final bool hasPendingWrites;
}

/// Akses dokumen cloud activities (skema v2) — seam tipis antara
/// `CloudFirstActivityRepository` dan Firestore.
///
/// Alasan seam (S1): `cloud_firestore` tidak bisa dijalankan headless di
/// mesin dev (platform: android/ios/macos/web), sehingga operasi Firestore
/// dibungkus di sini agar repository + mirror Isar bisa dites unit dengan
/// backend fake — tanpa mengubah perilaku produksi.
abstract class CloudActivitiesBackend {
  /// Merge-set dokumen di `/users/{uid}/activities/{docId}`
  /// (create dan update lewat jalur yang sama).
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data);

  /// Semua dokumen visible (`deleted == false`), mentah; nonaktif
  /// disentuh hanya oleh repository (defense filtering).
  Future<List<Map<String, dynamic>>> queryVisible(String uid);

  /// Stream dokumen visible (`deleted == false`) + metadata pending
  /// (`hasPendingWrites`) untuk status tulis per-activity.
  Stream<List<CloudActivityDoc>> watchVisible(String uid);

  /// Dokumen mentah, atau null bila tidak ada / tidak terbaca.
  Future<Map<String, dynamic>?> getDoc(String uid, String docId);
}

/// Implementasi produksi di atas `FirebaseFirestore`.
class FirestoreCloudActivitiesBackend implements CloudActivitiesBackend {
  FirestoreCloudActivitiesBackend(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('activities');

  @override
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data) {
    return _col(uid).doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(
      uid,
    ).where('deleted', isEqualTo: false).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
        .toList();
  }

  @override
  Stream<List<CloudActivityDoc>> watchVisible(String uid) {
    // includeMetadataChanges WAJIB: transisi pending→acked (perubahan
    // metadata saja) TIDAK memicu snapshot secara default — tanpa ini
    // badge pending menempel selamanya (temuan uji device S2).
    return _col(uid)
        .where('deleted', isEqualTo: false)
        .snapshots(includeMetadataChanges: true)
        .map(
          (QuerySnapshot<Map<String, dynamic>> s) => s.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    CloudActivityDoc(
                      id: d.id,
                      data: d.data(),
                      hasPendingWrites: d.metadata.hasPendingWrites,
                    ),
              )
              .toList(),
        );
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col(
      uid,
    ).doc(docId).get();
    return doc.data();
  }
}
