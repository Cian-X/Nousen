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

  // ---- Restore: cloud → lokal (setelah login) ----

  /// Tarik semua progress dari Firestore dan tulis ke Isar lokal.
  /// Entry yang sudah ada di lokal (sama id) di-skip, bukan ditimpa,
  /// agar data lokal yang mungkin lebih baru tidak hilang.
  /// Mengembalikan jumlah entry yang di-restore.
  Future<int> restoreFromCloud() async {
    final String? uid = _authState.currentUid;
    final ProgressRepository? cloud = _cloudFor(uid);
    if (cloud == null) {
      debugPrint('[restore] skip: tidak ada sesi cloud');
      return 0;
    }

    debugPrint('[restore] mulai tarik data dari Firestore uid=$uid');
    final List<ProgressEntryModel> cloudEntries = await cloud.getAll();
    debugPrint('[restore] cloud punya ${cloudEntries.length} entry');

    if (cloudEntries.isEmpty) {
      return 0;
    }

    // Ambil semua id lokal untuk de-duplikasi.
    final List<ProgressEntryModel> localEntries = await _local.getAll();
    final Set<String> localIds =
        localEntries.map((e) => e.id).toSet();

    int restored = 0;
    for (final ProgressEntryModel entry in cloudEntries) {
      if (localIds.contains(entry.id)) {
        continue;
      }
      try {
        await _local.upsert(entry);
        restored++;
      } catch (e) {
        debugPrint('[restore] gagal upsert lokal ${entry.id}: $e');
      }
    }

    debugPrint('[restore] selesai: $restored entry baru ditulis ke lokal');
    return restored;
  }

  /// Push semua progress lokal ke Firestore yang belum ada di cloud.
  /// Dipanggil sekali saat pertama kali login agar data lama
  /// yang sudah ada di Isar ter-sync ke cloud.
  Future<int> syncUpExisting() async {
    final String? uid = _authState.currentUid;
    final ProgressRepository? cloud = _cloudFor(uid);
    if (cloud == null) {
      debugPrint('[syncup-progress] skip: tidak ada sesi cloud');
      return 0;
    }

    final List<ProgressEntryModel> localEntries = await _local.getAll();
    if (localEntries.isEmpty) return 0;

    final List<ProgressEntryModel> cloudEntries = await cloud.getAll();
    final Set<String> cloudIds = cloudEntries.map((e) => e.id).toSet();

    int pushed = 0;
    for (final ProgressEntryModel entry in localEntries) {
      if (cloudIds.contains(entry.id)) continue;
      try {
        await cloud.upsert(entry);
        pushed++;
      } catch (e) {
        debugPrint('[syncup-progress] gagal push ${entry.id}: $e');
      }
    }

    debugPrint('[syncup-progress] selesai: $pushed entry dipush ke cloud');
    return pushed;
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
