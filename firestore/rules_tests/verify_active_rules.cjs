#!/usr/bin/env node
/**
 * Verifikasi rules Firestore yang SEDANG AKTIF di produksi (bukan asumsi).
 *
 * Membaca kredensial Firebase CLI yang sudah login, meminta access token,
 * lalu mengambil release `cloud.firestore` + ruleset-nya lewat Firebase Rules
 * API. Hasilnya dibandingkan dengan `firestore.rules.draft` di repo supaya
 * jelas versi mana yang sedang berlaku.
 *
 * Pemakaian:
 *   node firestore/rules_tests/verify_active_rules.cjs [projectId]
 *
 * Butuh: sudah `firebase login` dengan akun yang punya akses project.
 * Exit code 0 = rules aktif identik dengan draft lokal; 1 = beda/gagal.
 */
'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const https = require('node:https');
const crypto = require('node:crypto');

const PROJECT_ID = process.argv[2] || 'nousen-747fb';
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const DRAFT_PATH = path.join(REPO_ROOT, 'firestore.rules.draft');

// Client publik milik Firebase CLI (bukan rahasia; dipakai CLI resmi).
const CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function configStoreCandidates() {
  const home = os.homedir();
  return [
    process.env.KIMAKI_FIREBASE_CONFIGSTORE,
    path.join(home, '.config', 'configstore', 'firebase-tools.json'),
    path.join(home, 'AppData', 'Roaming', 'configstore', 'firebase-tools.json'),
  ].filter(Boolean);
}

function readRefreshToken() {
  for (const candidate of configStoreCandidates()) {
    if (!fs.existsSync(candidate)) continue;
    const parsed = JSON.parse(fs.readFileSync(candidate, 'utf8'));
    if (parsed?.tokens?.refresh_token) return parsed.tokens.refresh_token;
  }
  throw new Error(
    'Kredensial Firebase CLI tidak ditemukan. Jalankan `firebase login` dulu.',
  );
}

function request(url, options = {}, body = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let raw = '';
      res.on('data', (chunk) => (raw += chunk));
      res.on('end', () => {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`HTTP ${res.statusCode}: ${raw.slice(0, 300)}`));
          return;
        }
        resolve(JSON.parse(raw));
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function getAccessToken(refreshToken) {
  const form = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: refreshToken,
    grant_type: 'refresh_token',
  }).toString();
  const res = await request(
    'https://oauth2.googleapis.com/token',
    {
      method: 'POST',
      headers: {
        'content-type': 'application/x-www-form-urlencoded',
        'content-length': Buffer.byteLength(form),
      },
    },
    form,
  );
  return res.access_token;
}

function normalize(source) {
  return source.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').trim();
}

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

async function main() {
  const token = await getAccessToken(readRefreshToken());
  const auth = { authorization: `Bearer ${token}` };
  const base = 'https://firebaserules.googleapis.com/v1';

  const release = await request(
    `${base}/projects/${PROJECT_ID}/releases/cloud.firestore`,
    { headers: auth },
  );
  if (!release.rulesetName) {
    throw new Error('Release cloud.firestore belum punya rulesetName.');
  }
  const ruleset = await request(`${base}/${release.rulesetName}`, {
    headers: auth,
  });
  const file = ruleset.source?.files?.[0];
  if (!file?.content) throw new Error('Ruleset aktif tidak berisi source.');

  const deployed = normalize(file.content);
  const localDraft = normalize(fs.readFileSync(DRAFT_PATH, 'utf8'));
  const deployedHash = sha256(deployed);
  const draftHash = sha256(localDraft);

  const markers = {
    'tombstone (deletedAt)': /deletedAt/.test(deployed),
    'server timestamp (request.time)': /request\.time/.test(deployed),
    'hard delete dilarang': /allow delete:\s*if false/.test(deployed),
  };

  console.log(`project          : ${PROJECT_ID}`);
  console.log(`release          : ${release.name}`);
  console.log(`ruleset          : ${release.rulesetName}`);
  console.log(`updateTime       : ${release.updateTime}`);
  console.log(`source file      : ${file.name}`);
  console.log(`deployed lines   : ${deployed.split('\n').length}`);
  console.log(`deployed sha256  : ${deployedHash}`);
  console.log(`draft sha256     : ${draftHash}`);
  console.log(`identik dg draft : ${deployedHash === draftHash}`);
  for (const [label, ok] of Object.entries(markers)) {
    console.log(`marker ${label.padEnd(30)}: ${ok ? 'ADA' : 'TIDAK ADA'}`);
  }

  const problems = [];
  if (deployedHash !== draftHash) problems.push('rules aktif != firestore.rules.draft');
  for (const [label, ok] of Object.entries(markers)) {
    if (!ok) problems.push(`marker v2 hilang: ${label}`);
  }
  if (problems.length > 0) {
    console.error('\nGAGAL:');
    for (const problem of problems) console.error(`- ${problem}`);
    process.exitCode = 1;
    return;
  }
  console.log('\nOK: rules aktif adalah skema v2 dan identik dengan draft lokal.');
}

main().catch((error) => {
  console.error(`GAGAL: ${error.message}`);
  process.exitCode = 1;
});
