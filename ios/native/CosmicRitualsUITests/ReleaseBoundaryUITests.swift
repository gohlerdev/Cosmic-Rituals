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

    /// Launches with no arguments at all: the app is free and needs none.
    private func launched() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    // MARK: - Public candidate

    /// Run this against `-configuration Release`. The app is free: a public
    /// build must reach the PRODUCT immediately. It previously had to stop at
    /// a purchase surface, and that requirement is exactly what stranded real
    /// devices when the store had nothing to sell — the paywall could not be
    /// priced and the Panchang could not be reached.
    func testPublicBuildOpensStraightIntoTheProduct() {
        let app = launched()

        XCTAssertFalse(
            app.descendants(matching: .any).containing(
                NSPredicate(format: "label CONTAINS 'TestFlight testing access'")
            ).firstMatch.waitForExistence(timeout: 5),
            "A public build must never show the testing-access banner"
        )
        for identifier in ["subscription.gate", "subscription.unavailable"] {
            XCTAssertFalse(
                app.descendants(matching: .any).matching(identifier: identifier).firstMatch
                    .waitForExistence(timeout: 3),
                "The paywall is deleted; \(identifier) must not exist"
            )
        }

        let panchang = app.descendants(matching: .any).matching(identifier: "panchang.lunarmonth").firstMatch
        if !panchang.waitForExistence(timeout: 30) {
            let dump = XCTAttachment(string: app.debugDescription)
            dump.name = "release-build-hierarchy"
            dump.lifetime = .keepAlways
            add(dump)
            XCTFail("A public build must land in the Panchang with no purchase surface")
        }
    }
}
