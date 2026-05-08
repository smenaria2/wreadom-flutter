# Shared Librebook Project Skills

Use this file as the durable project briefing for future Codex sessions that work across the Librebook mobile and web projects.

## Project Map

- `C:\Users\user\librebook_flutter` is the Flutter/mobile project. The app uses Riverpod, Firebase Auth, Firestore, Storage, Cloud Functions, Messaging, App Check, local notifications, and platform-specific Firebase options in `lib/firebase_options.dart`.
- Flutter source lives under `lib/src`, split into `config`, `core`, `data`, `domain`, `localization`, `presentation`, and `utils`. Generated localization output lives under `lib/src/localization/generated`.
- Flutter runtime configuration comes from Dart defines. Use `dart_defines.example.json` as the safe template and keep real local values in ignored files such as `dart_defines.local.json`.
- Flutter Cloud Functions live in `functions/index.js`. This Firebase CLI workspace uses Node 22, Firebase Admin, Firebase Functions v1, and Backblaze B2/S3 helpers for audio review uploads.
- `C:\Users\user\librebook` is the npm web project. It is a Vite React/TypeScript app with Firebase client setup in `services/firebaseConfig.ts`.
- Web app code is organized around `pages`, `components`, `services`, `hooks`, `utils`, root app files, and serverless API routes under `api`.
- Web Cloud Functions source lives in `functions/*.ts`, with compiled JavaScript in `functions/lib`. Treat the TypeScript source as the preferred editable source when syncing function behavior.

## Shared Firebase Backend

- Both projects target the same Firebase project: `studio-8109133561-1eb90`.
- Shared Firebase app details include messaging sender ID `601247128838`, storage bucket `studio-8109133561-1eb90.firebasestorage.app`, and the web app ID `1:601247128838:web:1bd0d3f4e026297d025287` where applicable.
- The web repo's `.firebaserc` maps `default` to `studio-8109133561-1eb90`. The Flutter repo's `firebase.json` also references the same project through Flutter platform config, even though its `.firebaserc` currently has no default project alias.
- Both apps read and write the same Firestore data model. Any collection, document shape, field name, rule, index, callable function, notification payload, FCM token behavior, link shape, or derived counter may affect both clients.
- Features can be cross-dependent. Before changing a feature in either app, search both repos for the same collection names, callable names, service names, model fields, notification types, and route/link parameters.

## Cloud Functions Responsibilities

- Treat Cloud Functions as one shared backend surface even though each repo has its own `functions` directory.
- Current overlapping function responsibilities include push notifications, FCM token claiming/removal, follows, recommendations, book views, comments/replies, feed likes, profile denormalization, conversations/messages, book publishing and collaboration notifications, review highlighting, audio review B2 upload/download/delete URLs, and homepage metadata refresh.
- Scheduled and homepage metadata behavior includes `refreshHomepageMetadata`, `onDailyTopicWrite`, `onHomeBannerWrite`, and `manualRefreshHomepage`.
- Callable functions used by clients must remain compatible across web and Flutter. Check request parameters, auth requirements, return payloads, region assumptions, error codes, and client call sites before changing them.
- Prefer making the web TypeScript functions source canonical when practical, then port or sync behavior into the Flutter repo's JavaScript functions if both Firebase workspaces remain active.
- Do not deploy functions from one repo until shared behavior has been compared with the sibling repo and the intended canonical source is clear.

## Rules, Indexes, and Storage

- `firestore.rules` currently exists in both repos and is synchronized. Keep it synchronized whenever rules change.
- The web repo also has `storage.rules` and `firestore.indexes.json`. The Flutter repo currently does not have matching root files for those Firebase resources.
- If adding or changing collections, query patterns, storage paths, roles, ownership rules, review/comment permissions, messaging permissions, profile visibility, or admin-like workflows, update rules and indexes as part of the same task.
- When a rule or index change is required, inspect both clients for all affected reads/writes and update both repos' Firebase configuration files where appropriate.
- Use file comparison rather than memory for sync checks. At minimum compare `firestore.rules`, function exports, callable function names, and client service usages before finishing backend-affecting work.

## Cross-Project Change Workflow

- Start every non-trivial feature or backend task by identifying whether it touches shared Firebase state. Assume it does if it involves schema, collections, rules, functions, notifications, counters, homepage metadata, messaging, follows, comments, reviews, audio reviews, collaboration, auth, storage, or public links.
- Search both repos before editing. Useful targets include Flutter `lib/src/data`, `lib/src/domain`, and `lib/src/presentation`; web `services`, `pages`, `components`, `types.ts`, and `constants.ts`; and both `functions` directories.
- Keep shared names stable unless intentionally migrating both clients. This includes collection names, document IDs, field names, callable names, notification `type` values, FCM payload keys, route/query parameters, and Cloudinary/B2 object metadata.
- If a change affects one client first, add compatibility handling so the other client keeps working until it is updated.
- When changing Firestore rules or functions in one repo, compare and update the other repo before considering the task complete.
- Note any intentional divergence explicitly in the final response, including which repo is canonical and why.

## Secrets and Config

- Do not commit real API keys, upload presets, passwords, service account JSON, keystores, `.env.local`, or secret values.
- Flutter Firebase API keys are supplied via Dart defines such as `FIREBASE_WEB_API_KEY`, `FIREBASE_ANDROID_API_KEY`, `FIREBASE_IOS_API_KEY`, and `FIREBASE_WINDOWS_API_KEY`.
- Flutter Cloudinary values are supplied via Dart defines such as `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET`.
- Web Firebase values are supplied through `.env` or `.env.example` names such as `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID`, `VITE_FIREBASE_STORAGE_BUCKET`, `VITE_FIREBASE_MESSAGING_SENDER_ID`, and `VITE_FIREBASE_APP_ID`.
- Web push uses `VITE_VAPID_KEY`. Web Cloudinary public config uses `VITE_CLOUDINARY_CLOUD_NAME` and `VITE_CLOUDINARY_API_KEY`; never put a Cloudinary API secret in client env files.
- Backblaze B2 audio review credentials belong only in Firebase secrets or function runtime environment. The function code should reference secret names such as `B2_KEY_ID`, `B2_APPLICATION_KEY`, `B2_AUDIO_BUCKET_NAME`, `B2_AUDIO_BUCKET_ID`, `B2_AUDIO_S3_ENDPOINT`, and `B2_AUDIO_DOWNLOAD_BASE_URL`.
- Firebase client config is not a server secret, but API keys should still be restricted in Google Cloud/Firebase by package name, bundle ID, SHA certificate, or web domain.

## Validation Checklist

- Flutter app checks:
  - `flutter analyze`
  - `flutter test`
  - `cd functions && npm test`
- Web app checks:
  - `npm run build`
  - `cd functions && npm run build`
  - `cd functions && npm test`
- Firebase sync checks:
  - Compare `C:\Users\user\librebook_flutter\firestore.rules` with `C:\Users\user\librebook\firestore.rules`.
  - Compare exported Cloud Function names and callable function names across both `functions` directories.
  - Search both clients for changed callable names, collection names, notification types, FCM payload keys, storage paths, and route/query parameters.
  - Confirm any required `storage.rules` or `firestore.indexes.json` updates in the web repo, and decide whether matching files/config are needed in the Flutter repo.
- Final response for cross-project work should mention which repos changed, which sync checks were performed, which tests passed, and any remaining backend/client compatibility risks.
