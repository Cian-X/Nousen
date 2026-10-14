import 'package:flutter/material.dart';

/// Kerangka dashboard admin Nousen (Flutter Web).
///
/// Status: skeleton saja. Belum terhubung ke Firebase project mana pun,
/// belum membaca data pengguna, belum ada fitur admin. Firebase project,
/// Auth, dan Firestore rules disiapkan terpisah setelah owner menyediakan
/// akses (lihat brief Firebase). Jangan demo-kan sebagai admin aktif.
void main() {
  runApp(const NousenAdminApp());
}

class NousenAdminApp extends StatelessWidget {
  const NousenAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOUSEN Admin',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B7BD6),
        useMaterial3: true,
      ),
      home: const _AdminPlaceholderPage(),
    );
  }
}

class _AdminPlaceholderPage extends StatelessWidget {
  const _AdminPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NOUSEN Admin')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Kerangka dashboard admin.\n'
            'Menunggu Firebase project + Auth + Firestore rules dari owner\n'
            'sebelum dihubungkan ke data mana pun.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
