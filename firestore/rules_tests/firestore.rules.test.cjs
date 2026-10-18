/**
 * Emulator test untuk firestore.rules.draft (S0).
 *
 * Fokus utama (review Muse): aturan `updatedAt == request.time` harus
 * terbukti DITERIMA saat klien memakai FieldValue.serverTimestamp() dan
 * DITOLAK saat memakai Timestamp jam device / tanpa updatedAt.
 *
 * Cara jalan (lihat docs/firestore-migration/README.md):
 *   cd firestore/rules_tests
 *   npm install firebase @firebase/rules-unit-testing
 *   npx --yes firebase-tools@15 emulators:exec --only firestore --project demo-nousen-rules "node firestore.rules.test.cjs"
 */
const fs = require('fs');
const path = require('path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-nousen-rules';

async function main() {
  const rules = fs.readFileSync(
    path.join(__dirname, '..', '..', 'firestore.rules.draft'),
    'utf8',
  );
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });

  const alice = testEnv.authenticatedContext('alice').firestore();
  const bob = testEnv.authenticatedContext('bob').firestore();
  const anon = testEnv.unauthenticatedContext().firestore();

  const results = [];
  async function check(name, fn) {
    try {
      await fn();
      results.push([name, true, '']);
    } catch (e) {
      results.push([name, false, e && e.message ? e.message : String(e)]);
    }
  }

  const activityDoc = (db, uid, id) => doc(db, `users/${uid}/activities/${id}`);
  const alive = (id) => ({
    id,
    title: 'Tes',
    deleted: false,
    updatedAt: serverTimestamp(),
  });

  // Seed dokumen untuk test read/update/delete (lewati rules).
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice/activities/a1'), {
      id: 'a1',
      title: 'Seed',
      deleted: false,
      updatedAt: Timestamp.now(),
    });
  });

  // --- akses membaca ---
  await check('owner bisa READ koleksi sendiri', () =>
    assertSucceeds(getDoc(activityDoc(alice, 'alice', 'a1'))));

  await check('user lain TIDAK bisa READ koleksi alice', () =>
    assertFails(getDoc(activityDoc(bob, 'alice', 'a1'))));

  await check('anonim TIDAK bisa READ', () =>
    assertFails(getDoc(activityDoc(anon, 'alice', 'a1'))));

  // --- inti: updatedAt == request.time ---
  await check(
    'CREATE + FieldValue.serverTimestamp() -> DITERIMA (updatedAt == request.time)',
    () => assertSucceeds(setDoc(activityDoc(alice, 'alice', 'a2'), alive('a2'))),
  );

  await check('CREATE tanpa updatedAt -> DITOLAK', () =>
    assertFails(
      setDoc(activityDoc(alice, 'alice', 'a3'), {
        id: 'a3',
        title: 'x',
        deleted: false,
      }),
    ));

  await check(
    'CREATE dengan Timestamp jam device -> DITOLAK (anti clock-spoof)',
    () =>
      assertFails(
        setDoc(activityDoc(alice, 'alice', 'a4'), {
          id: 'a4',
          title: 'x',
          deleted: false,
          updatedAt: Timestamp.now(),
        }),
      ),
  );

  await check('CREATE dengan deleted: true -> DITOLAK', () =>
    assertFails(
      setDoc(activityDoc(alice, 'alice', 'a5'), {
        id: 'a5',
        title: 'x',
        deleted: true,
        updatedAt: serverTimestamp(),
      }),
    ));

  await check('CREATE dengan id != docId -> DITOLAK', () =>
    assertFails(
      setDoc(activityDoc(alice, 'alice', 'a6'), {
        id: 'LAIN',
        title: 'x',
        deleted: false,
        updatedAt: serverTimestamp(),
      }),
    ));

  await check('UPDATE owner + serverTimestamp() -> DITERIMA', () =>
    assertSucceeds(
      updateDoc(activityDoc(alice, 'alice', 'a2'), {
        title: 'Baru',
        updatedAt: serverTimestamp(),
      }),
    ));

  await check('UPDATE tanpa updatedAt -> DITOLAK', () =>
    assertFails(updateDoc(activityDoc(alice, 'alice', 'a2'), { title: 'Lagi' })));

  await check('TOMBSTONE (deleted: true + serverTimestamp) -> DITERIMA', () =>
    assertSucceeds(
      setDoc(
        activityDoc(alice, 'alice', 'a2'),
        {
          deleted: true,
          deletedAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        },
        { merge: true },
      ),
    ));

  await check('HARD DELETE -> DITOLAK (wajib tombstone)', () =>
    assertFails(deleteDoc(activityDoc(alice, 'alice', 'a1'))));

  await check('user lain TIDAK bisa WRITE ke koleksi alice', () =>
    assertFails(setDoc(activityDoc(bob, 'alice', 'a7'), alive('a7'))));

  await check('anonim TIDAK bisa WRITE', () =>
    assertFails(setDoc(activityDoc(anon, 'alice', 'a8'), alive('a8'))));

  // --- koleksi lain memakai kontrak sama ---
  await check('owner CREATE progress + serverTimestamp() -> DITERIMA', () =>
    assertSucceeds(
      setDoc(doc(alice, 'users/alice/progress/p1'), {
        id: 'p1',
        deleted: false,
        updatedAt: serverTimestamp(),
      }),
    ));

  await check('owner CREATE reminders + serverTimestamp() -> DITERIMA', () =>
    assertSucceeds(
      setDoc(doc(alice, 'users/alice/reminders/r1'), {
        id: 'r1',
        deleted: false,
        updatedAt: serverTimestamp(),
      }),
    ));

  await check('owner CREATE agendaNotes + serverTimestamp() -> DITERIMA', () =>
    assertSucceeds(
      setDoc(doc(alice, 'users/alice/agendaNotes/n1'), {
        id: 'n1',
        deleted: false,
        updatedAt: serverTimestamp(),
      }),
    ));

  await check("settings/app CREATE + serverTimestamp() -> DITERIMA", () =>
    assertSucceeds(
      setDoc(doc(alice, 'users/alice/settings/app'), {
        id: 'app',
        localeCode: 'id',
        deleted: false,
        updatedAt: serverTimestamp(),
      }),
    ));

  await check("settings doc selain 'app' -> DITOLAK", () =>
    assertFails(
      setDoc(doc(alice, 'users/alice/settings/other'), {
        id: 'other',
        localeCode: 'id',
        deleted: false,
        updatedAt: serverTimestamp(),
      }),
    ));

  await testEnv.cleanup();

  let failed = 0;
  for (const [name, ok, err] of results) {
    console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${ok ? '' : `  -> ${err}`}`);
    if (!ok) failed++;
  }
  console.log(`\n${results.length - failed}/${results.length} checks passed`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('FATAL', e);
  process.exit(2);
});
