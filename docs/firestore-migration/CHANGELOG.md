# Changelog & Bug Log — migrasi Firestore Nousen

Dokumen ini mencatat jejak perubahan, bukti uji perangkat, dan bug yang
ditemukan selama fase "beresin online" (cloud-first + rules v2). Untuk
penjelasan teknis lengkap lihat `README.md` §18–§19.

---

## 2026-11-01 — Read-compat v2 (data lama tampil tanpa backfill)

**Commit:** `097d63a` — `feat(cloud-first): read-compat v2 — dokumen tanpa field deleted dianggap hidup`

| Item | Detail |
| --- | --- |
| Perubahan | Query `deleted == false` di server dihapus untuk `activities`, `reminders`, `agendaNotes`; visibility diputuskan di repository (`deleted != true` — field tidak ada = hidup). Progress sudah read-compat sejak `92cf199`. |
| Alasan | Dokumen hasil dual-write v1 (lengkap di Firestore, tanpa field `deleted`) tidak pernah ikut query sehingga data lama "hilang" dari daftar walau datanya ada. |
| Alternatif yang ditolak | Backfill Isar → Firestore (`LoginBackfillCoordinator`). Tidak perlu karena datanya sudah di cloud; menambah proses + risiko tulis ganda. |
| APK uji | `build\app\outputs\flutter-apk\app-prod-debug.apk` (flavor `prod`, 5 flag cloud-first ON), build 2026-11-01 10:27, 223.298.370 B, SHA-256 `22CC9873BBE8169D875ADA8134BB0BAC4E14B87345641A2A570639E44C91A07D` |
| Uji perangkat (owner, 2026-11-01) | **LULUS** — aktivitas lama muncul, progres lama tampil, reminder + catatan agenda lama muncul, edit & hapus normal, tidak ada snackbar/badge merah |
| Tes otomatis | 3 tes read-compat baru (aktivitas, reminder, catatan). Suite terkait 42/42. Full suite **279 PASS**, 2 gagal pre-existing `typography_guardrails_test` |
| Analyzer | 0 error (baseline) |

**Commit pendukung**

| Commit | Isi |
| --- | --- |
| `73691fa` | `docs(migration)`: menandai §19 sudah di-commit — diff hanya 2 baris dokumentasi (README §19 status), sesuai maksud |

Catatan: folder `widgetbook/` (scaffold Flutter tak terpakai) dihapus dari
working tree atas permintaan owner; folder itu tidak pernah masuk commit,
jadi tidak ada commit khusus untuknya.

---

## 2026-10-31 — Progress naik ke skema v2 + deploy rules v2

**Commit:** `92cf199` — `feat(progress): cloud-first progress naik ke skema v2 (serverTimestamp + tombstone)`

| Item | Detail |
| --- | --- |
| Perubahan | `progressCloudDocMap` / `progressTombstoneMap` / `isProgressDocAlive`; `deleteByActivity` jadi batch tombstone (chunk ≤450, tanpa hard delete); semua jalur baca menyembunyikan tombstone; dokumen v1 lawas tetap tampil |
| APK uji | `app-prod-debug.apk`, build 2026-10-31 19:19, 245.578.495 B, SHA-256 `206C030C18B8763679640A3F79AEA2307ACC511BE59EEAB6EBEE14B0E11064DC` |
| Uji perangkat (owner, 2026-10-31) | **LULUS** — ceklist/unchecklist, hapus progres, tambah aktivitas, tanpa PERMISSION_DENIED |
| Tes otomatis | Progress suite 38/38; full suite 276 PASS (+2 pre-existing); emulator rules 23/23 (4 cek baru progress v2) |
| Deploy rules | `firebase deploy --only firestore:rules --project nousen-747fb` pada 2026-10-31T14:49:30Z (21:49 WIB) |
| Ruleset aktif | `projects/nousen-747fb/rulesets/91caafc1-2885-4d67-a3d0-a27f9319e195` — source `firestore.rules.draft` |
| Verifikasi isi rules aktif (2026-11-01) | Dibaca ulang via Firebase Rules API: berisi `deletedAt`, `updatedAt == request.time`, `allow delete: if false` → **v2 benar-benar aktif**, identik dengan `firestore.rules.draft` |

---

## Bug Log

### BUG-001 — Rules v2 menolak tulis progress skema v1 (2026-10-31)

| Field | Isi |
| --- | --- |
| Gejala | Setelah rules v2 di-deploy, simpan progres di HP gagal: snackbar merah "Gagal simpan progres ke cloud" (PERMISSION_DENIED) |
| Akar masalah | `CloudFirstProgressRepository` masih menulis `updatedAt` string ISO dan tanpa field `deleted`; rules v2 mensyaratkan `updatedAt == request.time` dan `deleted == false`, serta melarang hard delete |
| Tindakan darurat | Rollback rules ke versi lawas owner-only (`firestore.rules`, 430 B) pada hari yang sama |
| Perbaikan | Progress dinaikkan ke skema v2 (`92cf199`), APK dipasang + diuji device, baru rules v2 di-deploy ulang |
| Status | **Selesai** — rules v2 aktif, uji device lulus |

### BUG-002 — `flutter build apk` menghasilkan APK basi / gagal senyap (2026-10-31)

| Field | Isi |
| --- | --- |
| Gejala | Build "sukses" tapi `app-debug.apk` tidak berubah (mtime tetap 19 Okt, hash identik); percobaan berikut gagal `Gradle build failed to produce an .apk file` |
| Akar masalah | Sejak S5 project punya product flavor (`prod`, `s5a`, `s5b`); build tanpa `--flavor` mencari `app-debug.apk` yang tidak dihasilkan lagi |
| Perbaikan | Selalu build dengan `--flavor prod` (applicationId `com.nousen.app`) → output `app-prod-debug.apk`; verifikasi mtime + SHA-256 setiap build |
| Status | **Selesai** |

### BUG-003 — Data lama tidak tampil setelah cloud-first ON (2026-10-31)

| Field | Isi |
| --- | --- |
| Gejala | Daftar aktivitas/reminder/catatan kosong walau data ada di HP dan sudah pernah tersinkron |
| Akar masalah | Query cloud-first memfilter `.where('deleted', isEqualTo: false)`; dokumen hasil dual-write v1 tidak punya field `deleted` sehingga tidak pernah masuk hasil query |
| Perbaikan | Read-compat v2 (`097d63a`): filter visibility dipindah ke repository, dokumen tanpa `deleted` = hidup |
| Status | **Selesai** — terverifikasi di perangkat owner 2026-11-01 |

---

## Status akhir fase "beresin online"

| Komponen | Status |
| --- | --- |
| Firestore composite indexes (5) | deployed |
| Rules v2 (owner-only, serverTimestamp + tombstone) | **deployed & aktif** |
| Progress skema v2 | selesai (`92cf199`) |
| Read-compat semua domain | selesai (`097d63a`) |
| Dokumentasi (§18–§19 + file ini) | selesai |
| Uji perangkat owner | lulus (2026-10-31 & 2026-11-01) |
| Push ke `origin/main` | belum (menunggu persetujuan owner) |
| Backfill login-first (S6.0) | tidak dijalankan — tidak diperlukan; tetap tersedia untuk device yang datanya belum pernah ke cloud |
