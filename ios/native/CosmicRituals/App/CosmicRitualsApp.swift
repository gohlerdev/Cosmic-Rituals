import SwiftUI

/// Cosmic Rituals — a native SwiftUI app for the Vedic Panchang: the five limbs of
/// the day (tithi, nakshatra, yoga, karana, vara), the Moon's nakshatra & pada, and
/// the thirty day & night muhurtas with live timing — presented in the shared
/// cosmic-glass theme. Day-level limbs are explicitly disclosed as a noon snapshot.
@main
struct CosmicRitualsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
