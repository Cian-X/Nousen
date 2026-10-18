import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/activity/domain/activity_repository.dart';
import 'package:nousen/features/auth/presentation/login_page.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/domain/progress_repository.dart';
import 'package:nousen/features/settings/presentation/settings_logout_tile.dart';
import 'package:nousen/services/firebase/firebase_auth_service.dart';

/// Fake [FirebaseAuthService] (implement, bukan extends — konstruktor asli
/// memanggil `FirebaseAuth.instance` yang tidak jalan headless di tes).
class _FakeAuthService implements FirebaseAuthService {
  final StreamController<User?> _authChanges =
      StreamController<User?>.broadcast();

  int signOutCalls = 0;
  Object? signOutError;
  Completer<void>? signOutGate;

  @override
  Stream<User?> authStateChanges() => _authChanges.stream;

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInWithGoogle() async =>
      throw UnsupportedError('signInWithGoogle tidak dipakai di tes ini');

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final Completer<void>? gate = signOutGate;
    if (gate != null) {
      await gate.future;
    }
    final Object? error = signOutError;
    if (error != null) {
      throw error;
    }
    // Perilaku Firebase: stream sesi memancarkan null setelah signOut.
    _authChanges.add(null);
  }

  void emitUser(User? user) => _authChanges.add(user);

  void dispose() {
    _authChanges.close();
  }
}

/// Fake [User]: AuthGate hanya membaca `uid`; sisanya via noSuchMethod
/// (forwarder) supaya tidak perlu menuliskan seluruh antarmuka firebase_auth.
class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('_FakeUser hanya menyediakan uid');
  }
}

class _FakeActivityRepo implements ActivityRepository {
  @override
  Stream<List<ActivityModel>> watchAll() =>
      Stream<List<ActivityModel>>.value(const <ActivityModel>[]);

  @override
  Future<List<ActivityModel>> getAll() async => const <ActivityModel>[];

  @override
  Future<ActivityModel?> getById(String id) async => null;

  @override
  Future<void> upsert(ActivityModel activity) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeProgressRepo implements ProgressRepository {
  @override
  Stream<List<ProgressEntryModel>> watchAll() =>
      Stream<List<ProgressEntryModel>>.value(const <ProgressEntryModel>[]);

  @override
  Stream<List<ProgressEntryModel>> watchByActivity(String activityId) =>
      Stream<List<ProgressEntryModel>>.value(const <ProgressEntryModel>[]);

  @override
  Stream<List<ProgressEntryModel>> watchByDate(String dateKey) =>
      Stream<List<ProgressEntryModel>>.value(const <ProgressEntryModel>[]);

  @override
  Stream<List<ProgressEntryModel>> watchByDateRange({
    required String fromDateKey,
    required String toDateKey,
  }) =>
      Stream<List<ProgressEntryModel>>.value(const <ProgressEntryModel>[]);

  @override
  Future<List<ProgressEntryModel>> getAll() async =>
      const <ProgressEntryModel>[];

  @override
  Future<ProgressEntryModel?> getByActivityAndDate({
    required String activityId,
    required String dateKey,
  }) async =>
      null;

  @override
  Future<void> upsert(ProgressEntryModel entry) async {}

  @override
  Future<void> deleteByActivity(String activityId) async {}
}

void main() {
  group('SettingsLogoutTile (S2)', () {
    late _FakeAuthService service;

    setUp(() {
      service = _FakeAuthService();
      addTearDown(service.dispose);
    });

    Future<void> pumpTile(WidgetTester tester) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            firebaseAuthServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsLogoutTile()),
          ),
        ),
      );
    }

    testWidgets('tap Keluar → signOut dipanggil; spinner tampil saat proses; '
        'kembali idle setelah selesai', (WidgetTester tester) async {
      await pumpTile(tester);

      service.signOutGate = Completer<void>();
      await tester.tap(find.text('Sign out'));
      await tester.pump();

      expect(service.signOutCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.signOutGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('gagal → pesan error terlihat (non-silent) + tombol bisa '
        'dicoba lagi', (WidgetTester tester) async {
      await pumpTile(tester);

      service.signOutError = StateError('firebase off');
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(service.signOutCalls, 1);
      expect(find.textContaining('Sign out failed'), findsOneWidget);
      expect(find.textContaining('firebase off'), findsOneWidget);

      service.signOutError = null;
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(service.signOutCalls, 2);
    });
  });

  group('AuthGate flow (S2 — logout sukses kembali ke LoginPage)', () {
    late _FakeAuthService service;

    setUp(() {
      service = _FakeAuthService();
      addTearDown(service.dispose);
    });

    Future<void> pumpGate(WidgetTester tester) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            firebaseAvailabilityProvider.overrideWithValue(true),
            firebaseAuthServiceProvider.overrideWithValue(service),
            activityRepositoryProvider.overrideWithValue(_FakeActivityRepo()),
            progressRepositoryProvider.overrideWithValue(_FakeProgressRepo()),
          ],
          child: const MaterialApp(
            home: AuthGate(child: Scaffold(body: SettingsLogoutTile())),
          ),
        ),
      );
    }

    testWidgets('sesi login → app; tap Keluar (signOut sukses) → LoginPage', (
      WidgetTester tester,
    ) async {
      await pumpGate(tester);
      await tester.pump();
      // Stream sesi belum memancarkan apa pun → loading (bukan child).
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      service.emitUser(_FakeUser('u1'));
      await tester.pumpAndSettle();
      // Repo bukan dual-write → restore dilewati → child tampil.
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // signOut sukses → authStateChanges null → gate kembali ke LoginPage.
      expect(service.signOutCalls, 1);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
    });
  });
}
