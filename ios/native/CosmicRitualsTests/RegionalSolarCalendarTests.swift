import XCTest
@testable import CosmicRituals

/// The four regional solar-month reckonings. The critical-moment rules are
/// pinned to Dershowitz & Reingold's formalization (eqs. 25-28), and the
/// day-1 fixtures to published 2026 regional new-year dates — the same
/// external-source discipline the lunisolar tests use.
final class RegionalSolarCalendarTests: XCTestCase {

    private func context(_ y: Int, _ m: Int, _ d: Int,
                         lat: Double = 13.0827, lon: Double = 80.2707,
                         tz: String = "Asia/Kolkata") -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: tz)!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: lat, longitude: lon, timeZoneIdentifier: tz
        )
    }

    private func civilDay(_ date: Date, tz: String = "Asia/Kolkata") -> (y: Int, m: Int, d: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: tz)!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year!, c.month!, c.day!)
    }

    // MARK: - Published new-year fixtures, 2026

    /// Tamil Puthandu 2026: Chithirai 1 falls on 14 April 2026 (published
    /// Tamil calendars; Mesha sankranti mid-morning IST, well before
    /// sunset, so the Tamil rule starts the month the same day).
    func testTamilNewYearIsApril14() throws {
        let month = try XCTUnwrap(RegionalSolarCalendarEngine.solarMonth(
            context: context(2026, 4, 20), rule: .tamil))
        XCTAssertEqual(month.monthName, "Chithirai")
        XCTAssertEqual(month.monthIndex, 0)
        let start = civilDay(month.monthStart)
        XCTAssertEqual([start.y, start.m, start.d], [2026, 4, 14])
        XCTAssertEqual(month.dayOfMonth, 7, "20 April is Chithirai 7")
        XCTAssertNil(month.eraYear, "the Tamil 60-year cycle is deliberately not implemented")
    }

    /// West Bengal Pohela Boishakh 2026: 15 April — the day AFTER the
    /// sankranti, per the Bengal midnight rule. (Bangladesh's reformed
    /// calendar pins 14 April; that is a different construction, disclosed,
    /// not computed.) San 1433 = 2026 - 593.
    func testBengalNewYearIsApril15() throws {
        let kolkata = context(2026, 4, 20, lat: 22.5726, lon: 88.3639)
        let month = try XCTUnwrap(RegionalSolarCalendarEngine.solarMonth(
            context: kolkata, rule: .bengal))
        XCTAssertEqual(month.monthName, "Boishakh")
        let start = civilDay(month.monthStart)
        XCTAssertEqual([start.y, start.m, start.d], [2026, 4, 15])
        XCTAssertEqual(month.eraYear, 1433)
        XCTAssertEqual(month.eraName, "Bengali San")
    }

    /// Kerala: Chingam 1 of Kollam 1202 falls on 17 August 2026 (published
    /// Malayalam calendars).
    func testKollamYear1202BeginsAugust17() throws {
        let kochi = context(2026, 8, 20, lat: 9.9312, lon: 76.2673)
        let month = try XCTUnwrap(RegionalSolarCalendarEngine.solarMonth(
            context: kochi, rule: .malayali))
        XCTAssertEqual(month.monthName, "Chingam")
        XCTAssertEqual(month.monthIndex, 4)
        let start = civilDay(month.monthStart)
        XCTAssertEqual([start.y, start.m, start.d], [2026, 8, 17])
        XCTAssertEqual(month.eraYear, 1202)
        XCTAssertEqual(month.eraName, "Kollam")
    }

    /// Odisha's Pana Sankranti 2026: Baisakha 1 on 14 April — the any-time
    /// rule starts the month on the sunrise-to-sunrise day containing the
    /// sankranti.
    func testOdiaNewYearIsApril14() throws {
        let bhubaneswar = context(2026, 4, 20, lat: 20.2961, lon: 85.8245)
        let month = try XCTUnwrap(RegionalSolarCalendarEngine.solarMonth(
            context: bhubaneswar, rule: .orissa))
        XCTAssertEqual(month.monthName, "Baisakha")
        let start = civilDay(month.monthStart)
        XCTAssertEqual([start.y, start.m, start.d], [2026, 4, 14])
    }

    // MARK: - Rule structure

    /// The four critical moments genuinely differ on the same day: next
    /// sunrise (Orissa), sunset (Tamil), sunrise + 3/5 daylight (Malayali),
    /// and next civil midnight (Bengal) — in strictly increasing order
    /// Malayali < Tamil < Bengal < Orissa for a morning sankranti.
    func testCriticalMomentsAreDistinctAndOrdered() throws {
        let ctx = context(2026, 4, 14)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let sankranti = cal.date(from: DateComponents(year: 2026, month: 4, day: 14, hour: 9))!

        var moments: [RegionalSolarRule: Date] = [:]
        for rule in RegionalSolarRule.allCases {
            moments[rule] = try XCTUnwrap(RegionalSolarCalendarEngine.criticalMoment(
                rule: rule, sankranti: sankranti, context: ctx))
        }
        XCTAssertLessThan(moments[.malayali]!, moments[.tamil]!)
        XCTAssertLessThan(moments[.tamil]!, moments[.bengal]!)
        XCTAssertLessThan(moments[.bengal]!, moments[.orissa]!)

        // Malayali critical is exactly 3/5 into the daylight.
        let solar = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx))
        let expected = solar.sunrise.addingTimeInterval(
            solar.sunset.timeIntervalSince(solar.sunrise) * 3 / 5)
        XCTAssertEqual(moments[.malayali]!.timeIntervalSince(expected), 0, accuracy: 1)
    }

    /// An evening sankranti splits the rules: Tamil and Malayali defer to
    /// the next day while Orissa keeps the same Hindu civil day.
    func testEveningSankrantiSplitsTheRules() throws {
        let ctx = context(2026, 4, 14)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let evening = cal.date(from: DateComponents(year: 2026, month: 4, day: 14, hour: 20))!

        let orissa = try XCTUnwrap(RegionalSolarCalendarEngine.firstDay(
            rule: .orissa, sankranti: evening, context: ctx))
        let tamil = try XCTUnwrap(RegionalSolarCalendarEngine.firstDay(
            rule: .tamil, sankranti: evening, context: ctx))
        XCTAssertEqual(civilDay(orissa.localNoon).d, 14, "any-time rule keeps the day")
        XCTAssertEqual(civilDay(tamil.localNoon).d, 15, "sunset rule defers")
    }

    /// A pre-dawn sankranti belongs to the PREVIOUS Hindu civil day under
    /// the Orissa rule — sunrise-to-sunrise days, not midnight days.
    func testPreDawnSankrantiBelongsToPreviousHinduDay() throws {
        let ctx = context(2026, 4, 14)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let preDawn = cal.date(from: DateComponents(year: 2026, month: 4, day: 14, hour: 3))!
        let first = try XCTUnwrap(RegionalSolarCalendarEngine.firstDay(
            rule: .orissa, sankranti: preDawn, context: ctx))
        XCTAssertEqual(civilDay(first.localNoon).d, 13)

        // Bengal, by contrast, uses the Gregorian midnight day: a 3 a.m.
        // sankranti on the 14th begins the month on the 15th.
        let bengal = try XCTUnwrap(RegionalSolarCalendarEngine.firstDay(
            rule: .bengal, sankranti: preDawn, context: ctx))
        XCTAssertEqual(civilDay(bengal.localNoon).d, 15)
    }

    // MARK: - Disclosed limits

    /// The Bengal boundary zone is apparent midnight +/- 24 temporal
    /// minutes; an instant at apparent midnight is inside, one two hours
    /// later is outside.
    func testBengalBoundaryZoneDetection() throws {
        let ctx = context(2026, 4, 14, lat: 22.5726, lon: 88.3639)
        let today = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx))
        let tomorrow = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx.advancedByLocalDays(1)))
        let night = tomorrow.sunrise.timeIntervalSince(today.sunset)
        let apparentMidnight = today.sunset.addingTimeInterval(night / 2)

        XCTAssertTrue(RegionalSolarCalendarEngine.isInBengalBoundaryZone(
            sankranti: apparentMidnight, context: ctx))
        XCTAssertFalse(RegionalSolarCalendarEngine.isInBengalBoundaryZone(
            sankranti: apparentMidnight.addingTimeInterval(2 * 3_600), context: ctx))
    }

    /// A sankranti within the solver's 60-minute envelope of a critical
    /// moment must carry the uncertainty flag; the 2026 Mesha morning
    /// sankranti is hours from every boundary and must not.
    func testSolverMarginFlag() throws {
        let month = try XCTUnwrap(RegionalSolarCalendarEngine.solarMonth(
            context: context(2026, 4, 20), rule: .tamil))
        XCTAssertFalse(month.isWithinSolverMarginOfBoundary,
                       "the April 2026 sankranti is mid-morning, hours from sunset")
    }

    /// Polar latitudes: no sunrise, no fabricated reckoning.
    func testPolarFailsClosed() {
        let longyearbyen = context(2026, 6, 21, lat: 78.2232, lon: 15.6469, tz: "Arctic/Longyearbyen")
        for rule in RegionalSolarRule.allCases where rule != .bengal {
            XCTAssertNil(RegionalSolarCalendarEngine.solarMonth(context: longyearbyen, rule: rule),
                         "\(rule.rawValue) must fail closed without a sunrise")
        }
    }

    /// Twelve months, twelve names, every rule; and the two verified eras
    /// differ by the documented offsets.
    func testStructuralCompleteness() {
        for rule in RegionalSolarRule.allCases {
            XCTAssertEqual(rule.monthNames.count, 12, rule.rawValue)
            XCTAssertEqual(Set(rule.monthNames).count, 12, "\(rule.rawValue): unique names")
        }
        XCTAssertEqual(RegionalSolarRule.tamil.monthNames[0], "Chithirai")
        XCTAssertEqual(RegionalSolarRule.malayali.monthNames[4], "Chingam")
        XCTAssertEqual(RegionalSolarRule.bengal.monthNames[0], "Boishakh")
        XCTAssertEqual(RegionalSolarRule.orissa.monthNames[0], "Baisakha")
    }
}
