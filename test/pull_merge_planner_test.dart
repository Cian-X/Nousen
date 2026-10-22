import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/migration/application/pull_merge_planner.dart';
import 'package:nousen/features/migration/domain/pull_merge_models.dart';

CloudMergeDoc _cloud(
  String id, {
  Map<String, Object?> data = const <String, Object?>{},
  DateTime? updatedAt,
  bool deleted = false,
}) {
  return CloudMergeDoc(
    id: id,
    data: <String, Object?>{'id': id, ...data},
    updatedAt: updatedAt,
    deleted: deleted,
  );
}

LocalMergeRow _local(
  String id, {
  Map<String, Object?> data = const <String, Object?>{},
  DateTime? updatedAt,
}) {
  return LocalMergeRow(
    id: id,
    data: <String, Object?>{'id': id, ...data},
    updatedAt: updatedAt,
  );
}

PullMergeEntry _entryFor(PullMergePlan plan, String id) {
  return plan.entries.firstWhere((PullMergeEntry entry) => entry.id == id);
}

void main() {
  group('PullMergePlanner (S6.0 dry-run)', () {
    test('cloud-only → pullCloud; local-only → keepLocal', () {
      final PullMergePlan plan =
          PullMergePlanner(now: () => DateTime.utc(2026, 10, 22, 12)).plan(
            cloud: <PullMergeCollection, List<CloudMergeDoc>>{
              PullMergeCollection.activities: <CloudMergeDoc>[_cloud('a1')],
            },
            local: <PullMergeCollection, List<LocalMergeRow>>{
              PullMergeCollection.activities: <LocalMergeRow>[_local('a2')],
            },
          );

      expect(plan.isDryRun, isTrue);
      expect(plan.generatedAtUtc, DateTime.utc(2026, 10, 22, 12));
      expect(_entryFor(plan, 'a1').action, PullMergeAction.pullCloud);
      expect(_entryFor(plan, 'a2').action, PullMergeAction.keepLocal);
      expect(plan.countOf(PullMergeAction.pullCloud), 1);
      expect(plan.countOf(PullMergeAction.keepLocal), 1);
      expect(plan.requiresReview, isEmpty);
    });

    test('cloud menang tetapi field media lokal dipertahankan', () {
      final PullMergePlan plan = PullMergePlanner().plan(
        cloud: <PullMergeCollection, List<CloudMergeDoc>>{
          PullMergeCollection.progress: <CloudMergeDoc>[
            _cloud(
              'p1',
              data: <String, Object?>{
                'notes': 'dari cloud',
                'photoPaths': <String>[],
              },
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
          ],
          PullMergeCollection.agendaNotes: <CloudMergeDoc>[
            _cloud(
              'n1',
              data: <String, Object?>{'text': 'catatan cloud'},
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
          ],
          PullMergeCollection.settings: <CloudMergeDoc>[
            _cloud(
              'app',
              data: <String, Object?>{'localeCode': 'en'},
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
          ],
        },
        local: <PullMergeCollection, List<LocalMergeRow>>{
          PullMergeCollection.progress: <LocalMergeRow>[
            _local(
              'p1',
              data: <String, Object?>{
                'notes': 'versi lokal',
                'photoPaths': <String>['/lokal/a.jpg'],
                'photoPath': '/lokal/a.jpg',
                'photoNote': 'foto lokal',
              },
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
          ],
          PullMergeCollection.agendaNotes: <LocalMergeRow>[
            _local(
              'n1',
              data: <String, Object?>{
                'photoPaths': <String>['/lokal/note.jpg'],
              },
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
          ],
          PullMergeCollection.settings: <LocalMergeRow>[
            _local(
              'app',
              data: <String, Object?>{'profileAvatarPath': '/lokal/avatar.jpg'},
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
          ],
        },
      );

      final PullMergeEntry progress = _entryFor(plan, 'p1');
      expect(progress.action, PullMergeAction.pullCloud);
      expect(progress.mergedData!['notes'], 'dari cloud');
      expect(progress.mergedData!['photoPaths'], <String>['/lokal/a.jpg']);
      expect(progress.mergedData!['photoPath'], '/lokal/a.jpg');
      expect(progress.preservedLocalFields.keys.toSet(), <String>{
        'photoPaths',
        'photoPath',
      });
      // photoNote bukan field media yang dilindungi → tetap versi cloud
      // (tidak ada di cloud pada contoh ini).
      expect(progress.mergedData!.containsKey('photoNote'), isFalse);

      final PullMergeEntry note = _entryFor(plan, 'n1');
      expect(note.mergedData!['text'], 'catatan cloud');
      expect(note.mergedData!['photoPaths'], <String>['/lokal/note.jpg']);

      final PullMergeEntry settings = _entryFor(plan, 'app');
      expect(settings.mergedData!['localeCode'], 'en');
      expect(settings.mergedData!['profileAvatarPath'], '/lokal/avatar.jpg');
    });

    test('lokal lebih baru dari server di luar toleransi → conflictReview', () {
      final PullMergePlan plan =
          PullMergePlanner(
            clockSkewTolerance: const Duration(minutes: 2),
            now: () => DateTime.utc(2026, 10, 22),
          ).plan(
            cloud: <PullMergeCollection, List<CloudMergeDoc>>{
              PullMergeCollection.activities: <CloudMergeDoc>[
                _cloud(
                  'a1',
                  data: <String, Object?>{'title': 'cloud'},
                  updatedAt: DateTime.utc(2026, 10, 22, 10),
                ),
              ],
            },
            local: <PullMergeCollection, List<LocalMergeRow>>{
              PullMergeCollection.activities: <LocalMergeRow>[
                _local(
                  'a1',
                  data: <String, Object?>{'title': 'lokal'},
                  updatedAt: DateTime.utc(2026, 10, 22, 10, 30),
                ),
              ],
            },
          );

      final PullMergeEntry entry = _entryFor(plan, 'a1');
      expect(entry.action, PullMergeAction.conflictReview);
      expect(entry.localNewerThanCloud, isTrue);
      expect(plan.requiresReview, hasLength(1));
      // Dry-run tetap menampilkan kandidat data cloud.
      expect(entry.mergedData!['title'], 'cloud');
    });

    test('selisih dalam toleransi tetap pullCloud (bukan konflik)', () {
      final PullMergePlan plan =
          PullMergePlanner(clockSkewTolerance: const Duration(minutes: 5)).plan(
            cloud: <PullMergeCollection, List<CloudMergeDoc>>{
              PullMergeCollection.activities: <CloudMergeDoc>[
                _cloud('a1', updatedAt: DateTime.utc(2026, 10, 22, 10)),
              ],
            },
            local: <PullMergeCollection, List<LocalMergeRow>>{
              PullMergeCollection.activities: <LocalMergeRow>[
                _local('a1', updatedAt: DateTime.utc(2026, 10, 22, 10, 2)),
              ],
            },
          );

      expect(_entryFor(plan, 'a1').action, PullMergeAction.pullCloud);
      expect(plan.requiresReview, isEmpty);
    });

    test('cloud tombstone + lokal ada → keepLocalTombstone, tanpa hapus', () {
      final PullMergePlan plan = PullMergePlanner().plan(
        cloud: <PullMergeCollection, List<CloudMergeDoc>>{
          PullMergeCollection.activities: <CloudMergeDoc>[
            _cloud(
              'a1',
              updatedAt: DateTime.utc(2026, 10, 22, 10),
              deleted: true,
            ),
            _cloud(
              'a2',
              updatedAt: DateTime.utc(2026, 10, 22, 10),
              deleted: true,
            ),
          ],
        },
        local: <PullMergeCollection, List<LocalMergeRow>>{
          PullMergeCollection.activities: <LocalMergeRow>[
            _local('a1', data: <String, Object?>{'title': 'masih lokal'}),
          ],
        },
      );

      final PullMergeEntry entry = _entryFor(plan, 'a1');
      expect(entry.action, PullMergeAction.keepLocalTombstone);
      expect(entry.cloudDeleted, isTrue);
      expect(entry.mergedData, isNull);
      expect(plan.entries.where((PullMergeEntry e) => e.id == 'a2'), isEmpty);
      expect(plan.requiresReview, hasLength(1));
    });

    test('reconcile notifikasi reminder: unik, urut, idempoten', () {
      final PullMergePlanner planner = PullMergePlanner(
        now: () => DateTime.utc(2026, 10, 22),
      );
      final PullMergePlan first = planner.plan(
        cloud: <PullMergeCollection, List<CloudMergeDoc>>{
          PullMergeCollection.reminders: <CloudMergeDoc>[
            _cloud(
              'r2',
              data: <String, Object?>{'isNotificationEnabled': true},
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
            _cloud(
              'r3',
              data: <String, Object?>{'isNotificationEnabled': false},
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
            _cloud(
              'r4',
              updatedAt: DateTime.utc(2026, 10, 22, 10),
              deleted: true,
            ),
          ],
        },
        local: <PullMergeCollection, List<LocalMergeRow>>{
          PullMergeCollection.reminders: <LocalMergeRow>[
            _local(
              'r1',
              data: <String, Object?>{'isNotificationEnabled': true},
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
            _local(
              'r4',
              data: <String, Object?>{'isNotificationEnabled': true},
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
          ],
        },
      );

      expect(first.reminderIdsToReschedule, <String>['r1', 'r2', 'r4']);

      final PullMergePlan second = planner.plan(
        cloud: <PullMergeCollection, List<CloudMergeDoc>>{
          PullMergeCollection.reminders: <CloudMergeDoc>[
            _cloud(
              'r2',
              data: <String, Object?>{'isNotificationEnabled': true},
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
            _cloud(
              'r3',
              data: <String, Object?>{'isNotificationEnabled': false},
              updatedAt: DateTime.utc(2026, 10, 22, 10),
            ),
            _cloud(
              'r4',
              updatedAt: DateTime.utc(2026, 10, 22, 10),
              deleted: true,
            ),
          ],
        },
        local: <PullMergeCollection, List<LocalMergeRow>>{
          PullMergeCollection.reminders: <LocalMergeRow>[
            _local(
              'r1',
              data: <String, Object?>{'isNotificationEnabled': true},
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
            _local(
              'r4',
              data: <String, Object?>{'isNotificationEnabled': true},
              updatedAt: DateTime.utc(2026, 10, 22, 9),
            ),
          ],
        },
      );

      expect(second.reminderIdsToReschedule, first.reminderIdsToReschedule);
    });

    test('id duplikat di satu sisi ditolak (data integrity)', () {
      expect(
        () => PullMergePlanner().plan(
          cloud: <PullMergeCollection, List<CloudMergeDoc>>{
            PullMergeCollection.activities: <CloudMergeDoc>[
              _cloud('a1'),
              _cloud('a1'),
            ],
          },
          local: <PullMergeCollection, List<LocalMergeRow>>{},
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => PullMergePlanner().plan(
          cloud: <PullMergeCollection, List<CloudMergeDoc>>{
            PullMergeCollection.activities: <CloudMergeDoc>[],
          },
          local: <PullMergeCollection, List<LocalMergeRow>>{
            PullMergeCollection.activities: <LocalMergeRow>[
              _local('a1'),
              _local('a1'),
            ],
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('plan JSON menandai dry-run, aksi, dan tidak bisa dimutasi', () {
      final PullMergePlan plan =
          PullMergePlanner(now: () => DateTime.utc(2026, 10, 22, 12)).plan(
            cloud: <PullMergeCollection, List<CloudMergeDoc>>{
              PullMergeCollection.activities: <CloudMergeDoc>[
                _cloud('a1', data: <String, Object?>{'title': 'cloud'}),
              ],
            },
            local: <PullMergeCollection, List<LocalMergeRow>>{
              PullMergeCollection.activities: <LocalMergeRow>[
                _local('a1', data: <String, Object?>{'title': 'lokal'}),
              ],
            },
          );

      final Map<String, Object?> json = plan.toJson();
      expect(json['dryRun'], isTrue);
      expect(json['generatedAt'], '2026-10-22T12:00:00.000Z');
      expect((json['entries']! as List), hasLength(1));

      final PullMergeEntry entry = _entryFor(plan, 'a1');
      expect(() => entry.mergedData!['title'] = 'ubah', throwsUnsupportedError);
      expect(() => plan.entries.add(entry), throwsUnsupportedError);
    });
  });
}
