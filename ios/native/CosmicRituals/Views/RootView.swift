import SwiftUI

/// App root: owns the active theme variant and injects it into the environment.
/// `PanchangView` reads/writes the same `@AppStorage` key to drive the picker.
@MainActor
struct RootView: View {
    @AppStorage("cosmicThemeVariant") private var variantRaw = CosmicThemeVariant.cosmicDark.rawValue
    @StateObject private var subscriptionStore: SubscriptionStore
    @StateObject private var ritualSessionStore: RitualSessionStore
    @Environment(\.scenePhase) private var scenePhase
    private let bypassStoreRefresh: Bool

    init() {
        // Visual and UI automation must reach the offline product without a
        // live App Store session. The launch token is compiled out of Release.
        #if DEBUG
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTestingPremium")
        #else
        let isUITesting = false
        #endif

        // Owned by ReleaseChannel so the choice leaves detectable evidence in the built
        // product; an inline #if compiles to nothing and cannot be inspected afterwards.
        let isTestingDistribution = ReleaseChannel.isTestingDistribution

        let initialState = SubscriptionLaunchPolicy.initialState(
            isUITestingPremium: isUITesting,
            isTestingDistribution: isTestingDistribution
        )
        bypassStoreRefresh = initialState.hasPremiumAccess
        _subscriptionStore = StateObject(
            wrappedValue: SubscriptionStore(
                accessState: initialState,
                listensForTransactions: !initialState.hasPremiumAccess
            )
        )
        _ritualSessionStore = StateObject(wrappedValue: RitualSessionStore())
    }

    init(subscriptionStore: SubscriptionStore) {
        bypassStoreRefresh = true
        _subscriptionStore = StateObject(wrappedValue: subscriptionStore)
        _ritualSessionStore = StateObject(wrappedValue: RitualSessionStore(defaults: nil))
    }

    private var activeScheme: CosmicColorScheme {
        (CosmicThemeVariant(rawValue: variantRaw) ?? .cosmicDark).colorScheme
    }

    var body: some View {
        Group {
            if subscriptionStore.accessState.hasPremiumAccess {
                // The banner and its copy are fenced out of every non-testing build. It was
                // already unreachable in Release, but the string still shipped, and a
                // Release binary containing "TestFlight testing access" is exactly the
                // evidence a release audit should never have to explain away.
                #if TESTFLIGHT_BETA_ACCESS
                if subscriptionStore.accessState.isTestingAccess {
                    PanchangView()
                        .safeAreaInset(edge: .top, spacing: 0) {
                            testingAccessBanner
                        }
                } else {
                    PanchangView()
                }
                #else
                PanchangView()
                    .safeAreaInset(edge: .top, spacing: 0) {
                        billingAttentionBanner
                    }
                #endif
            } else {
                SubscriptionGateView(store: subscriptionStore)
            }
        }
            // Keeps the channel marker in __TEXT,__cstring, where the release-boundary
            // inspector finds it after stripping.
            //
            // Deliberately NOT an .accessibilityIdentifier on this view: applied at the root
            // it replaced the identifiers of everything beneath it, so `subscription.gate`
            // and the rest vanished from the accessibility tree. The marker is evidence for
            // a binary inspector, not a UI affordance, and it must not distort the tree the
            // app's own tests query.
            .background {
                // No explicit font: a fixed size here is a real Dynamic Type finding, and
                // an invisible string is not worth one.
                Text(verbatim: ReleaseChannel.marker)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
            .environment(\.cosmicTheme, activeScheme)
            .environmentObject(ritualSessionStore)
            .environment(\.colorScheme, activeScheme.colorScheme)
            .preferredColorScheme(activeScheme.colorScheme)
            .tint(activeScheme.primary)
            .task {
                guard !bypassStoreRefresh else { return }
                await subscriptionStore.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, !bypassStoreRefresh else { return }
                Task { await subscriptionStore.refresh() }
            }
    }

    /// Shown only in the grace period: the one phase where the user still has access and
    /// still has something they can fix. Every other phase is either fine or already over,
    /// and a banner there would be noise during a ritual.
    ///
    /// Copy is factual and promises nothing. Final wording, and whether this appears at all,
    /// is the owner's call.
    @ViewBuilder
    private var billingAttentionBanner: some View {
        if subscriptionStore.renewalPhase.needsAttentionWhileEntitled {
            Link(destination: SubscriptionCatalog.manageSubscriptionsURL) {
                Label(
                    "Payment issue \u{2014} access continues for now",   // COPY PENDING
                    systemImage: "exclamationmark.circle"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(activeScheme.semanticPrimaryText)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(activeScheme.semanticDivider)
                        .frame(height: 0.5)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Payment issue. Your subscription could not renew and access continues for now.")
            .accessibilityHint("Opens Manage Subscriptions")
        }
    }

    #if TESTFLIGHT_BETA_ACCESS
    private var testingAccessBanner: some View {
        Label("TestFlight testing access", systemImage: "testtube.2")
            .font(.caption.weight(.semibold))
            .foregroundStyle(activeScheme.semanticPrimaryText)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(activeScheme.semanticDivider)
                    .frame(height: 0.5)
            }
            .accessibilityLabel("TestFlight testing access. Purchases are not required in this testing build. \(ReleaseChannel.marker)")
    }
    #endif
}

#Preview {
    RootView(subscriptionStore: SubscriptionStore(accessState: .entitled, listensForTransactions: false))
}
