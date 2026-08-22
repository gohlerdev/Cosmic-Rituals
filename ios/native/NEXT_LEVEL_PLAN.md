# Cosmic Rituals — next-level product, accuracy, and release plan

Document date: 2026-08-21
Planning horizon: internal beta through reference-grade product
Canonical app: native SwiftUI target in `ios/native/CosmicRituals`
Distribution boundary: testing only until Gohler explicitly authorizes a later release step

## 1. Purpose

Cosmic Rituals must become the most dependable ceremony-and-practice app in its
space. It should not be a generic astrology app with a Pooja tab, nor a visual
variation of Cosmic Astrology, Cosmic Numerology, or CosmicVastu. Its primary
object is a ritual being understood, prepared, performed, interrupted safely,
resumed, and completed with its timing, sources, safety limits, and tradition
boundaries intact.

The product should answer five questions clearly:

1. What household practice can I consider today?
2. Which date, place, time zone, and sunrise reference produced the timing?
3. What do I need, what is optional, and what can I substitute safely?
4. How do I proceed step by step without inventing lineage-specific practice?
5. Which details must I confirm with my family, temple, sampradaya, Jyotishi, or priest?

Accuracy and truthful scope disclosure outrank feature count and visual drama.

## 2. Authority and release boundary

This plan separates product work from distribution work.

- Local implementation, tests, Simulator QA, and documentation may proceed only
  when explicitly authorized.
- TestFlight upload, App Store Connect mutation, external tester distribution,
  review submission, pricing changes, subscription activation, and public release
  are separate actions requiring explicit authorization at the time they occur.
- Builds 7 and 8 are internal-testing-only builds. Their `TESTFLIGHT_BETA_ACCESS`
  compilation condition intentionally bypasses purchases for internal testing.
  Neither may ever be promoted or repurposed as a public App Store candidate.
- A public candidate must use a new build number and the standard `Release`
  configuration without the testing-access condition.
- The planned 14-day trial must be configured and verified through StoreKit and
  App Store Connect. Device time must never determine trial eligibility.

## 3. Status vocabulary

Every phase and handoff must use these terms precisely:

- **Planned:** described here but not implemented.
- **Implemented:** present in source, but not necessarily built or exercised.
- **Built:** compiled for a named target and configuration.
- **Tested:** passed a named automated or manual test on a dated environment.
- **User-confirmed:** Gohler observed the relevant behavior.
- **Uploaded:** Apple accepted the binary upload; processing may still be pending.
- **Testing:** a processed build is assigned to an intended TestFlight group.
- **Release candidate:** all engineering, product, accessibility, accuracy, and
  commerce gates pass for the standard Release configuration.
- **Release-approved:** Gohler explicitly authorized submission or publication.
- **Live:** Apple distribution is actually available to the intended audience.

A green build is not automatically a good product, an accurate calculation, a
usable ritual flow, a TestFlight installation, or a release approval.

## 4. Confirmed baseline

The branch before this plan was `codex/cosmic-rituals-modernization`, tracking its
origin at commit `caeb325`. The current TestFlight baseline is version 1.0 build 8,
internal testing only. Its uploaded application source snapshot is commit `039158a`;
later commits record release evidence without changing that uploaded app binary.

On 2026-08-22, signed-in App Store Connect verification showed build 8 upload
processing `Complete`, a 90-day testing window, and assignment to
`Cosmic Rituals Internal` with two testers. The external group was not attached,
and no App Review or public-release action was taken. Installation, first launch
from TestFlight, and soak remain unverified and are the next distribution gates.

### 4.1 Shipping product surface

The existing native app already contains:

- Vara, Tithi, Nakshatra, Yoga, and Karana with separately solved transitions.
- Sunrise/sunset and sunrise-anchored day context.
- Moon sign, Nakshatra Pada, lord, and Gana.
- Brahma Muhurta, Abhijit Muhurta, Rahu Kala, Yamaganda, Gulika Kala, and Dur Muhurta.
- Choghadiya, Hora, and thirty day/night muhurtas.
- Monthly Panchang calendar.
- A 33,909-city offline GeoNames catalog and guarded current-location handling.
- On-device text/PDF sharing and App Intents.
- Three information modes, six themes, Dynamic Type support, contrast checks,
  Reduce Motion handling, and VoiceOver labels.
- Twelve offline, structured Pooja Vidhis with materials, preparation, steps,
  short public mantras, meanings, safety notes, tradition limits, and sources.
- A dedicated TestFlight build configuration separated from standard Release.
- A StoreKit model for monthly and annual subscriptions with a requested
  two-week introductory trial in the local StoreKit configuration.

### 4.2 Explicitly non-shipping or incomplete

- Notifications are visibly off and not production-ready.
- Widget source is a prototype; there is no shipping WidgetKit extension contract.
- Live Activities, Dynamic Island behavior, and Apple Watch are pending.
- Moonrise/moonset, festivals/vratas, extended lunisolar calendar data, and nine
  Graha positions are quarantined prototypes, not trusted product capabilities.
- Varjyam and Amrit Kalam are pending.
- Regional festival precedence, Amanta/Purnimanta choice, Adhika/Kshaya month
  handling, and event-specific vyapti rules are not release-ready.
- Content is typed and validated in Swift, but it is not yet managed through a
  complete versioned editorial/reviewer pipeline.
- Before the current work, ritual material and guided-step progress was ephemeral.

### 4.3 First implemented slice retained with this plan

The current change set establishes the first recoverable Ritual Journey seam:

- local-only, versioned preparation and guided-practice session state;
- immediate persistence after material and step changes;
- sanitization against the active catalog after content changes;
- relaunch recovery, completion, and intentional restart behavior;
- a direct “Continue your ritual” entry point for unfinished practice;
- a factual ritual-day context card containing civil date, calculation location,
  IANA time zone, Tithi, Nakshatra, and sunrise availability;
- explicit language that calculated facts do not make a Pooja universally
  required on that day;
- automated coverage for persistence, invalid stored data, unknown materials,
  completion/restart, and polar sunrise disclosure.

This slice is a foundation, not a claim that the full plan is complete.

## 5. Product principles that govern every phase

### 5.1 Ceremonial identity

- Use temple light, sandalwood, kumkum, ghee-lamp ivory, brass, flowers, water,
  textiles, and restrained household-altar photography.
- Keep imagery subordinate to text with reliable contrast veils.
- Do not use deity images as decorative wallpaper.
- Do not use generic starfields, orbit motifs, blueprint grids, or number-ledger
  metaphors that belong to the other Cosmic apps.
- Use sequential, calm, native surfaces. Do not gamify sacred practice.

### 5.2 Accuracy and honesty

- Every timing result must retain date, coordinate, location label, IANA time
  zone, sunrise reference, ayanamsha/convention, rule-pack version, and fallback.
- Unsupported calculations stay hidden or clearly marked as research.
- Regional differences must be explicit choices, not silently guessed defaults.
- No static Gregorian festival lookup may masquerade as a rule-complete Hindu calendar.
- No invented mantra, transliteration, ritual instruction, remedy, guarantee, or
  festival date may enter the product.

### 5.3 Safety and practitioner boundaries

- Flame, smoke, water, food, allergy, medication, pregnancy, disability,
  property, and local-law constraints override ceremonial preference.
- Initiatory bija mantras, nyasa, formal homa, installation, formal visarjana,
  and received lineage practices remain outside generic household guidance.
- Priest-recommended guides stop visibly at the officiant boundary.
- Family or temple practice takes precedence over a general reference.

### 5.4 Privacy and reliability

- Ritual selection, progress, and preferences remain on device unless a future
  sync design receives explicit privacy and product approval.
- No unnecessary analytics, advertising SDK, third-party account, or cloud
  dependency is introduced.
- Every important flow must survive interruption, backgrounding, force quit,
  app update, temporary StoreKit failure, and loss of network.

## 6. Multiphase execution plan

## Phase 0 — current-truth rebaseline and field evidence

Estimated duration: 5–7 working days
Dependency: none
Release effect: none

### Objectives

Establish the current repository, App Store Connect, device, accessibility, and
user-experience truth before expanding the app.

### Work

- Reverify branch, remote, clean/dirty status, version/build settings, schemes,
  signing identities, subscription product identifiers, and TestFlight groups.
- Reverify build 8 processing, group assignment, invite count, installability,
  and launch behavior in signed-in App Store Connect.
- Install on at least one current iPhone-class Simulator, one small iPhone
  layout, and one iPad layout; use a physical device when available.
- Exercise fresh install, upgrade from build 7 to build 8, app relaunch, force quit,
  airplane mode, denied location, stale GPS, time-zone change, date-line change,
  dark/light appearance, Reduce Motion, and accessibility Dynamic Type.
- Capture dated screenshots of Panchang, Timing, Muhurtas, Pooja library,
  preparation, guided practice, interruption/resume, completion, Calendar, and paywall.
- Record cold-launch time, first-interaction time, memory footprint, calculation
  latency, monthly-calendar latency, PDF creation time, and offline-city search latency.
- Ask internal testers only outcome-focused questions: could they open it, find a
  Pooja, understand the source/safety boundary, begin, resume, and complete it?

### Exit gate

- A current evidence report distinguishes observed, tested, and unverified states.
- The app opens on the target device without an unexplained App Store connection failure.
- Every launch blocker is reproduced and classified as code, StoreKit metadata,
  App Store configuration, signing, account, network, or device state.
- No later phase relies solely on July 2026 TestFlight evidence.

## Phase 1 — access reliability and testing/public separation

Estimated duration: 2–3 weeks
Dependency: Phase 0

### Objectives

Make launch and subscription behavior deterministic while making it impossible
to mistake an internal bypass build for a public candidate.

### Work

- Define a complete entitlement state machine: checking, entitled, testing
  access, eligible-to-purchase, purchasing, pending approval, restoring, grace
  period, billing retry, expired, refunded/revoked, offline cached receipt,
  store unavailable, and unrecoverable configuration error.
- Preserve verified access during temporary product-metadata outages without
  granting access from an unverified transaction.
- Ensure every StoreKit transaction path verifies the transaction, finishes it,
  and refreshes access exactly once.
- Add explicit, human-readable recovery actions for offline StoreKit, missing
  products, restore failure, pending purchases, and account mismatch.
- Add automated release-boundary tests that prove:
  - the standard scheme archives `Release`;
  - the TestFlight scheme archives `TestFlight`;
  - `TESTFLIGHT_BETA_ACCESS` appears only in the internal configuration;
  - standard Release never starts with testing access;
  - public archive validation fails if the bypass symbol is present.
- Add a build-time/archive inspection script that reads the built binary’s
  configuration evidence before any distribution handoff.
- Document the App Store Connect subscription-group, introductory-offer, tax,
  agreements, localization, and review-note dependencies without mutating them.

### Test matrix

- New user eligible for the 14-day trial.
- New user not eligible for an introductory offer.
- Active monthly and active annual subscriber.
- Upgrade/downgrade transition.
- Ask-to-Buy or otherwise pending purchase.
- Billing retry and grace period.
- Expired, refunded, or revoked subscription.
- Restore on a second test device.
- No network at first launch and after a previously verified entitlement.
- StoreKit products unavailable while transaction entitlements remain readable.

### Exit gate

- Twenty-five consecutive cold launches succeed in the intended internal build.
- Every state has one primary action, accessible text, and a deterministic test.
- The standard Release archive contains no testing-access path.
- No upload occurs during this phase without a new explicit instruction.

## Phase 2 — versioned ritual content and session architecture

Estimated duration: 3–5 weeks
Dependency: Phase 1 for commerce boundary; can prototype after Phase 0

### Objectives

Turn the twelve guides into a durable, reviewable content system and make the
entire ritual journey recoverable.

### Data contracts

Create explicit, Codable, versioned models for:

- `RitualGuide`
- `RitualVariant`
- `RitualMaterial`
- `MaterialAlternative`
- `RitualStep`
- `SafetyConstraint`
- `MantraReference`
- `Citation`
- `TraditionBoundary`
- `EditorialReviewRecord`
- `RitualSession`
- `CalculationReceipt`
- `RegionalRulePack`

Every guide must carry stable IDs, content version, locale, review date, reviewer
role, source set, change summary, practice level, region/tradition scope, and
minimum compatible schema version.

### Work

- Move content from monolithic hard-coded construction into validated versioned
  resources while retaining offline availability and compile-time/test validation.
- Build a deterministic content loader with schema validation, duplicate-ID
  detection, referential-integrity checks, safe fallback, and migration tests.
- Migrate all twelve guides with semantic-diff evidence proving no step, safety
  note, source, mantra meaning, or practitioner boundary was lost.
- Extend the retained session foundation to support selected ritual, materials,
  current step, completed steps, deliberate skip state, private local note,
  completion state, guide version, and migration receipt.
- Decide whether private notes require encrypted file storage rather than
  UserDefaults before adding them. Do not put sensitive free text in plaintext
  preferences by convenience.
- Define retention and reset behavior visibly; never silently erase progress
  because a guide received a new version.

### Exit gate

- All twelve guides load offline from the versioned resource layer.
- Invalid, incomplete, or future-schema content fails closed with a safe message.
- Force quit, device restart, app update, content-version update, and corrupted
  local state recover predictably.
- Migration tests demonstrate no content loss.

## Phase 3 — complete Ritual Journey

Estimated duration: 4–6 weeks
Dependency: Phase 2

### Objectives

Make the app’s primary flow: choose → verify context → prepare → begin → perform
→ interrupt → resume → close respectfully.

### Information architecture

- **Ritual Today:** factual day/location receipt, daily household practices,
  unfinished-practice recovery, and one clear next action.
- **Explore:** reviewed guide library with purpose, occasion, duration, practice
  level, safety, sources, and regional scope.
- **Prepare:** materials grouped as required, optional, safe alternatives, and
  practitioner-supplied; readiness remains factual, never a fake confidence score.
- **Practice:** one step at a time with previous/next, mantra meaning,
  transliteration choice, safety note, pause, and practitioner boundary.
- **Closure:** completion items, prasada/cleanup safety, quiet reflection, and
  an option to review—not streaks, points, or competitive metrics.

### Work

- Add minimal onboarding for location policy, calculation convention, household
  scope, source transparency, and notification state.
- Connect Panchang facts to Pooja discovery only where a reviewed rule supports
  the connection. Until then, show context without inferred festival claims.
- Make every session action immediately durable and idempotent.
- Add explicit pause, resume, start-over, and discard confirmations appropriate
  to the amount of progress at risk.
- Keep screen awake during active guided practice only with visible user benefit
  and restore normal behavior afterward.
- Support accessibility alternatives for gestures and motion.
- Add a concise session-recovery card to the app’s primary entry surface.

### Exit gate

On a device with no network, a tester can select a reviewed guide, prepare
materials, begin, advance several steps, force quit, relaunch, resume at the
correct step, complete the closure, and inspect the guide’s sources and boundaries.

## Phase 4 — distinctive ceremonial redesign

Estimated duration: 3–5 weeks
Dependency: stable Phase 3 information architecture

### Objectives

Make Cosmic Rituals unmistakably ceremonial, modern, calm, accessible, and
different from the other three Cosmic products.

### Visual system

- Create a small, licensed/provenance-recorded set of contextual backgrounds:
  dawn preparation, diya and brass, flowers and water, textile/altar detail,
  evening closure, and neutral low-stimulation practice.
- Select imagery by screen purpose and appearance rather than using one image everywhere.
- Define warm semantic pigments for preparation, timing, caution, practitioner
  boundary, source/provenance, active practice, and completion.
- Use opaque or material-backed content surfaces with measured contrast against
  every crop. Photography must never compete with instructions.
- Establish a ritual typography hierarchy with highly readable body text,
  Devanagari metrics, transliteration, numbers, and time strings.
- Give Panchang, Timing, Muhurtas, Pooja, and Calendar different screen grammar
  while preserving coherent navigation and shared accessibility behavior.

### Required QA

- Small iPhone, current iPhone, and iPad split/full screen.
- Light and dark appearance across all supported themes.
- Portrait and supported landscape orientations.
- Every Dynamic Type size including accessibility sizes.
- VoiceOver order, headings, labels, values, hints, and custom actions.
- Voice Control and Switch Control reachability.
- Increase Contrast, Differentiate Without Color, Reduce Motion, Reduce
  Transparency, and grayscale checks.
- Long Hindi/English text, Devanagari, transliteration, and 12/24-hour time.

### Exit gate

- Blind screenshot review identifies the product as Rituals rather than
  Astrology, Numerology, or Vastu.
- Every primary action is visible without decoding decorative UI.
- Text/background contrast passes measured requirements for every theme and image crop.
- No deity imagery is used as decoration and no generic starfield remains as the primary metaphor.

## Phase 5 — reviewed ritual-content expansion

Estimated duration: 6–10 weeks, parallel after Phase 2
Dependency: versioned content/editorial pipeline

### Objectives

Grow depth deliberately from twelve guides to approximately twenty-four reviewed
guides, rather than shipping a large unreviewed catalog.

### Editorial pipeline

Each guide passes:

1. Product proposal and scope classification.
2. Primary/secondary source collection.
3. Household adaptation draft.
4. Safety review.
5. Tradition/region/sampradaya boundary review.
6. Sanskrit/Devanagari/transliteration review where relevant.
7. Language review.
8. Schema and content-policy validation.
9. Guided-practice device review.
10. Named approval record and version publication.

### Candidate groups

- Daily and weekly household practice.
- Common deity-focused Panchopachara guides.
- Festival preparation guides only after the calendar engine supports their date rules.
- Life-event preparation maps that stop at the priest boundary.
- Safe closure, cleanup, prasada, and accessible-adaptation references.

### Prohibited content

- Invented or restricted mantras.
- Fear-based remedies or guaranteed outcomes.
- Medical, legal, financial, fertility, relationship, or astrological guarantees.
- Unreviewed fire rites, nyasa, installation, visarjana, or priestly substitutions.
- Static dates presented as rule-derived festivals.

### Exit gate

- Every guide has complete provenance, review metadata, safety classification,
  tradition scope, and device-reviewed guided flow.
- No guide ships solely because a public chatbot or competitor displayed it.

## Phase 6 — Hindi, transliteration, and verified pronunciation

Estimated duration: 4–7 weeks
Dependency: Phase 2 models; may overlap Phase 5

### Work

- Localize operational UI into Hindi while keeping English complete.
- Store Sanskrit/Devanagari, transliteration, meaning, and instruction as
  separate reviewed fields; do not transliterate UI strings mechanically.
- Offer a clear transliteration preference with a documented standard.
- Add human-reviewed audio only when pronunciation, licensing, speaker consent,
  and source provenance are recorded.
- Provide normal and slow playback, offline assets, interruption handling,
  route-change handling, and VoiceOver controls.
- Ensure audio is optional and never presented as initiation or universal lineage authority.

### Exit gate

- No untranslated operational string in the Hindi flow.
- Devanagari and transliteration render without clipping at accessibility sizes.
- Every audio asset has review and provenance metadata and works offline.

## Phase 7 — reference-grade calculation program

Estimated duration: 8–14 weeks, parallel with product work
Dependency: independent reference methodology

### Objectives

Quantify the accuracy envelope instead of relying on a few agreeable examples.

### Work

- Build a fixture corpus across decades, hemispheres, continents, high
  latitudes, DST transitions, date-line edges, skipped/extended Tithis,
  Nakshatra boundaries, and ayanamsha-sensitive instants.
- Compare Sun/Moon longitude, sunrise/sunset, five limbs, transitions, kala
  windows, Choghadiya, Hora, and muhurtas against documented independent references.
- Define tolerances before running the comparison and preserve every outlier.
- Evaluate whether the current Meeus-based engine remains sufficient or whether
  a legally compatible high-precision ephemeris is required.
- Record ephemeris version, ayanamsha, observer assumptions, refraction,
  elevation policy, solver tolerance, and fallback in calculation receipts.
- Add metamorphic/invariant tests: chronological transitions, civil-day
  preservation, no fabricated polar schedules, location signature isolation,
  and consistency between UI, export, App Intent, notification, and widget consumers.

### Exit gate

- A published internal comparison report lists fixture sources, tolerances,
  pass rates, and every unresolved outlier.
- No high-severity unexplained timing discrepancy remains.
- Unsupported results remain quarantined rather than rounded into apparent correctness.

## Phase 8 — regional observance and festival engine

Estimated duration: 10–18 weeks
Dependency: Phase 7 accuracy foundation

### Work

- Model real lunations and explicit Amanta/Purnimanta choices.
- Detect Adhika and Kshaya months.
- Encode sunrise, Madhyahna, Pradosha, Nishita, moonrise, and event-specific
  vyapti/precedence rules as versioned, cited rule packs.
- Make region/tradition an explicit user choice with a neutral unconfigured state.
- Begin with a small bounded event set whose rules can be fully tested.
- Produce a decision trace for every observance date explaining the inputs and
  precedence rule that selected it.
- Compare multiple years and cities against at least two documented references,
  resolving methodology differences rather than averaging results.

### Exit gate

- No festival result comes from a static Gregorian table.
- Regional differences are visible and explainable.
- Every supported event passes multi-year, multi-city fixtures and reviewer sign-off.

## Phase 9 — notifications, widgets, Live Activities, and Watch

Estimated duration: 5–9 weeks
Dependency: stable calculation receipt and session contract

### Notifications

- Request permission only after the user selects a meaningful reminder.
- Store calculation context and rule version with each request.
- Reschedule on location, time-zone, date, calendar, and relevant settings changes.
- Handle denied, provisional, scheduled-summary, and revoked permissions honestly.
- Never notify from stale or fallback timing without labeling the limitation.

### WidgetKit

- Add a real widget extension and App Group.
- Share a compact, versioned, read-only snapshot rather than duplicate calculations.
- Show generation time, location label, time zone, and stale state.
- Provide privacy-safe placeholder/redacted states.

### Live Activity and Watch

- Use Live Activity only for a user-selected active ritual or a verified imminent
  transition; do not create continuous ceremonial noise.
- Add Watch only after the iPhone Ritual Journey is stable.
- Keep the phone calculation/session contract authoritative and test handoff,
  interruption, stale state, and independent app launch.

### Exit gate

- UI, notifications, widgets, Live Activity, and Watch consume one versioned
  calculation/session contract.
- Location/time-zone changes cannot leave silently stale times.
- Permission denial never blocks the core offline app.

## Phase 10 — internal candidate, external beta, and production readiness

Estimated duration: 2–4 weeks after prior gates
Dependency: required product gates complete

### Internal candidate

- Increment build number from the source-of-truth project settings.
- Build the dedicated internal TestFlight configuration.
- Run archive validation, symbol checks, privacy manifest checks, dSYM checks,
  export validation, and device smoke tests.
- Upload only with explicit authorization.
- Verify processing, group assignment, invite, installation, first launch,
  relaunch, offline launch, purchase bypass label, and 24–72 hour soak separately.

### Public candidate

- Use the standard Release scheme and a new unique build number.
- Prove the testing-access symbol is absent from the archive.
- Verify live sandbox StoreKit products, localized price, 14-day eligibility,
  purchase, restore, expiry, refund/revoke, grace period, and offline entitlement.
- Complete privacy labels, support/privacy/terms URLs, age rating, export
  compliance, screenshots, description, review notes, and subscription metadata.
- Run an authorized external beta before review submission.
- Submit or make live only after Gohler’s explicit release approval.

### Release gates

1. **Engineering:** clean build, full tests, no critical crash/hang/data-loss issue.
2. **Accuracy:** fixtures and tolerances pass with no hidden severe outlier.
3. **Content:** review/provenance complete; prohibited content absent.
4. **Product:** offline Ritual Journey succeeds end to end.
5. **Accessibility:** no critical blocker in supported assistive configurations.
6. **Commerce:** every entitlement/trial state tested with real StoreKit configuration.
7. **Distribution:** archive identity, signing, processing, install, and soak verified.
8. **Authority:** explicit approval exists for the exact external action.

## 7. Dependency order and release trains

### Release Train A — strong internal beta

Target horizon: 8–12 weeks after execution resumes.

- Phase 0 rebaseline.
- Phase 1 access/release separation.
- Phase 2 content/session foundation.
- Phase 3 complete Ritual Journey.
- Phase 4 ceremonial redesign.

Result: a visibly distinct, reliable, interruption-safe internal beta. It is not
automatically a public candidate.

### Release Train B — 14-day-trial production candidate

Target horizon: 14–22 weeks after execution resumes.

- Release Train A gates.
- First reviewed content expansion.
- Hindi/transliteration foundation and only approved audio.
- Real subscription lifecycle validation.
- Authorized external beta and soak.

Result: a standard Release candidate, still requiring explicit submission approval.

### Release Train C — category-leading reference product

Target horizon: 24–40 weeks after execution resumes.

- Reference-grade calculation report.
- Rule-complete bounded regional observance engine.
- Stable notifications and real WidgetKit extension.
- Selective Live Activity and later Watch experience.
- Broader reviewed content and language depth.

## 8. Quality scorecard

The program should track outcomes rather than feature count.

### Reliability

- 100% of interrupted ritual sessions recover to the correct guide and step.
- Zero material/step loss across force quit and app update in the migration suite.
- Zero StoreKit metadata failure that makes an already verified user unable to launch.
- Zero testing-bypass binary accepted as a public candidate.

### Accuracy

- 100% of displayed timing includes the correct calculation context.
- Zero hidden high-severity discrepancy in the supported fixture corpus.
- Zero prototype calendar/astronomy capability exposed as trusted production data.

### Product clarity

- At least 90% of internal testers identify the primary Pooja action without instruction.
- At least 90% can find safety, sources, and practitioner limits before starting.
- At least 90% complete the offline interruption/resume scenario without assistance.

### Accessibility

- Zero critical VoiceOver, Dynamic Type, contrast, or reduced-motion blocker.
- Every primary action has an accessible name, value where needed, and recovery path.

### Content governance

- 100% of shipping guides have version, sources, review date, reviewer role,
  safety classification, and tradition/region boundary.
- Zero invented mantra, guarantee, or uncited festival rule.

## 9. Required verification commands

At minimum, native source changes must pass:

```bash
cd /Users/psy/Documents/Cosmic-Rituals/ios/native

xcodebuild \
  -project CosmicRituals.xcodeproj \
  -scheme CosmicRituals \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

xcodebuild \
  -project CosmicRituals.xcodeproj \
  -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,id=<available-simulator-uuid>' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Consequential candidates additionally require standard Release and dedicated
internal TestFlight archive inspection, real-device evidence, and the phase-specific gates.

## 10. Immediate next acceptance milestone

The following vertical slice now passes as a six-test Simulator UI suite, including
force-quit recovery and respectful completion:

> A user chooses one of the twelve reviewed rituals, sees the exact civil
> date/location/time-zone/sunrise context without a fabricated recommendation,
> prepares required materials, begins the guide offline, advances several steps,
> force quits, reopens the app, resumes at the correct step, completes respectful
> closure, and can inspect the guide’s safety, source, and tradition boundaries.

The immediate distribution acceptance gate is to install build 8 from TestFlight on
an intended tester device and visibly repeat that journey, including first launch,
offline relaunch, the testing-access label, and correct resume state. Record the device,
OS, result, and any tester-facing failure before expanding content, redesigning every
surface, or adding platform extensions.
