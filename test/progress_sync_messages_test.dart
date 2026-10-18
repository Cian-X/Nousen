import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/presentation/progress_sync_messages.dart';

ProgressSyncFailure _failure(ProgressSyncOperation operation) {
  return ProgressSyncFailure(
    id: 'p1',
    operation: operation,
    message: 'boom',
    at: DateTime(2026, 10, 18),
  );
}

void main() {
  group('ProgressSyncMessages (S2)', () {
    test('snackbar save id/en', () {
      expect(
        progressSyncFailureSnackMessage(
          isId: true,
          failure: _failure(ProgressSyncOperation.save),
        ),
        'Gagal simpan progres ke cloud: boom',
      );
      expect(
        progressSyncFailureSnackMessage(
          isId: false,
          failure: _failure(ProgressSyncOperation.save),
        ),
        'Failed to save progress to cloud: boom',
      );
    });

    test('snackbar delete id/en', () {
      expect(
        progressSyncFailureSnackMessage(
          isId: true,
          failure: _failure(ProgressSyncOperation.delete),
        ),
        'Gagal hapus progres ke cloud: boom',
      );
      expect(
        progressSyncFailureSnackMessage(
          isId: false,
          failure: _failure(ProgressSyncOperation.delete),
        ),
        'Failed to delete progress to cloud: boom',
      );
    });

    test('tooltip pending & failed', () {
      expect(progressSyncPendingTooltip(isId: true), contains('Menunggu'));
      expect(
        progressSyncPendingTooltip(isId: false),
        'Waiting to sync progress to cloud',
      );
      expect(
        progressSyncFailureTooltip(isId: false, reason: 'boom'),
        'Cloud progress sync failed: boom',
      );
      expect(
        progressSyncFailureTooltip(isId: true, reason: 'boom'),
        'Gagal sinkron progres ke cloud: boom',
      );
    });
  });
}
