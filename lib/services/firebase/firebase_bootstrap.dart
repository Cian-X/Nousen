import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Hasil inisialisasi Firebase yang aman untuk dijalankan tanpa konfigurasi.
///
/// Tanpa `google-services.json` / `GoogleService-Info.plist` (mis. sebelum
/// project Firebase disediakan owner), [Firebase.initializeApp] melempar.
/// Fungsi ini menangkapnya sehingga aplikasi tetap jalan dengan fitur
/// Firebase nonaktif; panggil [isAvailable] sebelum memakai Auth/Firestore.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _available = false;

  /// true bila Firebase berhasil diinisialisasi pada proses ini.
  static bool get isAvailable => _available;

  static Future<bool> initialize() async {
    if (_available) {
      return true;
    }
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('[firebase] init dilewati (belum dikonfigurasi): $e');
      _available = false;
    }
    return _available;
  }
}
