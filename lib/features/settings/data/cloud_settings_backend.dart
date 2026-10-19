import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu dokumen settings cloud + metadata local-queue Firestore (S3).
///
/// Settings adalah singleton `settings/app`, jadi [data] null berarti dokumen
/// belum ada (bukan "list kosong"). Lihat `CloudReminderDoc` untuk arti
/// [hasPendingWrites].
class CloudSettingsDoc {
  const CloudSettingsDoc({required this.data, required this.hasPendingWrites});

  final Map<String, dynamic> data;
  final bool hasPendingWrites;
}

/// Akses dokumen cloud settings (skema v2) — seam tipis antara
/// `CloudFirstSettingsRepository` dan Firestore.
///
/// Path tetap: `/users/{uid}/settings/app` (doc id `app`, sesuai
/// `firestore.rules.draft`). Field khusus perangkat (`profileAvatarPath`)
/// tidak pernah ditulis ke cloud — lihat README §15.
abstract class CloudSettingsBackend {
  /// Merge-set `settings/app`.
  Future<void> setDoc(String uid, Map<String, dynamic> data);

  /// Snapshot `settings/app` + metadata pending; `null` bila dokumen belum
  /// ada. `includeMetadataChanges` wajib agar transisi pending→acked
  /// memancarkan snapshot (badge pending tidak menempel).
  Stream<CloudSettingsDoc?> watchDoc(String uid);

  /// Baca sekali `settings/app`, atau null bila tidak ada.
  Future<Map<String, dynamic>?> getDoc(String uid);
}

/// Implementasi produksi di atas `FirebaseFirestore`.
class FirestoreCloudSettingsBackend implements CloudSettingsBackend {
  FirestoreCloudSettingsBackend(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('settings').doc('app');

  @override
  Future<void> setDoc(String uid, Map<String, dynamic> data) {
    return _doc(uid).set(data, SetOptions(merge: true));
  }

  @override
  Stream<CloudSettingsDoc?> watchDoc(String uid) {
    return _doc(uid).snapshots(includeMetadataChanges: true).map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return CloudSettingsDoc(
        data: data,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
    });
  }

  @override
  Future<Map<String, dynamic>?> getDoc(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _doc(
      uid,
    ).get();
    return snapshot.exists ? snapshot.data() : null;
  }
}
