/// Entitas yang di-backfill Isar → Firestore (S0).
///
/// Urutan deklarasi = urutan eksekusi backfill (deterministik, dependency
/// dokumen tidak masalah karena Firestore tidak punya FK).
enum BackfillEntityKind {
  settings('settings', 'app'),
  activities('activities', null),
  reminders('reminders', null),
  agendaNotes('agendaNotes', null),
  progress('progress', null);

  const BackfillEntityKind(this.collection, this.fixedDocId);

  /// Nama koleksi Firestore di bawah `users/{uid}/`.
  final String collection;

  /// Doc id tetap (mis. `settings/app`); null berarti doc id = id entitas.
  final String? fixedDocId;
}
