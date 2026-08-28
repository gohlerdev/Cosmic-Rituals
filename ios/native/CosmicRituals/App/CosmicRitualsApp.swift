import SwiftUI

/// Cosmic Rituals — a native SwiftUI app for the Vedic Panchang: the five limbs of
/// the day (tithi, nakshatra, yoga, karana, vara), the Moon's nakshatra & pada, and
/// the thirty day & night muhurtas with live timing, and an offline, tradition-aware
/// Pooja Vidhi library — presented in the shared cosmic-glass theme. Day-level limbs
/// are anchored to the selected location's sunrise, with an explicit local-noon
/// fallback when sunrise is unavailable.
@main
struct CosmicRitualsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
