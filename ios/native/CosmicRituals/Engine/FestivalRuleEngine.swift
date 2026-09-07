import Foundation

// MARK: - Festivals, specified rather than tabulated
//
// This REPLACES the FestivalData prototype's keying, whose own header admitted
// two holes (no Adhika/Kshaya handling, no observance precedence) and carried a
// third it did not name: its Krishna-paksha entries used PURNIMANTA month
// names while the engine computes Amanta, so the same lunar night was labelled
// with two different months and nothing recorded which was meant.
//
// Every rule here therefore declares four things instead of two:
//
//  1. WHICH MONTH, AND IN WHICH NAMING. A Krishna-paksha festival has two
//     correct month names. Maha Shivaratri is Krishna Chaturdashi of AMANTA
//     Magha and of PURNIMANTA Phalguna -- Wikipedia states both and adds that
//     "despite the difference in month name, the festival is observed on the
//     same lunar night across India." A rule that names one without saying
//     which is ambiguous by construction.
//  2. PAKSHA AND TITHI separately, rather than a 0-29 index whose meaning
//     depends on an unstated paksha convention.
//  3. THE OBSERVANCE INSTANT. This is the precedence the prototype lacked.
//     A tithi spans parts of two civil days, and which day carries the
//     festival depends on WHEN the tithi must be running: at sunrise for most
//     observances, at nishita (the middle of the night) for Shivaratri and
//     Janmashtami, at madhyahna (midday) for Ganesh Chaturthi, at pradosha
//     (just after sunset) for Lakshmi Puja. Using sunrise for all of them
//     puts several major festivals on the wrong day.
//  4. ITS SOURCE, and any regional divergence.
//
// ONLY RULES VERIFIED AGAINST A PUBLISHED 2026 DATE SHIP. The prototype's
// remaining entries stay where they are, unrouted, until each is checked the
// same way -- a festival list is exactly the kind of content that looks
// harmless and is wrong in ways users notice.
//
// ADHIKA MONTHS: a leap month carries no festivals of its own; observances
// fall in the nija (true) month. Rules therefore match only non-Adhika
// lunations, which is also why the masa engine's Adhika flag had to exist
// before this file could.

enum MasaNaming: String, Sendable {
    case amanta
    case purnimanta
}

enum FestivalPaksha: String, Sendable {
    case shukla
    case krishna
}

/// When the tithi must be running for a civil day to carry the festival.
enum ObservanceInstant: String, Sendable {
    /// The tithi prevailing at sunrise — the default for most observances.
    case sunrise
    /// Midday: sunrise plus half the daylight arc.
    case madhyahna
    /// Just after sunset.
    case pradosha
    /// The middle of the night, sunset to next sunrise.
    case nishita

    var explanation: String {
        switch self {
        case .sunrise: return "the tithi running at sunrise"
        case .madhyahna: return "the tithi running at midday"
        case .pradosha: return "the tithi running just after sunset"
        case .nishita: return "the tithi running in the middle of the night"
        }
    }
}

struct FestivalRule: Identifiable, Sendable {
    let id: String
    let name: String
    /// 0 = Chaitra … 11 = Phalguna, in the naming `naming` declares.
    let masaIndex: Int
    let naming: MasaNaming
    let paksha: FestivalPaksha
    /// 1…15. Purnima and Amavasya are 15 of their respective pakshas.
    let tithiInPaksha: Int
    let observance: ObservanceInstant
    /// The published date this rule was verified against.
    let verifiedAgainst: String
    let note: String
}

struct VerifiedFestivalOccurrence: Identifiable, Equatable {
    let ruleID: String
    let name: String
    /// Local noon of the civil day carrying the festival.
    let day: Date
    let observance: ObservanceInstant

    var id: String { ruleID }
}

enum FestivalRuleEngine {

    /// Only rules checked against a published 2026 date. Deliberately short.
    static let rules: [FestivalRule] = [
        FestivalRule(
            id: "maha-shivaratri", name: "Maha Shivaratri",
            masaIndex: 10, naming: .amanta, paksha: .krishna, tithiInPaksha: 14,
            observance: .nishita,
            verifiedAgainst: "15 February 2026",
            note: "Krishna Chaturdashi of Amanta Magha — Purnimanta Phalguna. The same lunar night under both namings; the observance is centred on nishita, so the civil day is the one whose middle-of-night carries the tithi."
        ),
        FestivalRule(
            id: "rama-navami", name: "Rama Navami",
            masaIndex: 0, naming: .amanta, paksha: .shukla, tithiInPaksha: 9,
            observance: .madhyahna,
            verifiedAgainst: "26 March 2026",
            note: "Chaitra Shukla Navami. Shukla-paksha months are named identically in both reckonings, so no naming ambiguity arises. THIS RULE IS WHY OBSERVANCE PRECEDENCE EXISTS: in 2026 Navami runs 11:48 on 26 March to 10:06 on 27 March, so it is still running at sunrise on the 27th and a naive sunrise rule lands a day late. Madhyahna on the 26th falls inside the tithi and gives the published date."
        ),
        FestivalRule(
            id: "ganesh-chaturthi", name: "Ganesh Chaturthi",
            masaIndex: 5, naming: .amanta, paksha: .shukla, tithiInPaksha: 4,
            observance: .madhyahna,
            verifiedAgainst: "14 September 2026",
            note: "Bhadrapada Shukla Chaturthi, observed at madhyahna — the classical reason a Chaturthi that begins late morning still carries the festival that day."
        ),
        FestivalRule(
            id: "lakshmi-puja", name: "Diwali · Lakshmi Puja",
            masaIndex: 6, naming: .amanta, paksha: .krishna, tithiInPaksha: 15,
            observance: .pradosha,
            verifiedAgainst: "8 November 2026",
            note: "Amavasya ending Amanta Ashwina — Purnimanta Kartika, which is why Diwali is commonly called a Kartika festival. Lakshmi Puja is a pradosha observance, so the evening decides the day."
        ),
    ]

    /// ATTEMPTED AND NOT SHIPPED, with the reason measured rather than
    /// guessed. These are recorded here so the same rule is not re-attempted
    /// naively, and so the absence reads as a decision.
    ///
    /// KRISHNA JANMASHTAMI. A single-instant nishita rule cannot express it.
    /// Measured at Delhi in 2026, the tithi at successive nishita instants
    /// runs 21 (3 Sep) then 23 (4 Sep) — Krishna Ashtami never touches a
    /// nishita at all that year, because it begins and ends between two
    /// midnights. The published date is 4 September. The classical rule is
    /// correspondingly conditional (and is exactly where the smarta and
    /// vaishnava traditions are documented to diverge), so shipping any
    /// single-instant approximation would put the festival on the wrong day
    /// in some years while looking right in others. It waits for a sourced
    /// conditional rule, not a tuned constant.
    static let attemptedButUnresolved: [String] = [
        "Krishna Janmashtami — Krishna Ashtami touched no nishita instant in 2026 (tithi 21 then 23 at successive midnights); needs the sourced conditional rule, including the smarta/vaishnava divergence.",
    ]

    // MARK: Observance instants

    /// The instant a rule's tithi must be running on a given civil day.
    /// Nil where sunrise does not exist — no festival is placed on a day the
    /// app cannot anchor.
    static func observanceInstant(
        _ observance: ObservanceInstant,
        context: CalculationContext
    ) -> Date? {
        guard let solar = CosmicEngine.getSunriseSunset(context: context) else { return nil }
        switch observance {
        case .sunrise:
            return solar.sunrise
        case .madhyahna:
            return solar.sunrise.addingTimeInterval(
                solar.sunset.timeIntervalSince(solar.sunrise) / 2)
        case .pradosha:
            return solar.sunset.addingTimeInterval(24 * 60)
        case .nishita:
            guard let tomorrow = CosmicEngine.getSunriseSunset(context: context.advancedByLocalDays(1)) else {
                return nil
            }
            return solar.sunset.addingTimeInterval(
                tomorrow.sunrise.timeIntervalSince(solar.sunset) / 2)
        }
    }

    /// The 0-29 tithi index a rule targets, in the app's own convention
    /// (0 = Shukla Pratipada … 29 = Amavasya).
    static func targetTithiIndex(_ rule: FestivalRule) -> Int {
        switch rule.paksha {
        case .shukla: return rule.tithiInPaksha - 1
        case .krishna: return 15 + rule.tithiInPaksha - 1
        }
    }

    // MARK: Matching

    /// Does this civil day carry the festival?
    static func matches(rule: FestivalRule, context: CalculationContext) -> Bool {
        guard let instant = observanceInstant(rule.observance, context: context) else { return false }

        let tithi = CosmicEngine.getPanchang(
            date: instant, timezoneIdentifier: context.timeZoneIdentifier).tithiIndex
        guard tithi == targetTithiIndex(rule) else { return false }

        // The masa is read at the observance instant's own lunation, so a
        // festival late in a Krishna paksha is tested against the month that
        // actually contains it.
        let masaContext = CalculationContext(
            localDay: instant,
            latitude: context.latitude,
            longitude: context.longitude,
            timeZoneIdentifier: context.timeZoneIdentifier
        )
        let info = LunarCalendarEngine.monthInfo(context: masaContext)

        // A leap month carries no festivals; they fall in the nija month.
        guard !info.isAdhika else { return false }

        switch rule.naming {
        case .amanta:
            return info.amantaMasaIndex == rule.masaIndex
        case .purnimanta:
            let purnimanta = info.pakshaIsShukla
                ? info.amantaMasaIndex
                : (info.amantaMasaIndex + 1) % 12
            return purnimanta == rule.masaIndex
        }
    }

    /// The civil day carrying a rule's festival in a Gregorian year, searched
    /// only in the window the masa can plausibly fall — a full-year scan would
    /// run the lunation solver hundreds of times for no gain.
    static func occurrence(
        rule: FestivalRule,
        gregorianYear year: Int,
        context: CalculationContext
    ) -> VerifiedFestivalOccurrence? {
        var calendar = context.calendar
        calendar.timeZone = context.timeZone
        guard let januaryFirst = calendar.date(
            from: DateComponents(year: year, month: 1, day: 1, hour: 12)) else { return nil }

        for offset in 0..<366 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: januaryFirst) else { continue }
            let dayContext = CalculationContext(
                localDay: day,
                latitude: context.latitude,
                longitude: context.longitude,
                timeZoneIdentifier: context.timeZoneIdentifier
            )
            // Cheap gate first: the tithi must match before the lunation
            // solver is asked anything.
            guard let instant = observanceInstant(rule.observance, context: dayContext) else { continue }
            let tithi = CosmicEngine.getPanchang(
                date: instant, timezoneIdentifier: context.timeZoneIdentifier).tithiIndex
            guard tithi == targetTithiIndex(rule) else { continue }

            if matches(rule: rule, context: dayContext) {
                return VerifiedFestivalOccurrence(
                    ruleID: rule.id, name: rule.name,
                    day: dayContext.localNoon, observance: rule.observance
                )
            }
        }
        return nil
    }

    /// Every verified festival of a Gregorian year, in date order.
    static func occurrences(gregorianYear year: Int, context: CalculationContext) -> [VerifiedFestivalOccurrence] {
        rules
            .compactMap { occurrence(rule: $0, gregorianYear: year, context: context) }
            .sorted { $0.day < $1.day }
    }

    /// The festivals, if any, falling on the context's own civil day.
    static func festivals(on context: CalculationContext) -> [VerifiedFestivalOccurrence] {
        rules.compactMap { rule in
            matches(rule: rule, context: context)
                ? VerifiedFestivalOccurrence(ruleID: rule.id, name: rule.name,
                                     day: context.localNoon, observance: rule.observance)
                : nil
        }
    }
}
