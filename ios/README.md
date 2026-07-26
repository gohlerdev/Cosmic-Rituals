# Cosmic Rituals — Native iOS handoff

This `ios/` section is an additive, self-contained snapshot of the completed native SwiftUI application. The GitHub repository was empty when cloned; its remote and new local history remain intact.

## Layout

- `native/` — exact sanitized snapshot of the live Xcode project
- `evidence/` — selected final simulator screenshots

## Current product state

- Native SwiftUI application targeting iOS 26
- Six selectable light/dark visual themes with Liquid Glass surfaces and motion polish
- Ritual-now guidance, Panchang/five-limb context, Vedic ledger, location support, and saved preferences
- Privacy manifest, city data, tests, and app icon assets included
- `CosmicWidgets/` source is preserved, but it is not currently wired as an Xcode widget target and must not be presented as shipping functionality

## Verification already completed

- Simulator design and experience QA completed on iPhone 17 / iOS 26.5
- Native project and unit-test target are included under `native/`
- TestFlight: version 1.0, build 3 uploaded successfully; archive/build products are intentionally excluded from source control

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

## Snapshot provenance

- Copied read-only from `/Users/psy/Documents/Gohler/Cosmic-Rituals`
- Snapshot date: 2026-07-26
- Included source files: 41
- Aggregate relative-path/content SHA-256: `80bab676abbf21a77da200b60ab534e37318af6dfe6f018d099dd7a679430495`
- Excluded: `.DS_Store`, user Xcode state, DerivedData, build products, archives, and signing material

