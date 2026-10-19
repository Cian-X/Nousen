import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/core/migration/migration_flags.dart';

void main() {
  group('MigrationFlags (S0)', () {
    test('default semua flag mati → perilaku produksi tidak berubah', () {
      const MigrationFlags flags = MigrationFlags();
      expect(flags.cloudFirstActivities, isFalse);
      expect(flags.cloudFirstProgress, isFalse);
      expect(flags.cloudFirstReminders, isFalse);
      expect(flags.cloudFirstNotes, isFalse);
      expect(flags.cloudFirstSettings, isFalse);
      expect(flags.anyEnabled, isFalse);

      expect(MigrationFlags.disabled.cloudFirstActivities, isFalse);
      expect(MigrationFlags.disabled.cloudFirstProgress, isFalse);
      expect(MigrationFlags.disabled.cloudFirstReminders, isFalse);
      expect(MigrationFlags.disabled.cloudFirstNotes, isFalse);
      expect(MigrationFlags.disabled.cloudFirstSettings, isFalse);
      expect(MigrationFlags.disabled.anyEnabled, isFalse);
    });

    test('pickCloudFirst: flag mati memakai fallback (repo lama) dan '
        'tidak mengevaluasi closure cloud', () {
      String evaluated = '';
      final String picked = pickCloudFirst<String>(
        cloudFirst: false,
        cloud: () {
          evaluated = 'cloud';
          return 'cloud';
        },
        fallback: () {
          evaluated = 'fallback';
          return 'fallback';
        },
      );

      expect(picked, 'fallback');
      expect(evaluated, 'fallback');
    });

    test('pickCloudFirst: flag hidup memakai closure cloud', () {
      final String picked = pickCloudFirst<String>(
        cloudFirst: true,
        cloud: () => 'cloud',
        fallback: () => 'fallback',
      );

      expect(picked, 'cloud');
    });
  });

  group('MigrationFlags (S1/S2/S3 — aktivasi build device owner)', () {
    // Dibaca dari dart-define build:
    // - `NOUSEN_CLOUD_FIRST_ACTIVITIES` (S1), `NOUSEN_CLOUD_FIRST_PROGRESS` (S2);
    // - `NOUSEN_CLOUD_FIRST_REMINDERS|NOTES|SETTINGS` (S3);
    // - run biasa (tanpa define) → false → membuktikan default produksi mati;
    // - run verifikasi dengan define `=true` → true → membuktikan jalur
    //   aktivasi APK owner benar-benar menyalakan flag.
    const bool activatedInBuild = bool.fromEnvironment(
      'NOUSEN_CLOUD_FIRST_ACTIVITIES',
    );
    const bool progressActivatedInBuild = bool.fromEnvironment(
      'NOUSEN_CLOUD_FIRST_PROGRESS',
    );
    const bool remindersActivatedInBuild = bool.fromEnvironment(
      'NOUSEN_CLOUD_FIRST_REMINDERS',
    );
    const bool notesActivatedInBuild = bool.fromEnvironment(
      'NOUSEN_CLOUD_FIRST_NOTES',
    );
    const bool settingsActivatedInBuild = bool.fromEnvironment(
      'NOUSEN_CLOUD_FIRST_SETTINGS',
    );

    test('fromEnvironment mengikuti dart-define build', () {
      expect(
        MigrationFlags.fromEnvironment.cloudFirstActivities,
        activatedInBuild,
      );
      expect(
        MigrationFlags.fromEnvironment.cloudFirstProgress,
        progressActivatedInBuild,
      );
      expect(
        MigrationFlags.fromEnvironment.cloudFirstReminders,
        remindersActivatedInBuild,
      );
      expect(
        MigrationFlags.fromEnvironment.cloudFirstNotes,
        notesActivatedInBuild,
      );
      expect(
        MigrationFlags.fromEnvironment.cloudFirstSettings,
        settingsActivatedInBuild,
      );
      expect(
        MigrationFlags.fromEnvironment.anyEnabled,
        activatedInBuild ||
            progressActivatedInBuild ||
            remindersActivatedInBuild ||
            notesActivatedInBuild ||
            settingsActivatedInBuild,
      );
    });
  });
}
