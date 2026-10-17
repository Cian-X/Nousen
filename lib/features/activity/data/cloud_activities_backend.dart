import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Stream dokumen visible (`deleted == false`).
  Stream<List<Map<String, dynamic>>> watchVisible(String uid);

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
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid)
        .where('deleted', isEqualTo: false)
        .get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
        .toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchVisible(String uid) {
    return _col(uid)
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> s) => s.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
              .toList(),
        );
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col(uid)
        .doc(docId)
        .get();
    return doc.data();
  }
}
