import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/progress/data/firestore_progress_repository.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Hasil tulis cloud pada operasi dual-write terakhir.
enum CloudWriteStatus {
  /// Cloud dilewati: logout atau Firebase tak tersedia. Bukan error.
  skippedOffline,

  /// Tertulis ke Isar dan Firestore.
  synced,

  /// Tertulis ke Isar, GAGAL ke Firestore. Data lokal aman;
  /// [CloudSyncState.message] menjelaskan penyebab untuk ditindaklanjuti.
  /// BUKAN klaim sukses sinkron.
  failed,
}

/// Status sinkron cloud terakhir yang dapat diobservasi UI/diagostik.
class CloudSyncState {
  const CloudSyncState({
    required this.status,
    this.message,
    required this.at,
  });

  final CloudWriteStatus status;
  final String? message;
  final DateTime at;
}

/// Decorator dual-write [ProgressRepository] untuk pilot progres/checklist.
///
/// - BACA selalu dari Isar (sumber utama; UI dan mode lokal tidak berubah).
/// - TULIS: Isar dulu (gagal = lempar seperti semula), lalu Firestore
///   best-effort bila ada UID login. Tidak ada transaksi atomik lintas
///   Isar–Firestore; kegagalan cloud tidak pernah merusak data lokal dan
///   dilaporkan jujur via [syncState].
class DualWriteProgressRepository implements ProgressRepository {
  DualWriteProgressRepository({
    required ProgressRepository local,
    required CloudAuthState authState,
    FirebaseFirestore? firestore,
    ProgressRepository Function(String uid)? cloudFactory,
  })  : _local = local,
        _authState = authState,
        _firestore = firestore,
        _cloudFactory = cloudFactory;

  final ProgressRepository _local;
  final CloudAuthState _authState;

  /// Firestore di-inject agar dapat difake di tes. Null = pakai instance
  /// default saat dibutuhkan (dan hanya bila login).
  final FirebaseFirestore? _firestore;

  /// Pabrik cloud alternatif (dipakai tes dengan fake cloud yang
  /// mengimplementasikan [ProgressRepository]).
  final ProgressRepository Function(String uid)? _cloudFactory;

  final ValueNotifier<CloudSyncState> syncState =
      ValueNotifier<CloudSyncState>(
    CloudSyncState(status: CloudWriteStatus.skippedOffline, at: DateTime.now()),
  );

  void _record(CloudWriteStatus status, [String? message]) {
    syncState.value = CloudSyncState(
      status: status,
      message: message,
      at: DateTime.now(),
    );
  }

  ProgressRepository? _cloudFor(String? uid) {
    if (uid == null || uid.isEmpty) {
      return null;
    }
    if (_cloudFactory != null) {
      return _cloudFactory(uid);
    }
    try {
      final FirebaseFirestore fs = _firestore ?? FirebaseFirestore.instance;
      return FirestoreProgressRepository(firestore: fs, uid: uid);
    } catch (e) {
      debugPrint('[dualwrite] firestore tak tersedia: $e');
      return null;
    }
  }

  // ---- Baca: selalu lokal ----

  @override
  Stream<List<ProgressEntryModel>> watchAll() => _local.watchAll();

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) =>
      _local.watchByActivity(activityId);

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) =>
      _local.watchByDate(dateKey);

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) =>
      _local.watchByDateRange(
        fromDateKey: fromDateKey,
        toDateKey: toDateKey,
      );

  @override
  Future<List<ProgressEntryModel>> getAll() => _local.getAll();

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) =>
      _local.getByActivityAndDate(
        activityId: activityId,
        dateKey: dateKey,
      );

  // ---- Tulis: lokal dulu, cloud best-effort ----

  @override
  Future<void> upsert(ProgressEntryModel entry) async {
    await _local.upsert(entry);
    final ProgressRepository? cloud =
        _cloudFor(_authState.currentUid);
    if (cloud == null) {
      _record(CloudWriteStatus.skippedOffline, 'tanpa login/cloud');
      return;
    }
    try {
      await cloud.upsert(entry);
      _record(CloudWriteStatus.synced);
    } catch (e) {
      _record(CloudWriteStatus.failed, e.toString());
    }
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    await _local.deleteByActivity(activityId);
    final ProgressRepository? cloud =
        _cloudFor(_authState.currentUid);
    if (cloud == null) {
      _record(CloudWriteStatus.skippedOffline, 'tanpa login/cloud');
      return;
    }
    try {
      await cloud.deleteByActivity(activityId);
      _record(CloudWriteStatus.synced);
    } catch (e) {
      _record(CloudWriteStatus.failed, e.toString());
    }
  }
}
