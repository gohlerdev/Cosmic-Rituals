import XCTest

/// Proves, against a running build, that the product behaves as the channel it claims to be.
///
/// This is the third and last layer of the release boundary, and the only one that judges the
/// app while it is actually running:
///
/// 1. the build phase fails a build whose configuration and flag disagree;
/// 2. `scripts/inspect_release_boundary.sh` reads markers out of a finished binary;
/// 3. this launches that binary and checks what it does.
///
/// It lives in the UI test target because the unit target cannot be built in `Release` or
/// `TestFlight` at all: `ENABLE_TESTABILITY` is set only in the project's Debug configuration,
/// so `@testable import CosmicRituals` fails to compile there. Do not "fix" that by overriding
/// `ENABLE_TESTABILITY` on the command line — testability changes what the compiler emits, and
/// a Release build with it forced on is no longer the build being judged.
///
/// Configuration and method are paired at invocation time, and a mismatched pairing fails
/// loudly rather than passing quietly:
///
///     xcodebuild -scheme CosmicRitualsReleaseBoundary -configuration Release \
///       -only-testing:CosmicRitualsUITests/ReleaseBoundaryUITests/testPublicBuildCarriesThePublicMarkerAndGatesAccess test
///
///     xcodebuild -scheme CosmicRitualsReleaseBoundary -configuration TestFlight \
///       -only-testing:CosmicRitualsUITests/ReleaseBoundaryUITests/testInternalTestingBuildCarriesTheTestingMarker test
final class ReleaseBoundaryUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Launches with no arguments at all. `-uiTestingPremium` is compiled out of every
    /// non-Debug build, and passing it here would only obscure what is being measured.
    private func launched() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    // MARK: - Public candidate

    /// Run this against `-configuration Release`.
    func testPublicBuildCarriesThePublicMarkerAndGatesAccess() {
        let app = launched()

        // The channel marker itself is checked in the binary by
        // scripts/inspect_release_boundary.sh. What this layer adds is the consequence: with
        // no entitlement and no testing bypass, a public build must stop at a purchase
        // surface and must never show the testing banner.
        XCTAssertFalse(
            app.descendants(matching: .any).containing(
                NSPredicate(format: "label CONTAINS 'TestFlight testing access'")
            ).firstMatch.waitForExistence(timeout: 5),
            "A public build must never show the testing-access banner"
        )
        let gate = app.descendants(matching: .any).matching(identifier: "subscription.gate").firstMatch
        let unavailable = app.descendants(matching: .any).matching(identifier: "subscription.unavailable").firstMatch
        if !(gate.waitForExistence(timeout: 30) || unavailable.waitForExistence(timeout: 10)) {
            let dump = XCTAttachment(string: app.debugDescription)
            dump.name = "release-build-hierarchy"
            dump.lifetime = .keepAlways
            add(dump)
            XCTFail("A public build with no entitlement must reach a purchase surface, not the product")
        }
    }

    // MARK: - Internal testing build

    /// Run this against `-configuration TestFlight`. It is the positive control: if it fails,
    /// the check cannot see the difference between the two channels and the Release result
    /// above means nothing.
    func testInternalTestingBuildCarriesTheTestingMarker() {
        let app = launched()

        // An internal tester must reach the product without a purchase, and must be told
        // plainly that this build does not require one.
        // Matched on any element, not staticTexts: the banner is a Label inside a
        // safeAreaInset, and SwiftUI exposes it as one combined element rather than as a
        // separate static text.
        let banner = app.descendants(matching: .any).containing(
            NSPredicate(format: "label CONTAINS 'TestFlight testing access'")
        ).firstMatch
        if !banner.waitForExistence(timeout: 30) {
            let dump = XCTAttachment(string: app.debugDescription)
            dump.name = "testflight-build-hierarchy"
            dump.lifetime = .keepAlways
            add(dump)
            XCTFail("The internal testing build must show the testing-access banner")
        }
        XCTAssertFalse(
            app.descendants(matching: .any).matching(identifier: "subscription.gate").firstMatch.exists,
            "The internal testing build must not stop at the purchase gate"
        )
    }
}
