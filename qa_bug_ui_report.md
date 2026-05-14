# Wreadom Flutter Bug and UI Issues Report

Audit date: 2026-05-12 13:16 +04:00  
Workspace: `C:\Users\user\librebook_flutter`  
Scope: current working tree, Chrome/web-first QA, source-backed UI review  

## Executive Summary

The static and unit-test baseline is healthy: `flutter analyze`, `flutter test`, Functions `npm test`, and `flutter build web` all completed successfully. The main issue found during runtime QA is that the Chrome web app did not render a usable first screen in local testing. Headless Chrome screenshots at both mobile and desktop sizes show a blank white page, and the in-app browser initially showed only a mostly black Flutter surface with a thin cyan/blue strip and no usable UI.

Because no test credentials were present in `dart_defines.local.json` or discoverable project files, signed-in workflows could not be completed end-to-end. Source review still found user-facing bugs and UI issues in auth-gated areas, especially profile privacy settings and collaboration requests.

## Environment and Commands Run

- `flutter analyze` - passed, no issues found.
- `flutter test` - passed, 146 tests.
- `npm test` in `functions` - passed, 14 tests.
- `flutter build web --dart-define-from-file=dart_defines.local.json` - passed.
- `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define-from-file=dart_defines.local.json` - served app at `http://127.0.0.1:3000/`.
- Chrome web screenshots:
  - Mobile: `C:\Users\user\librebook_flutter\qa_web_mobile.png`
  - Desktop: `C:\Users\user\librebook_flutter\qa_web_desktop.png`

Build note: `flutter build web` reports WebAssembly dry-run incompatibilities from `flutter_tts_web.dart` in the `flutter_tts` dependency. This does not fail the current JS web build, but it blocks a clean Wasm migration.

## Confirmed Bugs

### B1 - Chrome web first screen renders blank

Severity: High  
Area: Web startup / login entry  
Evidence: `qa_web_mobile.png`, `qa_web_desktop.png`, in-app browser observation  
Affected code: `lib\main.dart:54-80`

Reproduction:
1. Run `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define-from-file=dart_defines.local.json`.
2. Open `http://127.0.0.1:3000/` in Chrome.
3. Capture mobile or desktop viewport.

Actual:
- Headless Chrome captured a blank white page.
- The in-app browser loaded the `Wreadom` title but showed no usable login UI.

Expected:
- Unauthenticated users should see the localized login screen with logo, email/password fields, Google sign-in, theme/language controls, and signup toggle.

Likely risk area:
- Startup awaits several platform services before `runApp`: Hive/offline storage, Firebase, App Check, notifications, and Google Sign-In (`lib\main.dart:54-80`). If any web plugin call hangs or throws before `runApp`, the app has no fallback UI.

Suggested fix:
- Move noncritical service initialization after `runApp` or wrap each web-sensitive initialization with timeout/error fallback.
- Specifically review `FirebaseAppCheck.instance.activate`, `NotificationService.instance.init()`, and `GoogleSignIn.instance.initialize` on web.
- Add a web smoke test or integration check that asserts the login screen appears within a short timeout.

### B2 - Profile privacy dropdown cannot reliably change value

Severity: High  
Area: Profile settings  
Affected code: `lib\src\presentation\screens\profile_settings_screen.dart:42-51`, `lib\src\presentation\screens\profile_settings_screen.dart:72-85`, `lib\src\presentation\screens\profile_settings_screen.dart:98-100`

Reproduction:
1. Open Profile Settings as a signed-in user.
2. Change Privacy from the saved value to another option.
3. Observe the dropdown after `setState`.
4. Tap Save.

Actual:
- `_privacy` is overwritten from `user.privacyLevel` on every build (`line 51`).
- The dropdown calls `setState` on change (`line 84`), causing a rebuild that can immediately restore the old server value before save.
- Save can persist the old privacy value instead of the user's selected value.

Expected:
- The selected privacy value should remain stable in local state until saved or discarded.

Suggested fix:
- Initialize form fields once in `initState`, a guarded `_didPopulateForm` block, or a post-load method.
- Do not assign `_privacy = user.privacyLevel ?? _privacy` unconditionally inside `build`.
- Add a widget test that changes the dropdown and verifies `updatePrivacyLevel` receives the new value.

### B3 - Production routes expose placeholder copy

Severity: Medium  
Area: Certificate and Competition routes  
Affected code: `lib\src\presentation\routing\app_router.dart:344-350`, `lib\src\presentation\routing\app_router.dart:382-385`

Reproduction:
1. Navigate to `/certificate` or `/competition`.

Actual:
- Certificate route says the Flutter build "can be expanded".
- Competition route says content "can be surfaced".

Expected:
- Either a production-ready experience, a clearly labeled unavailable state, or no visible navigation to these routes until supported.

Suggested fix:
- Replace placeholder implementation copy with product copy and a clear action, or hide routes from user navigation.
- Track backend/data dependencies explicitly if these are planned features.

## UI/UX Issues

### U1 - Collaboration request screen has hardcoded English strings

Severity: Medium  
Area: Collaboration request / localization  
Affected code: `lib\src\presentation\screens\collaboration_request_screen.dart:35-43`, `lib\src\presentation\screens\collaboration_request_screen.dart:79-91`, `lib\src\presentation\screens\collaboration_request_screen.dart:117-144`, `lib\src\presentation\screens\collaboration_request_screen.dart:180`

Issue:
- Multiple user-visible strings bypass localization: "Collaboration request", "This request is no longer available.", "wants to collaborate with you.", "Draft preview", "Decline", "Accept", "Open book", and the update error snackbar.

Impact:
- Hindi users see mixed-language UI in an important signed-in workflow.
- Translation completeness checks will not catch these strings because they are not in ARB files.

Suggested fix:
- Move all strings into `app_en.arb` and `app_hi.arb`.
- Add a localization hardening test that fails for common hardcoded `Text('...')` strings in presentation screens.

### U2 - Error messages expose raw technical exceptions

Severity: Medium  
Area: Login, comments, notifications, reader, reviews  
Examples:
- `lib\src\presentation\widgets\comment_widgets.dart:138`
- `lib\src\presentation\screens\notifications_screen.dart:170`
- `lib\src\presentation\components\book\review_sheet.dart:110`
- `lib\src\presentation\screens\reader_screen.dart:698-734`

Issue:
- Several user-facing snackbars/screens display raw exception values such as `$e`, `$error`, or `$err`.

Impact:
- Users see implementation details instead of recoverable guidance.
- Backend/Firebase error text may be too long for mobile snackbars and may leak internal details.

Suggested fix:
- Map known Firebase/network/permission failures to localized, actionable messages.
- Log raw details to `AppLogCollector` while showing concise UI copy.

### U3 - Several reader controls remain hardcoded in English

Severity: Low to Medium  
Area: Reader / TTS / review/comment controls  
Examples:
- `lib\src\presentation\screens\reader_screen.dart:845`
- `lib\src\presentation\screens\reader_screen.dart:872`
- `lib\src\presentation\screens\reader_screen.dart:1253-1329`
- `lib\src\presentation\screens\reader_screen.dart:2752`
- `lib\src\presentation\screens\reader_screen.dart:3072`

Issue:
- Tooltips, snackbars, and labels such as "View PDF", "Reader Settings", "Read aloud failed", "No readable text selected", "Edit", and "Font Size" bypass localization.

Impact:
- The reader is one of the app's core surfaces; mixed language here is more visible than in secondary flows.

Suggested fix:
- Move strings to ARB files and use `AppLocalizations`.
- Add focused widget tests for Hindi reader settings and TTS error states.

## Accessibility and Responsive Findings

### A1 - Blank web first screen is also an accessibility blocker

Severity: High  
Evidence: Chrome screenshots listed above

Issue:
- No meaningful controls or text are available on the first screen during web runtime testing.

Impact:
- Keyboard, screen reader, and visual users cannot begin login/signup.

Suggested fix:
- Same as B1; additionally add a semantic smoke assertion for the login heading or email field.

### A2 - Localization and overflow risk remains in long-form signed-in surfaces

Severity: Medium  
Area: Reader, collaboration request, profile settings

Issue:
- Existing tests cover several long-title and Hindi cases, but source review still found unlocalized strings in dense signed-in surfaces. These strings may not expand correctly in Hindi and are not covered by ARB placeholder checks.

Suggested fix:
- Expand widget coverage for collaboration request and reader settings at 390px width in Hindi.
- Include text-scale checks for settings, request actions, and reader bottom sheets.

## Auth-Gated Coverage

Status: Blocked for live signed-in QA.

Blocker:
- No safe test login credentials were present in `dart_defines.local.json`.
- Repository search did not find usable demo/test login credentials.
- The unauthenticated Chrome web entry did not render a usable login UI, so account creation or Google sign-in could not be safely attempted in the local browser pass.

Reviewed by source/tests:
- Profile settings
- Collaboration request
- Reader controls
- Notifications error state
- Comments/review error handling
- Existing automated coverage for routing, writer pad, home banner, notification visibility, collaboration, reader/progress hardening, archive filtering, and feed/message hardening.

## Screenshots and Evidence

- `C:\Users\user\librebook_flutter\qa_web_mobile.png` - 390x844 Chrome capture, blank page.
- `C:\Users\user\librebook_flutter\qa_web_desktop.png` - 1280x720 Chrome capture, blank page.
- `C:\Users\user\librebook_flutter\qa_flutter_web.out.log` - local web-server startup log.

## Recommended Next Steps

1. Fix the web startup blank screen first; it blocks real web QA and all unauthenticated conversion flows.
2. Fix the profile privacy form state bug; it can cause user settings to save incorrectly.
3. Replace placeholder certificate/competition routes or hide them.
4. Localize collaboration request and reader hardcoded strings.
5. Add web smoke/integration coverage for first render, profile privacy editing, and Hindi text-scale checks.
