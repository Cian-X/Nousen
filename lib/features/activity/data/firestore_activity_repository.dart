import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';

/// Implementasi cloud [ActivityRepository] di atas Firestore.
///
/// Path: `/users/{uid}/activities/{activityId}` (sesuai `firestore.rules`
/// owner-only). Kelas ini mentah: tanpa fallback, tanpa status.
/// Orkestrasi dual-write ada di [DualWriteActivityRepository].
/// Jangan dipakai langsung oleh UI.
class FirestoreActivityRepository implements ActivityRepository {
  FirestoreActivityRepository({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('activities');

  static Map<String, dynamic> toMap(ActivityModel a) {
    return <String, dynamic>{
      'id': a.id,
      'title': a.title,
      'family': a.family,
      'category': a.category,
      'tags': a.tags,
      'duration': a.duration,
      'isAnomali': a.isAnomali,
      'selectedDays': a.selectedDays,
      'subActivities': a.subActivities,
      'timeMinutes': a.timeMinutes,
      'weeklyGoal': a.weeklyGoal,
      'preReminderMinutes': a.preReminderMinutes,
      'isNotificationEnabled': a.isNotificationEnabled,
      'enableMorningReminder': a.enableMorningReminder,
      'enableEndOfDayReminder': a.enableEndOfDayReminder,
      'enablePhotoProgress': a.enablePhotoProgress,
      'lastThreeDayRuleNotifiedDate': a.lastThreeDayRuleNotifiedDate,
      'createdAt': a.createdAt.toIso8601String(),
      'updatedAt': a.updatedAt.toIso8601String(),
      'scheduleUpdatedAt': a.scheduleUpdatedAt?.toIso8601String(),
    };
  }

  static ActivityModel fromMap(Map<String, dynamic> m) {
    return ActivityModel(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      family: m['family'] as String? ?? 'general',
      category: m['category'] as String? ?? 'other',
      tags: (m['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      duration: (m['duration'] as num?)?.toInt() ?? 0,
      isAnomali: m['isAnomali'] as bool? ?? false,
      selectedDays: (m['selectedDays'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      subActivities: (m['subActivities'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      timeMinutes: (m['timeMinutes'] as num?)?.toInt() ?? 0,
      weeklyGoal: (m['weeklyGoal'] as num?)?.toInt() ?? 0,
      preReminderMinutes: (m['preReminderMinutes'] as num?)?.toInt() ?? 0,
      isNotificationEnabled: m['isNotificationEnabled'] as bool? ?? true,
      enableMorningReminder: m['enableMorningReminder'] as bool? ?? false,
      enableEndOfDayReminder: m['enableEndOfDayReminder'] as bool? ?? false,
      enablePhotoProgress: m['enablePhotoProgress'] as bool? ?? false,
      lastThreeDayRuleNotifiedDate:
          m['lastThreeDayRuleNotifiedDate'] as String?,
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scheduleUpdatedAt: m['scheduleUpdatedAt'] == null
          ? null
          : DateTime.tryParse(m['scheduleUpdatedAt'].toString()),
    );
  }

  @override
  Stream<List<ActivityModel>> watchAll() {
    return _col.snapshots().map((s) {
      final List<ActivityModel> list =
          s.docs.map((d) => fromMap(d.data())).toList();
      list.sort((a, b) => a.title.compareTo(b.title));
      return list;
    });
  }

  @override
  Future<List<ActivityModel>> getAll() async {
    final snap = await _col.get();
    final List<ActivityModel> list =
        snap.docs.map((d) => fromMap(d.data())).toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Future<ActivityModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return fromMap(doc.data()!);
  }

  @override
  Future<void> upsert(ActivityModel activity) async {
    try {
      await _col.doc(activity.id).set(toMap(activity), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[dualwrite-activity] cloud upsert gagal: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      debugPrint('[dualwrite-activity] cloud delete gagal: $e');
      rethrow;
    }
  }
}
