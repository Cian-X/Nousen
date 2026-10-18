import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nousen/features/migration/data/backfill_sink.dart';
import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';

/// Sink backfill ke Firestore: `users/{uid}/{collection}/{docId}`.
///
/// S0: hanya perangkat/di jalan ketika uji coba — TIDAK dipanggil otomatis
/// oleh alur produksi mana pun.
class FirestoreBackfillSink implements BackfillSink {
  FirestoreBackfillSink({
    required FirebaseFirestore firestore,
    required this.uid,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  final String? uid;

  DocumentReference<Map<String, dynamic>> _ref(
    BackfillEntityKind kind,
    String docId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection(kind.collection)
        .doc(docId);
  }

  @override
  Future<bool> createDoc(
    BackfillEntityKind kind,
    String docId,
    Map<String, Object?> data,
  ) {
    final DocumentReference<Map<String, dynamic>> ref = _ref(kind, docId);
    // cloud_firestore (Dart) tidak menyediakan `DocumentReference.create()`
    // (itu admin SDK). Transaksi memberi semantik yang sama: baca + tulis
    // dalam satu transaksi; saat dua perangkat menulis bersamaan, Firestore
    // me-retry transaksi yang kalah sehingga hasilnya deterministik —
    // dokumen hanya dibuat sekali, tidak pernah ditimpa setelah ada.
    return _firestore.runTransaction<bool>((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      if (snap.exists) {
        return false;
      }
      tx.set(ref, Map<String, dynamic>.from(data));
      return true;
    });
  }

  @override
  Object serverTimestamp() => FieldValue.serverTimestamp();
}
