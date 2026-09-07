import XCTest
@testable import CosmicRituals

/// Festival rules against published 2026 dates. These are the strongest
/// fixtures in the suite in one specific way: a festival date is checkable by
/// anyone with a calendar, so a wrong rule cannot hide behind a plausible
/// number.
final class FestivalRuleTests: XCTestCase {

    private func delhi(_ y: Int, _ m: Int, _ d: Int) -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: 28.6139, longitude: 77.2090, timeZoneIdentifier: "Asia/Kolkata"
        )
    }

    private func day(_ date: Date) -> (m: Int, d: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let c = cal.dateComponents([.month, .day], from: date)
        return (c.month!, c.day!)
    }

    private func occurrence(_ id: String) throws -> VerifiedFestivalOccurrence {
        let rule = try XCTUnwrap(FestivalRuleEngine.rules.first { $0.id == id })
        return try XCTUnwrap(
            FestivalRuleEngine.occurrence(rule: rule, gregorianYear: 2026, context: delhi(2026, 1, 1)),
            "\(id) did not resolve in 2026")
    }

    // MARK: - Published 2026 dates

    /// Maha Shivaratri 2026: 15 February. Krishna Chaturdashi of Amanta
    /// Magha — a nishita observance, so the middle of the night decides.
    func testMahaShivaratri2026() throws {
        XCTAssertEqual(day(try occurrence("maha-shivaratri").day).m, 2)
        XCTAssertEqual(day(try occurrence("maha-shivaratri").day).d, 15)
    }

    /// Rama Navami 2026: 26 March. THE TEST THAT JUSTIFIES THE WHOLE
    /// OBSERVANCE MECHANISM. Navami runs 11:48 on 26 March to 10:06 on
    /// 27 March, so it is still running at sunrise on the 27th: a
    /// sunrise-prevailing rule lands a day late. Madhyahna on the 26th falls
    /// inside the tithi and reproduces the published date.
    func testRamaNavami2026UsesMadhyahnaNotSunrise() throws {
        let found = day(try occurrence("rama-navami").day)
        XCTAssertEqual([found.m, found.d], [3, 26])

        // And the contrast is real: at sunrise on the 27th the tithi is still
        // Navami, which is exactly how a naive rule would go wrong.
        let march27 = delhi(2026, 3, 27)
        let sunrise = try XCTUnwrap(FestivalRuleEngine.observanceInstant(.sunrise, context: march27))
        XCTAssertEqual(
            CosmicEngine.getPanchang(date: sunrise, timezoneIdentifier: "Asia/Kolkata").tithiIndex,
            8, "Navami still runs at sunrise on the 27th")
        let madhyahna = try XCTUnwrap(FestivalRuleEngine.observanceInstant(.madhyahna, context: march27))
        XCTAssertNotEqual(
            CosmicEngine.getPanchang(date: madhyahna, timezoneIdentifier: "Asia/Kolkata").tithiIndex,
            8, "but not at midday — which is what decides the day")
    }

    /// Janmashtami is deliberately NOT shipped, and the reason is recorded
    /// with its measured evidence: Krishna Ashtami touched no nishita instant
    /// at all in 2026. A test pins the absence so it cannot be quietly filled
    /// in with a tuned rule later.
    func testJanmashtamiIsWithheldWithItsReason() {
        XCTAssertNil(FestivalRuleEngine.rules.first { $0.id == "krishna-janmashtami" },
                     "no single-instant rule may ship for Janmashtami")
        let reasons = FestivalRuleEngine.attemptedButUnresolved.joined(separator: " ")
        XCTAssertTrue(reasons.localizedCaseInsensitiveContains("Janmashtami"))
        XCTAssertTrue(reasons.localizedCaseInsensitiveContains("nishita"))
        XCTAssertTrue(reasons.localizedCaseInsensitiveContains("smarta"),
                      "the documented divergence is named, not hidden")
    }

    /// Ganesh Chaturthi 2026: 14 September. Bhadrapada Shukla Chaturthi at
    /// madhyahna.
    func testGaneshChaturthi2026() throws {
        let found = day(try occurrence("ganesh-chaturthi").day)
        XCTAssertEqual([found.m, found.d], [9, 14])
    }

    /// Diwali Lakshmi Puja 2026: 8 November. The Amavasya ending Amanta
    /// Ashwina, at pradosha.
    func testLakshmiPuja2026() throws {
        let found = day(try occurrence("lakshmi-puja").day)
        XCTAssertEqual([found.m, found.d], [11, 8])
    }

    // MARK: - Rule structure

    /// THE AMBIGUITY GUARD. Every Krishna-paksha rule must declare which
    /// naming its month index is given in — that ambiguity is exactly what
    /// made the old prototype's table unusable.
    func testEveryRuleDeclaresItsNamingAndObservance() {
        XCTAssertFalse(FestivalRuleEngine.rules.isEmpty)
        for rule in FestivalRuleEngine.rules {
            XCTAssertTrue((0..<12).contains(rule.masaIndex), rule.id)
            XCTAssertTrue((1...15).contains(rule.tithiInPaksha), rule.id)
            XCTAssertFalse(rule.verifiedAgainst.isEmpty, "\(rule.id) must name the date it was checked against")
            XCTAssertFalse(rule.note.isEmpty, rule.id)
            if rule.paksha == .krishna {
                XCTAssertTrue(rule.note.localizedCaseInsensitiveContains("purnimanta"),
                              "\(rule.id): a Krishna-paksha rule must state both month names")
            }
        }
    }

    /// Tithi indices map correctly into the app's 0-29 convention.
    func testTithiIndexMapping() throws {
        let shivaratri = try XCTUnwrap(FestivalRuleEngine.rules.first { $0.id == "maha-shivaratri" })
        XCTAssertEqual(FestivalRuleEngine.targetTithiIndex(shivaratri), 28, "Krishna Chaturdashi")
        let navami = try XCTUnwrap(FestivalRuleEngine.rules.first { $0.id == "rama-navami" })
        XCTAssertEqual(FestivalRuleEngine.targetTithiIndex(navami), 8, "Shukla Navami")
        let amavasya = try XCTUnwrap(FestivalRuleEngine.rules.first { $0.id == "lakshmi-puja" })
        XCTAssertEqual(FestivalRuleEngine.targetTithiIndex(amavasya), 29, "Amavasya")
    }

    /// The four observance instants are genuinely different moments of the
    /// same day, in the right order.
    func testObservanceInstantsAreOrderedWithinTheDay() throws {
        let ctx = delhi(2026, 3, 27)
        let sunrise = try XCTUnwrap(FestivalRuleEngine.observanceInstant(.sunrise, context: ctx))
        let madhyahna = try XCTUnwrap(FestivalRuleEngine.observanceInstant(.madhyahna, context: ctx))
        let pradosha = try XCTUnwrap(FestivalRuleEngine.observanceInstant(.pradosha, context: ctx))
        let nishita = try XCTUnwrap(FestivalRuleEngine.observanceInstant(.nishita, context: ctx))
        XCTAssertLessThan(sunrise, madhyahna)
        XCTAssertLessThan(madhyahna, pradosha)
        XCTAssertLessThan(pradosha, nishita)

        // Madhyahna is exactly the midpoint of the daylight arc.
        let solar = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx))
        let expected = solar.sunrise.addingTimeInterval(
            solar.sunset.timeIntervalSince(solar.sunrise) / 2)
        XCTAssertEqual(madhyahna.timeIntervalSince(expected), 0, accuracy: 1)
    }

    /// Each festival resolves to exactly one day of 2026 — a rule that
    /// matched a whole paksha would be silently wrong.
    func testEachFestivalResolvesToASingleDay() throws {
        for rule in FestivalRuleEngine.rules {
            let found = try XCTUnwrap(FestivalRuleEngine.occurrence(
                rule: rule, gregorianYear: 2026, context: delhi(2026, 1, 1)), rule.id)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
            // The day before and after must not also match.
            for delta in [-1, 1] {
                let neighbour = CalculationContext(
                    localDay: cal.date(byAdding: .day, value: delta, to: found.day)!,
                    latitude: 28.6139, longitude: 77.2090, timeZoneIdentifier: "Asia/Kolkata")
                XCTAssertFalse(FestivalRuleEngine.matches(rule: rule, context: neighbour),
                               "\(rule.id) also matched the neighbouring day \(delta)")
            }
        }
    }

    /// The whole-year listing returns every verified rule, in date order.
    func testYearListingIsCompleteAndSorted() {
        let all = FestivalRuleEngine.occurrences(gregorianYear: 2026, context: delhi(2026, 1, 1))
        XCTAssertEqual(all.count, FestivalRuleEngine.rules.count)
        XCTAssertEqual(all, all.sorted { $0.day < $1.day })
    }

    /// Polar latitudes: no sunrise, no observance instant, no festival placed.
    func testPolarFailsClosed() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Arctic/Longyearbyen")!
        let ctx = CalculationContext(
            localDay: cal.date(from: DateComponents(year: 2026, month: 6, day: 21, hour: 12))!,
            latitude: 78.2232, longitude: 15.6469, timeZoneIdentifier: "Arctic/Longyearbyen")
        XCTAssertNil(FestivalRuleEngine.observanceInstant(.sunrise, context: ctx))
        XCTAssertTrue(FestivalRuleEngine.festivals(on: ctx).isEmpty)
    }
}
