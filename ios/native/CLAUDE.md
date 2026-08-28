# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Cosmic Rituals is a dependency-free native SwiftUI iOS app for the Vedic **Panchang**
(five limbs), the **30 muhurtas**, auspicious/inauspicious kala, and 12 offline
**Pooja Vidhi** guides. Everything is computed on-device and fully offline. It is a
focused extraction from the parent Cosmic Astrology app (`ios/old/CosmicAstrology`) —
natal-chart, dasha, ascendant, and divisional-chart machinery were deliberately left
behind and should not be reintroduced.

## Commands

Build and test run through `xcodebuild`; there is no package manager, lint config, or
CI script in the repo.

`NEXT_LEVEL_PLAN.md` §9 mandates this pair as the minimum any native source change must
pass — compile generically first, then test against a concrete simulator:

```bash
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build-for-testing

xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,id=<available-simulator-uuid>' \
  CODE_SIGNING_ALLOWED=NO test
```

Use `xcrun simctl list devices available` to get a UUID. `-destination
'platform=iOS Simulator,name=iPhone 17,OS=latest'` also works for local iteration.

```bash
# Run a single test (the suite spans CosmicEngineTests plus sibling files -- PersonalStar, PanchangYoga, CelestialRiseSet, Performance, ReleaseBoundary and more; ~125 cases and growing)
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:CosmicRitualsTests/CosmicEngineTests/testRitualSessionSurvivesRelaunchCompletionAndRestart test
```

Add `-derivedDataPath .derived-data` to reuse the repo-local (gitignored) derived data
and avoid full rebuilds.

Consequential candidates additionally require standard `Release` and dedicated internal
`TestFlight` archive inspection plus real-device evidence — see the release boundary below.

Targets: `CosmicRituals` (app) and `CosmicRitualsTests` (XCTest, `@testable import`).
Deployment target **iOS 26** (the muhurta pills use the iOS 26 `.glassEffect` API);
Swift 5 language mode; bundle id `com.cosmic.rituals`; team `DJJ824N6RB`.

## Build configurations

Three configurations, not the usual two:

| Config | Scheme | Notes |
|---|---|---|
| `Debug` | `CosmicRituals` | Defines `DEBUG` |
| `Release` | `CosmicRituals` | The only valid public App Store configuration |
| `TestFlight` | `CosmicRitualsTestFlight` | Defines `TESTFLIGHT_BETA_ACCESS` |

`TESTFLIGHT_BETA_ACCESS` now only stamps a provenance marker into the binary
(`ReleaseChannel`), so a release inspector can tell which configuration produced an
archive. It grants nothing: the app is free, so there is no access to bypass. **A
build made with this configuration must still never be promoted or repurposed as a
public App Store candidate.** A public candidate uses a new build number and the standard
`Release` configuration.

## Project file

`CosmicRituals.xcodeproj` uses a **file-system–synchronized root group**
(`PBXFileSystemSynchronizedRootGroup`, Xcode 16+) rooted at `CosmicRituals/`. New files
placed under that directory — including resources like `world_cities.tsv` — are picked
up automatically; do not hand-edit `project.pbxproj` to add sources. `Info.plist` is
generated from build settings (`GENERATE_INFOPLIST_FILE = YES`), so Info.plist keys are
set via `INFOPLIST_KEY_*` build settings.

Consequence worth knowing: **`CosmicWidgets/` sits outside the synchronized group and is
not a target.** That source does not compile and is not shipped. Per `ACCURACY.md` it is
not a widget until an extension target, App Group, signing capability, and end-to-end
tests exist.

## Architecture

The golden rule, inherited from the Cosmic Astrology family: **the engine never imports
SwiftUI, and the views never do astronomy.**

- `CosmicRituals/Engine/` — pure Foundation. `CosmicEngine` is an `enum` namespace of
  static functions implementing a sidereal ephemeris (Meeus algorithms, Lahiri /
  Chitra Paksha ayanamsha). `PanchangModels.swift` holds the value types;
  `MuhurtaLibrary` adds per-muhurta classical detail keyed by id 1–30;
  `PoojaVidhiCatalog` is pure data with deterministic search and executable validation.
- `CosmicRituals/Theme/CosmicTheme.swift` — the cosmic-glass palette, components,
  responsive navigation, and motion safeguards.
- `CosmicRituals/Views/` — `RootView` selects the Premium gate or the main experience;
  `PanchangView` owns the date, destination, preferences, and `LocationManager`.

### CalculationContext is the calculation contract

Every location-aware engine call takes a `CalculationContext` — a civil date bound to
explicit coordinates and an **IANA time zone**. Most engine functions have a legacy
`(date:latDeg:lonDeg:)` overload alongside the context overload; prefer the context one
in new code.

Rules that the tests enforce and that changes must preserve:

- A Panchang day is anchored to **sunrise at the selected location**; the five limbs are
  evaluated at that instant.
- Formatting uses the calculation location's time zone, never the device's.
- The daily snapshot is cached **together with its context**, so SwiftUI never renders
  values from a previous location while recomputation is in flight.
- New Delhi is the visible first-run default, not a hidden fallback. Once a city or
  current location is chosen, every calculation, export, and App Intent uses it.
- When sunrise does not exist for the latitude and date, the app does **not** fabricate
  sunrise-derived schedules — the snapshot falls back to 12:00 local civil time and the
  UI labels the fallback. Muhurta, Choghadiya, Hora, Rahu Kala, Yamaganda, Gulika,
  Abhijit, Brahma Muhurta, and Dur Muhurta simply have no result.

### No paywall

**Cosmic Rituals is free. There is no paywall, no account, no purchase, and no
StoreKit code path**, and a test (`testTheAppShipsFreeWithNoStoreCodePath`) fails the
build if any source file reintroduces `import StoreKit` or a `SubscriptionStoreView`.

This replaced a StoreKit 2 subscription gate that failed CLOSED: when the products
were not purchasable in App Store Connect, real devices reached a paywall that could
not be priced and a Panchang that could not be opened — an app that needs no network
at all, sealed by a store fault the user could do nothing about. Everything here is
computed on-device at no marginal cost, so the gate was never worth its failure mode.
`AppLinks` keeps the privacy, terms, and support URLs a shipped app owes its users.

### Ritual session recovery

`RitualSessionStore` persists the minimum durable state needed to resume an interrupted
ritual (status, prepared material ids, step index) to `UserDefaults` under a versioned
key, with small synchronous writes. It intentionally stores no location, religious
profile, analytics identifier, or cloud data. No ritual completion, search text, or
religious preference leaves the device.

## Content and accuracy policy

These are correctness constraints, not preferences. Read `POOJA_CONTENT.md` and
`ACCURACY.md` before touching ritual content or calculations.

- **Never synthesize ritual material.** Initiatory bija-mantras, nyasa, Vedic recitation,
  homa, formal kalasha installation, and lineage-specific visarjana are out of scope.
  Priest-recommended guides stop at the officiant's boundary. The Satyanarayana katha
  must be locally received, not generated.
- The catalog distinguishes `simpleHousehold`, `extendedHousehold`, and
  `priestRecommended`; keep that boundary intact. `PoojaVidhiCatalog.validationIssues`
  must stay empty — it checks unique ids, sequential steps, preparation detail, safety
  notes, source transparency, and complete mantra fields.
- Rituals guarantee no material, medical, legal, relationship, or astrological outcome.
  Fasting is optional and never prescribed. Participation is never restricted by caste,
  gender, menstruation, marital status, or birth.
- **Quarantined work stays quarantined.** Experimental festival, extended Vedic-calendar,
  moonrise/moonset, and low-precision Graha-position code exists in the repo but is not
  routed into shipping navigation. Do not surface it or describe it as available until it
  has independent fixtures and visible precision disclosures.
- Test fixtures record their external source (timeanddate.com, NAOJ, Griffith Observatory,
  published Mumbai/Hyderabad tables) beside the expected value, precisely so an ephemeris
  change cannot update implementation and expectation together. When a fixture fails,
  fix the engine or justify the fixture against its source — do not silently retune it.
- The solver converges to sub-second resolution; that describes the solver, not the
  accuracy of the compact model. The published comparison envelope is ±12 minutes.

## Release boundary

Per `NEXT_LEVEL_PLAN.md`, distribution actions are separate from engineering and each
requires explicit authorization at the time it occurs: TestFlight upload, App Store
Connect mutation, external tester distribution, review submission, pricing changes,
subscription activation, and public release. Do not perform any of them on your own
initiative. Any build made with the `TestFlight` configuration is internal-testing-only, whatever its build number.

Use the plan's status vocabulary precisely when reporting: *planned, implemented, built,
tested, user-confirmed, uploaded, testing, release candidate, release-approved, live*.
A green build is not a tested product.

## Current milestone

`NEXT_LEVEL_PLAN.md` §10 names one vertical slice to finish and independently verify
before any catalog breadth, redesign, or platform extension work:

> Choose one of the twelve reviewed rituals → see the exact civil date, location, IANA
> time zone, and sunrise context with no fabricated recommendation → prepare required
> materials → begin offline → advance several steps → force quit → reopen → resume at
> the correct step → complete respectful closure → inspect the guide's safety, sources,
> and tradition boundaries.

`RitualSessionStore`, `RitualDayContext`, and the `PoojaVidhiViews` wiring are the
foundation for this slice (plan §4.3), not a claim that it is complete.

## Reference docs

`ARCHITECTURE.md` (engine details, what was imported from the parent app) ·
`ACCURACY.md` (method provenance, fixtures, tolerances, quarantined prototypes) ·
`POOJA_CONTENT.md` (ritual content contract and sources) ·
`SUBSCRIPTION_RELEASE.md` (product ids, App Store Connect setup, sandbox matrix) ·
`NEXT_LEVEL_PLAN.md` (current product/accuracy/release plan) ·
`PRODUCT_IDENTITY.md`, `ROADMAP.md`, `APP_STORE_SUBMISSION.md`, `design-qa.md`,
`ART_ASSET_PROVENANCE.md`.
