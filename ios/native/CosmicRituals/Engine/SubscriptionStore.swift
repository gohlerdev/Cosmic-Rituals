import Foundation
import StoreKit

enum SubscriptionCatalog {
    static let monthlyProductID = "com.cosmic.rituals.premium.monthly"
    static let annualProductID = "com.cosmic.rituals.premium.annual"
    static let productIDs = [annualProductID, monthlyProductID]

    static let privacyPolicyURL = URL(string: "https://gohlerdev.github.io/Cosmic-Rituals/privacy/")!
    static let termsOfUseURL = URL(string: "https://gohlerdev.github.io/Cosmic-Rituals/terms/")!
    static let supportURL = URL(string: "https://gohlerdev.github.io/Cosmic-Rituals/support/")!
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    static let requestedTrialDays = 14
}

enum SubscriptionAccessState: Equatable {
    case checking
    case entitled
    case testingAccess
    case locked
    case storeUnavailable(String)

    var hasPremiumAccess: Bool {
        self == .entitled || self == .testingAccess
    }

    var isTestingAccess: Bool {
        self == .testingAccess
    }
}

enum SubscriptionLaunchPolicy {
    static func initialState(
        isUITestingPremium: Bool,
        isTestingDistribution: Bool
    ) -> SubscriptionAccessState {
        if isUITestingPremium {
            return .entitled
        }
        if isTestingDistribution {
            return .testingAccess
        }
        return .checking
    }
}

enum SubscriptionEntitlementChecker {
    static func grantsAccess(activeProductIDs: Set<String>) -> Bool {
        !activeProductIDs.isDisjoint(with: SubscriptionCatalog.productIDs)
    }

    static func currentActiveProductIDs() async -> Set<String> {
        var activeProductIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard SubscriptionCatalog.productIDs.contains(transaction.productID) else { continue }
            activeProductIDs.insert(transaction.productID)
        }
        return activeProductIDs
    }

    static func grantsCurrentAccess() async -> Bool {
        grantsAccess(activeProductIDs: await currentActiveProductIDs())
    }
}

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var accessState: SubscriptionAccessState
    @Published private(set) var products: [Product] = []
    @Published private(set) var isEligibleForRequestedTrial = false
    @Published private(set) var isRefreshing = false

    private var transactionUpdatesTask: Task<Void, Never>?

    /// Serialises refresh passes. See `refresh()`.
    private var refreshTask: Task<Void, Never>?
    private var pendingRefreshCount = 0

    /// Injection seams. Defaults are the live StoreKit calls, so production behaviour is
    /// unchanged; tests supply deterministic stand-ins because `Product.products` and
    /// `AppStore.sync` cannot be driven from a unit test without a StoreKit session.
    private let loadActiveProductIDs: @Sendable () async -> Set<String>
    private let loadProducts: @Sendable ([String]) async throws -> [Product]
    private let syncPurchases: @Sendable () async throws -> Void

    init(
        accessState: SubscriptionAccessState = .checking,
        listensForTransactions: Bool = true,
        loadActiveProductIDs: @escaping @Sendable () async -> Set<String> = {
            await SubscriptionEntitlementChecker.currentActiveProductIDs()
        },
        loadProducts: @escaping @Sendable ([String]) async throws -> [Product] = {
            try await Product.products(for: $0)
        },
        syncPurchases: @escaping @Sendable () async throws -> Void = {
            try await AppStore.sync()
        }
    ) {
        self.loadActiveProductIDs = loadActiveProductIDs
        self.loadProducts = loadProducts
        self.syncPurchases = syncPurchases
        self.accessState = accessState
        if listensForTransactions {
            transactionUpdatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { return }
                    await self?.handle(transactionResult: result)
                }
            }
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    /// Every caller observes a pass that *began after its own request*.
    ///
    /// The previous implementation returned immediately when a refresh was already running.
    /// That silently dropped the post-purchase refresh: `handle(transactionResult:)` finishes
    /// the transaction and then refreshes, and returning from the App Store sheet is exactly
    /// when the `scenePhase` refresh fires — so a paying user could be left on the paywall
    /// until the next cold launch. Chaining instead of dropping makes "refreshes exactly
    /// once per change" true rather than "at most once".
    ///
    /// Passes are chained, never cancelled: `performRefresh()` writes `.checking` before it
    /// awaits, so a cancelled pass would strand the loading overlay.
    func refresh() async {
        pendingRefreshCount += 1
        isRefreshing = true
        defer {
            pendingRefreshCount -= 1
            if pendingRefreshCount == 0 { isRefreshing = false }
        }

        let previous = refreshTask
        let pass = Task { @MainActor [weak self] in
            await previous?.value
            await self?.performRefresh()
        }
        refreshTask = pass
        await pass.value
    }

    private func performRefresh() async {
        if !accessState.hasPremiumAccess {
            accessState = .checking
        }

        let activeProductIDs = await loadActiveProductIDs()
        let hasAccess = SubscriptionEntitlementChecker.grantsAccess(activeProductIDs: activeProductIDs)
        if hasAccess {
            accessState = .entitled
        }

        do {
            let loadedProducts = try await loadProducts(SubscriptionCatalog.productIDs)
            products = loadedProducts.sorted(by: productSort)
            isEligibleForRequestedTrial = await hasEligibleRequestedTrial(in: products)

            if !hasAccess {
                accessState = products.isEmpty
                    ? .storeUnavailable("Subscriptions are temporarily unavailable. Check your connection and try again.")
                    : .locked
            }
        } catch is CancellationError {
            return
        } catch {
            if !hasAccess {
                accessState = .storeUnavailable("The App Store could not load subscription options. Check your connection and try again.")
            }
        }
    }

    func restorePurchases() async {
        do {
            try await syncPurchases()
            await refresh()
        } catch is CancellationError {
            return
        } catch StoreKitError.userCancelled {
            // Dismissing the sign-in sheet is not a failure and must not be reported as one.
            return
        } catch {
            // A restore that fails must never take away access the user already has: the
            // entitlement was verified locally and does not depend on this sync succeeding.
            guard !accessState.hasPremiumAccess else { return }
            accessState = .storeUnavailable("Purchases could not be restored. Confirm the App Store account and try again.")
        }
    }

    /// Finishes every transaction, then grants only for a verified one in the catalog.
    ///
    /// Both `VerificationResult` cases carry a `Transaction`, and an unfinished transaction is
    /// redelivered by the App Store on every launch forever. Returning early on the unverified
    /// or foreign-product paths — as this did — leaves those transactions unfinished for good.
    /// Finishing is not the same as trusting: access still comes only from the verified path.
    private func handle(transactionResult: VerificationResult<Transaction>) async {
        let transaction: Transaction
        let isVerified: Bool
        switch transactionResult {
        case .verified(let value):
            transaction = value
            isVerified = true
        case .unverified(let value, _):
            transaction = value
            isVerified = false
        }

        await transaction.finish()

        guard isVerified, SubscriptionCatalog.productIDs.contains(transaction.productID) else { return }
        await refresh()
    }

    private func hasEligibleRequestedTrial(in products: [Product]) async -> Bool {
        for product in products {
            guard let subscription = product.subscription,
                  let offer = subscription.introductoryOffer,
                  offer.paymentMode == .freeTrial,
                  offer.period.unit == .week,
                  offer.period.value == 2 else { continue }
            if await subscription.isEligibleForIntroOffer {
                return true
            }
        }
        return false
    }

    private func productSort(_ lhs: Product, _ rhs: Product) -> Bool {
        guard let lhsPeriod = lhs.subscription?.subscriptionPeriod,
              let rhsPeriod = rhs.subscription?.subscriptionPeriod else {
            return lhs.id < rhs.id
        }
        return subscriptionPeriodDays(lhsPeriod) > subscriptionPeriodDays(rhsPeriod)
    }

    private func subscriptionPeriodDays(_ period: Product.SubscriptionPeriod) -> Int {
        let multiplier: Int
        switch period.unit {
        case .day: multiplier = 1
        case .week: multiplier = 7
        case .month: multiplier = 30
        case .year: multiplier = 365
        @unknown default: multiplier = 0
        }
        return period.value * multiplier
    }
}
