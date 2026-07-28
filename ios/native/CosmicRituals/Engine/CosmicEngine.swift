import Foundation

// MARK: - Cosmic Engine (Panchang Ephemeris)
//
// Sidereal system, Lahiri Chitra Paksha ayanamsha.
// Algorithms: Meeus "Astronomical Algorithms" 2nd ed.
//
// This is the Panchang-focused slice of the shared Cosmic engine: it computes the
// five limbs of the Vedic day (tithi, nakshatra, yoga, karana, vara), the Moon's
// nakshatra/pada, local sunrise/sunset, and the thirty day & night muhurtas. The
// natal-chart, dasha, and divisional-chart machinery lives in the parent app and is
// intentionally not imported here.

enum CosmicEngine {

    // MARK: Constants
    static let J2000: Double = 2451545.0
    private static let C0: Double = 23.85709239   // Lahiri ayanamsha at J2000
    private static let C1: Double = 1.39688797    // degrees per Julian century
    private static let C2: Double = 0.00030706    // degrees per Julian century squared
    private static let DEG = Double.pi / 180.0
    private static let RAD = 180.0 / Double.pi

    // MARK: - Julian Date (Meeus §7)

    static func julianDate(year: Int, month: Int, day: Int, decimalHour: Double = 12.0) -> Double {
        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let A = Int(Double(y) / 100.0)
        let B = 2 - A + Int(Double(A) / 4.0)
        let dayFrac = Double(day) + decimalHour / 24.0
        return Double(Int(365.25 * Double(y + 4716))) +
               Double(Int(30.6001 * Double(m + 1))) +
               dayFrac + Double(B) - 1524.5
    }

    static func julianDateFromDate(_ date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let hour = Double(comps.hour ?? 12) + Double(comps.minute ?? 0) / 60.0 + Double(comps.second ?? 0) / 3600.0
        return julianDate(year: comps.year ?? 2000, month: comps.month ?? 1, day: comps.day ?? 1, decimalHour: hour)
    }

    // MARK: - Lahiri Ayanamsha (Chitra Paksha)

    static func lahiriAyanamsha(year: Double) -> Double {
        let centuries = (year - 2000.0) / 100.0
        return C0 + C1 * centuries + C2 * centuries * centuries
    }

    // MARK: - Sun (Meeus §25)

    static func sunLongitude(jd: Double) -> Double {
        let T = (jd - J2000) / 36525.0
        let L0 = normalize360(280.46646 + 36000.76983 * T + 0.0003032 * T * T)
        let M  = normalize360(357.52911 + 35999.05029 * T - 0.0001537 * T * T) * DEG
        let C  = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(M)
                + (0.019993 - 0.000101 * T) * sin(2 * M)
                + 0.000289 * sin(3 * M)
        let sunLon = L0 + C
        // Jupiter and Venus perturbations
        let Jup = normalize360(19.9 + 0.9856 * (jd - J2000)) * DEG
        let Ven = normalize360(212.0 + 0.985 * (jd - J2000)) * DEG
        let perturb = -0.00569 - 0.00478 * sin(Ven) + 0.0128 * sin(Jup)
        // Apparent longitude (nutation + aberration)
        let omega = normalize360(125.04 - 1934.136 * T) * DEG
        let apparent = sunLon + perturb - 0.00478 * sin(omega)
        return normalize360(apparent)
    }

    // MARK: - Moon (Meeus §47, complete Table 47.A longitude series)

    static func moonLongitude(jd: Double) -> Double {
        let T = (jd - J2000) / 36525.0
        let t2 = T * T
        let t3 = t2 * T
        let t4 = t3 * T
        let LpDegrees = normalize360(
            218.3164477 + 481267.88123421 * T - 0.0015786 * t2
                + t3 / 538841.0 - t4 / 65194000.0
        )
        let D = normalize360(
            297.8501921 + 445267.1114034 * T - 0.0018819 * t2
                + t3 / 545868.0 - t4 / 113065000.0
        ) * DEG
        let M = normalize360(
            357.5291092 + 35999.0502909 * T - 0.0001536 * t2
                + t3 / 24490000.0
        ) * DEG
        let Mp = normalize360(
            134.9633964 + 477198.8675055 * T + 0.0087414 * t2
                + t3 / 69699.0 - t4 / 14712000.0
        ) * DEG
        let F = normalize360(
            93.2720950 + 483202.0175233 * T - 0.0036539 * t2
                - t3 / 3526000.0 + t4 / 863310000.0
        ) * DEG

        // Meeus Table 47.A. Column order is exactly D, M, M′, F; coefficients
        // are in microdegrees. E scaling is E^abs(M coefficient).
        let terms: [(d: Int, m: Int, mp: Int, f: Int, coefficient: Double)] = [
            (0, 0, 1, 0, 6_288_774),
            (2, 0, -1, 0, 1_274_027),
            (2, 0, 0, 0, 658_314),
            (0, 0, 2, 0, 213_618),
            (0, 1, 0, 0, -185_116),
            (0, 0, 0, 2, -114_332),
            (2, 0, -2, 0, 58_793),
            (2, -1, -1, 0, 57_066),
            (2, 0, 1, 0, 53_322),
            (2, -1, 0, 0, 45_758),
            (0, 1, -1, 0, -40_923),
            (1, 0, 0, 0, -34_720),
            (0, 1, 1, 0, -30_383),
            (2, 0, 0, -2, 15_327),
            (0, 0, 1, 2, -12_528),
            (0, 0, 1, -2, 10_980),
            (4, 0, -1, 0, 10_675),
            (0, 0, 3, 0, 10_034),
            (4, 0, -2, 0, 8_548),
            (2, 1, -1, 0, -7_888),
            (2, 1, 0, 0, -6_766),
            (1, 0, -1, 0, -5_163),
            (1, 1, 0, 0, 4_987),
            (2, -1, 1, 0, 4_036),
            (2, 0, 2, 0, 3_994),
            (4, 0, 0, 0, 3_861),
            (2, 0, -3, 0, 3_665),
            (0, 1, -2, 0, -2_689),
            (2, 0, -1, 2, -2_602),
            (2, -1, -2, 0, 2_390),
            (1, 0, 1, 0, -2_348),
            (2, -2, 0, 0, 2_236),
            (0, 1, 2, 0, -2_120),
            (0, 2, 0, 0, -2_069),
            (2, -2, -1, 0, 2_048),
            (2, 0, 1, -2, -1_773),
            (2, 0, 0, 2, -1_595),
            (4, -1, -1, 0, 1_215),
            (0, 0, 2, 2, -1_110),
            (3, 0, -1, 0, -892),
            (2, 1, 1, 0, -810),
            (4, -1, -2, 0, 759),
            (0, 2, -1, 0, -713),
            (2, 2, -1, 0, -700),
            (2, 1, -2, 0, 691),
            (2, -1, 0, -2, 596),
            (4, 0, 1, 0, 549),
            (0, 0, 4, 0, 537),
            (4, -1, 0, 0, 520),
            (1, 0, -2, 0, -487),
            (2, 1, 0, -2, -399),
            (0, 0, 2, -2, -381),
            (1, 1, 1, 0, 351),
            (3, 0, -2, 0, -340),
            (4, 0, -3, 0, 330),
            (2, -1, 2, 0, 327),
            (0, 2, 1, 0, -323),
            (1, 1, -1, 0, 299),
            (2, 0, 3, 0, 294),
            (2, 0, -1, -2, 0),
        ]
        let e = 1.0 - 0.002516 * T - 0.0000074 * T * T
        var sumL: Double = 0
        for term in terms {
            let argument = Double(term.d) * D
                + Double(term.m) * M
                + Double(term.mp) * Mp
                + Double(term.f) * F
            let eFactor: Double
            switch abs(term.m) {
            case 1: eFactor = e
            case 2: eFactor = e * e
            default: eFactor = 1
            }
            sumL += term.coefficient * eFactor * sin(argument)
        }
        let a1 = normalize360(119.75 + 131.849 * T) * DEG
        let a2 = normalize360(53.09 + 479264.290 * T) * DEG
        let lp = LpDegrees * DEG
        sumL += 3_958 * sin(a1) + 1_962 * sin(lp - F) + 318 * sin(a2)

        // Mean geocentric ecliptic longitude, referred to the mean equinox of date.
        let lon = LpDegrees + sumL / 1_000_000.0
        return normalize360(lon)
    }

    // MARK: - Nakshatra

    static func getNakshatraPada(_ siderealDeg: Double) -> NakshatraResult {
        let d = normalize360(siderealDeg)
        let nakIdx = Int(d / (360.0 / 27.0))
        let degInNak = d - Double(nakIdx) * (360.0 / 27.0)
        let pada = Int(degInNak / (360.0 / 108.0)) + 1
        let lord = NakshatraResult.lords[nakIdx]
        return NakshatraResult(
            nakshatraIndex: nakIdx,
            nakshatraName: Panchang.nakshatraNames[nakIdx],
            pada: pada.clamped(to: 1...4),
            nakshatraLord: lord,
            symbol: NakshatraResult.symbols[nakIdx],
            gana: NakshatraResult.ganas[nakIdx],
            degree: d
        )
    }

    // MARK: - Panchang

    static func getPanchang(
        context: CalculationContext,
        includeTransitions: Bool = true
    ) -> Panchang {
        let solar = getSunriseSunset(context: context)
        let referenceDate = solar?.sunrise ?? context.localNoon
        return getPanchang(
            date: referenceDate,
            calendar: context.calendar,
            sunriseTime: solar?.sunrise,
            sunsetTime: solar?.sunset,
            transitions: includeTransitions ? getPanchangTransitions(after: referenceDate) : .unavailable
        )
    }

    private static func panchangReferenceDate(for context: CalculationContext) -> Date {
        getSunriseSunset(context: context)?.sunrise ?? context.localNoon
    }

    static func getPanchang(date: Date, timezoneIdentifier: String = "UTC") -> Panchang {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .gmt
        return getPanchang(
            date: date,
            calendar: calendar,
            sunriseTime: nil,
            sunsetTime: nil,
            transitions: .unavailable
        )
    }

    private static func getPanchang(
        date: Date,
        calendar: Calendar,
        sunriseTime: Date?,
        sunsetTime: Date?,
        transitions: PanchangTransitions
    ) -> Panchang {
        let jd = julianDateFromDate(date)
        let sunLon  = siderealize(sunLongitude(jd: jd), jd: jd)
        let moonLon = siderealize(moonLongitude(jd: jd), jd: jd)

        // Tithi: each 12° of moon-sun separation
        let elongation = normalize360(moonLon - sunLon)
        let tithiIdx = Int(elongation / 12.0)

        // Nakshatra of Moon
        let moonNak = getNakshatraPada(moonLon)

        // Yoga: (sun + moon) / (360/27)
        let yogaDeg = normalize360(sunLon + moonLon)
        let yogaIdx = Int(yogaDeg / (360.0 / 27.0)) % 27

        // Karana: half-tithi
        let karanaRaw = Int(elongation / 6.0)
        let karanaIdx = karanaIndex(forHalfTithiIndex: karanaRaw)

        let weekday = calendar.component(.weekday, from: date)
        let weekdayNames = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

        let moonSignIdx = Int(moonLon / 30.0) % 12

        return Panchang(
            date: date,
            tithiIndex: tithiIdx.clamped(to: 0...29),
            tithiName: Panchang.tithiNames[tithiIdx.clamped(to: 0...29)],
            nakshatraIndex: moonNak.nakshatraIndex,
            nakshatraName: moonNak.nakshatraName,
            yogaIndex: yogaIdx,
            yogaName: Panchang.yogaNames[yogaIdx],
            karanaIndex: karanaIdx.clamped(to: 0...10),
            karanaName: Panchang.karanaNames[karanaIdx.clamped(to: 0...10)],
            weekdayName: weekdayNames[(weekday - 1).clamped(to: 0...6)],
            moonSignIndex: moonSignIdx,
            moonSignName: ZodiacSign.fromIndex(moonSignIdx).name,
            sunriseTime: sunriseTime,
            sunsetTime: sunsetTime,
            transitions: transitions
        )
    }

    static func karanaIndex(forHalfTithiIndex rawValue: Int) -> Int {
        let raw = rawValue.clamped(to: 0...59)
        if raw == 0 { return 10 } // Kimstughna
        if raw <= 56 { return (raw - 1) % 7 } // Bava…Vishti repeat eight times
        return raw - 50 // 57 Shakuni, 58 Chatushpada, 59 Naga
    }

    // MARK: - Panchang limb boundaries

    /// Solves the next boundary of every changing Panchang limb from an exact
    /// reference instant. Each angle is monotonic over the short search window,
    /// so a bracketed binary search gives sub-second numerical precision without
    /// coupling the result to the UI's refresh cadence.
    static func getPanchangTransitions(after date: Date) -> PanchangTransitions {
        PanchangTransitions(
            tithi: nextTransition(for: .tithi, after: date),
            nakshatra: nextTransition(for: .nakshatra, after: date),
            yoga: nextTransition(for: .yoga, after: date),
            karana: nextTransition(for: .karana, after: date)
        )
    }

    private struct LimbTransitionState {
        let angle: Double
        let segmentSize: Double
        let currentName: String
        let nextName: String
    }

    private static func nextTransition(
        for kind: PanchangLimbKind,
        after date: Date
    ) -> PanchangTransition? {
        let initial = limbTransitionState(for: kind, at: date)
        let remainder = initial.angle.truncatingRemainder(dividingBy: initial.segmentSize)
        let distanceToBoundary = remainder < 1e-10
            ? initial.segmentSize
            : initial.segmentSize - remainder

        func accumulatedAngle(at candidate: Date) -> Double {
            let angle = limbTransitionState(for: kind, at: candidate).angle
            return normalize360(angle - initial.angle)
        }

        var lower = date
        var upper = date.addingTimeInterval(36 * 3_600)
        while accumulatedAngle(at: upper) < distanceToBoundary,
              upper.timeIntervalSince(date) < 72 * 3_600 {
            upper = upper.addingTimeInterval(12 * 3_600)
        }
        guard accumulatedAngle(at: upper) >= distanceToBoundary else { return nil }

        for _ in 0..<56 {
            let midpoint = lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
            if accumulatedAngle(at: midpoint) >= distanceToBoundary {
                upper = midpoint
            } else {
                lower = midpoint
            }
        }

        return PanchangTransition(
            kind: kind,
            currentName: initial.currentName,
            nextName: initial.nextName,
            endTime: lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
        )
    }

    private static func limbTransitionState(
        for kind: PanchangLimbKind,
        at date: Date
    ) -> LimbTransitionState {
        let jd = julianDateFromDate(date)
        let sunSidereal = siderealize(sunLongitude(jd: jd), jd: jd)
        let moonSidereal = siderealize(moonLongitude(jd: jd), jd: jd)
        let elongation = normalize360(moonSidereal - sunSidereal)

        let angle: Double
        let segmentSize: Double
        let segmentCount: Int
        switch kind {
        case .tithi:
            angle = elongation
            segmentSize = 12
            segmentCount = 30
        case .nakshatra:
            angle = moonSidereal
            segmentSize = 360.0 / 27.0
            segmentCount = 27
        case .yoga:
            angle = normalize360(sunSidereal + moonSidereal)
            segmentSize = 360.0 / 27.0
            segmentCount = 27
        case .karana:
            angle = elongation
            segmentSize = 6
            segmentCount = 60
        }

        let rawIndex = Int(angle / segmentSize).clamped(to: 0...(segmentCount - 1))
        let nextRawIndex = (rawIndex + 1) % segmentCount
        let names: (current: String, next: String)
        switch kind {
        case .tithi:
            names = (Panchang.tithiNames[rawIndex], Panchang.tithiNames[nextRawIndex])
        case .nakshatra:
            names = (Panchang.nakshatraNames[rawIndex], Panchang.nakshatraNames[nextRawIndex])
        case .yoga:
            names = (Panchang.yogaNames[rawIndex], Panchang.yogaNames[nextRawIndex])
        case .karana:
            names = (
                Panchang.karanaNames[karanaIndex(forHalfTithiIndex: rawIndex)],
                Panchang.karanaNames[karanaIndex(forHalfTithiIndex: nextRawIndex)]
            )
        }

        return LimbTransitionState(
            angle: angle,
            segmentSize: segmentSize,
            currentName: names.current,
            nextName: names.next
        )
    }

    // MARK: - Sunrise / Sunset (NOAA / Meeus ch.15)

    /// Returns sunrise and sunset as UTC hour-of-day (e.g. 6.5 = 06:30 UTC)
    static func sunriseSunsetUTHours(year: Int, month: Int, day: Int,
                                     latDeg: Double, lonDeg: Double) -> (rise: Double, set: Double)? {
        let jd0 = julianDate(year: year, month: month, day: day, decimalHour: 0)
        let n   = jd0 - 2451545.0
        // Mean solar longitude and mean anomaly
        let L   = normalize360(280.460  + 0.9856474 * n)
        let gRad = normalize360(357.528 + 0.9856003 * n) * DEG
        // Ecliptic longitude
        let eclRad = normalize360(L + 1.915 * sin(gRad) + 0.020 * sin(2 * gRad)) * DEG
        // Solar declination
        let sinDec = sin(23.4393 * DEG) * sin(eclRad)
        let dec    = asin(sinDec)
        // Hour angle for apparent sunrise (−50' = refraction + disc radius)
        let cosH = (sin(-0.8333 * DEG) - sin(latDeg * DEG) * sin(dec)) /
                   (cos(latDeg * DEG) * cos(dec))
        guard abs(cosH) <= 1 else { return nil }   // polar day/night
        let H = acos(cosH) * RAD                   // degrees
        // Right ascension for equation of time
        let RA  = normalize360(atan2(cos(23.4393 * DEG) * sin(eclRad), cos(eclRad)) * RAD)
        let eqT = normalize180(L - RA) * 4.0      // minutes
        // Solar transit in UTC hours
        let noon = 12.0 - lonDeg / 15.0 - eqT / 60.0
        return (noon - H / 15.0, noon + H / 15.0)
    }

    /// Converts a fractional UTC hour on a given calendar day to a Date
    static func dateFromUTCHour(_ h: Double, year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = 0; comps.minute = 0; comps.second = 0; comps.timeZone = .gmt
        let midnight = calendar.date(from: comps) ?? Date(timeIntervalSince1970: 0)
        return midnight.addingTimeInterval(h * 3600.0)
    }

    // MARK: - 30 Muhurtas

    private static let muhurtaData: [(name: String, quality: MuhurtaQuality, purpose: String)] = [
        // Day muhurtas 1–15
        ("Rudra",           .inauspicious, "Avoid new beginnings; destructive energy"),
        ("Ahi (Sarpa)",     .inauspicious, "Inauspicious; serpentine delays likely"),
        ("Mitra",           .auspicious,   "Excellent for alliances, friendships, meetings"),
        ("Pitru",           .mixed,        "Suitable for ancestral rites and offerings"),
        ("Vasu",            .auspicious,   "Good for financial matters and prosperity"),
        ("Vara",            .mixed,        "Ceremonial work; moderate auspiciousness"),
        ("Vishvedeva",      .auspicious,   "Religious ceremonies and worship"),
        ("Vidhi",           .excellent,    "Excellent for learning, contracts, new work"),
        ("Satamukhi",       .inauspicious, "Avoid; scattered energy"),
        ("Puruhuta",        .auspicious,   "Indra's hour — powerful for important tasks"),
        ("Vahini",          .inauspicious, "Instability; avoid major decisions"),
        ("Naktanakara",     .inauspicious, "Avoid; hidden obstacles"),
        ("Varuna",          .mixed,        "Water ceremonies; moderate for travel"),
        ("Aryaman",         .auspicious,   "Marriage, partnerships, legal matters"),
        ("Bhaga",           .auspicious,   "Prosperity, enjoyment, material success"),
        // Night muhurtas 16–30
        ("Girisha",         .inauspicious, "Avoid activities; dark energy"),
        ("Ajapada",         .mixed,        "Spiritual practices; meditation"),
        ("Ahirbudhnya",     .mixed,        "Subtle energy work; introspection"),
        ("Pushya",          .excellent,    "Supremely auspicious for all purposes"),
        ("Ashwi",           .auspicious,   "Health, speed, travel, new ventures"),
        ("Yama",            .inauspicious, "Most inauspicious night muhurta; avoid all"),
        ("Agni",            .mixed,        "Fire ceremonies, purification rites"),
        ("Vidhaatru",       .mixed,        "Creative and artistic work"),
        ("Kanda",           .inauspicious, "Obstacles and delays; avoid"),
        ("Aditi",           .auspicious,   "New beginnings, freedom, expansion"),
        ("Jiva (Amrita)",   .excellent,    "Nectar of immortality — highly auspicious"),
        ("Vishnu",          .auspicious,   "Devotion, preservation, sustenance"),
        ("Dyumadgadyuti",   .auspicious,   "Brilliance, fame, success in endeavors"),
        ("Brahma",          .excellent,    "Highest wisdom; excellent for all purposes"),
        ("Samudraam",       .inauspicious, "Inauspicious; avoid important work"),
    ]

    /// Compute all 30 muhurtas for a civil day and explicit location context.
    /// Empty means sunrise/sunset is unavailable (for example polar day/night).
    static func getMuhurtas(context: CalculationContext) -> [Muhurta] {
        guard let today = getSunriseSunset(context: context),
              let tomorrow = getSunriseSunset(context: context.advancedByLocalDays(1)) else {
            return []
        }

        let sunrise = today.sunrise
        let sunset = today.sunset
        let nextSunrise = tomorrow.sunrise

        let dayDuration   = sunset.timeIntervalSince(sunrise)   / 15.0
        let nightDuration = nextSunrise.timeIntervalSince(sunset) / 15.0

        var results: [Muhurta] = []
        for i in 0..<15 {
            let start = sunrise.addingTimeInterval(Double(i) * dayDuration)
            let end   = start.addingTimeInterval(dayDuration)
            let data  = muhurtaData[i]
            results.append(Muhurta(id: i + 1, name: data.name, quality: data.quality,
                                   purpose: data.purpose, startTime: start, endTime: end, isDay: true))
        }
        for i in 0..<15 {
            let start = sunset.addingTimeInterval(Double(i) * nightDuration)
            let end   = start.addingTimeInterval(nightDuration)
            let data  = muhurtaData[i + 15]
            results.append(Muhurta(id: i + 16, name: data.name, quality: data.quality,
                                   purpose: data.purpose, startTime: start, endTime: end, isDay: false))
        }
        return results
    }

    static func getMuhurtas(date: Date, latDeg: Double, lonDeg: Double) -> [Muhurta] {
        getMuhurtas(context: CalculationContext(
            localDay: date,
            latitude: latDeg,
            longitude: lonDeg,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        ))
    }

    // MARK: - Public Convenience

    /// Returns the Moon's sidereal nakshatra and pada for a given date.
    static func getMoonNakshatraPada(date: Date) -> NakshatraResult {
        let jd = julianDateFromDate(date)
        return getNakshatraPada(siderealize(moonLongitude(jd: jd), jd: jd))
    }

    static func getMoonNakshatraPada(context: CalculationContext) -> NakshatraResult {
        getMoonNakshatraPada(date: panchangReferenceDate(for: context))
    }

    /// Returns sunrise and sunset as `Date` values for a given day and location.
    static func getSunriseSunset(context: CalculationContext) -> (sunrise: Date, sunset: Date)? {
        let components = context.localDayComponents
        guard let y = components.year, let m = components.month, let d = components.day,
              let ss = sunriseSunsetUTHours(
                year: y,
                month: m,
                day: d,
                latDeg: context.latitude,
                lonDeg: context.longitude
              ) else { return nil }
        return (dateFromUTCHour(ss.rise, year: y, month: m, day: d),
                dateFromUTCHour(ss.set, year: y, month: m, day: d))
    }

    static func getSunriseSunset(date: Date, latDeg: Double, lonDeg: Double) -> (sunrise: Date, sunset: Date)? {
        getSunriseSunset(context: CalculationContext(
            localDay: date,
            latitude: latDeg,
            longitude: lonDeg,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        ))
    }

    // MARK: - Sunrise-based daily observances

    /// Brahma Muhurta is the traditional 48-minute muhurta beginning two
    /// muhurtas before sunrise and ending one muhurta before sunrise.
    static func getBrahmaMuhurta(context: CalculationContext) -> (start: Date, end: Date)? {
        guard let sunrise = getSunriseSunset(context: context)?.sunrise else { return nil }
        return (
            start: sunrise.addingTimeInterval(-96 * 60),
            end: sunrise.addingTimeInterval(-48 * 60)
        )
    }

    /// Abhijit is the eighth of fifteen daylight muhurtas, centered on local
    /// apparent noon. It scales with daylight rather than assuming a fixed
    /// 48-minute clock interval. Classical daily Panchang practice does not
    /// present it as an auspicious window on Wednesday.
    static func getAbhijitMuhurta(context: CalculationContext) -> (start: Date, end: Date)? {
        guard context.localDayComponents.weekday != 4,
              let solar = getSunriseSunset(context: context) else {
            return nil
        }
        let daylight = solar.sunset.timeIntervalSince(solar.sunrise)
        let muhurtaLength = daylight / 15.0
        let solarNoon = solar.sunrise.addingTimeInterval(daylight / 2.0)
        return (
            start: solarNoon.addingTimeInterval(-muhurtaLength / 2.0),
            end: solarNoon.addingTimeInterval(muhurtaLength / 2.0)
        )
    }

    // MARK: - Choghadiya (Vedic day-segments)

    static func getChoghadiya(context: CalculationContext) -> [Choghadiya] {
        guard let today = getSunriseSunset(context: context),
              let tomorrow = getSunriseSunset(context: context.advancedByLocalDays(1)) else {
            return []
        }

        let sunrise = today.sunrise
        let sunset = today.sunset
        let nextSunrise = tomorrow.sunrise

        // 0=Sun … 6=Sat
        let wd = (context.localDayComponents.weekday ?? 1) - 1

        // Cycle: Udveg(0) Char(1) Labh(2) Amrit(3) Kaal(4) Shubh(5) Rog(6)
        let cycle: [ChoghadiyaQuality] = [.udveg, .char, .labh, .amrit, .kaal, .shubh, .rog]
        let dayStart:   [Int] = [0, 3, 6, 2, 5, 1, 4]  // day start index by weekday
        let nightStart: [Int] = [5, 1, 4, 0, 3, 6, 2]  // night start index by weekday

        let dayDur   = sunset.timeIntervalSince(sunrise) / 8.0
        let nightDur = nextSunrise.timeIntervalSince(sunset) / 8.0

        var out: [Choghadiya] = []
        for i in 0..<8 {
            let q = cycle[(dayStart[wd] + i) % 7]
            let s = sunrise.addingTimeInterval(Double(i) * dayDur)
            out.append(Choghadiya(id: i + 1, quality: q, startTime: s,
                                  endTime: s.addingTimeInterval(dayDur), isDay: true))
        }
        for i in 0..<8 {
            let q = cycle[(nightStart[wd] + i * 5) % 7]   // step –2 ≡ ×5 (mod 7)
            let s = sunset.addingTimeInterval(Double(i) * nightDur)
            out.append(Choghadiya(id: i + 9, quality: q, startTime: s,
                                  endTime: s.addingTimeInterval(nightDur), isDay: false))
        }
        return out
    }

    static func getChoghadiya(date: Date, latDeg: Double, lonDeg: Double) -> [Choghadiya] {
        getChoghadiya(context: CalculationContext(
            localDay: date,
            latitude: latDeg,
            longitude: lonDeg,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        ))
    }

    // MARK: - Hora (Planetary Hours, Chaldean cycle)

    static func getHora(context: CalculationContext) -> [Hora] {
        guard let today = getSunriseSunset(context: context),
              let tomorrow = getSunriseSunset(context: context.advancedByLocalDays(1)) else {
            return []
        }

        let sunrise = today.sunrise
        let sunset = today.sunset
        let nextSunrise = tomorrow.sunrise

        let wd = (context.localDayComponents.weekday ?? 1) - 1

        // Chaldean cycle: Sun Venus Mercury Moon Saturn Jupiter Mars
        let chal: [CelestialBody] = [.sun, .venus, .mercury, .moon, .saturn, .jupiter, .mars]
        // Day-lord start index per weekday (Sun=0 Mon=3 Tue=6 Wed=2 Thu=5 Fri=1 Sat=4)
        let lordIdx: [Int] = [0, 3, 6, 2, 5, 1, 4]
        let start = lordIdx[wd]

        let dayDur   = sunset.timeIntervalSince(sunrise) / 12.0
        let nightDur = nextSunrise.timeIntervalSince(sunset) / 12.0

        var out: [Hora] = []
        for i in 0..<12 {
            let planet = chal[(start + i) % 7]
            let s = sunrise.addingTimeInterval(Double(i) * dayDur)
            out.append(Hora(id: i + 1, planet: planet, startTime: s,
                            endTime: s.addingTimeInterval(dayDur), isDay: true))
        }
        for i in 0..<12 {
            let planet = chal[(start + 12 + i) % 7]
            let s = sunset.addingTimeInterval(Double(i) * nightDur)
            out.append(Hora(id: i + 13, planet: planet, startTime: s,
                            endTime: s.addingTimeInterval(nightDur), isDay: false))
        }
        return out
    }

    static func getHora(date: Date, latDeg: Double, lonDeg: Double) -> [Hora] {
        getHora(context: CalculationContext(
            localDay: date,
            latitude: latDeg,
            longitude: lonDeg,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        ))
    }

    // MARK: - Moonrise / Moonset prototype (not surfaced)

    /// Experimental approximation retained for research only. It is not
    /// topocentric and must not be wired into a shipping surface without the
    /// validation work listed in ACCURACY.md.
    static func getMoonriseMoonset(date: Date, latDeg: Double, lonDeg: Double) -> (moonrise: Date?, moonset: Date?) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2024, m = comps.month ?? 1, d = comps.day ?? 1

        let jd         = julianDate(year: y, month: m, day: d, decimalHour: 12.0)
        let moonLonRad = moonLongitude(jd: jd) * DEG
        let eps        = 23.4393 * DEG

        let sinDec = sin(eps) * sin(moonLonRad)
        let dec    = asin(sinDec)

        // Parallax-corrected altitude at rise/set ≈ +0.125° (Moon specific)
        let cosH = (sin(0.125 * DEG) - sin(latDeg * DEG) * sin(dec)) /
                   (cos(latDeg * DEG) * cos(dec))
        guard abs(cosH) <= 1 else { return (nil, nil) }

        let H       = acos(cosH) * RAD
        let transit = 12.0 - lonDeg / 15.0

        return (dateFromUTCHour(transit - H / 15.0, year: y, month: m, day: d),
                dateFromUTCHour(transit + H / 15.0, year: y, month: m, day: d))
    }

    // MARK: - Sun Nakshatra

    static func getSunNakshatra(date: Date) -> NakshatraResult {
        let jd = julianDateFromDate(date)
        return getNakshatraPada(siderealize(sunLongitude(jd: jd), jd: jd))
    }

    static func getSunNakshatra(context: CalculationContext) -> NakshatraResult {
        getSunNakshatra(date: panchangReferenceDate(for: context))
    }

    // MARK: - Tithi End Time

    static func getTithiEndTime(date: Date) -> Date? {
        nextTransition(for: .tithi, after: date)?.endTime
    }

    static func getTithiEndTime(context: CalculationContext) -> Date? {
        nextTransition(for: .tithi, after: panchangReferenceDate(for: context))?.endTime
    }

    // MARK: - Chandra Bala & Tara Bala

    struct TaraBalaResult {
        let position: Int           // 1–27 from birth nakshatra
        let taraNumber: Int         // 1–9
        let taraName: String
        let taraQuality: String     // "Auspicious" / "Inauspicious" / "Variable"
        let chandraBalaStrong: Bool  // strong Chandra Bala?
        let chandraBalaScore: String // "Strong" / "Weak"
    }

    static func getTaraBala(currentNakshatraIdx: Int, birthNakshatraIdx: Int) -> TaraBalaResult {
        let pos = ((currentNakshatraIdx - birthNakshatraIdx + 27) % 27) + 1

        // Chandra Bala: strong at positions 1, 3, 6, 7, 10, 11 (from birth nakshatra)
        let strongPositions: Set<Int> = [1, 3, 6, 7, 10, 11]
        let isStrong = strongPositions.contains(pos)

        // Tara: group positions into 9 taras of 3 nakshatras each
        let taraNum = ((pos - 1) % 9) + 1
        let taraNames = ["Janma", "Sampat", "Vipat", "Kshema", "Pratyak", "Sadhana", "Nidhan", "Mitra", "Parama Mitra"]
        let taraQualities = ["Variable", "Auspicious", "Inauspicious", "Auspicious", "Inauspicious",
                             "Auspicious", "Inauspicious", "Auspicious", "Most Auspicious"]
        return TaraBalaResult(
            position: pos,
            taraNumber: taraNum,
            taraName: taraNames[taraNum - 1],
            taraQuality: taraQualities[taraNum - 1],
            chandraBalaStrong: isStrong,
            chandraBalaScore: isStrong ? "Strong" : "Weak"
        )
    }

    // MARK: - Sunrise-based inauspicious kalas

    /// Rahu Kala, Yamaganda, and Gulika Kala are weekday-specific selections
    /// from eight equal daylight divisions. Keeping the tables in the engine
    /// prevents presentation code from inventing clock-time fallbacks.
    static func getRahuKala(context: CalculationContext) -> (start: Date, end: Date)? {
        let slots = [8, 2, 7, 5, 6, 4, 3] // Sunday through Saturday
        return daylightKala(context: context, slotsByWeekday: slots)
    }

    static func getYamaganda(context: CalculationContext) -> (start: Date, end: Date)? {
        let slots = [5, 4, 3, 2, 1, 7, 6] // Sunday through Saturday
        return daylightKala(context: context, slotsByWeekday: slots)
    }

    static func getGulikaKala(context: CalculationContext) -> (start: Date, end: Date)? {
        let slots = [7, 6, 5, 4, 3, 2, 1] // Sunday through Saturday
        return daylightKala(context: context, slotsByWeekday: slots)
    }

    private static func daylightKala(
        context: CalculationContext,
        slotsByWeekday: [Int]
    ) -> (start: Date, end: Date)? {
        guard slotsByWeekday.count == 7,
              let weekday = context.localDayComponents.weekday,
              (1...7).contains(weekday),
              let solar = getSunriseSunset(context: context) else {
            return nil
        }
        let slotLength = solar.sunset.timeIntervalSince(solar.sunrise) / 8.0
        let slot = slotsByWeekday[weekday - 1]
        let start = solar.sunrise.addingTimeInterval(Double(slot - 1) * slotLength)
        return (start: start, end: start.addingTimeInterval(slotLength))
    }

    /// Returns the classically inauspicious Dur Muhurta windows for the Vedic day.
    /// Indices are zero-based within the 15 daylight or 15 night divisions.
    /// Tuesday's second period is a night division; treating every weekday entry
    /// as a daylight slot produces a plausible but materially wrong result.
    static func getDurMuhurta(context: CalculationContext) -> [(start: Date, end: Date, label: String)] {
        guard let today = getSunriseSunset(context: context),
              let tomorrow = getSunriseSunset(context: context.advancedByLocalDays(1)) else {
            return []
        }
        let daySlotLength = today.sunset.timeIntervalSince(today.sunrise) / 15.0
        let nightSlotLength = tomorrow.sunrise.timeIntervalSince(today.sunset) / 15.0

        // Weekday from Calendar (1=Sun…7=Sat)
        let wd = context.localDayComponents.weekday ?? 1
        let daySlots: [Int]
        let nightSlots: [Int]
        switch wd {
        case 1: (daySlots, nightSlots) = ([13], [])
        case 2: (daySlots, nightSlots) = ([8, 11], [])
        case 3: (daySlots, nightSlots) = ([3], [6])
        case 4: (daySlots, nightSlots) = ([7], [])
        case 5: (daySlots, nightSlots) = ([5, 11], [])
        case 6: (daySlots, nightSlots) = ([3, 8], [])
        case 7: (daySlots, nightSlots) = ([0, 1], [])
        default: (daySlots, nightSlots) = ([], [])
        }

        var periods = daySlots.map { index in
            let start = today.sunrise.addingTimeInterval(Double(index) * daySlotLength)
            return (start: start, end: start.addingTimeInterval(daySlotLength), label: "")
        }
        periods += nightSlots.map { index in
            let start = today.sunset.addingTimeInterval(Double(index) * nightSlotLength)
            return (start: start, end: start.addingTimeInterval(nightSlotLength), label: "")
        }
        periods.sort { $0.start < $1.start }
        return periods.enumerated().map { index, period in
            (
                start: period.start,
                end: period.end,
                label: periods.count == 1 ? "Dur Muhurta" : (index == 0 ? "1st" : "2nd")
            )
        }
    }

    static func getDurMuhurta(date: Date, latDeg: Double, lonDeg: Double) -> [(start: Date, end: Date, label: String)] {
        getDurMuhurta(context: CalculationContext(
            localDay: date,
            latitude: latDeg,
            longitude: lonDeg,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        ))
    }

    // MARK: - Vedic Calendar Extended Info prototype (not surfaced)

    static func getVedicCalendarInfo(date: Date, latDeg: Double, lonDeg: Double,
                                     birthNakshatraIndex: Int = -1) -> VedicCalendarInfo {
        let jd       = julianDateFromDate(date)
        let sunSid   = siderealize(sunLongitude(jd: jd), jd: jd)
        let sunSignIdx = Int(sunSid / 30) % 12

        // ── Vikram Samvat & Shaka Samvat ───────────────────────────────────
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .gmt
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let ceYear = c.year ?? 2026, month = c.month ?? 1

        // New year (Chaitra Shukla Pratipada) falls in March-April; use month>=4
        let vs = ceYear + (month >= 4 ? 57 : 56)
        let shaka = ceYear - (month >= 4 ? 78 : 79)

        // ── Lunar Month (Amanta) ────────────────────────────────────────────
        // Approximate: the Amanta masa name matches the Sun's sidereal sign
        let masaNames = ["Chaitra","Vaishakha","Jyeshtha","Ashadha","Shravana",
                         "Bhadrapada","Ashwina","Kartika","Margashirsha","Pausha","Magha","Phalguna"]
        let amanta = masaNames[sunSignIdx]
        // Purnimanta shifts masa name by +1 during Shukla Paksha (tithis 1-14)
        let p = getPanchang(date: date)
        let purnimanta: String
        if p.tithiIndex < 15 {
            purnimanta = masaNames[(sunSignIdx + 1) % 12]
        } else {
            purnimanta = amanta
        }

        // ── Vedic Ritu (sidereal season) ───────────────────────────────────
        let rituNames  = ["Vasanta","Vasanta","Grishma","Grishma","Varsha","Varsha",
                          "Sharad","Sharad","Hemanta","Hemanta","Shishira","Shishira"]
        let drikNames  = ["Spring","Spring","Summer","Summer","Monsoon","Monsoon",
                          "Autumn","Autumn","Pre-winter","Pre-winter","Winter","Winter"]
        let vedaRitu   = rituNames[sunSignIdx]
        let drikRitu   = drikNames[sunSignIdx]

        // ── Ayana (based on sidereal Sun) ──────────────────────────────────
        // Uttarayan: Sun in Makara(9) through Mithuna(2); Dakshinayan: Karka(3) through Dhanu(8)
        let ayana = (sunSignIdx >= 3 && sunSignIdx <= 8) ? "Dakshinayan" : "Uttarayan"

        // ── Anandadi Yoga ──────────────────────────────────────────────────
        // Formula: (weekday_idx + nakshatra_idx) % 9, Sun=0
        let weekdayIdx = (Calendar.current.component(.weekday, from: date) - 1) // 0=Sun
        let nakIdx     = p.nakshatraIndex
        let anandIdx   = (weekdayIdx + nakIdx) % 9
        let anandNames = ["Ananda","Kala","Dhvamsa","Saumya","Mitra","Parama Mitra",
                          "Adhamadha","Krodha","Nandana"]
        let anandMean  = ["Joy & happiness — excellent","Death-like — avoid important work",
                          "Destructive energy — inauspicious","Gentle & calm — auspicious",
                          "Friendly — good for alliances","Supreme friendship — highly auspicious",
                          "Mixed results — medium quality","Anger & conflict — inauspicious",
                          "Bliss — auspicious"]
        let anandaSpicious = [0,3,4,5,8].contains(anandIdx)

        // ── Amrit Kaal (from Amrit Choghadiya) ───────────────────────────
        let choghadiyas = getChoghadiya(date: date, latDeg: latDeg, lonDeg: lonDeg)
        // Find first upcoming (or current) Amrit choghadiya today
        let now = Date()
        let amritChog = choghadiyas.first { $0.quality == .amrit && $0.endTime > now }
        let amritStart = amritChog?.startTime
        let amritEnd   = amritChog?.endTime

        // ── Chandrashtama ─────────────────────────────────────────────────
        var chandrashtama = ""
        var isChandrashtama = false
        if birthNakshatraIndex >= 0 {
            let cIdx = (birthNakshatraIndex + 7) % 27
            chandrashtama = Panchang.nakshatraNames[cIdx]
            isChandrashtama = (p.nakshatraIndex == cIdx)
        }

        return VedicCalendarInfo(
            vikramSamvat: vs, shakaSamvat: shaka,
            amantaMasa: amanta, purnimantaMasa: purnimanta,
            ayana: ayana, vedaRitu: vedaRitu, drikRitu: drikRitu,
            anandadiYoga: anandNames[anandIdx],
            anandadiIsAuspicious: anandaSpicious,
            anandadiMeaning: anandMean[anandIdx],
            amritKaalStart: amritStart, amritKaalEnd: amritEnd,
            chandrashtamaNakshatra: chandrashtama,
            isCurrentlyChandrashtama: isChandrashtama
        )
    }

    // MARK: - Nine Graha Positions prototype (not surfaced; low precision)

    private enum PlanetID { case mercury, venus, mars, jupiter, saturn }

    private struct OrbitalElements {
        let N, i, w, a, e, M: Double
    }

    private static func orbEl(_ p: PlanetID, d: Double) -> OrbitalElements {
        switch p {
        case .mercury: return OrbitalElements(N: 48.3313 + 3.24587e-5*d,  i: 7.0047 + 5.00e-8*d,
                                               w: 29.1241 + 1.01444e-5*d,  a: 0.387098,
                                               e: 0.205635 + 5.59e-10*d,   M: 168.6562 + 4.0923344368*d)
        case .venus:   return OrbitalElements(N: 76.6799 + 2.46590e-5*d,   i: 3.3946 + 2.75e-8*d,
                                               w: 54.8910 + 1.38374e-5*d,   a: 0.723330,
                                               e: 0.006773 - 1.302e-9*d,    M: 48.0052 + 1.6021302244*d)
        case .mars:    return OrbitalElements(N: 49.5574 + 2.11081e-5*d,   i: 1.8497 - 1.78e-8*d,
                                               w: 286.5016 + 2.92961e-5*d,  a: 1.523688,
                                               e: 0.093405 + 2.516e-9*d,    M: 18.6021 + 0.5240207766*d)
        case .jupiter: return OrbitalElements(N: 100.4542 + 2.76854e-5*d,  i: 1.3030 - 1.557e-7*d,
                                               w: 273.8777 + 1.64505e-5*d,  a: 5.20256,
                                               e: 0.048498 + 4.469e-9*d,    M: 19.8950 + 0.0830853001*d)
        case .saturn:  return OrbitalElements(N: 113.6634 + 2.38980e-5*d,  i: 2.4886 - 1.081e-7*d,
                                               w: 339.3939 + 2.97661e-5*d,  a: 9.55475,
                                               e: 0.055546 - 9.499e-9*d,    M: 316.9670 + 0.0334442282*d)
        }
    }

    private static func keplerE(M_deg: Double, e: Double) -> Double {
        let π = Double.pi
        let M = normalize360(M_deg) * π / 180
        var E = M + e * sin(M) * (1 + e * cos(M))
        E = E - (E - e * sin(E) - M) / (1 - e * cos(E))
        return E * 180 / π
    }

    private static func earthHelio(d: Double) -> (x: Double, y: Double) {
        let e = 0.016709 - 1.151e-9 * d
        let M = normalize360(356.0470 + 0.9856002585 * d)
        let w = (282.9404 + 4.70935e-5 * d) * Double.pi / 180
        let E = keplerE(M_deg: M, e: e) * Double.pi / 180
        let r = sqrt(pow(cos(E) - e, 2) + pow(sqrt(1 - e*e) * sin(E), 2))
        let v = atan2(sqrt(1 - e*e) * sin(E), cos(E) - e)
        let lon = v + w
        return (x: r * cos(lon), y: r * sin(lon))
    }

    private static func geocentricTropical(_ p: PlanetID, d: Double) -> Double {
        let el = orbEl(p, d: d)
        let N = normalize360(el.N) * Double.pi / 180
        let i = el.i * Double.pi / 180
        let w = normalize360(el.w) * Double.pi / 180
        let e = el.e
        let E_rad = keplerE(M_deg: el.M, e: e) * Double.pi / 180

        let xv = el.a * (cos(E_rad) - e)
        let yv = el.a * sqrt(1 - e * e) * sin(E_rad)
        let v  = atan2(yv, xv)
        let r  = sqrt(xv * xv + yv * yv)

        let xh = r * (cos(N) * cos(v + w) - sin(N) * sin(v + w) * cos(i))
        let yh = r * (sin(N) * cos(v + w) + cos(N) * sin(v + w) * cos(i))

        let earth = earthHelio(d: d)
        return normalize360(atan2(yh - earth.y, xh - earth.x) * 180 / Double.pi)
    }

    static func getGrahaPositions(date: Date) -> [GrahaPosition] {
        let jd = julianDateFromDate(date)
        let d  = jd - 2451543.5  // Schlyter epoch offset

        func retro(_ today: Double, _ tomorrow: Double) -> Bool {
            let delta = normalize360(tomorrow - today)
            return delta > 180  // retrograde if "forward" arc > 180° → actually moved backward
        }

        let sunTrop     = sunLongitude(jd: jd)
        let moonTrop    = moonLongitude(jd: jd)
        let merTrop     = geocentricTropical(.mercury, d: d)
        let venTrop     = geocentricTropical(.venus,   d: d)
        let marTrop     = geocentricTropical(.mars,    d: d)
        let jupTrop     = geocentricTropical(.jupiter, d: d)
        let satTrop     = geocentricTropical(.saturn,  d: d)
        let N_moon      = normalize360(125.1228 - 0.0529538083 * d)
        let rahuTrop    = N_moon
        let ketuTrop    = normalize360(rahuTrop + 180)

        // Day-ahead for retrograde detection
        let dN = d + 1
        let merR = retro(merTrop, geocentricTropical(.mercury, d: dN))
        let venR = retro(venTrop, geocentricTropical(.venus,   d: dN))
        let marR = retro(marTrop, geocentricTropical(.mars,    d: dN))
        let jupR = retro(jupTrop, geocentricTropical(.jupiter, d: dN))
        let satR = retro(satTrop, geocentricTropical(.saturn,  d: dN))

        func make(_ body: CelestialBody, _ tropical: Double, _ retrograde: Bool) -> GrahaPosition {
            let sid  = siderealize(tropical, jd: jd)
            let sIdx = Int(sid / 30) % 12
            let sign = ZodiacSign.fromIndex(sIdx)
            return GrahaPosition(body: body, siderealDegree: sid,
                                 signIndex: sIdx, signName: sign.name, signSymbol: sign.symbol,
                                 degreeInSign: sid.truncatingRemainder(dividingBy: 30),
                                 isRetrograde: retrograde)
        }

        return [
            make(.sun,     sunTrop,  false),
            make(.moon,    moonTrop, false),
            make(.mars,    marTrop,  marR),
            make(.mercury, merTrop,  merR),
            make(.jupiter, jupTrop,  jupR),
            make(.venus,   venTrop,  venR),
            make(.saturn,  satTrop,  satR),
            make(.rahu,    rahuTrop, true),
            make(.ketu,    ketuTrop, true),
        ]
    }

    // MARK: - Helpers

    static func normalize360(_ deg: Double) -> Double {
        var d = deg.truncatingRemainder(dividingBy: 360)
        if d < 0 { d += 360 }
        return d
    }

    static func normalize180(_ deg: Double) -> Double {
        let normalized = normalize360(deg)
        return normalized > 180 ? normalized - 360 : normalized
    }

    private static func siderealize(_ tropical: Double, jd: Double) -> Double {
        let year = 2000.0 + (jd - J2000) / 365.25
        return normalize360(tropical - lahiriAyanamsha(year: year))
    }
}
