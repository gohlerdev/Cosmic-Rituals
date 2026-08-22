import Foundation

/// Which distribution channel this binary was compiled for, and — more importantly — the
/// evidence of that choice inside the compiled product.
///
/// The problem this solves: before it existed, a `Release` build and a `TestFlight` build were
/// byte-indistinguishable apart from `CFBundleVersion`. `NEXT_LEVEL_PLAN.md` Phase 1 asks that
/// "public archive validation fails if the bypass symbol is present", and there was no symbol
/// to detect. The compilation condition leaves no trace of itself: `#if` that resolves to
/// `false` compiles to nothing at all.
///
/// So the marker is a string constant, deliberately consumed at a call site that survives
/// optimisation and stripping, landing it in `__TEXT,__cstring` where `strings` can find it.
/// "Bypass symbol" therefore means this string, not an `nm` symbol — a `Release` build is
/// stripped and has no symbol table worth reading.
///
/// The two markers are asymmetric on purpose. Checking only for the absence of the beta marker
/// would pass on an empty file, a truncated download, or a binary the checker failed to read.
/// Requiring the public marker to be *present* means the check has to prove it can see inside
/// the binary before it is allowed to say yes.
enum ReleaseChannel {

    #if TESTFLIGHT_BETA_ACCESS

    /// Internal testing distribution: purchases are bypassed so testers can reach the offline
    /// product without a live App Store session. Never valid for public release.
    static let isTestingDistribution = true

    /// Present only in an internal testing build. Its presence in a public candidate is a
    /// release-blocking defect.
    static let marker = "COSMIC_RITUALS_TESTING_ACCESS_BUILD"

    #else

    static let isTestingDistribution = false

    /// Present in every non-testing build. Its *absence* means the inspector could not read
    /// the binary and must not report a pass.
    static let marker = "COSMIC_RITUALS_PUBLIC_BUILD"

    #endif

    /// Exactly one marker is compiled in. Declaring both unconditionally would put both
    /// strings in every binary and make the inspection meaningless, so tests that need the
    /// other one spell it out as a literal - test code never ships in a Release archive.
}
