# Cosmic Rituals — product status and roadmap

> Product standard: a definitive, private native Panchang experience whose
> calculation claims never outrun its evidence.

Status words in this document are strict:

- **Shipping** means reachable in the app target and covered by a current build.
- **Validated** means it also has an automated invariant or independent fixture.
- **Prototype** means source exists but is not a user-facing capability.
- **Pending** means it is not implemented.

## Current shipping surface

| Capability | Status | Evidence / limit |
|---|---|---|
| Vara, Tithi, Nakshatra, Yoga, Karana | Shipping + validated | Anchored to selected-location sunrise |
| All four limb transition times | Shipping + validated | Independent Paris fixture; chronological boundary invariants |
| Moon sign, Nakshatra Pada, lord, and Gana | Shipping | Evaluated at the same sunrise reference |
| Sunrise and sunset | Shipping + validated | Four public civil-time fixtures; explicit polar no-result |
| Brahma Muhurta | Shipping | 96–48 minutes before real sunrise |
| Abhijit Muhurta | Shipping + validated | Daylight-scaled; omitted on Wednesday |
| Rahu Kala, Yamaganda, Gulika Kala | Shipping + validated | Published Mumbai fixture; local daylight divisions |
| Dur Muhurta | Shipping + validated | Correct weekday table, including Tuesday night period |
| Choghadiya | Shipping | Eight local day + eight local night periods |
| Hora | Shipping | Twelve local day + twelve local night planetary hours |
| 30 Ahoratra Muhurtas | Shipping | Fifteen day + fifteen night windows |
| Muhurta details and activity filter | Shipping | Traditional symbolic guidance, not prediction |
| Monthly sunrise-snapshot calendar | Shipping | Cache keyed by location and time zone |
| Offline location catalog | Shipping + validated | 33,909 GeoNames cities; CC BY 4.0 attribution |
| Current-location mode | Shipping + validated | Freshness, authorization, coordinate, and accuracy gates |
| Text and PDF sharing | Shipping | Uses the active calculation time zone and sunrise reference |
| App Intents / Shortcuts | Shipping | Requires a persisted explicit location |
| Three information layouts + six themes | Shipping + validated | Dynamic Type, contrast, Reduce Motion, VoiceOver labels |
| Calculation-integrity disclosure | Shipping | Method, privacy, tolerance, and ceremonial-use caveat |

The detailed method and fixture record is in [ACCURACY.md](ACCURACY.md).

## Platform truth

| Capability | Status | What remains |
|---|---|---|
| Automatic notifications | Pending / visibly off | Location/date-safe scheduling, permission UX, tests |
| Home Screen widgets | Prototype source only | Widget extension target, App Group, signing, shared context, E2E tests |
| Live Activity / Dynamic Island | Pending | ActivityKit target and lifecycle design |
| Apple Watch | Pending | Watch target, shared calculation contract, device QA |

The app and documentation must not describe prototype source as a shipping
capability.

## Calculation work intentionally quarantined

The following source is preserved for research but is not routed into shipping
navigation because it does not yet meet the evidence bar:

| Area | Status | Required before surfacing |
|---|---|---|
| Moonrise and moonset | Prototype | Topocentric altitude solver, parallax, multiple global fixtures |
| Festival and vrata calendar | Prototype | True lunisolar month, Adhika/Kshaya handling, regional precedence rules, fixtures |
| Extended Samvat / Masa / Anandadi panel | Prototype | Rule-complete calendar derivation and regional settings |
| Nine Graha positions | Prototype | Reference-grade ephemeris and error envelope |
| Varjyam / Amrit Kalam | Pending | Nakshatra-based intervals and published fixtures |

## Next product phases

### 1. Reference-grade astronomy

- Evaluate a legally compatible high-precision ephemeris strategy.
- Add global Moonrise/Moonset and Graha fixtures before enabling their views.
- Expand five-limb fixtures across ayanamsha-boundary and skipped/extended-tithi cases.
- Add observer elevation and refraction settings only if their effect can be
  explained without creating false confidence.

### 2. Rule-complete observance calendar

- Model Amanta and Purnimanta lunar months from actual lunations.
- Detect Adhika and Kshaya months.
- Encode event-specific sunrise, midnight, Pradosha, and tithi-precedence rules.
- Make regional school an explicit user choice.
- Ship festival data only after multi-year, multi-city fixture validation.

### 3. Native ecosystem

- Add the WidgetKit target and shared context contract.
- Add notifications only with rescheduling on location, time-zone, and date changes.
- Design Live Activity and Watch surfaces around the next verified transition,
  not around duplicated calculation code.

### 4. International depth

- Localize interface, Panchang terminology, numeral style, and 12/24-hour time.
- Add transliteration preferences without changing calculation identity.
- Validate right-to-left layout and the largest Dynamic Type sizes.

## Release gates

Every release must pass:

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

It must also receive simulator QA for the three experience modes, dark and light
appearance, location changes, a next-day transition, polar no-schedule behavior,
Reduce Motion, and an accessibility Dynamic Type size.

Last truthfulness review: 2026-07-27.
