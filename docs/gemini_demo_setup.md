# Gemini Demo Setup

Untuk demo lokal di HP, jangan taruh API key di file Dart.

## File lokal

1. Buat file:

```text
config/gemini_demo.local.env
```

2. Isi dengan format:

```env
GEMINI_API_KEY=PASTE_YOUR_GEMINI_API_KEY_HERE
```

File ini sudah masuk `.gitignore`, jadi tidak ikut ter-commit.

## Menjalankan app

Pakai salah satu:

```bash
flutter run --dart-define=GEMINI_API_KEY=ISI_API_KEY_KAMU
```

atau

```bash
flutter run --dart-define-from-file=config/gemini_demo.local.env
```

## Akses di code

Config dibaca dari:

- `lib/core/constants/ai_demo_config.dart`
- `lib/services/gemini_activity_service.dart`

Service/provider yang sudah disiapkan:

- `geminiActivityServiceProvider`

Catatan:

- Aman untuk demo pribadi.
- Tidak aman untuk distribusi APK publik.
- Untuk production, pindahkan pemanggilan Gemini ke backend atau Firebase AI Logic.
