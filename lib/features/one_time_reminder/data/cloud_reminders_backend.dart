import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu dokumen reminder cloud + metadata local-queue Firestore (S3).
///
/// [hasPendingWrites] adalah satu-satunya sinyal "local queue" yang
/// dipisahkan dari ack server oleh FlutterFire:
/// - `true`  = perubahan sudah masuk cache lokal SDK (antrean tulis) tetapi
///   BELUM dikonfirmasi server;
/// - `false` = dokumen mencerminkan state yang sudah dikonfirmasi server.
/// SDK tidak menyediakan Future terpisah untuk "queued lokal" (lihat
/// README §13.6) — metadata inilah yang dipakai status pending UI.
class CloudReminderDoc {
  const CloudReminderDoc({
    required this.id,
    required this.data,
    required this.hasPendingWrites,
  });

  final String id;
  final Map<String, dynamic> data;
  final bool hasPendingWrites;
}

/// Akses dokumen cloud reminders (skema v2) — seam tipis antara
/// `CloudFirstOneTimeReminderRepository` dan Firestore.
///
/// Path: `/users/{uid}/reminders/{reminderId}` (sesuai
/// `firestore.rules.draft` owner-only). Seam yang sama dengan S1b/S2 supaya
/// repository + mirror Isar bisa dites unit tanpa `cloud_firestore` headless.
abstract class CloudRemindersBackend {
  /// Merge-set dokumen di `/users/{uid}/reminders/{docId}`
  /// (create dan update lewat jalur yang sama).
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data);

  /// Dokumen hidup (`deleted != true`) + metadata pending
  /// (`hasPendingWrites`). Satu query kanonik per uid dipakai untuk baca
  /// (`watchAll`/`getAll`) dan status pending per-reminder.
  Stream<List<CloudReminderDoc>> watchVisible(String uid);

  /// Semua dokumen hidup, sekali baca (untuk `getAll`).
  Future<List<Map<String, dynamic>>> queryVisible(String uid);

  /// Dokumen mentah (termasuk tombstone), atau null bila tidak ada.
  Future<Map<String, dynamic>?> getDoc(String uid, String docId);
}

/// Implementasi produksi di atas `FirebaseFirestore`.
class FirestoreCloudRemindersBackend implements CloudRemindersBackend {
  FirestoreCloudRemindersBackend(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('reminders');

  @override
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data) {
    return _col(uid).doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<CloudReminderDoc>> watchVisible(String uid) {
    // includeMetadataChanges WAJIB: transisi pending→acked (perubahan
    // metadata saja) TIDAK memicu snapshot secara default — tanpa ini badge
    // pending menempel selamanya (temuan uji device S2).
    return _col(uid)
        .where('deleted', isEqualTo: false)
        .snapshots(includeMetadataChanges: true)
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    CloudReminderDoc(
                      id: doc.id,
                      data: doc.data(),
                      hasPendingWrites: doc.metadata.hasPendingWrites,
                    ),
              )
              .toList(),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> queryVisible(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _col(
      uid,
    ).where('deleted', isEqualTo: false).get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data())
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid, String docId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _col(
      uid,
    ).doc(docId).get();
    return snapshot.exists ? snapshot.data() : null;
  }
}
