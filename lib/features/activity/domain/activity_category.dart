/// Kategori aktivitas wajib dengan ID stabil.
///
/// ID disimpan ke Isar dan dipakai lintas fitur (form, statistik,
/// distribusi kategori). Label UI selalu lewat [labelOf] agar terlokalisasi.
class ActivityCategory {
  const ActivityCategory._();

  static const String work = 'work';
  static const String learning = 'learning';
  static const String health = 'health';
  static const String personal = 'personal';
  static const String other = 'other';

  static const List<String> values = <String>[
    work,
    learning,
    health,
    personal,
    other,
  ];

  static const String defaultId = other;

  static bool isValid(String? id) => values.contains(id);

  /// ID aman untuk dibaca dari data lama yang belum punya kategori.
  static String safeId(String? id) => isValid(id) ? id! : defaultId;

  static String labelOf(String id, String localeCode) {
    final bool isId = localeCode == 'id';
    return switch (safeId(id)) {
      work => isId ? 'Kerja' : 'Work',
      learning => isId ? 'Belajar' : 'Learning',
      health => isId ? 'Kesehatan' : 'Health',
      personal => isId ? 'Pribadi' : 'Personal',
      _ => isId ? 'Lainnya' : 'Other',
    };
  }
}
