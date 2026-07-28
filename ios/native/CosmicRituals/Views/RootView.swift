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
        bypassStoreRefresh = isUITesting
        _subscriptionStore = StateObject(
            wrappedValue: SubscriptionStore(
                accessState: isUITesting ? .entitled : .checking,
                listensForTransactions: !isUITesting
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
                PanchangView()
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
}

#Preview {
    RootView(subscriptionStore: SubscriptionStore(accessState: .entitled, listensForTransactions: false))
}
