import SwiftUI

/// App root: owns the active theme variant and injects it into the environment.
/// `PanchangView` reads/writes the same `@AppStorage` key to drive the picker.
@MainActor
struct RootView: View {
    @AppStorage("cosmicThemeVariant") private var variantRaw = CosmicThemeVariant.cosmicDark.rawValue
    @StateObject private var subscriptionStore: SubscriptionStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _subscriptionStore = StateObject(wrappedValue: SubscriptionStore())
    }

    init(subscriptionStore: SubscriptionStore) {
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
                await subscriptionStore.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await subscriptionStore.refresh() }
            }
    }
}

#Preview {
    RootView(subscriptionStore: SubscriptionStore(accessState: .entitled, listensForTransactions: false))
}
