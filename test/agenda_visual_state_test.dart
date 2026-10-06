import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_visual_state.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';

void main() {
  group('resolveAgendaVisualState', () {
    test('upcoming sebelum jam mulai (kasus titid 08:30 vs 11:00)', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 4, 8, 30)),
        AgendaVisualState.upcoming,
      );
    });

    test('ongoing setelah jam mulai tanpa jam selesai', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 4, 11, 30)),
        AgendaVisualState.ongoing,
      );
    });

    test('ongoing di antara jam mulai dan selesai', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        scheduledEndAt: DateTime(2026, 10, 4, 12),
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 4, 11, 30)),
        AgendaVisualState.ongoing,
      );
    });

    test('missed setelah jam selesai lewat tanpa diselesaikan', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        scheduledEndAt: DateTime(2026, 10, 4, 12),
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 4, 12, 30)),
        AgendaVisualState.missed,
      );
    });

    test('missed keesokan hari tanpa jam selesai', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 5, 8)),
        AgendaVisualState.missed,
      );
    });

    test('done selalu menang tanpa peduli waktu', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        isCompleted: true,
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 6, 8)),
        AgendaVisualState.done,
      );
    });

    test('induk selesai tapi sub kurang bukan done', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        scheduledEndAt: DateTime(2026, 10, 4, 12),
        isCompleted: true,
        subActivities: const <String>['a', 'b'],
        completedSubActivities: const <String>['a'],
      );

      // Masih dalam rentang jam → ongoing, bukan done.
      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 4, 11, 30)),
        AgendaVisualState.ongoing,
      );
    });

    test('induk + semua sub selesai baru done', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        isCompleted: true,
        subActivities: const <String>['a'],
        completedSubActivities: const <String>['a'],
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 6, 8)),
        AgendaVisualState.done,
      );
    });

    test('dilewati (skip) mengalahkan status waktu', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        isSkipped: true,
      );

      expect(
        resolveAgendaVisualState(item, DateTime(2026, 10, 4, 12)),
        AgendaVisualState.skipped,
      );
    });
  });

  group('buildAgendaMilestones', () {
    test('tonggak dibuat dan dijadwalkan selalu ada', () {
      final OneTimeReminderModel item = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
      );

      final List<AgendaMilestone> milestones = buildAgendaMilestones(
        item,
        now: DateTime(2026, 10, 3, 8),
        idLabel: true,
      );

      expect(milestones.length, 2);
      expect(milestones[0].label, 'Dibuat');
      expect(milestones[1].label, 'Dijadwalkan');
      expect(milestones[1].done, isFalse);
    });

    test('tonggak selesai hanya bila benar selesai', () {
      final OneTimeReminderModel open = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
      );
      final OneTimeReminderModel done = _reminder(
        scheduledAt: DateTime(2026, 10, 4, 11),
        isCompleted: true,
      );

      expect(
        buildAgendaMilestones(
          open,
          now: DateTime(2026, 10, 6, 8),
          idLabel: true,
        ).length,
        2,
      );
      final List<AgendaMilestone> doneMilestones = buildAgendaMilestones(
        done,
        now: DateTime(2026, 10, 6, 8),
        idLabel: true,
      );
      expect(doneMilestones.length, 3);
      expect(doneMilestones.last.label, 'Selesai');
      expect(doneMilestones.last.done, isTrue);
    });
  });
  group('resolveAgendaProgressPercent', () {
    test('tanpa sub mengikuti induk saja', () {
      expect(
        resolveAgendaProgressPercent(
          _reminder(
            scheduledAt: DateTime(2026, 10, 4, 11),
          ),
        ),
        0,
      );
      expect(
        resolveAgendaProgressPercent(
          _reminder(
            scheduledAt: DateTime(2026, 10, 4, 11),
            isCompleted: true,
          ),
        ),
        100,
      );
    });

    test('satu sub selesai tanpa induk = 50%', () {
      expect(
        resolveAgendaProgressPercent(
          _reminder(
            scheduledAt: DateTime(2026, 10, 4, 11),
            subActivities: const <String>['a'],
            completedSubActivities: const <String>['a'],
          ),
        ),
        50,
      );
    });

    test('induk + semua sub selesai = 100%', () {
      expect(
        resolveAgendaProgressPercent(
          _reminder(
            scheduledAt: DateTime(2026, 10, 4, 11),
            isCompleted: true,
            subActivities: const <String>['a', 'b'],
            completedSubActivities: const <String>['a', 'b'],
          ),
        ),
        100,
      );
    });
  });
}

OneTimeReminderModel _reminder({
  required DateTime scheduledAt,
  DateTime? scheduledEndAt,
  bool isCompleted = false,
  bool isSkipped = false,
  List<String> subActivities = const <String>[],
  List<String> completedSubActivities = const <String>[],
}) {
  final DateTime now = DateTime(2026, 10, 4, 8);
  return OneTimeReminderModel(
    id: 'reminder-1',
    title: 'titid',
    iconKey: 'calendar',
    scheduledAt: scheduledAt,
    scheduledEndAt: scheduledEndAt,
    preReminderMinutes: 0,
    isNotificationEnabled: true,
    subActivities: subActivities,
    completedSubActivities: completedSubActivities,
    isCompleted: isCompleted,
    isSkipped: isSkipped,
    createdAt: now,
    updatedAt: now,
  );
}
