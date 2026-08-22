import Combine
import StoreKit
import XCTest
@testable import CosmicRituals

/// Pins the three access-reliability defects fixed in Phase 1 items B1-B3.
///
/// These drive `SubscriptionStore` through its injection seams rather than through StoreKit,
/// so they are deterministic and need no session. What they cannot cover is `Transaction` and
/// `Product` themselves, which have no public initialiser — the transaction-finishing path is
/// therefore asserted at the policy level and exercised end to end only by a StoreKit session
/// suite, which the work order schedules separately.
@MainActor
final class SubscriptionRefreshTests: XCTestCase {

    // MARK: - B1: overlapping refreshes must coalesce, never drop

    /// The regression that matters: a purchase completing while a scenePhase refresh is in
    /// flight used to refresh zero times, leaving a paying user on the paywall.
    func testRefreshRequestedDuringAnInFlightPassStillObservesItsOwnPass() async {
        let entitlements = UncheckedBox<Set<String>>([])
        let passes = UncheckedBox(0)
        let firstPassStarted = expectation(description: "first pass started")
        let releaseFirstPass = expectation(description: "first pass released")

        let store = SubscriptionStore(
            accessState: .checking,
            listensForTransactions: false,
            loadActiveProductIDs: {
                let index = passes.increment()
                if index == 1 {
                    firstPassStarted.fulfill()
                    await Self.wait(for: releaseFirstPass)
                }
                return entitlements.value
            },
            loadProducts: { _ in [] },
            syncPurchases: {}
        )

        // Pass one is in flight and blocked, exactly like a refresh awaiting StoreKit.
        let first = Task { await store.refresh() }
        await fulfillment(of: [firstPassStarted], timeout: 5)

        // The purchase lands: the entitlement exists now, and a refresh is requested.
        entitlements.value = [SubscriptionCatalog.monthlyProductID]
        let second = Task { await store.refresh() }

        releaseFirstPass.fulfill()
        await first.value
        await second.value

        XCTAssertEqual(passes.value, 2, "The second request must run its own pass, not be dropped")
        XCTAssertTrue(
            store.accessState.hasPremiumAccess,
            "A purchase completing during an in-flight refresh must still unlock access; was \(store.accessState)"
        )
    }

    /// `isRefreshing` drives `.disabled(...)` on the retry and restore buttons, so it must
    /// describe the whole chain rather than flapping between queued passes.
    func testIsRefreshingIsTrueWhileAPassIsInFlightAndClearsWhenTheChainDrains() async {
        let started = expectation(description: "pass started")
        let release = expectation(description: "pass released")

        let store = SubscriptionStore(
            accessState: .checking,
            listensForTransactions: false,
            loadActiveProductIDs: {
                started.fulfill()
                await Self.wait(for: release)
                return []
            },
            loadProducts: { _ in [] },
            syncPurchases: {}
        )

        let inFlight = Task { await store.refresh() }
        await fulfillment(of: [started], timeout: 5)
        XCTAssertTrue(store.isRefreshing, "A refresh awaiting StoreKit must report as refreshing")

        release.fulfill()
        await inFlight.value
        XCTAssertFalse(store.isRefreshing, "isRefreshing must clear once the chain drains")
    }

    // MARK: - B2: a failed restore must never revoke verified access

    func testFailedRestoreDoesNotRevokeAccessTheUserAlreadyHas() async {
        let store = SubscriptionStore(
            accessState: .entitled,
            listensForTransactions: false,
            loadActiveProductIDs: { [SubscriptionCatalog.annualProductID] },
            loadProducts: { _ in [] },
            syncPurchases: { throw StoreKitError.networkError(URLError(.notConnectedToInternet)) }
        )

        await store.restorePurchases()

        XCTAssertEqual(store.accessState, .entitled, "A failed restore must leave verified access intact")
    }

    func testFailedRestoreFromLockedStillReportsAnUnavailableStore() async {
        let store = SubscriptionStore(
            accessState: .locked,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: { throw StoreKitError.networkError(URLError(.notConnectedToInternet)) }
        )

        await store.restorePurchases()

        guard case .storeUnavailable = store.accessState else {
            return XCTFail("A locked user whose restore failed must be told; was \(store.accessState)")
        }
    }

    /// Dismissing the App Store sign-in sheet is a decision, not an error, and must not be
    /// reported to the user as a failure.
    func testCancelledRestoreIsNotReportedAsFailure() async {
        let store = SubscriptionStore(
            accessState: .locked,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: { throw StoreKitError.userCancelled }
        )

        await store.restorePurchases()

        XCTAssertEqual(store.accessState, .locked, "A dismissed restore must leave the state alone")
    }

    // MARK: - B4: the reason must be the cause, not a guess

    /// The split that matters: StoreKit answering successfully with zero products is an App
    /// Store Connect configuration fault, and telling that user to check their connection
    /// sends them to fix something that is not broken.
    func testEmptyProductListIsReportedAsConfigurationNotConnectivity() async {
        let store = SubscriptionStore(
            accessState: .checking,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: {}
        )

        await store.refresh()

        XCTAssertEqual(store.accessState, .storeUnavailable(.productsMissing))
    }

    func testUnavailableReasonSeparatesOfflineFromStoreFailure() {
        XCTAssertEqual(
            SubscriptionStore.unavailableReason(for: StoreKitError.networkError(URLError(.notConnectedToInternet))),
            .offline
        )
        XCTAssertEqual(
            SubscriptionStore.unavailableReason(for: StoreKitError.networkError(URLError(.badServerResponse))),
            .storeUnreachable
        )
        XCTAssertEqual(SubscriptionStore.unavailableReason(for: StoreKitError.systemError(URLError(.unknown))), .storeUnreachable)
        XCTAssertEqual(SubscriptionStore.unavailableReason(for: URLError(.notConnectedToInternet)), .offline)
    }

    func testFailedRestoreFromLockedReportsRestoreFailedSpecifically() async {
        let store = SubscriptionStore(
            accessState: .locked,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: { throw StoreKitError.networkError(URLError(.notConnectedToInternet)) }
        )

        await store.restorePurchases()

        XCTAssertEqual(store.accessState, .storeUnavailable(.restoreFailed))
    }

    /// A restore that succeeds and finds nothing is the only signal StoreKit gives that the
    /// user is signed in to a different Apple Account than the one that purchased.
    func testSuccessfulRestoreThatFindsNothingReportsNoEntitlements() async {
        let store = SubscriptionStore(
            accessState: .locked,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: {}
        )

        await store.restorePurchases()

        XCTAssertEqual(store.accessState, .storeUnavailable(.restoreFoundNoEntitlements))
    }

    func testSuccessfulRestoreThatFindsAnEntitlementDoesNotReportNoEntitlements() async {
        let store = SubscriptionStore(
            accessState: .locked,
            listensForTransactions: false,
            loadActiveProductIDs: { [SubscriptionCatalog.annualProductID] },
            loadProducts: { _ in [] },
            syncPurchases: {}
        )

        await store.restorePurchases()

        XCTAssertEqual(store.accessState, .entitled)
    }

    // MARK: - B5: .checking must never strand, and a timeout must never revoke access

    /// The state a user cannot escape: an indefinite spinner with retry disabled.
    func testAnEntitlementLookupThatNeverAnswersEndsInARecoverableStateNotASpinner() async {
        let store = SubscriptionStore(
            accessState: .checking,
            listensForTransactions: false,
            loadActiveProductIDs: {
                try? await Task.sleep(for: .seconds(60))
                return []
            },
            loadProducts: { _ in [] },
            syncPurchases: {},
            entitlementDeadline: .milliseconds(50),
            productLoadDeadline: .milliseconds(50)
        )

        await store.refresh()

        XCTAssertEqual(store.accessState, .storeUnavailable(.storeUnreachable))
        XCTAssertFalse(store.isRefreshing, "isRefreshing must clear even when StoreKit never answers")
    }

    func testATimeoutNeverRevokesAccessTheUserAlreadyHas() async {
        let store = SubscriptionStore(
            accessState: .entitled,
            listensForTransactions: false,
            loadActiveProductIDs: {
                try? await Task.sleep(for: .seconds(60))
                return []
            },
            loadProducts: { _ in [] },
            syncPurchases: {},
            entitlementDeadline: .milliseconds(50),
            productLoadDeadline: .milliseconds(50)
        )

        await store.refresh()

        XCTAssertEqual(store.accessState, .entitled, "A lookup that did not answer proves nothing")
    }

    /// Retrying from an unavailable screen must not replace the explanation with a spinner.
    func testRefreshFromUnavailableDoesNotPassThroughChecking() async {
        let observed = UncheckedBox<[SubscriptionAccessState]>([])
        let store = SubscriptionStore(
            accessState: .storeUnavailable(.productsMissing),
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: {}
        )
        let recorder = store.$accessState.sink { observed.value.append($0) }
        defer { recorder.cancel() }

        await store.refresh()

        XCTAssertFalse(
            observed.value.contains(.checking),
            "Retrying an unavailable screen must not flash the loading overlay; saw \(observed.value)"
        )
    }

    // MARK: - B7: renewal phase refines the message, never the access

    func testRenewalStateMapsToThePhasesTheAppDistinguishes() {
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: .subscribed), .subscribed)
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: .inGracePeriod), .gracePeriod)
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: .inBillingRetryPeriod), .billingRetry)
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: .expired), .expired)
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: .revoked), .revoked)
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: nil), .unknown)
    }

    /// RenewalState is a RawRepresentable struct, not a closed enum, so a future OS can
    /// return something this app has never seen. That must be silent, not alarming.
    func testUnrecognisedRenewalStateIsSilentRatherThanAlarming() {
        let future = Product.SubscriptionInfo.RenewalState(rawValue: 9_999)
        XCTAssertEqual(SubscriptionStore.renewalPhase(for: future), .unknown)
        XCTAssertFalse(SubscriptionRenewalPhase.unknown.needsAttentionWhileEntitled)
    }

    /// Grace period is the only phase that both keeps access and asks for action.
    func testOnlyTheGracePeriodAsksTheUserToActWhileStillEntitled() {
        XCTAssertTrue(SubscriptionRenewalPhase.gracePeriod.needsAttentionWhileEntitled)
        for phase: SubscriptionRenewalPhase in [.subscribed, .billingRetry, .expired, .revoked, .unknown] {
            XCTAssertFalse(phase.needsAttentionWhileEntitled, "\(phase) must not nag a user mid-ritual")
        }
    }

    /// The invariant that matters: no renewal value can reach `hasPremiumAccess`.
    func testRenewalPhaseCannotGrantOrRemoveAccess() async {
        for state in [Product.SubscriptionInfo.RenewalState.expired, .revoked, .inBillingRetryPeriod] {
            let store = SubscriptionStore(
                accessState: .checking,
                listensForTransactions: false,
                loadActiveProductIDs: { [SubscriptionCatalog.annualProductID] },
                loadProducts: { _ in [] },
                syncPurchases: {},
                loadRenewalState: { _ in state }
            )
            await store.refresh()
            XCTAssertTrue(
                store.accessState.hasPremiumAccess,
                "A verified entitlement grants access regardless of renewal state; \(state) removed it"
            )
        }

        let noEntitlement = SubscriptionStore(
            accessState: .checking,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: {},
            loadRenewalState: { _ in .subscribed }
        )
        await noEntitlement.refresh()
        XCTAssertFalse(
            noEntitlement.accessState.hasPremiumAccess,
            "A healthy renewal state must not manufacture access without an entitlement"
        )
    }

    /// A status lookup that fails says nothing, so it must not overwrite what we knew.
    func testAFailedRenewalLookupDoesNotOverwriteAKnownPhase() async {
        let phases = UncheckedBox<[Product.SubscriptionInfo.RenewalState?]>([.inGracePeriod, nil])
        let store = SubscriptionStore(
            accessState: .checking,
            listensForTransactions: false,
            loadActiveProductIDs: { [SubscriptionCatalog.annualProductID] },
            loadProducts: { _ in [] },
            syncPurchases: {},
            loadRenewalState: { _ in
                var remaining = phases.value
                let next = remaining.isEmpty ? nil : remaining.removeFirst()
                phases.value = remaining
                return next
            }
        )

        await store.refresh()
        XCTAssertEqual(store.renewalPhase, .gracePeriod)

        await store.refresh()
        XCTAssertEqual(store.renewalPhase, .gracePeriod, "A lookup that did not answer must not clear a known phase")
    }

    // MARK: - B3: testing access is never widened by any of this

    func testTestingAccessIsNeverRevokedByAFailedRestore() async {
        let store = SubscriptionStore(
            accessState: .testingAccess,
            listensForTransactions: false,
            loadActiveProductIDs: { [] },
            loadProducts: { _ in [] },
            syncPurchases: { throw StoreKitError.networkError(URLError(.badServerResponse)) }
        )

        await store.restorePurchases()

        XCTAssertEqual(store.accessState, .testingAccess)
        XCTAssertTrue(store.accessState.isTestingAccess)
    }

    // MARK: - Helpers

    private static func wait(for expectation: XCTestExpectation) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                _ = XCTWaiter().wait(for: [expectation], timeout: 10)
                continuation.resume()
            }
        }
    }
}

/// Minimal mutable box for values shared with `@Sendable` seams inside a single test.
/// Access is confined to one test's execution, which is why the unchecked conformance is safe.
private final class UncheckedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) { stored = value }

    var value: Value {
        get { lock.lock(); defer { lock.unlock() }; return stored }
        set { lock.lock(); stored = newValue; lock.unlock() }
    }
}

extension UncheckedBox where Value == Int {
    func increment() -> Int {
        lock_increment()
    }

    private func lock_increment() -> Int {
        let next = value + 1
        value = next
        return next
    }
}
