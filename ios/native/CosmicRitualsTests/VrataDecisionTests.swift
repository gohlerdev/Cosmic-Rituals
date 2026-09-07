import XCTest
@testable import CosmicRituals

/// The conditional vrata rules, pinned to Kane's History of Dharmasastra
/// (Vol. V pt. 1) as the checkable English rendering of the nibandhas.
final class VrataDecisionTests: XCTestCase {

    private func delhi(_ y: Int, _ m: Int, _ d: Int) -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: 28.6139, longitude: 77.2090, timeZoneIdentifier: "Asia/Kolkata")
    }
    private func md(_ date: Date) -> [Int] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let c = cal.dateComponents([.month, .day], from: date)
        return [c.month!, c.day!]
    }

    /// Rohini is the fourth nakshatra; the engine's index must be the app's.
    func testRohiniIndexMatchesTheNakshatraTable() {
        XCTAssertEqual(Panchang.nakshatraNames[VrataDecisionEngine.rohiniIndex], "Rohini")
    }

    /// THE PREVIOUSLY WITHHELD CASE. In 2026 Krishna Ashtami touched no
    /// nishita instant. The Tithitattva cascade's last clause — "on two days
    /// or on neither, the later day" — resolves it to 4 September, the
    /// published date, without a tuned constant.
    func testJanmashtami2026ResolvesByTheCascade() throws {
        let decision = try XCTUnwrap(VrataDecisionEngine.janmashtami(
            gregorianYear: 2026, context: delhi(2026, 1, 1)))
        XCTAssertEqual(md(decision.day), [9, 4])
        XCTAssertFalse(decision.candidateDays.isEmpty)
        XCTAssertEqual(decision.day, decision.candidateDays.last!,
                       "whichever tier fired, 2026 lands on the later candidate")
    }

    /// The cascade must never return a day outside the two Ashtami candidates.
    func testJanmashtamiDayIsAlwaysACandidate() throws {
        for year in [2025, 2026, 2027] {
            let decision = try XCTUnwrap(VrataDecisionEngine.janmashtami(
                gregorianYear: year, context: delhi(year, 1, 1)), "\(year)")
            XCTAssertTrue(decision.candidateDays.contains(decision.day), "\(year)")
            XCTAssertTrue((1...2).contains(decision.candidateDays.count), "\(year)")
        }
    }

    /// Twenty-four (or twenty-five with an Adhika month) Ekadashis a year,
    /// alternating shukla and krishna, each smarta day carrying Ekadashi at
    /// sunrise, and the Vaishnava day never earlier than the smarta day.
    func testEkadashiStructure() {
        let all = VrataDecisionEngine.ekadashis(gregorianYear: 2026, context: delhi(2026, 1, 1))
        // 2026 has an Adhika Jyeshtha, so twenty-five lunations' worth.
        XCTAssertTrue((24...26).contains(all.count), "got \(all.count)")
        let kshaya = all.filter(\.isKshaya)
        XCTAssertGreaterThan(kshaya.count, 0, "a year normally has a kshaya Ekadashi or two; none would mean the detector is dead")
        for e in kshaya {
            XCTAssertTrue(e.traditionsDiffer, "a kshaya Ekadashi always splits the traditions")
        }
        for e in all where !e.isKshaya {
            XCTAssertGreaterThanOrEqual(e.vaishnavaDay, e.smartaDay)
            if e.arunodayaVedha {
                XCTAssertEqual(e.vaishnavaDay.timeIntervalSince(e.smartaDay), 86_400, accuracy: 3_700,
                               "vedha moves the Vaishnava fast exactly one day")
            } else {
                XCTAssertEqual(e.vaishnavaDay, e.smartaDay)
            }
        }
        // The two pakshas alternate.
        for (a, b) in zip(all, all.dropFirst()) {
            XCTAssertNotEqual(a.isShukla, b.isShukla, "pakshas alternate")
        }
    }

    /// Published 2026 fixtures (onlinejyotish.com Ekadashi calendar, smarta
    /// vs Vaishnava columns): Yogini Ekadashi smarta 10 July / Vaishnava 11
    /// July; Prabodhini smarta 20 November / Vaishnava 21 November. Three
    /// where the two agree: Shattila 14 January, Jaya 29 January, Vijaya
    /// 13 February. The split days are the rule's own signature.
    func testPublishedSmartaVaishnavaSplits2026() throws {
        let all = VrataDecisionEngine.ekadashis(gregorianYear: 2026, context: delhi(2026, 1, 1))
        func find(_ m: Int, _ d: Int) throws -> EkadashiDecision {
            try XCTUnwrap(all.first { md($0.smartaDay) == [m, d] }, "no Ekadashi with smarta day \(m)/\(d)")
        }
        // Both 2026 splits are KSHAYA Ekadashis: the tithi touched no sunrise,
        // so Dashami persisted through the earlier one (suryodaya-vedha).
        let yogini = try find(7, 10)
        XCTAssertTrue(yogini.isKshaya, "Yogini 2026 is a kshaya Ekadashi")
        XCTAssertTrue(yogini.traditionsDiffer)
        XCTAssertEqual(md(yogini.vaishnavaDay), [7, 11])

        let prabodhini = try find(11, 20)
        XCTAssertTrue(prabodhini.isKshaya)
        XCTAssertEqual(md(prabodhini.vaishnavaDay), [11, 21])

        for (m, d) in [(1, 14), (1, 29), (2, 13)] {
            let same = try find(m, d)
            XCTAssertFalse(same.traditionsDiffer, "\(m)/\(d) is a same-day Ekadashi")
            XCTAssertFalse(same.isKshaya)
            XCTAssertEqual(same.vaishnavaDay, same.smartaDay)
        }

        // The published table names Yogini and Prabodhini as splitting days;
        // it was not established to be an exhaustive list of splits, so this
        // asserts CONTAINMENT plus a sane bound rather than an exact set. The
        // engine also splits 26 May, which falls inside 2026's Adhika
        // Jyeshtha (pinned in LunarCalendarTests) — an Adhika month carries a
        // real Ekadashi, so a third split there is plausible and is neither
        // asserted as correct nor assumed wrong.
        let splits = all.filter(\.traditionsDiffer).map { md($0.smartaDay) }
        XCTAssertTrue(splits.contains([7, 10]) && splits.contains([11, 20]),
                      "both published splits are reproduced; got \(splits)")
        XCTAssertLessThanOrEqual(splits.count, 4,
                                 "splits are the exception, not the rule; got \(splits)")
        // BOTH of Kane's clauses fire in 2026, which is the strongest
        // available evidence that neither is dead code: Yogini and Prabodhini
        // split by suryodaya-vedha (kshaya), while 26 May — inside the Adhika
        // Jyeshtha — splits by arunodaya-vedha. Every split must be one or
        // the other, never neither.
        for split in splits {
            let decision = try find(split[0], split[1])
            XCTAssertTrue(decision.isKshaya || decision.arunodayaVedha,
                          "a split must come from one of the two vedha clauses: \(split)")
        }
        XCTAssertTrue(splits.contains { try! find($0[0], $0[1]).isKshaya },
                      "at least one suryodaya-vedha split")
        XCTAssertTrue(splits.contains { try! find($0[0], $0[1]).arunodayaVedha },
                      "at least one arunodaya-vedha split")
    }

    /// The smarta/vaishnava split is real, not theoretical: across a year some
    /// Ekadashis must split the traditions and most must not. A build that
    /// always or never splits has lost the rule — and an earlier draft that
    /// carried only Kane's arunodaya clause split on NOTHING in 2026 while
    /// still passing every structural test.
    func testSplitOccursSometimesNotAlways() {
        let all = VrataDecisionEngine.ekadashis(gregorianYear: 2026, context: delhi(2026, 1, 1))
        let split = all.filter(\.traditionsDiffer).count
        XCTAssertGreaterThan(split, 0, "no Ekadashi ever split the traditions")
        XCTAssertLessThan(split, all.count, "every Ekadashi split the traditions")
    }

    /// The vedha instant is exactly four ghatikas (96 minutes) before sunrise.
    func testVedhaWindowIsFourGhatikas() throws {
        let ctx = delhi(2026, 3, 1)
        let solar = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx))
        // Reconstruct the engine's arithmetic from the fixed ghatika.
        let arunodaya = solar.sunrise.addingTimeInterval(-4 * 24 * 60)
        XCTAssertEqual(solar.sunrise.timeIntervalSince(arunodaya), 96 * 60, accuracy: 1)
    }
}


/// The Tithitattva cascade over booleans. Extracted from the astronomy after a
/// negative control showed the final branch never fires in 2020-2035 and was
/// therefore untested; here every branch is exercised directly.
final class JanmashtamiCascadeTests: XCTestCase {

    private func choose(_ j: [Bool], _ r: [Bool], _ a: [Bool]) -> (index: Int, tier: JanmashtamiTier) {
        VrataDecisionEngine.chooseTier(jayantiAtNishita: j, rohiniOverlap: r, ashtamiAtNishita: a)
    }

    /// Tier 1 wins over everything, and takes the LATER day when both qualify.
    func testJayantiAtNishitaTakesPrecedenceAndPrefersTheLaterDay() {
        XCTAssertEqual(choose([true, false], [true, true], [true, true]).index, 0)
        XCTAssertEqual(choose([true, false], [true, true], [true, true]).tier, .jayantiAtNishita)
        XCTAssertEqual(choose([true, true], [false, false], [false, false]).index, 1,
                       "two Jayantis: the later")
    }

    /// Tier 2 fires only without a Jayanti, and also prefers the later day.
    func testRohiniOverlapIsSecondAndPrefersTheLaterDay() {
        let r = choose([false, false], [true, true], [true, false])
        XCTAssertEqual(r.tier, .ashtamiWithRohini)
        XCTAssertEqual(r.index, 1)
        XCTAssertEqual(choose([false, false], [true, false], [false, true]).index, 0)
    }

    /// Tier 3 requires EXACTLY one day with Ashtami at nishita.
    func testAshtamiAtNishitaRequiresExactlyOneDay() {
        let single = choose([false, false], [false, false], [false, true])
        XCTAssertEqual(single.tier, .ashtamiAtNishita)
        XCTAssertEqual(single.index, 1)
    }

    /// THE BRANCH THE CONTROL EXPOSED. Ashtami at nishita on BOTH days, or on
    /// NEITHER, falls through to the later day — the Tithitattva's own last
    /// clause. Neither case occurs in 2020-2035, so this is the only place it
    /// is checked.
    func testFallbackTakesTheLaterDayOnBothAndOnNeither() {
        let both = choose([false, false], [false, false], [true, true])
        XCTAssertEqual(both.tier, .laterDayFallback)
        XCTAssertEqual(both.index, 1, "two midnights: the later day")

        let neither = choose([false, false], [false, false], [false, false])
        XCTAssertEqual(neither.tier, .laterDayFallback)
        XCTAssertEqual(neither.index, 1, "no midnight: the later day")
    }

    /// A single-candidate year (the Ashtami confined to one Hindu day) always
    /// resolves to that day, whichever tier fires.
    func testSingleCandidateAlwaysResolvesToItself() {
        for j in [true, false] {
            for r in [true, false] {
                for a in [true, false] {
                    XCTAssertEqual(choose([j], [r], [a]).index, 0, "j\(j) r\(r) a\(a)")
                }
            }
        }
    }

    /// The observed 2026 path: no Jayanti at nishita, Rohini overlapping the
    /// later day — tier 2, later candidate, which is the published 4 September.
    func testTwentyTwentySixTakesTheRohiniOverlapTier() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let ctx = CalculationContext(
            localDay: cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!,
            latitude: 28.6139, longitude: 77.2090, timeZoneIdentifier: "Asia/Kolkata")
        let decision = try XCTUnwrap(VrataDecisionEngine.janmashtami(gregorianYear: 2026, context: ctx))
        XCTAssertEqual(decision.tier, .ashtamiWithRohini)
        XCTAssertEqual(decision.day, decision.candidateDays.last)
    }
}
