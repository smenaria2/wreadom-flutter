# Collections feature improvements

## Goal

Polish collections on author profiles and the collection detail screen, fully localize collection-facing text in English and Hindi, and publish the verified Android release to the Google Play internal track.

## Scope and implementation plan

### 1. Complete collection localization

Files:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_hi.arb`
- Generated localization files under `lib/src/localization/generated/`
- `lib/src/presentation/components/collections/horizontal_collections_list.dart`
- `lib/src/presentation/components/collections/rounded_collection_card.dart`
- `lib/src/presentation/components/collections/collection_form_sheet.dart`
- `lib/src/presentation/components/collections/add_to_collection_sheet.dart`
- `lib/src/presentation/screens/collection_detail_screen.dart`
- Collection-related route/error strings if they are user-visible

Actions:

1. Inventory every hard-coded, user-visible collection string, including labels, tooltips, validation messages, empty/error states, singular/plural book counts, delete confirmation, edit/create actions, and add/remove flows.
2. Add English and Hindi ARB entries, using parameterized messages for errors and ICU plural messages for book counts.
3. Replace literals with `AppLocalizations` lookups.
4. Run `flutter gen-l10n` so generated localization classes remain synchronized.

Acceptance:

- No collection-facing English literal remains in the collection profile/detail/form/add-books UI.
- English and Hindi show correct singular/plural book counts.
- Both locales compile without missing localization getters.

### 2. Separate collections from the author's works

Files:

- `lib/src/presentation/components/profile/user_content_tab.dart`
- `lib/src/presentation/components/collections/horizontal_collections_list.dart`

Actions:

1. After the horizontal collections section, render a visual separator and localized **Author's works** header before the books grid.
2. Show the separator/header only when at least one real collection exists. The owner-only **New collection** tile does not count as an existing collection.
3. Expose collection-presence state from `HorizontalCollectionsList` or compose both sections from the same provider so visibility is derived from the loaded collection list without duplicate visual loading states.
4. Preserve the current empty-books message below the new header when collections exist but the author has no published books.

Acceptance:

- With one or more collections: collections strip -> separator -> localized Author's works -> book content.
- With no collections: no separator or Author's works header is introduced.
- Owner and public-profile behavior remain consistent.

### 3. Simplify and resize the collection detail screen

File:

- `lib/src/presentation/screens/collection_detail_screen.dart`

Actions:

1. Remove the **Stories inside collection** heading and its reserved spacing.
2. Move the owner-only **Add books** action into the app-bar actions immediately beside the Share action. Use a localized tooltip and an unambiguous add-to-books icon; retain loading/disabled behavior.
3. Make the collection hero cover circular by clipping the 120x120 foreground collage to a circle while leaving the blurred full-width background intact.
4. Remove the edit icon beside the subtitle/description and the separate empty-description edit affordance. Keep one edit icon beside the title; opening it continues to edit both title and description in the existing form.
5. Display the localized book count directly below the subtitle/description in the expanded header. Define the no-description layout so the count still occupies the same stable position.
6. Remove the old body-level book count and Add books button after their information/actions move into the header/app bar.
7. Match the collection books grid cover/card sizing to the profile content books grid: three columns, the same child aspect ratio and spacing used by `UserContentTab`, with responsive validation on narrow phones. Prefer extracting shared grid constants rather than duplicating magic numbers.
8. Preserve owner-only remove and drag-reorder controls without obscuring the resized covers.

Acceptance:

- No **Stories inside collection** text appears.
- The foreground collection icon is round.
- Collection book covers visually match profile content book covers at the same viewport width.
- Add books appears beside Share only for the collection owner and opens the existing selector.
- Only the title row has an edit button, and that button edits both fields.
- Book count appears below the subtitle and updates after add/remove operations.

### 4. Tests and visual verification

Files:

- Add focused widget tests under `test/` for the collections profile section and collection detail screen.

Checks:

1. Test conditional Author's works visibility for zero and non-zero collections.
2. Test owner versus visitor actions on collection detail.
3. Test absence of **Stories inside collection** and the subtitle edit icon.
4. Test localized singular/plural book counts in English and Hindi.
5. Test that title edit opens a form containing both title and description fields.
6. Run `dart format` on changed Dart files.
7. Run `flutter analyze` and the focused tests, followed by the full `flutter test` suite.
8. Run the root web-preview script and visually compare English/Hindi, owner/visitor, empty/populated collections, and narrow/wide layouts against the supplied screenshots.

## Release

After all checks pass:

1. Inspect `git status` and ensure only intended release changes will be included. This matters because `publish_play_store.ps1` runs `git add -A` and creates a release commit.
2. Run the root `publish_play_store.ps1` script in the normal host PowerShell session, outside the sandbox, as required by `AGENTS.md`.
3. Confirm the script builds the release AAB, publishes successfully to the Google Play **internal** track, and completes its subsequent production Vercel deployment.
4. Record the published version/build number and report any Play Store or Vercel failure without claiming release success.

## Definition of done

- Every scoped UI and localization acceptance criterion passes.
- Formatting, analysis, focused tests, and full tests pass.
- Visual QA passes for English and Hindi on representative mobile widths.
- The Play Store internal-track upload and the script-triggered Vercel deployment both succeed.
