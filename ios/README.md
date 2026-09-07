# Cosmic Rituals — Native iOS handoff

This `ios/` section is the canonical, self-contained native SwiftUI application.
It began as a sanitized handoff from the development checkout and now carries its
own tested accuracy and product-integrity improvements.

## Layout

- `native/` — working Xcode project, tests, and product documentation
- `evidence/` — historical handoff screenshots (not current QA evidence)

## Current product state

- Native SwiftUI application targeting iOS 26
- Six selectable light/dark visual themes with Liquid Glass surfaces and motion polish
- Sunrise-anchored Panchang, four limb transitions, three experience layouts,
  location-aware timing, saved preferences, and calculation-integrity disclosure
- Privacy manifest, city data, tests, and app icon assets included
- `CosmicWidgets/` source is preserved, but it is not currently wired as an Xcode widget target and must not be presented as shipping functionality

## Historical release state

- The imported handoff had simulator design QA on iPhone 17 / iOS 26.5.
- TestFlight version 1.0 build 3 was uploaded from the earlier development checkout.
- Those facts do not prove that the current source is release-ready; rerun the
  build, tests, and simulator QA below for every change.

## Build and test

Run from this repository's `ios/native` directory:

```bash
xcodebuild \
  -project CosmicRituals.xcodeproj \
  -scheme CosmicRituals \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

xcodebuild \
  -project CosmicRituals.xcodeproj \
  -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Initial-import provenance

- Copied read-only from `/Users/psy/Documents/Gohler/Cosmic-Rituals`
- Snapshot date: 2026-07-26
- Included source files: 41
- Original aggregate relative-path/content SHA-256: `80bab676abbf21a77da200b60ab534e37318af6dfe6f018d099dd7a679430495`
- Excluded: `.DS_Store`, user Xcode state, DerivedData, build products, archives, and signing material

`SNAPSHOT.sha256` records that import only. It is intentionally not a checksum of
the evolving canonical source tree.
