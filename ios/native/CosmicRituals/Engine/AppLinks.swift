import Foundation

/// The app's published policy and support destinations.
///
/// This file is what remains of the former subscription layer. Cosmic Rituals
/// is free: there is no paywall, no account, no purchase, and no StoreKit
/// code path. The Panchang is computed entirely on this device at no
/// marginal cost, so gating it behind a store — one that could fail and lock
/// every user out of an app that needs no network at all — was never a
/// trade worth making. The policy links stay because a shipped app owes its
/// users a privacy policy and a way to ask for help, purchases or not.
enum AppLinks {
    static let privacyPolicyURL = URL(string: "https://gohlerdev.github.io/Cosmic-Rituals/privacy/")!
    static let termsOfUseURL = URL(string: "https://gohlerdev.github.io/Cosmic-Rituals/terms/")!
    static let supportURL = URL(string: "https://gohlerdev.github.io/Cosmic-Rituals/support/")!
}
