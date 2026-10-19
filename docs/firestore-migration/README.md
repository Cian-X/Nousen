# Migrasi Firestore — Catatan S0 (tooling + draft)

Status: **S0 tereksekusi (temuan QC ronde 1 & 2 diperbaiki, §12); S1 dikerjakan — cloud-first + mirror Isar untuk build uji device owner (§13). Belum di-deploy; flag produksi masih mati (aktivasi S1 hanya build-time, khusus APK owner).**
Semua artefak di bawah adalah draft lokal untuk review; tidak ada deploy,
tidak ada perubahan data produksi, tidak ada aktivasi flag di produksi.

## 1. Apa yang ada di S0

| Artefak | File | Fungsi |
| --- | --- | --- |
| Feature flag | `lib/core/migration/migration_flags.dart` | `MigrationFlags` (default SEMUA mati) + `pickCloudFirst` |
| Wiring provider | `lib/app/providers.dart` | `migrationFlagsProvider`; `activityRepositoryProvider` bercabang flag |
| Repo cloud-first | `lib/features/activity/data/cloud_first_activity_repository.dart` | Firestore primer + tombstone + server timestamp + **mirror Isar best-effort (S1)** (khusus activities) |
| Backend cloud (seam) | `lib/features/activity/data/cloud_activities_backend.dart` | `CloudActivitiesBackend` + impl Firestore — repo cloud-first bisa dites tanpa Firebase asli (S1) |
| Backfill | `lib/features/migration/**` | `BackfillService`, sink Firestore, source Isar, checkpoint, mappers |
| Rules draft | `firestore.rules.draft` | Draft rules skema v2 (belum deploy) |
| Indexes draft | `firestore.indexes.json` | Draft composite indexes (belum deploy) |
| Config CLI | `firebase.json` | Menunjuk rules ke `firestore.rules.draft` + port emulator |
| Emulator test | `firestore/rules_tests/` | 19 check rules + 20 ronde konkurensi 2-client (create-if-absent) di Firestore Emulator |
| Tes unit | `test/migration_flags_test.dart`, `test/backfill_service_test.dart`, `test/cloud_first_activity_repository_test.dart`, `test/s1_cloud_first_wiring_test.dart` | 15 tes S0 (flag + backfill full-rescan) + 16 tes S1 (CRUD/mirror cloud-first, wiring provider, aktivasi build) |

`firestore.rules` (rules lama) **tidak diubah** — file itu tetap referensi
aturan yang berlaku sekarang.

## 2. Feature flag

- Default: `MigrationFlags.disabled` → `activityRepositoryProvider` mengembalikan
  `DualWriteActivityRepository` persis seperti sebelumnya. Tidak ada perubahan
  perilaku produksi.
- Uji coba (dev/test saja):
  ```dart
  ProviderScope(
    overrides: [
      migrationFlagsProvider.overrideWithValue(
        const MigrationFlags(cloudFirstActivities: true),
      ),
    ],
    child: const NousenApp(),
  )
  ```
- Dengan flag hidup: login Firebase wajib (uid null → `StateError`, tidak ada
  fallback senyap). Dokumen lama tanpa field `deleted` TIDAK muncul di query —
  jalankan backfill dulu (bagian 3).
- Aktivasi build-time (S1 — APK uji device owner; **tidak** mengubah default):
  ```bash
  flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true
  ```
  Tanpa define, `MigrationFlags.fromEnvironment` identik dengan
  `MigrationFlags.disabled` (semua mati). Rollback = pasang APK tanpa define
  (atau APK lama) — data selama S1 sudah ada di mirror Isar. Detail §13.

## 3. Backfill Isar → Firestore

Sifat yang dijanjikan (dan diuji):

- **Idempoten & bebas race** — tiap dokumen ditulis lewat SATU operasi atomik
  `createDoc` (create-if-absent; transaksi di Firestore); dokumen cloud yang
  sudah ada dilewati (`skippedExisting`), tidak pernah ditimpa. Dua device
  yang backfill bersamaan aman — diuji unit + di emulator dengan dua client
  nyata (§6).
- **Full rescan tiap run** — tidak ada baris yang dilewati berdasarkan
  `isarId`: setiap run memverifikasi SEMUA baris lokal lewat `createDoc`,
  sehingga baris baru yang muncul terlambat di bawah kursor checkpoint lama
  tetap tertangkap (temuan QC ronde 2; trade-off biaya di §12 butir 4).
  Crash kapan pun → rerun = verifikasi ulang penuh; isarId duplikat aman
  (dedup via `docId`, bukan `isarId`). Checkpoint tetap menyimpan kursor
  `lastIsarId` + status `done` ke `BackfillCheckpointStore` (produksi:
  `<appDocuments>/migration/backfill_checkpoint.json`) sebagai informasi
  progres kumulatif — bukan penentu skip.
- **Tanpa login = batal** — uid null → berhenti tanpa tulis apa pun.
- **Checkpoint per uid** — checkpoint uid lain diabaikan (mulai dari nol).
- **Urutan** — `settings → activities → reminders → agendaNotes → progress`,
  baris urut `isarId` menaik. Counter di laporan bersifat **kumulatif**
  (termasuk nilai checkpoint yang di-restore).

Contoh pemakaian (dari harness dev — TIDAK ada pemanggilan otomatis di
aplikasi):

```dart
final report = await BackfillService(
  sink: FirestoreBackfillSink(
    firestore: FirebaseFirestore.instance,
    uid: FirebaseAuth.instance.currentUser?.uid,
  ),
  source: IsarBackfillLocalSource(isar),
  checkpoints: FileBackfillCheckpointStore(
    baseDirectoryProvider: getApplicationDocumentsDirectory,
  ),
  log: debugPrint,
).run();
```

Reset: hapus file `migration/backfill_checkpoint.json` di app documents.
Jangan jalankan terhadap data produksi sampai ada instruksi eksplisit.

## 4. Rules draft — kontrak skema v2

`firestore.rules.draft` memberlakukan:

1. Owner-only (`request.auth.uid == uid`) untuk `users/{uid}/activities|progress|reminders|agendaNotes|settings`.
2. **Setiap create/update wajib `updatedAt == request.time`** — artinya klien
   harus menulis `FieldValue.serverTimestamp()`. Timestamp jam device DITOLAK
   (anti clock-spoof), tanpa `updatedAt` DITOLAK.
3. Hard delete DILARANG; hapus = tombstone `{deleted: true, deletedAt: serverTimestamp()}`.
4. Create wajib `deleted: false` dan `id` == doc id (settings hanya `app`).
5. Default deny untuk semua path lain (termasuk dashboard admin).

**Peringatan sequencing:** klien lama (dual-write) menulis `updatedAt` string
ISO → akan TERTOLAK. Deploy rules hanya setelah semua device memakai klien
cloud-first (S2/S3), bukan sebelum.

## 5. Indexes draft

`firestore.indexes.json`: 5 composite index (activities, progress ×2,
reminders, agendaNotes) — semuanya prefix `deleted == false`. Aman
di-deploy kapan pun (tidak mengubah perilaku).

## 6. Verifikasi emulator (hasil nyata)

Dijalankan 2026-10-17 di mesin dev Windows:

```
firestore/rules_tests $ npm install firebase @firebase/rules-unit-testing
repo root $ npx firebase-tools@13 emulators:exec --only firestore \
  --project demo-nousen-rules "node firestore/rules_tests/firestore.rules.test.cjs"
```

Hasil: **19/19 checks PASSED** (emulator `cloud-firestore-emulator v1.19.8`,
tanpa project online — `demo-` prefix = offline). Termasuk yang diminta
reviewer:

- `CREATE + FieldValue.serverTimestamp() → DITERIMA (updatedAt == request.time)` ✅
- `CREATE dengan Timestamp jam device → DITOLAK` ✅ (anti clock-spoof)
- `CREATE tanpa updatedAt → DITOLAK` ✅
- `UPDATE + serverTimestamp() → DITERIMA`; `UPDATE tanpa updatedAt → DITOLAK` ✅
- `TOMBSTONE → DITERIMA`; `HARD DELETE → DITOLAK` ✅
- cross-user & anonim ditolak; `settings/app` boleh, doc id lain ditolak ✅

### Uji konkurensi nyata — 2 client, transaksi create-if-absent (QC ronde 2)

```
repo root $ npx --yes firebase-tools@13 emulators:exec --only firestore \
  --project demo-nousen-rules \
  "node firestore/rules_tests/backfill_concurrency.test.cjs"
```

Dua client SDK Firestore terpisah (context/app terpisah dari
rules-unit-testing → koneksi SDK sendiri-sendiri, uid sama = dua "device")
menjalankan transaksi create-if-absent **bersamaan** pada doc id yang sama
dengan payload berbeda — pola transaksi identik dengan
`FirestoreBackfillSink.createDoc` (Dart): `runTransaction { get → exists? →
set }`, dengan rules `firestore.rules.draft` aktif.

Hasil (2026-10-17): **20/20 ronde PASSED** — tiap ronde tepat satu create
menang (distribusi run ini: A=7, B=13 — menang bergantian, bukan selalu
device yang sama), yang kalah selalu `false` tanpa error (retry otomatis
SDK), create ketiga → `false`, sweep akhir 20/20 dokumen utuh & valid
(`updatedAt` berupa Timestamp server). File:
`firestore/rules_tests/backfill_concurrency.test.cjs`.

Catatan tooling: firebase-tools v15 menuntut **Java 21+**; mesin ini Java 17,
karena itu dipakai **firebase-tools v13** (didukung). Sebelum deploy di
mesin lain, bebas memakai CLI terbaru (deploy tidak butuh emulator/Java).

## 7. Field yang TIDAK ikut backfill (sengaja)

Path file perangkat tidak berguna di device lain dan upload Storage ditunda:

- `progress.photoPaths`, `progress.photoPath` (dan `photoNote` tetap ikut)
- `agendaNotes.photoPaths`
- `settings.profileAvatarPath`

Efek: sampai tahap Storage, foto/avatar tetap lokal per device. Dokumen
cloud hanya membawa metadata.

## 8. Kehilangan field lama (disetujui owner untuk tahap uji coba)

`ActivityEntity` (Isar) sejak awal tidak menyimpan `family`, `tags`,
`duration`, `isAnomali` — backfill TIDAK bisa memulihkannya, dokumen cloud
aktivitas lama akan tanpa field tersebut sampai entri tersebut diedit ulang
lewat app (upsert dari model domain akan mengisinya kembali).

Field lain aman: `isCompleted` progress diwakili via `status` dengan fallback
`'done'` (sama seperti `toDomain`); `hasSeededData` ikut terbawa di dalam
`weeklyRoutineJson` apa adanya; `notificationVibration`/`extraActivitiesNote`
juga berada di dalam JSON itu.

## 9. Rollback & pull-merge — STATUS: BELUM DIRANCANG (di luar S0)

Catatan S1: rollback sementara untuk uji owner tersedia lewat **flag OFF +
mirror Isar** (§13) — aplikasi kembali membaca Isar yang selalu di-mirror
saat flag ON. Pull-merge penuh (cloud → Isar, LWW, tombstone, foto) tetap
belum dirancang.

Reviewer menandai "pull-merge rollback jangan dianggap gratis". Disetujui —
S0 tidak mengimplementasikannya. Yang wajib diputuskan sebelum rollout S2:

- arah merge cloud→Isar saat rollback, LWW memakai **server time**;
- tombstone: jangan hapus data lokal hanya karena cloud bilang deleted;
- path foto lokal tidak ada di cloud — merge tidak boleh menghapus foto;
- rekonsiliasi penjadwalan notifikasi setelah merge harus idempoten.

## 10. Instruksi deploy manual (Aslam)

```bash
# 1. CLI + login (sekali)
npm install -g firebase-tools
firebase login
firebase use nousen-747fb    # atau: firebase use --add

# 2. (disarankan) ulangi emulator test dahulu
cd firestore/rules_tests && npm install firebase @firebase/rules-unit-testing
cd ../..
npx firebase-tools@13 emulators:exec --only firestore --project demo-nousen-rules \
  "node firestore/rules_tests/firestore.rules.test.cjs"

# 3. indexes (aman kapan saja)
firebase deploy --only firestore:indexes

# 4. rules — HANYA setelah semua device memakai klien cloud-first
firebase deploy --only firestore:rules
```

Catatan:

- `firebase.json` saat ini menunjuk `firestore.rules.draft` sebagai rules.
  Setelah review menyetujui, boleh di-rename menjadi `firestore.rules`
  (update juga `firebase.json`) sebelum deploy.
- Rollback rules: simpan salinan rules yang sedang aktif sebelum deploy;
  redeploy salinan itu untuk kembali.
- Jangan deploy rules selama klien lama (dual-write) masih menulis —
  tulisannya akan tertolak.

## 11. Batasan S0 (jujur)

- Cloud-first hanya untuk **activities** (kerangka/reference). Progress,
  reminders, agendaNotes, settings masih jalur lama; flag per entitas
  ditambahkan saat entitasnya dikerjakan.
- `CloudFirstActivityRepository` — **S1 selesai**: seam backend + 12 tes
  unit (CRUD cloud, mirror Isar, jalur error, tanpa login) + 3 tes wiring
  provider; emulator Dart tetap tidak bisa headless (§13.2).
- Belum ada UI/otomasi yang memanggil `BackfillService` — tooling manual.
- Foto/avatar belum di-upload (Storage ditunda, tanpa Blaze).

## 12. QC Hermes (S0) — temuan & perbaikan

Temuan QC (Hermes, 2026-10-17) dan statusnya:

1. **Race backfill** — pola `docExists` lalu `set()` terpisah: dua device
   yang backfill bersamaan bisa sama-sama melihat "belum ada" dan saling
   menimpa. **Diperbaiki**: sink kini hanya punya SATU operasi atomik
   `createDoc` (create-if-absent). Catatan implementasi: `cloud_firestore`
   Dart tidak menyediakan `DocumentReference.create()` (itu admin SDK),
   jadi `FirestoreBackfillSink.createDoc` memakai `runTransaction` (baca +
   tulis satu transaksi, retry otomatis saat konflik) — semantik sama
   dengan `create()`: gagal/tidak menulis bila dokumen sudah ada. Tes
   baru: dua device paralel dengan isi berbeda → dokumen dibuat tepat
   sekali, tidak ada yang ditimpa.
2. **IsarId duplikat vs kursor resume** — baris di bawah kursor dilewati
   tanpa verifikasi sehingga duplikat isarId bisa salah ter-skip, lalu
   entitas ditandai selesai. **Diperbaiki**: kursor disnapshot di awal run;
   baris tepat di kursor diverifikasi ulang lewat `createDoc` (idempoten).
   Tes baru: resume di kursor dengan isarId duplikat.
3. **`package-lock.json` tak terlacak** — `firestore/rules_tests/package.json`
   + `package-lock.json` adalah bagian S0 dan ikut di-commit saat S0
   di-commit; `firestore/rules_tests/node_modules/` sudah masuk `.gitignore`
   (deklarasi di laporan awal kurang lengkap — bukan file nyasar).

### Ronde 2

4. **Resume melewati baris baru di bawah kursor** — strategi ronde 1
   "skip `isarId < lastIsarId`" membuat baris yang muncul terlambat dengan
   id di bawah kursor tidak pernah ter-backfill. **Diperbaiki**: full rescan
   tiap run — TIDAK ada skip berbasis `isarId`; semua baris diverifikasi
   `createDoc` atomik (baris lama = skip terkalkulasi, bukan skip buta).
   Trade-off: biaya satu operasi Firestore (transaksi baca) per baris per
   run — diterima karena skala data personal (ribuan baris) dan correctness
   > kecepatan. Alternatif watermark/count-based ditolak karena tidak
   menjamin (insert+delete bisa saling menyamarkan). Tes unit baru:
   "baris baru muncul DI BAWAH kursor checkpoint → tetap dibuat".
5. **Uji konkurensi wajib emulator nyata (bukan fake sink)** — **Dipenuhi**:
   `firestore/rules_tests/backfill_concurrency.test.cjs` — 2 client SDK
   independen × 20 ronde transaksi create-if-absent bersamaan pada doc id
   yang sama, payload berbeda, rules asli aktif → **20/20 ronde PASSED**
   (satu pemenang, tanpa penimpaan, dokumen akhir valid; lihat §6).
   Catatan jujur: `cloud_firestore` Dart tidak punya implementasi
   desktop/headless (platform: android/ios/macos/web), jadi tidak bisa
   dijalankan headless di mesin ini; invariant yang diuji (transaksi
   create-if-absent) adalah semantik server Firestore yang dipakai
   `FirestoreBackfillSink.createDoc` lewat primitif yang sama
   (`runTransaction`: get → exists? → set). Menjalankan varian Dart penuh
   butuh device Android/iOS/macOS — sisa risiko yang ditandai.

Status alur review: **Kima perbaiki (ronde 1 & 2 selesai) → QC ulang
Hermes → review arsitektur Bang Muse → keputusan owner untuk S1.** Belum
ada commit; belum ada apa pun yang menyentuh produksi.

Owner memberi lampu hijau S1 → S1 dikerjakan (§13): mirror Isar pada
cloud-first + build uji khusus device owner. S1 menunggu QC sebelum
gate 2 hari dijalankan owner.

## 13. S1 — build uji device owner (cloud-first + mirror Isar)

Status: **artefak + tes selesai; APK dibangun; BELUM ada verifikasi runtime
di device; gate 2 hari baru mulai setelah owner memasang APK.**

### 13.1 Perubahan S1 (di atas S0)

QC wiring (temuan Muse) dikonfirmasi benar: kerangka S0 **tidak punya
mirror Isar** — flag ON hanya menulis Firestore. S1 menambahkan:

1. **Mirror Isar di `CloudFirstActivityRepository`** (`mirror:` param):
   - BACA: tetap Firestore-only (authoritative) — mirror tidak pernah
     dipakai untuk baca dan tidak di-refresh oleh baca;
   - TULIS/UPSERT: Firestore dulu (di-await; gagal → rethrow, mirror TIDAK
     ditulis), lalu mirror Isar best-effort (gagal → hanya log, operasi
     yang sudah tersimpan di cloud tidak digagalkan); — **(semantik tulis
     ini digantikan S1b §13.6: operasi tidak lagi menunggu ack server;
     mirror selalu ditulis)**;
   - DELETE: tombstone cloud dulu (tidak pernah hard delete), lalu
     `mirror.delete` — supaya rollback tidak memunculkan entri yang sudah
     dihapus.
2. **Seam `CloudActivitiesBackend`** (`cloud_activities_backend.dart`):
   operasi Firestore (setDoc/query/watch/get) dipindah ke balik interface —
   supaya repository + mirror bisa dites unit tanpa Firebase asli
   (`cloud_firestore` tidak headless di mesin ini).
3. **Aktivasi build-time** `MigrationFlags.fromEnvironment`
   (`--dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true`) — default produksi
   tetap semua mati (§2).
4. **Seam provider** di `providers.dart`: `activityLocalRepositoryProvider`,
   `cloudActivitiesBackendProvider`, `cloudAuthStateProvider` — wiring
   cloud-first bisa dites end-to-end dengan fake.

### 13.2 Hasil verifikasi yang benar-benar dijalankan

| Verifikasi | Perintah | Hasil |
| --- | --- | --- |
| Repo + mirror + wiring + flag (tanpa define) | `flutter test test/cloud_first_activity_repository_test.dart test/s1_cloud_first_wiring_test.dart test/migration_flags_test.dart test/dual_write_activity_test.dart --no-pub` | **28/28 PASSED** |
| Jalur aktivasi dart-define | `flutter test --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true test/migration_flags_test.dart test/s1_cloud_first_wiring_test.dart --no-pub` | **7/7 PASSED** — flag true; provider default (tanpa override) memilih `CloudFirstActivityRepository` |
| Analyze | `flutter analyze` | 64 temuan **pre-existing** (generated Isar, seeder, dll — file lama); **0 di file S1** |
| Build APK | §13.3 | §13.3 |

Hasil nyata S1b (dijalankan 2026-10-18, source S1b belum di-commit):

| Verifikasi | Perintah | Hasil |
| --- | --- | --- |
| Suite fokus S1b (repo offline/status, wiring, widget badge, messages) | `flutter test test/cloud_first_activity_repository_test.dart test/s1_cloud_first_wiring_test.dart test/activity_sync_badge_widget_test.dart test/activity_sync_messages_test.dart test/migration_flags_test.dart test/dual_write_activity_test.dart --no-pub` | **46/46 PASSED** (42 + 4 tes race ack out-of-order — fix QC Hermes, §13.6) |
| Suite penuh | `flutter test --no-pub` | **139 PASSED, 2 GAGAL pre-existing** (`typography_guardrails_test.dart` — sudah gagal sebelum S1b; tidak ada pelanggaran baru dari file S1b) |
| Jalur aktivasi dart-define (S1b) | `flutter test --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true test/migration_flags_test.dart test/s1_cloud_first_wiring_test.dart --no-pub` | **9/9 PASSED** |
| Analyze (S1b) | `flutter analyze` | **64 temuan — sama persis dengan baseline**; 0 di file S1b |
| Build APK S1b | §13.3 (tabel S1b) | 2 APK dibangun, hash tercatat |

Cakupan tes S1 (16 tes baru):
- CRUD: upsert create/update → cloud merge-set skema v2 (`deleted:false`,
  `updatedAt` server timestamp, `clientUpdatedAt` ISO) + mirror ikut;
  delete → tombstone + mirror.delete; baca dari cloud + filter `deleted`;
  `getById` null untuk tombstone/missing.
- Jalur error: cloud gagal → rethrow, mirror tidak ditulis (tidak ada
  partial state); mirror gagal → operasi tetap sukses; tanpa login →
  `StateError`, tidak menyentuh backend/mirror.
- Wiring: flag OFF → `DualWriteActivityRepository` (lama); flag ON →
  cloud-first + mirror hidup lewat provider.

Yang **BELUM** diverifikasi (jujur): runtime device app nyata — login
Firebase produksi, Firestore produksi, dan perilaku lintas-device. Antrean
offline + durability SDK nyata sudah dibuktikan lewat repro emulator
terpisah (§13.6), dan kontrak repository offline/reject sudah ditutup tes
otomatis S1b; E2E app di HP owner tetap wajib manual (§13.5).

### 13.3 APK uji + instalasi owner

Dibangun 2026-10-17 (debug; signing debug keystore mesin ini — sama dengan
signing release repo ini, jadi upgrade di atas build dari mesin yang sama
tidak butuh uninstall):

| Artefak | Flag | Size | SHA256 |
| --- | --- | --- | --- |
| `build/s1-owner-apks/nousen-s1-cloudfirst-debug.apk` | S1 ON | 245.335.517 B (~234 MB) | `750974A85357AAA0DE96A59483DEB8442A6FFB92E6FE30C85319DB76AAC85323` |
| `build/s1-owner-apks/nousen-s1-rollback-debug.apk` | OFF (rollback) | 245.331.789 B (~234 MB) | `196888C1149807747F9B0E777657B9434C9A1AFA9DA4101AC07DC9B0C3A42BEC` |

Build ulang dari source (artefak mentah di `build/app/outputs/flutter-apk/app-debug.apk`):

```bash
flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true   # APK S1 owner
flutter build apk --debug                                                    # APK rollback (flag OFF)
```

Device terdeteksi saat build: **hanya emulator** (`emulator-5554`) — HP
fisik owner TIDAK tersambung, jadi emulator **sengaja tidak diinstal**
(instruksi brief). Langkah install owner:

1. Salin `nousen-s1-cloudfirst-debug.apk` ke HP (USB / file sharing).
2. Buka file di HP → izinkan "install unknown apps" bila diminta.
3. Install **di atas** app yang terpasang (upgrade, data tidak dihapus).
   Bila muncul "App not installed" / signature mismatch: app lama beda
   signing key → JANGAN langsung uninstall (uninstall menghapus data app);
   lapor ke Kima dulu.
4. Buka app → login Firebase seperti biasa → jalankan checklist §13.5.

Rollback: pasang `nousen-s1-rollback-debug.apk` di atas build S1 (upgrade,
tanpa hapus data) → flag OFF → app kembali membaca Isar; data selama S1
tetap ada di mirror.

#### 13.3b APK S1b v2 (offline UX + fix race ack QC — pasang DI ATAS APK S1)

Dibangun 2026-10-18 dari source S1b **setelah fix race ack out-of-order**
(temuan QC Hermes, §13.6); signing sama (debug keystore mesin ini) →
upgrade di atas APK S1 tanpa uninstall:

| Artefak | Flag | Size | SHA256 |
| --- | --- | --- | --- |
| `build/s1b-owner-apks/nousen-s1b2-cloudfirst-debug.apk` | S1 ON | 245.343.338 B (~234 MB) | `02345B8CB31EB8CDEF02192EADD13F6312F7333C9491D787A8479FAA7208842D` |
| `build/s1b-owner-apks/nousen-s1b2-rollback-debug.apk` | OFF (rollback) | 245.343.549 B (~234 MB) | `6C71C05970E2C056AD0A07D2968E576007D989D8F520663C3D4ACB30724F9421` |

**APK v1 (`nousen-s1b-cloudfirst/rollback-debug.apk`) SUPERSEDED — JANGAN
dipasang**: dibangun sebelum fix race ack; Hermes menahan gate sampai race
diperbaiki (sudah diperbaiki + diuji, §13.6).

Langkah owner: pasang `nousen-s1b2-cloudfirst-debug.apk` di atas APK S1 →
jalankan checklist §13.5 (versi baru yang menyertakan uji pending badge +
force-stop). Bila "signature mismatch": jangan uninstall (data hilang) —
lapor dulu.

### 13.4 Perilaku yang harus diekspektasi owner saat S1 ON

- Daftar aktivitas = **isi Firestore** uid login, difilter `deleted == false`
  → hanya dokumen skema v2. Backfill produksi TIDAK dijalankan di S1, jadi
  dokumen lama (dual-write tanpa field `deleted`) belum muncul di daftar;
  entri baru / entri lama yang di-edit ulang lewat app akan muncul.
- Semua tulis (create/edit/delete) masuk cloud + mirror Isar.
- Offline (S1b, §13.6): save/edit/delete **selesai cepat** — UI tidak
  menggantung; entri baru/edit langsung terlihat dari cache lokal.
  - Badge amber (awan panah) di kartu = tulis masih **pending** (belum
    di-ack server = local queue, bukan error);
  - badge hilang = **synced**;
  - badge merah + snackbar = server **menolak** (rules/auth) — non-silent;
  - badge/antrean selamat dari force-stop (persistence SDK).
- Rollback (flag OFF): aplikasi kembali membaca Isar (mirror) — data selama
  S1 tetap ada; entri yang sudah dihapus selama S1 tidak muncul kembali
  walau tombstone belum di-ack saat app ditutup.
- Tanpa login Firebase: operasi activity melempar error (tidak ada fallback
  senyap) — sesuai desain cloud-first.

### 13.5 Checklist manual gate S2 (2 hari, owner)

Ulangi setelah memasang APK S1b (+ build rollback). Langkah:

1. **CRUD online**: buat/edit/hapus beberapa activity → pastikan tampil
   benar; tidak ada badge tersisa setelah beberapa detik (semua synced).
2. **Offline create/edit**: airplane mode → buat atau edit activity →
   tombol simpan harus selesai cepat (tidak menggantung); entri langsung
   terlihat; badge amber muncul di kartu aktivitas tersebut.
3. **Force-stop saat pending**: (masih airplane mode) tutup paksa app dari
   recent apps → buka lagi → entri tetap ada + badge amber tetap muncul.
4. **Reconnect**: nyalakan internet → tunggu beberapa detik → badge amber
   hilang (synced) → cek konsistensi (device lain / Firebase console bila
   tersedia). Tidak ada data hilang.
5. **Offline delete**: airplane mode → hapus satu activity (menu ⋮ →
   Hapus) → konfirmasi cepat, entri langsung hilang (tidak menggantung) →
   reconnect → tetap hilang di console.
6. **Reject server (kalau terjadi)**: bila muncul snackbar "Gagal
   ... ke cloud: ..." + badge merah, catat pesannya (screenshot) — itu
   reject rules/auth yang memang di-surfacekan; jangan diabaikan.
7. **Rollback drill** (akhir): pasang APK rollback → daftar kembali ke
   Isar; entri yang dihapus selama S1 TIDAK muncul kembali; data S1 masih
   ada.
8. Catat setiap error/keanehan (screenshot + waktu) → lapor; jangan klaim
   gate lulus sebelum 2 hari tanpa insiden.

### 13.6 S1b — perbaikan offline UX (Opsi A versi Hermes, 2026-10-18)

Status: **diimplementasikan + tes otomatis hijau (termasuk fix race ack
out-of-order dari QC Hermes); APK v2 dibangun; belum diuji manual di device
owner (checklist §13.5).** Belum di-commit/di-push saat dokumen ini ditulis.

**Akar masalah (investigasi hari-1, terbukti).** Laporan owner "spinner
save menggantung saat airplane mode" berasal dari semantik SDK Firestore:
Future tulis (`set`/`delete`) hanya resolve **setelah ack server**
(`Tasks.await(setTask)` → `SyncEngine.writeMutations` → resolve di
`handleSuccessfulWrite`/`handleRejectedWrite`). S1 meng-`await` penuh
sebelum mirror, sehingga operasi menggantung offline dan mirror Isar
tertunda sampai reconnect. Bukti runtime di emulator (Firestore emulator
`demo-repro`, proyek lokal — bukan produksi): online resolve 1,19 s;
offline PENDING ≥20 s sambil cache sudah `exists=true pending=true
fromCache=true`; resolve +117 ms setelah reconnect; delete serupa (~98 ms
setelah reconnect). Run-2: antrean offline selamat `am force-stop` →
restart → auto-sync; data tidak hilang (hanya UX + keterlambatan mirror).

**Perubahan S1b (hanya jalur flag ON).**

1. `CloudFirstActivityRepository.upsert/delete`: Firestore **diinisiasi**
   tetapi operasi **tidak menunggu ack**; mirror Isar langsung di-await
   (Isar lokal tidak butuh jaringan) → UI tidak pernah menggantung; sync
   berlanjut di antrean SDK saat online.
2. Status tulis per-activity:
   - `pending` (local queue) → metadata snapshot `hasPendingWrites`
     (seam `CloudActivityDoc` + `watchPendingIds()`) — badge amber di
     kartu aktivitas + header detail; durable lintas force-stop/relaunch
     karena persistence SDK;
   - `synced` → tidak pending & tidak gagal (badge hilang — indikator
     normal, tanpa ikon);
   - `failed` (reject server: rules/auth/error saat ack) →
     `ActivitySyncFailures` — snackbar + badge merah dengan pesan; BUKAN
     `catchError` + log senyap.
3. Delete: tombstone cloud non-blocking + `mirror.delete` langsung →
   rollback (flag OFF) tidak resurrect baris yang sudah dihapus, walau
   tombstone belum di-ack. State lokal yang dipertahankan: baris Isar
   dihapus + cloud tombstone `deleted:true` (tidak ada hard delete).
4. `ActivityActions.deleteActivity`: pembersihan progres (jalur
   dual-write, pre-existing await ack) tidak lagi menahan UI — bagian
   lokal tetap dieksekusi, bagian cloud lanjut di background.

**Batas API & kebijakan (jujur).**

- FlutterFire **tidak** menyediakan Future "queued lokal" yang terpisah
  dari ack server; satu-satunya sinyal local-queue adalah
  `hasPendingWrites`. "Queued/pending" di UI berarti "tulis sudah
  diserahkan ke SDK" (diverifikasi lewat metadata) — bukan klaim ack
  lokal palsu, dan TIDAK pernah diklaim "server-confirmed" sebelum ack.
- Retry: transient/offline ditangani otomatis oleh antrean SDK (mutation
  bertahan sampai ack, termasuk lintas force-stop). Reject permanen
  (rules/auth) TIDAK di-retry otomatis — user melihat failed + alasan;
  menyimpan ulang = mengirim ulang. Reject yang diputuskan server saat
  proses app sudah mati tidak bisa direkonstruksi SDK saat app hidup
  kembali (mutation sudah dibuang) → rekonsiliasi penuh = kandidat S2
  (belum dirancang).
- Tradeoff yang diterima: mirror tetap ditulis walau cloud reject
  (local-first). Konsekuensinya rollback sesaat bisa menampilkan entri
  yang cloud tolak — tercatat sebagai keterbatasan gate, bukan sembunyi.

**QC ronde Hermes (2026-10-18) — blocker race ack out-of-order (SUDAH DI-FIX).**

Hermes menahan approval dengan satu temuan yang menyentuh status data:
`_trackAck` memproses tiap ack secara terpisah, sementara status failure
disimpan satu per activity id → **reject lama dari operasi yang sudah
digantikan bisa menampilkan `failed` padahal versi terbaru sudah synced**;
sebaliknya, ack sukses lama bisa membersihkan `failed` milik operasi
terbaru (save/save maupun save/delete). Arah risiko: badge/snackbar yang
menyesatkan (status cloud tidak sesuai kenyataan), bukan korupsi data.

Fix: korelasi per-attempt di `CloudFirstActivityRepository` —
`_writeAttempts[activityId]` naik monoton di tiap operasi tulis
(upsert/delete); ack/reject hanya diterapkan bila attempt-nya masih yang
TERBARU untuk activity itu; hasil stale diabaikan (log debug). Empat tes
out-of-order baru di `cloud_first_activity_repository_test.dart` (fake
backend dengan gate per-set):

1. reject lama TIDAK menimpa ack sukses operasi terbaru;
2. ack sukses lama TIDAK membersihkan reject operasi terbaru;
3. reject edit lama tidak muncul setelah delete terbaru;
4. reject delete terbaru tetap tercatat walau ack edit lama telat sukses.

Bukti: sebelum fix 4/4 GAGAL (repro race nyata di fake backend yang
mengontrol urutan ack); sesudah fix 4/4 lulus; suite fokus **46/46**;
suite penuh **139 lulus** (2 gagal pre-existing); analyze **64 = baseline**
(`cacheExtent` di `home_shell_page.dart` juga ada di baseline pra-S1).
APK dibangun ulang (v2 — tabel §13.3b). Commit/push tetap ditahan.

**File S1b.** `cloud_first_activity_repository.dart` (inti),
`cloud_activities_backend.dart` (+`CloudActivityDoc`),
`activity_sync_failures.dart` (baru), `activity_sync_badge.dart` (baru),
`activity_sync_messages.dart` (baru), `providers.dart`,
`activity_actions.dart`, `home_shell_page.dart`, `activity_detail_page.dart`.

**Tes S1b.** `cloud_first_activity_repository_test.dart` (offline ack
menggantung → selesai cepat + mirror segera; reject → failed + event;
ack sukses → sembuh; delete pending → mirror langsung terhapus/rollback
tidak resurrect), `s1_cloud_first_wiring_test.dart` (pending ids +
failures terhubung provider; flag OFF tidak aktif), widget badge,
messages. Lihat §13.2 tabel untuk hasil perintah nyata saat build S1b.

---

## 14. S2 — progress cloud-first + tombol logout (2026-10-18)

Status: **diimplementasikan + 37 tes baru hijau (termasuk fix gap
delete-reject activity-scoped dari QC Hermes dan fix bug uji device
logout→login §14.6); analyze 64 = baseline; commit S2 + script APK
sudah dibuat owner (`167ab74`, `baf740a`); fix §14.6 masih di working
tree; verifikasi runtime device = checklist §14.5.**

### 14.1 Perubahan S2 (hanya jalur flag progress ON + tile logout)

1. `CloudFirstProgressRepository` (baru) — progress cloud-first saat
   `NOUSEN_CLOUD_FIRST_PROGRESS=true`, simetris S1b:
   - BACA: selalu Firestore (authoritative) via seam `CloudProgressBackend`;
     `watchByActivity`/`watchByDate`/`watchByDateRange`/`getAll` = filter
     client-side dari satu stream `watchAll(uid)`; pending ids dibaca dari
     metadata snapshot (`hasPendingWrites`).
   - UPSERT: `backend.setDoc` **diinisiasi tanpa menunggu ack server** →
     mirror Isar `upsert` langsung di-await → operasi offline selesai
     instan (tidak menahan UI), sync berlanjut di antrean SDK.
   - DELETE `deleteByActivity`: batch **hard delete** v1 yang sama dengan
     jalur dual-write existing (keputusan audit: tanpa tombstone; tanpa
     perubahan skema/backfill/rules/index) — SDK diinisiasi tanpa await
     ack, mirror `deleteByActivity` langsung.
   - Status tulis: `pending` (metadata) / `synced` (tidak pending) /
     `failed` (reject) — snackbar via `ProgressSyncFailures` (BUKAN log
     senyap) dengan dua cakupan badge: `upsert` → per-entry
     (`ProgressSyncBadge` di baris/header entri); `deleteByActivity` →
     activity-scoped (`ProgressDeleteBadge` di kartu aktivitas + header
     detail — tetap terlihat setelah baris progres lokal terhapus).
   - Korelasi attempt (race ack out-of-order): guard key per entry
     (`entry.id` untuk upsert, `delete-by-activity:<activityId>` untuk
     delete) — ack/reject lama yang bukan attempt terbaru diabaikan.
2. Flag baru `MigrationFlags.cloudFirstProgress` +
   `--dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true`; flag OFF = jalur
   `DualWriteProgressRepository` persis seperti sebelumnya (rollback build).
3. Tombol logout: `SettingsLogoutTile` di section "Pengguna" — memanggil
   `FirebaseAuthService.signOut()` existing dengan spinner + error
   non-silent (snackbar, tombol bisa dicoba lagi); sukses → AuthGate
   (stream sesi memancarkan null) kembali ke halaman login. Tanpa
   redesign auth.
4. `CloudSyncIndicator` disembunyikan bila repo progress bukan dual-write
   (flag ON) — indikator global last-write digantikan badge per-entry +
   badge activity-scoped untuk kegagalan delete.
5. AuthGate: jalur restore/syncUp tetap hanya untuk repo dual-write
   (perilaku S1b). Seam tes baru: `cloudProgressBackendProvider`,
   `progressLocalRepositoryProvider`, `progressSyncFailuresProvider`,
   `cloudFirstProgressRepositoryProvider`, `progressPendingIdsProvider`,
   `firebaseAvailabilityProvider` (AuthGate testable tanpa Firebase statis).

### 14.2 Batasan (jujur)

- Skema progress tetap **v1** (reuse `FirestoreProgressRepository.toMap/
  fromMap`): tanpa `deleted`/tombstone untuk progress. Dokumen hasil
  dual-write existing sudah kompatibel → tidak ada backfill.
- `deleteByActivity` offline hanya menghapus dokumen yang sudah dikenal
  cache SDK saat batch dijalankan; dokumen yang belum pernah di-fetch di
  device bisa tertinggal di Firestore (perilaku batch = jalur dual-write;
  rekonsiliasi penuh kandidat tahap berikutnya).
- Reject yang diputuskan server saat proses app sudah mati tidak bisa
  direkonstruksi SDK saat app hidup kembali (mutation sudah dibuang) —
  batas sama dengan S1b §13.6.
- Flag ON membaca dari cloud: entri Isar lokal yang belum pernah masuk
  cloud tidak tampil; tidak ada push/backfill otomatis di S2.
- Kegagalan `upsert` terlihat per-entry (badge di baris/header entri);
  kegagalan `deleteByActivity` terlihat activity-scoped
  (`ProgressSyncFailures.byActivity` → badge merah di kartu aktivitas +
  header detail) — tetap terlihat setelah baris progres lokal terhapus.
  Batas jujur: `deleteByActivity` hanya dipanggil dari alur hapus
  aktivitas, jadi badge itu tampil bila baris aktivitasnya masih ada
  (mis. tombstone aktivitas ikut ditolak sehingga barisnya muncul lagi);
  pada kasus jarang "aktivitas sudah terhapus tapi batch progres ditolak",
  kanal yang tersisa = snackbar + pelacak in-session (tidak ada baris
  yang bisa ditempeli badge).
- Mirror tetap ditulis walau cloud reject (local-first, konsisten S1b).

### 14.3 Hasil verifikasi (dijalankan 2026-10-18; fix §14.6 di working tree di atas commit owner)

| Verifikasi | Perintah | Hasil |
| --- | --- | --- |
| Suite fokus S2 + regresi S1b/dual-write (11 file) | `flutter test test/cloud_first_progress_repository_test.dart test/cloud_first_progress_wiring_test.dart test/progress_sync_badge_widget_test.dart test/progress_sync_messages_test.dart test/settings_logout_test.dart test/migration_flags_test.dart test/dual_write_progress_test.dart test/s1_cloud_first_wiring_test.dart test/cloud_first_activity_repository_test.dart test/activity_sync_badge_widget_test.dart test/activity_sync_messages_test.dart` | **85/85 PASSED** |
| Jalur aktivasi dart-define progress | `flutter test --dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true test/migration_flags_test.dart test/cloud_first_progress_wiring_test.dart` | **9/9 PASSED** — flag true; provider default (tanpa override) memilih `CloudFirstProgressRepository` |
| Kedua flag (S1b + S2) | `flutter test --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true --dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true test/migration_flags_test.dart test/s1_cloud_first_wiring_test.dart test/cloud_first_progress_wiring_test.dart` | **14/14 PASSED** |
| Suite penuh | `flutter test` | **176 PASSED, 2 GAGAL pre-existing** (`typography_guardrails_test.dart` — sama seperti baseline S1b) |
| Analyze | `flutter analyze` | **64 temuan — sama persis dengan baseline**; 0 di file S2 |
| Whitespace | `git diff --check` | bersih |
| APK uji owner | `build-apk-s2.bat` (owner; KEDUA define ON) | dibangun owner 2026-10-18 20:49 → device test menemukan bug logout→login (§14.6); fix sudah di working tree, APK perlu di-rebuild untuk retest |

Cakupan 37 tes baru S2 (termasuk 3 tes fix bug device §14.6):

- `cloud_first_progress_repository_test.dart` (20): upsert non-blocking +
  mirror langsung walau ack menggantung (offline); reject save → failed
  per-entry + event; ack sukses → sembuh; race save/save tidak saling
  menimpa (guard key); delete non-blocking + mirror langsung terhapus;
  reject delete → failure activity-scoped TETAP tercatat setelah baris
  mirror terhapus (byEntry tidak tercampur) + event; retry delete sukses →
  status dibersihkan; race delete/delete dua arah (reject lama diabaikan,
  ack lama tidak membersihkan reject terbaru); pending ids dari metadata;
  watch terfilter (activity/date/range); getAll; getByActivityAndDate;
  tanpa login → `StateError`; mirror gagal tidak melempar; ganti sesi
  (logout→login) → `watchAll` + `watchPendingIds` re-subscribe ke uid
  baru (fix §14.6).
- `cloud_first_activity_repository_test.dart` (+1, S1b): ganti sesi →
  `watchAll` re-subscribe ke uid baru (fix §14.6 sama, lintas repo).
- `cloud_first_progress_wiring_test.dart` (5): default build mengikuti
  dart-define; flag ON → repo cloud-first + tulis cloud & mirror lewat
  provider; flag OFF → dual-write lokal-only, repo cloud-first null,
  pending ids tidak aktif.
- `progress_sync_badge_widget_test.dart` (5): badge entri — pending milik
  entry → ikon awan-upload; entry lain/null → tanpa ikon; reject → ikon
  merah + tooltip pesan; failed menang atas pending, clear → kembali
  pending, synced → tanpa ikon. Badge delete activity-scoped — reject
  delete terlihat tanpa baris entri (activity lain bersih), `clearActivity`
  → badge hilang.
- `progress_sync_messages_test.dart` (3): snackbar save/delete id+en,
  tooltip pending/failed.
- `settings_logout_test.dart` (3): tile logout — spinner saat proses,
  error non-silent + retry; alur AuthGate — sesi login → child, signOut
  sukses → kembali ke `LoginPage`.

### 14.4 File S2

Baru: `cloud_first_progress_repository.dart`, `cloud_progress_backend.dart`,
`progress_sync_failures.dart`, `progress_sync_badge.dart`,
`progress_sync_messages.dart`, `settings_logout_tile.dart` + 5 file tes
(§14.3). Diubah: `providers.dart`, `migration_flags.dart`,
`home_shell_page.dart`, `activity_detail_page.dart`,
`cloud_sync_indicator.dart`, `login_page.dart`, `settings_page.dart`,
`migration_flags_test.dart`.

Fix §14.6 (working tree di atas commit owner `167ab74`/`baf740a`,
hanya jalur flag ON): `cloud_first_activity_repository.dart`,
`cloud_first_progress_repository.dart`,
`cloud_first_activity_repository_test.dart`,
`cloud_first_progress_repository_test.dart`.

### 14.5 Checklist verifikasi manual owner (device)

1. Bangun APK uji dari working tree:
   `flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true`
   (opsional tambah `--dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true`;
   tanpa define = build rollback).
2. Airplane mode → ubah progress entri (status/sub/notes/foto): simpan
   selesai instan (tidak menggantung); badge awan-upload (pending) muncul
   di kartu/header detail.
3. Force-stop app lalu buka lagi (masih offline): badge pending masih ada
   (antrean SDK durable lintas restart); data tampil dari cache cloud.
4. Online → badge pending hilang sendiri setelah ack (synced, tanpa aksi).
5. Cek console Firestore: `users/{uid}/progress/{entryId}` berisi field
   v1 (status/subCompleted/completedSubActivities/updatedAt/dll.).
6. Race: ubah entri dua kali cepat (offline → online) → setelah sync,
   status yang tampil = versi TERBARU, bukan reject/ack lama.
7. Hapus aktivitas berprogress saat offline → UI tidak menggantung;
   setelah online, dokumen progress ikut terhapus di Firestore (dokumen
   yang dikenal cache). Bila batch delete ditolak server (mis. rules/auth)
   → snackbar error + badge merah (awan silang) di kartu/header aktivitas
   yang tampil kembali; hapus ulang setelah penyebabnya beres → badge
   hilang (retry sukses membersihkan status).
8. Logout: Settings → Pengguna → "Keluar" → spinner singkat → halaman
   login; login Google ulang berhasil. Gagal → snackbar error terlihat +
   bisa dicoba lagi.
9. Setelah login ulang (item 8): cek/uncek progres + buat aktivitas baru
   harus tampil langsung (fix §14.6 — sebelumnya beku karena listen
   cloud lama mati saat logout). Bila masih beku: force-stop lalu buka
   lagi — bila data yang tadi ditulis MUNCUL, artinya tulis sukses dan
   sisa masalah murni sisi baca; lapor ke sesi ini.
10. Rollback: pasang build tanpa define → `CloudSyncIndicator` global
    kembali tampil dan perilaku dual-write lama utuh.

### 14.6 Fix bug uji device owner (2026-10-18, pasca-APK 20:49)

Gejala (laporan owner, build §14.5 item 1 dengan KEDUA define ON):
setelah **logout → login**, tidak bisa ceklist/unceklist progres,
tidak bisa membuat aktivitas, dan badge pending awan "pindah-pindah".

#### 14.6.1 Percobaan fix #1 — re-subscribe dengan `asyncExpand` (GUGUR di device)

Semua stream baca dibuat ulang setiap `CloudAuthState.uidChanges()`
berubah (`.distinct().asyncExpand`); uid null → emisi kosong (stream
tetap hidup). Perilaku lama dijaga: watch tanpa login tetap `StateError`.
Jalur dual-write (flag OFF) tidak berubah.

**Hasil uji device: GUGUR.** APK diagnostic (SHA256 `326D91F6…`) →
logout→login tetap beku. Logcat (`build/phone_logcat_repro.txt`): `uid=`
tercetak **sekali** per stream — 0× `uid=null`, 0× listen ulang, 6×
`listen ERROR [cloud_firestore/permission-denied]` saat logout tanpa
pemulihan. Writes tetap ACK (jalur tulis baca uid per operasi) tapi
reads beku selamanya — persis keluhan owner.

#### 14.6.2 Akar masalah #2 (final): `asyncExpand` mem-pause source sesi

`asyncExpand` (Dart SDK) memanggil `subscription.pause()` pada source dan
baru `resume()` saat stream konversi **selesai**. `snapshots()` Firestore
**tidak pernah selesai** → setelah uid pertama, source `uidChanges`
ter-pause permanen → event logout/login tidak pernah diproses →
re-subscribe #1 no-op. Tes #1 lolos karena fake mengembalikan
`Stream.value(...)` (selesai seketika → pause/resume jalan) — stream
nyata tidak. Navigasi UI tetap jalan karena AuthGate memakai subscription
terpisah ke `authStateChanges()`.

#### 14.6.3 Fix final: switch manual (bukan `asyncExpand`)

Kedua repo: `_sessionStream` diganti switch manual — `StreamController` +
`.listen()` langsung ke `uidChanges().distinct()` yang **tidak pernah
di-pause**; tiap uid baru → batalkan listen lama, buka listen baru; uid
null → batalkan listen + emisi kosong; error listen diteruskan; buka
listen dibungkus `try/catch` (perilaku sama dengan `asyncExpand`). Trace
`[cloudfirst-*]` (`uid=`, `listen DATA/ERROR/DONE`) dipertahankan —
konsisten dengan trace `mirror Isar SYNCED`/`cloud ACK` yang sudah ada.

Tes diperkuat: `_FakeBackend.keepWatchOpen` — stream watch yang TIDAK
selesai (pola `snapshots()`), dipakai tes ganti sesi. **Terbukti GAGAL di
kode `asyncExpand`** (`Expected: empty / Actual: [data lama]`) dan lolos
di switch manual; tes juga meng-assert listen lama dibatalkan (0 listen
zombie) + listen baru tetap hidup (snapshot lanjutan mengalir).

#### 14.6.4 Verifikasi device (build SHA256 `EE187CDB…`)

Logcat `build/phone_logcat_fix.txt` (HP OPPO `8a2b6a45`, kedua define ON,
`flutter build apk --debug --dart-define=NOUSEN_CLOUD_FIRST_ACTIVITIES=true
--dart-define=NOUSEN_CLOUD_FIRST_PROGRESS=true`):

- Cold start 23:36:47: 6 stream `uid=5fqT…` + `listen DATA`.
- Siklus owner 23:37:20→28: **`uid=null` ×6** lalu **`uid=5fqT…` ×6**
  (listen dibuat ulang) → ceklist + buat aktivitas jalan (ACK 23:37:47–52).
- Siklus kedua 23:40:04→23:41:06: idem; home kembali 8/8.
- Uncheck→check "Mandi" (assistant): UI flip 7/8→8/8, ACK ~0,25 dtk,
  badge pending muncul lalu bersih.
- **0× `listen ERROR`** sepanjang sesi (build lama: 6× permission-denied).

Suite: tes ganti-sesi 3/3 (yang sebelumnya gagal di `asyncExpand`), suite
fokus 2 file 43/43, suite penuh 176 PASS (2 gagal pre-existing
`typography_guardrails_test`), analyze 64 = baseline.

#### 14.6.5 Badge pending: grace 2 detik (umpan balik owner, build `2E880477…`)

Owner: badge amber muncul-hilang sekejap saat online — secara data benar
(in-flight ACK ~0,1–0,2 dtk) tapi membingungkan; ekspektasi owner: badge =
penanda "belum sampai cloud" (offline/lambat). Fix UX: `pendingIdsWithGrace`
(`providers.dart`) — badge hanya tampil bila `hasPendingWrites` bertahan
LEBIH LAMA dari `pendingBadgeGrace` (2 dtk). Online normal → 0 kedip;
offline/lambat → tampil dan bertahan sampai ACK. Memakai durasi, bukan
deteksi sinyal jaringan langsung (WiFi tanpa internet tetap terlihat
"online"; `hasPendingWrites` yang bertahan adalah sinyal nyata).
Tes: `test/pending_ids_grace_test.dart` (5 kasus: ACK cepat tidak tampil,
pending > grace tampil, ACK setelah tampil langsung hilang, per-id, error).
Suite penuh 181 PASS (2 gagal pre-existing), analyze 64 = baseline.
Owner setelah uji di HP: "udah aman".

### 14.7 Rollback S2

- Build flag OFF (tanpa define) → `progressRepositoryProvider` kembali ke
  `DualWriteProgressRepository` (jalur produksi lama); tidak ada
  perubahan skema/rules/data → tanpa undo.
- Tombol logout tidak bergantung flag (tampil bila Firebase tersedia);
  rollback logout = revert `settings_logout_tile.dart` + `settings_page.dart`
  + blok AuthGate di `login_page.dart`.
- Fix §14.6 hanya menyentuh repo cloud-first (aktif saat flag ON); tidak
  perlu undo terpisah — build flag OFF tidak memakai kode itu.
