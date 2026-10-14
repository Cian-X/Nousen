import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/activity/data/firestore_activity_repository.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Decorator dual-write [ActivityRepository] — pola identik dengan
/// [DualWriteProgressRepository]:
///
/// - BACA selalu dari Isar (sumber utama).
/// - TULIS: Isar dulu, lalu Firestore best-effort bila ada UID login.
class DualWriteActivityRepository implements ActivityRepository {
  DualWriteActivityRepository({
    required ActivityRepository local,
    required CloudAuthState authState,
    FirebaseFirestore? firestore,
    ActivityRepository Function(String uid)? cloudFactory,
  })  : _local = local,
        _authState = authState,
        _firestore = firestore,
        _cloudFactory = cloudFactory;

  final ActivityRepository _local;
  final CloudAuthState _authState;
  final FirebaseFirestore? _firestore;
  final ActivityRepository Function(String uid)? _cloudFactory;

  ActivityRepository? _cloudFor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    if (_cloudFactory != null) return _cloudFactory(uid);
    try {
      final fs = _firestore ?? FirebaseFirestore.instance;
      return FirestoreActivityRepository(firestore: fs, uid: uid);
    } catch (e) {
      debugPrint('[dualwrite-activity] firestore tak tersedia: $e');
      return null;
    }
  }

  // ---- Restore: cloud → lokal ----

  /// Tarik semua activity dari Firestore, tulis ke Isar lokal.
  /// Entry yang sudah ada (sama id) di-skip.
  Future<int> restoreFromCloud() async {
    final String? uid = _authState.currentUid;
    final ActivityRepository? cloud = _cloudFor(uid);
    if (cloud == null) {
      debugPrint('[restore-activity] skip: tidak ada sesi cloud');
      return 0;
    }

    debugPrint('[restore-activity] mulai tarik data uid=$uid');
    final List<ActivityModel> cloudEntries = await cloud.getAll();
    debugPrint('[restore-activity] cloud punya ${cloudEntries.length} activity');

    if (cloudEntries.isEmpty) return 0;

    final List<ActivityModel> localEntries = await _local.getAll();
    final Set<String> localIds = localEntries.map((e) => e.id).toSet();

    int restored = 0;
    for (final ActivityModel entry in cloudEntries) {
      if (localIds.contains(entry.id)) continue;
      try {
        await _local.upsert(entry);
        restored++;
      } catch (e) {
        debugPrint('[restore-activity] gagal upsert lokal ${entry.id}: $e');
      }
    }

    debugPrint('[restore-activity] selesai: $restored activity baru');
    return restored;
  }

  // ---- Sync up: lokal → cloud (initial push) ----

  /// Push semua activity lokal ke Firestore yang belum ada di cloud.
  /// Dipanggil sekali saat pertama kali dual-write activity aktif
  /// agar data lama yang sudah ada di Isar ter-sync ke cloud.
  Future<int> syncUpExisting() async {
    final String? uid = _authState.currentUid;
    final ActivityRepository? cloud = _cloudFor(uid);
    if (cloud == null) {
      debugPrint('[syncup-activity] skip: tidak ada sesi cloud');
      return 0;
    }

    final List<ActivityModel> localEntries = await _local.getAll();
    if (localEntries.isEmpty) return 0;

    final List<ActivityModel> cloudEntries = await cloud.getAll();
    final Set<String> cloudIds = cloudEntries.map((e) => e.id).toSet();

    int pushed = 0;
    for (final ActivityModel entry in localEntries) {
      if (cloudIds.contains(entry.id)) continue;
      try {
        await cloud.upsert(entry);
        pushed++;
      } catch (e) {
        debugPrint('[syncup-activity] gagal push ${entry.id}: $e');
      }
    }

    debugPrint('[syncup-activity] selesai: $pushed activity dipush ke cloud');
    return pushed;
  }

  // ---- Baca: selalu lokal ----

  @override
  Stream<List<ActivityModel>> watchAll() => _local.watchAll();

  @override
  Future<List<ActivityModel>> getAll() => _local.getAll();

  @override
  Future<ActivityModel?> getById(String id) => _local.getById(id);

  // ---- Tulis: lokal dulu, cloud best-effort ----

  @override
  Future<void> upsert(ActivityModel activity) async {
    await _local.upsert(activity);
    final cloud = _cloudFor(_authState.currentUid);
    if (cloud == null) return;
    try {
      await cloud.upsert(activity);
      debugPrint('[dualwrite-activity] cloud SYNCED ${activity.id}');
    } catch (e) {
      debugPrint('[dualwrite-activity] cloud FAIL ${activity.id}: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    final cloud = _cloudFor(_authState.currentUid);
    if (cloud == null) return;
    try {
      await cloud.delete(id);
      debugPrint('[dualwrite-activity] cloud DELETE $id');
    } catch (e) {
      debugPrint('[dualwrite-activity] cloud DELETE FAIL $id: $e');
    }
  }
}
