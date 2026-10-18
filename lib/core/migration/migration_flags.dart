/// Flag migrasi Firestore cloud-first (tahap S0/S1/S2).
///
/// Kontrak: default SEMUA flag `false` — dengan flag mati seluruh jalur
/// produksi tetap memakai repository lama (Isar / dual-write) persis seperti
/// sebelum migrasi. Ada dua cara mengaktifkan flag untuk uji coba:
/// - `ProviderScope` override (tes/dev);
/// - build-time [fromEnvironment] (S1/S2, APK khusus device owner).
/// Belum ada mekanisme aktivasi jarak jauh.
class MigrationFlags {
  const MigrationFlags({
    this.cloudFirstActivities = false,
    this.cloudFirstProgress = false,
  });

  /// Bila true, `activityRepositoryProvider` memakai repository cloud-first
  /// (Firestore sebagai sumber utama + mirror Isar). Flag per entitas
  /// ditambah saat entitas bersangkutan siap (progress S2; reminders/settings
  /// menyusul).
  final bool cloudFirstActivities;

  /// Bila true (S2), `progressRepositoryProvider` memakai
  /// `CloudFirstProgressRepository` — pola tulis sama dengan S1b activities
  /// (tanpa menunggu ack; mirror Isar segera; status pending/failed
  /// per-entry). Flag OFF = jalur dual-write lama, tidak berubah.
  final bool cloudFirstProgress;

  /// Semua flag mati — perilaku produksi yang berlaku saat ini.
  static const MigrationFlags disabled = MigrationFlags();

  /// Aktivasi build-time (S1/S2 — APK uji khusus device owner):
  ///
  /// ```bash
  /// flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true
  /// flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true
  /// ```
  ///
  /// Tanpa define, semua flag tetap `false` (identik dengan [disabled]) —
  /// build produksi tidak berubah dan tidak ada nilai tersembunyi.
  static const MigrationFlags fromEnvironment = MigrationFlags(
    cloudFirstActivities: bool.fromEnvironment('NOUSEN_CLOUD_FIRST_ACTIVITIES'),
    cloudFirstProgress: bool.fromEnvironment('NOUSEN_CLOUD_FIRST_PROGRESS'),
  );

  /// True bila ada minimal satu jalur cloud-first aktif.
  bool get anyEnabled => cloudFirstActivities || cloudFirstProgress;
}

/// Pilih repository: [cloud] hanya bila [cloudFirst] true, selain itu
/// [fallback] (jalur lama). Fungsi murni supaya logika pemilihan dapat
/// dites tanpa membuka Isar/Firebase.
T pickCloudFirst<T>({
  required bool cloudFirst,
  required T Function() cloud,
  required T Function() fallback,
}) {
  return cloudFirst ? cloud() : fallback();
}
