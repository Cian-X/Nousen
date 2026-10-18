import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/presentation/activity_sync_messages.dart';

ActivitySyncFailure _failure(ActivitySyncOperation operation) {
  return ActivitySyncFailure(
    activityId: 'a1',
    operation: operation,
    message: 'boom',
    at: DateTime(2026, 10, 18),
  );
}

void main() {
  group('ActivitySyncMessages (S1b)', () {
    test('snackbar save id/en', () {
      expect(
        activitySyncFailureSnackMessage(
          isId: true,
          failure: _failure(ActivitySyncOperation.save),
        ),
        'Gagal simpan ke cloud: boom',
      );
      expect(
        activitySyncFailureSnackMessage(
          isId: false,
          failure: _failure(ActivitySyncOperation.save),
        ),
        'Failed to save to cloud: boom',
      );
    });

    test('snackbar delete id', () {
      expect(
        activitySyncFailureSnackMessage(
          isId: true,
          failure: _failure(ActivitySyncOperation.delete),
        ),
        'Gagal hapus ke cloud: boom',
      );
    });

    test('tooltip pending & failed', () {
      expect(activitySyncPendingTooltip(isId: true), contains('Menunggu'));
      expect(
        activitySyncFailureTooltip(isId: false, reason: 'boom'),
        'Cloud sync failed: boom',
      );
    });
  });
}
