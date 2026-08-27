import XCTest

/// The traditional-clock surface, driven through the real app process.
///
/// This exists because a green unit suite proves the arithmetic, not that the
/// numbers ever reach a screen. It navigates to the Prahar segment, asserts the
/// eight prahars and the Ishta Kaal reading are actually rendered, checks that
/// the convention disclosure travels with them, and attaches a screenshot so a
/// reviewer can see the surface without booting anything.
final class PraharClockUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Destination 1 is the Choghadiya / Hora / Prahar screen; the launch
    /// argument avoids depending on themed tab-bar hit targets.
    private func launchOnTimeDivisions() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ritualSelectedDestination", "1"]
        app.launch()
        return app
    }

    private func requireExistence(_ element: XCUIElement, _ message: String, timeout: TimeInterval = 20) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message)
    }

    func testPraharClockRendersTheEightPraharsAndIshtaKaal() throws {
        let app = launchOnTimeDivisions()

        let praharTab = app.buttons["Prahar"].firstMatch
        requireExistence(praharTab, "the Prahar segment must be reachable from the time-divisions screen")
        praharTab.tap()

        // The Ishta Kaal card and its unit labels.
        requireExistence(app.staticTexts["ISHTA KAAL"], "the Ishta Kaal card must render")
        for unit in ["ghati", "pala", "vipala"] {
            XCTAssertTrue(app.staticTexts[unit].waitForExistence(timeout: 5), "missing unit label: \(unit)")
        }

        // All eight prahars, by name, in both halves of the day.
        for name in ["Purvahna", "Madhyahna", "Aparahna", "Sayahna",
                     "Pradosha", "Nishitha", "Triyama", "Usha"] {
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5), "missing prahar: \(name)")
        }
        requireExistence(app.staticTexts["Day Prahars"], "day prahar section")
        requireExistence(app.staticTexts["Night Prahars"], "night prahar section")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "prahar-clock"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    /// The ghati convention must be disclosed on the surface that uses it, not
    /// only in a source comment. A reader has to be able to tell that dinamana
    /// moves because ghatis are fixed, and that a competing reckoning exists.
    func testConventionAndDayLengthAreDisclosedOnScreen() throws {
        let app = launchOnTimeDivisions()
        app.buttons["Prahar"].firstMatch.tap()

        requireExistence(app.staticTexts["Day and Night Length"], "dinamana / ratrimana card")
        XCTAssertTrue(app.staticTexts["Dinamana (daylight)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ratrimana (night)"].waitForExistence(timeout: 5))

        let disclosure = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "30 ghatis")
        ).firstMatch
        requireExistence(disclosure, "the competing 30-ghati reckoning must be disclosed on screen")

        let proportional = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "only near the equator")
        ).firstMatch
        requireExistence(proportional, "the proportional-prahar caveat must be disclosed on screen")
    }
}
