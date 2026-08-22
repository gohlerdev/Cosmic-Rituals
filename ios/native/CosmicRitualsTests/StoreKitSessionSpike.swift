import StoreKit
import StoreKitTest
import XCTest
@testable import CosmicRituals

/// Establishes whether a `SKTestSession` can drive this app's commerce path from a unit test,
/// before any suite is written on top of that assumption.
///
/// Two things make it uncertain here, and both are checked rather than assumed:
///
/// 1. `StoreKit/CosmicRituals.storekit` has no `PBXFileReference` and sits outside every
///    synchronized root group, so it is not copied into any bundle and
///    `SKTestSession(configurationFileNamed:)` cannot find it. The file is located from
///    `#filePath` instead, which is the same approach the existing StoreKit configuration test
///    already uses.
/// 2. `CosmicRitualsTests` is app-hosted, so `RootView.init` runs before any test does and
///    starts a live `Transaction.updates` listener that can race the session.
///
/// OUTCOME, measured 2026-08-22: the session is NOT usable in this configuration.
///
/// `SKTestSession(contentsOf:)` constructs without throwing, and the fixture is reachable
/// from `#filePath`, but `Product.products(for:)` then returns an empty array. Stopping the
/// app host from touching StoreKit at launch (`isUnitTestHost` in `RootView.init`, added for
/// this) does not change that, so the app-host race was not the cause.
///
/// The remaining explanation is the one the work order predicted: `CosmicRituals.storekit`
/// has no `PBXFileReference` and belongs to no target, so nothing tells the *app process*
/// that this configuration is its store. A session created in the test process does not
/// retroactively become the host's store.
///
/// What would unblock it, in increasing order of commitment:
///   1. add the fixture to the project and set it as the scheme's StoreKit configuration;
///   2. failing that, run the commerce scenarios against a sandbox account, which is a
///      distribution action and needs authorization at the time.
///
/// Until one of those happens, the ten Phase 1 commerce scenarios are NOT reachable from
/// XCTest. The seam-driven tests in `SubscriptionRefreshTests` cover the store's own logic;
/// what stays uncovered is `Product`, `Transaction`, and the purchase flow itself.
final class StoreKitSessionSpike: XCTestCase {

    /// The canonical fixture. Deliberately not duplicated into the test bundle: two copies of
    /// a product catalogue drift, and the one that drifts is always the one nobody reads.
    static func configurationURL() -> URL {
        URL(fileURLWithPath: #filePath)          // .../CosmicRitualsTests/StoreKitSessionSpike.swift
            .deletingLastPathComponent()         // .../CosmicRitualsTests
            .deletingLastPathComponent()         // .../ios/native
            .appendingPathComponent("StoreKit/CosmicRituals.storekit")
    }

    func testTheStoreKitFixtureIsReachableFromTheTestBundle() throws {
        let url = Self.configurationURL()
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: url.path),
            "The .storekit fixture must be locatable from #filePath; it is not in any bundle"
        )
    }

    /// The two session-backed tests are skipped rather than deleted, so the blocker stays
    /// visible in the suite instead of living only in a commit message. Remove the skip the
    /// moment the fixture is added to the project — the assertions below are already right.
    func testASessionBackedProductLookupReturnsBothConfiguredProducts() async throws {
        try XCTSkipUnless(
            Self.sessionServesProducts(),
            "SKTestSession serves no products while CosmicRituals.storekit belongs to no target"
        )

        let session = try SKTestSession(contentsOf: Self.configurationURL())
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }

        let products = try await Product.products(for: SubscriptionCatalog.productIDs)
        XCTAssertEqual(Set(products.map(\.id)), Set(SubscriptionCatalog.productIDs))
    }

    /// Probes once, cheaply, whether a session can serve this app's products. Returning false
    /// is a statement about the project layout, not about the code under test.
    private static func sessionServesProducts() -> Bool {
        guard let session = try? SKTestSession(contentsOf: configurationURL()) else { return false }
        session.disableDialogs = true
        let probe = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var served = false
        Task {
            served = ((try? await Product.products(for: SubscriptionCatalog.productIDs))?.isEmpty == false)
            probe.signal()
        }
        _ = probe.wait(timeout: .now() + 20)
        return served
    }
}
