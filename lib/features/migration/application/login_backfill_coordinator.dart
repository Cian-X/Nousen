import 'dart:async';

import 'package:nousen/features/migration/data/backfill_completion_store.dart';
import 'package:nousen/features/migration/data/backfill_models.dart';
import 'package:nousen/features/migration/domain/backfill_completion.dart';

/// Status satu panggilan [LoginBackfillCoordinator.onLogin].
enum LoginBackfillStatus {
  /// Belum login (uid null/kosong) — tidak ada tulis/baca marker.
  skippedNoAuth,

  /// Uid ini sudah menyelesaikan backfill versi saat ini (marker valid).
  skippedCompleted,

  /// Backfill selesai penuh dan marker tersimpan.
  completed,

  /// Backfill tidak selesai / error. Marker TIDAK disimpan; login berikutnya
  /// menjalankan ulang full rescan (idempoten).
  failed,
}

/// Hasil satu panggilan [LoginBackfillCoordinator.onLogin].
class LoginBackfillResult {
  const LoginBackfillResult({
    required this.status,
    this.uid,
    this.report,
    this.error,
  });

  final LoginBackfillStatus status;
  final String? uid;
  final BackfillReport? report;
  final Object? error;

  bool get isCompleted => status == LoginBackfillStatus.completed;
  bool get isFailed => status == LoginBackfillStatus.failed;
}

/// Fungsi backfill per uid (produksi: `BackfillService(...).run`).
typedef BackfillRun = Future<BackfillReport> Function(String uid);

/// Orkestrasi backfill "login-first" S6.0.
///
/// Kontrak:
/// - **Login-first**: dipanggil setelah uid tersedia; uid null/kosong =
///   skip tanpa menyentuh store.
/// - **Idempoten lintas restart**: marker [BackfillCompletion] per uid
///   disimpan oleh [BackfillCompletionStore]; uid yang sudah selesai dengan
///   versi sama dilewati.
/// - **Resumable**: kegagalan di tengah run TIDAK menulis marker. Login
///   berikutnya menjalankan ulang `run` — [BackfillService] memakai
///   create-if-absent + full rescan, jadi aman dan tidak menimpa dokumen.
/// - **Single-flight per uid**: panggilan `onLogin` bersamaan untuk uid yang
///   sama berbagi satu Future; `runBackfill` dipanggil sekali.
/// - **Tidak di-wire** ke provider/main pada S6.0: kode ini belum dipanggil
///   otomatis oleh aplikasi (lihat README §17 gate owner-device).
class LoginBackfillCoordinator {
  LoginBackfillCoordinator({
    required BackfillRun runBackfill,
    required BackfillCompletionStore completions,
    this.version = loginBackfillVersion,
    DateTime Function()? now,
    this.log,
  }) : _runBackfill = runBackfill,
       _completions = completions,
       _now = now ?? DateTime.now;

  final BackfillRun _runBackfill;
  final BackfillCompletionStore _completions;
  final int version;
  final DateTime Function() _now;
  final void Function(String message)? log;

  final Map<String, Future<LoginBackfillResult>> _inFlight =
      <String, Future<LoginBackfillResult>>{};

  /// Dipanggil setiap login. Tidak pernah melempar error: semua kegagalan
  /// dikembalikan sebagai [LoginBackfillStatus.failed] (agar auth gate tidak
  /// ikut gagal hanya karena backfill).
  Future<LoginBackfillResult> onLogin(String? uid) {
    final String? normalized = uid?.trim();
    if (normalized == null || normalized.isEmpty) {
      _emit('[s6] backfill login dilewati: belum login');
      return Future<LoginBackfillResult>.value(
        const LoginBackfillResult(status: LoginBackfillStatus.skippedNoAuth),
      );
    }

    final Future<LoginBackfillResult>? existing = _inFlight[normalized];
    if (existing != null) {
      return existing;
    }

    final Future<LoginBackfillResult> run = _run(normalized);
    _inFlight[normalized] = run;
    unawaited(
      run.whenComplete(() {
        _inFlight.remove(normalized);
      }),
    );
    return run;
  }

  Future<LoginBackfillResult> _run(String uid) async {
    try {
      final BackfillCompletion? saved = await _completions.load(uid);
      if (saved != null && saved.matchesVersion(version)) {
        _emit('[s6] backfill uid=$uid sudah selesai (versi $version)');
        return LoginBackfillResult(
          status: LoginBackfillStatus.skippedCompleted,
          uid: uid,
        );
      }

      final BackfillReport report = await _runBackfill(uid);
      if (report.abortedNoAuth || report.uid != uid || !report.allDone) {
        _emit(
          '[s6] backfill uid=$uid tidak selesai '
          '(uid=${report.uid}, allDone=${report.allDone}) — marker tidak '
          'disimpan',
        );
        return LoginBackfillResult(
          status: LoginBackfillStatus.failed,
          uid: uid,
          report: report,
        );
      }

      await _completions.markCompleted(
        BackfillCompletion(
          uid: uid,
          completedAtUtc: _now().toUtc(),
          version: version,
        ),
      );
      _emit('[s6] backfill uid=$uid selesai; marker disimpan');
      return LoginBackfillResult(
        status: LoginBackfillStatus.completed,
        uid: uid,
        report: report,
      );
    } catch (error) {
      _emit('[s6] backfill uid=$uid gagal: $error');
      return LoginBackfillResult(
        status: LoginBackfillStatus.failed,
        uid: uid,
        error: error,
      );
    }
  }

  void _emit(String message) {
    log?.call(message);
  }
}
