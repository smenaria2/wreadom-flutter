---
status: diagnosed
trigger: "Android Wi-Fi logs show cache misses, short-budget Firestore timeouts, repeated notification failures, and many concurrent live chapter reads."
created: 2026-08-25
updated: 2026-08-25
---

## Symptoms

- Expected: cached Home and previously visited pages render immediately, with at most one bounded background refresh per equivalent read.
- Actual: startup and page navigation can still be delayed; many chapter reads start together, Notifications retries and times out, and Feed has no cache on its first visit.
- Errors: four-second Firestore timeouts, including queued requests with only 68-75 ms remaining; repeated nonblocking Notifications timeout errors.
- Timeline: observed on Android build 2.4.11+83532874 after the cache-first performance release.
- Reproduction: launch on Wi-Fi, use Home, then visit Notifications, Feed, Writer, Messages, and Profile.

## Current Focus

- hypothesis: confirmed. Home and reusable book cards mount per-book live chapter providers, while Notifications bypasses cache-first request coordination.
- test: traced all liveBookChaptersProvider consumers, widget mount counts, request keys, notification refresh triggers, and widget-side error logging against the reported timing sequence.
- expecting: confirmed. Each unique card without readingTimeMinutes starts a chapter cache/server/listener path; notification timeouts leave uncancelled native reads and the same retained error is logged again on rebuild.
- next_action: remove live chapter subscriptions from cards; make live providers disposable; route Notifications first-page reads through the cache-first single-flight helper; log controller error transitions once.
- reasoning_checkpoint: the 68-75 ms server timeouts are consistent with a four-second overall deadline mostly consumed while queued, not with 75 ms native network attempts.

## Evidence

- timestamp: 2026-08-25T00:10:07+04:00
  observation: twelve or more live_chapters_initial_refresh operations time out together, many after only 68-75 ms of execution budget.
- timestamp: 2026-08-25T00:10:07+04:00
  observation: embedded chapter cache reads mostly hit, but initial reads take up to roughly 900 ms during the fan-out.
- timestamp: 2026-08-25T00:10:07+04:00
  observation: homepage_books_with_leaves and book_ids consume the full four-second server budget on Android Wi-Fi.
- timestamp: 2026-08-25T00:10:07+04:00
  observation: Notifications reports repeated four-second failures before eventually producing nonempty state.
- timestamp: 2026-08-25T00:10:07+04:00
  observation: once Feed is mounted, following IDs return in 1.73 seconds and ten posts parse in another 0.87 seconds, indicating feed parsing itself is not the 25-second elapsed value.
- timestamp: 2026-08-25T00:30:00+04:00
  observation: BookCardMetricsRow watches liveBookChaptersProvider for every displayed book lacking readingTimeMinutes, and the provider is not auto-disposed.
- timestamp: 2026-08-25T00:30:00+04:00
  observation: Notifications uses raw query.get followed by Dart Future.timeout instead of FirestoreCacheFirst, so timed-out native reads can overlap later retries.
- timestamp: 2026-08-25T00:30:00+04:00
  observation: Notifications logs the retained error from widget build; rebuilds can duplicate the same UI and collector error pair without a new query attempt.

## Eliminated

- hypothesis: feed merge/parsing is responsible for the full startup delay.
  reason: logged query_merge is 0 ms and the first network refresh after Feed mounts finishes in about 2.6 seconds.
- hypothesis: the trace proves an Android Wi-Fi native transport defect.
  reason: application-created fan-out and queue starvation are sufficient to explain the pattern, while Feed, following, Messages, and a later Notifications refresh succeed on the same session.

## Resolution

- root_cause: Per-card live chapter subscriptions create distinct cache/server/listener reads and exhaust the four shared server slots. Notifications performs an uncoordinated default Firestore get with a non-cancelling Dart timeout and logs retained errors repeatedly from build.
- fix: Remove live chapter providers from list/card metrics, dispose page-owned live providers, add cache-first single-flight notification reads with refresh cooldown, and log errors only on state transitions.
- verification: Diagnosis only; no production code changed. Validate the hotfix with request-count tests and same-device Wi-Fi/mobile timing before considering native mitigation.
- files_changed: none
