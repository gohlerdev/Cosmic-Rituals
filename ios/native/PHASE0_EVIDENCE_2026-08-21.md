# Phase 0 evidence — 2026-08-21

Scope: the Phase 0 rebaseline items that can be verified locally, plus a first pass at the
§10 acceptance slice. Distribution state (App Store Connect, TestFlight build 7) was **not**
touched or verified — that requires a signed-in session and explicit authorization.

Status vocabulary follows `NEXT_LEVEL_PLAN.md` §3.

| Field | Value |
| --- | --- |
| Branch | `codex/cosmic-rituals-modernization` |
| Commit | `8d1fe69` — Add recoverable ritual journey foundation and plan |
| Working tree | Clean at start of run (only untracked `CLAUDE.md`, added this session) |
| Host | macOS (Darwin 25.6.0), Xcode at `/Applications/Xcode.app` |
| Runtime | iOS 26.5 (23F77) Simulator |
| Configuration | `Debug` (unsigned, `CODE_SIGNING_ALLOWED=NO`) |

## 1. Repository truth (verified)

`xcodebuild -list` confirms the project matches what the plan and docs describe:

- Targets: `CosmicRituals`, `CosmicRitualsTests`
- Build configurations: `Debug`, `Release`, `TestFlight`
- Schemes: `CosmicRituals`, `CosmicRitualsTestFlight`

Deployment target 26.0, bundle id `com.cosmic.rituals`, `CURRENT_PROJECT_VERSION = 7`,
`MARKETING_VERSION = 1.0`. `TESTFLIGHT_BETA_ACCESS` appears only in the `TestFlight`
configuration and is consumed only at `CosmicRituals/Views/RootView.swift:24`.

## 2. Build — **Built**

```
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derived-data CODE_SIGNING_ALLOWED=NO build-for-testing
```

Result: `** TEST BUILD SUCCEEDED **` (exit 0). No warnings surfaced in the tail of the log.

## 3. Automated tests — **Tested**

```
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,id=<CosmicRituals-QA-iPhone17>' \
  -derivedDataPath .derived-data CODE_SIGNING_ALLOWED=NO test
```

Result: `** TEST SUCCEEDED **` — **55 passed, 0 failed**, all in `CosmicEngineTests`.

Directly relevant to the §10 slice:

- `testRitualSessionSurvivesRelaunchCompletionAndRestart` — passed
- `testRitualSessionRejectsUnknownMaterialAndRecoversFromInvalidStorage` — passed
- `testRitualDayContextStatesFactsWithoutInventingAnObservance` — passed
- `testPoojaVidhiCatalogIsStructuredCompleteAndTraceable` — passed
- `testPoojaPrimaryScreensRenderAtPhoneAndAccessibilitySizes` — passed

## 4. Device install and launch — **Built / partially user-verifiable**

Fresh simulators were created for this run so "fresh install" means what it says:

| Simulator | Device | Purpose |
| --- | --- | --- |
| `CosmicRituals-QA-iPhone17` | iPhone 17 | Test-suite host |
| `CosmicRituals-Walkthrough-iPhone17` | iPhone 17 | App walkthrough |
| `CosmicRituals-QA-iPad` | iPad Pro 13-inch (M5) | iPad layout |

Install and launch both succeed on a clean device. No crash, no hang.

### 4.1 Fresh install with no App Store session

Screenshot `02-first-screen.png`. On a fresh install with no entitlement and no App Store
connection, the app lands on the Premium gate showing **"The App Store is unavailable —
Subscriptions are temporarily unavailable. Check your connection and try again."** with
*Try again* and *Restore purchases*, plus the disclosure that *"Existing verified access is
preserved when product information cannot load."*

This is a designed, honest state rather than a crash or a silent hang, and it matches the
`SubscriptionStore` contract. It is recorded here because Phase 0's exit gate asks that every
launch blocker be reproduced and classified: **classification = StoreKit metadata
unavailable in a simulator with no App Store account**, not a code defect.

Consequence worth noting for Phase 1: the entire offline product sits behind this gate, so a
brand-new user with no connectivity currently cannot reach any offline content. Phase 1
already owns "explicit, human-readable recovery actions for offline StoreKit"; this run
confirms the state is reachable on a clean device.

For the remaining walkthrough the app was launched with the DEBUG-only `-uiTestingPremium`
argument, which is compiled out of Release.

## 5. §10 acceptance slice — partial

### 5.1 Verified

**Factual ritual context, no fabricated recommendation.** Screenshots `04`, `07`, `08`.
The Pooja surface renders a *Ritual context* card marked `CALCULATED`:

> Friday, 21 August 2026 · New Delhi, India · Asia/Kolkata
> Navami · Anuradha · Sunrise 5:53 AM
> "Use these sunrise-anchored facts to confirm timing with your family, temple, or
> practitioner. They do not make one Pooja universally required today."

Date, location label, IANA time zone, tithi, nakshatra, and the sunrise reference are all
present, and the copy explicitly refuses to convert those facts into an obligation. This is
what plan §5.2 and §10 ask for.

**Session recovery across a cold start.** Screenshot `08-ipad-resume.png`.
A mid-ritual session was seeded into the app's persisted state (`daily-panchopachara`,
`status = inProgress`, `currentStepIndex = 4`, four prepared materials), the **simulator was
fully shut down and rebooted**, and the app was launched cold. The library surfaced:

> **Continue your ritual**
> Daily Panchopachara Pooja
> Resume step 5 of 12

Reading the persisted state back after that launch shows the session intact — same step
index, same four material IDs — proving the load → `reconcileWithCatalog` → `persist` round
trip preserves progress rather than resetting it. A full device reboot is a stricter
interruption than the force-quit the plan asks for.

**Accessibility at the largest Dynamic Type size.** Screenshot `09-ipad-ax-largest.png`.
At `accessibility-extra-extra-extra-large` the context card, disclosure copy, and the
"Change calculation location" action all scale without clipping or truncation, and the tab
bar collapses to icons — consistent with the passing
`testAccessibilityLargeDestinationLayoutUsesIconsWithoutLosingLabels`.

**iPad layout.** Screenshot `08`. The Pooja surface, category filters, 12-guide list, and
tab bar lay out correctly on iPad Pro 13-inch in portrait.

### 5.2 Interactive legs — now covered by an automated UI test

The first pass of this run could only inject session state, because `xcrun simctl` can
install, launch, terminate, and screenshot but cannot tap. That gap is now closed by a new
`CosmicRitualsUITests` target rather than by a one-off manual pass, so the slice stays
verified on every future run instead of decaying into a claim.

`RitualJourneyUITests.testCompleteRitualJourneySurvivesForceQuitAndResumesAtCorrectStep`
drives the shipping app and asserts, in order:

1. The context card is labelled `CALCULATED` and carries the no-obligation disclaimer.
2. A guide opens from the library by tap.
3. *Prepare materials*, *Safety and respectful closure*, and *Tradition and sources* are
   all reachable before practice starts.
4. Tapping the required material moves readiness from `Required 0/1` to `Required 1/1`.
5. Guided practice begins, rewinds to step 1, and three taps of **Next** reach step 4.
6. `app.terminate()` force quits the process.
7. After relaunch the resume card reads exactly `Resume step 4 of 12`.
8. Tapping it lands on step 4.
9. Advancing to the end and tapping **Complete** reaches "Pooja complete", shows the
   *Close respectfully* items, and offers a deliberate restart rather than auto-resetting.

Supporting tests in the same target: a priest-boundary content check on
`satyanarayana-vrata`, two `performAccessibilityAudit()` passes (library and guided
practice), a guard that a completed ritual is not advertised as unfinished work, and an
`XCTApplicationLaunchMetric` cold-launch measurement.

The app's own source was not modified to make this possible — it already carried the
identifiers `pooja.library`, `pooja.dayContext`, `pooja.vidhi.*`, `pooja.begin.*`,
`pooja.resume.*`, and `pooja.guided.*`.

Two SwiftUI details are worth recording, because they cost a debugging cycle and will cost
another if forgotten. `pooja.library` lands on a **ScrollView**, so type-specific queries
such as `app.otherElements["pooja.library"]` match nothing. And `.accessibilityIdentifier`
applied to the guided view's `ZStack` **propagates to its children**, so
`pooja.guided.<id>` matches the background image, the scroll view, and both navigation
buttons. The tests therefore query with `descendants(matching: .any)`: which view type
receives a SwiftUI modifier is not part of the app's contract, and asserting on it makes
tests brittle for no benefit.

Still not covered by automation: explicit start-over/discard confirmations, and the
Share/PDF export path from the guide detail toolbar.

### 5.3 Method note

Seeding required care and the first three attempts produced a misleading result worth
recording, since anyone repeating this will hit it:

- `xcrun simctl spawn <sim> defaults write com.cosmic.rituals …` writes the simulator's
  **device-level** `data/Library/Preferences/` plist, not the app's container plist.
- The app reads a merged view but persists to its **container** plist. Because the app writes
  an empty session envelope on first launch, that empty container value shadowed every seed
  placed at the device level, which looked exactly like the app discarding valid sessions.
- `killall` does not exist in the simulator's `simctl spawn` environment, so cfprefsd cannot
  be reset that way; its in-memory cache kept overwriting direct file writes.

The reliable method is: terminate the app, **shut the simulator down**, write the seed into
the app container's `Library/Preferences/com.cosmic.rituals.plist`, boot, then launch.

No app defect was found here — the earlier "sessions wiped" readings were entirely an
artifact of writing to the wrong preferences domain.

## 6. Performance — **Measured**

`CosmicRitualsTests/PerformanceTests.swift` records these on the reference runner
(iPhone 17 simulator, iOS 26.5, Debug). No baselines are committed: these are recordings,
not asserted ceilings, because a baseline set on one machine fails on another for reasons
unrelated to the code.

| Measurement | Average |
|---|---|
| Daily Panchang calculation (with transitions) | ~1 ms |
| Full daily surface (limbs, muhurtas, choghadiya, hora, all kala) | ~1 ms |
| Monthly calendar, 31 transition-free cells | <1 ms |
| PDF export | 7 ms |
| City catalog load (33,909 rows) | 141 ms |
| City search, 3 worst-case prefix queries | 357 ms |
| Peak physical memory across the above | 85–90 MB |

The engine is not a performance concern. The four boundary solves dominate a single day,
which is why a whole month of transition-free cells costs less than one day *with*
transitions — the `includeTransitions: false` path is doing its job.

**The one number worth acting on is city search: ~120 ms per query**, a linear scan over
33,909 rows wired to a search-as-you-type field. `WorldCityCatalog.search` has no
`Task.isCancelled` check inside the loop and `scheduleSearch` only tests cancellation after
the scan returns, so a superseded keystroke still pays for a full scan. Recorded here as a
finding; not fixed in this pass.

## 7. Accessibility remediation — **Implemented and tested**

The two `performAccessibilityAudit()` passes were not clean on first run: **29 issues** on
the Pooja library and **9** in guided practice. Rather than record them as debt, they were
traced to source and fixed, then re-measured.

### 7.1 What was fixed

**31 edits across 8 files.** The app's ceremonial design was not flattened; no engine code
was touched.

*Hit targets and VoiceOver semantics (17 edits).* The 4 pt `Pooja progress` bar carried the
step announcement, so the only element speaking progress was 4 pt tall — the announcement
moved onto the ~39 pt header and the bar is now `accessibilityHidden`. Muhurta quality
reached the user only as colour plus `★★`/`★`/`◐`/`✕` glyphs, which VoiceOver reads as
symbol names; every muhurta row, the NOW banner, the summary pills, Choghadiya rows, and the
Favourable/Best-avoided lists now carry spoken equivalents built from existing `rawValue`
content — **no new ritual content was authored**. Calendar chevrons said "chevron.left"; the
theme picker emitted no element at all for its `Canvas`-drawn selection state. Legal links in
the paywall were ~45×16 pt each despite a 44 pt container.

*Dynamic Type (5 edits).* `ViewThatFits` never reflowed the day-context pills — the audit
frames showed all three still on one line — so `Dashami`, `Jyeshtha` and `Sunrise 5:54 AM`
were **fully** unscalable. Replaced with an explicit `dynamicTypeSize > .large` branch,
matching the pattern already used in `RitualResponsiveLayout`. The `REQUIRED` material badge
was pinned at 9 pt — two points below the iOS minimum, on safety-relevant content.

*Contrast (2 edits).* `semanticSecondaryText` 0.72/0.76 → 0.80/0.82 and
`semanticTertiaryText` 0.60/0.62 → 0.70/0.72.

### 7.2 Result, measured

| Surface | Before | After | Detail |
| --- | --- | --- | --- |
| Pooja library | 29 | **27** | dynamicType 11 → 8 (all *fully unsupported* gone); contrast 18 → 19 |
| Guided practice | 9 | **7** | hitRegion 1 → **0**; contrast 6 → 5; dynamicType 2 → 2 |

Two whole classes of finding are eliminated: **no hit-region failures remain anywhere**, and
**no element is fully Dynamic Type unsupported** — what survives is "partially unsupported".

**Contrast barely moved, and that is the informative result.** Raising text opacity makes
light-on-dark text *lighter*, which helps over the dark card scrim and actively hurts where
the sanctuary photograph's bright lamp cores composite through. The net was −1 across both
surfaces: `Jyeshtha` and `2 sources` were fixed, and the library's household-disclaimer
paragraph newly failed. The root cause is not the text token — it is translucent glass over a
bright photograph, and the real fix is the readability veil, deliberately **deferred**: it
re-tunes the signature background across all six themes, and the supporting measurement
sampled one image asset. `NEXT_LEVEL_PLAN.md` Phase 4's exit gate requires measured contrast
for *every* theme and image crop, so it should land there, measured, not here, extrapolated.

### 7.3 The audits are now a guard, not a ledger

The audit tests previously used `XCTExpectFailure(strict: false)`, which can never fail —
including for a brand-new regression. That is gone (`XCTExpectFailure` count in the target is
**0**). In its place, `auditBudget` records the surviving debt per surface per audit type,
and the assertion fails three ways:

- **REGRESSION** — any type exceeds its recorded count.
- **NEW AUDIT TYPE** — a class of finding appears that was never budgeted (exactly what
  `strict: false` was blind to).
- **STALE BUDGET** — the surface improved but the number was not lowered, so a fix cannot be
  silently reverted.

The budget keys on `XCUIAccessibilityAuditType.rawValue`, not on Apple's wording, so a
reworded system string cannot masquerade as a new defect. Runs pin
`UICTContentSizeCategoryL`, because both contrast and Dynamic Type counts move with text
size and an unpinned number is not reproducible.

Recorded budget: `pooja-library` contrast 19 / dynamicType 8; `guided-practice` contrast 5 /
dynamicType 2. The `hitRegion` entry was deleted rather than set to zero.

### 7.4 Verification after the change

- `build-for-testing`: **succeeded**
- `CosmicRitualsTests`: **62 passed, 0 failed** — including the two contrast guard tests,
  which the token change moves further into safety (secondary 6.36 → 8.35 : 1)
- `CosmicRitualsUITests`: **6 passed, 0 failed**, with the real budget guard
- Visual check at default text size: ceremonial design unchanged, body copy visibly more
  legible (`10-after-fixes-library.png`)

### 7.5 Known debt deliberately left

`'Household adaptation'` and `'2 sources'` remain partially Dynamic Type unsupported at
`.caption2`; `MuhurtaSummaryPill`'s visible label is still `.system(size: 8)`; and
`ChoghadiyaHoraView` carries seven more fixed-size fonts. None sit on a path this pass
touched. They are inside the recorded budget — bounded, not silenced.

### 7.6 Device and appearance matrix — **Tested**

The §10 journey and the priest-boundary check were run across five configurations after
every fix landed. All pass.

| Configuration | Result |
| --- | --- |
| iPhone 17, dark, default text | PASS |
| iPhone 17, light, default text | PASS |
| iPhone 16e (small), dark, default text | PASS |
| iPad Pro 13-inch, dark, default text | PASS |
| iPhone 17, dark, `accessibility-extra-extra-extra-large` | PASS |

The accessibility-size run initially failed, and the cause is worth recording because it
will recur. Both Pooja surfaces are `LazyVStack`s, so an element that has not been scrolled
toward **does not exist in the hierarchy at all** — `exists` is false, not merely
`isHittable`. Most scroll helpers test hittability, which silently does the wrong thing
here: the element is not waiting to be revealed, it has not been built. A fixed swipe budget
also cannot span text sizes (three swipes at default, dozens at XXXL), so the helper scrolls
until content stops advancing and treats its cap as a runaway guard rather than the exit
condition. End-of-content is detected from the last materialised text's label and frame
origin — a prefix of static-text labels is a false constant, because query order is not
visual order and the leading entries (navigation bar, sticky header) never change while the
body scrolls.

This was a **test defect, not an app defect**: a real user scrolls and reaches everything.

## 8. Not measured / not done

- Landscape, the other five themes, VoiceOver *order* (labels and traits are now covered),
  Voice Control, Switch Control, Increase Contrast, Differentiate Without Color, Reduce
  Motion, Reduce Transparency, grayscale.
- Upgrade-from-build-7, airplane mode, denied location, stale GPS, time-zone change, and
  date-line change scenarios.
- Any App Store Connect or TestFlight verification.
- Internal tester questions.

## 9. Artifacts

Screenshots: `../../evidence/2026-08-21/` (untracked; ~19 MB)

| File | Shows |
| --- | --- |
| `01-fresh-launch.png` | Launch animation (incidental) |
| `02-first-screen.png` | Fresh install → Premium gate, App Store unavailable |
| `03-resume-after-coldlaunch.png` | Pooja surface, default text size |
| `04-resume-card-xs.png` | Ritual context card fully visible, extra-small text |
| `05-resume-seeded.png` | Seeding attempt via wrong preferences domain |
| `06-plist-probe.png` | Probe that identified the container/device plist split |
| `07-resume-verified.png` | iPhone after successful seed + reboot |
| `08-ipad-resume.png` | **"Continue your ritual — Resume step 5 of 12"** after cold boot |
| `09-ipad-ax-largest.png` | Largest accessibility Dynamic Type size |

Simulators created for this run are still present and can be removed with
`xcrun simctl delete "CosmicRituals-QA-iPhone17" "CosmicRituals-Walkthrough-iPhone17" "CosmicRituals-QA-iPad"`.

## 10. Assessment against the Phase 0 exit gate

| Exit-gate item | State |
| --- | --- |
| Evidence report distinguishing observed / tested / unverified | Met by this document |
| App opens without unexplained App Store connection failure | Opens; the App Store failure is explained and classified above |
| Every launch blocker reproduced and classified | One reachable gate state found and classified |
| No later phase relies solely on July 2026 TestFlight evidence | Repository and simulator evidence is now dated 2026-08-21; **App Store Connect state still unverified** |

Phase 0 is **not** complete. Device performance numbers, the wider accessibility and
interruption matrix, and all distribution verification remain outstanding.
