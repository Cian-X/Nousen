import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';

/// Implementasi cloud [ProgressRepository] di atas Firestore.
///
/// Path: `/users/{uid}/progress/{entryId}` (sesuai `firestore.rules`
/// owner-only). Path foto lokal (`photoPaths`, `photoPath`) TIDAK diunggah
/// karena menunjuk file perangkat; metadata lain ikut penuh.
///
/// Kelas ini mentah: tanpa fallback, tanpa status. Orkestrasi dual-write
/// (Isar primer + best-effort cloud) ada di
/// [DualWriteProgressRepository]. Jangan dipakai langsung oleh UI.
class FirestoreProgressRepository implements ProgressRepository {
  FirestoreProgressRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('progress');

  static Map<String, dynamic> toMap(ProgressEntryModel e) {
    return <String, dynamic>{
      'id': e.id,
      'activityId': e.activityId,
      'dateKey': e.dateKey,
      'status': e.statusKey,
      'subCompleted': e.subCompleted,
      'subTotal': e.subTotal,
      'completedSubActivities': e.completedSubActivities,
      'photoNote': e.photoNote,
      'notes': e.notes,
      'completionTime': e.effectiveCompletionTime?.toIso8601String(),
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
    };
  }

  static ProgressEntryModel fromMap(Map<String, dynamic> m) {
    return ProgressEntryModel(
      id: m['id'] as String,
      activityId: m['activityId'] as String,
      dateKey: m['dateKey'] as String,
      status: activityDayStatusFromStorage(m['status'] as String?),
      subCompleted: (m['subCompleted'] as num?)?.toInt() ?? 0,
      subTotal: (m['subTotal'] as num?)?.toInt() ?? 0,
      completedSubActivities:
          (m['completedSubActivities'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      photoPaths: const <String>[],
      photoPath: null,
      photoNote: m['photoNote'] as String?,
      notes: m['notes'] as String?,
      completionTime: m['completionTime'] == null
          ? null
          : DateTime.tryParse(m['completionTime'].toString()),
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  List<ProgressEntryModel> _sorted(Iterable<Map<String, dynamic>> docs) {
    final List<ProgressEntryModel> models =
        docs.map(fromMap).toList();
    models.sort(
      (a, b) => b.dateKey.compareTo(a.dateKey),
    );
    return models;
  }

  @override
  Stream<List<ProgressEntryModel>> watchAll() {
    return _col.snapshots().map((s) => _sorted(s.docs.map((d) => d.data())));
  }

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) {
    return _col
        .where('activityId', isEqualTo: activityId)
        .snapshots()
        .map((s) => _sorted(s.docs.map((d) => d.data())));
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) {
    return _col
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map((s) => _sorted(s.docs.map((d) => d.data())));
  }

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) {
    return _col
        .where('dateKey', isGreaterThanOrEqualTo: fromDateKey)
        .where('dateKey', isLessThanOrEqualTo: toDateKey)
        .snapshots()
        .map((s) => _sorted(s.docs.map((d) => d.data())));
  }

  @override
  Future<List<ProgressEntryModel>> getAll() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col.get();
    return _sorted(snap.docs.map((d) => d.data()));
  }

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('activityId', isEqualTo: activityId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    return fromMap(snap.docs.first.data());
  }

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    final Map<String, dynamic> data = toMap(entry);
    debugPrint('[firestore] upsert doc=${entry.id} path=${_col.path}/${entry.id} '
        'payload=$data');
    try {
      await _col.doc(entry.id).set(data, SetOptions(merge: true));
      debugPrint('[firestore] upsert OK doc=${entry.id}');
    } catch (e) {
      debugPrint('[firestore] upsert FAIL doc=${entry.id}: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _col
          .where('activityId', isEqualTo: activityId)
          .get();
      final WriteBatch batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[dualwrite] cloud delete gagal: $e');
      rethrow;
    }
  }
}
