import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/migration/application/backfill_service.dart';
import 'package:nousen/features/migration/data/backfill_checkpoint_store.dart';
import 'package:nousen/features/migration/data/backfill_local_source.dart';
import 'package:nousen/features/migration/data/backfill_models.dart';
import 'package:nousen/features/migration/data/backfill_sink.dart';
import 'package:nousen/features/migration/domain/backfill_entity_kind.dart';

class _FakeSink implements BackfillSink {
  _FakeSink({
    this.uid = 'user-1',
    Map<String, Map<String, Object?>>? docs,
    List<String>? writeOrder,
  }) : docs = docs ?? <String, Map<String, Object?>>{},
       writeOrder = writeOrder ?? <String>[];

  static const String serverTsSentinel = '<server-ts>';

  @override
  String? uid;

  /// Dua sink bisa berbagi map yang sama untuk mensimulasikan dua device
  /// yang menulis ke satu cloud Firestore.
  final Map<String, Map<String, Object?>> docs;
  final List<String> writeOrder;
  int serverTimestampCalls = 0;

  String _key(BackfillEntityKind kind, String docId) =>
      '${kind.collection}/$docId';

  @override
  Future<bool> createDoc(
    BackfillEntityKind kind,
    String docId,
    Map<String, Object?> data,
  ) async {
    // Cek + sisip TANPA `await` di antara keduanya = atomik di event loop
    // Dart, meniru `createDoc` Firestore (transaksi create-if-absent).
    final String key = _key(kind, docId);
    if (docs.containsKey(key)) {
      return false;
    }
    docs[key] = data;
    writeOrder.add(key);
    return true;
  }

  @override
  Object serverTimestamp() {
    serverTimestampCalls++;
    return serverTsSentinel;
  }
}

class _FakeSource implements BackfillLocalSource {
  _FakeSource(this.rowsByKind);

  final Map<BackfillEntityKind, List<BackfillLocalRow>> rowsByKind;
  final Map<BackfillEntityKind, int> readCalls = <BackfillEntityKind, int>{};

  @override
  Future<List<BackfillLocalRow>> readAll(BackfillEntityKind kind) async {
    readCalls[kind] = (readCalls[kind] ?? 0) + 1;
    return List<BackfillLocalRow>.of(
      rowsByKind[kind] ?? const <BackfillLocalRow>[],
    );
  }
}

class _MemoryCheckpointStore implements BackfillCheckpointStore {
  Map<String, Object?>? data;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<Map<String, Object?>?> load() async {
    loadCalls++;
    final Map<String, Object?>? snapshot = data;
    if (snapshot == null) {
      return null;
    }
    // Lewat JSON: memastikan checkpoint benar-benar serializable (meniru
    // FileBackfillCheckpointStore) dan tidak berbagi referensi.
    return (jsonDecode(jsonEncode(snapshot)) as Map).cast<String, Object?>();
  }

  @override
  Future<void> save(Map<String, Object?> value) async {
    saveCalls++;
    data = (jsonDecode(jsonEncode(value)) as Map).cast<String, Object?>();
  }
}

BackfillLocalRow _row(BackfillEntityKind kind, int isarId, String docId) {
  return BackfillLocalRow(
    isarId: isarId,
    docId: docId,
    buildData: (Object serverTs) => <String, Object?>{
      'id': docId,
      'title': '$docId-title',
      'updatedAt': serverTs,
      'deleted': false,
    },
  );
}

void main() {
  group('BackfillService (S0)', () {
    test('idempoten: run kedua tidak membuat dokumen baru (full rescan, '
        'semua baris terverifikasi sebagai skip)', () async {
      final _FakeSink sink = _FakeSink();
      final _FakeSource source = _FakeSource(
        <BackfillEntityKind, List<BackfillLocalRow>>{
          BackfillEntityKind.activities: <BackfillLocalRow>[
            _row(BackfillEntityKind.activities, 1, 'a1'),
            _row(BackfillEntityKind.activities, 2, 'a2'),
          ],
        },
      );
      final _MemoryCheckpointStore store = _MemoryCheckpointStore();

      final BackfillReport first = await BackfillService(
        sink: sink,
        source: source,
        checkpoints: store,
      ).run();

      expect(first.allDone, isTrue);
      expect(first.totalPushed, 2);
      expect(sink.docs.length, 2);
      expect(sink.serverTimestampCalls, 2);
      expect(
        sink.docs['activities/a1']!['updatedAt'],
        _FakeSink.serverTsSentinel,
      );

      final int? readCallsAfterFirst =
          source.readCalls[BackfillEntityKind.activities];

      final BackfillReport second = await BackfillService(
        sink: sink,
        source: source,
        checkpoints: store,
      ).run();

      // Run kedua tidak membuat dokumen baru: semua baris diverifikasi
      // ulang (full rescan) dan terhitung skip — inilah yang membuat baris
      // baru di bawah kursor lama ikut tertangkap (temuan QC ronde 2).
      expect(second.totalPushed, 2); // kumulatif, tanpa tambahan
      expect(second.totalSkippedExisting, 2);
      expect(second.allDone, isTrue);
      // Payload dibangun lagi untuk verifikasi, tapi tidak ada tulis baru.
      expect(sink.serverTimestampCalls, 4);
      expect(sink.writeOrder.length, 2);
      // Beda dari strategi kursor lama: sumber dibaca ulang tiap run.
      expect(
        source.readCalls[BackfillEntityKind.activities],
        (readCallsAfterFirst ?? 0) + 1,
      );
      expect(sink.docs.length, 2);
      expect(sink.docs['activities/a1']!['title'], 'a1-title');
    });

    test(
      'skip dokumen cloud yang sudah ada dan TIDAK menimpa isinya',
      () async {
        final _FakeSink sink = _FakeSink();
        sink.docs['activities/a1'] = <String, Object?>{
          'title': 'VERSI-CLOUD',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        };
        final _FakeSource source = _FakeSource(
          <BackfillEntityKind, List<BackfillLocalRow>>{
            BackfillEntityKind.activities: <BackfillLocalRow>[
              _row(BackfillEntityKind.activities, 1, 'a1'),
              _row(BackfillEntityKind.activities, 2, 'a2'),
            ],
          },
        );

        final BackfillReport report = await BackfillService(
          sink: sink,
          source: source,
          checkpoints: _MemoryCheckpointStore(),
        ).run();

        expect(report.totalPushed, 1);
        expect(report.totalSkippedExisting, 1);
        expect(sink.docs['activities/a1']!['title'], 'VERSI-CLOUD');
        expect(sink.docs['activities/a2']!['title'], 'a2-title');

        final BackfillEntityReport activities = report.entities.firstWhere(
          (BackfillEntityReport e) => e.kind == BackfillEntityKind.activities,
        );
        expect(activities.pushed, 1);
        expect(activities.skippedExisting, 1);
        expect(activities.done, isTrue);
      },
    );

    test('full rescan: baris lama (di bawah kursor) diverifikasi ulang '
        'sebagai skip — tidak ada skip buta berbasis isarId', () async {
      // Cloud sudah memuat a1 & a2 dari run sebelumnya (state konsisten
      // dengan checkpoint lama).
      final _FakeSink sink = _FakeSink();
      sink.docs['activities/a1'] = <String, Object?>{
        'title': 'a1-title',
        'updatedAt': _FakeSink.serverTsSentinel,
      };
      sink.docs['activities/a2'] = <String, Object?>{
        'title': 'a2-title',
        'updatedAt': _FakeSink.serverTsSentinel,
      };
      final _FakeSource source = _FakeSource(
        <BackfillEntityKind, List<BackfillLocalRow>>{
          BackfillEntityKind.activities: <BackfillLocalRow>[
            _row(BackfillEntityKind.activities, 1, 'a1'),
            _row(BackfillEntityKind.activities, 2, 'a2'),
            _row(BackfillEntityKind.activities, 3, 'a3'),
            _row(BackfillEntityKind.activities, 4, 'a4'),
          ],
        },
      );
      final _MemoryCheckpointStore store = _MemoryCheckpointStore()
        ..data = <String, Object?>{
          'version': 1,
          'uid': 'user-1',
          'entities': <String, Object?>{
            'activities': <String, Object?>{
              'lastIsarId': 2,
              'pushed': 2,
              'skippedExisting': 0,
              'done': false,
            },
          },
        };

      final BackfillReport report = await BackfillService(
        sink: sink,
        source: source,
        checkpoints: store,
      ).run();

      // a1/a2 diverifikasi via createDoc → sudah ada → skip, TIDAK ditulis
      // ulang; a3/a4 dibuat.
      expect(
        sink.writeOrder
            .where((String key) => key.startsWith('activities/'))
            .toList(),
        <String>['activities/a3', 'activities/a4'],
      );
      expect(sink.docs['activities/a1']!['title'], 'a1-title');
      expect(sink.docs['activities/a2']!['title'], 'a2-title');

      final BackfillEntityReport activities = report.entities.firstWhere(
        (BackfillEntityReport e) => e.kind == BackfillEntityKind.activities,
      );
      // Kumulatif: 2 dari checkpoint + 2 baris baru.
      expect(activities.pushed, 4);
      expect(activities.skippedExisting, 2);
      expect(activities.lastIsarId, 4);
      expect(activities.done, isTrue);
    });

    test(
      'baris baru muncul DI BAWAH kursor checkpoint → tetap dibuat '
      '(full rescan; temuan QC ronde 2)',
      () async {
        // Pass pertama (simulasi): a1, a3, a5 sudah di cloud, checkpoint
        // mencatat kursor 5 — dengan strategi lama, semua baris baru
        // ber-isarId < 5 akan dilewati SELAMANYA.
        final _FakeSink sink = _FakeSink();
        for (final String docId in <String>['a1', 'a3', 'a5']) {
          sink.docs['activities/$docId'] = <String, Object?>{
            'title': '$docId-title',
            'updatedAt': _FakeSink.serverTsSentinel,
          };
        }
        final _FakeSource source = _FakeSource(
          <BackfillEntityKind, List<BackfillLocalRow>>{
            BackfillEntityKind.activities: <BackfillLocalRow>[
              _row(BackfillEntityKind.activities, 1, 'a1'),
              // Insert terlambat: isarId 2 < kursor 5.
              _row(BackfillEntityKind.activities, 2, 'late'),
              _row(BackfillEntityKind.activities, 3, 'a3'),
              _row(BackfillEntityKind.activities, 5, 'a5'),
              _row(BackfillEntityKind.activities, 6, 'a6'),
            ],
          },
        );
        final _MemoryCheckpointStore store = _MemoryCheckpointStore()
          ..data = <String, Object?>{
            'version': 1,
            'uid': 'user-1',
            'entities': <String, Object?>{
              'activities': <String, Object?>{
                'lastIsarId': 5,
                'pushed': 3,
                'skippedExisting': 0,
                'done': true,
              },
            },
          };

        final BackfillReport report = await BackfillService(
          sink: sink,
          source: source,
          checkpoints: store,
        ).run();

        // 'late' (di bawah kursor) TETAP dibuat, a6 dibuat, sisanya skip.
        expect(
          sink.writeOrder
              .where((String key) => key.startsWith('activities/'))
              .toList(),
          <String>['activities/late', 'activities/a6'],
        );
        expect(sink.docs['activities/late']!['title'], 'late-title');
        expect(sink.docs['activities/a1']!['title'], 'a1-title');

        final BackfillEntityReport activities = report.entities.firstWhere(
          (BackfillEntityReport e) => e.kind == BackfillEntityKind.activities,
        );
        expect(activities.pushed, 5); // 3 kumulatif + late + a6
        expect(activities.skippedExisting, 3);
        expect(activities.lastIsarId, 6);
        expect(activities.done, isTrue);
      },
    );

    test(
      'dua device backfill bersamaan: tidak ada dokumen yang ditimpa '
      '(create-if-absent atomik)',
      () async {
        // Satu cloud bersama untuk dua device.
        final Map<String, Map<String, Object?>> cloud =
            <String, Map<String, Object?>>{};
        final List<String> writeOrder = <String>[];
        final _FakeSink deviceA = _FakeSink(
          docs: cloud,
          writeOrder: writeOrder,
        );
        final _FakeSink deviceB = _FakeSink(
          docs: cloud,
          writeOrder: writeOrder,
        );

        BackfillLocalRow rowWithTitle(String docId, int isarId, String title) {
          return BackfillLocalRow(
            isarId: isarId,
            docId: docId,
            buildData: (Object serverTs) => <String, Object?>{
              'id': docId,
              'title': title,
              'updatedAt': serverTs,
              'deleted': false,
            },
          );
        }

        // Device A dan B sama-sama punya a1 dengan isi BERBEDA (state lokal
        // divergen — inilah kenapa menimpa berbahaya).
        final BackfillService serviceA = BackfillService(
          sink: deviceA,
          source: _FakeSource(
            <BackfillEntityKind, List<BackfillLocalRow>>{
              BackfillEntityKind.activities: <BackfillLocalRow>[
                rowWithTitle('a1', 1, 'dari-device-A'),
                rowWithTitle('a2', 2, 'dari-device-A'),
              ],
            },
          ),
          checkpoints: _MemoryCheckpointStore(),
        );
        final BackfillService serviceB = BackfillService(
          sink: deviceB,
          source: _FakeSource(
            <BackfillEntityKind, List<BackfillLocalRow>>{
              BackfillEntityKind.activities: <BackfillLocalRow>[
                rowWithTitle('a1', 1, 'dari-device-B'),
                rowWithTitle('a3', 3, 'dari-device-B'),
              ],
            },
          ),
          checkpoints: _MemoryCheckpointStore(),
        );

        final List<BackfillReport> reports =
            await Future.wait(<Future<BackfillReport>>[
              serviceA.run(),
              serviceB.run(),
            ]);
        final BackfillReport reportA = reports[0];
        final BackfillReport reportB = reports[1];

        // a1 dibuat tepat SEKALI (3 dokumen unik → 3 create sukses) dan
        // tepat satu device menghitungnya sebagai skip. Dengan pola lama
        // (cek-dulu-baru-tulis) kedua device akan sama-sama menulis a1 →
        // total pushed 4 dan salah satu isi hilang.
        expect(cloud.length, 3);
        expect(reportA.totalPushed + reportB.totalPushed, 3);
        expect(reportA.totalSkippedExisting + reportB.totalSkippedExisting, 1);
        expect(
          writeOrder.where((String key) => key == 'activities/a1').length,
          1,
        );
        // Isi a1 = milik pembuatnya, tidak ditimpa setelah dibuat.
        expect(
          cloud['activities/a1']!['title'],
          anyOf('dari-device-A', 'dari-device-B'),
        );
      },
    );

    test(
      'isarId duplikat: kedua baris diverifikasi lewat docId — yang belum '
      'tertulis tetap dibuat',
      () async {
        // Run sebelum crash sudah menulis dup-a; dup-b (isarId sama, 5)
        // belum sempat diproses.
        final _FakeSink sink = _FakeSink();
        sink.docs['activities/dup-a'] = <String, Object?>{
          'title': 'dup-a-title',
          'updatedAt': _FakeSink.serverTsSentinel,
        };
        final _FakeSource source = _FakeSource(
          <BackfillEntityKind, List<BackfillLocalRow>>{
            BackfillEntityKind.activities: <BackfillLocalRow>[
              _row(BackfillEntityKind.activities, 5, 'dup-a'),
              _row(BackfillEntityKind.activities, 5, 'dup-b'),
            ],
          },
        );
        final _MemoryCheckpointStore store = _MemoryCheckpointStore()
          ..data = <String, Object?>{
            'version': 1,
            'uid': 'user-1',
            'entities': <String, Object?>{
              'activities': <String, Object?>{
                'lastIsarId': 5,
                'pushed': 1,
                'skippedExisting': 0,
                'done': false,
              },
            },
          };

        final BackfillReport report = await BackfillService(
          sink: sink,
          source: source,
          checkpoints: store,
        ).run();

        // Full rescan via docId: dup-a di-skip (sudah ada), dup-b TETAP
        // dibuat — isarId sama tidak membuatnya ikut ter-skip.
        expect(sink.docs.containsKey('activities/dup-b'), isTrue);
        expect(sink.docs['activities/dup-a']!['title'], 'dup-a-title');
        final BackfillEntityReport activities = report.entities.firstWhere(
          (BackfillEntityReport e) => e.kind == BackfillEntityKind.activities,
        );
        expect(activities.skippedExisting, 1);
        expect(activities.pushed, 2); // 1 dari checkpoint + dup-b
        expect(activities.done, isTrue);
      },
    );

    test('resume aman saat tulis sudah terjadi tapi checkpoint belum '
        'tersimpan (verifikasi ulang create-if-absent)', () async {
      final _FakeSink sink = _FakeSink();
      // a1 sudah tertulis di cloud, checkpoint masih kosong (simulasi crash).
      sink.docs['activities/a1'] = <String, Object?>{
        'title': 'a1-title',
        'updatedAt': _FakeSink.serverTsSentinel,
      };
      final _FakeSource source = _FakeSource(
        <BackfillEntityKind, List<BackfillLocalRow>>{
          BackfillEntityKind.activities: <BackfillLocalRow>[
            _row(BackfillEntityKind.activities, 1, 'a1'),
            _row(BackfillEntityKind.activities, 2, 'a2'),
          ],
        },
      );

      final BackfillReport report = await BackfillService(
        sink: sink,
        source: source,
        checkpoints: _MemoryCheckpointStore(),
      ).run();

      expect(report.totalPushed, 1);
      expect(report.totalSkippedExisting, 1);
      expect(sink.docs['activities/a1']!['title'], 'a1-title');
      expect(sink.docs['activities/a2']!['title'], 'a2-title');
    });

    test('checkpoint milik uid lain diabaikan (mulai dari nol)', () async {
      final _FakeSink sink = _FakeSink();
      final _FakeSource source = _FakeSource(
        <BackfillEntityKind, List<BackfillLocalRow>>{
          BackfillEntityKind.activities: <BackfillLocalRow>[
            _row(BackfillEntityKind.activities, 1, 'a1'),
            _row(BackfillEntityKind.activities, 2, 'a2'),
          ],
        },
      );
      final _MemoryCheckpointStore store = _MemoryCheckpointStore()
        ..data = <String, Object?>{
          'version': 1,
          'uid': 'uid-lain',
          'entities': <String, Object?>{
            'activities': <String, Object?>{
              'lastIsarId': 2,
              'pushed': 2,
              'skippedExisting': 0,
              'done': true,
            },
          },
        };

      final BackfillReport report = await BackfillService(
        sink: sink,
        source: source,
        checkpoints: store,
      ).run();

      expect(report.totalPushed, 2);
      expect(sink.docs.length, 2);
    });

    test(
      'tanpa login: batal tanpa tulis apa pun dan tanpa baca checkpoint',
      () async {
        for (final String? uid in <String?>[null, '   ']) {
          final _FakeSink sink = _FakeSink(uid: uid);
          final _MemoryCheckpointStore store = _MemoryCheckpointStore();
          final _FakeSource source = _FakeSource(
            <BackfillEntityKind, List<BackfillLocalRow>>{
              BackfillEntityKind.activities: <BackfillLocalRow>[
                _row(BackfillEntityKind.activities, 1, 'a1'),
              ],
            },
          );

          final BackfillReport report = await BackfillService(
            sink: sink,
            source: source,
            checkpoints: store,
          ).run();

          expect(report.abortedNoAuth, isTrue);
          expect(sink.docs, isEmpty);
          expect(sink.writeOrder, isEmpty);
          expect(store.loadCalls, 0);
          expect(store.data, isNull);
        }
      },
    );

    test(
      'memproses baris urut isarId walaupun sumber tidak berurutan',
      () async {
        final _FakeSink sink = _FakeSink();
        final _FakeSource source = _FakeSource(
          <BackfillEntityKind, List<BackfillLocalRow>>{
            BackfillEntityKind.activities: <BackfillLocalRow>[
              _row(BackfillEntityKind.activities, 3, 'a3'),
              _row(BackfillEntityKind.activities, 1, 'a1'),
              _row(BackfillEntityKind.activities, 2, 'a2'),
            ],
          },
        );

        await BackfillService(
          sink: sink,
          source: source,
          checkpoints: _MemoryCheckpointStore(),
        ).run();

        expect(
          sink.writeOrder
              .where((String key) => key.startsWith('activities/'))
              .toList(),
          <String>['activities/a1', 'activities/a2', 'activities/a3'],
        );
      },
    );

    test(
      'checkpoint berkala (persistEvery) dan final menyimpan status done',
      () async {
        final _FakeSink sink = _FakeSink();
        final _FakeSource source = _FakeSource(
          <BackfillEntityKind, List<BackfillLocalRow>>{
            BackfillEntityKind.activities: <BackfillLocalRow>[
              _row(BackfillEntityKind.activities, 1, 'a1'),
              _row(BackfillEntityKind.activities, 2, 'a2'),
              _row(BackfillEntityKind.activities, 3, 'a3'),
              _row(BackfillEntityKind.activities, 4, 'a4'),
              _row(BackfillEntityKind.activities, 5, 'a5'),
            ],
          },
        );
        final _MemoryCheckpointStore store = _MemoryCheckpointStore();

        final BackfillReport report = await BackfillService(
          sink: sink,
          source: source,
          checkpoints: store,
          persistEvery: 2,
        ).run();

        expect(report.totalPushed, 5);
        expect(store.saveCalls, greaterThan(1));
        final Map<String, Object?> entities = (store.data!['entities'] as Map)
            .cast<String, Object?>();
        final Map<String, Object?> activities = (entities['activities'] as Map)
            .cast<String, Object?>();
        expect(activities['lastIsarId'], 5);
        expect(activities['done'], true);
        expect(store.data!['uid'], 'user-1');
      },
    );
  });

  group('FileBackfillCheckpointStore', () {
    test('save → load roundtrip di direktori sementara', () async {
      final Directory dir = await Directory.systemTemp.createTemp(
        'nousen_backfill_ckpt',
      );
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final FileBackfillCheckpointStore store = FileBackfillCheckpointStore(
        baseDirectoryProvider: () async => dir,
      );

      expect(await store.load(), isNull);

      await store.save(<String, Object?>{
        'version': 1,
        'uid': 'u1',
        'entities': <String, Object?>{
          'activities': <String, Object?>{
            'lastIsarId': 7,
            'pushed': 3,
            'skippedExisting': 1,
            'done': false,
          },
        },
      });

      final Map<String, Object?>? loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!['uid'], 'u1');
      final Map<String, Object?> entities = (loaded['entities'] as Map)
          .cast<String, Object?>();
      final Map<String, Object?> activities = (entities['activities'] as Map)
          .cast<String, Object?>();
      expect(activities['lastIsarId'], 7);
      expect(activities['done'], false);
    });
  });
}
