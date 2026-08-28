import Foundation

// MARK: - Regional solar months: Tamil, Malayali, Bengal, Odia reckonings
//
// The lunisolar Amanta/Purnimanta masa the app already computes is not how
// Tamil Nadu, Kerala, Bengal, or Odisha name their months: those regions run
// SOLAR months, each beginning at a sankranti, and they differ precisely in
// WHICH CIVIL DAY a month begins when the sankranti falls at an awkward hour.
//
// The four rules are implemented exactly as formalized by Dershowitz &
// Reingold, "Indian Calendrical Calculations" (eqs. 25-28), cross-checked
// against the Sewell & Dikshit tradition they cite:
//
//  - ORISSA rule (also Punjab, Haryana): "the solar month is determined by
//    the stellar position of the sun the following morning" -- the month
//    begins on the Hindu civil day (sunrise to sunrise) CONTAINING the
//    sankranti, whatever its hour.
//  - TAMIL rule: "sunset of the current day is used" -- sankranti before
//    sunset begins the month that day; after sunset, the next day.
//  - MALAYALI (Kerala) rule: the critical moment is sunrise + 3/5 of the
//    daylight ("1:12 p.m. seasonal time" -- the end of aparahna).
//  - BENGAL rule (also Assam, Tripura): "midnight at the start of the civil
//    day is usually used" -- the month begins the civil day AFTER the
//    sankranti's day -- "unless the zodiac sign changes between 11:36 p.m.
//    and 12:24 a.m. (temporal time), in which case various special rules
//    apply, depending on the month and on the day of the week."
//
// THREE DISCLOSED LIMITS:
//  1. The Bengal special zone's month-and-weekday sub-rules are not published
//     in the consulted source. A sankranti inside that window is therefore
//     FLAGGED as a boundary case with both candidate days implied, never
//     silently resolved.
//  2. Bangladesh's reformed civil calendar (fixed month lengths; Pohela
//     Boishakh pinned to 14 April) is a different construction from the
//     astronomical Bengal rule implemented here, which matches the West
//     Bengal traditional reckoning (Pohela Boishakh 15 April 2026).
//  3. Day-1 determination inherits the sankranti solver's disclosed
//     +/-60-minute envelope: when the solved instant lies within that margin
//     of the rule's critical moment, the result is flagged rather than
//     presented as certain. Kerala tradition also historically uses its own
//     critical longitude; this app computes every reckoning from its single
//     disclosed Lahiri chokepoint.
//
// Month names verified per region (all begin at Mesha): Tamil Chithirai...,
// Malayalam Medam... (Kollam year increments at Chingam 1), Bengali
// Boishakh... (San = CE-593 after Pohela Boishakh), Odia Baisakha... (Pana
// Sankranti = Mesha). Tamil's 60-year name cycle and Odisha's anka year are
// not implemented (unverified here) and are named as absent.

struct RegionalSolarMonth: Equatable {
    let rule: RegionalSolarRule
    /// 0 = the month beginning at Mesha sankranti.
    let monthIndex: Int
    let monthName: String
    /// First civil day of the month, as local noon of that day.
    let monthStart: Date
    /// 1-based day of the solar month at the context's civil day.
    let dayOfMonth: Int
    /// Era year where one is verified (Kollam, Bengali San); nil otherwise.
    let eraYear: Int?
    let eraName: String?
    /// True when the sankranti fell inside Bengal's 23:36-00:24 temporal
    /// window, whose sub-rules the consulted source does not publish.
    let isBengalBoundaryCase: Bool
    /// True when the solved sankranti lies within the solver's +/-60-minute
    /// envelope of this rule's critical moment, so the day-1 call could flip.
    let isWithinSolverMarginOfBoundary: Bool
}

enum RegionalSolarRule: String, CaseIterable, Identifiable {
    case orissa
    case tamil
    case malayali
    case bengal

    var id: String { rawValue }

    var regionTitle: String {
        switch self {
        case .orissa: return "Odisha"
        case .tamil: return "Tamil Nadu"
        case .malayali: return "Kerala"
        case .bengal: return "Bengal"
        }
    }

    var ruleSummary: String {
        switch self {
        case .orissa: return "Month begins on the sunrise-to-sunrise day containing the sankranti"
        case .tamil: return "Sankranti before sunset begins the month that day; after sunset, the next day"
        case .malayali: return "Critical moment is sunrise plus three-fifths of the daylight"
        case .bengal: return "Month begins the civil day after the sankranti"
        }
    }

    var monthNames: [String] {
        switch self {
        case .orissa:
            return ["Baisakha", "Jyestha", "Ashadha", "Shravana", "Bhadraba", "Ashwina",
                    "Kartika", "Margashira", "Pausha", "Magha", "Phalguna", "Chaitra"]
        case .tamil:
            return ["Chithirai", "Vaikasi", "Aani", "Aadi", "Aavani", "Purattasi",
                    "Aippasi", "Karthigai", "Margazhi", "Thai", "Maasi", "Panguni"]
        case .malayali:
            return ["Medam", "Edavam", "Mithunam", "Karkidakam", "Chingam", "Kanni",
                    "Thulam", "Vrischikam", "Dhanu", "Makaram", "Kumbham", "Meenam"]
        case .bengal:
            return ["Boishakh", "Joishtho", "Asharh", "Shrabon", "Bhadro", "Ashshin",
                    "Kartik", "Ogrohayon", "Poush", "Magh", "Falgun", "Choitro"]
        }
    }
}

enum RegionalSolarCalendarEngine {

    /// The margin inside which a day-1 call is flagged: the sankranti
    /// solver's disclosed comparison envelope.
    static let solverMarginSeconds: TimeInterval = 60 * 60

    // MARK: Critical moments

    /// The rule's critical moment on the Hindu civil day that contains the
    /// sankranti. Nil where sunrise does not exist -- no reckoning is
    /// fabricated at polar latitudes, matching the rest of the app.
    static func criticalMoment(
        rule: RegionalSolarRule,
        sankranti: Date,
        context: CalculationContext
    ) -> Date? {
        guard let day = hinduCivilDay(containing: sankranti, location: context),
              let solar = CosmicEngine.getSunriseSunset(context: day) else { return nil }
        switch rule {
        case .orissa:
            // The whole sunrise-to-sunrise day qualifies: the critical moment
            // is the NEXT sunrise.
            guard let next = CosmicEngine.getSunriseSunset(context: day.advancedByLocalDays(1)) else { return nil }
            return next.sunrise
        case .tamil:
            return solar.sunset
        case .malayali:
            let daylight = solar.sunset.timeIntervalSince(solar.sunrise)
            return solar.sunrise.addingTimeInterval(daylight * 3 / 5)
        case .bengal:
            // Civil midnight at the end of the sankranti's GREGORIAN day.
            var calendar = context.calendar
            calendar.timeZone = context.timeZone
            let startOfDay = calendar.startOfDay(for: sankranti)
            return calendar.date(byAdding: .day, value: 1, to: startOfDay)
        }
    }

    /// The context whose sunrise-to-sunrise Hindu day contains `instant`.
    private static func hinduCivilDay(
        containing instant: Date,
        location context: CalculationContext
    ) -> CalculationContext? {
        let onDay = CalculationContext(
            localDay: instant,
            latitude: context.latitude,
            longitude: context.longitude,
            timeZoneIdentifier: context.timeZoneIdentifier
        )
        guard let solar = CosmicEngine.getSunriseSunset(context: onDay) else { return nil }
        return instant >= solar.sunrise ? onDay : onDay.advancedByLocalDays(-1)
    }

    /// First civil day of the month begun by `sankranti`, as a context.
    static func firstDay(
        rule: RegionalSolarRule,
        sankranti: Date,
        context: CalculationContext
    ) -> CalculationContext? {
        guard let day = hinduCivilDay(containing: sankranti, location: context),
              let critical = criticalMoment(rule: rule, sankranti: sankranti, context: context) else {
            return nil
        }
        switch rule {
        case .orissa:
            return day
        case .tamil, .malayali:
            return sankranti <= critical ? day : day.advancedByLocalDays(1)
        case .bengal:
            // The day whose midnight-start follows the sankranti: the
            // Gregorian day after the sankranti's, anchored to local noon.
            var calendar = context.calendar
            calendar.timeZone = context.timeZone
            let nextDayNoon = calendar.date(
                byAdding: .day, value: 1,
                to: calendar.startOfDay(for: sankranti)
            )?.addingTimeInterval(12 * 3_600)
            guard let nextDayNoon else { return nil }
            return CalculationContext(
                localDay: nextDayNoon,
                latitude: context.latitude,
                longitude: context.longitude,
                timeZoneIdentifier: context.timeZoneIdentifier
            )
        }
    }

    /// Bengal's unpublished special zone: apparent midnight +/- 24 temporal
    /// minutes (11:36 p.m. to 12:24 a.m. temporal time), where a temporal
    /// minute is 1/720 of the night.
    static func isInBengalBoundaryZone(sankranti: Date, context: CalculationContext) -> Bool {
        guard let day = hinduCivilDay(containing: sankranti, location: context),
              let today = CosmicEngine.getSunriseSunset(context: day),
              let tomorrow = CosmicEngine.getSunriseSunset(context: day.advancedByLocalDays(1)) else {
            return false
        }
        let night = tomorrow.sunrise.timeIntervalSince(today.sunset)
        guard night > 0 else { return false }
        let apparentMidnight = today.sunset.addingTimeInterval(night / 2)
        let window = night * 24 / 720
        return abs(sankranti.timeIntervalSince(apparentMidnight)) <= window
    }

    // MARK: Public entry

    static func solarMonth(context: CalculationContext, rule: RegionalSolarRule) -> RegionalSolarMonth? {
        let reference = CosmicEngine.panchangReferenceDate(for: context)

        // The month running today is begun by the latest sankranti whose
        // first day is not after today. A sankranti later today (after the
        // sunrise reference) can still begin the month TODAY under the Tamil
        // and Malayali rules, so both neighbors are considered.
        let recent = LunarCalendarEngine.nextSankranti(after: reference.addingTimeInterval(-40 * 86_400))
        var candidate = recent
        var previous = candidate
        for _ in 0..<3 {
            let next = LunarCalendarEngine.nextSankranti(after: candidate.instant.addingTimeInterval(60))
            if next.instant <= reference.addingTimeInterval(86_400) {
                previous = candidate
                candidate = next
            } else {
                break
            }
        }

        func build(_ sankranti: (instant: Date, rashiIndex: Int)) -> RegionalSolarMonth? {
            guard let first = firstDay(rule: rule, sankranti: sankranti.instant, context: context),
                  let critical = criticalMoment(rule: rule, sankranti: sankranti.instant, context: context) else {
                return nil
            }
            var calendar = context.calendar
            calendar.timeZone = context.timeZone
            let firstDayStart = calendar.startOfDay(for: first.localNoon)
            let todayStart = calendar.startOfDay(for: context.localNoon)
            guard let dayCount = calendar.dateComponents([.day], from: firstDayStart, to: todayStart).day,
                  dayCount >= 0 else { return nil }

            let monthIndex = sankranti.rashiIndex
            let era = eraYear(rule: rule, monthIndex: monthIndex, monthStartYear: calendar.component(.year, from: first.localNoon))
            return RegionalSolarMonth(
                rule: rule,
                monthIndex: monthIndex,
                monthName: rule.monthNames[monthIndex],
                monthStart: first.localNoon,
                dayOfMonth: dayCount + 1,
                eraYear: era?.year,
                eraName: era?.name,
                isBengalBoundaryCase: rule == .bengal
                    && isInBengalBoundaryZone(sankranti: sankranti.instant, context: context),
                isWithinSolverMarginOfBoundary:
                    abs(sankranti.instant.timeIntervalSince(critical)) <= solverMarginSeconds
            )
        }

        // Prefer the later sankranti when its month has already begun.
        if let month = build(candidate), month.dayOfMonth >= 1,
           month.monthStart <= context.localNoon.addingTimeInterval(12 * 3_600) {
            return month
        }
        return build(previous)
    }

    /// Verified era years only: Kollam (increments at Chingam 1) and the
    /// Bengali San (increments at Pohela Boishakh). Tamil's 60-year cycle
    /// and Odisha's anka are not implemented.
    private static func eraYear(
        rule: RegionalSolarRule,
        monthIndex: Int,
        monthStartYear: Int
    ) -> (year: Int, name: String)? {
        switch rule {
        case .malayali:
            // Chingam (index 4) opens the Kollam year: ME = CE - 824 from
            // Chingam through Meenam; the Mesha-Karkidakam months belong to
            // the year begun the previous Chingam (CE - 825).
            return monthIndex >= 4
                ? (monthStartYear - 824, "Kollam")
                : (monthStartYear - 825, "Kollam")
        case .bengal:
            // Boishakh (index 0) opens the San: CE - 593 for months starting
            // April onward; Poush through Choitro start in the next CE year
            // but belong to the San begun the previous Boishakh.
            return monthIndex <= 8
                ? (monthStartYear - 593, "Bengali San")
                : (monthStartYear - 594, "Bengali San")
        case .orissa, .tamil:
            return nil
        }
    }
}
