import Foundation

// MARK: - Generic rise/transit/set solver (Meeus ch. 15)
//
// Body-agnostic: the caller supplies apparent equatorial coordinates for any
// instant and the standard altitude for the event. The Sun's existing
// hour-angle solver stays the production sunrise path; this solver exists for
// bodies whose motion is too fast for the single-evaluation shortcut -- the
// Moon moves ~13 degrees/day, so its rise time must be iterated with the
// position re-evaluated at each trial instant. Where Meeus interpolates
// between tabulated daily positions, this implementation evaluates the
// ephemeris directly at each trial instant, which is strictly more accurate.
//
// Validated against the Sun: with the Sun's apparent longitude converted to
// RA/Dec and h0 = -0.8333 degrees, this solver reproduces the production
// sunrise/sunset solver within the fixture tolerance on every fixture city.

enum CelestialRiseSet {

    struct EquatorialPosition {
        /// Apparent right ascension, degrees 0-360.
        let rightAscensionDeg: Double
        /// Apparent declination, degrees.
        let declinationDeg: Double
    }

    /// Greenwich mean sidereal time in degrees (Meeus 12.4), same constants
    /// the family's ascendant computation uses.
    static func greenwichSiderealTimeDeg(jd: Double) -> Double {
        let T = (jd - CosmicEngine.J2000) / 36525.0
        let gmst = 280.46061837
            + 360.98564736629 * (jd - CosmicEngine.J2000)
            + 0.000387933 * T * T
            - T * T * T / 38_710_000
        return CosmicEngine.normalize360(gmst)
    }

    /// Rise and set as UTC hour-of-day for the given UTC calendar day, or nil
    /// per event when the body does not cross `standardAltitudeDeg` that day
    /// (circumpolar or never-rising at that latitude).
    ///
    /// `position` must return APPARENT equatorial coordinates for an
    /// arbitrary UT Julian date. Longitude is east-positive.
    static func riseSet(
        utcYear: Int, month: Int, day: Int,
        latDeg: Double, lonDeg: Double,
        standardAltitudeDeg: Double,
        position: (Double) -> EquatorialPosition
    ) -> (rise: Double?, set: Double?) {
        let jd0 = CosmicEngine.julianDate(year: utcYear, month: month, day: day, decimalHour: 0)
        let phi = latDeg * .pi / 180
        let h0 = standardAltitudeDeg * .pi / 180

        // Local hour angle of the body at day-fraction m (degrees, -180..180).
        func hourAngle(atFraction m: Double) -> (H: Double, pos: EquatorialPosition) {
            let jd = jd0 + m
            let pos = position(jd)
            let lst = greenwichSiderealTimeDeg(jd: jd) + lonDeg
            var H = CosmicEngine.normalize360(lst - pos.rightAscensionDeg)
            if H > 180 { H -= 360 }
            return (H, pos)
        }

        // Transit: iterate until the hour angle is ~0.
        var mTransit = 0.5
        for _ in 0..<10 {
            let (H, _) = hourAngle(atFraction: mTransit)
            // The hour angle advances ~360.9856 degrees per day.
            let delta = -H / 360.9856
            mTransit += delta
            if abs(delta) < 1e-7 { break }
        }

        // Semi-diurnal arc at a trial instant, or nil when there is no
        // crossing (|cos H0| > 1).
        func semiArcDegrees(at m: Double) -> Double? {
            let (_, pos) = hourAngle(atFraction: m)
            let delta = pos.declinationDeg * .pi / 180
            let cosH0 = (sin(h0) - sin(phi) * sin(delta)) / (cos(phi) * cos(delta))
            guard abs(cosH0) <= 1 else { return nil }
            return acos(cosH0) * 180 / .pi
        }

        func refineEvent(rising: Bool) -> Double? {
            guard let initialArc = semiArcDegrees(at: mTransit) else { return nil }
            var m = mTransit + (rising ? -1 : 1) * initialArc / 360.9856
            for _ in 0..<10 {
                guard let arc = semiArcDegrees(at: m) else { return nil }
                let (H, _) = hourAngle(atFraction: m)
                let target = rising ? -arc : arc
                var diff = target - H
                if diff > 180 { diff -= 360 }
                if diff < -180 { diff += 360 }
                let delta = diff / 360.9856
                m += delta
                if abs(delta) < 1e-7 { break }
            }
            return m * 24
        }

        return (refineEvent(rising: true), refineEvent(rising: false))
    }

    /// The Moon's apparent equatorial position from the engine's apparent
    /// longitude and Table 47.B latitude, with the mean obliquity.
    static func moonEquatorial(jd: Double) -> EquatorialPosition {
        let T = (jd - CosmicEngine.J2000) / 36525.0
        let epsilon = (23.4392911 - 0.0130042 * T - 0.0000001639 * T * T + 0.0000005036 * T * T * T) * .pi / 180
        let lambda = CosmicEngine.moonLongitude(jd: jd) * .pi / 180
        let beta = CosmicEngine.moonLatitude(jd: jd) * .pi / 180
        let alpha = atan2(
            sin(lambda) * cos(epsilon) - tan(beta) * sin(epsilon),
            cos(lambda)
        ) * 180 / .pi
        let delta = asin(
            sin(beta) * cos(epsilon) + cos(beta) * sin(epsilon) * sin(lambda)
        ) * 180 / .pi
        return EquatorialPosition(
            rightAscensionDeg: CosmicEngine.normalize360(alpha),
            declinationDeg: delta
        )
    }

    /// Standard altitude for moonrise/moonset from the TRUE horizontal
    /// parallax at the given instant: Meeus ch. 15, h0 = 0.7275 pi - 34',
    /// with sin(pi) = 6378.14 km / Delta and Delta from the now-carried
    /// Table 47.A distance series. Ranges ~0.088 to 0.180 degrees across
    /// the anomalistic month; the former fixed mean (+0.125) could err
    /// about a minute of rise time, more at high latitudes.
    static func moonStandardAltitudeDeg(jd: Double) -> Double {
        let delta = CosmicEngine.moonDistanceKm(jd: jd)
        let parallax = asin(6_378.14 / delta) * 180 / .pi
        return 0.7275 * parallax - 34.0 / 60.0
    }

    /// Moonrise and moonset for the selected LOCAL civil day. Solves the
    /// three surrounding UTC days and keeps the events that land on the
    /// requested local day -- the same day-mapping discipline the sunrise
    /// path uses. A nil is a genuine astronomical fact: roughly once a
    /// lunar month the rise (or set) slips past midnight and a civil day
    /// has none, and the UI states that instead of hiding the row.
    static func moonRiseSet(context: CalculationContext) -> (moonrise: Date?, moonset: Date?) {
        let components = context.localDayComponents
        guard let y = components.year, let m = components.month, let d = components.day else {
            return (nil, nil)
        }
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let base = utcCal.date(from: DateComponents(year: y, month: m, day: d, hour: 12)) else {
            return (nil, nil)
        }
        let calendar = context.calendar
        var rise: Date?
        var set: Date?
        for offset in -1...1 {
            guard let dayDate = utcCal.date(byAdding: .day, value: offset, to: base) else { continue }
            let dc = utcCal.dateComponents([.year, .month, .day], from: dayDate)
            guard let uy = dc.year, let um = dc.month, let ud = dc.day else { continue }
            let dayNoonJD = CosmicEngine.julianDate(year: uy, month: um, day: ud, decimalHour: 12)
            let events = riseSet(
                utcYear: uy, month: um, day: ud,
                latDeg: context.latitude, lonDeg: context.longitude,
                standardAltitudeDeg: moonStandardAltitudeDeg(jd: dayNoonJD),
                position: moonEquatorial
            )
            if let r = events.rise {
                let date = CosmicEngine.dateFromUTCHour(r, year: uy, month: um, day: ud)
                if calendar.isDate(date, inSameDayAs: context.localNoon), rise == nil { rise = date }
            }
            if let st = events.set {
                let date = CosmicEngine.dateFromUTCHour(st, year: uy, month: um, day: ud)
                if calendar.isDate(date, inSameDayAs: context.localNoon), set == nil { set = date }
            }
        }
        return (rise, set)
    }

    /// The Sun's apparent equatorial position from the engine's own apparent
    /// longitude and mean obliquity -- used by the solar cross-validation and
    /// available to any caller needing solar RA/Dec.
    static func sunEquatorial(jd: Double) -> EquatorialPosition {
        let T = (jd - CosmicEngine.J2000) / 36525.0
        let epsilon = (23.4392911 - 0.0130042 * T - 0.0000001639 * T * T + 0.0000005036 * T * T * T) * .pi / 180
        let lambda = CosmicEngine.sunLongitude(jd: jd) * .pi / 180
        let alpha = atan2(cos(epsilon) * sin(lambda), cos(lambda)) * 180 / .pi
        let delta = asin(sin(epsilon) * sin(lambda)) * 180 / .pi
        return EquatorialPosition(
            rightAscensionDeg: CosmicEngine.normalize360(alpha),
            declinationDeg: delta
        )
    }
}
