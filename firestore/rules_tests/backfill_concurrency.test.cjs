/**
 * Emulator integration test — QC ronde 2, blocker 2 (S0 backfill).
 *
 * Create-if-absent ATOMIK di bawah konkurensi NYATA: DUA client Firestore
 * independen (context terpisah dari @firebase/rules-unit-testing → app +
 * koneksi SDK sendiri-sendiri) menjalankan transaksi create-if-absent pada
 * DOC ID YANG SAMA, dimulai bersamaan, dengan payload BERBEDA. Pola
 * transaksinya identik dengan `FirestoreBackfillSink.createDoc` (Dart):
 * runTransaction { get → exists? → set }.
 *
 * Bukan fake sink dan bukan simulasi sinkron: dua client SDK nyata, lewat
 * jaringan ke emulator Firestore lokal, dengan security rules
 * `firestore.rules.draft` aktif (context authenticated sebagai uid yang
 * sama = dua "device" milik user yang sama). TIDAK menyentuh project/data
 * produksi — hanya emulator lokal dengan project `demo-` prefix.
 *
 * Yang diverifikasi per ronde:
 *   1. Tepat SATU transaksi menang (true); yang kalah melaporkan false
 *      tanpa error (SDK retry otomatis setelah konflik/penimpaan gagal).
 *   2. Pemenang tidak ditimpa: isi dokumen akhir = payload pemenang.
 *   3. Percobaan create ketiga (sekuensial) → false, dokumen tidak berubah.
 *   4. Dokumen akhir valid: id sesuai docId, deleted false, updatedAt
 *      berupa Timestamp server.
 *
 * Cara jalan (lihat docs/firestore-migration/README.md §6):
 *   repo root $ npx --yes firebase-tools@13 emulators:exec --only firestore \
 *     --project demo-nousen-rules \
 *     "node firestore/rules_tests/backfill_concurrency.test.cjs"
 */
const fs = require('fs');
const path = require('path');

const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');

const PROJECT_ID = 'demo-nousen-rules';
const UID = 'device-user-backfill';
const ROUNDS = 20;

// Cermin FirestoreBackfillSink.createDoc (Dart): create-if-absent atomik.
async function createDocIfAbsent(db, docPath, payload) {
  return db.runTransaction(async (tx) => {
    const ref = db.doc(docPath);
    const snap = await tx.get(ref);
    if (snap.exists) {
      return false;
    }
    tx.set(ref, payload);
    return true;
  });
}

function payloadFor(docId, deviceLabel) {
  return {
    id: docId,
    title: `dari-device-${deviceLabel}`,
    deleted: false,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  };
}

async function main() {
  const rules = fs.readFileSync(
    path.join(__dirname, '..', '..', 'firestore.rules.draft'),
    'utf8',
  );
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });

  // Dua context terpisah = dua app = dua client SDK independen; keduanya
  // authenticated sebagai uid yang sama (dua "device" satu user).
  const deviceA = testEnv.authenticatedContext(UID).firestore();
  const deviceB = testEnv.authenticatedContext(UID).firestore();

  // Bersihkan sisa run sebelumnya agar ronde selalu mulai dari kondisi
  // "dokumen belum ada" (idempoten untuk dijalankan ulang).
  await testEnv.clearFirestore();

  let failed = 0;
  const wins = { A: 0, B: 0 };
  const expected = new Array(ROUNDS);

  for (let i = 0; i < ROUNDS; i++) {
    const docId = `concurrent-${i}`;
    const docPath = `users/${UID}/activities/${docId}`;
    const fail = (msg) => {
      failed++;
      console.log(`FAIL  ronde ${i}: ${msg}`);
    };

    // Mulai BERSAMAAN (satu tick): dua transaksi create-if-absent.
    const [wonByA, wonByB] = await Promise.all([
      createDocIfAbsent(deviceA, docPath, payloadFor(docId, 'A')),
      createDocIfAbsent(deviceB, docPath, payloadFor(docId, 'B')),
    ]);

    if (typeof wonByA !== 'boolean' || typeof wonByB !== 'boolean') {
      fail(`hasil transaksi bukan boolean (A=${wonByA}, B=${wonByB})`);
      continue;
    }
    const winners = (wonByA ? 1 : 0) + (wonByB ? 1 : 0);
    if (winners !== 1) {
      fail(
        `diharapkan tepat 1 create menang, dapat ${winners} ` +
          `(A=${wonByA}, B=${wonByB})`,
      );
      continue;
    }

    const winnerLabel = wonByA ? 'A' : 'B';
    const loserLabel = wonByA ? 'B' : 'A';
    wins[winnerLabel]++;
    expected[i] = winnerLabel;

    // Pemenang tidak ditimpa: baca ulang dari client LAIN.
    const after = await deviceB.doc(docPath).get();
    const data = after.data();
    if (!data) {
      fail('dokumen akhir tidak ditemukan setelah transaksi');
      continue;
    }
    if (data.title !== `dari-device-${winnerLabel}`) {
      fail(
        `pemenang ${winnerLabel} tapi isi dokumen "${data.title}" ` +
          '(terjadi penimpaan!)',
      );
      continue;
    }

    // Create ketiga (sekuensial, payload device C) → false + utuh.
    const third = await createDocIfAbsent(
      deviceA,
      docPath,
      payloadFor(docId, 'C'),
    );
    if (third !== false) {
      fail(`create ketiga harus false (hasil: ${third})`);
      continue;
    }
    const afterThird = await deviceA.doc(docPath).get();
    if (afterThird.data().title !== `dari-device-${winnerLabel}`) {
      fail('dokumen berubah setelah create ketiga');
      continue;
    }

    console.log(
      `PASS  ronde ${i}: pemenang=${winnerLabel} (kalah=${loserLabel} → false), ` +
        'create ketiga=false, dokumen utuh',
    );
  }

  // Sweep akhir: semua dokumen utuh + valid (bukan hanya tidak berubah).
  let intact = 0;
  for (let i = 0; i < ROUNDS; i++) {
    if (!expected[i]) {
      continue;
    }
    const snap = await deviceA
      .doc(`users/${UID}/activities/concurrent-${i}`)
      .get();
    const data = snap.data() || {};
    const valid =
      data.id === `concurrent-${i}` &&
      data.deleted === false &&
      data.title === `dari-device-${expected[i]}` &&
      data.updatedAt instanceof firebase.firestore.Timestamp &&
      data.updatedAt.toMillis() > 0;
    if (valid) {
      intact++;
    } else {
      failed++;
      console.log(`FAIL  sweep ronde ${i}: dokumen tidak valid / berubah`);
    }
  }

  await testEnv.cleanup();

  console.log(
    `\n${ROUNDS - failed}/${ROUNDS} rounds passed — ` +
      '2 client SDK independen, doc id sama, transaksi create-if-absent ' +
      `bersamaan; menang: A=${wins.A} B=${wins.B}; ` +
      `sweep akhir ${intact}/${ROUNDS} dokumen utuh & valid`,
  );
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('FATAL', e);
  process.exit(2);
});
