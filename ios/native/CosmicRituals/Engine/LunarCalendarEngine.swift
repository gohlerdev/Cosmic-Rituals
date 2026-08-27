import Foundation

// MARK: - Lunar calendar: Sankranti, masa (Amanta/Purnimanta), Adhika, years
//
// This REPLACES the quarantined getVedicCalendarInfo approximation (which
// guessed the masa from the sun sign and switched years at a Gregorian
// month boundary) with the real construction:
//  - Sankranti = the instant the SIDEREAL (Lahiri) Sun enters a rashi,
//    solved by bisection on the same five-limb apparent longitude.
//  - A lunation runs new moon to new moon (elongation 0), solved the same
//    way; the Amanta masa is named by the sankranti falling inside it
//    (Mesha -> Chaitra ... Mina -> Phalguna), a lunation with NO sankranti
//    is Adhika and borrows the following masa's name, and one with two is
//    the rare Kshaya.
//  - Vikram and Shaka years increment at Chaitra Shukla Pratipada (the
//    dominant North-Indian anchor; Gujarat's Kartika-anchored Vikram
//    variant is a named divergence, not implemented).
//  - Purnimanta months run full moon to full moon: during Krishna paksha
//    the Purnimanta month already carries the NEXT Amanta name.
// Fixtures against published 2026 calendars pin the sankranti instants,
// the masa containing a known date, the Adhika determination, and both
// year numbers; see LunarCalendarTests and ACCURACY.md.

struct LunarMonthInfo: Equatable {
    /// 0 = Chaitra ... 11 = Phalguna.
    let amantaMasaIndex: Int
    let isAdhika: Bool
    /// True for the rare Kshaya month (two sankrantis in one lunation).
    let isKshaya: Bool
    let pakshaIsShukla: Bool
    /// The lunation's bounds (new-moon instants).
    let monthStart: Date
    let monthEnd: Date
    let vikramYear: Int
    let shakaYear: Int

    var amantaMasaName: String {
        (isAdhika ? "Adhika " : "") + LunarCalendarEngine.masaNames[amantaMasaIndex]
    }

    /// Purnimanta reckoning: Krishna paksha belongs to the FOLLOWING name.
    var purnimantaMasaName: String {
        if pakshaIsShukla { return amantaMasaName }
        let next = (amantaMasaIndex + (isAdhika ? 0 : 1)) % 12
        return (isAdhika ? "Adhika " : "") + LunarCalendarEngine.masaNames[isAdhika ? amantaMasaIndex : next]
    }

    var pakshaName: String { pakshaIsShukla ? "Shukla Paksha" : "Krishna Paksha" }
}

enum LunarCalendarEngine {

    static let masaNames = [
        "Chaitra", "Vaishakha", "Jyeshtha", "Ashadha", "Shravana", "Bhadrapada",
        "Ashwina", "Kartika", "Margashirsha", "Pausha", "Magha", "Phalguna",
    ]

    // MARK: Sidereal solar longitude and Sun-Moon elongation

    static func siderealSunDegrees(at date: Date) -> Double {
        let jd = CosmicEngine.julianDateFromDate(date)
        return CosmicEngine.siderealize(CosmicEngine.sunLongitude(jd: jd), jd: jd)
    }

    static func elongationDegrees(at date: Date) -> Double {
        let jd = CosmicEngine.julianDateFromDate(date)
        return CosmicEngine.normalize360(
            CosmicEngine.moonLongitude(jd: jd) - CosmicEngine.sunLongitude(jd: jd)
        )
    }

    /// Signed smallest angular difference a - b in (-180, 180].
    private static func signedDelta(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d <= -180 { d += 360 }
        return d
    }

    /// Bisection for the instant a monotonically increasing angle crosses
    /// `target`, given a bracket where the signed delta changes sign from
    /// negative to positive.
    private static func solveCrossing(
        target: Double,
        lower initialLower: Date,
        upper initialUpper: Date,
        angle: (Date) -> Double
    ) -> Date {
        var lower = initialLower
        var upper = initialUpper
        for _ in 0..<56 {
            let midpoint = lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
            if signedDelta(angle(midpoint), target) >= 0 {
                upper = midpoint
            } else {
                lower = midpoint
            }
        }
        return lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
    }

    // MARK: Sankranti

    /// The next sankranti at or after `date`: the instant the sidereal Sun
    /// enters the next rashi, and that rashi's index (0 = Mesha).
    static func nextSankranti(after date: Date) -> (instant: Date, rashiIndex: Int) {
        let current = siderealSunDegrees(at: date)
        let targetRashi = (Int(current / 30) + 1) % 12
        let target = Double(targetRashi) * 30
        // The Sun covers at most 30 degrees in ~32 days; bracket day-by-day.
        var lower = date
        var upper = date.addingTimeInterval(86_400)
        for _ in 0..<40 {
            if signedDelta(siderealSunDegrees(at: upper), target) >= 0 { break }
            lower = upper
            upper = upper.addingTimeInterval(86_400)
        }
        let instant = solveCrossing(target: target, lower: lower, upper: upper, angle: siderealSunDegrees(at:))
        return (instant, targetRashi)
    }

    // MARK: New moons (lunation bounds)

    /// The next instant of elongation 0 (new moon end / amavasya end) at or
    /// after `date`.
    static func nextNewMoon(after date: Date) -> Date {
        var lower = date
        var upper = date.addingTimeInterval(86_400)
        var previous = elongationDegrees(at: date)
        for _ in 0..<35 {
            let value = elongationDegrees(at: upper)
            if value < previous { break }  // wrapped past 360
            previous = value
            lower = upper
            upper = upper.addingTimeInterval(86_400)
        }
        return solveCrossing(target: 0, lower: lower, upper: upper, angle: elongationDegrees(at:))
    }

    /// The last elongation-0 instant strictly before `date`.
    static func previousNewMoon(before date: Date) -> Date {
        // A lunation is at most ~29.9 days; start comfortably before it.
        let probe = date.addingTimeInterval(-31 * 86_400)
        var newMoon = nextNewMoon(after: probe)
        // Advance while the following new moon is still before `date`.
        for _ in 0..<3 {
            let next = nextNewMoon(after: newMoon.addingTimeInterval(3_600))
            if next < date {
                newMoon = next
            } else {
                break
            }
        }
        return newMoon
    }

    // MARK: Masa

    /// Masa index (0 = Chaitra) for a lunation, from the rashi the Sun
    /// enters inside it: Mesha -> Chaitra, Vrishabha -> Vaishakha, ...
    /// Fixture-pinned against published 2026 calendars.
    static func masaIndex(forSankrantiRashi rashi: Int) -> Int {
        ((rashi % 12) + 12) % 12
    }

    /// Sankrantis strictly inside (start, end].
    private static func sankrantis(from start: Date, to end: Date) -> [(instant: Date, rashiIndex: Int)] {
        var result: [(Date, Int)] = []
        var cursor = start
        for _ in 0..<3 {
            let next = nextSankranti(after: cursor.addingTimeInterval(60))
            guard next.instant <= end else { break }
            result.append(next)
            cursor = next.instant
        }
        return result
    }

    /// The lunation containing `date`, classified.
    private static func lunation(containing date: Date) -> (start: Date, end: Date, masa: Int, adhika: Bool, kshaya: Bool) {
        let start = previousNewMoon(before: date)
        let end = nextNewMoon(after: start.addingTimeInterval(3_600))
        let crossings = sankrantis(from: start, to: end)
        if crossings.isEmpty {
            // Adhika: borrows the FOLLOWING masa's name (Adhika Jyeshtha
            // precedes Nija Jyeshtha).
            let following = nextSankranti(after: end)
            return (start, end, masaIndex(forSankrantiRashi: following.rashiIndex), true, false)
        }
        let masa = masaIndex(forSankrantiRashi: crossings[0].rashiIndex)
        return (start, end, masa, false, crossings.count > 1)
    }

    // MARK: Public entry

    static func monthInfo(context: CalculationContext) -> LunarMonthInfo {
        let reference = CosmicEngine.panchangReferenceDate(for: context)
        let current = lunation(containing: reference)
        let panchang = CosmicEngine.getPanchang(context: context)
        let shukla = panchang.tithiIndex < 15

        // Walk back to Chaitra Shukla Pratipada (the start of the current
        // lunar year): step lunation by lunation until the previous one is
        // a non-adhika Chaitra whose start is at or before the reference.
        var yearStart = current.start
        var probe = current
        for _ in 0..<14 {
            if probe.masa == 0 && !probe.adhika { yearStart = probe.start; break }
            probe = lunation(containing: probe.start.addingTimeInterval(-3_600))
            yearStart = probe.start
        }
        var calendar = context.calendar
        calendar.timeZone = context.timeZone
        let anchorYear = calendar.component(.year, from: yearStart)

        return LunarMonthInfo(
            amantaMasaIndex: current.masa,
            isAdhika: current.adhika,
            isKshaya: current.kshaya,
            pakshaIsShukla: shukla,
            monthStart: current.start,
            monthEnd: current.end,
            // Vikram Samvat = CE + 57 and Shaka = CE - 78 counted from the
            // Chaitra Shukla Pratipada of the lunar year (North-Indian
            // anchor; Gujarat's Kartika-anchored Vikram variant is a named
            // divergence, disclosed in ACCURACY.md, not implemented).
            vikramYear: anchorYear + 57,
            shakaYear: anchorYear - 78
        )
    }

    /// Ayana from the sidereal Sun (the Makar-Sankranti tradition):
    /// Uttarayana from Makara through Mithuna, Dakshinayana from Karka
    /// through Dhanu. Drik-style tropical solstice ayana is a named
    /// divergence, not implemented.
    static func ayanaName(context: CalculationContext) -> String {
        let sun = siderealSunDegrees(at: CosmicEngine.panchangReferenceDate(for: context))
        let rashi = Int(sun / 30) % 12
        return (3...8).contains(rashi) ? "Dakshinayana" : "Uttarayana"
    }
}
