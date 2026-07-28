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

    init(accessState: SubscriptionAccessState = .checking, listensForTransactions: Bool = true) {
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

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        if !accessState.hasPremiumAccess {
            accessState = .checking
        }

        let activeProductIDs = await SubscriptionEntitlementChecker.currentActiveProductIDs()
        let hasAccess = SubscriptionEntitlementChecker.grantsAccess(activeProductIDs: activeProductIDs)
        if hasAccess {
            accessState = .entitled
        }

        do {
            let loadedProducts = try await Product.products(for: SubscriptionCatalog.productIDs)
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
            try await AppStore.sync()
            await refresh()
        } catch is CancellationError {
            return
        } catch {
            accessState = .storeUnavailable("Purchases could not be restored. Confirm the App Store account and try again.")
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else { return }
        guard SubscriptionCatalog.productIDs.contains(transaction.productID) else { return }
        await transaction.finish()
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
