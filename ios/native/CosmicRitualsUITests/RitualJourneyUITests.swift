import XCTest

/// End-to-end coverage for the acceptance slice named in `NEXT_LEVEL_PLAN.md` §10:
/// choose a reviewed ritual, see the exact calculation context with no fabricated
/// recommendation, prepare materials, begin offline, advance, force quit, resume at the
/// correct step, complete respectful closure, and inspect safety/source/tradition limits.
///
/// These tests drive the real app process. They deliberately read the current step from
/// the interface instead of assuming a clean install, so a device that already holds
/// ritual progress does not produce a false failure.
final class RitualJourneyUITests: XCTestCase {

    private let vidhiID = "daily-panchopachara"
    private let vidhiTitle = "Daily Panchopachara Pooja"
    private let stepCount = 12
    private let requiredMaterialName = "Murti, image, or other sacred focus"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Launch

    /// `-uiTestingPremium` is compiled out of Release; it exists so automation can reach
    /// the offline product without a live App Store session. `-ritualSelectedDestination`
    /// lands directly on the Pooja surface through the argument domain, which keeps the
    /// test off the themed navigation bar's hit targets.
    @discardableResult
    private func launchApp(extraLaunchArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingPremium", "-ritualSelectedDestination", "3"]
            + extraLaunchArguments
        app.launch()
        return app
    }

    // MARK: - Helpers

    /// Identifier lookup that does not assume an element type. SwiftUI decides whether a
    /// given modifier lands on a scroll view, a button, or a plain container, and that
    /// choice is not part of the app's contract — matching on type makes tests brittle.
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func requireExistence(
        _ element: XCUIElement,
        _ message: String,
        timeout: TimeInterval = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message, file: file, line: line)
    }

    /// The guide surfaces are built on `LazyVStack`, so a section that has not been
    /// scrolled into range does not exist in the hierarchy at all — `exists` is false
    /// rather than merely `isHittable` being false. Anything below the fold therefore has
    /// to be scrolled *into being* before it can be asserted on or tapped.
    /// A fixed swipe budget cannot work across text sizes: the same guide that needs three
    /// swipes at the default size needs dozens at `accessibility-extra-extra-extra-large`,
    /// and any constant large enough for the latter wastes minutes on the former. So this
    /// scrolls until the element appears or the content genuinely stops advancing, using a
    /// fingerprint of what is currently on screen to detect the bottom. The cap is only a
    /// runaway guard, not the normal exit.
    @discardableResult
    private func scrollUntilExists(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 80
    ) -> Bool {
        guard !element.exists else { return true }

        let scroll = app.scrollViews.firstMatch
        var swipes = 0
        var stalled = 0
        var lastFingerprint = ""

        while !element.exists && swipes < maxSwipes {
            let fingerprint = visibleFingerprint(of: app)
            scroll.swipeUp()
            swipes += 1

            if visibleFingerprint(of: app) == fingerprint {
                stalled += 1
                // Two consecutive swipes that changed nothing on screen means the scroll
                // view is at its end and the element is genuinely absent.
                if stalled >= 2 { break }
            } else {
                stalled = 0
            }
            lastFingerprint = fingerprint
        }
        _ = lastFingerprint
        return element.exists
    }

    /// Identifies what is currently rendered. Static-text *order* in the query is not
    /// visual order and the leading entries (navigation bar, sticky header) stay constant
    /// while the body scrolls, so a prefix of labels is a false constant. The frame of the
    /// last materialised text moves on every real scroll, which makes it a dependable
    /// end-of-content signal for a `LazyVStack`.
    private func visibleFingerprint(of app: XCUIApplication) -> String {
        let texts = app.staticTexts.allElementsBoundByIndex
        guard let last = texts.last else { return "empty" }
        return "\(texts.count)|\(last.label)|\(Int(last.frame.origin.y))"
    }

    /// Height of the floating navigation bar and search field that the Pooja surface
    /// overlays on top of its scroll content. An element whose centre falls inside this
    /// band reports as hittable but forwards the tap to the overlay instead, so the test
    /// must scroll it clear before tapping.
    private let bottomOverlayHeight: CGFloat = 190

    /// Scrolls the first scroll view until `element` exists and its centre is clear of the
    /// bottom overlays, then taps it.
    private func scrollToAndTap(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            scrollUntilExists(element, in: app, maxSwipes: maxSwipes),
            "Expected element to come into existence before tapping",
            file: file,
            line: line
        )

        let clearLimit = app.frame.maxY - bottomOverlayHeight
        var swipes = 0
        while element.exists,
              element.frame.midY > clearLimit || !element.isHittable,
              swipes < maxSwipes {
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
            swipes += 1
        }

        XCTAssertTrue(element.isHittable, "Expected element to become hittable", file: file, line: line)
        XCTAssertLessThan(
            element.frame.midY,
            clearLimit,
            "Expected element to scroll clear of the bottom overlays before tapping",
            file: file,
            line: line
        )
        element.tap()
    }

    /// The begin action lives in a bottom safe-area inset, so it stays on screen while the
    /// rest of the guide scrolls. Its title is the most reliable readable signal of
    /// preparation state.
    private func beginButton(in app: XCUIApplication) -> XCUIElement {
        element("pooja.begin.\(vidhiID)", in: app)
    }

    /// Reads "Step N of 12" from the navigation bar and returns N.
    private func currentStepNumber(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> Int {
        let predicate = NSPredicate(format: "label BEGINSWITH 'Step ' AND label ENDSWITH ' of \(stepCount)'")
        let title = app.navigationBars.staticTexts.matching(predicate).firstMatch
        guard title.waitForExistence(timeout: 20) else {
            XCTFail("Guided practice did not show a 'Step N of \(stepCount)' title", file: file, line: line)
            return -1
        }
        let digits = title.label
            .replacingOccurrences(of: " of \(stepCount)", with: "")
            .replacingOccurrences(of: "Step ", with: "")
        return Int(digits) ?? -1
    }

    /// Walks backwards until the guided flow sits on step 1, so step assertions are absolute.
    private func rewindToFirstStep(in app: XCUIApplication) {
        let previous = app.buttons["Previous"]
        var guardCounter = 0
        while previous.exists && previous.isEnabled && guardCounter < stepCount + 2 {
            previous.tap()
            guardCounter += 1
        }
        XCTAssertEqual(currentStepNumber(in: app), 1, "Expected to rewind to the first step")
    }

    private func openPoojaLibrary(extraLaunchArguments: [String] = []) -> XCUIApplication {
        let app = launchApp(extraLaunchArguments: extraLaunchArguments)
        requireExistence(element("pooja.library", in: app), "Pooja library did not appear")
        return app
    }

    // MARK: - §10 acceptance slice

    func testCompleteRitualJourneySurvivesForceQuitAndResumesAtCorrectStep() throws {
        var app = openPoojaLibrary()

        // 1. The calculation context is factual and states no observance obligation.
        //
        //    The library is a LazyVStack, so at accessibility text sizes the header alone
        //    can fill the viewport and the context card is not instantiated until it is
        //    scrolled toward. That is correct SwiftUI behaviour, not a defect, so the
        //    assertion scrolls to find the card rather than assuming it is already built —
        //    otherwise this test passes at default text size and fails at XXXL for a
        //    reason that has nothing to do with the ritual journey.
        let dayContext = element("pooja.dayContext", in: app)
        XCTAssertTrue(
            scrollUntilExists(dayContext, in: app),
            "Ritual context card was not reachable by scrolling the Pooja library"
        )
        XCTAssertTrue(
            scrollUntilExists(app.staticTexts["CALCULATED"], in: app),
            "Context card must be labelled as calculated"
        )
        let disclaimer = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'do not make one Pooja universally required today'")
        ).firstMatch
        XCTAssertTrue(
            scrollUntilExists(disclaimer, in: app),
            "Context card must state that calculated facts do not oblige a Pooja"
        )

        // 2. Choose one of the twelve reviewed rituals.
        scrollToAndTap(element("pooja.vidhi.\(vidhiID)", in: app), in: app)
        requireExistence(app.navigationBars[vidhiTitle], "Guide detail did not open")

        // 3. Prepare the required material. The begin action reports readiness, and it
        //    stays on screen in the bottom inset while the guide scrolls.
        let begin = beginButton(in: app)
        requireExistence(begin, "Begin action did not appear on the guide detail")
        XCTAssertTrue(
            begin.label.contains("required left"),
            "A guide with no prepared materials must not invite the user straight in; was '\(begin.label)'"
        )

        let materialButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", requiredMaterialName)
        ).firstMatch
        scrollToAndTap(materialButton, in: app)
        XCTAssertTrue(
            begin.label == "Begin guided Pooja",
            "Ticking the required material must be reflected in the begin action; was '\(begin.label)'"
        )

        // 4. Safety, sources, and tradition limits are inspectable before starting.
        for section in ["Prepare materials", "Safety and respectful closure", "Tradition and sources"] {
            let heading = app.staticTexts[section]
            XCTAssertTrue(
                scrollUntilExists(heading, in: app),
                "Guide detail must expose the '\(section)' section"
            )
        }

        // 5. Begin offline and advance several steps.
        begin.tap()
        requireExistence(element("pooja.guided.\(vidhiID)", in: app), "Guided practice did not open")
        rewindToFirstStep(in: app)

        let advanceCount = 3
        for _ in 0..<advanceCount {
            app.buttons["Next"].tap()
        }
        let stepBeforeQuit = currentStepNumber(in: app)
        XCTAssertEqual(stepBeforeQuit, 1 + advanceCount, "Advancing must move one step at a time")

        // 6. Force quit and reopen.
        app.terminate()
        app = openPoojaLibrary()

        // 7. Resume entry point reports the correct step and restores it.
        //    Scroll-aware for the same LazyVStack reason as the context card: at
        //    accessibility text sizes the card sits below the fold on a fresh launch.
        let resumeCard = element("pooja.resume.\(vidhiID)", in: app)
        XCTAssertTrue(
            scrollUntilExists(resumeCard, in: app),
            "Unfinished practice must offer a resume entry point after force quit"
        )
        XCTAssertTrue(
            resumeCard.label.contains("Resume step \(stepBeforeQuit) of \(stepCount)"),
            "Resume card must name the saved step; was '\(resumeCard.label)'"
        )
        scrollToAndTap(resumeCard, in: app)
        if !element("pooja.guided.\(vidhiID)", in: app).waitForExistence(timeout: 15) {
            let dump = XCTAttachment(string: app.debugDescription)
            dump.name = "hierarchy-after-resume-tap"
            dump.lifetime = .keepAlways
            add(dump)
            let bars = app.navigationBars.allElementsBoundByIndex.map { $0.identifier }
            XCTFail("Resuming did not open guided practice. Navigation bars on screen: \(bars)")
        }
        XCTAssertEqual(
            currentStepNumber(in: app),
            stepBeforeQuit,
            "Resuming must land on the step the ritual was interrupted at"
        )

        // 8. Complete respectful closure.
        var safety = 0
        while app.buttons["Next"].exists && safety < stepCount + 2 {
            app.buttons["Next"].tap()
            safety += 1
        }
        let complete = app.buttons["Complete"]
        requireExistence(complete, "Final step must offer a Complete action")
        complete.tap()

        requireExistence(app.navigationBars["Pooja complete"], "Completing did not reach the closure screen")
        XCTAssertTrue(
            app.staticTexts["Close respectfully"].waitForExistence(timeout: 10),
            "Closure screen must show respectful completion items"
        )
        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Review from the beginning'")
            ).firstMatch.exists,
            "Closure screen must offer a deliberate restart rather than auto-resetting"
        )
    }

    /// A completed ritual must not keep advertising itself as unfinished work.
    func testCompletedRitualIsNotOfferedAsUnfinishedPractice() throws {
        let app = openPoojaLibrary()
        let resumeCard = element("pooja.resume.\(vidhiID)", in: app)
        guard resumeCard.waitForExistence(timeout: 5) else { return }
        XCTAssertFalse(
            resumeCard.label.contains("Completed"),
            "A completed ritual must not appear as a 'continue your ritual' prompt"
        )
    }

    // MARK: - Content boundaries

    func testGuideDetailNeverPresentsPriestBoundaryContentAsHouseholdInstruction() throws {
        let app = openPoojaLibrary()
        scrollToAndTap(element("pooja.vidhi.satyanarayana-vrata", in: app), in: app)
        requireExistence(app.navigationBars["Satyanarayana Vrata Pooja"], "Priest-recommended guide did not open")

        let boundary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'priest' OR label CONTAINS[c] 'officiant'")
        ).firstMatch
        var swipes = 0
        while !boundary.exists && swipes < 20 {
            app.scrollViews.firstMatch.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(
            boundary.exists,
            "A priest-recommended guide must visibly name the officiant boundary"
        )
    }

    // MARK: - Accessibility

    /// Every audit type the system can report, keyed by raw bitmask. Keying on the raw
    /// value rather than on `compactDescription` is deliberate: the two Dynamic Type
    /// variants ("unsupported" / "partially unsupported") are Apple strings that change
    /// between Xcode releases, and a reworded string must not read as a new class of defect.
    /// Raw values are from `XCUIAccessibilityAuditTypes.h`
    /// (`NS_OPTIONS(uint64_t)`: contrast 1<<0, elementDetection 1<<1, hitRegion 1<<2,
    /// sufficientElementDescription 1<<3, dynamicType 1<<16, textClipped 1<<17, trait 1<<18).
    private static let auditTypeNames: [UInt64: String] = [
        XCUIAccessibilityAuditType.contrast.rawValue: "contrast",
        XCUIAccessibilityAuditType.elementDetection.rawValue: "elementDetection",
        XCUIAccessibilityAuditType.hitRegion.rawValue: "hitRegion",
        XCUIAccessibilityAuditType.sufficientElementDescription.rawValue: "sufficientElementDescription",
        XCUIAccessibilityAuditType.dynamicType.rawValue: "dynamicType",
        XCUIAccessibilityAuditType.textClipped.rawValue: "textClipped",
        XCUIAccessibilityAuditType.trait.rawValue: "trait",
    ]

    private static func auditTypeName(_ raw: UInt64) -> String {
        auditTypeNames[raw] ?? "unnamedAuditType(rawValue: \(raw))"
    }

    /// The Dynamic Type size the budget was recorded at, and the launch arguments that
    /// pin it. `UICTContentSizeCategoryL` is the system default, so these numbers describe
    /// the size most people actually see — and pinning it is what makes the numbers
    /// reproducible, because both the contrast and Dynamic Type counts move with text size.
    private static let auditContentSize = "UICTContentSizeCategoryL"
    private static let auditLaunchArguments = [
        "-UIPreferredContentSizeCategoryName", auditContentSize
    ]

    /// Accepted accessibility debt per surface, recorded on the reference runner:
    /// iPhone 17 simulator, Debug, `auditContentSize`. The counts are viewport-dependent
    /// because both surfaces are `LazyVStack`s, so a different simulator model is expected
    /// to need its own recording rather than to match these.
    ///
    /// These are ceilings, not targets. Nothing listed here is acceptable design; each
    /// number is a promise that the surface is no worse than the day the debt was written
    /// down. Phase 4 lowers them. Nothing is allowed to raise them.
    private static let auditBudget: [String: [UInt64: Int]] = [
        "pooja-library": [
            // Observed 14, 14 and 16 on three consecutive runs after the photograph was
            // dimmed (19 and 19 before it). The contrast count on this surface is not
            // reproducible to the unit: the audit samples a composited photograph and the
            // library is a LazyVStack, so how much of it has materialised shifts what gets
            // sampled. Budgeted at the top of the observed band rather than the best run,
            // because a guard that flakes gets muted, and a muted guard protects nothing.
            XCUIAccessibilityAuditType.contrast.rawValue: 17,
            XCUIAccessibilityAuditType.dynamicType.rawValue: 8,
        ],
        // guided-practice contrast rose 5 -> 7 when the photograph was dimmed. Stable across
        // three runs, and the two additions are carded captions rather than the un-carded
        // pills the change was aimed at.
        //
        // The carded case was then modelled, and the model disagrees with the audit. Text on
        // CosmicGlassCard over the veil measures 9.37:1 secondary and 7.57:1 tertiary at the
        // shipped card opacity, worst cell across all three dark themes - and dimming the
        // photograph improves it to 10.09 and 8.09. Every flagged label uses
        // theme.semanticSecondaryText; this file has no uses of SwiftUI's dimmer .secondary.
        // So there is no computable contrast problem on these elements, yet the system audit
        // reports one, most likely from sampling antialiased .caption glyphs over a textured
        // card.
        //
        // Recorded rather than chased. Do not tune CosmicGlassCard's opacity to move this
        // number: raising it to 0.92 took guided to 6 and 0.97 took it to 5 while sending
        // library back from 14 to 19, which is trial-fitting two coupled surfaces against a
        // measurement that is already suspect.
        "guided-practice": [
            XCUIAccessibilityAuditType.contrast.rawValue: 7,
            XCUIAccessibilityAuditType.dynamicType.rawValue: 2,
        ],
    ]

    /// How far under budget a surface may drift before the budget is called stale. Sized to
    /// the measured run-to-run variance of the contrast audit (about 3 on the library), so
    /// normal jitter does not read as a fix. A real fix removes a whole class of finding and
    /// still trips this. There is no tolerance in the other direction — any increase above
    /// the budget is a regression by definition.
    private static let auditBudgetSlack = 4

    /// Runs the system audit, attaches the itemised report, and returns the issue count per
    /// audit type.
    ///
    /// Returning `true` from the handler marks the issue handled, which suppresses XCTest's
    /// own one-failure-per-issue reporting. That is deliberate: those failures name only the
    /// audit type, which is neither enough to fix anything nor enough to tell a regression
    /// from debt that was already agreed. Judgement happens in `assertAuditWithinBudget`.
    private func auditCountingIssuesByType(
        _ app: XCUIApplication,
        surface: String
    ) throws -> [UInt64: Int] {
        var findings: [String] = []
        var counts: [UInt64: Int] = [:]

        try app.performAccessibilityAudit { issue in
            counts[issue.auditType.rawValue, default: 0] += 1
            let element = issue.element?.debugDescription ?? "unknown element"
            findings.append(
                """
                [\(Self.auditTypeName(issue.auditType.rawValue))] \(issue.compactDescription)
                    \(issue.detailedDescription)
                    element: \(element.prefix(300))
                """
            )
            return true
        }

        guard !findings.isEmpty else { return counts }

        let runner = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "device"
        let report = """
            \(surface) accessibility audit — \(findings.count) issue(s)
            runner: \(runner) · \(ProcessInfo.processInfo.operatingSystemVersionString) · \(Self.auditContentSize)
            counts by type:
            \(Self.budgetLiteral(for: counts))

            """ + findings.joined(separator: "\n\n")

        let attachment = XCTAttachment(string: report)
        attachment.name = "accessibility-audit-\(surface)"
        attachment.lifetime = .keepAlways
        add(attachment)

        return counts
    }

    /// Fails when a surface exceeds its recorded debt, when it reports an audit type the
    /// budget has never seen, or when the recorded debt is stale because the surface got
    /// better. Passing means "exactly as bad as we agreed — no worse, and no quietly
    /// better either".
    private func assertAuditWithinBudget(
        _ app: XCUIApplication,
        surface: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let observed = try auditCountingIssuesByType(app, surface: surface)

        guard let budget = Self.auditBudget[surface] else {
            XCTFail(
                "No accessibility budget recorded for '\(surface)'. Add one to `auditBudget`:\n"
                    + Self.budgetLiteral(for: observed),
                file: file,
                line: line
            )
            return
        }

        var problems: [String] = []
        for raw in Set(observed.keys).union(budget.keys).sorted() {
            let seen = observed[raw] ?? 0
            let allowed = budget[raw] ?? 0
            let name = Self.auditTypeName(raw)

            if allowed == 0 {
                problems.append(
                    "NEW AUDIT TYPE — '\(name)' reported \(seen) issue(s). This class of finding "
                        + "did not exist when the debt was recorded; fix it rather than budgeting it."
                )
            } else if seen > allowed {
                problems.append(
                    "REGRESSION — '\(name)' grew from \(allowed) to \(seen) issue(s)."
                )
            } else if seen == 0 || seen < allowed - Self.auditBudgetSlack {
                problems.append(
                    "STALE BUDGET — '\(name)' is budgeted at \(allowed) but only \(seen) remain. "
                        + "Lower the number, deleting the entry once it reaches 0, so the fix cannot "
                        + "be silently undone. If a second run does not reproduce it, it was "
                        + "composition jitter rather than a fix."
                )
            }
        }

        guard !problems.isEmpty else { return }

        XCTFail(
            """
            \(surface) is outside its recorded accessibility debt.

            \(problems.joined(separator: "\n"))

            Observed on this run — the budget entry matching it is:
            "\(surface)": [
            \(Self.budgetLiteral(for: observed))
            ],

            The itemised report naming every element and frame is attached as
            "accessibility-audit-\(surface)".
            """,
            file: file,
            line: line
        )
    }

    private static func budgetLiteral(for counts: [UInt64: Int]) -> String {
        guard !counts.isEmpty else { return "    // no issues" }
        return counts
            .sorted { $0.key < $1.key }
            .map { raw, count in
                if let name = auditTypeNames[raw] {
                    return "    XCUIAccessibilityAuditType.\(name).rawValue: \(count),"
                }
                return "    \(raw): \(count), // unnamed audit type"
            }
            .joined(separator: "\n")
    }

    /// Both surfaces still carry accessibility debt against the shipped ceremonial design,
    /// and that debt is bounded rather than silenced. Two distinct classes of finding are
    /// present, and they are not equally certain.
    ///
    /// * **Dynamic Type unsupported** — definitive. Several labels use fixed point sizes
    ///   (`.font(.system(size:))`), so they cannot scale for a user who needs larger text.
    /// * **Contrast failed** — indicative rather than conclusive. The audit samples the
    ///   composited background, and these surfaces layer text over a photographic sanctuary
    ///   image behind translucent material, which is exactly the case the sampler handles
    ///   least reliably. It still points at real risk, because the same layering is what
    ///   `NEXT_LEVEL_PLAN.md` §5.1 warns about when it says imagery must stay subordinate
    ///   to text behind reliable contrast veils.
    ///
    /// Fixing them belongs to plan Phase 4 (ceremonial redesign), whose exit gate requires
    /// measured contrast for every theme and image crop. Until then the budget in
    /// `auditBudget` is the contract: it fails on a regression, fails on an audit type that
    /// has never been seen before, and fails when the surface improves without the number
    /// being lowered — so a Phase 4 fix cannot be silently reverted.
    func testPoojaLibraryStaysWithinRecordedAccessibilityDebt() throws {
        let app = openPoojaLibrary(extraLaunchArguments: Self.auditLaunchArguments)
        try assertAuditWithinBudget(app, surface: "pooja-library")
    }

    func testGuidedPracticeStaysWithinRecordedAccessibilityDebt() throws {
        let app = openPoojaLibrary(extraLaunchArguments: Self.auditLaunchArguments)
        scrollToAndTap(element("pooja.vidhi.\(vidhiID)", in: app), in: app)
        requireExistence(app.navigationBars[vidhiTitle], "Guide detail did not open")
        element("pooja.begin.\(vidhiID)", in: app).tap()
        requireExistence(element("pooja.guided.\(vidhiID)", in: app), "Guided practice did not open")
        try assertAuditWithinBudget(app, surface: "guided-practice")
    }

    // MARK: - Launch performance

    func testColdLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            launchApp().terminate()
        }
    }
}
