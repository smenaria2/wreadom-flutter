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
