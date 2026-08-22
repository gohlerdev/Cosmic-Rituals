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

/// Why subscription options could not be shown.
///
/// The previous `storeUnavailable(String)` carried a prebuilt sentence, which meant an App
/// Store Connect configuration fault and a dropped Wi-Fi connection told the user the same
/// thing: check your connection. They are not the same problem and only one of them is the
/// user's to fix. Carrying the reason instead of the sentence lets the view say something
/// true, and lets a test assert on the cause rather than on copy.
enum SubscriptionUnavailableReason: Equatable, Sendable {
    /// The device could not reach the network at all.
    case offline
    /// The network is up but StoreKit failed.
    case storeUnreachable
    /// StoreKit answered successfully with no products. Nothing the user can do: the
    /// products are missing or not yet approved in App Store Connect.
    case productsMissing
    /// `AppStore.sync()` threw.
    case restoreFailed
    /// `AppStore.sync()` succeeded and found nothing. The usual cause is being signed in to
    /// a different App Store account than the one that purchased - which StoreKit has no
    /// error case for, so this is the only signal that it happened.
    case restoreFoundNoEntitlements
}

/// Thrown when a StoreKit await exceeds its deadline. Distinct from a StoreKit failure so
/// the reason mapper does not have to guess at a cause that never arrived.
struct SubscriptionDeadlineExceeded: Error, Equatable {}

enum SubscriptionAccessState: Equatable {
    case checking
    case entitled
    case testingAccess
    case locked
    case storeUnavailable(SubscriptionUnavailableReason)

    var hasPremiumAccess: Bool {
        self == .entitled || self == .testingAccess
    }

    var isTestingAccess: Bool {
        self == .testingAccess
    }
}

/// Where a subscription is in its renewal life, as distinct from whether it grants access.
///
/// Kept deliberately separate from `SubscriptionAccessState`. Access comes from verified
/// current entitlements and nothing else; renewal state refines what the user is *told* and
/// must never widen what they can reach. Making it a separate property rather than a payload
/// on `.entitled` means that invariant holds by construction — there is no path from a
/// renewal value to `hasPremiumAccess`.
enum SubscriptionRenewalPhase: Equatable, Sendable {
    /// Renewing normally.
    case subscribed
    /// A payment failed and Apple is retrying while access continues. The user can still fix
    /// it, and telling them is the difference between a renewal and a silent lapse.
    case gracePeriod
    /// A payment failed, the grace period is over, and access has ended.
    case billingRetry
    /// Ran to its end without renewing.
    case expired
    /// Refunded or revoked by Apple.
    case revoked
    /// No status was available. Never treated as bad news: a lookup that did not answer says
    /// nothing about the subscription.
    case unknown

    /// Whether the user should be told something actionable. Grace period is the only phase
    /// where they still have access *and* something to fix.
    var needsAttentionWhileEntitled: Bool { self == .gracePeriod }
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

    /// Refines the message only. See `SubscriptionRenewalPhase`.
    @Published private(set) var renewalPhase: SubscriptionRenewalPhase = .unknown

    private var transactionUpdatesTask: Task<Void, Never>?

    /// How long either StoreKit await may take before the refresh gives up. Generous enough
    /// not to fire on a slow connection, short enough that the user is never stuck.
    /// Placeholder pending the owner's copy and timing decision.
    static let defaultEntitlementDeadline: Duration = .seconds(12)   // COPY PENDING
    static let defaultProductLoadDeadline: Duration = .seconds(12)   // COPY PENDING

    private let entitlementDeadline: Duration
    private let productLoadDeadline: Duration

    /// Serialises refresh passes. See `refresh()`.
    private var refreshTask: Task<Void, Never>?
    private var pendingRefreshCount = 0

    /// Injection seams. Defaults are the live StoreKit calls, so production behaviour is
    /// unchanged; tests supply deterministic stand-ins because `Product.products` and
    /// `AppStore.sync` cannot be driven from a unit test without a StoreKit session.
    private let loadActiveProductIDs: @Sendable () async -> Set<String>
    private let loadProducts: @Sendable ([String]) async throws -> [Product]
    private let syncPurchases: @Sendable () async throws -> Void
    private let loadRenewalState: @Sendable ([Product]) async -> Product.SubscriptionInfo.RenewalState?

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
        },
        loadRenewalState: @escaping @Sendable ([Product]) async -> Product.SubscriptionInfo.RenewalState? = {
            await SubscriptionStore.currentRenewalState(in: $0)
        },
        entitlementDeadline: Duration = SubscriptionStore.defaultEntitlementDeadline,
        productLoadDeadline: Duration = SubscriptionStore.defaultProductLoadDeadline
    ) {
        self.entitlementDeadline = entitlementDeadline
        self.productLoadDeadline = productLoadDeadline
        self.loadActiveProductIDs = loadActiveProductIDs
        self.loadProducts = loadProducts
        self.syncPurchases = syncPurchases
        self.loadRenewalState = loadRenewalState
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
        let previousState = accessState

        // Only the states that have nothing to show become `.checking`. An unavailable
        // screen must not be replaced by a spinner on every retry: that discards the
        // explanation the user is reading and resets their scroll position.
        if accessState == .checking || accessState == .locked {
            accessState = .checking
        }

        let activeProductIDs: Set<String>
        do {
            activeProductIDs = try await withDeadline(entitlementDeadline) { [loadActiveProductIDs] in
                await loadActiveProductIDs()
            }
        } catch is CancellationError {
            accessState = previousState
            return
        } catch {
            // The entitlement lookup did not answer. That proves nothing about whether the
            // user has access, so it must never take access away.
            accessState = previousState.hasPremiumAccess
                ? previousState
                : .storeUnavailable(.storeUnreachable)
            return
        }

        let hasAccess = SubscriptionEntitlementChecker.grantsAccess(activeProductIDs: activeProductIDs)
        if hasAccess {
            accessState = .entitled
        }

        do {
            let loadedProducts = try await withDeadline(productLoadDeadline) { [loadProducts] in
                try await loadProducts(SubscriptionCatalog.productIDs)
            }
            products = loadedProducts.sorted(by: productSort)
            isEligibleForRequestedTrial = await hasEligibleRequestedTrial(in: products)

            // Never allowed to change access, only the message. A lookup that fails leaves
            // the previous phase alone rather than reporting bad news it cannot support.
            let state = await loadRenewalState(products)
            if state != nil || renewalPhase == .unknown {
                renewalPhase = Self.renewalPhase(for: state)
            }

            if !hasAccess {
                accessState = products.isEmpty
                    ? .storeUnavailable(.productsMissing)
                    : .locked
            }
        } catch is CancellationError {
            // Restore what the user was looking at rather than leaving `.checking` written
            // above as the final state, which stranded the loading overlay permanently.
            if !hasAccess { accessState = previousState }
            return
        } catch {
            // A product-load failure never downgrades an entitlement that already arrived.
            if !hasAccess {
                accessState = .storeUnavailable(
                    error is SubscriptionDeadlineExceeded
                        ? .storeUnreachable
                        : Self.unavailableReason(for: error)
                )
            }
        }
    }

    /// Bounds one await. Without this a StoreKit call that never answers leaves the store in
    /// `.checking` and `isRefreshing` true for the lifetime of the process, which shows an
    /// indefinite spinner and disables retry — the one state a user cannot escape.
    ///
    /// The two awaits are bounded independently on purpose: a slow product load must not
    /// cancel an entitlement result that has already arrived.
    private func withDeadline<T: Sendable>(
        _ duration: Duration,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: duration)
                throw SubscriptionDeadlineExceeded()
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw SubscriptionDeadlineExceeded()
            }
            return first
        }
    }

    /// Maps StoreKit's renewal state onto the phases this app distinguishes.
    ///
    /// `RenewalState` is a `RawRepresentable` struct rather than a closed enum, so unknown
    /// future values are possible and must not be guessed at — they map to `.unknown`, which
    /// is silent, rather than to anything that would alarm the user.
    static func renewalPhase(for state: Product.SubscriptionInfo.RenewalState?) -> SubscriptionRenewalPhase {
        guard let state else { return .unknown }
        switch state {
        case .subscribed:            return .subscribed
        case .inGracePeriod:         return .gracePeriod
        case .inBillingRetryPeriod:  return .billingRetry
        case .expired:               return .expired
        case .revoked:               return .revoked
        default:                     return .unknown
        }
    }

    /// Reads the renewal state from the products already loaded, so no extra network call is
    /// made and no subscription group identifier is hardcoded. The fixture group id in
    /// `CosmicRituals.storekit` never reaches App Store Connect, so hardcoding it would work
    /// in tests and fail in production - the worst possible direction.
    ///
    /// Only `.verified` statuses are read. An unverified status is not evidence of anything.
    static func currentRenewalState(in products: [Product]) async -> Product.SubscriptionInfo.RenewalState? {
        for product in products {
            guard let subscription = product.subscription else { continue }
            guard let statuses = try? await subscription.status else { continue }
            for status in statuses {
                guard case .verified = status.transaction else { continue }
                return status.state
            }
        }
        return nil
    }

    /// Distinguishes "you are offline" from "StoreKit itself failed". Anything else is
    /// reported as unreachable rather than guessed at.
    static func unavailableReason(for error: Error) -> SubscriptionUnavailableReason {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .networkError(let urlError):
                switch urlError.code {
                case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
                    return .offline
                default:
                    return .storeUnreachable
                }
            default:
                return .storeUnreachable
            }
        }
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return .offline
        }
        return .storeUnreachable
    }

    func restorePurchases() async {
        do {
            try await syncPurchases()
            await refresh()

            // A sync that succeeds and still finds nothing is the account-mismatch signal:
            // StoreKit has no error for "signed in to the wrong Apple Account", so silence
            // here is the only evidence. Never overwrite access the user actually has.
            if !accessState.hasPremiumAccess {
                accessState = .storeUnavailable(.restoreFoundNoEntitlements)
            }
        } catch is CancellationError {
            return
        } catch StoreKitError.userCancelled {
            // Dismissing the sign-in sheet is not a failure and must not be reported as one.
            return
        } catch {
            // A restore that fails must never take away access the user already has: the
            // entitlement was verified locally and does not depend on this sync succeeding.
            guard !accessState.hasPremiumAccess else { return }
            accessState = .storeUnavailable(.restoreFailed)
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
