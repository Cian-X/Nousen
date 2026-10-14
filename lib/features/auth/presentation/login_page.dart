import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/activity/data/dual_write_activity_repository.dart';
import 'package:nousen/features/progress/data/dual_write_progress_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_service.dart';
import 'package:nousen/services/firebase/firebase_bootstrap.dart';

/// Layar login Google. Ditampilkan hanya bila Firebase terkonfigurasi
/// dan belum ada sesi. Tanpa Firebase: app langsung masuk (mode lokal).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      // Sukses: authStateChanges memicu gate ke app. Batal: diam.
    } on GoogleSignInCancelled {
      // Batal oleh pengguna: bukan error, kembali idle tanpa pesan.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Login gagal (${e.code}), coba lagi.');
    } catch (e) {
      setState(() => _error = 'Login gagal, coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'NOUSEN',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk menyinkronkan progres antar perangkat.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B7BD6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sign in with Google',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gerbang sesi: tanpa Firebase → langsung app (mode lokal, perilaku lama);
/// dengan Firebase → tunggu sesi, belum login → [LoginPage].
/// Setelah login → restore cloud → baru tampilkan app.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  /// UID yang terakhir berhasil di-restore, agar tidak restore ulang
  /// di rebuild yang sama (misalnya rotasi layar).
  String? _restoredForUid;
  bool _restoring = false;
  String? _restoreError;

  Future<void> _doRestore(String uid) async {
    if (_restoredForUid == uid) return;
    setState(() {
      _restoring = true;
      _restoreError = null;
    });
    try {
      // 1. Restore activities dari cloud → lokal.
      final activityRepo = ref.read(activityRepositoryProvider);
      if (activityRepo is DualWriteActivityRepository) {
        final int aCount = await activityRepo.restoreFromCloud();
        debugPrint('[authgate] activity restore: $aCount entry');
        // 2. Push aktivitas lokal yang belum ada di cloud.
        final int aPushed = await activityRepo.syncUpExisting();
        debugPrint('[authgate] activity sync up: $aPushed pushed');
      }

      // 3. Restore progress dari cloud → lokal.
      final progressRepo = ref.read(progressRepositoryProvider);
      if (progressRepo is DualWriteProgressRepository) {
        final int pCount = await progressRepo.restoreFromCloud();
        debugPrint('[authgate] progress restore: $pCount entry');
        // 4. Push progress lokal yang belum ada di cloud.
        final int pPushed = await progressRepo.syncUpExisting();
        debugPrint('[authgate] progress sync up: $pPushed pushed');
      }

      _restoredForUid = uid;
    } catch (e) {
      debugPrint('[authgate] restore error: $e');
      _restoredForUid = uid;
      _restoreError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isAvailable) {
      return widget.child;
    }
    final AsyncValue<User?> session = ref.watch(firebaseAuthStateProvider);
    return session.when(
      data: (User? user) {
        if (user == null) {
          // Reset restore state saat logout.
          _restoredForUid = null;
          return const LoginPage();
        }
        if (_restoring) {
          return const _CloudRestoreView();
        }
        if (_restoredForUid != user.uid) {
          // Trigger restore sekali setelah login.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _doRestore(user.uid);
          });
          return const _CloudRestoreView();
        }
        return widget.child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => widget.child,
    );
  }
}

/// Loading screen saat restore cloud → lokal.
class _CloudRestoreView extends StatelessWidget {
  const _CloudRestoreView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              'Menyinkronkan data…',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mengambil progres dari cloud',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
