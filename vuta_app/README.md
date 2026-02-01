# VUTA

VUTA is a Flutter application targeting Android.

## Tech Stack

- **Flutter** (Dart)
- **Riverpod** state management
- **Dio** for networking
- **WorkManager** for background tasks
- **Shared Preferences** for lightweight persistence

## Requirements

- **Flutter SDK** installed and on PATH
- **Android Studio** + Android SDK
- **Flutter** and **Dart** plugins installed in Android Studio

## Run in Android Studio (recommended)

1. Open **Android Studio**.
2. `File` → `Open...` → select the **`vuta_app/`** folder.
3. Wait for Gradle + Flutter indexing to finish.
4. In the terminal (Android Studio or external), from `vuta_app/` run:
   - `flutter pub get`
5. Select a device:
   - **Android Emulator** (Device Manager)
   - or a **physical device** with USB debugging enabled
6. Click **Run** (green play button) or run:
   - `flutter run`

### Common Android Studio troubleshooting

- If you see `flutter.sdk not set in local.properties`:
  - Run `flutter pub get` once, or
  - Run `flutter doctor -v` and ensure Flutter is properly installed.
  - Android Studio/Flutter tooling will regenerate `android/local.properties` automatically.

## Build Release Artifacts

From `vuta_app/`:

- **APK (Release)**
  - Command: `flutter build apk --release`
  - Output:
    - `build/app/outputs/flutter-apk/app-release.apk`

- **AAB (Release / Play Store)**
  - Command: `flutter build appbundle --release`
  - Output:
    - `build/app/outputs/bundle/release/app-release.aab`

### Important: signing

This project is currently configured to sign `release` with the **debug keystore** (so release builds work out of the box).
For Play Store publishing, you should configure a proper release keystore.

## App Icon / Logo

The app logo asset is:

- `assets/images/vuta_logo.png`

Launcher icons are generated via `flutter_launcher_icons`:

- `dart run flutter_launcher_icons`

## Project Structure

- `lib/main.dart` – app entry point
- `lib/core/` – shared utilities, theme, widgets
- `lib/features/` – feature modules/screens
- `lib/services/` – background tasks, permissions, etc.
- `android/` – Android host project (Gradle, manifest, resources)

## Useful Commands

- `flutter pub get`
- `flutter clean`
- `flutter run`
- `flutter build apk --release`
- `flutter build appbundle --release`
