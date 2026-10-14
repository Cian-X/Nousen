import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Sumber status login minimal untuk dual-write.
///
/// Didefinisikan di sini (bukan mengimpor service Auth fase-1) agar pilot
/// progres tidak bergantung pada branch fitur lain; kedua implementasi
/// disatukan saat branch digabung.
abstract class CloudAuthState {
  /// UID Firebase saat ini, null bila logout / Firebase tak tersedia.
  String? get currentUid;

  /// Berubah setiap login/logout.
  Stream<String?> uidChanges();
}

/// Implementasi Firebase dari [CloudAuthState].
///
/// Tidak memanggil `Firebase.initializeApp` sendiri: bila Firebase belum
/// dikonfigurasi, semua akses dibungkus aman dan UID dibaca null.
class FirebaseCloudAuthState implements CloudAuthState {
  @override
  String? get currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      debugPrint('[dualwrite] baca uid gagal (firebase off?): $e');
      return null;
    }
  }

  @override
  Stream<String?> uidChanges() {
    try {
      return FirebaseAuth.instance
          .authStateChanges()
          .map((user) => user?.uid);
    } catch (_) {
      return Stream<String?>.value(null);
    }
  }
}
