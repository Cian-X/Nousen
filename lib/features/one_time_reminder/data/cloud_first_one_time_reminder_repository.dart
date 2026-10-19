import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nousen/core/utils/activity_icon_utils.dart';
import 'package:nousen/features/activity/domain/activity_category.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_agenda_notes_backend.dart';
import 'package:nousen/features/one_time_reminder/data/cloud_reminders_backend.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_sync_failures.dart';
import 'package:nousen/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_repository.dart';
import 'package:nousen/services/firebase/firebase_auth_state.dart';

/// Repository reminder + catatan agenda cloud-first (S3) — pola sama dengan
/// `CloudFirstProgressRepository` S2.
///
/// Satu repository menaungi dua koleksi karena interface lama
/// [OneTimeReminderRepository] menggabungkan keduanya, sedangkan owner
/// meminta flag terpisah:
/// - [remindersBackend] null  → reminder tetap jalur Isar (flag OFF);
/// - [notesBackend] null      → catatan tetap jalur Isar (flag OFF).
///
/// Path (skema v2, `firestore.rules.draft`):
/// - `/users/{uid}/reminders/{reminderId}`;
/// - `/users/{uid}/agendaNotes/{noteId}`.
///
/// Semantik baca/tulis:
/// - BACA selalu dari Firestore (authoritative, cloud-first). Pengecualian
///   yang disengaja: `AgendaNoteModel.photoPaths` adalah path file perangkat
///   dan TIDAK pernah ditulis ke cloud (README §7); saat membaca di
///   perangkat yang sama, path lokal di-overlay dari mirror Isar supaya foto
///   yang sudah dilampirkan tidak hilang dari UI (tidak ada upload).
/// - TULIS: Firestore DIINISIASI lebih dulu, tetapi penyelesaian operasi
///   TIDAK menunggu ack server (SDK baru resolve/error setelah server
///   menjawab → `await` penuh menggantung saat offline). Mirror Isar
///   di-await segera setelahnya supaya rollback (flag OFF) melihat data
///   terbaru.
/// - Status tulis:
///   - `pending` dari metadata snapshot (`hasPendingWrites`) via
///     [watchReminderPendingIds]/[watchNotePendingIds] — durable lintas
///     force-stop karena persistence SDK;
///   - `failed` (reject server: rules/auth/error lain) dicatat di
///     [OneTimeReminderSyncFailures] agar non-silent (snackbar + badge).
/// - Korelasi per-attempt (guard race ack out-of-order, pola S1b/S2): ack
///   atau reject hanya berlaku untuk operasi TERBARU id tersebut. Guard key
///   reminder dan note dipisah karena id keduanya beda namespace.
/// - LWW: `updatedAt` selalu `FieldValue.serverTimestamp()` — urutan menang
///   ditentukan jam server, bukan jam device (`clientUpdatedAt` hanya
///   audit).
/// - Tanpa login Firebase jalur cloud melempar [StateError] (kontrak yang
///   sama dengan S1b/S2); metode yang delegasi ke mirror tidak melempar.
class CloudFirstOneTimeReminderRepository implements OneTimeReminderRepository {
  CloudFirstOneTimeReminderRepository({
    required CloudAuthState authState,
    OneTimeReminderRepository? mirror,
    CloudRemindersBackend? remindersBackend,
    CloudAgendaNotesBackend? notesBackend,
    OneTimeReminderSyncFailures? failures,
  }) : _authState = authState,
       _mirror = mirror,
       _remindersBackend = remindersBackend,
       _notesBackend = notesBackend,
       _failures = failures ?? OneTimeReminderSyncFailures();

  final CloudAuthState _authState;

  /// Mirror lokal (Isar) untuk jalur rollback dan overlay media lokal;
  /// null = tanpa mirror.
  final OneTimeReminderRepository? _mirror;

  final CloudRemindersBackend? _remindersBackend;
  final CloudAgendaNotesBackend? _notesBackend;

  /// Pelacak kegagalan ack server (dipakai UI via provider).
  final OneTimeReminderSyncFailures _failures;

  /// Operasi tulis terakhir per guard key — dasar korelasi ack/reject
  /// dengan operasi terbaru.
  final Map<String, int> _writeAttempts = <String, int>{};

  static const int schemaVersion = 2;

  /// Prefix guard key agar id reminder dan id note tidak bertabrakan.
  static const String _reminderGuardPrefix = 'reminder:';
  static const String _noteGuardPrefix = 'note:';

  /// Akses pelacak kegagalan (wiring provider/UI).
  OneTimeReminderSyncFailures get failures => _failures;

  bool get remindersCloudEnabled => _remindersBackend != null;

  bool get notesCloudEnabled => _notesBackend != null;

  String get _uid {
    final String? uid = _authState.currentUid;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'CloudFirstOneTimeReminderRepository butuh login Firebase (uid null).',
      );
    }
    return uid;
  }

  // ---------------------------------------------------------------------
  // Skema dokumen (dipakai tulis + tes; satu sumber kontrak)
  // ---------------------------------------------------------------------

  /// Dokumen reminder hidup — field identik dengan backfill S0
  /// (`reminderBackfillMap`), plus `updatedAt` server timestamp.
  static Map<String, dynamic> reminderToMap(OneTimeReminderModel model) {
    return <String, dynamic>{
      'id': model.id,
      'title': model.title,
      'iconKey': normalizeActivityIconKey(model.iconKey),
      'scheduledAt': model.scheduledAt.toIso8601String(),
      'scheduledEndAt': model.scheduledEndAt?.toIso8601String(),
      'categoryId': ActivityCategory.safeId(model.categoryId),
      'description': model.description.trim(),
      'subActivities': _normalizedStrings(model.subActivities),
      'completedSubActivities': _normalizedStrings(
        model.completedSubActivities,
      ),
      'preReminderMinutes': model.preReminderMinutes,
      'isNotificationEnabled': model.isNotificationEnabled,
      'isCompleted': model.isCompleted,
      'isSkipped': model.isSkipped,
      'createdAt': model.createdAt.toIso8601String(),
      'clientUpdatedAt': model.updatedAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
      'deletedAt': null,
      'schemaVersion': schemaVersion,
    };
  }

  /// Tombstone reminder (hard delete dilarang `firestore.rules.draft`).
  static Map<String, dynamic> reminderTombstoneMap(String id) {
    return <String, dynamic>{
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'schemaVersion': schemaVersion,
    };
  }

  static OneTimeReminderModel reminderFromMap(
    Map<String, dynamic> data, {
    String? fallbackId,
  }) {
    final DateTime createdAt = _date(data['createdAt']) ?? DateTime.now();
    return OneTimeReminderModel(
      id: _string(data['id']) ?? fallbackId ?? '',
      title: _string(data['title']) ?? '',
      iconKey: normalizeActivityIconKey(_string(data['iconKey'])),
      scheduledAt: _date(data['scheduledAt']) ?? createdAt,
      scheduledEndAt: _date(data['scheduledEndAt']),
      categoryId: ActivityCategory.safeId(_string(data['categoryId'])),
      description: (_string(data['description']) ?? '').trim(),
      subActivities: _stringList(data['subActivities']),
      completedSubActivities: _stringList(data['completedSubActivities']),
      preReminderMinutes: _int(data['preReminderMinutes']) ?? 0,
      isNotificationEnabled: data['isNotificationEnabled'] == true,
      isCompleted: data['isCompleted'] == true,
      isSkipped: data['isSkipped'] == true,
      createdAt: createdAt,
      updatedAt:
          _date(data['clientUpdatedAt']) ??
          _date(data['updatedAt']) ??
          createdAt,
    );
  }

  /// Dokumen catatan hidup. `photoPaths` sengaja TIDAK ditulis (path file
  /// perangkat; upload Storage belum ada) — lihat README §7/§15.
  static Map<String, dynamic> noteToMap(AgendaNoteModel note) {
    return <String, dynamic>{
      'id': note.id,
      'reminderId': note.reminderId,
      'text': note.text,
      'createdAt': note.createdAt.toIso8601String(),
      'clientUpdatedAt': note.updatedAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
      'deletedAt': null,
      'schemaVersion': schemaVersion,
    };
  }

  /// Tombstone catatan agenda.
  static Map<String, dynamic> noteTombstoneMap(String id) {
    return <String, dynamic>{
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'schemaVersion': schemaVersion,
    };
  }

  static AgendaNoteModel noteFromMap(
    Map<String, dynamic> data, {
    String? fallbackId,
  }) {
    final DateTime createdAt = _date(data['createdAt']) ?? DateTime.now();
    return AgendaNoteModel(
      id: _string(data['id']) ?? fallbackId ?? '',
      reminderId: _string(data['reminderId']) ?? '',
      text: _string(data['text']) ?? '',
      // Selalu kosong dari cloud; di-overlay dari mirror saat membaca.
      photoPaths: const <String>[],
      createdAt: createdAt,
      updatedAt:
          _date(data['clientUpdatedAt']) ??
          _date(data['updatedAt']) ??
          createdAt,
    );
  }

  // ---------------------------------------------------------------------
  // Baca reminder
  // ---------------------------------------------------------------------

  @override
  Stream<List<OneTimeReminderModel>> watchAll() {
    final CloudRemindersBackend? backend = _remindersBackend;
    if (backend == null) {
      return _requireMirror().watchAll();
    }
    return _sessionStream(
      (String uid) => backend.watchVisible(uid).map(_visibleReminders),
      whenLoggedOut: () => const <OneTimeReminderModel>[],
      debugTag: 'watchAll',
    );
  }

  @override
  Future<List<OneTimeReminderModel>> getAll() async {
    final CloudRemindersBackend? backend = _remindersBackend;
    if (backend == null) {
      return _requireMirror().getAll();
    }
    final List<Map<String, dynamic>> docs = await backend.queryVisible(_uid);
    return _modelsFromMaps(docs);
  }

  @override
  Future<OneTimeReminderModel?> getById(String id) async {
    final CloudRemindersBackend? backend = _remindersBackend;
    if (backend == null) {
      return _requireMirror().getById(id);
    }
    final Map<String, dynamic>? data = await backend.getDoc(_uid, id);
    if (data == null || data['deleted'] == true) {
      return null;
    }
    return reminderFromMap(data, fallbackId: id);
  }

  List<OneTimeReminderModel> _visibleReminders(List<CloudReminderDoc> docs) {
    return _modelsFromMaps(
      docs
          .where((CloudReminderDoc doc) => doc.data['deleted'] != true)
          .map((CloudReminderDoc doc) => doc.data),
    );
  }

  List<OneTimeReminderModel> _modelsFromMaps(
    Iterable<Map<String, dynamic>> docs,
  ) {
    final List<OneTimeReminderModel> models = docs
        .map((Map<String, dynamic> data) => reminderFromMap(data))
        .toList();
    models.sort(
      (OneTimeReminderModel a, OneTimeReminderModel b) =>
          a.scheduledAt.compareTo(b.scheduledAt),
    );
    return models;
  }

  // ---------------------------------------------------------------------
  // Tulis reminder
  // ---------------------------------------------------------------------

  @override
  Future<void> upsert(OneTimeReminderModel reminder) async {
    final CloudRemindersBackend? backend = _remindersBackend;
    if (backend == null) {
      return _requireMirror().upsert(reminder);
    }
    final String uid = _uid;
    final String guardKey = '$_reminderGuardPrefix${reminder.id}';
    final int attempt = _registerWrite(guardKey);
    _trackAck(
      backend.setDoc(uid, reminder.id, reminderToMap(reminder)),
      guardKey: guardKey,
      recordId: reminder.id,
      target: OneTimeReminderSyncTarget.reminder,
      attempt: attempt,
      operation: OneTimeReminderSyncOperation.save,
    );
    await _mirrorUpsertReminder(reminder);
  }

  @override
  Future<void> delete(String id) async {
    final CloudRemindersBackend? backend = _remindersBackend;
    if (backend == null) {
      return _requireMirror().delete(id);
    }
    final String uid = _uid;
    final String guardKey = '$_reminderGuardPrefix$id';
    final int attempt = _registerWrite(guardKey);
    _trackAck(
      backend.setDoc(uid, id, reminderTombstoneMap(id)),
      guardKey: guardKey,
      recordId: id,
      target: OneTimeReminderSyncTarget.reminder,
      attempt: attempt,
      operation: OneTimeReminderSyncOperation.delete,
    );
    await _mirrorDeleteReminder(id);
  }

  /// Stream id reminder yang tulisannya masih menunggu ack server
  /// (`hasPendingWrites`), untuk badge pending. Kosong bila flag reminder
  /// OFF.
  Stream<Set<String>> watchReminderPendingIds() {
    final CloudRemindersBackend? backend = _remindersBackend;
    if (backend == null) {
      return Stream<Set<String>>.value(const <String>{});
    }
    return _sessionStream(
      (String uid) =>
          backend.watchVisible(uid).map((List<CloudReminderDoc> docs) {
            return <String>{
              for (final CloudReminderDoc doc in docs)
                if (doc.hasPendingWrites) doc.id,
            };
          }),
      whenLoggedOut: () => const <String>{},
      debugTag: 'watchReminderPendingIds',
    );
  }

  // ---------------------------------------------------------------------
  // Baca catatan
  // ---------------------------------------------------------------------

  @override
  Stream<List<AgendaNoteModel>> watchNotes(String reminderId) {
    final CloudAgendaNotesBackend? backend = _notesBackend;
    if (backend == null) {
      return _requireMirror().watchNotes(reminderId);
    }
    return _sessionStream(
      (String uid) => backend
          .watchVisible(uid)
          .asyncMap(
            (List<CloudAgendaNoteDoc> docs) =>
                _notesWithLocalPhotos(docs, reminderId),
          ),
      whenLoggedOut: () => const <AgendaNoteModel>[],
      debugTag: 'watchNotes',
    );
  }

  /// Filter `reminderId` di klien (satu query kanonik per uid, pola S2),
  /// urut `createdAt` naik (sama dengan Isar `sortByCreatedAt`), lalu
  /// overlay `photoPaths` lokal dari mirror.
  Future<List<AgendaNoteModel>> _notesWithLocalPhotos(
    List<CloudAgendaNoteDoc> docs,
    String reminderId,
  ) async {
    final List<AgendaNoteModel> notes = docs
        .where(
          (CloudAgendaNoteDoc doc) =>
              doc.data['deleted'] != true &&
              doc.data['reminderId'] == reminderId,
        )
        .map(
          (CloudAgendaNoteDoc doc) => noteFromMap(doc.data, fallbackId: doc.id),
        )
        .toList();
    notes.sort(
      (AgendaNoteModel a, AgendaNoteModel b) =>
          a.createdAt.compareTo(b.createdAt),
    );
    if (notes.isEmpty) {
      return notes;
    }
    final Map<String, List<String>> localPhotos = await _localPhotoPaths(
      reminderId,
    );
    if (localPhotos.isEmpty) {
      return notes;
    }
    return notes
        .map(
          (AgendaNoteModel note) => localPhotos.containsKey(note.id)
              ? note.copyWith(photoPaths: localPhotos[note.id])
              : note,
        )
        .toList();
  }

  Future<Map<String, List<String>>> _localPhotoPaths(String reminderId) async {
    final OneTimeReminderRepository? mirror = _mirror;
    if (mirror == null) {
      return const <String, List<String>>{};
    }
    try {
      final List<AgendaNoteModel> local = await mirror
          .watchNotes(reminderId)
          .first;
      return <String, List<String>>{
        for (final AgendaNoteModel note in local)
          if (note.photoPaths.isNotEmpty) note.id: note.photoPaths,
      };
    } catch (error) {
      debugPrint(
        '[cloudfirst-reminder] overlay photoPaths lokal gagal '
        '($reminderId): $error',
      );
      return const <String, List<String>>{};
    }
  }

  // ---------------------------------------------------------------------
  // Tulis catatan
  // ---------------------------------------------------------------------

  @override
  Future<void> upsertNote(AgendaNoteModel note) async {
    final CloudAgendaNotesBackend? backend = _notesBackend;
    if (backend == null) {
      return _requireMirror().upsertNote(note);
    }
    final String uid = _uid;
    final String guardKey = '$_noteGuardPrefix${note.id}';
    final int attempt = _registerWrite(guardKey);
    _trackAck(
      backend.setDoc(uid, note.id, noteToMap(note)),
      guardKey: guardKey,
      recordId: note.id,
      target: OneTimeReminderSyncTarget.note,
      attempt: attempt,
      operation: OneTimeReminderSyncOperation.save,
    );
    // Mirror menyimpan foto lokal (cloud tidak) — dipakai overlay baca.
    await _mirrorUpsertNote(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    final CloudAgendaNotesBackend? backend = _notesBackend;
    if (backend == null) {
      return _requireMirror().deleteNote(id);
    }
    final String uid = _uid;
    final String guardKey = '$_noteGuardPrefix$id';
    final int attempt = _registerWrite(guardKey);
    _trackAck(
      backend.setDoc(uid, id, noteTombstoneMap(id)),
      guardKey: guardKey,
      recordId: id,
      target: OneTimeReminderSyncTarget.note,
      attempt: attempt,
      operation: OneTimeReminderSyncOperation.delete,
    );
    await _mirrorDeleteNote(id);
  }

  /// Stream id catatan yang tulisannya masih menunggu ack server. Kosong
  /// bila flag notes OFF.
  Stream<Set<String>> watchNotePendingIds() {
    final CloudAgendaNotesBackend? backend = _notesBackend;
    if (backend == null) {
      return Stream<Set<String>>.value(const <String>{});
    }
    return _sessionStream(
      (String uid) =>
          backend.watchVisible(uid).map((List<CloudAgendaNoteDoc> docs) {
            return <String>{
              for (final CloudAgendaNoteDoc doc in docs)
                if (doc.hasPendingWrites) doc.id,
            };
          }),
      whenLoggedOut: () => const <String>{},
      debugTag: 'watchNotePendingIds',
    );
  }

  // ---------------------------------------------------------------------
  // Sesi + ack tracking
  // ---------------------------------------------------------------------

  OneTimeReminderRepository _requireMirror() {
    final OneTimeReminderRepository? mirror = _mirror;
    if (mirror == null) {
      throw StateError(
        'CloudFirstOneTimeReminderRepository tanpa mirror Isar untuk jalur '
        'flag OFF.',
      );
    }
    return mirror;
  }

  /// Stream cloud yang reaktif terhadap sesi (pola fix S2).
  ///
  /// Listen Firestore tidak hidup lagi setelah logout→login, jadi listen
  /// dibuat ULANG tiap uid berubah. Sengaja bukan `asyncExpand` (source
  /// ter-pause permanen karena snapshots tidak pernah selesai). Sesi
  /// berakhir → emisi [whenLoggedOut], bukan error, supaya stream hidup
  /// untuk sesi berikutnya.
  Stream<T> _sessionStream<T>(
    Stream<T> Function(String uid) open, {
    required T Function() whenLoggedOut,
    required String debugTag,
  }) {
    // watch tanpa login = StateError (kontrak yang sama dengan S2).
    _uid;
    late final StreamController<T> controller;
    StreamSubscription<T>? inner;
    StreamSubscription<String?>? session;
    var closed = false;

    void emit(T data) {
      if (!closed) {
        controller.add(data);
      }
    }

    void emitError(Object error, StackTrace stackTrace) {
      if (!closed) {
        controller.addError(error, stackTrace);
      }
    }

    void openListen(String uid) {
      Stream<T> next;
      try {
        next = open(uid);
      } catch (error, stackTrace) {
        emitError(error, stackTrace);
        return;
      }
      inner = next.listen(
        (T data) {
          debugPrint('[cloudfirst-reminder] $debugTag listen DATA');
          emit(data);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[cloudfirst-reminder] $debugTag listen ERROR: $error');
          emitError(error, stackTrace);
        },
        onDone: () {
          debugPrint('[cloudfirst-reminder] $debugTag listen DONE');
        },
      );
    }

    void switchSession(String? uid) {
      debugPrint('[cloudfirst-reminder] $debugTag uid=${uid ?? 'null'}');
      final StreamSubscription<T>? previous = inner;
      inner = null;
      if (previous != null) {
        unawaited(previous.cancel());
      }
      if (uid == null || uid.isEmpty) {
        emit(whenLoggedOut());
        return;
      }
      openListen(uid);
    }

    controller = StreamController<T>(
      onListen: () {
        session = _authState.uidChanges().distinct().listen(
          switchSession,
          onError: emitError,
        );
      },
      onCancel: () {
        closed = true;
        unawaited(session?.cancel());
        final StreamSubscription<T>? previous = inner;
        inner = null;
        if (previous != null) {
          unawaited(previous.cancel());
        }
      },
    );
    return controller.stream;
  }

  int _registerWrite(String guardKey) {
    final int next = (_writeAttempts[guardKey] ?? 0) + 1;
    _writeAttempts[guardKey] = next;
    return next;
  }

  /// Pantau ack/reject tanpa memblokir pemanggil; hanya hasil operasi
  /// TERBARU per guard key yang diterapkan (pola S1b/S2).
  void _trackAck(
    Future<void> ack, {
    required String guardKey,
    required String recordId,
    required OneTimeReminderSyncTarget target,
    required int attempt,
    required OneTimeReminderSyncOperation operation,
  }) {
    unawaited(
      ack.then(
        (_) {
          if (_writeAttempts[guardKey] != attempt) {
            debugPrint(
              '[cloudfirst-reminder] ack STALE diabaikan ${operation.name} '
              '${target.name} $recordId (attempt $attempt)',
            );
            return;
          }
          if (target == OneTimeReminderSyncTarget.reminder) {
            _failures.clearReminder(recordId);
          } else {
            _failures.clearNote(recordId);
          }
          debugPrint(
            '[cloudfirst-reminder] cloud ACK ${operation.name} '
            '${target.name} $recordId',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_writeAttempts[guardKey] != attempt) {
            debugPrint(
              '[cloudfirst-reminder] reject STALE diabaikan '
              '${operation.name} ${target.name} $recordId '
              '(attempt $attempt): $error',
            );
            return;
          }
          if (target == OneTimeReminderSyncTarget.reminder) {
            _failures.recordReminder(
              reminderId: recordId,
              operation: operation,
              error: error,
            );
          } else {
            _failures.recordNote(
              noteId: recordId,
              operation: operation,
              error: error,
            );
          }
          debugPrint(
            '[cloudfirst-reminder] cloud FAIL ${operation.name} '
            '${target.name} $recordId: $error',
          );
        },
      ),
    );
  }

  Future<void> _mirrorUpsertReminder(OneTimeReminderModel reminder) async {
    final OneTimeReminderRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.upsert(reminder);
      debugPrint(
        '[cloudfirst-reminder] mirror Isar SYNCED reminder ${reminder.id}',
      );
    } catch (error) {
      debugPrint(
        '[cloudfirst-reminder] mirror Isar FAIL upsert ${reminder.id}: '
        '$error',
      );
    }
  }

  Future<void> _mirrorDeleteReminder(String id) async {
    final OneTimeReminderRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.delete(id);
      debugPrint('[cloudfirst-reminder] mirror Isar DELETE reminder $id');
    } catch (error) {
      debugPrint('[cloudfirst-reminder] mirror Isar FAIL delete $id: $error');
    }
  }

  Future<void> _mirrorUpsertNote(AgendaNoteModel note) async {
    final OneTimeReminderRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.upsertNote(note);
      debugPrint('[cloudfirst-reminder] mirror Isar SYNCED note ${note.id}');
    } catch (error) {
      debugPrint(
        '[cloudfirst-reminder] mirror Isar FAIL upsert note ${note.id}: '
        '$error',
      );
    }
  }

  Future<void> _mirrorDeleteNote(String id) async {
    final OneTimeReminderRepository? mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.deleteNote(id);
      debugPrint('[cloudfirst-reminder] mirror Isar DELETE note $id');
    } catch (error) {
      debugPrint(
        '[cloudfirst-reminder] mirror Isar FAIL delete note $id: $error',
      );
    }
  }
}

List<String> _normalizedStrings(List<String> raw) {
  return raw
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList();
}

List<String> _stringList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return _normalizedStrings(raw.whereType<String>().toList(growable: false));
}

String? _string(Object? raw) {
  if (raw is String) {
    return raw;
  }
  if (raw == null) {
    return null;
  }
  return '$raw';
}

int? _int(Object? raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw.trim());
  }
  return null;
}

DateTime? _date(Object? raw) {
  if (raw is Timestamp) {
    return raw.toDate();
  }
  if (raw is DateTime) {
    return raw;
  }
  if (raw is String) {
    return DateTime.tryParse(raw);
  }
  return null;
}
