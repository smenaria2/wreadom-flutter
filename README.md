# librebook_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Functions

This app uses a hybrid Firebase architecture:

- keep user-driven, latency-sensitive reads and writes in the Flutter client
- move derived data, counters, notifications, and multi-document consistency into Cloud Functions

The Firebase CLI workspace for functions lives in [functions/index.js](C:\Users\user\librebook_flutter\functions\index.js).

## Runtime Configuration and Secrets

Client runtime values are supplied with Dart defines. Do not add real API keys,
upload presets, passwords, tokens, keystores, or `.env.local` files to source
control.

Create a local untracked copy from [dart_defines.example.json](C:\Users\user\librebook_flutter\dart_defines.example.json),
for example `dart_defines.local.json`, then run:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

For release builds:

```bash
flutter build apk --dart-define-from-file=dart_defines.local.json
flutter build appbundle --dart-define-from-file=dart_defines.local.json
```

The required client values are:

- `FIREBASE_WEB_API_KEY`
- `FIREBASE_ANDROID_API_KEY`
- `FIREBASE_IOS_API_KEY`
- `FIREBASE_WINDOWS_API_KEY`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`

Keep Android signing secrets in ignored local files only:

- `android/key.properties`
- `android/app/upload-keystore.jks`

Firebase Functions B2 credentials must stay in Firebase secrets or the function
runtime environment. The source code should only contain secret names, not
secret values.

Before pushing, run:

```bash
flutter test test/secrets_hardening_test.dart
```

CI also runs gitleaks using [.gitleaks.toml](C:\Users\user\librebook_flutter\.gitleaks.toml).
Firebase client config in `android/app/google-services.json` is public app
configuration, but restrict those API keys in Google Cloud/Firebase by package
name, bundle ID, SHA certificate, or web domain. Restrict the Cloudinary upload
preset to the smallest allowed formats, size, folder, and transformation policy.

### Local setup

Install Flutter and the Firebase CLI, then install the Functions dependencies:

```bash
cd functions
npm install
```

### Run locally with emulators

From the repo root:

```bash
firebase emulators:start --only auth,firestore,functions
```

Or from `functions/`:

```bash
npm run serve
```

### Validate changes

```bash
flutter analyze
flutter test
cd functions && npm test
```

## App Versioning

Keep the manual app version in [pubspec.yaml](C:\Users\user\librebook_flutter\pubspec.yaml):

```yaml
version: 1.0.0+1
```

The part before `+` is the visible app version. Use the root release script to keep that version name and update the build number to seconds since `2024-01-01T00:00:00Z`.

```powershell
.\build_ver_apk.ps1
```

### Deploy functions

```bash
firebase deploy --only functions
```

### Current server-owned responsibilities

- follow create/delete: counters and follow notifications
- comment writes: feed comment counts, review aggregates, and reply/comment notifications
- feed like notifications
- profile denormalization propagation
- message side effects for conversation summary and notifications
- published book follower notifications
- scheduled homepage metadata refresh
