# librebook_flutter

## What this codebase does
A hybrid Flutter application for a social reading and writing platform (Librebook). Users can read books, write stories (using a Quill-based editor), follow other authors, and engage in social features like comments, likes, and messages. It uses Firebase for Authentication, Firestore for real-time data, and Cloud Functions for side effects and data consistency.

## Auth shape
- `FirebaseAuthRepository` manages authentication using `firebase_auth` and `google_sign_in`.
- Core primitives: `signUp`, `signIn`, `signInWithGoogle`, `logout`.
- Auth state is exposed via `authStateChanges` stream and managed by Riverpod `currentUserProvider`.
- User data is anchored in the `users` Firestore collection, indexed by Firebase Auth UID.

## Threat model
1. **Unauthorized Content Manipulation**: Attempting to edit or delete books/chapters/comments without proper authorship or collaboration permissions.
2. **Account Takeover**: Exploiting vulnerabilities in the auth flow or session management.
3. **Insecure Side Effects**: Manipulating Cloud Function triggers (via Firestore writes) to spam notifications, inflate counters, or bypass business logic.
4. **Data Leakage**: Accessing private drafts or user metadata not intended for public view.

## Project-specific patterns to flag
1. **Direct `users` Collection Writes**: Client-side updates to sensitive fields in `users/{userId}` without using secure server-side functions.
2. **Insecure Collaboration Logic**: Bypassing authorship checks in `writer_pad_screen.dart` or `book_collaboration_utils.dart`.
3. **FCM Token Registry Management**: Improper addition or removal of tokens in `FirebaseAuthRepository.claimFcmToken`.
4. **Cloud Function Inputs**: Passing unvalidated or racy data to callables like `claimFcmToken` or `removeFcmToken`.

## Known false-positives
1. **`firebase_options.dart`**: Contains standard public Firebase configuration strings.
2. **Web-specific Sign-in**: The `kIsWeb` block in `FirebaseAuthRepository` constructor which handles GIS events.
3. **Development Emulators**: Hardcoded `localhost` references used when running with Firebase emulators.
