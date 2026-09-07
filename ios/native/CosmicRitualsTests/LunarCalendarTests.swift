import XCTest
@testable import CosmicRituals

/// The lunisolar construction: sankranti and new-moon solvers, masa
/// classification, Adhika detection, and year anchoring. Structural pins
/// here; published-calendar fixtures are appended beside their sources.
final class LunarCalendarTests: XCTestCase {

    private func context(_ y: Int, _ m: Int, _ d: Int) -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: 28.6139, longitude: 77.2090,
            timeZoneIdentifier: "Asia/Kolkata"
        )
    }

    private func utc(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: 0))!
    }

    /// Twelve successive sankrantis advance the rashi by one each time, sit
    /// 28-32 days apart, and land the sidereal Sun on an exact multiple of
    /// 30 degrees.
    func testSankrantiSolverWalksTheZodiac() {
        var cursor = utc(2026, 1, 1)
        var previousRashi: Int?
        var previousInstant: Date?
        for _ in 0..<12 {
            let (instant, rashi) = LunarCalendarEngine.nextSankranti(after: cursor)
            let sun = LunarCalendarEngine.siderealSunDegrees(at: instant)
            let offToBoundary = abs(sun - Double(rashi) * 30)
            XCTAssertLessThan(min(offToBoundary, 360 - offToBoundary), 1e-4)
            if let previousRashi {
                XCTAssertEqual(rashi, (previousRashi + 1) % 12)
            }
            if let previousInstant {
                let days = instant.timeIntervalSince(previousInstant) / 86_400
                XCTAssertTrue((28...32).contains(Int(days)), "spacing \(days)")
            }
            previousRashi = rashi
            previousInstant = instant
            cursor = instant.addingTimeInterval(60)
        }
    }

    /// Successive new moons sit 29.2-29.9 days apart with elongation zero
    /// at each instant, and previousNewMoon inverts nextNewMoon.
    func testNewMoonSolverIsConsistent() {
        var cursor = utc(2026, 3, 1)
        var previous: Date?
        for _ in 0..<6 {
            let newMoon = LunarCalendarEngine.nextNewMoon(after: cursor)
            let elongation = LunarCalendarEngine.elongationDegrees(at: newMoon)
            XCTAssertLessThan(min(elongation, 360 - elongation), 1e-3)
            if let previous {
                let days = newMoon.timeIntervalSince(previous) / 86_400
                XCTAssertTrue((29.2...29.95).contains(days), "lunation \(days)")
            }
            let recovered = LunarCalendarEngine.previousNewMoon(before: newMoon.addingTimeInterval(86_400))
            XCTAssertEqual(recovered.timeIntervalSince(newMoon), 0, accuracy: 2)
            previous = newMoon
            cursor = newMoon.addingTimeInterval(3_600)
        }
    }

    /// The month info is internally coherent: the lunation brackets the
    /// date, paksha matches the tithi, and the masa index is a real month.
    func testMonthInfoIsCoherent() {
        let ctx = context(2026, 8, 27)
        let info = LunarCalendarEngine.monthInfo(context: ctx)
        let reference = CosmicEngine.panchangReferenceDate(for: ctx)
        XCTAssertLessThan(info.monthStart, reference)
        XCTAssertGreaterThan(info.monthEnd, reference)
        XCTAssertTrue((0..<12).contains(info.amantaMasaIndex))
        let panchang = CosmicEngine.getPanchang(context: ctx)
        XCTAssertEqual(info.pakshaIsShukla, panchang.tithiIndex < 15)
        XCTAssertEqual(info.vikramYear - info.shakaYear, 135, "the two eras differ by a fixed 135 years")
    }

    /// Purnimanta reckoning: during Shukla paksha both reckonings agree;
    /// during Krishna paksha the Purnimanta month carries the next name.
    func testPurnimantaShiftsInKrishnaPaksha() {
        // Scan a lunation for one day of each paksha.
        var sawShukla = false
        var sawKrishna = false
        for day in 1...28 {
            let info = LunarCalendarEngine.monthInfo(context: context(2026, 9, day))
            if info.isAdhika { continue }
            if info.pakshaIsShukla {
                XCTAssertEqual(info.purnimantaMasaName, info.amantaMasaName)
                sawShukla = true
            } else {
                XCTAssertNotEqual(info.purnimantaMasaName, info.amantaMasaName)
                sawKrishna = true
            }
            if sawShukla && sawKrishna { return }
        }
        XCTAssertTrue(sawShukla && sawKrishna)
    }

    // MARK: Published-calendar fixtures

    private func istDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ minute: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: minute))!
    }

    /// Published 2026 sankranti instants. Source: Drik Panchang sankranti
    /// pages (Makar 2026-01-14 15:13 IST, Mesha 2026-04-14 09:39, Karka
    /// 2026-07-16 23:45); Prokerala publishes each ~9-10 minutes earlier
    /// (15:04 / 09:30 / 23:35) -- a stable inter-source divergence recorded
    /// deliberately.
    ///
    /// TOLERANCE IS 60 MINUTES, NOT the app's 12-minute limb envelope, and
    /// that is physics, not a retune: a sankranti is driven by the SUN
    /// alone (~0.04 degrees/hour), so the compact model's ~0.01-degree
    /// solar error amplifies to tens of minutes here, where the Moon-driven
    /// limb boundaries (~0.55 degrees/hour) keep it near a minute. Measured
    /// against Drik: -29 min (Makara), -44 min (Mesha), within 12 (Karka).
    /// The masa/Adhika/year classification is unaffected -- it needs only
    /// WHICH LUNATION the sankranti falls in -- and no sankranti clock time
    /// is displayed in the app. Disclosed in ACCURACY.md.
    func testPublishedSankrantiInstants() {
        let cases: [(Date, Int, Date)] = [
            (utc(2026, 1, 10), 9, istDate(2026, 1, 14, 15, 13)),   // Makara
            (utc(2026, 4, 10), 0, istDate(2026, 4, 14, 9, 39)),    // Mesha
            (utc(2026, 7, 12), 3, istDate(2026, 7, 16, 23, 45)),   // Karka
        ]
        for (from, rashi, published) in cases {
            let (instant, solvedRashi) = LunarCalendarEngine.nextSankranti(after: from)
            XCTAssertEqual(solvedRashi, rashi)
            XCTAssertEqual(instant.timeIntervalSince(published), 0, accuracy: 60 * 60,
                           "rashi \(rashi): solved \(instant) vs published \(published)")
        }
    }

    /// The one Adhika masa of 2025-2028: Adhika Jyeshtha, 2026-05-17 to
    /// 2026-06-15 (AdhikMaas.com, HinduPad series page, Drik Panchang's
    /// Adhika Purnima on 2026-05-31). A date inside it must classify as
    /// Adhika Jyeshtha; a date in the following lunation as ordinary (Nija)
    /// Jyeshtha; and no other 2026 month may read Adhika.
    func testAdhikaJyeshtha2026() {
        let adhika = LunarCalendarEngine.monthInfo(context: context(2026, 5, 25))
        XCTAssertTrue(adhika.isAdhika)
        XCTAssertEqual(adhika.amantaMasaIndex, 2, "Jyeshtha")
        XCTAssertEqual(adhika.amantaMasaName, "Adhika Jyeshtha")

        let nija = LunarCalendarEngine.monthInfo(context: context(2026, 6, 25))
        XCTAssertFalse(nija.isAdhika)
        XCTAssertEqual(nija.amantaMasaIndex, 2)

        for (month, day) in [(1, 20), (3, 25), (8, 5), (10, 10), (12, 20)] {
            XCTAssertFalse(LunarCalendarEngine.monthInfo(context: context(2026, month, day)).isAdhika,
                           "2026-\(month)-\(day) is not adhika")
        }
    }

    /// Published day fixture for 2026-08-27 (Prokerala Ujjain day panchang;
    /// shubhpanchang agrees): Amanta Shravana, Purnimanta Shravana (Shukla
    /// paksha), Vikram Samvat 2083, Shaka 1948. VS 2083 began at Chaitra
    /// Shukla Pratipada on 2026-03-19 (RitiRiwaz); Gujarat's Kartika-anchored
    /// Vikram (still 2082 in August) is a named divergence, not implemented.
    func testPublishedMonthAndYearsForAugust2026() {
        let info = LunarCalendarEngine.monthInfo(context: context(2026, 8, 27))
        XCTAssertEqual(info.amantaMasaIndex, 4, "Shravana")
        XCTAssertFalse(info.isAdhika)
        XCTAssertTrue(info.pakshaIsShukla)
        XCTAssertEqual(info.purnimantaMasaName, "Shravana")
        XCTAssertEqual(info.vikramYear, 2083)
        XCTAssertEqual(info.shakaYear, 1948)
    }

    /// Ayana flips exactly at the Karka and Makara sankrantis of the
    /// sidereal tradition.
    func testAyanaFollowsTheSiderealSun() {
        XCTAssertEqual(LunarCalendarEngine.ayanaName(context: context(2026, 8, 27)), "Dakshinayana")
        XCTAssertEqual(LunarCalendarEngine.ayanaName(context: context(2026, 2, 10)), "Uttarayana")
    }
}
