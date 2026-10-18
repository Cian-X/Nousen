import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/core/widgets/nousen_nav_icon.dart';

/// Item "Keluar" di halaman Pengaturan (S2).
///
/// Memanggil [FirebaseAuthService.signOut] yang sudah ada — tidak ada alur
/// auth baru. Setelah sukses, `AuthGate` (login_page.dart) otomatis kembali
/// ke `LoginPage` lewat stream `authStateChanges`. Kegagalan (mis. Firebase
/// tak tersedia saat dipanggil) di-surfacekan lewat snackbar — tidak ada
/// logout senyap; tombol bisa dicoba lagi setelah gagal.
class SettingsLogoutTile extends ConsumerStatefulWidget {
  const SettingsLogoutTile({super.key});

  @override
  ConsumerState<SettingsLogoutTile> createState() => _SettingsLogoutTileState();
}

class _SettingsLogoutTileState extends ConsumerState<SettingsLogoutTile> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    try {
      await ref.read(firebaseAuthServiceProvider).signOut();
      // Sukses: tidak ada navigasi manual di sini — AuthGate berpindah ke
      // LoginPage begitu authStateChanges memancarkan null.
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isId ? 'Gagal keluar: $error' : 'Sign out failed: $error',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    final Color color = theme.colorScheme.error;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _busy ? null : _signOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: <Widget>[
              NousenNavIcon(Icons.logout_rounded, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isId ? 'Keluar' : 'Sign out',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                NousenNavIcon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
