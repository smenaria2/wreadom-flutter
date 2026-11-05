# Wreadom (librebook_flutter) – working agreements

## Work on the project as a whole
- The app may ship to production after testing. If you find any other issue while working, reviewing or testing (failing or stale tests, broken rules, regressions, loaders, security loosening), **tell the user and fix it in the same pass where possible**. Do not leave known issues behind.
- After changes run `flutter analyze` and the full `flutter test`; report every failure with its cause, including pre-existing ones. Never say something is fixed unless it was verified; say what is unverified.

## Firestore rules (shared with the web app)
- Firebase project `studio-8109133561-1eb90` is shared with the web app in `C:\Users\user\librebook`. `firestore.rules` in both folders **must be identical**. Before editing or deploying rules, diff the two copies; the older copy once overwrote live rules (dropped `collections`, `leaderboards`, `books_metadata`, `users/{id}/private`).
- Several tests (`qa_hardening_test`, `book_collaboration_test`) read `firestore.rules` as text; update them when rules change on purpose.
- Test rules in the Firestore emulator before deploying. Deploy only on explicit user approval: `firebase deploy --only firestore:rules --project studio-8109133561-1eb90`.

## Release
- `publish_play_store.ps1` builds, versions, commits and publishes (Play internal + Vercel). Commit and push first; the script makes its own `release:` commit, then push it.
- `play_store_key.json` and `dart_defines.local.json` are secrets (gitignored); never commit them.

## Features worth knowing
- Author UPI support: `author_support/{uid}` and `support_claims/{authorId_supporterId}`; no money passes through the app; claims are author-verified (green tick); Cloud Function `onSupportClaimWrite`. Keep supporter recognition cosmetic (no unlocked content) to stay outside Google Play Billing.
- Privacy Policy and Terms pages live on wreadom.in; draft clauses are in `docs/support-feature-legal-text.md`.
