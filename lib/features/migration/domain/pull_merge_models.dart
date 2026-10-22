/// Koleksi yang ikut pull-merge (cloud → Isar) dry-run.
enum PullMergeCollection {
  settings('settings'),
  activities('activities'),
  reminders('reminders'),
  agendaNotes('agendaNotes'),
  progress('progress');

  const PullMergeCollection(this.key);

  /// Nama koleksi di Firestore (`users/{uid}/<key>`).
  final String key;
}

/// Aksi rencana pull-merge (belum diterapkan — dry-run).
enum PullMergeAction {
  /// Salin/ubah baris lokal dari dokumen cloud (cloud menang), sambil
  /// mempertahankan field media lokal.
  pullCloud,

  /// Baris hanya ada lokal (atau cloud tombstone) — jangan hapus.
  keepLocal,

  /// Cloud menandai `deleted: true`, tetapi baris lokal TETAP dipertahankan
  /// (kebijakan §9: tombstone tidak menghapus data lokal). Perlu review owner.
  keepLocalTombstone,

  /// Cloud lebih baru, tetapi jam device lokal tampak lebih baru dari
  /// `updatedAt` server di luar toleransi clock skew. Dry-run menandai untuk
  /// review; TIDAK memilih pemenang otomatis.
  conflictReview,
}

/// Dokumen cloud untuk planner (sudah dipetakan dari Firestore).
class CloudMergeDoc {
  CloudMergeDoc({
    required this.id,
    required Map<String, Object?> data,
    this.updatedAt,
    this.deleted = false,
    this.deletedAt,
  }) : data = Map<String, Object?>.unmodifiable(
         Map<String, Object?>.from(data),
       );

  final String id;
  final Map<String, Object?> data;

  /// `updatedAt` server (LWW acuan), null bila dokumen lama tidak punya.
  final DateTime? updatedAt;
  final bool deleted;
  final DateTime? deletedAt;
}

/// Baris lokal Isar untuk planner.
class LocalMergeRow {
  LocalMergeRow({
    required this.id,
    required Map<String, Object?> data,
    this.updatedAt,
  }) : data = Map<String, Object?>.unmodifiable(
         Map<String, Object?>.from(data),
       );

  final String id;
  final Map<String, Object?> data;

  /// Jam device (`clientUpdatedAt`); TIDAK sebanding langsung dengan jam
  /// server — hanya dipakai untuk deteksi anomali clock skew.
  final DateTime? updatedAt;
}

/// Satu baris rencana pull-merge.
class PullMergeEntry {
  PullMergeEntry({
    required this.collection,
    required this.id,
    required this.action,
    this.cloudUpdatedAt,
    this.localUpdatedAt,
    Map<String, Object?>? mergedData,
    Map<String, Object?> preservedLocalFields = const <String, Object?>{},
    this.cloudDeleted = false,
    this.localNewerThanCloud = false,
  }) : mergedData = mergedData == null
           ? null
           : Map<String, Object?>.unmodifiable(
               Map<String, Object?>.from(mergedData),
             ),
       preservedLocalFields = Map<String, Object?>.unmodifiable(
         Map<String, Object?>.from(preservedLocalFields),
       );

  final PullMergeCollection collection;
  final String id;
  final PullMergeAction action;
  final DateTime? cloudUpdatedAt;
  final DateTime? localUpdatedAt;

  /// Data hasil merge (cloud + field media lokal) untuk aksi
  /// [PullMergeAction.pullCloud] / [PullMergeAction.conflictReview].
  final Map<String, Object?>? mergedData;

  /// Field media lokal yang dipertahankan saat cloud menang.
  final Map<String, Object?> preservedLocalFields;
  final bool cloudDeleted;
  final bool localNewerThanCloud;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'collection': collection.key,
      'id': id,
      'action': action.name,
      'cloudUpdatedAt': cloudUpdatedAt?.toUtc().toIso8601String(),
      'localUpdatedAt': localUpdatedAt?.toUtc().toIso8601String(),
      'cloudDeleted': cloudDeleted,
      'localNewerThanCloud': localNewerThanCloud,
      'preservedLocalFields': preservedLocalFields,
      if (mergedData != null) 'mergedData': mergedData,
    };
  }
}

/// Rencana pull-merge (DRY-RUN: tidak ada tulis Isar/Firestore).
class PullMergePlan {
  PullMergePlan({
    required this.generatedAtUtc,
    required List<PullMergeEntry> entries,
    required List<String> reminderIdsToReschedule,
  }) : entries = List<PullMergeEntry>.unmodifiable(entries),
       reminderIdsToReschedule = List<String>.unmodifiable(
         reminderIdsToReschedule,
       );

  final DateTime generatedAtUtc;
  final List<PullMergeEntry> entries;

  /// Id reminder yang perlu dijadwalkan ulang setelah merge (deterministik,
  /// unik, urut). Rekonsiliasi notifikasi harus idempoten.
  final List<String> reminderIdsToReschedule;

  /// Selalu true pada S6.0 — planner tidak pernah menerapkan perubahan.
  bool get isDryRun => true;

  int countOf(PullMergeAction action) =>
      entries.where((PullMergeEntry entry) => entry.action == action).length;

  List<PullMergeEntry> get requiresReview => entries
      .where(
        (PullMergeEntry entry) =>
            entry.action == PullMergeAction.conflictReview ||
            entry.action == PullMergeAction.keepLocalTombstone,
      )
      .toList(growable: false);

  Map<String, int> get countByAction => <String, int>{
    for (final PullMergeAction action in PullMergeAction.values)
      action.name: countOf(action),
  };

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dryRun': isDryRun,
      'generatedAt': generatedAtUtc.toIso8601String(),
      'entries': entries
          .map((PullMergeEntry entry) => entry.toJson())
          .toList(growable: false),
      'reminderIdsToReschedule': reminderIdsToReschedule,
    };
  }
}
