import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/activity/data/cloud_activities_backend.dart';
import 'package:nousen/features/activity/data/firestore_activity_repository.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Repository aktivitas cloud-first (S0 kerangka → S1 mirror Isar).
///
/// Path: `/users/{uid}/activities/{activityId}` dengan skema v2:
/// - `updatedAt` = server timestamp (LWW oleh jam server, bukan jam device);
/// - hapus = tombstone `{deleted: true, deletedAt: serverTimestamp()}`,
///   tidak pernah hard delete;
/// - `clientUpdatedAt` menyimpan jam device untuk audit.
///
/// Semantik baca/tulis (S1):
/// - BACA selalu dari Firestore (authoritative, cloud-first).
/// - TULIS: Firestore dulu (di-await; error di-rethrow), baru mirror [Isar]
///   best-effort — mirror ada supaya rollback (flag OFF → jalur Isar/
///   dual-write) tetap melihat data terbaru. Mirror gagal hanya di-log,
///   tidak menggagalkan operasi yang sudah tersimpan di cloud.
/// - Mirror TIDAK pernah dipakai untuk baca dan tidak di-refresh oleh baca.
/// - Offline: SDK Firestore (persistence Android default aktif) mengantre
///   tulis ke cache lokal dan resolve; mirror mengikuti setelah resolve,
///   sinkron ke server saat reconnect — verifikasi offline nyata tetap
///   manual di device (README §13).
///
/// Catatan:
/// - Hanya dipakai bila `MigrationFlags.cloudFirstActivities` aktif; default
///   produksi tetap `DualWriteActivityRepository` (Isar primer).
/// - Query memfilter `deleted == false`; dokumen lama yang belum pernah
///   ditulis dengan field `deleted` harus di-backfill dulu sebelum flag
///   dinyalakan (lihat `BackfillService`).
/// - Tanpa login Firebase repository ini melempar [StateError] (jalur
///   cloud-first mensyaratkan auth produksi) — belum ada fallback senyap.
class CloudFirstActivityRepository implements ActivityRepository {
  CloudFirstActivityRepository({
    required CloudActivitiesBackend backend,
    required CloudAuthState authState,
    ActivityRepository? mirror,
  }) : _backend = backend,
       _authState = authState,
       _mirror = mirror;

  final CloudActivitiesBackend _backend;
  final CloudAuthState _authState;

  /// Mirror lokal (Isar) untuk jalur rollback; null = tanpa mirror.
  final ActivityRepository? _mirror;

  /// Versi skema dokumen cloud (S0/S1: v2 — tombstone + server timestamp).
  static const int schemaVersion = 2;

  String get _uid {
    final String? uid = _authState.currentUid;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'CloudFirstActivityRepository butuh login Firebase (uid null).',
      );
    }
    return uid;
  }

  /// Map tulis skema v2 dari model domain (dipakai upsert/tombstone).
  static Map<String, dynamic> toMap(
    ActivityModel activity, {
    required bool deleted,
  }) {
    return <String, dynamic>{
      ...FirestoreActivityRepository.toMap(activity),
      'clientUpdatedAt': activity.updatedAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': deleted,
      'deletedAt': deleted ? FieldValue.serverTimestamp() : null,
      'schemaVersion': schemaVersion,
    };
  }

  /// Map tombstone (delete = update, bukan hard delete).
  static Map<String, dynamic> tombstoneMap() {
    return <String, dynamic>{
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': schemaVersion,
    };
  }

  /// Baca aman: konversi nilai `Timestamp` server ke ISO-8601 string agar
  /// bisa diparse [FirestoreActivityRepository.fromMap].
  static ActivityModel fromFirestoreMap(Map<String, dynamic> m) {
    final Map<String, dynamic> normalized = <String, dynamic>{};
    m.forEach((String key, Object? value) {
      normalized[key] = value is Timestamp
          ? value.toDate().toIso8601String()
          : value;
    });
    return FirestoreActivityRepository.fromMap(normalized);
  }

  List<ActivityModel> _visible(Iterable<Map<String, dynamic>> docs) {
    final List<ActivityModel> list = <ActivityModel>[];
    for (final Map<String, dynamic> doc in docs) {
      if (doc['deleted'] == true) {
        continue;
      }
      list.add(fromFirestoreMap(doc));
    }
    list.sort((ActivityModel a, ActivityModel b) => a.title.compareTo(b.title));
    return list;
  }

  // ---- Baca: selalu cloud ----

  @override
  Stream<List<ActivityModel>> watchAll() {
    return _backend.watchVisible(_uid).map(_visible);
  }

  @override
  Future<List<ActivityModel>> getAll() async {
    final List<Map<String, dynamic>> docs = await _backend.queryVisible(_uid);
    return _visible(docs);
  }

  @override
  Future<ActivityModel?> getById(String id) async {
    final Map<String, dynamic>? data = await _backend.getDoc(_uid, id);
    if (data == null || data['deleted'] == true) {
      return null;
    }
    return fromFirestoreMap(data);
  }

  // ---- Tulis: cloud dulu (authoritative), mirror best-effort ----

  @override
  Future<void> upsert(ActivityModel activity) async {
    try {
      await _backend.setDoc(_uid, activity.id, toMap(activity, deleted: false));
    } catch (e) {
      debugPrint('[cloudfirst-activity] upsert gagal: $e');
      rethrow;
    }
    await _mirrorUpsert(activity);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _backend.setDoc(_uid, id, tombstoneMap());
    } catch (e) {
      debugPrint('[cloudfirst-activity] tombstone gagal: $e');
      rethrow;
    }
    await _mirrorDelete(id);
  }

  Future<void> _mirrorUpsert(ActivityModel activity) async {
    final ActivityRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.upsert(activity);
      debugPrint('[cloudfirst-activity] mirror Isar SYNCED ${activity.id}');
    } catch (e) {
      debugPrint(
        '[cloudfirst-activity] mirror Isar FAIL upsert ${activity.id}: $e',
      );
    }
  }

  Future<void> _mirrorDelete(String id) async {
    final ActivityRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.delete(id);
      debugPrint('[cloudfirst-activity] mirror Isar DELETE $id');
    } catch (e) {
      debugPrint('[cloudfirst-activity] mirror Isar FAIL delete $id: $e');
    }
  }
}
