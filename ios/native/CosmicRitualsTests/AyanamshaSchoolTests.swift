import XCTest
@testable import CosmicRituals

/// The sidereal schools. Constants are pinned to the Swiss Ephemeris source
/// rows they were read from, and the default is pinned to Lahiri because
/// every published fixture in this suite depends on it.
final class AyanamshaSchoolTests: XCTestCase {

    private func context(_ y: Int, _ m: Int, _ d: Int) -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: 28.6139, longitude: 77.2090, timeZoneIdentifier: "Asia/Kolkata"
        )
    }

    // MARK: - Constants

    /// Offsets are exact differences of the Swiss Ephemeris J1900 rows:
    /// Raman {360 − 338.98556} and KP {360 − 337.636111} against Lahiri's
    /// NOVA anchoring {360 − 337.53953}.
    func testOffsetsMatchTheSwissEphemerisRows() {
        XCTAssertEqual(AyanamshaSchool.lahiri.offsetFromLahiriDegrees, 0)
        XCTAssertEqual(AyanamshaSchool.raman.offsetFromLahiriDegrees, -1.446030, accuracy: 1e-9)
        XCTAssertEqual(AyanamshaSchool.krishnamurti.offsetFromLahiriDegrees, -0.096581, accuracy: 1e-9)

        // Independently published comparisons: Raman about 1.45 degrees below
        // Lahiri, KP about six arcminutes below.
        XCTAssertEqual(AyanamshaSchool.raman.offsetArcminutes, -86.76, accuracy: 0.05)
        XCTAssertEqual(AyanamshaSchool.krishnamurti.offsetArcminutes, -5.79, accuracy: 0.05)
    }

    /// THE VARIANT IDENTIFICATION. The app's Lahiri polynomial run back one
    /// Julian century must land on the NOVA/Hand J1900 value, not the
    /// Calendar Reform Committee one — this is what makes the constant
    /// offsets above legitimate, since all three rows are then the same
    /// epoch and precession family.
    func testAppLahiriIsTheNovaVariant() {
        let atJ1900 = CosmicEngine.lahiriAyanamsha(year: 1900)
        let novaValue = 360 - 337.53953
        XCTAssertEqual(atJ1900, novaValue, accuracy: 1.0 / 3600.0,
                       "agrees with the NOVA anchoring to within an arcsecond")

        // And it is NOT the Calendar Reform Committee variant, which sits
        // measurably elsewhere at its own epoch.
        let crcAtItsEpoch = 23.250182778 - 0.004658035
        let crcYear = 2000.0 + (2435553.5 - CosmicEngine.J2000) / 365.25
        XCTAssertNotEqual(CosmicEngine.lahiriAyanamsha(year: crcYear), crcAtItsEpoch, accuracy: 1e-6)
    }

    /// The default must stay Lahiri: every published fixture in this suite
    /// is a Lahiri fixture, and a changed default would silently reinterpret
    /// all of them.
    func testDefaultRemainsLahiri() {
        XCTAssertEqual(AyanamshaSchool.default, .lahiri)
        let jd = CosmicEngine.julianDateFromDate(Date(timeIntervalSince1970: 1_780_000_000))
        XCTAssertEqual(CosmicEngine.siderealize(100, jd: jd),
                       CosmicEngine.siderealize(100, jd: jd, school: .lahiri),
                       accuracy: 1e-12,
                       "the two-argument entry point is Lahiri by definition")
    }

    // MARK: - Behaviour

    /// A school shifts every sidereal longitude by exactly its offset, at
    /// any epoch — the property that makes it a school rather than a
    /// separate ephemeris.
    func testSchoolShiftsLongitudeByExactlyItsOffset() {
        for year in [1900.0, 1975.0, 2026.0, 2050.0] {
            let jd = CosmicEngine.J2000 + (year - 2000) * 365.25
            let lahiri = CosmicEngine.siderealize(200, jd: jd, school: .lahiri)
            for school in AyanamshaSchool.allCases {
                let value = CosmicEngine.siderealize(200, jd: jd, school: school)
                let delta = CosmicEngine.normalize360(value - lahiri + 180) - 180
                XCTAssertEqual(delta, -school.offsetFromLahiriDegrees, accuracy: 1e-9,
                               "\(school.rawValue) at \(year)")
            }
        }
    }

    /// The ayanamsha still grows with time in every school — the offset is a
    /// constant, not a replacement for precession — and every school grows by
    /// the SAME amount, which is what makes a constant offset legitimate.
    ///
    /// The per-century growth is C1 − C2, not C1: the polynomial is
    /// C0 + C1·t + C2·t² with t in centuries from J2000, so between t = −1
    /// (1900) and t = 0 (2000) the quadratic term contributes −C2.
    /// 1.39688797 − 0.00030706 = 1.39658091.
    func testEverySchoolStillPrecessesAtTheSameRate() {
        let expectedCenturyGrowth = 1.39688797 - 0.00030706
        var rates: [Double] = []
        for school in AyanamshaSchool.allCases {
            let earlier = CosmicEngine.ayanamsha(year: 1900, school: school)
            let later = CosmicEngine.ayanamsha(year: 2000, school: school)
            XCTAssertEqual(later - earlier, expectedCenturyGrowth, accuracy: 1e-9,
                           "\(school.rawValue) precesses at the shared rate")
            rates.append(later - earlier)
        }
        XCTAssertEqual(rates.max()! - rates.min()!, 0, accuracy: 1e-12,
                       "no school may carry its own precession")
    }

    // MARK: - Comparison surface

    /// Three readings, one per school, all resolving to real nakshatras.
    func testComparisonProducesOneReadingPerSchool() {
        let readings = SiderealSchoolComparison.readings(context: context(2026, 8, 27))
        XCTAssertEqual(readings.count, AyanamshaSchool.allCases.count)
        XCTAssertEqual(Set(readings.map(\.school)), Set(AyanamshaSchool.allCases))
        for reading in readings {
            XCTAssertTrue((0..<27).contains(reading.moonNakshatraIndex))
            XCTAssertTrue((1...4).contains(reading.moonPada))
            XCTAssertTrue((0..<360).contains(reading.moonSiderealDegrees))
        }
    }

    /// Raman's 1.45-degree offset is larger than a pada (3°20′ is a pada, so
    /// 1.45° is nearly half of one): across a year of days, the schools must
    /// disagree on the pada on a substantial fraction of them. A build where
    /// the offsets stopped being applied would show zero disagreement.
    func testSchoolsActuallyDivergeAcrossTheYear() {
        var nakshatraDisagreements = 0
        var padaDisagreements = 0
        for day in stride(from: 1, through: 360, by: 7) {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
            let base = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
            let date = cal.date(byAdding: .day, value: day, to: base)!
            let ctx = CalculationContext(
                localDay: date, latitude: 28.6139, longitude: 77.2090,
                timeZoneIdentifier: "Asia/Kolkata")
            if SiderealSchoolComparison.nakshatraDisagrees(context: ctx) { nakshatraDisagreements += 1 }
            if SiderealSchoolComparison.padaDisagrees(context: ctx) { padaDisagreements += 1 }
        }
        XCTAssertGreaterThan(nakshatraDisagreements + padaDisagreements, 3,
                             "the schools must visibly disagree on some days")
    }

    /// Every school states where its constant came from.
    func testEverySchoolCitesItsSource() {
        for school in AyanamshaSchool.allCases {
            XCTAssertTrue(school.citation.contains("sweph.h"), school.rawValue)
            XCTAssertFalse(school.title.isEmpty)
        }
        XCTAssertTrue(AyanamshaSchool.lahiri.citation.localizedCaseInsensitiveContains("different Lahiri"),
                      "the multiple-Lahiri problem is disclosed on the default itself")
    }
}
