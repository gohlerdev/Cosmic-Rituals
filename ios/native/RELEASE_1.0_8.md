# TestFlight evidence — 1.0 (8)

Date: 2026-08-22
Bundle ID: `com.cosmic.rituals`
Platform: iOS/iPadOS 26
Configuration: `TestFlight` — internal testing only
Disposition: uploaded via Transporter (reported by Gohler, 2026-08-22); App Store Connect
processing status, group assignment, and tester invitations not independently verified by
this session.

## What this build contains

First TestFlight build since `7` (2026-07-28, commit `957d21b`). Source snapshot at build
time: commit `039158a`.

Between 7 and 8:

- Accessibility remediation across eight files. Hit-region findings eliminated; no element
  is fully Dynamic Type unsupported. Muhurta quality, the NOW banner, Choghadiya rows, and
  the Favourable/Best-avoided lists now carry spoken equivalents built from existing
  content — no ritual material was authored.
- The sanctuary photograph is dimmed on dark themes (`imageOpacity` 0.78 → 0.52), measured
  against all three dark palettes rather than extrapolated from one asset.
- Offline city search: ~104 ms → ~16 ms per keystroke, by preparing the index once at load
  instead of folding 33,909 names per keystroke.
- Four access-reliability defects fixed, each of which could lock out a paying user: a
  refresh that dropped concurrent calls, a failed restore that revoked verified access,
  transactions that were never finished, and `.checking` with no deadline.
- Subscription failure states now name their cause instead of always blaming the network.
- Renewal status is read, so a failing payment is visible before access ends.

## Verification before upload

- `build-for-testing`: succeeded.
- `CosmicRitualsTests`: 91 passed, 1 skipped.
- `CosmicRitualsUITests`: 6 passed, including the §10 acceptance slice driven end to end
  (prepare → begin → advance → force quit → relaunch → resume at the correct step → closure).
- Device/appearance matrix: 5 of 5, including `accessibility-extra-extra-extra-large`.
- `scripts/inspect_release_boundary.sh … testflight`: **PASS** — testing-access marker
  present, public marker absent, build 8 not previously recorded. The inverse control
  (judging the same archive as `public`) correctly **FAILED**.

## Boundary

This is the `TestFlight` configuration. It compiles `TESTFLIGHT_BETA_ACCESS`, which grants
premium access unconditionally so internal testers reach the offline product without a live
App Store session. **It must never be promoted or repurposed as a public App Store
candidate.** A public candidate uses the standard `Release` configuration and a new build
number, and must pass the boundary inspector in its `public` mode.

## Not claimed

The upload itself was performed by Gohler through Transporter, not by this session — this
session's own upload attempts via `altool` were blocked by a keychain-lookup regression in
this Xcode 26.6 install (verified: `altool` could not read back a keychain item it had just
created itself). Apple's processing status, the build's acceptance and appearance in Connect,
internal group assignment, tester invitations, and installability on a device from TestFlight
are not verified here. Add them to this file once observed in a signed-in App Store Connect
session.
