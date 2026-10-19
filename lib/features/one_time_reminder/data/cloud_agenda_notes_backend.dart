import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu dokumen catatan agenda cloud + metadata local-queue Firestore (S3).
///
/// Lihat `CloudReminderDoc` untuk arti [hasPendingWrites].
class CloudAgendaNoteDoc {
  const CloudAgendaNoteDoc({
    required this.id,
    required this.data,
    required this.hasPendingWrites,
  });

  final String id;
  final Map<String, dynamic> data;
  final bool hasPendingWrites;
}

/// Akses dokumen cloud agenda notes (skema v2) — seam tipis antara
/// `CloudFirstOneTimeReminderRepository` dan Firestore.
///
/// Path: `/users/{uid}/agendaNotes/{noteId}` (sesuai
/// `firestore.rules.draft` owner-only). `photoPaths` TIDAK pernah ditulis
/// ke cloud (path file perangkat) — lihat README §15.
abstract class CloudAgendaNotesBackend {
  /// Merge-set dokumen di `/users/{uid}/agendaNotes/{docId}`.
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data);

  /// Dokumen hidup (`deleted != true`) + metadata pending
  /// (`hasPendingWrites`). Satu query kanonik per uid; repository memfilter
  /// `reminderId` (pola yang sama dengan progress S2).
  Stream<List<CloudAgendaNoteDoc>> watchVisible(String uid);

  /// Semua dokumen hidup, sekali baca (untuk kelengkapan seam / tes).
  Future<List<Map<String, dynamic>>> queryVisible(String uid);

  /// Dokumen mentah (termasuk tombstone), atau null bila tidak ada.
  Future<Map<String, dynamic>?> getDoc(String uid, String docId);
}

/// Implementasi produksi di atas `FirebaseFirestore`.
class FirestoreCloudAgendaNotesBackend implements CloudAgendaNotesBackend {
  FirestoreCloudAgendaNotesBackend(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('agendaNotes');

  @override
  Future<void> setDoc(String uid, String docId, Map<String, dynamic> data) {
    return _col(uid).doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<CloudAgendaNoteDoc>> watchVisible(String uid) {
    return _col(uid)
        .where('deleted', isEqualTo: false)
        .snapshots(includeMetadataChanges: true)
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    CloudAgendaNoteDoc(
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
