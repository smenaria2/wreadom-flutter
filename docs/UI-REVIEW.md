# LibreBook Flutter - UI Review

**Audited:** 2026-10-07
**Baseline:** Abstract 6-pillar standards (no UI-SPEC)
**Screenshots:** Not captured. This was a code-only audit of lib/src/presentation (214 files, about 31k lines in screens) and lib/l10n.

## Pillar Scores

| Pillar | Score | Key Finding |
|---|---|---|
| 1. Copywriting | 2/4 | About 40 hardcoded English strings bypass l10n. (Hindi key parity verified: no keys missing from app_hi.arb.) |
| 2. Visuals | 2/4 | 129 IconButtons but 119 tooltips. Only 35 Semantics and 17 semanticLabel across 92 GestureDetector/InkWell. |
| 3. Color | 2/4 | 670 hardcoded Color(0x)/Colors.* uses. Colors.red is used as the error colour. |
| 4. Typography | 2/4 | 358 inline fontSize values over 20+ distinct sizes, many at 8-11. |
| 5. Spacing | 3/4 | Mostly on a 4/8 grid, but off-grid values (10, 14, 18, 22) are common and there is no spacing tokens file. |
| 6. Experience Design | 2/4 | Many AsyncValue error branches are swallowed to SizedBox.shrink(). Raw exceptions are shown to users. |

**Overall: 13/24**

## Top 3 Priority Fixes

1. **Silent error and loading branches** - Users see blank sections with no explanation or retry. Examples are home_books_screen.dart:2140,2152-2153; public_profile_screen.dart:109-110,222-223; book_detail_screen.dart:1368; leaf_components.dart:1380; writer_dashboard_header.dart:157-158. Replace `SizedBox.shrink()` with a shared `AsyncErrorView` (message, retry, l10n) and a skeleton loader. Only about 36 skeleton/shimmer usages exist against 72 bare CircularProgressIndicators.
2. **Hardcoded and untranslated strings, including raw exception text** - Hindi users get English UI, and leaking `$e`/`$error` is poor UX. Examples:
   - archive_reader_screen.dart:36-48 ("Book not found", "Error loading book: $error")
   - reader_screen.dart:780,787,1090,1098,1167,1183 ("Watch Video Ad", "OK", "Unable to load this chapter.", "Retry", "Back to book")
   - writer_pad_screen.dart:1648,1658,3355-3371 (conflict dialog)
   - home_banner_screen.dart:90,113
   - social_links_menu.dart:20,24,45,76
   - attributions_screen.dart:16
   - animation_settings_card.dart:48
   - book_detail_screen.dart:642
   - collection_detail_screen.dart:147
   - home_books_screen.dart:1409
   - leaf_components.dart:1055 (`Text(e.toString())` on `Colors.red`)

   Move these to ARB and map exceptions to friendly messages.
3. **Theme bypass for color and type** - Dark-mode and contrast regressions, and no text-scale control. Use `colorScheme.error` instead of `Colors.red` (audio_post_creator.dart:239,395,687; comment_reply_sheet.dart:310,375; leaf_components.dart:968,1055; create_post_sheet.dart:392). Move the 358 inline `fontSize` values to the TextTheme roles (label/body/title). Note that 8-11sp text is used 102 times, which is illegible at small sizes. Concentrations of hardcoded color are reader_screen.dart (46), interactive_features_sheet.dart (44), generated_book_cover.dart (41), reel_post_content.dart (31), home_books_screen.dart (30) and feed_media_playable_card.dart (29). Share cards and certificates (participation_certificate, *_share_preview_sheet, review_share_card, profile_share_card) are legitimately fixed-palette exports and can stay hardcoded. Document that.

Additional fixes (4-8):

4. Tap targets under 48dp. Examples: create_post_sheet.dart:840 (`minimumSize: Size(28,28)`); create_post_sheet.dart:1060 (minHeight 20); feed_post_card.dart:942 and daily_topic_screen.dart:323 (`padding: zero` plus `BoxConstraints()` on icon/popup buttons, so about 18dp icon targets); daily_topic_screen.dart:402 and public_profile_screen.dart:499 (`MaterialTapTargetSize.shrinkWrap`); writer_pad_screen.dart:1069 (Size(68,36)). Also 61 occurrences of compact/zero padding or shrinkWrap overall.
5. Accessibility. 10 IconButtons lack tooltips, and 92 GestureDetector/InkWell widgets have few Semantics wrappers (35 total). Add `tooltip`/`Semantics(button: true, label: ...)`. Only one explicit textScaler use exists (public_profile_screen.dart:479). Test the app at 1.5-2.0x text scale, since fixed heights and small fonts are common.
6. Dialog and snackbar inconsistency. There are 39 showDialog, 26 AlertDialog and 123 showSnackBar calls, with some snackbars hardcoding `backgroundColor: Colors.red` (create_post_sheet.dart:392, audio_post_creator.dart:239). Create `showAppSnackBar(context, kind, message)` using theme snackBarTheme and `colorScheme.error`.
7. Responsive layout. Only 43 LayoutBuilder/MediaQuery uses exist across 214 files. `maxWidth: 420` is repeated (reader_screen.dart:5283, book_detail_screen.dart:660, onboarding_gate.dart:393, leaf_components.dart:1118) and some large fixed widths exist (feed_post_card.dart:339 width 600; 1312-1323 width 1000). Introduce shared breakpoints (layout_constants.dart currently only holds bottom-clearance constants) and verify tablet and web layouts. The existing screenshots dir has a `tablet_image1.png` to compare against.
8. Monolithic screens (reader_screen 6004 lines, writer_pad_screen 4949, home_books_screen 2201, book_detail_screen 2139) make consistency hard to maintain. Extract widgets.

## Detailed Findings

### Pillar 1: Copywriting (2/4)
- Positives: 1159 English keys, l10n used in 109 files, and meaningful labels (for example `l10n.removeImage`). The "Retry" and "OK" labels are generic but acceptable.
- BLOCKER for Hindi: the user-facing hardcoded strings listed in Fix 2. A grep for non-const `Text('...')` literals found 39 more matches, though some are dynamic and some are admin-only.
- Correction: a key-set diff shows app_hi.arb has every key in app_en.arb; the earlier "114 missing" claim was a line-count artifact.
- Error copy: "Error loading book: $error" and "Error opening link: $e" (social_links_menu.dart:24) expose internals. "Unable to load this chapter." is not localized.
- Writer conflict dialog (writer_pad_screen.dart:3355-3371) has clear, specific button labels but they are English-only.

### Pillar 2: Visuals (2/4)
- Theme setup is good (Material 3, Plus Jakarta Sans plus Noto Sans Devanagari fallback, global dialog/sheet/snackbar/nav themes in app_theme.dart:37-166).
- 129 IconButton against 119 tooltips, and 35 Semantics (some in leaf_components.dart:400, collection_widgets.dart:90, create_post_sheet.dart:1112). Many tappable GestureDetectors have no semantics.
- Icons at size 18 inside `padding: zero` menus (feed_post_card.dart:935-942) are visually and tactilely small.
- Generated book covers and share cards are rich, but cannot be judged without screenshots (not captured).
- 523 `withValues` against 0 `withOpacity`. This is good, so the deprecated API is not used.

### Pillar 3: Color (2/4)
- Theme is built from a ColorScheme (good), but 670 hardcoded colour literals exist in presentation code. 81 are in app_theme.dart itself (expected). Next are reader_screen.dart (46) and interactive_features_sheet.dart (44).
- 284 uses of `Colors.white/black` risk dark-mode contrast failures. For example `backgroundColor: Colors.black54` with `foregroundColor: Colors.white` at create_post_sheet.dart:838-839 is acceptable over images only.
- `Colors.red` as an error or record indicator, and about 71 other raw Colors.red/green/orange/blue/amber uses outside share/cover files, bypass `colorScheme.error` and can fail contrast in one of the two themes.
- Dark-mode awareness is present (47 `Brightness.dark`/`isDark` checks) but is applied ad hoc rather than through theme extensions.

### Pillar 4: Typography (2/4)
- 358 inline `fontSize` values. Distribution: 12 (55), 11 (49), 13 (44), 10 (33), 14 (28), then 18, 9, 8, 16, 20, 17, 30, 15, 24, 22. That is about 20 distinct sizes, plus a stray 13.5 (social_links_menu.dart:45,76).
- 8, 9, 10 and 11sp appear about 102 times, which is below the 12sp accessibility floor.
- 383 `TextStyle(` constructions, so the TextTheme roles are not being used consistently.
- Weights are set inline (for example `w700` at app_theme.dart:321-370), so weights are not constrained to 2-3.
- Good: Devanagari font fallback is configured (app_theme.dart:445-452).

### Pillar 5: Spacing (3/4)
- Most values fall on the 4/8 grid: 16 (329), 8 (308), 12 (273), 4 (148), 24 (98), 20 (86).
- Off-scale: 10 (170), 14 (130), 6 (105), 18 (47), 22, 26, 30, 3, 5, 7, 9. These are too many to read as a deliberate scale.
- No spacing tokens exist. layout_constants.dart only has bottom-nav and mini-player clearances (a good pattern worth extending).
- Fixed widths in non-export UI (feed_post_card.dart:339,845,1312) risk overflow on small phones. 354 maxLines/TextOverflow uses indicate reasonable overflow protection.

### Pillar 6: Experience Design (2/4)
- Positives: 113 `.when/AsyncValue` usages, retry affordances in reader (reader_screen.dart:1090-1183), a conflict-resolution dialog (writer_pad_screen.dart:3355), reduced-animation setting, haptics provider and a compulsory-update gate.
- Failing: silent `SizedBox.shrink()` error and loading branches (see Fix 1). Loading is mostly a bare spinner.
- The error UI leaks raw exceptions (archive_reader_screen.dart:48, leaf_components.dart:1055).
- Tap targets and text-scale gaps (Fixes 4 and 5).
- Dialog and snackbar styling is not centralised for severity.
- Responsive and tablet handling is thin (Fix 7).

## Files Audited
lib/src/presentation/** (screens, components, widgets, theme/app_theme.dart, constants/layout_constants.dart, routing), lib/l10n/app_en.arb, lib/l10n/app_hi.arb. Findings come from pattern greps, not a full line-by-line read, and no screenshots were captured. Verify visual claims on device.
