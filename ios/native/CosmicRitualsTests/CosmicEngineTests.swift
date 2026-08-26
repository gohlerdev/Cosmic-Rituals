import Foundation
import CoreLocation
import SwiftUI
import UIKit
import XCTest
@testable import CosmicRituals

final class CosmicEngineTests: XCTestCase {
    private static let loadedCatalog = Result { try WorldCityCatalog.load() }

    private struct SolarFixture {
        let name: String
        let latitude: Double
        let longitude: Double
        let timeZone: String
        let year: Int
        let month: Int
        let day: Int
        let expectedSunriseMinute: Int
        let expectedSunsetMinute: Int
        let toleranceMinutes: Int
    }

    /// Independent published civil-time fixtures. Sources are recorded beside the
    /// values so a future ephemeris change cannot simply update implementation and
    /// expectation together.
    private let solarFixtures: [SolarFixture] = [
        // timeanddate.com New Delhi, July 2026: 05:38 / 19:17.
        SolarFixture(name: "New Delhi", latitude: 28.6139, longitude: 77.2090,
                     timeZone: "Asia/Kolkata", year: 2026, month: 7, day: 24,
                     expectedSunriseMinute: 338, expectedSunsetMinute: 1_157, toleranceMinutes: 10),
        // National Astronomical Observatory of Japan: 04:43 / 18:52.
        SolarFixture(name: "Tokyo", latitude: 35.6762, longitude: 139.6503,
                     timeZone: "Asia/Tokyo", year: 2026, month: 7, day: 24,
                     expectedSunriseMinute: 283, expectedSunsetMinute: 1_132, toleranceMinutes: 10),
        // Griffith Observatory 2026 table, America/Los_Angeles with DST.
        SolarFixture(name: "Los Angeles", latitude: 34.0522, longitude: -118.2437,
                     timeZone: "America/Los_Angeles", year: 2026, month: 7, day: 24,
                     expectedSunriseMinute: 358, expectedSunsetMinute: 1_201, toleranceMinutes: 12),
        // timeanddate.com New York, March 2026; DST begins on this civil day.
        SolarFixture(name: "New York DST", latitude: 40.7128, longitude: -74.0060,
                     timeZone: "America/New_York", year: 2026, month: 3, day: 8,
                     expectedSunriseMinute: 438, expectedSunsetMinute: 1_135, toleranceMinutes: 12),
        // gaisma.com Apia, 21 July: 06:51 / 18:16. Apia sits at UTC+13 with a
        // longitude near -172, so its zone offset and solar time disagree by
        // more than a whole day-half; solving its events on the matching UTC
        // calendar day used to land every result on the WRONG local day. This
        // fixture exercises that date-line path, and the same-local-day
        // assertion below is the invariant that was silently violated.
        SolarFixture(name: "Apia date-line", latitude: -13.8506, longitude: -171.7513,
                     timeZone: "Pacific/Apia", year: 2026, month: 7, day: 21,
                     expectedSunriseMinute: 411, expectedSunsetMinute: 1_096, toleranceMinutes: 12),
    ]

    func testPublishedSolarFixturesStayOnSelectedLocalDay() throws {
        for fixture in solarFixtures {
            let context = context(
                fixture.year, fixture.month, fixture.day,
                latitude: fixture.latitude,
                longitude: fixture.longitude,
                timeZone: fixture.timeZone
            )
            let result = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: context), fixture.name)
            let calendar = context.calendar

            XCTAssertTrue(calendar.isDate(result.sunrise, inSameDayAs: context.localDay), fixture.name)
            XCTAssertTrue(calendar.isDate(result.sunset, inSameDayAs: context.localDay), fixture.name)

            let rise = calendar.dateComponents([.hour, .minute], from: result.sunrise)
            let set = calendar.dateComponents([.hour, .minute], from: result.sunset)
            let riseMinute = (rise.hour ?? 0) * 60 + (rise.minute ?? 0)
            let setMinute = (set.hour ?? 0) * 60 + (set.minute ?? 0)
            XCTAssertLessThanOrEqual(abs(riseMinute - fixture.expectedSunriseMinute), fixture.toleranceMinutes, fixture.name)
            XCTAssertLessThanOrEqual(abs(setMinute - fixture.expectedSunsetMinute), fixture.toleranceMinutes, fixture.name)
        }
    }

    func testTokyoNegativeUTCHourMapsToPreviousUTCDateButCorrectLocalDay() throws {
        let context = context(2026, 7, 24, latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo")
        let sunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: context)?.sunrise)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        XCTAssertEqual(utc.component(.day, from: sunrise), 23)
        XCTAssertEqual(context.calendar.component(.day, from: sunrise), 24)
        XCTAssertEqual(context.calendar.component(.hour, from: sunrise), 4)
    }

    func testDSTContextAdvancesByCivilDay() {
        let march7 = context(2026, 3, 7, latitude: 40.7128, longitude: -74.0060, timeZone: "America/New_York")
        let march8 = march7.advancedByLocalDays(1)
        let march9 = march8.advancedByLocalDays(1)

        XCTAssertEqual(march8.localDayComponents.day, 8)
        XCTAssertEqual(march9.localDayComponents.day, 9)
        XCTAssertEqual(march7.timeZone.secondsFromGMT(for: march7.localNoon), -18_000)
        XCTAssertEqual(march8.timeZone.secondsFromGMT(for: march8.localNoon), -14_400)
    }

    func testPolarDayNeverFabricatesSchedules() {
        let svalbard = context(2026, 6, 21, latitude: 78.2232, longitude: 15.6469, timeZone: "Arctic/Longyearbyen")

        XCTAssertNil(CosmicEngine.getSunriseSunset(context: svalbard))
        XCTAssertTrue(CosmicEngine.getMuhurtas(context: svalbard).isEmpty)
        XCTAssertTrue(CosmicEngine.getChoghadiya(context: svalbard).isEmpty)
        XCTAssertTrue(CosmicEngine.getHora(context: svalbard).isEmpty)
        XCTAssertTrue(CosmicEngine.getDurMuhurta(context: svalbard).isEmpty)
        XCTAssertNil(CosmicEngine.getRahuKala(context: svalbard))
        XCTAssertNil(CosmicEngine.getYamaganda(context: svalbard))
        XCTAssertNil(CosmicEngine.getGulikaKala(context: svalbard))
    }

    func testPublishedFridayDurMuhurtaUsesFourthAndNinthDaySegments() throws {
        // Drik Panchang, Mumbai, 2026-07-24: 08:49–09:42 and 13:11–14:03.
        let mumbai = context(2026, 7, 24, latitude: 19.0760, longitude: 72.8777, timeZone: "Asia/Kolkata")
        let periods = CosmicEngine.getDurMuhurta(context: mumbai)
        XCTAssertEqual(periods.count, 2)
        try assertLocalInterval(periods[0], startHour: 8, startMinute: 49, endHour: 9, endMinute: 42,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval(periods[1], startHour: 13, startMinute: 11, endHour: 14, endMinute: 3,
                                context: mumbai, toleranceMinutes: 12)
    }

    func testPublishedFridayRahuYamagandaAndGulikaKalas() throws {
        // Drik Panchang, Mumbai, 2026-07-24: Rahu 11:07–12:45,
        // Yamaganda 16:01–17:39, and Gulika 07:51–09:29.
        let mumbai = context(2026, 7, 24, latitude: 19.0760, longitude: 72.8777, timeZone: "Asia/Kolkata")
        let rahu = try XCTUnwrap(CosmicEngine.getRahuKala(context: mumbai))
        let yamaganda = try XCTUnwrap(CosmicEngine.getYamaganda(context: mumbai))
        let gulika = try XCTUnwrap(CosmicEngine.getGulikaKala(context: mumbai))

        try assertLocalInterval(
            (start: rahu.start, end: rahu.end, label: "Rahu Kala"),
            startHour: 11, startMinute: 7, endHour: 12, endMinute: 45,
            context: mumbai, toleranceMinutes: 12
        )
        try assertLocalInterval(
            (start: yamaganda.start, end: yamaganda.end, label: "Yamaganda"),
            startHour: 16, startMinute: 1, endHour: 17, endMinute: 39,
            context: mumbai, toleranceMinutes: 12
        )
        try assertLocalInterval(
            (start: gulika.start, end: gulika.end, label: "Gulika Kala"),
            startHour: 7, startMinute: 51, endHour: 9, endMinute: 29,
            context: mumbai, toleranceMinutes: 12
        )
    }

    func testPublishedTuesdayDurMuhurtaIncludesNightPeriod() throws {
        // Drik Panchang, Hyderabad, 2026-06-23: 08:21–09:14 and 23:14–23:57.
        let hyderabad = context(2026, 6, 23, latitude: 17.3850, longitude: 78.4867, timeZone: "Asia/Kolkata")
        let periods = CosmicEngine.getDurMuhurta(context: hyderabad)
        XCTAssertEqual(periods.count, 2)
        try assertLocalInterval(periods[0], startHour: 8, startMinute: 21, endHour: 9, endMinute: 14,
                                context: hyderabad, toleranceMinutes: 12)
        try assertLocalInterval(periods[1], startHour: 23, startMinute: 14, endHour: 23, endMinute: 57,
                                context: hyderabad, toleranceMinutes: 12)
    }

    func testPublishedFridayAbhijitScalesWithTheLocalDay() throws {
        // Drik Panchang, Mumbai, 2026-07-24: 12:19–13:11.
        let mumbai = context(2026, 7, 24, latitude: 19.0760, longitude: 72.8777, timeZone: "Asia/Kolkata")
        let period = try XCTUnwrap(CosmicEngine.getAbhijitMuhurta(context: mumbai))
        try assertLocalInterval(
            (start: period.start, end: period.end, label: "Abhijit"),
            startHour: 12, startMinute: 19, endHour: 13, endMinute: 11,
            context: mumbai, toleranceMinutes: 12
        )
    }

    func testPublishedFridayChoghadiyaSequenceAndTimes() throws {
        // Drik Panchang, Mumbai, 2026-07-24 (sunrise 06:12, sunset 19:17):
        // day Chara/Labha/Amrita/Kala/Shubha/Roga/Udvega/Chara,
        // night Roga/Kala/Labha/Udvega/Shubha/Amrita/Chara/Roga.
        let mumbai = context(2026, 7, 24, latitude: 19.0760, longitude: 72.8777, timeZone: "Asia/Kolkata")
        let periods = CosmicEngine.getChoghadiya(context: mumbai)
        XCTAssertEqual(periods.count, 16)
        XCTAssertEqual(periods.map(\.quality.rawValue), [
            "Char", "Labh", "Amrit", "Kaal", "Shubh", "Rog", "Udveg", "Char",
            "Rog", "Kaal", "Labh", "Udveg", "Shubh", "Amrit", "Char", "Rog",
        ])

        try assertLocalInterval((start: periods[0].startTime, end: periods[0].endTime, label: "day 1"),
                                startHour: 6, startMinute: 12, endHour: 7, endMinute: 51,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: periods[3].startTime, end: periods[3].endTime, label: "day 4"),
                                startHour: 11, startMinute: 7, endHour: 12, endMinute: 45,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: periods[7].startTime, end: periods[7].endTime, label: "day 8"),
                                startHour: 17, startMinute: 39, endHour: 19, endMinute: 17,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: periods[8].startTime, end: periods[8].endTime, label: "night 1"),
                                startHour: 19, startMinute: 17, endHour: 20, endMinute: 39,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: periods[10].startTime, end: periods[10].endTime, label: "night 3"),
                                startHour: 22, startMinute: 1, endHour: 23, endMinute: 23,
                                context: mumbai, toleranceMinutes: 12)
    }

    func testPublishedFridayHoraSequenceAndTimes() throws {
        // Drik Panchang, Mumbai, 2026-07-24 (sunrise 06:12, sunset 19:17):
        // Chaldean day sequence starting from Friday's lord (Venus).
        let mumbai = context(2026, 7, 24, latitude: 19.0760, longitude: 72.8777, timeZone: "Asia/Kolkata")
        let horas = CosmicEngine.getHora(context: mumbai)
        XCTAssertEqual(horas.count, 24)
        XCTAssertEqual(horas.map(\.planet), [
            .venus, .mercury, .moon, .saturn, .jupiter, .mars, .sun, .venus, .mercury, .moon, .saturn, .jupiter,
            .mars, .sun, .venus, .mercury, .moon, .saturn, .jupiter, .mars, .sun, .venus, .mercury, .moon,
        ])

        try assertLocalInterval((start: horas[0].startTime, end: horas[0].endTime, label: "day hora 1"),
                                startHour: 6, startMinute: 12, endHour: 7, endMinute: 18,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: horas[11].startTime, end: horas[11].endTime, label: "day hora 12"),
                                startHour: 18, startMinute: 12, endHour: 19, endMinute: 17,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: horas[12].startTime, end: horas[12].endTime, label: "night hora 1"),
                                startHour: 19, startMinute: 17, endHour: 20, endMinute: 12,
                                context: mumbai, toleranceMinutes: 12)
        try assertLocalInterval((start: horas[16].startTime, end: horas[16].endTime, label: "night hora 5"),
                                startHour: 22, startMinute: 56, endHour: 23, endMinute: 50,
                                context: mumbai, toleranceMinutes: 12)
    }

    func testAbhijitIsNotPresentedAsAuspiciousOnWednesday() {
        let bartlesville = context(
            2026, 7, 22,
            latitude: 36.7473,
            longitude: -95.9808,
            timeZone: "America/Chicago"
        )
        XCTAssertNil(CosmicEngine.getAbhijitMuhurta(context: bartlesville))
    }

    func testKaranaSequenceHasOneOpeningFixedKaranaAndThreeClosingFixedKaranas() {
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 0), 10)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 1), 0)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 2), 1)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 7), 6)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 8), 0)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 56), 6)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 57), 7)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 58), 8)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 59), 9)
    }

    func testLahiriAyanamshaMatchesSwissEphemerisReference() {
        // Swiss Ephemeris: 2020-01-01 12:00 TT = 24°08′11.3962″.
        let expected = 24.0 + 8.0 / 60.0 + 11.3962 / 3_600.0
        XCTAssertEqual(CosmicEngine.lahiriAyanamsha(year: 2020), expected, accuracy: 0.0001)

        // Second anchor, 120 years earlier, so the polynomial's RANGE is
        // fenced rather than one epoch: the canonical Lahiri value at J1900
        // is 22°27′37.69″ (Indian Ephemeris and Nautical Almanac 1965, the
        // constant Swiss Ephemeris itself carries). 0.001° tolerance covers
        // the compact polynomial's ~1.3″ deviation at this distance.
        let j1900 = 22.0 + 27.0 / 60.0 + 37.69 / 3_600.0
        XCTAssertEqual(CosmicEngine.lahiriAyanamsha(year: 1900), j1900, accuracy: 0.001)
    }

    /// Reykjavik (64.1°N) at the June solstice: the day is selected-civil-day
    /// anchored, but the SUN genuinely sets after local midnight. Published
    /// times (gaisma.com, June solstice, UTC+0 year-round): sunrise 02:55,
    /// sunset 00:04 on the NEXT calendar day. The engine must keep sunrise on
    /// the selected day, let sunset land on the next civil day rather than
    /// clamping or failing, and still divide the 30 muhurtas.
    func testReykjavikSolsticeSunsetCrossesLocalMidnight() throws {
        let reykjavik = context(2026, 6, 21, latitude: 64.1466, longitude: -21.9426, timeZone: "Atlantic/Reykjavik")
        let solar = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: reykjavik))
        let calendar = reykjavik.calendar

        XCTAssertTrue(calendar.isDate(solar.sunrise, inSameDayAs: reykjavik.localNoon))
        XCTAssertGreaterThan(solar.sunset, solar.sunrise)

        let rise = calendar.dateComponents([.hour, .minute], from: solar.sunrise)
        let riseMinute = (rise.hour ?? 0) * 60 + (rise.minute ?? 0)
        XCTAssertLessThanOrEqual(abs(riseMinute - (2 * 60 + 55)), 12, "published sunrise 02:55")

        let set = calendar.dateComponents([.day, .hour, .minute], from: solar.sunset)
        XCTAssertEqual(set.day, 22, "the sun sets after midnight, on the next civil day")
        let setMinute = (set.hour ?? 0) * 60 + (set.minute ?? 0)
        XCTAssertLessThanOrEqual(abs(setMinute - 4), 12, "published sunset 00:04 next day")

        XCTAssertEqual(CosmicEngine.getMuhurtas(context: reykjavik).count, 30)
    }

    func testMeeusChapter47MoonLongitudeFixture() {
        // Meeus example 47.a, 1992-04-12 0h TD. The book publishes BOTH the
        // mean longitude (133.162655°) and, after adding nutation, the
        // apparent longitude 133.167265°. The engine now returns apparent of
        // date (mean + leading-term nutation, the same -0.00478° sin Ω the
        // Sun's apparent longitude carries), so the fixture pins the book's
        // apparent value. Tolerance 0.0005° (~1.8″) covers the difference
        // between full nutation (16.595″ here) and the single leading term.
        XCTAssertEqual(CosmicEngine.moonLongitude(jd: 2_448_724.5), 133.167265, accuracy: 0.000_5)
    }

    func testNakshatraAndPadaBoundariesDoNotDrift() {
        let nakshatraSpan = 360.0 / 27.0
        let padaSpan = 360.0 / 108.0
        let epsilon = 0.000_001

        XCTAssertEqual(CosmicEngine.getNakshatraPada(360 - epsilon).nakshatraIndex, 26)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(nakshatraSpan - epsilon).nakshatraIndex, 0)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(nakshatraSpan + epsilon).nakshatraIndex, 1)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(padaSpan - epsilon).pada, 1)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(padaSpan + epsilon).pada, 2)
    }

    func testLocalContextProducesThirtyOrderedMuhurtas() throws {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let muhurtas = CosmicEngine.getMuhurtas(context: delhi)
        XCTAssertEqual(muhurtas.count, 30)
        XCTAssertTrue(zip(muhurtas, muhurtas.dropFirst()).allSatisfy {
            abs($0.endTime.timeIntervalSince($1.startTime)) < 0.001
        })
        let sunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: delhi)?.sunrise)
        XCTAssertEqual(muhurtas.first?.startTime, sunrise)
    }

    func testPanchangUsesContextWeekday() {
        let tokyo = context(2026, 7, 24, latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo")
        XCTAssertEqual(CosmicEngine.getPanchang(context: tokyo).weekdayName, "Friday")
    }

    func testDailyPanchangUsesLocalSunriseAndCarriesSolarTimes() throws {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let solar = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: delhi))
        let panchang = CosmicEngine.getPanchang(context: delhi)

        XCTAssertEqual(panchang.date.timeIntervalSince(solar.sunrise), 0, accuracy: 0.001)
        XCTAssertEqual(panchang.sunriseTime, solar.sunrise)
        XCTAssertEqual(panchang.sunsetTime, solar.sunset)
        XCTAssertTrue(panchang.referenceDisclosure(in: delhi.timeZone).localizedCaseInsensitiveContains("sunrise"))
    }

    func testPublishedParisPanchangTransitionsStayWithinCivilTimeTolerance() throws {
        // Independent reference: Drik Panchang for Paris, 2026-07-21.
        // https://www.drikpanchang.com/ — published values: sunrise 06:10,
        // Ashtami until 01:46 Jul 22, Chitra until 17:19, Siddha until 14:55,
        // and Vishti until 13:04. We allow 12 minutes because the app's compact
        // offline ephemeris intentionally omits the larger JPL/Swiss data files.
        let paris = context(2026, 7, 21, latitude: 48.8566, longitude: 2.3522, timeZone: "Europe/Paris")
        let panchang = CosmicEngine.getPanchang(context: paris)

        XCTAssertEqual(panchang.tithiName, "Ashtami")
        XCTAssertEqual(panchang.nakshatraName, "Chitra")
        XCTAssertEqual(panchang.yogaName, "Siddha")
        XCTAssertEqual(panchang.karanaName, "Vishti")

        try assertLocalTransition(
            panchang.transitions.tithi,
            current: "Ashtami", next: "Navami",
            year: 2026, month: 7, day: 22, hour: 1, minute: 46,
            context: paris, toleranceMinutes: 12
        )
        try assertLocalTransition(
            panchang.transitions.nakshatra,
            current: "Chitra", next: "Swati",
            year: 2026, month: 7, day: 21, hour: 17, minute: 19,
            context: paris, toleranceMinutes: 12
        )
        try assertLocalTransition(
            panchang.transitions.yoga,
            current: "Siddha", next: "Sadhya",
            year: 2026, month: 7, day: 21, hour: 14, minute: 55,
            context: paris, toleranceMinutes: 12
        )
        try assertLocalTransition(
            panchang.transitions.karana,
            current: "Vishti", next: "Bava",
            year: 2026, month: 7, day: 21, hour: 13, minute: 4,
            context: paris, toleranceMinutes: 12
        )
    }

    func testEverySolvedLimbBoundaryChangesToItsDeclaredNextValue() throws {
        let contexts = [
            context(2026, 1, 15, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata"),
            context(2026, 4, 9, latitude: -33.8688, longitude: 151.2093, timeZone: "Australia/Sydney"),
            context(2026, 7, 21, latitude: 48.8566, longitude: 2.3522, timeZone: "Europe/Paris"),
            context(2026, 11, 3, latitude: 37.4323, longitude: -121.8996, timeZone: "America/Los_Angeles"),
        ]

        for calculationContext in contexts {
            let daily = CosmicEngine.getPanchang(context: calculationContext)
            XCTAssertEqual(daily.transitions.chronological.count, PanchangLimbKind.allCases.count)

            for transition in daily.transitions.chronological {
                let before = CosmicEngine.getPanchang(
                    date: transition.endTime.addingTimeInterval(-60),
                    timezoneIdentifier: calculationContext.timeZoneIdentifier
                )
                let after = CosmicEngine.getPanchang(
                    date: transition.endTime.addingTimeInterval(60),
                    timezoneIdentifier: calculationContext.timeZoneIdentifier
                )
                XCTAssertEqual(
                    limbName(transition.kind, in: before),
                    transition.currentName,
                    "\(calculationContext.timeZoneIdentifier) \(transition.kind.rawValue) before boundary"
                )
                XCTAssertEqual(
                    limbName(transition.kind, in: after),
                    transition.nextName,
                    "\(calculationContext.timeZoneIdentifier) \(transition.kind.rawValue) after boundary"
                )
            }
        }
    }

    func testPolarFallbackIsExplicitAndDoesNotInventSunrise() {
        let svalbard = context(2026, 6, 21, latitude: 78.2232, longitude: 15.6469, timeZone: "Arctic/Longyearbyen")
        let panchang = CosmicEngine.getPanchang(context: svalbard)

        XCTAssertNil(panchang.sunriseTime)
        XCTAssertNil(panchang.sunsetTime)
        XCTAssertEqual(
            svalbard.calendar.component(.hour, from: panchang.date),
            CalculationContext.polarFallbackReferenceHour
        )
        XCTAssertTrue(panchang.referenceDisclosure(in: svalbard.timeZone).localizedCaseInsensitiveContains("unavailable"))
    }

    func testMonthCellSnapshotSkipsDetailedBoundaryWork() {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let compact = CosmicEngine.getPanchang(context: delhi, includeTransitions: false)

        XCTAssertTrue(compact.transitions.chronological.isEmpty)
        XCTAssertNotNil(compact.sunriseTime)
    }

    func testNextDayTransitionLabelIncludesCivilDateAndSameDayLabelDoesNot() throws {
        let paris = context(2026, 7, 21, latitude: 48.8566, longitude: 2.3522, timeZone: "Europe/Paris")
        let panchang = CosmicEngine.getPanchang(context: paris)
        let tithi = try XCTUnwrap(panchang.transitions.tithi)
        let nakshatra = try XCTUnwrap(panchang.transitions.nakshatra)
        let locale = Locale(identifier: "en_US_POSIX")

        let nextDay = tithi.endTime.ritualTransitionLabel(
            relativeTo: panchang.date,
            in: paris.timeZone,
            locale: locale
        )
        let sameDay = nakshatra.endTime.ritualTransitionLabel(
            relativeTo: panchang.date,
            in: paris.timeZone,
            locale: locale
        )

        XCTAssertTrue(nextDay.contains("22"))
        XCTAssertTrue(nextDay.contains("Jul"))
        XCTAssertFalse(sameDay.contains("Jul"))
    }

    func testPanchangPDFExporterProducesAValidNonEmptyPDF() {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let pdf = PanchangPDFExporter.generatePDF(context: delhi)

        XCTAssertTrue(pdf.starts(with: Data("%PDF".utf8)))
        XCTAssertGreaterThan(pdf.count, 5_000)

        let renderedArtifact = XCTAttachment(data: pdf, uniformTypeIdentifier: "com.adobe.pdf")
        renderedArtifact.name = "Cosmic-Rituals-Panchang-QA"
        renderedArtifact.lifetime = .keepAlways
        add(renderedArtifact)
    }

    func testCompleteOfflineCatalogCountAndGlobalSearch() throws {
        let cities = try Self.loadedCatalog.get()
        XCTAssertEqual(cities.count, WorldCityCatalog.expectedCatalogCount)

        let expectations = [
            "Reykjavik": "Reykjavik, Iceland",
            "Reykjavík": "Reykjavik, Iceland",
            "Sao": "Sao Paulo, Brazil",
            "São": "Sao Paulo, Brazil",
            "Tokyo": "Tokyo, Japan",
            "Nairobi": "Nairobi, Kenya",
        ]
        for (query, expectedFirst) in expectations {
            XCTAssertEqual(
                WorldCityCatalog.search(query, in: cities).first?.name,
                expectedFirst,
                query
            )
        }
    }

    func testOfflineCatalogSearchRanksPrefixesAndCapsResults() throws {
        let sample = [
            RitualLocation(name: "Port Tokyo, Test", latitude: 0, longitude: 0, timeZoneIdentifier: "Etc/UTC", source: .manual),
            RitualLocation(name: "Oldtokyo, Test", latitude: 0, longitude: 0, timeZoneIdentifier: "Etc/UTC", source: .manual),
            RitualLocation(name: "Tokyo, Japan", latitude: 0, longitude: 0, timeZoneIdentifier: "Asia/Tokyo", source: .manual),
        ]
        XCTAssertEqual(
            WorldCityCatalog.search("tokyo", in: sample).map(\.name),
            ["Tokyo, Japan", "Port Tokyo, Test", "Oldtokyo, Test"]
        )

        let cities = try Self.loadedCatalog.get()
        let capped = WorldCityCatalog.search("san", in: cities)
        XCTAssertEqual(capped.count, WorldCityCatalog.resultLimit)
    }

    func testLocationStoreRoundTripsExplicitSource() throws {
        let suiteName = "CosmicRitualsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let tokyo = try XCTUnwrap(WorldCityCatalog.popularCities.first { $0.name == "Tokyo, Japan" })

        RitualLocationStore.save(tokyo, defaults: defaults)
        XCTAssertEqual(RitualLocationStore.load(defaults: defaults), tokyo)
    }

    func testAppIntentRequiresPersistedLocationInsteadOfDefaultingToDelhi() throws {
        let suiteName = "CosmicRitualsTests.Intent.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(IntentCalculationContext.resolve(for: Date(), defaults: defaults))

        let tokyo = try XCTUnwrap(WorldCityCatalog.popularCities.first { $0.name == "Tokyo, Japan" })
        RitualLocationStore.save(tokyo, defaults: defaults)
        let resolved = try XCTUnwrap(IntentCalculationContext.resolve(for: Date(), defaults: defaults))
        XCTAssertEqual(resolved.1, tokyo)
        XCTAssertEqual(resolved.0.timeZoneIdentifier, "Asia/Tokyo")
    }

    func testPersistedGPSCoordinateIsDowngradedUntilFreshFix() {
        let current = RitualLocation(
            name: "Current Location",
            latitude: 64.1355,
            longitude: -21.8954,
            timeZoneIdentifier: "Atlantic/Reykjavik",
            source: .current
        )
        let saved = current.asSavedCurrent()
        XCTAssertEqual(saved.source, .savedCurrent)
        XCTAssertEqual(saved.name, "Last Known Location")
        XCTAssertEqual(saved.latitude, current.latitude)
        XCTAssertEqual(saved.longitude, current.longitude)
    }

    func testGPSFixValidatorAcceptsFreshAuthorizedAccurateCoordinate() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedWhenInUse,
            coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            timestamp: now.addingTimeInterval(-30),
            horizontalAccuracy: 850,
            now: now
        ))
    }

    func testGPSFixValidatorRejectsRevokedAuthorization() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .denied,
            coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            timestamp: now,
            horizontalAccuracy: 50,
            now: now
        ))
    }

    func testGPSFixValidatorRejectsStaleAndFutureTimestamps() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let coordinate = CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)

        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedAlways,
            coordinate: coordinate,
            timestamp: now.addingTimeInterval(-(RitualGPSFixValidator.maximumAge + 1)),
            horizontalAccuracy: 50,
            now: now
        ))
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedAlways,
            coordinate: coordinate,
            timestamp: now.addingTimeInterval(RitualGPSFixValidator.maximumFutureClockSkew + 1),
            horizontalAccuracy: 50,
            now: now
        ))
    }

    func testGPSFixValidatorRejectsInvalidCoordinateAndAccuracy() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedWhenInUse,
            coordinate: CLLocationCoordinate2D(latitude: .nan, longitude: 77.2090),
            timestamp: now,
            horizontalAccuracy: 50,
            now: now
        ))
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedWhenInUse,
            coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            timestamp: now,
            horizontalAccuracy: RitualGPSFixValidator.maximumHorizontalAccuracy + 1,
            now: now
        ))
    }

    func testDailySnapshotNamingMatchesSunriseReferenceSemantics() throws {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let panchang = CosmicEngine.getPanchang(context: delhi)
        let sunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: delhi)?.sunrise)
        XCTAssertEqual(panchang.date.timeIntervalSince(sunrise), 0, accuracy: 0.001)
        XCTAssertEqual(RitualExperienceMode.ritualNow.displayName, "Daily Snapshot")
        XCTAssertTrue(RitualExperienceMode.ritualNow.summary.localizedCaseInsensitiveContains("sunrise"))
        XCTAssertTrue(panchang.referenceDisclosure(in: delhi.timeZone).localizedCaseInsensitiveContains("sunrise"))
    }

    func testAccessibilityLargeDestinationLayoutUsesIconsWithoutLosingLabels() {
        XCTAssertFalse(RitualResponsiveLayout.usesIconOnlyDestinations(for: .large))
        XCTAssertTrue(RitualResponsiveLayout.usesIconOnlyDestinations(for: .accessibility2))

        let titles = RitualDestinationDescriptor.all.map(\.title)
        XCTAssertEqual(titles, ["Panchang", "Timing", "Muhurtas", "Pooja", "Calendar"])
        XCTAssertEqual(Set(titles).count, 5)
        XCTAssertTrue(RitualDestinationDescriptor.all.allSatisfy { !$0.symbol.isEmpty })
    }

    func testPoojaVidhiCatalogIsStructuredCompleteAndTraceable() {
        XCTAssertGreaterThanOrEqual(PoojaVidhiCatalog.all.count, 12)
        XCTAssertEqual(PoojaVidhiCatalog.validationIssues, [])

        for vidhi in PoojaVidhiCatalog.all {
            XCTAssertFalse(vidhi.summary.isEmpty, vidhi.id)
            XCTAssertFalse(vidhi.traditionNote.isEmpty, vidhi.id)
            XCTAssertFalse(vidhi.sourceNotes.isEmpty, vidhi.id)
            XCTAssertTrue(vidhi.sourceNotes.allSatisfy { $0.urlString.hasPrefix("https://") }, vidhi.id)
            XCTAssertGreaterThanOrEqual(vidhi.durationMinutes.lowerBound, 5, vidhi.id)
            XCTAssertLessThanOrEqual(vidhi.durationMinutes.lowerBound, vidhi.durationMinutes.upperBound, vidhi.id)
        }
    }

    func testSimpleHouseholdPoojasIncludeUnderstandablePublicMantras() {
        let householdVidhis = PoojaVidhiCatalog.all.filter { $0.practiceLevel == .simpleHousehold }
        XCTAssertFalse(householdVidhis.isEmpty)

        for vidhi in householdVidhis {
            let mantras = vidhi.steps.compactMap(\.mantra)
            XCTAssertFalse(mantras.isEmpty, vidhi.id)
            XCTAssertTrue(mantras.allSatisfy {
                !$0.devanagari.isEmpty && !$0.transliteration.isEmpty && !$0.meaning.isEmpty
            }, vidhi.id)
        }
    }

    func testPoojaReadinessCountsRequiredAndOptionalMaterialsSeparately() throws {
        let vidhi = try XCTUnwrap(PoojaVidhiCatalog.all.first { $0.id == "griha-pravesh" })
        let requiredIDs = Set(vidhi.materials.filter(\.isRequired).map(\.id))
        let optionalIDs = Set(vidhi.materials.filter { !$0.isRequired }.map(\.id))

        let initial = vidhi.readiness(preparedMaterialIDs: [])
        XCTAssertEqual(initial.requiredMaterialCount, requiredIDs.count)
        XCTAssertEqual(initial.optionalMaterialCount, optionalIDs.count)
        XCTAssertEqual(initial.requiredPreparationProgress, 0)
        XCTAssertFalse(initial.hasPreparedRequiredMaterials)
        XCTAssertEqual(initial.sourceCount, vidhi.sourceNotes.count)
        XCTAssertEqual(initial.practiceStatus, "Qualified practitioner recommended")
        XCTAssertTrue(initial.materialStatus.contains("\(requiredIDs.count) required"))
        XCTAssertTrue(initial.sourceStatus.contains("\(vidhi.sourceNotes.count) cited"))

        let prepared = vidhi.readiness(preparedMaterialIDs: requiredIDs.union(optionalIDs.prefix(1)))
        XCTAssertEqual(prepared.preparedRequiredMaterialCount, requiredIDs.count)
        XCTAssertEqual(prepared.preparedOptionalMaterialCount, min(1, optionalIDs.count))
        XCTAssertEqual(prepared.requiredPreparationProgress, 1)
        XCTAssertTrue(prepared.hasPreparedRequiredMaterials)
        XCTAssertEqual(prepared.remainingRequiredMaterialCount, 0)
        let expectedMaterialStatus = requiredIDs.count == 1
            ? "Required material marked ready"
            : "All \(requiredIDs.count) required materials marked ready"
        XCTAssertEqual(prepared.materialStatus, expectedMaterialStatus)
    }

    func testPoojaSearchCoversPanditGPTPublicStarterPillars() {
        XCTAssertEqual(PoojaVidhiCatalog.search("Lakshmi at home").first?.id, "lakshmi-home")
        XCTAssertEqual(PoojaVidhiCatalog.search("Griha Pravesh").first?.id, "griha-pravesh")
        XCTAssertTrue(PoojaVidhiCatalog.search("Navratri").contains { $0.id == "durga-navratri-home" })
        XCTAssertTrue(PoojaVidhiCatalog.search("mantra meaning").allSatisfy {
            $0.steps.contains { $0.mantra != nil }
        })
        XCTAssertTrue(PoojaVidhiCatalog.search("planetary", category: .planetary).allSatisfy {
            $0.category == .planetary
        })
    }

    func testRitualDayContextStatesFactsWithoutInventingAnObservance() {
        let context = RitualDayContext(
            civilDate: "Friday, 21 August 2026",
            locationName: "New Delhi, India",
            timeZoneIdentifier: "Asia/Kolkata",
            tithiName: "Navami",
            nakshatraName: "Anuradha",
            sunriseTime: "5:53 AM"
        )
        XCTAssertEqual(context.sunriseDisclosure, "Sunrise 5:53 AM")
        let polarContext = RitualDayContext(
            civilDate: "Sunday, 21 June 2026",
            locationName: "Longyearbyen, Svalbard",
            timeZoneIdentifier: "Arctic/Longyearbyen",
            tithiName: "Saptami",
            nakshatraName: "Purva Phalguni",
            sunriseTime: nil
        )
        XCTAssertEqual(polarContext.sunriseDisclosure, "Sunrise unavailable at this latitude")
    }

    @MainActor
    func testRitualSessionSurvivesRelaunchCompletionAndRestart() throws {
        let suiteName = "CosmicRitualsTests.RitualSession.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storageKey = "ritual-session-test"
        let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)
        let vidhi = try XCTUnwrap(PoojaVidhiCatalog.vidhi(id: "ganesha-home"))
        let materialID = try XCTUnwrap(vidhi.materials.first?.id)
        var store: RitualSessionStore? = RitualSessionStore(
            defaults: defaults,
            storageKey: storageKey,
            now: { fixedNow }
        )
        store?.toggleMaterial(materialID, for: vidhi)
        store?.begin(vidhi)
        store?.advance(in: vidhi)
        store?.advance(in: vidhi)
        var session = try XCTUnwrap(store?.session(for: vidhi))
        XCTAssertEqual(session.status, .inProgress)
        XCTAssertEqual(session.currentStepIndex, 2)
        XCTAssertEqual(session.preparedMaterialIDs, [materialID])
        XCTAssertEqual(store?.mostRecentUnfinishedSession?.id, vidhi.id)
        store = RitualSessionStore(defaults: defaults, storageKey: storageKey, now: { fixedNow })
        session = try XCTUnwrap(store?.session(for: vidhi))
        XCTAssertEqual(session.status, .inProgress)
        XCTAssertEqual(session.currentStepIndex, 2)
        XCTAssertEqual(session.preparedMaterialIDs, [materialID])
        for _ in 0...vidhi.steps.count { store?.advance(in: vidhi) }
        session = try XCTUnwrap(store?.session(for: vidhi))
        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.currentStepIndex, vidhi.steps.count - 1)
        XCTAssertNotNil(session.completedAt)
        XCTAssertNil(store?.mostRecentUnfinishedSession)
        store?.restartGuidedPractice(vidhi)
        session = try XCTUnwrap(store?.session(for: vidhi))
        XCTAssertEqual(session.status, .inProgress)
        XCTAssertEqual(session.currentStepIndex, 0)
        XCTAssertNil(session.completedAt)
        XCTAssertEqual(session.preparedMaterialIDs, [materialID])
    }

    @MainActor
    func testRitualSessionRejectsUnknownMaterialAndRecoversFromInvalidStorage() throws {
        let suiteName = "CosmicRitualsTests.RitualSession.Invalid.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storageKey = "ritual-session-invalid-test"
        let vidhi = try XCTUnwrap(PoojaVidhiCatalog.vidhi(id: "daily-panchopachara"))
        defaults.set(Data("not-json".utf8), forKey: storageKey)
        let store = RitualSessionStore(defaults: defaults, storageKey: storageKey)
        XCTAssertTrue(store.sessions.isEmpty)
        store.toggleMaterial("not-a-catalog-material", for: vidhi)
        XCTAssertTrue(store.session(for: vidhi).preparedMaterialIDs.isEmpty)
        XCTAssertNil(store.mostRecentUnfinishedSession)
    }

    func testSubscriptionPolicyRecognizesOnlyConfiguredProductsAndSecureLegalLinks() {
        XCTAssertEqual(Set(SubscriptionCatalog.productIDs).count, 2)
        XCTAssertTrue(SubscriptionCatalog.productIDs.allSatisfy {
            $0.hasPrefix("com.cosmic.rituals.premium.")
        })
        XCTAssertEqual(SubscriptionCatalog.requestedTrialDays, 14)
        XCTAssertFalse(SubscriptionEntitlementChecker.grantsAccess(activeProductIDs: []))
        XCTAssertFalse(SubscriptionEntitlementChecker.grantsAccess(activeProductIDs: ["unrelated.product"]))
        XCTAssertTrue(SubscriptionEntitlementChecker.grantsAccess(
            activeProductIDs: [SubscriptionCatalog.annualProductID]
        ))
        XCTAssertTrue([
            SubscriptionCatalog.privacyPolicyURL,
            SubscriptionCatalog.termsOfUseURL,
            SubscriptionCatalog.supportURL,
            SubscriptionCatalog.manageSubscriptionsURL
        ].allSatisfy { $0.scheme == "https" })
    }

    func testLaunchPolicyKeepsTestingAccessSeparateFromProductionEntitlements() {
        XCTAssertEqual(
            SubscriptionLaunchPolicy.initialState(
                isUITestingPremium: false,
                isTestingDistribution: false
            ),
            .checking
        )
        XCTAssertEqual(
            SubscriptionLaunchPolicy.initialState(
                isUITestingPremium: true,
                isTestingDistribution: false
            ),
            .entitled
        )
        XCTAssertEqual(
            SubscriptionLaunchPolicy.initialState(
                isUITestingPremium: false,
                isTestingDistribution: true
            ),
            .testingAccess
        )
        XCTAssertTrue(SubscriptionAccessState.testingAccess.hasPremiumAccess)
        XCTAssertTrue(SubscriptionAccessState.testingAccess.isTestingAccess)
        XCTAssertFalse(SubscriptionAccessState.entitled.isTestingAccess)
        XCTAssertFalse(SubscriptionAccessState.storeUnavailable(.offline).hasPremiumAccess)
    }

    func testStoreKitConfigurationDeclaresTwoWeekTrialsForEveryProduct() throws {
        let nativeRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = nativeRoot.appendingPathComponent("StoreKit/CosmicRituals.storekit")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let groups = try XCTUnwrap(root["subscriptionGroups"] as? [[String: Any]])
        let subscriptions = groups.flatMap { $0["subscriptions"] as? [[String: Any]] ?? [] }

        XCTAssertEqual(Set(subscriptions.compactMap { $0["productID"] as? String }), Set(SubscriptionCatalog.productIDs))
        XCTAssertEqual(Set(subscriptions.compactMap { $0["recurringSubscriptionPeriod"] as? String }), ["P1M", "P1Y"])

        for subscription in subscriptions {
            let productID = try XCTUnwrap(subscription["productID"] as? String)
            let offers = try XCTUnwrap(subscription["introductoryOffers"] as? [[String: Any]], productID)
            let offer = try XCTUnwrap(offers.first, productID)
            XCTAssertEqual(offer["paymentMode"] as? String, "free", productID)
            XCTAssertEqual(offer["subscriptionPeriod"] as? String, "P2W", productID)
            XCTAssertEqual(offer["numberOfPeriods"] as? Int, 1, productID)
        }
    }

    func testAccessibilityLargeLocationMetadataKeepsFullTimeZone() {
        XCTAssertEqual(
            RitualResponsiveLayout.locationMetadataLines(
                sourceDescription: "Offline city",
                timeZoneIdentifier: "Atlantic/Reykjavik",
                for: .large
            ),
            ["Offline city · Atlantic/Reykjavik"]
        )
        XCTAssertEqual(
            RitualResponsiveLayout.locationMetadataLines(
                sourceDescription: "Offline city",
                timeZoneIdentifier: "Atlantic/Reykjavik",
                for: .accessibility2
            ),
            ["Offline city", "Atlantic/Reykjavik"]
        )
        XCTAssertEqual(
            RitualResponsiveLayout.locationMetadataLines(
                sourceDescription: "Saved last GPS coordinate",
                timeZoneIdentifier: "America/Argentina/Buenos_Aires",
                for: .accessibility5
            ).last,
            "America/Argentina/Buenos_Aires"
        )
    }

    func testDatePresentationUsesSelectedLocationTimeZone() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let instant = try XCTUnwrap(utc.date(from: DateComponents(
            year: 2026, month: 7, day: 23, hour: 20, minute: 30
        )))
        let locale = Locale(identifier: "en_US_POSIX")
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let losAngeles = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        XCTAssertEqual(instant.ritualDate(template: "d", in: tokyo, locale: locale), "24")
        XCTAssertEqual(instant.ritualDate(template: "d", in: losAngeles, locale: locale), "23")
        XCTAssertEqual(
            instant.ritualShortTime(in: tokyo, locale: locale)
                .replacingOccurrences(of: "\u{202F}", with: " "),
            "5:30 AM"
        )
        XCTAssertEqual(
            instant.ritualShortTime(in: losAngeles, locale: locale)
                .replacingOccurrences(of: "\u{202F}", with: " "),
            "1:30 PM"
        )
    }

    func testLocationChangePreservesTheSelectedCivilDayAcrossDateLineOffsets() throws {
        var losAngelesCalendar = Calendar(identifier: .gregorian)
        losAngelesCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let selected = try XCTUnwrap(losAngelesCalendar.date(from: DateComponents(
            year: 2026, month: 7, day: 23, hour: 20, minute: 30
        )))
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let translated = selected.ritualCivilDay(
            preservingDateFrom: losAngelesCalendar.timeZone,
            into: tokyo
        )
        var tokyoCalendar = Calendar(identifier: .gregorian)
        tokyoCalendar.timeZone = tokyo
        let components = tokyoCalendar.dateComponents([.year, .month, .day, .hour], from: translated)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 23)
        XCTAssertEqual(components.hour, 12)
    }

    func testOnlyOwnedNotificationIdentifiersAreCleared() {
        XCTAssertTrue(NotificationManager.isRitualNotificationIdentifier("muhurta.2.123"))
        XCTAssertTrue(NotificationManager.isRitualNotificationIdentifier("brahma.123"))
        XCTAssertFalse(NotificationManager.isRitualNotificationIdentifier("another-feature.123"))
    }

    func testGeoNamesNoticeIsBundled() throws {
        let noticeURL = try XCTUnwrap(Bundle.main.url(forResource: "NOTICE", withExtension: "txt"))
        let notice = try String(contentsOf: noticeURL, encoding: .utf8)
        XCTAssertTrue(notice.contains("GeoNames"))
        XCTAssertTrue(notice.contains("CC BY 4.0"))
        XCTAssertTrue(notice.contains("cities15000"))

        let catalogURL = try XCTUnwrap(Bundle.main.url(forResource: "world_cities", withExtension: "tsv"))
        XCTAssertFalse(try String(contentsOf: catalogURL, encoding: .utf8).isEmpty)
        let matchingResources = Bundle.main.urls(forResourcesWithExtension: "tsv", subdirectory: nil)?
            .filter { $0.lastPathComponent == "world_cities.tsv" }
        XCTAssertEqual(matchingResources?.count, 1)
    }

    func testLightThemesKeepSemanticTextLegible() {
        let lightThemes = CosmicThemeVariant.allCases.map(\.colorScheme).filter(\.isLight)
        XCTAssertEqual(lightThemes.count, 3)
        XCTAssertEqual(CosmicThemeVariant.allCases.count - lightThemes.count, 3)

        for theme in lightThemes {
            XCTAssertEqual(theme.colorScheme, .light, theme.displayName)
            XCTAssertGreaterThanOrEqual(
                contrast(theme.semanticPrimaryText, over: theme.background),
                7.0,
                "\(theme.displayName) primary text"
            )
            XCTAssertGreaterThanOrEqual(
                contrast(theme.semanticSecondaryText, over: theme.background),
                4.5,
                "\(theme.displayName) secondary text"
            )
            XCTAssertGreaterThanOrEqual(
                contrast(theme.semanticTertiaryText, over: theme.background),
                3.0,
                "\(theme.displayName) tertiary text"
            )
        }
    }

    func testThemeNamesExpressAUniqueCeremonialIdentity() {
        XCTAssertEqual(
            CosmicThemeVariant.allCases.map(\.displayName),
            ["Deep Sandhya", "Temple Dawn", "Kumkum Night", "Ghee Lamp Ivory", "Sandalwood", "Lotus Ash"]
        )
        XCTAssertTrue(CosmicThemeVariant.allCases.allSatisfy {
            !$0.displayName.localizedCaseInsensitiveContains("cosmic")
                && !$0.displayName.localizedCaseInsensitiveContains("celestial")
                && !$0.displayName.localizedCaseInsensitiveContains("aurora")
        })
    }

    func testRitualSanctuaryBackgroundAssetIsBundled() {
        XCTAssertNotNil(UIImage(named: "RitualSanctuaryBackground"))
    }

    func testSelectedControlForegroundRemainsLegibleAcrossEveryTheme() {
        for theme in CosmicThemeVariant.allCases.map(\.colorScheme) {
            XCTAssertGreaterThanOrEqual(
                contrast(theme.selectedControlForeground, over: theme.primary),
                4.5,
                "\(theme.displayName) selected-control foreground"
            )
        }
    }

    func testMonthlyCalendarCacheIdentityChangesWithCalculationLocation() {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let tokyo = context(2026, 7, 24, latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo")
        let sameDelhiNextDay = delhi.advancedByLocalDays(1)

        XCTAssertNotEqual(
            MonthlyCalendarCalculationSignature(context: delhi),
            MonthlyCalendarCalculationSignature(context: tokyo)
        )
        XCTAssertEqual(
            MonthlyCalendarCalculationSignature(context: delhi),
            MonthlyCalendarCalculationSignature(context: sameDelhiNextDay),
            "Changing only the selected day must not invalidate a whole-month location cache"
        )
    }

    func testPrivacyManifestUsesOnlyStandardAppUserDefaultsReason() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        let accessedTypes = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = try XCTUnwrap(accessedTypes.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
        })
        let reasons = try XCTUnwrap(userDefaults["NSPrivacyAccessedAPITypeReasons"] as? [String])

        XCTAssertEqual(reasons, ["CA92.1"])
    }

    @MainActor
    func testPoojaPrimaryScreensRenderAtPhoneAndAccessibilitySizes() async {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let panchangValue = CosmicEngine.getPanchang(context: delhi)
        let ritualSessionStore = RitualSessionStore(defaults: nil)
        let panchang = NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                ScrollView {
                    PanchangExperienceHome(
                        mode: .ritualNow,
                        selectedDate: .constant(delhi.localDay),
                        panchang: panchangValue,
                        showTithiDetail: {},
                        showYogaDetail: {},
                        showKaranaDetail: {}
                    )
                    .padding()
                }
            }
            .navigationTitle("Panchang")
        }
        .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
        .environment(\.timeZone, delhi.timeZone)
        .preferredColorScheme(.dark)

        let library = NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                PoojaVidhiLibraryView()
            }
            .navigationTitle("Pooja")
        }
        .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
        .environmentObject(ritualSessionStore)
        .preferredColorScheme(.dark)

        let detail = NavigationStack {
            PoojaVidhiDetailView(vidhi: PoojaVidhiCatalog.all[2])
        }
        .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
        .environmentObject(ritualSessionStore)
        .preferredColorScheme(.dark)

        let guided = NavigationStack {
            GuidedPoojaView(vidhi: PoojaVidhiCatalog.all[1])
        }
        .environment(\.cosmicTheme, CosmicColorScheme.cloudDancer)
        .environmentObject(ritualSessionStore)
        .environment(\.dynamicTypeSize, .accessibility2)
        .preferredColorScheme(.light)

        await attachSnapshot(panchang, name: "Panchang Calculation Disclosure")
        await attachSnapshot(library, name: "Pooja Library")
        await attachSnapshot(detail, name: "Lakshmi Vidhi Detail")
        await attachSnapshot(guided, name: "Guided Pooja Accessibility Text")
    }

    @MainActor
    private func attachSnapshot<Content: View>(_ content: Content, name: String) async {
        let size = CGSize(width: 390, height: 844)
        let controller = UIHostingController(rootView: content)
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            XCTFail("A window scene is required for the rendering contract")
            return
        }
        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 150_000_000)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        XCTAssertEqual(image.size, size)
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }

    private func contrast(_ foreground: Color, over background: Color) -> Double {
        let foregroundRGBA = rgba(foreground)
        let backgroundRGBA = rgba(background)
        let alpha = foregroundRGBA.alpha
        let composite = (
            red: foregroundRGBA.red * alpha + backgroundRGBA.red * (1 - alpha),
            green: foregroundRGBA.green * alpha + backgroundRGBA.green * (1 - alpha),
            blue: foregroundRGBA.blue * alpha + backgroundRGBA.blue * (1 - alpha)
        )
        let foregroundLuminance = relativeLuminance(composite)
        let backgroundLuminance = relativeLuminance((
            red: backgroundRGBA.red,
            green: backgroundRGBA.green,
            blue: backgroundRGBA.blue
        ))
        return (max(foregroundLuminance, backgroundLuminance) + 0.05)
            / (min(foregroundLuminance, backgroundLuminance) + 0.05)
    }

    private func rgba(_ color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }

    private func relativeLuminance(_ color: (red: Double, green: Double, blue: Double)) -> Double {
        func linear(_ component: Double) -> Double {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red)
            + 0.7152 * linear(color.green)
            + 0.0722 * linear(color.blue)
    }

    private func context(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        latitude: Double,
        longitude: Double,
        timeZone: String
    ) -> CalculationContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone) ?? .gmt
        let localDay = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date(timeIntervalSince1970: 0)
        return CalculationContext(
            localDay: localDay,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone
        )
    }

    private func assertLocalTransition(
        _ transition: PanchangTransition?,
        current: String,
        next: String,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        context: CalculationContext,
        toleranceMinutes: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let transition = try XCTUnwrap(transition, file: file, line: line)
        XCTAssertEqual(transition.currentName, current, file: file, line: line)
        XCTAssertEqual(transition.nextName, next, file: file, line: line)
        let expected = try XCTUnwrap(context.calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute
        )), file: file, line: line)
        XCTAssertEqual(
            transition.endTime.timeIntervalSince(expected),
            0,
            accuracy: toleranceMinutes * 60,
            file: file,
            line: line
        )
    }

    private func limbName(_ kind: PanchangLimbKind, in panchang: Panchang) -> String {
        switch kind {
        case .tithi: return panchang.tithiName
        case .nakshatra: return panchang.nakshatraName
        case .yoga: return panchang.yogaName
        case .karana: return panchang.karanaName
        }
    }

    private func assertLocalInterval(
        _ period: (start: Date, end: Date, label: String),
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        context: CalculationContext,
        toleranceMinutes: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let components = context.localDayComponents
        let start = try XCTUnwrap(context.calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: startHour,
            minute: startMinute
        )), file: file, line: line)
        let end = try XCTUnwrap(context.calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: endHour,
            minute: endMinute
        )), file: file, line: line)
        XCTAssertEqual(period.start.timeIntervalSince(start), 0, accuracy: toleranceMinutes * 60, file: file, line: line)
        XCTAssertEqual(period.end.timeIntervalSince(end), 0, accuracy: toleranceMinutes * 60, file: file, line: line)
    }
}
