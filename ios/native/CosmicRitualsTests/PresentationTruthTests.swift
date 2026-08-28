import XCTest
@testable import CosmicRituals

/// Pins for the presentation-truth fixes from the second deep audit: the
/// "Best Time Today" selection, the tithi moon-phase glyph, and the
/// Wednesday Abhijit contradiction between the solar card and muhurta list.
final class PresentationTruthTests: XCTestCase {

    private func context(_ y: Int, _ m: Int, _ d: Int) -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: 19.0760, longitude: 72.8777,
            timeZoneIdentifier: "Asia/Kolkata"
        )
    }

    // MARK: Best Time Today

    private func muhurta(id: Int, quality: MuhurtaQuality, start: Date, minutes: Double) -> Muhurta {
        Muhurta(
            id: id, name: "Test", quality: quality, purpose: "",
            startTime: start, endTime: start.addingTimeInterval(minutes * 60), isDay: true
        )
    }

    /// A window that already ended is never "Best Time Today", however
    /// excellent; the recommendation moves to the upcoming match.
    func testBestTimeSkipsEndedWindows() throws {
        let keyword = try XCTUnwrap(MuhurtaLibrary.info(for: 8)).favorable[0].lowercased()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let ended = muhurta(id: 8, quality: .excellent, start: now.addingTimeInterval(-7_200), minutes: 48)
        let upcoming = muhurta(id: 8, quality: .auspicious, start: now.addingTimeInterval(3_600), minutes: 48)

        let best = MuhurtaRecommendation.best(matchingKeywords: [keyword], in: [ended, upcoming], now: now)
        XCTAssertEqual(best?.startTime, upcoming.startTime)
        XCTAssertNil(
            MuhurtaRecommendation.best(matchingKeywords: [keyword], in: [ended], now: now),
            "with only ended matches there is no recommendation"
        )
    }

    /// A mixed or inauspicious window is never recommended even while it is
    /// the one currently running; quality outranks currency. Among equal
    /// quality, a currently running window still wins over a later one.
    func testBestTimePrefersQualityOverCurrency() throws {
        let keyword = try XCTUnwrap(MuhurtaLibrary.info(for: 8)).favorable[0].lowercased()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let currentMixed = muhurta(id: 8, quality: .mixed, start: now.addingTimeInterval(-600), minutes: 48)
        let laterAuspicious = muhurta(id: 8, quality: .auspicious, start: now.addingTimeInterval(3_600), minutes: 48)
        let best = MuhurtaRecommendation.best(
            matchingKeywords: [keyword], in: [currentMixed, laterAuspicious], now: now
        )
        XCTAssertEqual(best?.startTime, laterAuspicious.startTime)
        XCTAssertEqual(best?.quality, .auspicious)

        let currentAuspicious = muhurta(id: 8, quality: .auspicious, start: now.addingTimeInterval(-600), minutes: 48)
        let tieBreak = MuhurtaRecommendation.best(
            matchingKeywords: [keyword], in: [laterAuspicious, currentAuspicious], now: now
        )
        XCTAssertEqual(tieBreak?.startTime, currentAuspicious.startTime, "equal quality: the running window wins")
    }

    // MARK: Tithi moon-phase glyph

    /// The glyph is a function of the tithi: Amavasya is the new moon,
    /// Purnima the full moon, the Ashtamis the quarters. A hard-coded
    /// waning crescent previously rendered for every tithi.
    func testMoonPhaseGlyphTracksTithi() {
        XCTAssertEqual(TithiMoonPhase.symbolName(tithiIndex: 29), "moonphase.new.moon", "Amavasya")
        XCTAssertEqual(TithiMoonPhase.symbolName(tithiIndex: 14), "moonphase.full.moon", "Purnima")
        XCTAssertEqual(TithiMoonPhase.symbolName(tithiIndex: 7), "moonphase.first.quarter", "Shukla Ashtami")
        XCTAssertEqual(TithiMoonPhase.symbolName(tithiIndex: 22), "moonphase.last.quarter", "Krishna Ashtami")
        XCTAssertEqual(TithiMoonPhase.symbolName(tithiIndex: 3), "moonphase.waxing.crescent")
        XCTAssertEqual(TithiMoonPhase.symbolName(tithiIndex: 26), "moonphase.waning.crescent")
    }

    // MARK: Wednesday Abhijit consistency

    /// The muhurta list's eighth daylight window IS Abhijit. The solar card
    /// already declines to present Abhijit as auspicious on Wednesday, so the
    /// list must not label the identical window Excellent on the same screen:
    /// Wednesday demotes it to mixed with the convention stated, and every
    /// other weekday leaves it untouched.
    func testWednesdayDemotesTheAbhijitWindowMuhurta() throws {
        // 2026-07-22 is a Wednesday; 2026-07-23 a Thursday (same fixture week
        // as the published Mumbai kala values).
        let wednesday = CosmicEngine.getMuhurtas(context: context(2026, 7, 22))
        let eighthOnWednesday = try XCTUnwrap(wednesday.first { $0.id == 8 })
        XCTAssertEqual(eighthOnWednesday.quality, .mixed)
        XCTAssertTrue(eighthOnWednesday.purpose.contains("Wednesday"))
        XCTAssertNil(CosmicEngine.getAbhijitMuhurta(context: context(2026, 7, 22)))

        let thursday = CosmicEngine.getMuhurtas(context: context(2026, 7, 23))
        let eighthOnThursday = try XCTUnwrap(thursday.first { $0.id == 8 })
        XCTAssertEqual(eighthOnThursday.quality, .excellent)
        let abhijit = try XCTUnwrap(CosmicEngine.getAbhijitMuhurta(context: context(2026, 7, 23)))
        XCTAssertEqual(eighthOnThursday.startTime.timeIntervalSince(abhijit.start), 0, accuracy: 1,
                       "the eighth daylight muhurta and Abhijit are the same window")
    }

    /// Moonrise must not be gated on sunrise: during Svalbard polar day the
    /// Sun never sets and the solar guard fails, but the Moon still has real
    /// events the bundle computes and the UI must show. 2026-06-21 has no
    /// moonrise at that latitude (below-horizon stretch), so sweep the
    /// following week for at least one genuine event.
    func testPolarDayStillYieldsMoonEventsSomewhereInTheWeek() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Arctic/Longyearbyen")!
        var found = false
        for day in 18...31 {
            let ctx = CalculationContext(
                localDay: cal.date(from: DateComponents(year: 2026, month: 6, day: day, hour: 12))!,
                latitude: 78.2232, longitude: 15.6469,
                timeZoneIdentifier: "Arctic/Longyearbyen"
            )
            XCTAssertNil(CosmicEngine.getSunriseSunset(context: ctx), "polar day persists on 2026-06-\(day)")
            let events = CelestialRiseSet.moonRiseSet(context: ctx)
            if events.moonrise != nil || events.moonset != nil { found = true }
        }
        XCTAssertTrue(found, "the Moon rises or sets on at least one polar-day date in the window")
    }
}


/// The Bengal panjika-lineage disclosure: the app computes drik-style tithis,
/// and in Bengal that is one of two live schools (Bisuddhasiddhanta vs. the
/// Gupta Press Surya-Siddhanta line), which publish different festival dates.
/// The sentence must ship in the panchang source, not only in documentation.
final class BengalLineageDisclosureTests: XCTestCase {
    func testTheDisclosureShipsInThePanchangSurface() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // CosmicRitualsTests
            .deletingLastPathComponent()   // ios/native
            .appendingPathComponent("CosmicRituals/Views/PanchangView.swift")
        let source = try String(contentsOf: root, encoding: .utf8)
        XCTAssertTrue(source.contains("Bisuddhasiddhanta"),
                      "the drik lineage is named")
        XCTAssertTrue(source.contains("Gupta Press"),
                      "the Surya-Siddhanta lineage is named")
        XCTAssertTrue(source.contains("one school's answer, not the canonical one"),
                      "the app does not claim canonicity in Bengal")
    }
}
