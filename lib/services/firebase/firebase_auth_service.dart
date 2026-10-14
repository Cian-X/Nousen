import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nousen/services/firebase/firebase_bootstrap.dart';

/// Dibuang saat Firebase belum dikonfigurasi (tanpa google-services.json).
class FirebaseNotConfigured implements Exception {
  const FirebaseNotConfigured();

  @override
  String toString() =>
      'Firebase belum dikonfigurasi di build ini (tanpa google-services.json).';
}

/// Dibuang saat pengguna membatalkan dialog Google Sign-In.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Layanan autentikasi Firebase + Google Sign-In.
///
/// Semua metode memeriksa [FirebaseBootstrap.isAvailable] lebih dulu,
/// sehingga aman dipanggil pada build tanpa konfigurasi Firebase
/// (melempar [FirebaseNotConfigured], bukan crash native).
class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? signIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _signIn = signIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _signIn;

  void _requireAvailable() {
    if (!FirebaseBootstrap.isAvailable) {
      throw const FirebaseNotConfigured();
    }
  }

  /// Stream sesi: null = logout; non-null = login.
  /// Dipakai UI untuk pemulihan state sesi saat app dibuka.
  Stream<User?> authStateChanges() {
    _requireAvailable();
    return _auth.authStateChanges();
  }

  /// Pengguna aktif saat ini, null bila belum login.
  User? get currentUser {
    if (!FirebaseBootstrap.isAvailable) {
      return null;
    }
    return _auth.currentUser;
  }

  /// Login Google. Melempar [GoogleSignInCancelled] bila pengguna batal,
  /// [FirebaseNotConfigured] bila Firebase belum siap.
  Future<UserCredential> signInWithGoogle() async {
    _requireAvailable();
    try {
      await _signIn.initialize();
    } catch (e) {
      debugPrint('[firebase-auth] google init gagal: $e');
      rethrow;
    }
    GoogleSignInAccount account;
    try {
      account = await _signIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelled();
      }
      rethrow;
    }
    final GoogleSignInAuthentication googleAuth = account.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[firebase-auth] signIn gagal: ${e.code}');
      rethrow;
    }
  }

  /// Logout dari Firebase dan Google (agar dialog akun muncul lagi).
  Future<void> signOut() async {
    _requireAvailable();
    await _signIn.signOut();
    await _auth.signOut();
  }
}
