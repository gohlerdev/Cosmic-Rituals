import XCTest
@testable import CosmicRituals

/// Prahars, Ishta Kaal and the ghati counters. The units and the prahar
/// construction were verified against sources BEFORE implementation (see the
/// header of TraditionalClockEngine.swift); the fixtures below record those
/// sources beside the expected values so an engine change cannot quietly
/// update implementation and expectation together.
final class TraditionalClockTests: XCTestCase {

    private func context(
        _ y: Int, _ m: Int, _ d: Int,
        lat: Double = 28.6139, lon: Double = 77.2090,
        tz: String = "Asia/Kolkata"
    ) -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: tz)!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: lat, longitude: lon, timeZoneIdentifier: tz
        )
    }

    private func instant(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, tz: String = "Asia/Kolkata") -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: tz)!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    // MARK: - Units

    /// sankul.org/ghati: "1 day & night or 24 hours = 60 ghatis; 1 ghati = 60
    /// palas; 1 pala = 60 vipalas." A ghati is a FIXED 24 minutes.
    func testSexagesimalUnitRatios() {
        XCTAssertEqual(GhatiPala(interval: 24 * 60), GhatiPala(ghati: 1, pala: 0, vipala: 0))
        XCTAssertEqual(GhatiPala(interval: 24), GhatiPala(ghati: 0, pala: 1, vipala: 0))
        XCTAssertEqual(GhatiPala(interval: 0.4), GhatiPala(ghati: 0, pala: 0, vipala: 1))
        XCTAssertEqual(GhatiPala(interval: 24 * 3_600).ghati, 60, "the 60-ghati day")
    }

    /// Published worked example (the x2.5 rule): sunrise 06:30, instant 16:30
    /// is 10 elapsed hours, which is exactly 25 ghatis.
    func testPublishedIshtaKaalWorkedExample() {
        XCTAssertEqual(GhatiPala(interval: 10 * 3_600), GhatiPala(ghati: 25, pala: 0, vipala: 0))
        // 2.5 ghatis to the hour, stated as the rule rather than assumed.
        XCTAssertEqual(GhatiPala(interval: 3_600).interval / GhatiPala.secondsPerGhati, 2.5)
    }

    /// Carrying is sexagesimal in both places, and a negative interval clamps
    /// to zero rather than producing a nonsense reading.
    func testConversionCarriesAndClampsClosed() {
        // 1 ghati + 1 pala + 1 vipala = 1440 + 24 + 0.4 s
        XCTAssertEqual(GhatiPala(interval: 1_464.4), GhatiPala(ghati: 1, pala: 1, vipala: 1))
        // 3599 vipalas is 59 pa 59 vi, one vipala short of rolling a ghati.
        XCTAssertEqual(GhatiPala(interval: 3_599 * 0.4), GhatiPala(ghati: 0, pala: 59, vipala: 59))
        XCTAssertEqual(GhatiPala(interval: -500), GhatiPala(ghati: 0, pala: 0, vipala: 0))
    }

    // MARK: - Prahar structure

    /// Eight prahars, contiguous, anchored on the real solar instants: the
    /// first opens at sunrise, the fourth closes exactly at sunset, and the
    /// eighth closes at the following sunrise.
    func testEightPraharsSpanSunriseToNextSunrise() throws {
        let ctx = context(2026, 8, 27)
        let prahars = TraditionalClock.prahars(context: ctx)
        XCTAssertEqual(prahars.count, 8)
        XCTAssertEqual(prahars.map(\.number), Array(1...8))
        XCTAssertEqual(prahars.filter(\.isDay).count, 4)
        XCTAssertEqual(prahars.map(\.name), [
            "Purvahna", "Madhyahna", "Aparahna", "Sayahna",
            "Pradosha", "Nishitha", "Triyama", "Usha",
        ])

        let today = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx))
        let tomorrow = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx.advancedByLocalDays(1)))
        XCTAssertEqual(prahars[0].start.timeIntervalSince(today.sunrise), 0, accuracy: 1)
        XCTAssertEqual(prahars[3].end.timeIntervalSince(today.sunset), 0, accuracy: 1)
        XCTAssertEqual(prahars[4].start.timeIntervalSince(today.sunset), 0, accuracy: 1)
        XCTAssertEqual(prahars[7].end.timeIntervalSince(tomorrow.sunrise), 0, accuracy: 1)

        for index in 1..<prahars.count {
            XCTAssertEqual(prahars[index].start, prahars[index - 1].end, "no gap at boundary \(index)")
        }
        for group in [Array(prahars[0..<4]), Array(prahars[4..<8])] {
            let durations = group.map(\.duration)
            XCTAssertEqual(durations.max()! - durations.min()!, 0, accuracy: 1,
                           "the four quarters of a half-day are equal to each other")
        }
    }

    /// THE LOAD-BEARING TEST. Wikipedia "Prahara": prahars are equal three-hour
    /// blocks only near the equator; elsewhere day and night prahars differ
    /// with the season. A fixed-three-hour implementation would pass every
    /// structural test above and fail here.
    func testPraharsAreProportionalNotThreeHourBlocks() throws {
        let threeHours: TimeInterval = 3 * 3_600

        // Delhi in late December: a short day, so day prahars must be
        // materially SHORTER than three hours and night prahars longer.
        let winter = TraditionalClock.prahars(context: context(2026, 12, 21))
        let winterDay = try XCTUnwrap(winter.first).duration
        let winterNight = try XCTUnwrap(winter.last).duration
        XCTAssertLessThan(winterDay, threeHours - 20 * 60, "short winter day prahar")
        XCTAssertGreaterThan(winterNight, threeHours + 20 * 60, "long winter night prahar")

        // Same place in June: the asymmetry reverses.
        let summer = TraditionalClock.prahars(context: context(2026, 6, 21))
        XCTAssertGreaterThan(try XCTUnwrap(summer.first).duration, threeHours + 15 * 60)
        XCTAssertLessThan(try XCTUnwrap(summer.last).duration, threeHours - 15 * 60)

        // Near the equator the two converge on three hours, as the source says.
        let equator = TraditionalClock.prahars(context: context(2026, 12, 21, lat: 1.3521, lon: 103.8198, tz: "Asia/Singapore"))
        XCTAssertEqual(try XCTUnwrap(equator.first).duration, threeHours, accuracy: 8 * 60)
        XCTAssertEqual(try XCTUnwrap(equator.last).duration, threeHours, accuracy: 8 * 60)
    }

    /// One surface, one solar model: a day prahar is exactly two Choghadiya
    /// slots (daylight/4 versus daylight/8), so the two features can never
    /// drift apart on screen.
    func testPraharBoundariesAgreeWithChoghadiya() throws {
        let ctx = context(2026, 8, 27)
        let prahars = TraditionalClock.prahars(context: ctx)
        let choghadiya = CosmicEngine.getChoghadiya(context: ctx)
        XCTAssertEqual(choghadiya.count, 16)
        for index in 0..<4 {
            XCTAssertEqual(prahars[index].start, choghadiya[index * 2].startTime)
            XCTAssertEqual(prahars[index].end, choghadiya[index * 2 + 1].endTime)
        }
    }

    // MARK: - Ishta Kaal

    /// Ishta Kaal is zero at sunrise and grows at 2.5 ghatis per elapsed hour.
    func testIshtaKaalIsMeasuredFromSunrise() throws {
        let ctx = context(2026, 8, 27)
        let sunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx)).sunrise

        let atSunrise = try XCTUnwrap(TraditionalClock.ishtaKaal(at: sunrise, context: ctx))
        XCTAssertEqual(atSunrise.value, GhatiPala(ghati: 0, pala: 0, vipala: 0))

        let fourHoursLater = try XCTUnwrap(
            TraditionalClock.ishtaKaal(at: sunrise.addingTimeInterval(4 * 3_600), context: ctx))
        XCTAssertEqual(fourHoursLater.value, GhatiPala(ghati: 10, pala: 0, vipala: 0))
        XCTAssertEqual(fourHoursLater.sunrise, sunrise, "the anchor is reported, not hidden")
    }

    /// The Vedic day runs sunrise to sunrise, so a small-hours instant belongs
    /// to the PREVIOUS Vedic day: its Ishta Kaal is a large positive reading
    /// near the end of the 60-ghati cycle, never a negative one.
    func testPreDawnInstantBelongsToThePreviousVedicDay() throws {
        let ctx = context(2026, 8, 27)
        let threeAM = instant(2026, 8, 27, 3, 0)

        let reading = try XCTUnwrap(TraditionalClock.ishtaKaal(at: threeAM, context: ctx))
        XCTAssertGreaterThan(reading.elapsed, 0, "never negative")
        XCTAssertTrue((50...59).contains(reading.value.ghati), "late in the cycle, got \(reading.value.ghati)")

        let yesterdaySunrise = try XCTUnwrap(
            CosmicEngine.getSunriseSunset(context: ctx.advancedByLocalDays(-1))).sunrise
        XCTAssertEqual(reading.sunrise, yesterdaySunrise)

        // And the same instant resolves to a NIGHT prahar of the previous day.
        // Which one is arithmetic, not intuition: Delhi's night here runs
        // ~18:50 to ~05:56, so each night prahar is ~2h46m and the sequence is
        // Pradosha ~18:50, Nishitha ~21:36, Triyama ~00:23, Usha ~03:09.
        // 03:00 therefore falls in Triyama -- Usha has not started yet.
        let prahar = try XCTUnwrap(TraditionalClock.prahar(at: threeAM, context: ctx))
        XCTAssertFalse(prahar.isDay)
        XCTAssertEqual(prahar.name, "Triyama")

        // Usha is the quarter that actually closes at sunrise, so an instant
        // shortly before dawn must land there and its prahar must end exactly
        // at the sunrise that ends the Vedic day.
        let todaySunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: ctx)).sunrise
        let beforeDawn = todaySunrise.addingTimeInterval(-30 * 60)
        let usha = try XCTUnwrap(TraditionalClock.prahar(at: beforeDawn, context: ctx))
        XCTAssertEqual(usha.name, "Usha")
        XCTAssertEqual(usha.number, 8)
        XCTAssertEqual(usha.end.timeIntervalSince(todaySunrise), 0, accuracy: 1)
    }

    /// The running prahar matches the prahar list that contains the instant.
    func testPraharAtInstantMatchesTheList() throws {
        let ctx = context(2026, 8, 27)
        let prahars = TraditionalClock.prahars(context: ctx)
        for expected in prahars {
            let midpoint = expected.start.addingTimeInterval(expected.duration / 2)
            XCTAssertEqual(try XCTUnwrap(TraditionalClock.prahar(at: midpoint, context: ctx)), expected)
        }
    }

    // MARK: - Dinamana / Ratrimana

    /// Derived from the repo's existing published fixture (Drik Panchang,
    /// Mumbai, 2026-07-24: sunrise 06:12, sunset 19:17). That daylight arc is
    /// 13h05m, which under the FIXED 24-minute ghati is 32 gh 42 pa — and
    /// emphatically not 30. That gap is the whole point: it is the observable
    /// signature of this engine's ghati convention, and it is what would
    /// vanish if someone silently switched to the competing 30-ghati clock,
    /// where dinamana is 30 by construction on every date everywhere.
    func testDinamanaShowsTheFixedGhatiConvention() throws {
        let mumbai = context(2026, 7, 24, lat: 19.0760, lon: 72.8777)
        let measure = try XCTUnwrap(TraditionalClock.dayNightMeasure(context: mumbai))

        let dinamanaGhatis = measure.dinamana.interval / GhatiPala.secondsPerGhati
        XCTAssertEqual(dinamanaGhatis, 32.708, accuracy: 0.5, "published 13h05m daylight")
        XCTAssertGreaterThan(abs(dinamanaGhatis - 30), 2,
                             "a 30-ghati reading here would mean the proportional convention")

        // Dinamana plus ratrimana is one whole 60-ghati day, within the slack
        // of a real sunrise-to-sunrise interval.
        let total = (measure.dinamana.interval + measure.ratrimana.interval) / GhatiPala.secondsPerGhati
        XCTAssertEqual(total, 60, accuracy: 0.2)
    }

    /// Dinamana must MOVE across the year at a mid-latitude — the property
    /// that makes it worth printing at all.
    func testDinamanaVariesAcrossTheYear() throws {
        let june = try XCTUnwrap(TraditionalClock.dayNightMeasure(context: context(2026, 6, 21))).dinamana
        let december = try XCTUnwrap(TraditionalClock.dayNightMeasure(context: context(2026, 12, 21))).dinamana
        XCTAssertGreaterThan(june.interval - december.interval, 2 * 3_600,
                             "Delhi's longest and shortest days differ by hours")
    }

    // MARK: - Fail closed

    /// No sunrise, no sunrise-derived schedule — the same rule the muhurta,
    /// Choghadiya and kala surfaces already follow. Never a fabricated clock.
    func testPolarDayFailsClosed() {
        let longyearbyen = context(2026, 6, 21, lat: 78.2232, lon: 15.6469, tz: "Arctic/Longyearbyen")
        XCTAssertTrue(TraditionalClock.prahars(context: longyearbyen).isEmpty)
        XCTAssertNil(TraditionalClock.dayNightMeasure(context: longyearbyen))
        XCTAssertNil(TraditionalClock.ishtaKaal(at: longyearbyen.localNoon, context: longyearbyen))
        XCTAssertNil(TraditionalClock.prahar(at: longyearbyen.localNoon, context: longyearbyen))
    }
}
