/// Versi logika login-first backfill S6.0.
///
/// Naikkan nilai ini bila semantik/urutan backfill berubah: marker lama
/// dianggap tidak berlaku sehingga user login berikutnya menjalankan ulang
/// full rescan (idempoten).
const int loginBackfillVersion = 1;

/// Marker "backfill sudah selesai untuk uid ini" (login-first).
class BackfillCompletion {
  const BackfillCompletion({
    required this.uid,
    required this.completedAtUtc,
    this.version = loginBackfillVersion,
  });

  final String uid;
  final DateTime completedAtUtc;
  final int version;

  bool matchesVersion(int expectedVersion) => version == expectedVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'completedAt': completedAtUtc.toUtc().toIso8601String(),
      'version': version,
    };
  }

  /// Parse satu entry marker; null bila bentuknya rusak.
  static BackfillCompletion? fromJson(String uid, Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Object? rawCompletedAt = raw['completedAt'];
    final DateTime? completedAt = rawCompletedAt is String
        ? DateTime.tryParse(rawCompletedAt)
        : null;
    final Object? rawVersion = raw['version'];
    if (completedAt == null || rawVersion is! int) {
      return null;
    }
    return BackfillCompletion(
      uid: uid,
      completedAtUtc: completedAt.toUtc(),
      version: rawVersion,
    );
  }
}
