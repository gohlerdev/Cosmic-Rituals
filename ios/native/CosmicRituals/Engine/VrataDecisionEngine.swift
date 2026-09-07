import Foundation

// MARK: - Vrata decision rules that a single observance instant cannot express
//
// Sources verified 3-0 before implementation (research cycle 3, 2026-08-28):
//
//  - THE GENERAL VEDHA DOCTRINE. Kane, History of Dharmasastra Vol. V pt. 1,
//    Sec. I ch. III (~pp. 72-73): "all religious acts prescribed for being
//    performed by day on certain tithis for gods must be begun in the morning
//    even if the tithi is mixed with another on that day, but all vratas to
//    be performed in the evening or night have to be performed on the tithi
//    existing in the evening or night even though it may be mixed up (viddha)
//    with another tithi." This is the udaya-vyapini vs pradosha/nishita
//    split the festival engine's observance instants already implement -- now
//    a sourced doctrine rather than a design choice.
//
//  - KRISHNA JANMASHTAMI, THE TITHITATTVA CASCADE (Raghunandana, via Kane
//    Sec. I ch. VII, ~pp. 132-135): fast on Jayanti (Ashtami conjoined with
//    Rohini) if it falls on one day; if on two, the later; if there is no
//    Jayanti, on Ashtami joined with Rohini (later if two); if no Rohini, on
//    Ashtami existing at midnight; and if Ashtami is at midnight on two days
//    or on NEITHER, on the later day. That last clause is the rule for the
//    exact case the festival engine withheld -- in 2026 Krishna Ashtami
//    touched no nishita instant -- and it resolves it to the later day.
//    The Nirnaya Sindhu is confirmed (3-0) to carry the same Rohini-plus-
//    nishita nirnaya, but only in Sanskrit; it is cited as the primary
//    nibandha, Kane as the checkable English rendering.
//
//  - A DIVERGENT SOUTH INDIAN SCHOOL, DISCLOSED NOT BLENDED. Kalaprakasika
//    ch. XLIII "Sreejayanthi" (N. Iyer tr., pp. 237-238) decides by MOONRISE
//    rather than nishita, distinguishes suddha from viddha by a different
//    vedha, and takes the later of two tithis on one day. It is a Vaishnava
//    (Pancharatra) rule and is named here as a school this engine does not
//    implement, so a South Indian reader knows the cascade above is the
//    Bengal-school nibandha answer.
//
//  - VAISHNAVA EKADASHI (Kane Sec. I ch. V, ~pp. 114-115, citing
//    Brahmavaivarta via Hemadri): if Dashami extends beyond 56 ghatikas from
//    sunrise -- i.e. into the last four ghatikas before the next sunrise, the
//    arunodaya-vedha -- or persists to the instant of sunrise, a Vaishnava
//    may not fast on that Ekadashi even if it then lasts a full day, and
//    fasts on the next day (Dvadashi) with parana the day after. Smartas are
//    not bound by arunodaya-vedha. That is the smarta/vaishnava Ekadashi
//    split, and it is computable from the tithi at two instants.
//
//    Kane's rule has TWO clauses and both matter. Beside arunodaya-vedha
//    (Dashami reaching into the last four ghatikas) he names Dashami
//    "persisting to the instant of sunrise" -- suryodaya-vedha. In practice
//    that second clause IS the kshaya Ekadashi: a tithi that begins after one
//    sunrise and ends before the next leaves Dashami running through the
//    earlier sunrise. Checked against the published 2026 calendar, every
//    split between the traditions that year is a kshaya case and no
//    arunodaya case arises, so an implementation carrying only the first
//    clause reproduces no divergence at all while looking correct.
//
// Both rules resolve on HINDU civil days (sunrise to sunrise), which is how
// the sources count ghatikas.

enum JanmashtamiTier: String, Equatable {
    /// Ashtami and Rohini both running at nishita (Jayanti proper).
    case jayantiAtNishita
    /// Ashtami and Rohini overlapping somewhere in the civil day.
    case ashtamiWithRohini
    /// Ashtami running at nishita, with no Rohini.
    case ashtamiAtNishita
    /// Ashtami at nishita on two days or on neither: the later day.
    case laterDayFallback
}

struct JanmashtamiDecision: Equatable {
    /// Local noon of the civil day carrying the fast.
    let day: Date
    let tier: JanmashtamiTier
    /// The two Hindu civil days Ashtami touched, earlier first.
    let candidateDays: [Date]
}

struct EkadashiDecision: Equatable {
    /// True for a Shukla Ekadashi, false for Krishna.
    let isShukla: Bool
    /// The day Ekadashi is present at sunrise (Kane's day-rite rule). For a
    /// kshaya Ekadashi this is the Hindu day the tithi ran inside.
    let smartaDay: Date
    /// Same as smartaDay unless arunodaya-vedha moves it to the next day.
    let vaishnavaDay: Date
    /// True when Dashami reached into the last four ghatikas before sunrise,
    /// so the Vaishnava fast moved to Dvadashi.
    let arunodayaVedha: Bool
    /// True when the Ekadashi touched NO sunrise (Dashami at one sunrise,
    /// Dvadashi at the next), so it ran wholly inside one Hindu day. This is
    /// Kane's SURYODAYA-VEDHA in its strongest form -- Dashami persists to
    /// the instant of sunrise -- and it is why such an Ekadashi always splits
    /// the two traditions.
    let isKshaya: Bool

    /// True when the two traditions fast on different days, by either vedha.
    var traditionsDiffer: Bool { vaishnavaDay != smartaDay }
}

enum VrataDecisionEngine {

    // MARK: Shared helpers

    private static func location(_ context: CalculationContext, day: Date) -> CalculationContext {
        CalculationContext(
            localDay: day,
            latitude: context.latitude,
            longitude: context.longitude,
            timeZoneIdentifier: context.timeZoneIdentifier
        )
    }

    private static func tithi(at instant: Date, _ context: CalculationContext) -> Int {
        CosmicEngine.getPanchang(date: instant, timezoneIdentifier: context.timeZoneIdentifier).tithiIndex
    }

    private static func nakshatra(at instant: Date) -> Int {
        CosmicEngine.getMoonNakshatraPada(date: instant).nakshatraIndex
    }

    /// The Hindu civil day (sunrise-anchored context) containing `instant`.
    private static func hinduDay(containing instant: Date, _ context: CalculationContext) -> CalculationContext? {
        let onDay = location(context, day: instant)
        guard let solar = CosmicEngine.getSunriseSunset(context: onDay) else { return nil }
        return instant >= solar.sunrise ? onDay : onDay.advancedByLocalDays(-1)
    }

    /// One ghatika is a fixed twenty-four minutes (see TraditionalClockEngine).
    private static let ghatika: TimeInterval = 24 * 60

    static let rohiniIndex = 3

    // MARK: Krishna Janmashtami

    /// The Tithitattva cascade for the Krishna Ashtami of Amanta Shravana in
    /// `year`. Nil when the Ashtami cannot be located (no sunrise, or the
    /// masa never resolves) -- never a guessed date.
    static func janmashtami(gregorianYear year: Int, context: CalculationContext) -> JanmashtamiDecision? {
        var calendar = context.calendar
        calendar.timeZone = context.timeZone
        guard let scanStart = calendar.date(from: DateComponents(year: year, month: 8, day: 1, hour: 12)) else {
            return nil
        }

        // Locate the Saptami-at-sunrise day of Amanta Shravana Krishna paksha,
        // whose end opens the Ashtami interval.
        var ashtamiStart: Date?
        for offset in 0..<50 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: scanStart) else { continue }
            let ctx = location(context, day: day)
            guard let solar = CosmicEngine.getSunriseSunset(context: ctx) else { continue }
            let atSunrise = tithi(at: solar.sunrise, context)
            guard atSunrise == 21 || atSunrise == 22 else { continue }
            let info = LunarCalendarEngine.monthInfo(context: ctx)
            guard info.amantaMasaIndex == 4, !info.isAdhika else { continue }
            if atSunrise == 21 {
                ashtamiStart = CosmicEngine.getTithiEndTime(date: solar.sunrise)
            } else {
                // Ashtami already running at sunrise: walk back to its start.
                var probe = solar.sunrise
                while tithi(at: probe, context) == 22 { probe = probe.addingTimeInterval(-15 * 60) }
                ashtamiStart = probe.addingTimeInterval(15 * 60)
            }
            break
        }
        guard let start = ashtamiStart,
              let end = CosmicEngine.getTithiEndTime(date: start.addingTimeInterval(3_600)),
              let firstDay = hinduDay(containing: start, context),
              let lastDay = hinduDay(containing: end.addingTimeInterval(-60), context) else {
            return nil
        }

        let candidates: [CalculationContext] = firstDay.localNoon == lastDay.localNoon
            ? [firstDay] : [firstDay, lastDay]

        func nishita(_ day: CalculationContext) -> Date? {
            FestivalRuleEngine.observanceInstant(.nishita, context: day)
        }
        func ashtamiAndRohini(at instant: Date) -> Bool {
            tithi(at: instant, context) == 22 && nakshatra(at: instant) == rohiniIndex
        }
        func overlapWithinDay(_ day: CalculationContext) -> Bool {
            guard let solar = CosmicEngine.getSunriseSunset(context: day),
                  let next = CosmicEngine.getSunriseSunset(context: day.advancedByLocalDays(1)) else { return false }
            var probe = solar.sunrise
            while probe < next.sunrise {
                if ashtamiAndRohini(at: probe) { return true }
                probe = probe.addingTimeInterval(20 * 60)
            }
            return false
        }

        let candidateNoons = candidates.map(\.localNoon)
        let choice = chooseTier(
            jayantiAtNishita: candidates.map { nishita($0).map(ashtamiAndRohini) ?? false },
            rohiniOverlap: candidates.map(overlapWithinDay),
            ashtamiAtNishita: candidates.map { day in nishita(day).map { tithi(at: $0, context) == 22 } ?? false }
        )
        return JanmashtamiDecision(
            day: candidateNoons[choice.index], tier: choice.tier, candidateDays: candidateNoons)
    }

    /// The Tithitattva cascade as a PURE function of the three conditions, so
    /// every branch is directly testable. The astronomy decides the booleans;
    /// this decides the day.
    ///
    /// It is extracted for a specific reason found by a negative control: the
    /// last branch ("Ashtami at midnight on two days or on neither -- the
    /// later day") never fires anywhere in 2020-2035, so a sabotage of it
    /// broke nothing and the branch was effectively untested. Over booleans
    /// it can be exercised exhaustively.
    static func chooseTier(
        jayantiAtNishita: [Bool],
        rohiniOverlap: [Bool],
        ashtamiAtNishita: [Bool]
    ) -> (index: Int, tier: JanmashtamiTier) {
        let count = jayantiAtNishita.count
        precondition(count > 0 && rohiniOverlap.count == count && ashtamiAtNishita.count == count)

        // Tier 1: Jayanti at nishita; the later day if two.
        if let index = jayantiAtNishita.lastIndex(of: true) {
            return (index, .jayantiAtNishita)
        }
        // Tier 2: Ashtami joined with Rohini anywhere in the day; later if two.
        if let index = rohiniOverlap.lastIndex(of: true) {
            return (index, .ashtamiWithRohini)
        }
        // Tier 3: Ashtami at nishita on EXACTLY one day.
        let atNishita = ashtamiAtNishita.enumerated().filter(\.element).map(\.offset)
        if atNishita.count == 1 {
            return (atNishita[0], .ashtamiAtNishita)
        }
        // On two days or on neither: the later day.
        return (count - 1, .laterDayFallback)
    }

    // MARK: Ekadashi

    /// Every Ekadashi of a Gregorian year with its smarta and Vaishnava days.
    /// A kshaya Ekadashi touching no sunrise is skipped rather than guessed:
    /// the verified rule speaks only of Ekadashi present at sunrise.
    static func ekadashis(gregorianYear year: Int, context: CalculationContext) -> [EkadashiDecision] {
        var calendar = context.calendar
        calendar.timeZone = context.timeZone
        guard let januaryFirst = calendar.date(from: DateComponents(year: year, month: 1, day: 1, hour: 12)) else {
            return []
        }
        var results: [EkadashiDecision] = []
        var previousAtSunrise: Int?

        for offset in 0..<366 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: januaryFirst) else { continue }
            let ctx = location(context, day: day)
            guard let solar = CosmicEngine.getSunriseSunset(context: ctx) else { previousAtSunrise = nil; continue }
            let atSunrise = tithi(at: solar.sunrise, context)
            defer { previousAtSunrise = atSunrise }

            let isEkadashi = atSunrise == 10 || atSunrise == 25
            let previousWasEkadashi = previousAtSunrise == 10 || previousAtSunrise == 25

            // KSHAYA / SURYODAYA-VEDHA. Dashami at YESTERDAY's sunrise and
            // Dvadashi at today's means the Ekadashi began and ended inside
            // yesterday's Hindu day, so Dashami persisted right through
            // yesterday's sunrise. Kane names that suryodaya-vedha alongside
            // arunodaya-vedha, and it carries the same consequence: the
            // smarta fast is the day the tithi ran in, the Vaishnava fast
            // moves to the following Dvadashi day. Measured against the
            // published 2026 calendar this is the ONLY case where the two
            // traditions split, so treating a kshaya Ekadashi as unsplit --
            // as an earlier draft of this engine did -- silently erased the
            // divergence the rule exists to express.
            if let previous = previousAtSunrise,
               (previous == 9 && atSunrise == 11) || (previous == 24 && atSunrise == 26) {
                let ranIn = ctx.advancedByLocalDays(-1)
                results.append(EkadashiDecision(
                    isShukla: previous == 9,
                    smartaDay: ranIn.localNoon,
                    vaishnavaDay: ctx.localNoon,
                    arunodayaVedha: false,
                    isKshaya: true))
                continue
            }

            // Only the FIRST sunrise an Ekadashi is present at defines the day.
            guard isEkadashi, !previousWasEkadashi else { continue }

            // Arunodaya-vedha: was Dashami still running four ghatikas before
            // this sunrise? (An Ekadashi present AT sunrise cannot also carry
            // suryodaya-vedha, so the two clauses never overlap.)
            let arunodaya = solar.sunrise.addingTimeInterval(-4 * ghatika)
            let dashamiIndex = atSunrise - 1
            let vedha = tithi(at: arunodaya, context) == dashamiIndex

            let smarta = ctx.localNoon
            let vaishnava = vedha ? ctx.advancedByLocalDays(1).localNoon : smarta
            results.append(EkadashiDecision(
                isShukla: atSunrise == 10,
                smartaDay: smarta,
                vaishnavaDay: vaishnava,
                arunodayaVedha: vedha,
                isKshaya: false
            ))
        }
        return results
    }
}
