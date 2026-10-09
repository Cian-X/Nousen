# Nousen

A Flutter-based personal activity and schedule management app for Android. Nousen helps users organize activities, plan their agenda, track progress, and build more intentional routines.

> This project is under active development and prepared as a demo project. It is not currently published on Google Play.

## Features

- Create and manage activities, including subtasks and progress tracking.
- Plan one-time and recurring reminders in the agenda.
- Browse a 14-day agenda window starting with today.
- View activity and progress summaries in Statistics.
- Configure app preferences in Settings.
- Receive scheduled notifications and open the related activity from a notification.

## Technology

- Flutter and Dart
- Riverpod for state management
- Isar for local data storage
- Android native integration (Java) for platform-specific functionality
- `flutter_local_notifications` for scheduled notifications

## Requirements

- Flutter SDK compatible with Dart `^3.10.4` (see `pubspec.yaml`)
- Android SDK and an Android device or emulator

## Run locally

```bash
git clone https://github.com/Cian-X/Nousen.git
cd Nousen
flutter pub get
flutter run
```

## Tests and analysis

```bash
flutter analyze
flutter test
```

## Build an Android APK

Universal APK:

```bash
flutter build apk --release
```

Split APKs by CPU architecture (install the matching APK for the target device):

```bash
flutter build apk --release --split-per-abi
```

Release signing must be configured with your own signing key before distributing a production release. Do not use debug signing for a public store release.

## Project status

Nousen is a student/demo project under active development. Features and platform behavior may change. Verify the current test and build results before relying on a particular release artifact.
