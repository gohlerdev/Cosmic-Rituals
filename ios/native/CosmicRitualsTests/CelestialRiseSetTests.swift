import XCTest
@testable import CosmicRituals

/// The generic Meeus ch. 15 rise/set solver and the Moon latitude series that
/// feeds it. The latitude table was transcribed from two independent
/// open-source transcription lineages agreeing on all 60 rows, then verified
/// end-to-end against Meeus's own worked example before landing.
final class CelestialRiseSetTests: XCTestCase {

    /// Meeus Example 47.a (2nd ed., p. 342): 1992 April 12, 0h TD
    /// (JD 2448724.5) gives the Moon's ecliptic latitude -3.229126 degrees.
    /// The same epoch's longitude fixture lives beside the sun tests.
    func testMeeusExample47aMoonLatitude() {
        XCTAssertEqual(CosmicEngine.moonLatitude(jd: 2_448_724.5), -3.229126, accuracy: 0.000_002)
    }

    /// The generic solver, fed the Sun, must reproduce the production
    /// hour-angle sunrise solver. Two independent formulations (iterated
    /// hour-angle crossing vs single-evaluation equation-of-time) agreeing
    /// within 2 minutes on four continents is the internal control for the
    /// machinery the Moon will use.
    func testGenericSolverReproducesProductionSunriseAcrossContinents() throws {
        let cases: [(name: String, lat: Double, lon: Double, y: Int, m: Int, d: Int)] = [
            ("New Delhi", 28.6139, 77.2090, 2026, 7, 24),
            ("Tokyo", 35.6762, 139.6503, 2026, 7, 24),
            ("Los Angeles", 34.0522, -118.2437, 2026, 7, 24),
            ("New York", 40.7128, -74.0060, 2026, 3, 8),
        ]
        for c in cases {
            let production = try XCTUnwrap(CosmicEngine.sunriseSunsetUTHours(
                year: c.y, month: c.m, day: c.d, latDeg: c.lat, lonDeg: c.lon
            ), c.name)
            let generic = CelestialRiseSet.riseSet(
                utcYear: c.y, month: c.m, day: c.d,
                latDeg: c.lat, lonDeg: c.lon,
                standardAltitudeDeg: -0.8333,
                position: CelestialRiseSet.sunEquatorial
            )
            let rise = try XCTUnwrap(generic.rise, c.name)
            let set = try XCTUnwrap(generic.set, c.name)

            func hourDelta(_ a: Double, _ b: Double) -> Double {
                var d = abs(a - b)
                if d > 12 { d = 24 - d }
                return d
            }
            XCTAssertLessThanOrEqual(hourDelta(rise, production.rise), 2.0 / 60, "\(c.name) rise")
            XCTAssertLessThanOrEqual(hourDelta(set, production.set), 2.0 / 60, "\(c.name) set")
        }
    }

    /// Structural bounds on the Moon's equatorial motion: right ascension
    /// advances roughly 13 degrees per day (11-16 across the anomalistic
    /// cycle), and declination stays inside the maximum possible band
    /// (obliquity + orbital inclination, ~28.6 degrees).
    func testMoonEquatorialMotionStaysInPhysicalBounds() {
        let start = CosmicEngine.julianDate(year: 2026, month: 7, day: 1, decimalHour: 0)
        for offset in 0..<28 {
            let jd = start + Double(offset)
            let today = CelestialRiseSet.moonEquatorial(jd: jd)
            let tomorrow = CelestialRiseSet.moonEquatorial(jd: jd + 1)
            var advance = tomorrow.rightAscensionDeg - today.rightAscensionDeg
            if advance < 0 { advance += 360 }
            XCTAssertGreaterThan(advance, 9, "day \(offset)")
            XCTAssertLessThan(advance, 18, "day \(offset)")
            XCTAssertLessThan(abs(today.declinationDeg), 28.8, "day \(offset)")
        }
    }

    /// External fixtures from the US Naval Observatory rise/set API
    /// (aa.usno.navy.mil/api/rstt/oneday), whose sunrise/sunset for the same
    /// queries exactly reproduce this suite's existing timeanddate and NAOJ
    /// solar fixtures -- a cross-source confirmation of the reference.
    func testUSNOMoonriseFixtures() throws {
        var cal = Calendar(identifier: .gregorian)

        // New Delhi, 2026-07-24 (USNO, tz +5:30): moonrise 15:20,
        // moonset 00:51 -- both inside the same civil day.
        let delhi = CalculationContext(
            localDay: {
                cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
                return cal.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: 12))!
            }(),
            latitude: 28.6139, longitude: 77.2090,
            timeZoneIdentifier: "Asia/Kolkata"
        )
        let delhiEvents = CelestialRiseSet.moonRiseSet(context: delhi)
        let delhiRise = try XCTUnwrap(delhiEvents.moonrise)
        let delhiSet = try XCTUnwrap(delhiEvents.moonset)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let riseParts = cal.dateComponents([.hour, .minute], from: delhiRise)
        XCTAssertLessThanOrEqual(abs((riseParts.hour! * 60 + riseParts.minute!) - (15 * 60 + 20)), 12)
        let setParts = cal.dateComponents([.hour, .minute], from: delhiSet)
        XCTAssertLessThanOrEqual(abs((setParts.hour! * 60 + setParts.minute!) - 51), 12)

        // Tokyo, 2026-07-24 (USNO, tz +9): moonrise 14:52 and NO moonset
        // that civil day -- the classical monthly skip, asserted as a
        // genuine nil rather than smoothed over.
        let tokyo = CalculationContext(
            localDay: {
                cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
                return cal.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: 12))!
            }(),
            latitude: 35.6762, longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo"
        )
        let tokyoEvents = CelestialRiseSet.moonRiseSet(context: tokyo)
        let tokyoRise = try XCTUnwrap(tokyoEvents.moonrise)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let tokyoParts = cal.dateComponents([.hour, .minute], from: tokyoRise)
        XCTAssertLessThanOrEqual(abs((tokyoParts.hour! * 60 + tokyoParts.minute!) - (14 * 60 + 52)), 12)
        XCTAssertNil(tokyoEvents.moonset, "USNO publishes no moonset for Tokyo on this civil day")
    }

    /// Once a sidereal month, moonrise (or moonset) genuinely skips a civil
    /// day. Over a 31-day window at Delhi's latitude the solver must produce
    /// a rise on most days while being allowed the classical skip -- and it
    /// must never produce two rises collapsing onto the same instant.
    func testMoonriseExistsOnMostDaysWithoutDuplicates() {
        var riseCount = 0
        var previous: Double? = nil
        for day in 1...31 {
            let events = CelestialRiseSet.riseSet(
                utcYear: 2026, month: 7, day: day,
                latDeg: 28.6139, lonDeg: 77.2090,
                standardAltitudeDeg: CelestialRiseSet.moonStandardAltitudeDeg,
                position: CelestialRiseSet.moonEquatorial
            )
            if let rise = events.rise {
                riseCount += 1
                if let previous {
                    XCTAssertNotEqual(rise, previous, "day \(day)")
                }
                previous = rise
            }
        }
        XCTAssertGreaterThanOrEqual(riseCount, 28)
    }
}
