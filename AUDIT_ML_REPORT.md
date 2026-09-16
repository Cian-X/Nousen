# 🔍 Audit ML/AI — Project Nousen (liburan_hebat)
**Tanggal audit:** 15 September 2026  
**Auditor:** Hermes Agent  
**Status:** READ-ONLY (tidak ada kode yang diubah)

---

## 1. Daftar Model ONNX

| # | File ONNX | MlModelKind | Fungsi | Task Type |
|---|-----------|-------------|--------|-----------|
| 1 | `days_model.onnx` | `activityDay` | Prediksi apakah hari ini cocok untuk menambah aktivitas baru | Classification (binary: cocok/tidak_cocok) |
| 2 | `time_model.onnx` | `activityTime` | Prediksi waktu terbaik untuk menambah aktivitas baru | Regression (output: minutes) |
| 3 | `detail_day_model.onnx` | `detailDay` | Prediksi apakah hari ini cocok untuk aktivitas tertentu (di detail page) | Classification (binary: cocok/tidak_cocok) |
| 4 | `detail_time_model.onnx` | `detailTime` | Prediksi waktu ideal untuk aktivitas tertentu (di detail page) | Regression (output: minutes) |
| 5 | `home_model.onnx` | `homeCompletion` | Prediksi apakah aktivitas akan selesai hari ini | Classification (binary: selesai/tidak_selesai) |
| 6 | `statistik_consistent_model.onnx` | `statsConsistency` | Prediksi apakah user konsisten di statistik | Classification (binary: konsisten/kurang_konsisten) |
| 7 | `statistik_slot_model.onnx` | `statsEffectiveSlot` | Prediksi slot waktu paling efektif | Classification (4-class: pagi/siang/sore/malam) |

---

## 2. Detail Tiap Model

### 2.1 Activity Day (`days_model.onnx`)
- **Input features (9):**

| Feature | Tipe | Sumber Data |
|---------|------|-------------|
| `category_enc` | int (encoded) | `SmartActivityAdvisor.mlProfileFor()` → `categoryKey` → LabelEncoder |
| `family_enc` | int (encoded) | `SmartActivityAdvisor.mlProfileFor()` → `familyKey` → LabelEncoder |
| `effort_enc` | int (encoded) | `SmartActivityAdvisor.mlProfileFor()` → `effortLevelKey` → LabelEncoder |
| `recommendedTime` | int (minutes) | User input: `recommendedTimeMinutes` |
| `userWakeUp` | int (minutes) | User setting: jam bangun |
| `userSleep` | int (minutes) | User setting: jam tidur |
| `numWorkdays` | int | Jumlah hari kerja user |
| `avgRoutineStart` | int (minutes) | Rata-rata mulai rutinitas |
| `avgRoutineEnd` | int (minutes) | Rata-rata akhir rutinitas |

- **Preprocessing:** LabelEncoder untuk categorical (family, category, effort). Numerik langsung `.toDouble()`.
- **Output:** Binary label (0=tidak_cocok, 1=cocok) + probability map
- **Algoritma:** Tidak ditemukan (tidak ada training script di project)
- **Dataset:** Synthetic data dari `E:/data_generator/`

### 2.2 Activity Time (`time_model.onnx`)
- **Input features (9):** Sama persis dengan Activity Day
- **Preprocessing:** Sama persis
- **Output:** Single float → di-round ke int → `_normalizePredictedTime()` clamp ke 0–1439, round ke kelipatan 5
- **Algoritma:** Tidak ditemukan
- **Dataset:** Synthetic data

### 2.3 Detail Day (`detail_day_model.onnx`)
- **Input features (10):**

| Feature | Tipe | Sumber Data |
|---------|------|-------------|
| `family_enc` | int (encoded) | Profile atau fallback |
| `category_enc` | int (encoded) | Profile atau fallback |
| `effort_enc` | int (encoded) | Profile atau fallback |
| `todayWeekday` | int (0-6) | `today.weekday - 1` |
| `streak` | int | `breakdown.currentStreak` |
| `completionRate` | double (0-1) | `totalCompleted / totalScheduled` |
| `totalScheduled` | int | Dari breakdown atau entries.length |
| `totalCompleted` | int | Dari breakdown atau entries completed count |
| `isStable` | int (0/1) | `totalScheduled >= 4 && (completionRate >= 0.65 || streak >= 3)` |
| `bestTimeSlot_enc` | int (encoded) | Dihitung dari completion history atau fallback profile |

- **Preprocessing:** LabelEncoder + derived features (`isStable`, `bestTimeSlot`)
- **Output:** Binary label (0=tidak_cocok, 1=cocok)
- **Algoritma:** Tidak ditemukan

### 2.4 Detail Time (`detail_time_model.onnx`)
- **Input features (10):** Sama persis dengan Detail Day
- **Output:** Single float → int minutes → `_normalizePredictedTime()` + `_timeBucketKey()`
- **Algoritma:** Tidak ditemukan

### 2.5 Home Completion (`home_model.onnx`)
- **Input features (9):**

| Feature | Tipe | Sumber Data |
|---------|------|-------------|
| `family_enc` | int (encoded) | Profile lookup |
| `category_enc` | int (encoded) | Profile lookup |
| `effort_enc` | int (encoded) | Profile lookup |
| `weekday` | int | Hari dalam minggu |
| `isWeekend` | int (0/1) | Boolean weekend |
| `streak` | int | Current streak |
| `completionRate` | double (0-1) | Rate |
| `scheduledTime` | int (minutes) | Waktu dijadwalkan |
| `numActivitiesToday` | int | Jumlah aktivitas hari ini |

- **Output:** Binary label (0=tidak_selesai, 1=selesai). Dipakai di home page AI brief.
- **Algoritma:** Tidak ditemukan

### 2.6 Stats Consistency (`statistik_consistent_model.onnx`)
- **Input features (7):**

| Feature | Tipe | Sumber Data |
|---------|------|-------------|
| `family_enc` | int (encoded) | Dominant activity profile |
| `category_enc` | int (encoded) | Dominant activity profile |
| `effort_enc` | int (encoded) | Dominant activity profile |
| `totalScheduled` | int | Stats aggregate |
| `totalCompleted` | int | Stats aggregate |
| `completionRate` | double | Derived |
| `streak` | int | Stats aggregate |

- **Output:** Binary (0=kurang_konsisten, 1=konsisten)
- **Algoritma:** Tidak ditemukan

### 2.7 Stats Effective Slot (`statistik_slot_model.onnx`)
- **Input features (7):** Sama persis dengan Stats Consistency
- **Output:** 4-class (0=pagi, 1=siang, 2=sore, 3=malam). Dinormalisasi ke English keys di `_normalizeSlotKey()`.
- **Algoritma:** Tidak ditemukan

---

## 3. Alur Data

```
User Action (tambah/lihat aktivitas/lihat stats)
    │
    ▼
SmartActivityAdvisor.mlProfileFor(activityTitle)
    │ Match title → activity_profiles.json (1052 lines, ~40+ profiles)
    │ Fallback ke 'umum'/'umum'/'medium' kalau tidak ketemu
    ▼
MlModelEncoderService.load()
    │ Baca model_encoders.json
    │ Encode: family → int, category → int, effort → int, bestTimeSlot → int
    ▼
Feature Vector Construction (di masing-masing ML Service)
    │ Gabungkan encoded features + numerical features
    │ Validasi: featureOrder.length == features.length
    ▼
MlModelSchemaService.schemaFor(kind)
    │ Baca model_schema.json, match key
    │ Validasi input size vs feature count
    ▼
OnnxModelService.sessionFor(kind)
    │ Load ONNX model dari assets/ml_model/
    │ Cache session per MlModelKind
    ▼
ONNX Runtime Inference
    │ Float32 tensor [1, N] → runInference
    │ Classifier: output_label + output_probability
    │ Regressor: variable (single float)
    ▼
Post-processing
    │ Classifier: extract label int → boolean/enum
    │ Regressor: round → normalizePredictedTime (clamp, round to 5)
    │ Stats slot: label → normalizeSlotKey (pagi→morning etc.)
    ▼
Riverpod Provider (FutureProvider.family)
    │ Cache by request equality (immutable request objects)
    ▼
UI Widget
    │ Home: _blendHomeBriefWithMl() → AI Brief card (headline+insight+suggestion)
    │ Activity Form: hybrid suggestion (ML time + SmartAdvisor recommendation)  
    │ Activity Detail: "Hari ini cocok"/"Rekomendasi jam" display
    │ Stats: ⚠️ Provider exists tapi TIDAK dipakai di presentation layer
```

---

## 4. Masalah ML yang Ditemukan

### 🔴 4.1 Training Script Tidak Ditemukan di Project
- Tidak ada file `.py` atau `.ipynb` di dalam repository Flutter
- `E:/data_generator/` hanya berisi **data generator**, bukan training pipeline
- **Implikasi:** Tidak bisa audit algoritma, hyperparameters, evaluation metrics, atau train/test split. Model ONNX adalah "black box" — kita cuma bisa lihat input/output shape-nya.

### 🔴 4.2 CRITICAL: Mismatch Family Taxonomy antara Training Data dan Inference
**Data generator `config.py` pakai family:**
- `olahraga`, `belajar`, `makan`, `hobi`, `kesehatan mental`

**Data generator v3 `catalog_activities.json` pakai family:**
- `makan`, `tidur`, `ibadah`, `kebersihan` (dan lainnya)

**Encoder app (`model_encoders.json`) pakai family:**
- `belajar`, `hiburan`, `hidrasi`, `kerja`, `kesehatan`, `makan`, `olahraga`, `perawatanDiri`, `produktif`, `rehat`, `rumah`, `sosial`, `tidur`, `umum` (14 families)

**Masalah:**
- `hobi` (training data) → **TIDAK ADA** di encoder
- `kesehatan mental` (training data) → **TIDAK ADA** di encoder
- `ibadah` (v3 data) → **TIDAK ADA** di encoder
- `kebersihan` (v3 data) → **TIDAK ADA** di encoder
- `hiburan`, `hidrasi`, `kerja`, `perawatanDiri`, `produktif`, `rehat`, `rumah`, `sosial` (encoder) → **TIDAK ADA** di training data config
- Ini berarti **model ditraining dengan label encoding yang BERBEDA dari yang dipakai saat inference**. Prediksi bisa entirely meaningless.

### 🔴 4.3 CRITICAL: Mismatch Category Taxonomy
**Data generator `config.py` pakai category:**
- `kesehatan`, `pendidikan`, `pengembangan diri`

**Data generator v3 pakai category:**
- `rutinitas` (bukan salah satu dari 5 category di encoder)

**Encoder app pakai category:**
- `istirahat`, `kesehatan`, `produktif`, `sosial`, `umum` (5 categories)

**Masalah:**
- `pendidikan`, `pengembangan diri` (training) → **TIDAK ADA** di encoder → encoding = null → prediction skipped atau wrong
- `rutinitas` (v3) → **TIDAK ADA** di encoder
- Model learned mapping `kesehatan=1` tapi inference encoding `kesehatan=1` hanya by accident match — the rest will mismatch

### 🟡 4.4 model_encoders.json "Asumsi" bukan dari Training
File JSON sendiri bilang:
> "Mapping ini mengikuti **asumsi** LabelEncoder-style dari taxonomy app saat ini. Jika nanti kamu punya mapping asli dari script training, file ini tinggal diganti tanpa mengubah logika inference."

Ini sangat berbahaya: encoding order di inference **belum pasti match** dengan encoding order saat training. Misalnya, jika training data pakai `belajar=0, hobi=1, kesehatan mental=2, makan=3, olahraga=4` tapi inference pakai `belajar=0, hiburan=1, hidrasi=2...`, maka semua encoded values salah.

### 🟡 4.5 Synthetic Data Quality Issues
- **config.py v1:** Hanya 5 aktivitas × 3 persona × 90 hari = ~1.350 records. Sangat kecil.
- **v3 data:** 1.4M+ lines progress entries — lebih banyak, tapi kita tidak tahu versi mana yang dipakai untuk training
- **Persona diversity:** v1 cuma 3 persona (dari 6 yang didefinisikan karena `NUM_PERSONAS=3`). Very limited behavioral variance.
- **No noise/anomaly modeling** di v1 script (v3 sudah ada `is_anomali` flag)

### 🟡 4.6 Data Leakage Potential
- `completionRate` dihitung dari `totalCompleted / totalScheduled` → ini **directly correlated** dengan target variable `selesai/tidak_selesai` di home_completion model
- `streak` juga heavily correlated dengan consistency target
- Model mungkin belajar trivial rule: "kalau completionRate tinggi → prediksi selesai" — which defeats the purpose

### 🟡 4.7 No Evaluation Metrics
- Tidak ada accuracy, precision, recall, F1, AUC yang tersimpan
- Tidak ada confusion matrix
- Tidak ada cross-validation evidence
- Impossible to know if models actually learned anything useful

### 🟡 4.8 Train/Test Split Info
- Tidak ditemukan. Tidak ada evidence proper train/test/validation split dilakukan.

### 🟡 4.9 Stats ML Not Connected to UI
- `statsMlInsightProvider` dideclare di `providers.dart` tapi **tidak ada widget yang `.watch()` atau `.read()` nya**
- `StatsMlInsight` (isConsistent, effectiveSlotKey) — computed but never displayed
- Dead code / incomplete feature

### 🟡 4.10 Feature Order Mismatch Between Activity Form and Schema
- Schema `activity_day` feature order: `category_enc, family_enc, effort_enc, ...`
- Schema `detail_day` feature order: `family_enc, category_enc, effort_enc, ...`
- Activity Form code builds vector as: `[categoryEnc, familyEnc, effortEnc, ...]` yang **match** activity_day schema
- Detail service builds: `[familyEnc, categoryEnc, effortEnc, ...]` yang **match** detail_day schema
- Ini benar tapi tricky — kalau ada yang swap order, silent wrong prediction. Positifnya: kodenya saat ini consistent dengan schema.

### 🟢 4.11 Schema Validation (Positif)
- `MlSchemaValidationResult.isSafeToWire` checks: `matchesInputCount && matchesOutputShape && featureOrder.length == inputSize`
- Runtime validation tersedia via `validateAgainstRuntime()` — good defensive programming

### 🟢 4.12 Encoder Fallback System (Positif)
- `MlModelEncoderService` punya hardcoded fallback encoders jika JSON file gagal load
- Graceful null handling: jika encoding gagal, return null → prediction skipped, not crashed

---

## 5. Scorecard

| Model | Status | Alasan |
|-------|--------|--------|
| **Activity Day** (`days_model.onnx`) | 🔴 Bermasalah | Taxonomy mismatch training vs inference. Encoder "asumsi". Tidak ada eval metrics. |
| **Activity Time** (`time_model.onnx`) | 🔴 Bermasalah | Sama — taxonomy mismatch. Regression target unclear (minutes of what?). |
| **Detail Day** (`detail_day_model.onnx`) | 🔴 Bermasalah | Taxonomy mismatch. `isStable` derived feature mungkin data leakage. |
| **Detail Time** (`detail_time_model.onnx`) | 🔴 Bermasalah | Taxonomy mismatch. `_normalizePredictedTime` heuristic (if 0-24, multiply by 60) unreliable. |
| **Home Completion** (`home_model.onnx`) | 🔴 Bermasalah | Taxonomy mismatch. `completionRate` as input → near data leakage with `selesai` target. |
| **Stats Consistency** (`statistik_consistent_model.onnx`) | 🔴 Bermasalah | Taxonomy mismatch. `completionRate` + `streak` → almost directly == target. **Dead code: not used in UI.** |
| **Stats Effective Slot** (`statistik_slot_model.onnx`) | 🔴 Bermasalah | Taxonomy mismatch. Features (completion stats) unrelated to time slot prediction. **Dead code: not used in UI.** |

**Overall ML System: 🔴 Needs Major Rework**

---

## 6. Rekomendasi

### P0 — Harus Diperbaiki Segera

1. **Buat dan simpan training pipeline lengkap** (script Python + notebook)
   - Harus reproducible: script → data → model → evaluation → ONNX export
   - Simpan di dalam repo atau linked repo, bukan hilang entah di mana
   
2. **Fix taxonomy mismatch**
   - Training data harus pakai **exact same** family/category values yang dipakai di inference
   - Encoder mapping harus **diekstrak dari training pipeline**, bukan "diasumsikan"
   - `model_encoders.json` harus auto-generated dari `LabelEncoder.classes_` saat training

3. **Re-train semua 7 model** setelah taxonomy di-align
   - Dengan evaluation metrics (accuracy, precision, recall, F1)
   - Dengan proper train/test split (80/20 minimum, stratified)
   - Log metrics ke file JSON yang di-bundle sama model ONNX

### P1 — Perlu Diperbaiki

4. **Fix data leakage di Home Completion model**
   - `completionRate` sebagai input feature untuk memprediksi completion → circular
   - Gunakan lagging features: completion rate KEMARIN, bukan hari ini
   
5. **Fix data leakage di Stats Consistency model**
   - `completionRate` + `streak` → practically = target `konsisten`
   - Gunakan features yang lebih indirect: time-of-day consistency, postpone rate, etc.

6. **Connect Stats ML ke UI atau hapus**
   - `statsMlInsightProvider` tidak dipakai di mana pun
   - Wiring ke stats_page.dart atau stats_report_page.dart

7. **Improve synthetic data**
   - Lebih banyak persona (≥10)
   - Lebih banyak variasi aktivitas
   - Anomaly/noise modeling
   - Temporal patterns (weekday vs weekend behavior)

### P2 — Nice to Have

8. **Model versioning**
   - Simpan model version di metadata ONNX
   - Schema validation saat app start (sudah ada `validateAgainstRuntime` tapi belum dipakai secara wajib)

9. **A/B testing framework**
   - Compare ML predictions vs rule-based (`SmartActivityAdvisor`) recommendations
   - Track apakah ML actually improves user outcome

10. **`_normalizePredictedTime` logic review**
    - Heuristic `if (minutes >= 0 && minutes <= 24) minutes *= 60` — ini asumsi bahwa regressor mungkin output jam (0-24) bukan menit. Harusnya fix di training/model output, bukan hack di inference.

---

## Appendix: File yang Di-audit

### Core ML Infrastructure
- `lib/services/ml/onnx_model_service.dart` — ONNX session management + caching
- `lib/services/ml/ml_model_schema_service.dart` — Schema loading + validation
- `lib/services/ml/ml_model_encoder_service.dart` — Label encoding service

### ML Service Layer
- `lib/features/home/application/home_ml_service.dart` — Home completion prediction
- `lib/features/activity/application/activity_detail_ml_service.dart` — Detail day/time prediction
- `lib/features/activity/application/activity_form_ml_service.dart` — Activity form day/time prediction
- `lib/features/stats/application/stats_ml_service.dart` — Stats consistency + slot prediction

### AI Engine
- `lib/features/home/application/home_ai_brief_engine.dart` — Rule-based AI brief (1477 lines, extensive)
- `lib/features/activity/application/smart_activity_advisor.dart` — Activity profiling + recommendation (1195 lines)

### Configuration
- `assets/ml_model/model_schema.json` — Model schemas (7 models)
- `assets/ml_model/model_encoders.json` — Label encoder mappings
- `assets/ai/activity_profiles.json` — 40+ activity profiles for SmartActivityAdvisor

### Presentation Layer (ML consumption)
- `lib/features/home/presentation/home_shell_page.dart` — `_blendHomeBriefWithMl()` blends ML into AI brief
- `lib/features/activity/presentation/activity_form_page.dart` — Hybrid suggestion with ML time prediction
- `lib/features/activity/presentation/activity_detail_page.dart` — Day suitability + time recommendation display
- Stats presentation: **NO ML consumption found**

### Data Generation
- `E:/data_generator/generate_synthetic_data.py` — Main generator
- `E:/data_generator/config.py` — 5 activities, 3 personas, 90 days
- `E:/data_generator/personas.py` — 6 persona profiles (only 3 used)

### ONNX Model Files
7 files in `assets/ml_model/`: `days_model.onnx`, `time_model.onnx`, `detail_day_model.onnx`, `detail_time_model.onnx`, `home_model.onnx`, `statistik_consistent_model.onnx`, `statistik_slot_model.onnx`

---

*Report generated by Hermes Agent — Nous Research*
