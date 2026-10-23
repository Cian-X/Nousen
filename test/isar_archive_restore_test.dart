import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:nousen/features/activity/data/activity_entity.dart';
import 'package:nousen/features/migration/application/isar_archive_restore_service.dart';
import 'package:nousen/features/migration/application/isar_archive_service.dart';
import 'package:nousen/features/migration/data/isar_archive_source.dart';
import 'package:nousen/features/migration/data/isar_archive_target.dart';
import 'package:nousen/features/migration/domain/isar_archive.dart';
import 'package:nousen/features/one_time_reminder/data/agenda_note_entity.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_entity.dart';
import 'package:nousen/features/progress/data/progress_entry_entity.dart';
import 'package:nousen/features/settings/data/app_settings_entity.dart';

const String _avatarPath = r'C:\synthetic\profile\avatar.jpg';
const List<String> _notePhotoPaths = <String>[
  r'C:\synthetic\notes\photo-1.jpg',
  r'C:\synthetic\notes\photo-2.jpg',
];
const List<String> _progressPhotoPaths = <String>[
  r'C:\synthetic\progress\photo-1.jpg',
  r'C:\synthetic\progress\photo-2.jpg',
];

const Set<String> _settingsKeys = <String>{
  'isarId',
  'morningReminderMinutes',
  'endOfDayReminderMinutes',
  'localeCode',
  'notificationsEnabled',
  'profileName',
  'profileAvatarPath',
  'weeklyRoutineJson',
  'wakeUpMinutes',
  'sleepMinutes',
  'usualBreakStartMinutes',
  'usualBreakEndMinutes',
  'hasSeededData',
};
const Set<String> _activityKeys = <String>{
  'isarId',
  'id',
  'title',
  'category',
  'selectedDays',
  'subActivities',
  'timeMinutes',
  'weeklyGoal',
  'preReminderMinutes',
  'isNotificationEnabled',
  'enableMorningReminder',
  'enableEndOfDayReminder',
  'enablePhotoProgress',
  'lastThreeDayRuleNotifiedDate',
  'createdAt',
  'updatedAt',
  'scheduleUpdatedAt',
};
const Set<String> _reminderKeys = <String>{
  'isarId',
  'id',
  'title',
  'iconKey',
  'scheduledAt',
  'scheduledEndAt',
  'categoryId',
  'description',
  'subActivities',
  'completedSubActivities',
  'preReminderMinutes',
  'isNotificationEnabled',
  'isCompleted',
  'isSkipped',
  'createdAt',
  'updatedAt',
};
const Set<String> _agendaNoteKeys = <String>{
  'isarId',
  'id',
  'reminderId',
  'text',
  'photoPaths',
  'createdAt',
  'updatedAt',
};
const Set<String> _progressKeys = <String>{
  'isarId',
  'id',
  'activityId',
  'dateKey',
  'statusKey',
  'subCompleted',
  'subTotal',
  'isCompleted',
  'completedSubActivities',
  'photoPaths',
  'photoPath',
  'photoNote',
  'notes',
  'completedAt',
  'createdAt',
  'updatedAt',
};

void main() {
  setUpAll(() async {
    final String dll = _isarDllPath();
    if (!File(dll).existsSync()) {
      throw StateError('Isar native library tidak ditemukan: $dll');
    }
    await Isar.initializeIsarCore(libraries: <Abi, String>{Abi.current(): dll});
  });

  group('IsarArchiveRestoreService + Isar asli (scratch)', () {
    test('capture → encode → parse → restore roundtrip semua field', () async {
      final _Scratch source = await _openScratch('roundtrip_src');
      addTearDown(source.dispose);
      await _seed(source.isar);

      final IsarArchive archive = await _capture(source.isar, 'roundtrip-src');
      expect(archive.counts, <String, int>{
        'settings': 1,
        'activities': 1,
        'reminders': 1,
        'agendaNotes': 1,
        'progress': 1,
      });
      expect(archive.totalDocuments, 5);
      expect(
        archive.collections[IsarArchiveCollection.settings]!.single.keys
            .toSet(),
        _settingsKeys,
      );
      expect(
        archive.collections[IsarArchiveCollection.activities]!.single.keys
            .toSet(),
        _activityKeys,
      );
      expect(
        archive.collections[IsarArchiveCollection.reminders]!.single.keys
            .toSet(),
        _reminderKeys,
      );
      expect(
        archive.collections[IsarArchiveCollection.agendaNotes]!.single.keys
            .toSet(),
        _agendaNoteKeys,
      );
      expect(
        archive.collections[IsarArchiveCollection.progress]!.single.keys
            .toSet(),
        _progressKeys,
      );

      final String encoded = archive.encode();
      final IsarArchive decoded = IsarArchive.decode(encoded);
      expect(decoded.checksum, archive.checksum);
      expect(decoded.checksum.length, 64);
      expect(decoded.counts, archive.counts);
      expect(decoded.collections, archive.collections);

      final _Scratch target = await _openScratch('roundtrip_dst');
      addTearDown(target.dispose);
      final IsarArchiveRestoreReport report =
          await const IsarArchiveRestoreService().restoreJson(
            encoded,
            target: IsarScratchArchiveTarget(isar: target.isar),
          );

      expect(report.databaseName, target.name);
      expect(report.checksum, archive.checksum);
      expect(report.counts, _fullCounts());
      expect(report.totalDocuments, 5);

      // Verifikasi langsung di Isar target.
      expect(await target.isar.appSettingsEntitys.count(), 1);
      expect(await target.isar.activityEntitys.count(), 1);
      expect(await target.isar.oneTimeReminderEntitys.count(), 1);
      expect(await target.isar.agendaNoteEntitys.count(), 1);
      expect(await target.isar.progressEntryEntitys.count(), 1);

      // Re-capture target: seluruh field (termasuk path foto lokal dan nilai
      // nullable) harus identik dengan archive asal.
      final IsarArchive restored = await _capture(
        target.isar,
        'roundtrip-restored',
      );
      expect(restored.collections, archive.collections);
      expect(restored.counts, archive.counts);

      final Map<String, Object?> settingsDoc =
          restored.collections[IsarArchiveCollection.settings]!.single;
      expect(settingsDoc['profileAvatarPath'], _avatarPath);
      expect(settingsDoc['weeklyRoutineJson'], isNotNull);
      expect(settingsDoc['profileName'], isNull);
      expect(settingsDoc['hasSeededData'], isNull);

      final Map<String, Object?> activityDoc =
          restored.collections[IsarArchiveCollection.activities]!.single;
      expect(activityDoc['selectedDays'], <int>[1, 3, 5, 7]);
      expect(activityDoc['subActivities'], <String>['sub-a', 'sub-b']);
      expect(activityDoc['category'], isNull);
      expect(activityDoc['scheduleUpdatedAt'], isNull);

      final Map<String, Object?> reminderDoc =
          restored.collections[IsarArchiveCollection.reminders]!.single;
      expect(reminderDoc['scheduledEndAt'], '2026-10-24T08:00:00.000Z');
      expect(reminderDoc['completedSubActivities'], <String>['r-sub-1']);
      expect(reminderDoc['isSkipped'], isNull);

      final Map<String, Object?> noteDoc =
          restored.collections[IsarArchiveCollection.agendaNotes]!.single;
      expect(noteDoc['photoPaths'], _notePhotoPaths);

      final Map<String, Object?> progressDoc =
          restored.collections[IsarArchiveCollection.progress]!.single;
      expect(progressDoc['photoPaths'], _progressPhotoPaths);
      expect(progressDoc['photoPath'], _progressPhotoPaths.first);
      expect(progressDoc['completedAt'], '2026-10-22T09:30:00.000Z');
      expect(progressDoc['photoNote'], isNull);
    });

    test(
      'restore ulang ke target sama ditolak; target baru tetap aman',
      () async {
        final _Scratch source = await _openScratch('repeat_src');
        addTearDown(source.dispose);
        await _seed(source.isar);
        final IsarArchive archive = await _capture(source.isar, 'repeat-src');
        final String encoded = archive.encode();

        final _Scratch target = await _openScratch('repeat_dst');
        addTearDown(target.dispose);
        final IsarScratchArchiveTarget targetAdapter = IsarScratchArchiveTarget(
          isar: target.isar,
        );
        await const IsarArchiveRestoreService().restoreJson(
          encoded,
          target: targetAdapter,
        );

        await expectLater(
          const IsarArchiveRestoreService().restoreJson(
            encoded,
            target: targetAdapter,
          ),
          throwsA(isA<StateError>()),
        );
        expect(
          await IsarArchiveService(
            source: IsarScratchArchiveSource(
              isar: target.isar,
              label: 'repeat-after-reject',
            ),
          ).capture().then((IsarArchive after) => after.collections),
          archive.collections,
        );

        // Repeat yang aman = restore ke database scratch BARU, bukan menimpa.
        final _Scratch secondTarget = await _openScratch('repeat_dst_2');
        addTearDown(secondTarget.dispose);
        final IsarArchiveRestoreReport secondReport =
            await const IsarArchiveRestoreService().restoreJson(
              encoded,
              target: IsarScratchArchiveTarget(isar: secondTarget.isar),
            );
        expect(secondReport.counts, _fullCounts());
        final IsarArchive restoredSecond = await _capture(
          secondTarget.isar,
          'repeat-second',
        );
        expect(restoredSecond.collections, archive.collections);
      },
    );

    test('archive rusak/terpotong ditolak sebelum mutation', () async {
      final _Scratch source = await _openScratch('invalid_src');
      addTearDown(source.dispose);
      await _seed(source.isar);
      final IsarArchive archive = await _capture(source.isar, 'invalid-src');
      final String encoded = archive.encode();
      final Map<String, Object?> json = (jsonDecode(encoded) as Map)
          .cast<String, Object?>();

      final List<String> invalidArchives = <String>[
        encoded.substring(0, encoded.length ~/ 2),
        encoded.substring(0, encoded.length - 10),
        jsonEncode(<String, Object?>{...json, 'schemaVersion': 1}),
        jsonEncode(<String, Object?>{
          ...json,
          'checksum': List<String>.filled(64, '0').join(),
        }),
        jsonEncode(<String, Object?>{
          ...json,
          'counts': <String, int>{
            ...(json['counts']! as Map).cast<String, int>(),
            'activities': 2,
          },
        }),
      ];

      final _Scratch target = await _openScratch('invalid_dst');
      addTearDown(target.dispose);
      final IsarScratchArchiveTarget targetAdapter = IsarScratchArchiveTarget(
        isar: target.isar,
      );
      for (final String invalid in invalidArchives) {
        await expectLater(
          const IsarArchiveRestoreService().restoreJson(
            invalid,
            target: targetAdapter,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(await targetAdapter.countDocuments(), _emptyCounts());
      }

      // isarId duplikat juga ditolak oleh parser, sebelum target disentuh.
      final Map<IsarArchiveCollection, List<Map<String, Object?>>> duplicateId =
          _copyCollections(archive);
      final Map<String, Object?> activity =
          duplicateId[IsarArchiveCollection.activities]!.single;
      duplicateId[IsarArchiveCollection.activities] = <Map<String, Object?>>[
        activity,
        Map<String, Object?>.from(activity),
      ];
      await expectLater(
        const IsarArchiveRestoreService().restoreJson(
          _withCollections(archive, duplicateId).encode(),
          target: targetAdapter,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(await targetAdapter.countDocuments(), _emptyCounts());
    });

    test('field rusak / id string duplikat ditolak sebelum mutation', () async {
      final _Scratch source = await _openScratch('mapping_src');
      addTearDown(source.dispose);
      await _seed(source.isar);
      final IsarArchive archive = await _capture(source.isar, 'mapping-src');

      final _Scratch target = await _openScratch('mapping_dst');
      addTearDown(target.dispose);
      final IsarScratchArchiveTarget targetAdapter = IsarScratchArchiveTarget(
        isar: target.isar,
      );

      final Map<IsarArchiveCollection, List<Map<String, Object?>>> badField =
          _copyCollections(archive);
      badField[IsarArchiveCollection.activities]!.single['selectedDays'] =
          'bukan-array';
      await expectLater(
        const IsarArchiveRestoreService().restoreJson(
          _withCollections(archive, badField).encode(),
          target: targetAdapter,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(await targetAdapter.countDocuments(), _emptyCounts());

      final Map<IsarArchiveCollection, List<Map<String, Object?>>> dupStringId =
          _copyCollections(archive);
      final Map<String, Object?> original =
          dupStringId[IsarArchiveCollection.activities]!.single;
      final Map<String, Object?> duplicate = Map<String, Object?>.from(original)
        ..['isarId'] = 999;
      dupStringId[IsarArchiveCollection.activities] = <Map<String, Object?>>[
        original,
        duplicate,
      ];
      await expectLater(
        const IsarArchiveRestoreService().restoreJson(
          _withCollections(archive, dupStringId).encode(),
          target: targetAdapter,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(await targetAdapter.countDocuments(), _emptyCounts());
    });

    test(
      'DB produksi / target non-scratch ditolak sebelum baca/tulis',
      () async {
        expect(
          () => validateS6ScratchDatabaseName('reminder_schedule_v2'),
          throwsA(isA<ArgumentError>()),
        );

        final _CountingTarget nonScratch = _CountingTarget(
          isScratch: false,
          databaseName: 'reminder_schedule_v2',
        );
        await expectLater(
          const IsarArchiveRestoreService().restoreJson(
            '{"bukan":"archive"}',
            target: nonScratch,
          ),
          throwsA(isA<StateError>()),
        );
        expect(nonScratch.countCalls, 0);
        expect(nonScratch.writeCalls, 0);

        final _CountingTarget lyingScratch = _CountingTarget(
          isScratch: true,
          databaseName: 'reminder_schedule_v2',
        );
        await expectLater(
          const IsarArchiveRestoreService().restoreJson(
            '{"bukan":"archive"}',
            target: lyingScratch,
          ),
          throwsA(isA<StateError>()),
        );
        expect(lyingScratch.countCalls, 0);
        expect(lyingScratch.writeCalls, 0);

        // Archive yang mengaku berasal dari DB produksi juga ditolak sebelum
        // target scratch dibaca/ditulis.
        final IsarArchive productionArchive = IsarArchive(
          capturedAtUtc: DateTime.utc(2026, 10, 23),
          sourceLabel: 'synthetic',
          databaseName: 'reminder_schedule_v2',
          collections:
              const <IsarArchiveCollection, List<Map<String, Object?>>>{},
        );
        final _CountingTarget scratchCounter = _CountingTarget(
          isScratch: true,
          databaseName: 'nousen_s6_scratch_counter',
        );
        await expectLater(
          const IsarArchiveRestoreService().restoreJson(
            productionArchive.encode(),
            target: scratchCounter,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(scratchCounter.countCalls, 0);
        expect(scratchCounter.writeCalls, 0);

        final _Scratch target = await _openScratch('production_archive');
        addTearDown(target.dispose);
        final IsarScratchArchiveTarget targetAdapter = IsarScratchArchiveTarget(
          isar: target.isar,
        );
        await expectLater(
          const IsarArchiveRestoreService().restoreJson(
            productionArchive.encode(),
            target: targetAdapter,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(await targetAdapter.countDocuments(), _emptyCounts());
      },
    );
  });
}

class _Scratch {
  _Scratch({required this.isar, required this.directory, required this.name});

  final Isar isar;
  final Directory directory;
  final String name;

  Future<void> dispose() async {
    await isar.close(deleteFromDisk: true);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

class _CountingTarget implements IsarArchiveTarget {
  _CountingTarget({required this.isScratch, required this.databaseName});

  @override
  final bool isScratch;

  @override
  final String databaseName;

  int countCalls = 0;
  int writeCalls = 0;

  @override
  Future<Map<IsarArchiveCollection, int>> countDocuments() async {
    countCalls += 1;
    return _emptyCounts();
  }

  @override
  Future<void> writeAll(IsarArchive archive) async {
    writeCalls += 1;
  }
}

Future<_Scratch> _openScratch(String suffix) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'nousen_s6_scratch_dir_',
  );
  final String name =
      'nousen_s6_scratch_${suffix}_${DateTime.now().microsecondsSinceEpoch}';
  final Isar isar = await Isar.open(
    <CollectionSchema<dynamic>>[
      AppSettingsEntitySchema,
      ActivityEntitySchema,
      OneTimeReminderEntitySchema,
      AgendaNoteEntitySchema,
      ProgressEntryEntitySchema,
    ],
    directory: directory.path,
    name: name,
  );
  return _Scratch(isar: isar, directory: directory, name: name);
}

Future<IsarArchive> _capture(Isar isar, String label) {
  return IsarArchiveService(
    source: IsarScratchArchiveSource(isar: isar, label: label),
    now: () => DateTime.utc(2026, 10, 23, 12),
  ).capture();
}

Future<void> _seed(Isar isar) async {
  final bool committed = await isar.writeTxn(() async {
    await isar.appSettingsEntitys.put(_settings());
    await isar.activityEntitys.put(_activity());
    await isar.oneTimeReminderEntitys.put(_reminder());
    await isar.agendaNoteEntitys.put(_note());
    await isar.progressEntryEntitys.put(_progress());
    return true;
  });
  expect(committed, isTrue);
}

AppSettingsEntity _settings() {
  return AppSettingsEntity()
    ..id = 1
    ..morningReminderMinutes = 30
    ..endOfDayReminderMinutes = 60
    ..localeCode = 'id'
    ..notificationsEnabled = true
    ..profileAvatarPath = _avatarPath
    ..weeklyRoutineJson =
        '{"routine":[],"extraActivitiesNote":"synthetic",'
        '"hasSeededData":true,"notificationVibration":false}'
    ..wakeUpMinutes = 360
    ..sleepMinutes = 1380
    ..usualBreakStartMinutes = 720
    ..usualBreakEndMinutes = 780;
}

ActivityEntity _activity() {
  return ActivityEntity()
    ..isarId = 41
    ..id = 'activity-synthetic-1'
    ..title = 'Synthetic Activity'
    ..selectedDays = <int>[1, 3, 5, 7]
    ..subActivities = <String>['sub-a', 'sub-b']
    ..timeMinutes = 45
    ..weeklyGoal = 4
    ..preReminderMinutes = 10
    ..isNotificationEnabled = true
    ..enableMorningReminder = true
    ..enableEndOfDayReminder = false
    ..enablePhotoProgress = true
    ..lastThreeDayRuleNotifiedDate = '2026-10-20'
    ..createdAt = DateTime.utc(2026, 10, 1, 8)
    ..updatedAt = DateTime.utc(2026, 10, 22, 9);
}

OneTimeReminderEntity _reminder() {
  return OneTimeReminderEntity()
    ..isarId = 42
    ..id = 'reminder-synthetic-1'
    ..title = 'Synthetic Reminder'
    ..iconKey = 'water'
    ..scheduledAt = DateTime.utc(2026, 10, 24, 7)
    ..scheduledEndAt = DateTime.utc(2026, 10, 24, 8)
    ..categoryId = 'work'
    ..description = 'Synthetic description'
    ..subActivities = <String>['r-sub-1', 'r-sub-2']
    ..completedSubActivities = <String>['r-sub-1']
    ..preReminderMinutes = 15
    ..isNotificationEnabled = true
    ..isCompleted = false
    ..createdAt = DateTime.utc(2026, 10, 20, 7)
    ..updatedAt = DateTime.utc(2026, 10, 22, 8);
}

AgendaNoteEntity _note() {
  return AgendaNoteEntity()
    ..isarId = 43
    ..id = 'note-synthetic-1'
    ..reminderId = 'reminder-synthetic-1'
    ..text = 'Synthetic note'
    ..photoPaths = _notePhotoPaths.toList(growable: false)
    ..createdAt = DateTime.utc(2026, 10, 20, 7, 5)
    ..updatedAt = DateTime.utc(2026, 10, 21, 8, 5);
}

ProgressEntryEntity _progress() {
  return ProgressEntryEntity()
    ..isarId = 44
    ..id = 'progress-synthetic-1'
    ..activityId = 'activity-synthetic-1'
    ..dateKey = '2026-10-22'
    ..statusKey = 'completed'
    ..subCompleted = 1
    ..subTotal = 2
    ..isCompleted = true
    ..completedSubActivities = <String>['sub-a']
    ..photoPaths = _progressPhotoPaths.toList(growable: false)
    ..photoPath = _progressPhotoPaths.first
    ..notes = 'Synthetic progress notes'
    ..completedAt = DateTime.utc(2026, 10, 22, 9, 30)
    ..createdAt = DateTime.utc(2026, 10, 22, 8)
    ..updatedAt = DateTime.utc(2026, 10, 22, 10);
}

Map<IsarArchiveCollection, List<Map<String, Object?>>> _copyCollections(
  IsarArchive archive,
) {
  return <IsarArchiveCollection, List<Map<String, Object?>>>{
    for (final IsarArchiveCollection collection in IsarArchiveCollection.values)
      collection: archive.collections[collection]!
          .map((Map<String, Object?> doc) => Map<String, Object?>.from(doc))
          .toList(growable: false),
  };
}

IsarArchive _withCollections(
  IsarArchive base,
  Map<IsarArchiveCollection, List<Map<String, Object?>>> collections,
) {
  return IsarArchive(
    capturedAtUtc: base.capturedAtUtc,
    sourceLabel: base.sourceLabel,
    databaseName: base.databaseName,
    collections: collections,
  );
}

Map<IsarArchiveCollection, int> _emptyCounts() {
  return <IsarArchiveCollection, int>{
    for (final IsarArchiveCollection collection in IsarArchiveCollection.values)
      collection: 0,
  };
}

Map<IsarArchiveCollection, int> _fullCounts() {
  return <IsarArchiveCollection, int>{
    for (final IsarArchiveCollection collection in IsarArchiveCollection.values)
      collection: 1,
  };
}

String _isarDllPath() {
  final File packageConfig = File('.dart_tool/package_config.json');
  final Map<String, dynamic> config =
      jsonDecode(packageConfig.readAsStringSync()) as Map<String, dynamic>;
  final List<dynamic> packages = config['packages'] as List<dynamic>;
  final Map<String, dynamic> entry = packages
      .cast<Map<String, dynamic>>()
      .firstWhere(
        (Map<String, dynamic> package) =>
            package['name'] == 'isar_flutter_libs',
      );
  final String rootUri = entry['rootUri'] as String;
  final Uri base = Directory('.dart_tool').uri;
  final Uri resolved = base.resolve(
    rootUri.endsWith('/') ? rootUri : '$rootUri/',
  );

  final String platformFolder;
  final String libraryFile;
  if (Platform.isWindows) {
    platformFolder = 'windows';
    libraryFile = 'isar.dll';
  } else if (Platform.isMacOS) {
    platformFolder = 'macos';
    libraryFile = 'libisar.dylib';
  } else if (Platform.isLinux) {
    platformFolder = 'linux';
    libraryFile = 'libisar.so';
  } else {
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} belum didukung tes Isar native',
    );
  }
  return File(
    '${resolved.toFilePath()}$platformFolder'
    '${Platform.pathSeparator}$libraryFile',
  ).path;
}
