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
