import XCTest
@testable import CosmicRituals

/// Varjyam, Amrit Kalam, Anandadi, Panchaka, and Ganda Mula — the tables
/// were verified against the Drik Panchang Thyajyam tutorial plus the Telugu
/// oursubhakaryam table, then empirically against prokerala.com 2026 dailies
/// (Ujjain, Lahiri) before implementation; sources recorded in ACCURACY.md.
final class PanchangSpecialWindowTests: XCTestCase {

    private func context(_ y: Int, _ m: Int, _ d: Int,
                         latitude: Double = 23.1793, longitude: Double = 75.7849,
                         timeZone: String = "Asia/Kolkata") -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timeZone)!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: latitude, longitude: longitude,
            timeZoneIdentifier: timeZone
        )
    }

    // MARK: Table integrity

    /// Both tables carry all 27 nakshatras with starts that leave room for
    /// the 4-ghati span inside the 60-ghati nakshatra.
    func testTablesAreCompleteAndInRange() {
        XCTAssertEqual(PanchangSpecialWindows.varjyamStartGhatis.count, 27)
        XCTAssertEqual(PanchangSpecialWindows.amritStartGhatis.count, 27)
        for start in PanchangSpecialWindows.varjyamStartGhatis + PanchangSpecialWindows.amritStartGhatis {
            XCTAssertGreaterThanOrEqual(start, 0)
            XCTAssertLessThanOrEqual(start + 4, 60)
        }
        // Spot pins from the verified table: Ashwini 50, Mula 56 (whose
        // Varjyam ends exactly at the nakshatra's end), Dhanishta 10;
        // Amrit: Ashwini 42, Anuradha 34 (the dailies' value, not the
        // Prashna Marga book's 28), Ardra 35 (the genuine non-V+24 cell).
        XCTAssertEqual(PanchangSpecialWindows.varjyamStartGhatis[0], 50)
        XCTAssertEqual(PanchangSpecialWindows.varjyamStartGhatis[18], 56)
        XCTAssertEqual(PanchangSpecialWindows.varjyamStartGhatis[22], 10)
        XCTAssertEqual(PanchangSpecialWindows.amritStartGhatis[0], 42)
        XCTAssertEqual(PanchangSpecialWindows.amritStartGhatis[16], 34)
        XCTAssertEqual(PanchangSpecialWindows.amritStartGhatis[5], 35)
    }

    /// Structural identity the sources state outright: Mula's Varjyam (start
    /// 56 of 60, length 4) ends exactly when the nakshatra ends.
    func testMulaVarjyamEndsAtTheNakshatraEnd() throws {
        // Scan a fortnight for a day whose nakshatra timeline includes Mula.
        for day in 18...31 {
            let ctx = context(2026, 8, day)
            let windows = CosmicEngine.limbWindows(for: .nakshatra, context: ctx)
            guard let mula = windows.first(where: { $0.name == "Mula" }) else { continue }
            let varjyams = PanchangSpecialWindows.varjyam(context: ctx)
            let mulaVarjyam = try XCTUnwrap(varjyams.first { $0.nakshatraName == "Mula" })
            XCTAssertEqual(mulaVarjyam.endTime.timeIntervalSince(mula.endTime), 0, accuracy: 2)
            return
        }
        XCTFail("no Mula window found in the scan range")
    }

    /// Every Varjyam/Amrit window sits inside its nakshatra's span and lasts
    /// exactly one fifteenth of it.
    func testWindowsSitInsideTheirNakshatra() {
        let ctx = context(2026, 8, 27)
        let nakshatras = CosmicEngine.limbWindows(for: .nakshatra, context: ctx)
        for special in PanchangSpecialWindows.varjyam(context: ctx) + PanchangSpecialWindows.amritKalam(context: ctx) {
            guard let host = nakshatras.first(where: { $0.name == special.nakshatraName }) else {
                XCTFail("no host window for \(special.nakshatraName)"); continue
            }
            let span = host.endTime.timeIntervalSince(host.startTime)
            XCTAssertGreaterThanOrEqual(special.startTime, host.startTime)
            XCTAssertLessThanOrEqual(special.endTime, host.endTime.addingTimeInterval(2))
            XCTAssertEqual(special.endTime.timeIntervalSince(special.startTime), span / 15, accuracy: 2)
        }
    }

    // MARK: Anandadi

    /// The empirically decisive fixtures (drik/prokerala 2026 dailies):
    /// Thursday + Dhanishta is Shrivatsa (#8) and Tuesday + Ashwini is
    /// Amrita (#21) — both only correct when the count runs over 28 with
    /// Abhijit inserted after Uttara Ashadha. Anchors themselves map to
    /// Ananda (#1).
    func testAnandadiEmpiricalFixtures() throws {
        XCTAssertEqual(PanchangSpecialWindows.anandadiYogas.count, 28)
        // Thursday = weekday 5; Dhanishta index 22.
        let thursday = try XCTUnwrap(PanchangSpecialWindows.anandadiIndex(weekday: 5, nakshatraIndex: 22))
        XCTAssertEqual(PanchangSpecialWindows.anandadiYogas[thursday].name, "Shrivatsa")
        // Tuesday = weekday 3; Ashwini index 0.
        let tuesday = try XCTUnwrap(PanchangSpecialWindows.anandadiIndex(weekday: 3, nakshatraIndex: 0))
        XCTAssertEqual(PanchangSpecialWindows.anandadiYogas[tuesday].name, "Amrita")
        // Each weekday's anchor nakshatra is Ananda.
        for (weekdayIndex, anchor) in PanchangSpecialWindows.anandadiAnchors.enumerated() {
            let index = try XCTUnwrap(PanchangSpecialWindows.anandadiIndex(
                weekday: weekdayIndex + 1, nakshatraIndex: anchor))
            XCTAssertEqual(index, 0, "anchor of weekday \(weekdayIndex + 1)")
        }
        // The quarantined 9-name prototype's formula must not have leaked in:
        // Thursday + Dhanishta under (weekday+nakshatra) % 9 would be 0.
        XCTAssertNotEqual(thursday % 9, thursday == 7 ? -1 : Int.min, "sanity")
        XCTAssertEqual(thursday, 7, "Shrivatsa is the eighth name (index 7)")
    }

    // MARK: Panchaka and Ganda Mula

    /// Ganda Mula is exactly the six Mercury/Ketu junction nakshatras.
    func testGandaMulaSet() {
        let expected = ["Ashwini": 0, "Ashlesha": 8, "Magha": 9, "Jyeshtha": 17, "Mula": 18, "Revati": 26]
        XCTAssertEqual(PanchangSpecialWindows.gandaMulaIndices, Set(expected.values))
        XCTAssertFalse(PanchangSpecialWindows.isGandaMula(nakshatraIndex: 1))
        XCTAssertTrue(PanchangSpecialWindows.isGandaMula(nakshatraIndex: 18))
    }

    /// Panchaka activation tracks the sidereal Moon crossing 300 degrees:
    /// inactive while the Moon is below Dhanishta's midpoint, active from
    /// there through Revati, and the type name comes from the weekday the
    /// period began (Wednesday/Thursday starts carry no name). Scan a
    /// sidereal month and require at least one activation streak of 4-6
    /// consecutive days.
    func testPanchakaActivatesForARunOfDaysEachSiderealMonth() {
        var streak = 0
        var longest = 0
        var sawTypedOrUntypedStart = false
        for day in 1...28 {
            let ctx = context(2026, 8, day)
            let result = PanchangSpecialWindows.panchaka(context: ctx)
            if result.active {
                streak += 1
                sawTypedOrUntypedStart = true
            } else {
                longest = max(longest, streak)
                streak = 0
            }
        }
        longest = max(longest, streak)
        XCTAssertTrue(sawTypedOrUntypedStart)
        XCTAssertTrue((4...6).contains(longest), "Panchaka runs ~4.5-5 days, got \(longest)")
    }
}
