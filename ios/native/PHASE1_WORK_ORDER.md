# WORK ORDER — Phase 1: entitlement state machine and release boundary
Single engineer. All anchors are **working-tree** line numbers (`project.pbxproj` is uncommitted and offset ~45 lines from HEAD; re-anchor by content, not number).

## Status (five lines)
1. Access is granted only from `.verified` transactions in `Transaction.currentEntitlements` for the two configured product IDs — `SubscriptionStore.swift:53-61`, `:49-51`, `:104-106` — and no unverified receipt path exists anywhere.
2. Verified access is correctly preserved when product metadata fails to load (`SubscriptionStore.swift:113`, `:121` both guard on `!hasAccess`), and `SubscriptionLaunchPolicy` (`:33-46`) keeps testing access a distinct, unit-tested state (`CosmicEngineTests.swift:687-713`).
3. Transactions arriving on `Transaction.updates` are verified, filtered to the catalog, and finished (`SubscriptionStore.swift:80-86`, `:138-143`); App Intents gate on the same verified check (`CosmicAppIntents.swift:37`, `:68`, `:93`).
4. The single most important thing wrong: **`refresh()` drops overlapping calls instead of coalescing them** (`SubscriptionStore.swift:94`) — the post-purchase `await refresh()` at `:142` runs *after* `transaction.finish()`, so a purchase completing while the `scenePhase` refresh (`RootView.swift:78-81`) is in flight refreshes **zero** times and leaves a paid user on the paywall until the next cold launch.
5. Second-order but structural: the state machine has 5 of the 14 required cases (`SubscriptionStore.swift:17-31`), and Release and TestFlight binaries are byte-indistinguishable except `CFBundleVersion`, so "archive validation fails if the bypass symbol is present" has no symbol to detect.

---

## A. DECISIONS NEEDED FROM THE OWNER (business only — engineering is blocked on these where noted)

**A1. Does an unpurchased, offline first-run user reach any content?**
Today `RootView.swift:56` gates the entire product; Phase 0 reproduced the dead end (`PHASE0_EVIDENCE_2026-08-21.md:83-86`).
Options: (i) designate a permanently free surface (today's Panchang, or one household Pooja); (ii) bounded local pre-purchase grace window; (iii) keep the hard gate and only make the copy honest.
Consequences: (i) moves the gate from `RootView` down into each surface and changes App Review positioning; (ii) reintroduces device-local time as an access input, which `NEXT_LEVEL_PLAN.md:41-42` currently prohibits and which would need that line explicitly amended; (iii) costs nothing beyond B4/B5. *Blocks final copy of B4; does not block B4's mechanics.*

**A2. What build number does the next public candidate carry, and do TestFlight and Release share one counter?**
Release is `CURRENT_PROJECT_VERSION = 6` (`project.pbxproj:447`), TestFlight is `7` (`:478`); both 1.0 (6) and 1.0 (7) are recorded as accepted uploads (`RELEASE_1.0_6.md`, `RELEASE_1.0_7.md`), so a standard Release archive today is not a viable candidate.
Options: single shared counter starting at 8; permanently diverged counters; move marketing version off 1.0.
Consequence: **blocks B14** (the xcconfig unification forces one value). No archive or upload is implied by answering.

**A3. Should the billing grace period be enabled for the real products?**
Engineering can represent `.gracePeriod` either way (B7). Turning it on is an App Store Connect mutation requiring separate authorization at the time.
Options: on (subscribers keep access through a payment failure; `.gracePeriod` becomes reachable for real users) / off (`.gracePeriod` stays a modelled-but-unreachable state; users go straight to billing retry with no access).

**A4. Is Ask-to-Buy / pending purchase a supported flow?**
Options: supported (B8 ships the pending state, its persistence, and its "Check again" action) / not supported (B8 drops to the `Result.failure` handling only, and the plan's "pending approval" state is recorded as knowingly deferred). Consequence: ~5 of B8's 8 hours.

**A5. What does a grace-period or billing-retry subscriber see — a warning, or nothing?**
And relatedly, how much of the subscription detail panel (B9) is shown: plan name, renewal date, trial-remaining, billing warning, or none.
Options: silent (no nag, access simply ends) / factual banner / banner plus a Manage Subscriptions link. Consequence: B9 scope; no engineering difference in the data layer.

**A6. Do the internal TestFlight testers need working App Shortcuts?**
The three intents gate on verified entitlement only (`CosmicAppIntents.swift:37`, `:68`, `:93`), so in the internal build every shortcut answers "Open Cosmic Rituals to start or restore Premium".
Options: keep verified-only and record the App Intents surface as untestable in the internal build / extend `#if TESTFLIGHT_BETA_ACCESS` to the intents, widening the bypass surface.

**A7. Do Privacy / Terms / Support stay on the store-unavailable screen?**
They are the only policy links a locked user can reach there (`SubscriptionViews.swift:154-169`); the normal path uses `.subscriptionStorePolicyDestination` (`:32-33`). Guideline 3.1.2 requires functional links for auto-renewable subscriptions. Options: keep all three / keep with a "needs a connection" caption / remove.

**A8. Copy for every new state.** Each state added in B4–B8 needs one primary action label and one body string. Engineering will ship placeholder strings marked `// COPY PENDING` and will not invent reassurance.

*Not a decision to make here: trial length and the 49.99 / 6.99 basis (`SUBSCRIPTION_RELEASE.md:12-13`) are untouched by this order.*

---

## B. ENGINEERING (ordered; each item is independently shippable and testable)

**B1 — Coalesce `refresh()`; add the injection seam. BLOCKER. 6h**
`SubscriptionStore.swift:93-125`. Split the body `:98-124` verbatim into `private func performRefresh()`. Replace the entry point with a serialized owned chain: `private var refreshTask: Task<Void, Never>?`; `refresh()` builds `Task { @MainActor in await previous?.value; await self.performRefresh() }`, stores it, and awaits it, so every caller observes a pass that *began after its own request*. Do **not** implement with `defer` (`:96` is non-async) and do **not** cancel-and-restart (`:118-119` returns bare after `.checking` was already written at `:99`, stranding the overlay). Drive `isRefreshing` (`:73`) from chain depth so `.disabled(store.isRefreshing)` at `SubscriptionViews.swift:135`/`:142` spans the whole chain.
Same commit: add closure seams on `init` (`:77`) with defaults preserving today's behaviour — `loadActiveProductIDs` → `SubscriptionEntitlementChecker.currentActiveProductIDs`, `loadProducts` → `Product.products(for:)`, `syncPurchases` → `AppStore.sync()`. Keep the existing two labels defaulted so `RootView.swift:35-40` and the previews at `SubscriptionViews.swift:186`, `:194` compile untouched.

**B2 — `restorePurchases()` must not revoke live access, and cancellation is not failure. 3h**
`SubscriptionStore.swift:127-136`. Add pure `static func restoreOutcome(for: Error) -> SubscriptionRestoreOutcome` (`.refresh` / `.dismissed` / `.failed(String)`): `CancellationError` and `StoreKitError.userCancelled` → `.dismissed` (return, touch nothing); everything else → `.failed`, and assign `.storeUnavailable` only behind `guard !accessState.hasPremiumAccess`. Route `syncPurchases` through the B1 seam and participate in the B1 chain so the sync window is covered by `isRefreshing`.

**B3 — Finish every transaction; give untrusted transactions a state. 4h**
`SubscriptionStore.swift:138-143`. Today `:139` and `:140` return without finishing, so the App Store redelivers forever. Destructure both `VerificationResult` cases (both carry a `Transaction`, so `finish()` compiles on either). Add pure `TransactionDispositionPolicy.disposition(isVerified:productID:) -> .grantAndFinish | .finishWithoutAccess | .finishAndReportUntrusted`; every branch finishes, only `.grantAndFinish` refreshes. Add a `Set<UInt64>` of handled `transaction.id` for idempotency (B8 needs it). The untrusted report may set state **only** when `!accessState.hasPremiumAccess`; its `hasPremiumAccess` and `isTestingAccess` must both be false so `RootView.swift:56-57` is unchanged. No retry machinery — verification is deterministic and local, and the app sells only auto-renewables (`StoreKit/CosmicRituals.storekit:13-18` are both empty).

**B4 — Typed unavailable reason; split configuration error from connectivity. 6h**
`SubscriptionStore.swift:22`: replace `storeUnavailable(String)` with an `Equatable` reason payload (`offline`, `storeUnreachable`, `productsMissing`, `restoreFailed`, `restoreFoundNoEntitlements`). The enum must stay `Equatable` — `SubscriptionViews.swift:18` compares with `==`. Map the `catch` at `:120` off the typed `StoreKitError`; map the *successful-but-empty* branch at `:113-117` to `productsMissing`, which is an App Store Connect configuration fault and must stop telling the user to check their connection. `restorePurchases`' failure (`:134`) → `restoreFailed`; a `sync()` that succeeds and yields zero entitlements → `restoreFoundNoEntitlements` (this is the real account-mismatch signal — `StoreKitError` has no such case, and the wrong-account path never reaches the `catch`). Drive icon/headline/body/actions from the reason in `unavailableView` (`SubscriptionViews.swift:104-181`), replacing the hardcoded `wifi.exclamationmark` (`:110`) and "The App Store is unavailable" (`:115`). Add `lastAttempt: (Date, reason)` rendered under the retry button. Must-update in the same commit: the exhaustive default-less switch at `SubscriptionViews.swift:11-16`, the preview at `:195`, and `CosmicEngineTests.swift:712`.

**B5 — Deadline `.checking`; stop stranding it; give it an action. 5h**
`SubscriptionStore.swift:98-100`, `:102`, `:109`, `:118-119`. Give the two awaits **independent** deadlines (race against `Task.sleep`) so the `defer` at `:96` always runs and `isRefreshing` always clears; a product-load timeout must never downgrade an entitlement result that arrives. Capture the pre-`refresh` state before the write at `:99` and restore it in the `CancellationError` branch at `:118-119` instead of returning bare. Narrow `:98-100` so it does not clobber an existing unavailable state — only enter `.checking` from `.checking`/`.locked`, and render retry progress inline from `isRefreshing` so the `ScrollView` at `SubscriptionViews.swift:105` keeps identity and scroll position. Add a delayed "Try again" (`.disabled(store.isRefreshing)`) to `loadingOverlay` (`SubscriptionViews.swift:89-102`). Deadline durations are placeholders pending A8.

**B6 — StoreKit test harness (host idle mode + fixture loader) + bounded spike. 6h**
`CosmicRitualsTests` is app-hosted (`project.pbxproj:516`, `:532`, `:548`), so the host's `RootView.init` runs first and starts a live `Transaction.updates` listener (`RootView.swift:38` → `SubscriptionStore.swift:79-86`) that will race any `SKTestSession`. Add a **DEBUG-only, access-neutral** idle gate in `RootView.swift:16-20`'s block: `isStoreKitTestHostIdle = arguments.contains("-storeKitTestHostIdle") || environment["XCTestConfigurationFilePath"] != nil`; feed it into `bypassStoreRefresh` (`:34`) and `listensForTransactions:` (`:38`). Keep `initialState` `.checking` — this grants nothing. Express the decision as a **new** pure function on `SubscriptionLaunchPolicy` (do not change `initialState(isUITestingPremium:isTestingDistribution:)`; `CosmicEngineTests.swift:688`, `:695`, `:702` call that exact signature). If the launch argument is also wanted, set `shouldUseLaunchSchemeArgsEnv = "NO"` on the TestAction (`CosmicRituals.xcscheme:43`) and add the argument there — nothing is currently inherited.
Fixture loading: `StoreKit/CosmicRituals.storekit` has **no** `PBXFileReference` and sits outside all three synchronized root groups (`project.pbxproj:32-36`), so `SKTestSession(configurationFileNamed:)` cannot work — use `SKTestSession(contentsOf:)` via the `#filePath` walk already proven at `CosmicEngineTests.swift:716-719`; refactor that into one shared helper. Spike first: confirm a session-backed `Product.products` returns 2 under the mandated `xcodebuild test` invocation before writing C-block suite; record the outcome either way.

**B7 — Renewal status: grace period, billing retry, expired, revoked. 10h**
`SubscriptionStore.swift:102-107`. Read `Product.SubscriptionInfo.Status` and switch on `RenewalState`: `.subscribed`→entitled, `.inGracePeriod`→grace (**grants access** — already true today via current entitlements, so this is a label, not a new unlock), `.inBillingRetryPeriod`, `.expired`, `.revoked`. Unwrap `Status.transaction` and `Status.renewalInfo` through `.verified` only. Derive the subscription group id at runtime from the verified transaction (or `product.subscription?.subscriptionGroupID`) — **never** hardcode the fixture id `C05B5A14` (`StoreKit/CosmicRituals.storekit:70`), which per `SUBSCRIPTION_RELEASE.md:70-72` never reaches App Store Connect. Entitlement stays the sole access authority: renewal state may refine the message, never widen access; a failed status lookup must leave access intact. Rename `.locked`→`.eligibleToPurchase` and fold `isEligibleForRequestedTrial` (`:72`, `:111`, `:145-157`) into the resolver's input rather than duplicating it. Express the whole mapping as one pure `resolve(entitlements:renewalState:productLoadOutcome:) -> SubscriptionAccessState`.

**B8 — Purchase phase and pending approval. 8h (scope depends on A4)**
`SubscriptionViews.swift:25-36`. Attach `.onInAppPurchaseStart` and `.onInAppPurchaseCompletion` (closure receives `(Product, Result<Product.PurchaseResult, any Error>)` — handle the `.failure` branch explicitly). Route `.success` into `handle(transactionResult:)` so B3's id-keyed idempotency makes whichever of the two channels lands first the only one that refreshes. Model phase as a **separate** `@Published purchasePhase` (`.idle/.purchasing/.awaitingApproval`), *not* an `accessState` case: `SubscriptionViews.swift:11-16` decides whether `SubscriptionStoreView` is mounted at all, and a new case outside the `:14` list tears down the in-flight purchase sheet. Also note `refresh()`'s `:98-100` write would erase a pending flag stored in `accessState` on the next foreground (`RootView.swift:78-80`). Ask-to-Buy leaves no transaction until approved, so persistence needs a small versioned `UserDefaults` record (mirror `RitualSessionStore`), cleared when the transaction arrives in `handle`. Primary action is "Check again" → `refresh()`; Restore is secondary and cannot recover an unapproved purchase.

**B9 — Subscriber detail panel. 4h (scope from A5, depends on B7)**
`PanchangView.swift:964-989`, the existing "Subscription & Support" section. Render facts read from StoreKit only — plan, renewal or expiry date in the user's locale, trial state, billing warning when applicable. Consider `.manageSubscriptionsSheet` in place of the external link at `:970` → `SubscriptionStore.swift:12`.

**B10 — `ReleaseChannel` marker; fence the bypass evidence. 4h**
New `CosmicRituals/App/ReleaseChannel.swift` (synchronized group picks it up; no pbxproj edit). Inside `#if TESTFLIGHT_BETA_ACCESS`: `isTestingDistribution = true` plus `testingAccessMarker = "COSMIC_RITUALS_TESTING_ACCESS_BUILD"`; `#else` only `isTestingDistribution = false` (plus a distinct public marker string). Replace the inline fence at `RootView.swift:24-28`. Wrap `RootView.swift:57-61` **and** `:84-98` in `#if TESTFLIGHT_BETA_ACCESS` — fencing only the property leaves the reference at `:60` undefined in Release — and consume the marker in the banner's accessibility label so it lands in `__TEXT,__cstring` and survives stripping. Leave `SubscriptionAccessState.testingAccess` (`:20`), `hasPremiumAccess` (`:24-26`), `isTestingAccess` (`:28-30`) and `SubscriptionLaunchPolicy` (`:33-46`) unconditional — `CosmicEngineTests.swift:707-711` asserts on them and both TestActions build Debug. Acceptance evidence: `strings -a` count of "TestFlight testing access" goes 4→0 in the Release binary and stays non-zero in TestFlight. Do not use `nm` (Release is stripped) and never make the human-facing banner copy load-bearing.

**B11 — "Release boundary guard" build phase. 2h**
Add one `PBXShellScriptBuildPhase` to the app target's `buildPhases` (`project.pbxproj:89-93`), before Sources, `alwaysOutOfDate = 1`, empty input/output paths. Scan **both** `SWIFT_ACTIVE_COMPILATION_CONDITIONS` and `OTHER_SWIFT_FLAGS` for `TESTFLIGHT_BETA_ACCESS`; fail if present when `CONFIGURATION != TestFlight`, fail if absent when `CONFIGURATION == TestFlight`, fail if `ENABLE_TESTABILITY == YES` in Release. Document honestly in the phase-1 evidence that it does not survive an operator who also overrides `CONFIGURATION` on the command line — that is what B12 is for. (Hand-editing `project.pbxproj` here is fine; `CLAUDE.md`'s prohibition is on adding *sources* that way.)

**B12 — `scripts/inspect_release_boundary.sh`. 4h**
No `scripts/` directory exists yet. Takes a `.app` or `.xcarchive`. Must: locate `Products/Applications/CosmicRituals.app/CosmicRituals` and hard-fail if absent (never pass on a missing binary); iterate every slice (`lipo -info` / `lipo -thin`); fail if the beta marker is present **or** the public marker absent for Release; fail on the inverse for TestFlight (the positive control that proves the check can see anything); cross-read the embedded `Info.plist` to know which configuration it is judging; fail when `CFBundleVersion` equals any build already recorded in a `RELEASE_<short>_<build>.md` file; **report** `CFBundleVersion`/`CFBundleShortVersionString` rather than enforcing a chosen value. Header comment must state that "bypass symbol" means the marker string, not an `nm` symbol.

**B13 — Release-boundary UI-test scheme. 4h**
The unit-test target cannot be built in Release or TestFlight — `ENABLE_TESTABILITY = YES` exists only in the project Debug config (`project.pbxproj:283`) and `@testable import` at `CosmicEngineTests.swift:6` fails the compile; `-skip-testing` does not help. Add shared `CosmicRitualsReleaseBoundary.xcscheme` whose Testables list is `CosmicRitualsUITests` only, and `CosmicRitualsUITests/ReleaseBoundaryUITests.swift` asserting on observable UI (banner accessibility label from `RootView.swift:97` vs. `subscription.gate`, `SubscriptionViews.swift:22`). Pair configuration with method at invocation time; a mismatched pairing must fail loudly. Do not override `ENABLE_TESTABILITY` on the command line.

**B14 — Single-source the build number. 2h. BLOCKED ON A2.**
Create `Config/Version.xcconfig` **outside** `CosmicRituals/` (that directory is a synchronized root group, `project.pbxproj:33`), reference it as `baseConfigurationReference` from all three app configurations, and delete `CURRENT_PROJECT_VERSION` from `project.pbxproj:416`, `:447`, `:478`. Moving the key to the project level does **not** single-source it — project-level settings are also three per-configuration objects. Also correct `PHASE0_EVIDENCE_2026-08-21.md:26`, which reports `CURRENT_PROJECT_VERSION = 7` as repository truth when only the TestFlight configuration carries it.

**B subtotal: 68h.**

---

## C. TESTS TO WRITE

Pure / no StoreKit — add to `CosmicRitualsTests/CosmicEngineTests.swift` beside `:668-737` (12h total for this group, included in the B items above except where noted):
- `testConcurrentRefreshRequestsCoalesceIntoExactlyOneFollowUpPass` — pins B1: N overlapping requests during one in-flight pass produce exactly one extra pass, zero requests produce zero; and a request made mid-pass ends `.entitled`, not `.locked`.
- `testRestoreRacingScenePhaseRefreshObservesAPassStartedAfterSync` — pins B1's chain guarantee for `restorePurchases()`.
- `testRestoreOutcomeClassifiesCancellationDismissalAndFailure` — pins B2: `CancellationError` and `StoreKitError.userCancelled` → `.dismissed`; `.networkError`/`.systemError` → `.failed`.
- `testFailedRestoreNeverRevokesVerifiedOrTestingAccess` — pins B2's guard using `SubscriptionStore(accessState: .entitled, listensForTransactions: false)` plus an injected throwing `syncPurchases`.
- `testTransactionDispositionFinishesUnverifiedAndForeignProducts` — pins B3's three branches; plus `hasPremiumAccess == false` / `isTestingAccess == false` for the untrusted state. Note in evidence that `handle(...)` itself remains uncovered by unit tests.
- `testUnavailableReasonMapsEmptyProductsToConfigurationNotConnectivity` — pins B4's `:113-117` split.
- `testRefreshFromUnavailableDoesNotPassThroughChecking` — pins B4/B5's `:98-100` narrowing.
- `testTimeoutNeverDowngradesVerifiedAccessAndAlwaysClearsIsRefreshing` and `testCancelledRefreshRestoresPriorState` — pin B5.
- `testHostListensForTransactionsIsFalseInIdleModeWithoutGrantingAccess` — pins B6's access-neutrality.
- `testAccessStateResolverCoversEveryModelledState` — pins B7's pure resolver across the full renewal-state × entitlement × product-load matrix.
- `testPurchaseResultTransitionsMapPendingCancelledAndFailure` — pins B8 (`.pending`/`.userCancelled` are constructible without a session).

Release-boundary text assertions (new file, `#filePath`-rooted, `XCTSkipUnless` the repo root exists but hard-fail on any missing file under it) — **4h, not covered by a B item**:
- `testStandardSchemeArchivesReleaseAndTestFlightSchemeArchivesTestFlight` — pins `CosmicRituals.xcscheme:113-114` = `Release` and `CosmicRitualsTestFlight.xcscheme:110-111` = `TestFlight`, and exactly one `<ArchiveAction` per scheme. Use a string scan or `XMLParser`, **not** `XMLDocument` (macOS-only, will not link into the simulator test bundle).
- `testTestingAccessConditionAppearsOnlyInTheTestFlightConfiguration` — pins that `TESTFLIGHT_BETA_ACCESS` occurs exactly once in `project.pbxproj` (currently `:497`) and that its enclosing `XCBuildConfiguration` block is `name = TestFlight;` (`:502`). Assert on content, never on line number.
- `testEveryTargetDeclaresAllThreeConfigurationsAndDefaultsToRelease` — iterate all `XCConfigurationList` blocks (`:608`, `:618`, `:628`, `:638`); assert name set `{Debug, Release, TestFlight}` and `defaultConfigurationName = Release`, plus at least three lists so an empty parse cannot pass vacuously.
- `testTestingAccessIsUnreachableOutsideTheCompilationFence` — source lint: the only `isTestingDistribution = true` is inside `#if TESTFLIGHT_BETA_ACCESS` with a false `#else`; `SubscriptionLaunchPolicy.initialState` has exactly one app call site; `.testingAccess` is returned/assigned only in `SubscriptionStore.swift` and otherwise only pattern-matched.
- `testAllConfigurationsResolveToOneBuildNumber` — pins B14 once A2 is answered.

SKTestSession suite, `CosmicRitualsTests/SubscriptionCommerceTests.swift` — **8h, gated on B6's spike passing**; fail loudly in `setUp` if the session is not live rather than `XCTSkip`:
- `testVerifiedEntitlementSurvivesProductMetadataOutage` (assert previously loaded products are retained and no regression to locked/unavailable), `testFirstLaunchOfflineWithNoEntitlementShowsRecoverableUnavailable` (pattern-match the reason, do not compare strings), `testExpiredSubscriptionLandsExactlyInEligibleToPurchase`, `testTrialEligibilityFlipsAfterTheGroupOfferIsConsumed`, `testTransactionIsVerifiedFinishedAndAccessRefreshedExactlyOnce` (assert `Transaction.unfinished` empty afterwards), `testApprovedAskToBuyTransactionGrantsAccess` (requires `_askToBuyEnabled`, `_billingGracePeriodEnabled`, `_renewalBillingIssuesEnabled` — currently all `false` at `StoreKit/CosmicRituals.storekit:20-26`; flipping the **local fixture** is engineering and changes nothing in App Store Connect). Run non-parallel; the TestableReference is `parallelizable = "YES"` (`CosmicRituals.xcscheme:47`).

**C additional (not in B): 12h. TOTAL: 80h ≈ 10 working days**, excluding time spent waiting on A1–A8.

---

## D. EXPLICITLY OUT OF SCOPE
- Any distribution action: archiving for submission, TestFlight upload, App Store Connect mutation (including toggling the real billing grace period per A3, creating sandbox testers, or configuring the introductory offer), external tester distribution, review submission, pricing changes, subscription activation, public release. Building Release/TestFlight products locally and running B12 against them is a check, not a handoff.
- Promoting, renumbering, or repurposing build 7 in any way. It stays internal-testing-only.
- Changing prices, trial length, or product IDs in `StoreKit/CosmicRituals.storekit` or anywhere else.
- Choosing the next public build number (A2), the offline gating model (A1), or any user-facing copy beyond `// COPY PENDING` placeholders.
- Physical-device StoreKit runs, and therefore any duplicated `.storekit` fixture inside a test bundle — keep one canonical file until a device run is actually required.
- `CosmicWidgets/`, catalog breadth, redesign, the quarantined festival/moonrise/graha prototypes, and the §10 ritual-journey slice.
- Reintroducing device-local time as an access input (would require amending `NEXT_LEVEL_PLAN.md:41-42` first, via A1).

---

## E. VERIFICATION COMMANDS
```bash
cd /Users/psy/Documents/Cosmic-Rituals/ios/native

# 1. Mandated pair (NEXT_LEVEL_PLAN.md §9) — run after every source change
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derived-data CODE_SIGNING_ALLOWED=NO build-for-testing

xcrun simctl list devices available | grep -m1 'iPhone 17'
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -derivedDataPath .derived-data CODE_SIGNING_ALLOWED=NO test

# 2. Single new test while iterating
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -derivedDataPath .derived-data CODE_SIGNING_ALLOWED=NO \
  -only-testing:CosmicRitualsTests/CosmicEngineTests/testConcurrentRefreshRequestsCoalesceIntoExactlyOneFollowUpPass test

# 3. B11 guard — the second and third must FAIL
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals -configuration Release \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals -configuration Release \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=TESTFLIGHT_BETA_ACCESS build
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals -configuration Release \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO \
  OTHER_SWIFT_FLAGS=-DTESTFLIGHT_BETA_ACCESS build

# 4. B10 marker evidence — Release 0 / TestFlight non-zero
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRitualsTestFlight -configuration TestFlight \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath .derived-data CODE_SIGNING_ALLOWED=NO build
strings -a .derived-data/Build/Products/Release-iphonesimulator/CosmicRituals.app/CosmicRituals \
  | grep -c 'COSMIC_RITUALS_TESTING_ACCESS_BUILD'   # expect 0
strings -a .derived-data/Build/Products/TestFlight-iphonesimulator/CosmicRituals.app/CosmicRituals \
  | grep -c 'COSMIC_RITUALS_TESTING_ACCESS_BUILD'   # expect > 0

# 5. B12 script, both sides
./scripts/inspect_release_boundary.sh .derived-data/Build/Products/Release-iphonesimulator/CosmicRituals.app     # expect PASS
./scripts/inspect_release_boundary.sh .derived-data/Build/Products/TestFlight-iphonesimulator/CosmicRituals.app  # expect PASS (positive control)

# 6. B13 release-boundary UI tests — configuration and method must be paired
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRitualsReleaseBoundary -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' CODE_SIGNING_ALLOWED=NO \
  -only-testing:CosmicRitualsUITests/ReleaseBoundaryUITests/testStandardReleaseBuildNeverStartsWithTestingAccess test
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRitualsReleaseBoundary -configuration TestFlight \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' CODE_SIGNING_ALLOWED=NO \
  -only-testing:CosmicRitualsUITests/ReleaseBoundaryUITests/testInternalTestFlightBuildStartsWithTestingAccess test
```