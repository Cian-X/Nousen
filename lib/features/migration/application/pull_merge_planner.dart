import 'package:nousen/features/migration/domain/pull_merge_models.dart';

/// Planner pull-merge cloud → Isar (DRY-RUN).
///
/// Kebijakan (mengikuti keputusan README migrasi §9):
/// - cloud live + lokal tidak ada → `pullCloud` (buat).
/// - cloud live + lokal ada → `pullCloud` (cloud menang), tetapi field media
///   lokal dipertahankan (`photoPaths`/`photoPath` progress, `photoPaths`
///   catatan agenda, `profileAvatarPath` settings).
/// - cloud tombstone (`deleted: true`) + lokal ada → `keepLocalTombstone`;
///   data lokal TIDAK dihapus.
/// - hanya lokal → `keepLocal`.
/// - lokal tampak lebih baru dari `updatedAt` server di luar
///   [clockSkewTolerance] → `conflictReview` (tidak memilih pemenang).
///
/// Planner ini tidak menulis apa pun: outputnya hanya [PullMergePlan]
/// (JSON-serializable) untuk direview sebelum apply (apply di luar S6.0).
class PullMergePlanner {
  PullMergePlanner({
    this.clockSkewTolerance = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Toleransi selisih jam device vs server sebelum dianggap konflik.
  final Duration clockSkewTolerance;

  final DateTime Function() _now;

  /// Field media yang tidak pernah dihapus oleh merge cloud → Isar.
  static const Map<PullMergeCollection, List<String>> preservedFields =
      <PullMergeCollection, List<String>>{
        PullMergeCollection.settings: <String>['profileAvatarPath'],
        PullMergeCollection.agendaNotes: <String>['photoPaths'],
        PullMergeCollection.progress: <String>['photoPaths', 'photoPath'],
      };

  PullMergePlan plan({
    required Map<PullMergeCollection, List<CloudMergeDoc>> cloud,
    required Map<PullMergeCollection, List<LocalMergeRow>> local,
  }) {
    final List<PullMergeEntry> entries = <PullMergeEntry>[];
    final Map<String, Map<String, Object?>> mergedReminderData =
        <String, Map<String, Object?>>{};

    for (final PullMergeCollection collection in PullMergeCollection.values) {
      final Map<String, CloudMergeDoc> cloudById = _indexCloud(
        collection,
        cloud[collection] ?? const <CloudMergeDoc>[],
      );
      final Map<String, LocalMergeRow> localById = _indexLocal(
        collection,
        local[collection] ?? const <LocalMergeRow>[],
      );

      final List<String> ids = <String>{
        ...cloudById.keys,
        ...localById.keys,
      }.toList()..sort();

      for (final String id in ids) {
        final CloudMergeDoc? cloudDoc = cloudById[id];
        final LocalMergeRow? localRow = localById[id];

        if (cloudDoc != null && cloudDoc.deleted) {
          if (localRow == null) {
            // Tombstone tanpa data lokal: tidak ada yang perlu dilakukan.
            continue;
          }
          entries.add(
            PullMergeEntry(
              collection: collection,
              id: id,
              action: PullMergeAction.keepLocalTombstone,
              cloudUpdatedAt: cloudDoc.updatedAt,
              localUpdatedAt: localRow.updatedAt,
              preservedLocalFields: _preservedLocalFields(collection, localRow),
              cloudDeleted: true,
            ),
          );
          if (collection == PullMergeCollection.reminders) {
            mergedReminderData[id] = localRow.data;
          }
          continue;
        }

        if (cloudDoc != null) {
          final Map<String, Object?> preserved = _preservedLocalFields(
            collection,
            localRow,
          );
          final Map<String, Object?> merged = <String, Object?>{
            ...cloudDoc.data,
            ...preserved,
          };
          final bool localNewer = _isLocalNewer(
            cloudDoc.updatedAt,
            localRow?.updatedAt,
          );
          entries.add(
            PullMergeEntry(
              collection: collection,
              id: id,
              action: localNewer
                  ? PullMergeAction.conflictReview
                  : PullMergeAction.pullCloud,
              cloudUpdatedAt: cloudDoc.updatedAt,
              localUpdatedAt: localRow?.updatedAt,
              mergedData: merged,
              preservedLocalFields: preserved,
              localNewerThanCloud: localNewer,
            ),
          );
          if (collection == PullMergeCollection.reminders) {
            mergedReminderData[id] = merged;
          }
          continue;
        }

        if (localRow != null) {
          entries.add(
            PullMergeEntry(
              collection: collection,
              id: id,
              action: PullMergeAction.keepLocal,
              localUpdatedAt: localRow.updatedAt,
              preservedLocalFields: _preservedLocalFields(collection, localRow),
            ),
          );
          if (collection == PullMergeCollection.reminders) {
            mergedReminderData[id] = localRow.data;
          }
        }
      }
    }

    final List<String> reminderIdsToReschedule =
        mergedReminderData.keys
            .where(
              (String id) =>
                  mergedReminderData[id]!['isNotificationEnabled'] != false,
            )
            .toList()
          ..sort();

    return PullMergePlan(
      generatedAtUtc: _now().toUtc(),
      entries: entries,
      reminderIdsToReschedule: reminderIdsToReschedule,
    );
  }

  bool _isLocalNewer(DateTime? cloudUpdatedAt, DateTime? localUpdatedAt) {
    if (cloudUpdatedAt == null || localUpdatedAt == null) {
      return false;
    }
    return localUpdatedAt.isAfter(cloudUpdatedAt.add(clockSkewTolerance));
  }

  Map<String, Object?> _preservedLocalFields(
    PullMergeCollection collection,
    LocalMergeRow? localRow,
  ) {
    if (localRow == null) {
      return const <String, Object?>{};
    }
    final List<String>? keys = preservedFields[collection];
    if (keys == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      for (final String key in keys)
        if (localRow.data.containsKey(key)) key: localRow.data[key],
    };
  }

  Map<String, CloudMergeDoc> _indexCloud(
    PullMergeCollection collection,
    List<CloudMergeDoc> docs,
  ) {
    final Map<String, CloudMergeDoc> index = <String, CloudMergeDoc>{};
    for (final CloudMergeDoc doc in docs) {
      if (doc.id.trim().isEmpty) {
        throw ArgumentError.value(
          doc.id,
          '${collection.key}.id',
          'id cloud kosong',
        );
      }
      if (index.containsKey(doc.id)) {
        throw ArgumentError('${collection.key}: id cloud duplikat (${doc.id})');
      }
      index[doc.id] = doc;
    }
    return index;
  }

  Map<String, LocalMergeRow> _indexLocal(
    PullMergeCollection collection,
    List<LocalMergeRow> rows,
  ) {
    final Map<String, LocalMergeRow> index = <String, LocalMergeRow>{};
    for (final LocalMergeRow row in rows) {
      if (row.id.trim().isEmpty) {
        throw ArgumentError.value(
          row.id,
          '${collection.key}.id',
          'id lokal kosong',
        );
      }
      if (index.containsKey(row.id)) {
        throw ArgumentError('${collection.key}: id lokal duplikat (${row.id})');
      }
      index[row.id] = row;
    }
    return index;
  }
}
