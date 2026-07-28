import SwiftUI

/// App root: owns the active theme variant and injects it into the environment.
/// `PanchangView` reads/writes the same `@AppStorage` key to drive the picker.
@MainActor
struct RootView: View {
    @AppStorage("cosmicThemeVariant") private var variantRaw = CosmicThemeVariant.cosmicDark.rawValue
    @StateObject private var subscriptionStore: SubscriptionStore
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

        // This condition exists only in the dedicated testing distribution
        // configuration. The production Release configuration never defines it.
        #if TESTFLIGHT_BETA_ACCESS
        let isTestingDistribution = true
        #else
        let isTestingDistribution = false
        #endif

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
    }

    init(subscriptionStore: SubscriptionStore) {
        bypassStoreRefresh = true
        _subscriptionStore = StateObject(wrappedValue: subscriptionStore)
    }

    private var activeScheme: CosmicColorScheme {
        (CosmicThemeVariant(rawValue: variantRaw) ?? .cosmicDark).colorScheme
    }

    var body: some View {
        Group {
            if subscriptionStore.accessState.hasPremiumAccess {
                if subscriptionStore.accessState.isTestingAccess {
                    PanchangView()
                        .safeAreaInset(edge: .top, spacing: 0) {
                            testingAccessBanner
                        }
                } else {
                    PanchangView()
                }
            } else {
                SubscriptionGateView(store: subscriptionStore)
            }
        }
            .environment(\.cosmicTheme, activeScheme)
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
            .accessibilityLabel("TestFlight testing access. Purchases are not required in this testing build.")
    }
}

#Preview {
    RootView(subscriptionStore: SubscriptionStore(accessState: .entitled, listensForTransactions: false))
}
