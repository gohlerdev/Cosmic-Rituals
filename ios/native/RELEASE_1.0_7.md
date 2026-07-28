# TestFlight evidence — 1.0 (7)

Date: 2026-07-28
Bundle ID: `com.cosmic.rituals`
Platform: iOS/iPadOS 26
Disposition: uploaded for internal TestFlight testing only; Apple processing pending

## Delivery result

- Source snapshot: commit `957d21b`.
- App Store Connect delivery UUID:
  `100fee66-edcd-410e-a13d-5d18f2b07b20`.
- Apple transport completed with no errors or warnings.
- The upload began App Store Connect processing at 23:50 IST.
- Export used `testFlightInternalTestingOnly = true`; Apple documents that such a
  build cannot be distributed through external TestFlight or the App Store.
- App Store processing completion and tester-group availability are not yet claimed.

## Reliability fix

- The dedicated `CosmicRitualsTestFlight` scheme now grants clearly labeled testing
  access without depending on App Store product metadata.
- A StoreKit outage or incomplete subscription propagation can no longer prevent
  internal testers from opening Panchang, Timing, Muhurtas, Pooja, or Calendar.
- The standard production `CosmicRituals` Release configuration remains unchanged:
  verified StoreKit entitlement is still required and no testing-access condition is
  compiled into its launch path.

## Quality gate

- Native test suite: 52 passed, 0 failed.
- Focused launch-policy regression: passed.
- Exact TestFlight configuration built, installed, and opened directly into the app
  with the visible `TestFlight testing access` banner.
- Standard production Release configuration separately built and remained on the
  entitlement gate while StoreKit was unavailable.
- Release archive: `/tmp/CosmicRituals-7-TestFlight.xcarchive`.
- Archive bundle/version/build: `com.cosmic.rituals`, `1.0`, `7`.
- Release architecture: arm64.
- Strict signature and privacy-manifest validation: passed.
- App and dSYM UUID matched:
  `AD763FF6-5F1E-30FB-9FE6-3F03393E716E`.
- App Store export re-signed with Apple Distribution, set
  `beta-reports-active = 1`, and set `get-task-allow = 0`.
- No UI-test entitlement token, XCTest, runtime-injection, Guard Malloc, Main Thread
  Checker, or debug launch marker was found in the archived release binary.

## Release boundary

- Build 7 is intentionally unsuitable for App Store submission because it grants
  internal testing access without a purchase.
- Archive the standard `CosmicRituals` scheme for a future App Store candidate after
  subscription products have been verified end to end.
- No App Store version, subscription, external beta group, Beta App Review, App Review,
  or public release action was taken.
