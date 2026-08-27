import SwiftUI

/// App root: owns the active theme variant and injects it into the environment.
/// `PanchangView` reads/writes the same `@AppStorage` key to drive the picker.
@MainActor
struct RootView: View {
    @AppStorage("cosmicThemeVariant") private var variantRaw = CosmicThemeVariant.cosmicDark.rawValue
    @StateObject private var ritualSessionStore: RitualSessionStore

    init() {
        _ritualSessionStore = StateObject(wrappedValue: RitualSessionStore())
    }

    /// Test seam: lets a harness inject a session store without touching
    /// `UserDefaults`.
    init(ritualSessionStore: RitualSessionStore) {
        _ritualSessionStore = StateObject(wrappedValue: ritualSessionStore)
    }

    private var activeScheme: CosmicColorScheme {
        (CosmicThemeVariant(rawValue: variantRaw) ?? .cosmicDark).colorScheme
    }

    var body: some View {
        PanchangView()
            // Keeps the channel marker in __TEXT,__cstring, where the release-boundary
            // inspector finds it after stripping.
            //
            // Deliberately NOT an .accessibilityIdentifier on this view: applied at the root
            // it replaced the identifiers of everything beneath it, so the rest vanished
            // from the accessibility tree. The marker is evidence for a binary inspector,
            // not a UI affordance, and it must not distort the tree the app's own tests
            // query.
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
    }
}

#Preview {
    RootView()
}
