import Foundation

// MARK: - Traditional Hindu timekeeping: prahars, Ishta Kaal, ghati counters
//
// Sources verified BEFORE implementation, and deliberately none of them a
// competitor's marketing copy (the capability was found via an App Store
// listing; the definitions were not taken from it):
//
//  - Units. sankul.org/ghati: "1 day & night or 24 hours = 60 ghatis (also
//    called dand); 1 ghati = 60 palas (also called vighati or kala); 1 pala =
//    60 vipalas (also called lipta or vikala)." A ghati is therefore a FIXED
//    24 minutes, and the alternate unit names are classical, not coinages.
//  - Ishta Kaal. The elapsed time from sunrise to an instant, expressed in
//    ghati-pala-vipala, with 2.5 ghatis to the hour. Cross-checked against a
//    published worked example: sunrise 06:30, instant 16:30 -> 10 hours ->
//    25 ghatis exactly (testPublishedIshtaKaalWorkedExample).
//  - Prahars. Wikipedia "Prahara": the eight prahars are NOT fixed three-hour
//    blocks. "If the location is near the equator, where day and night are the
//    same length year round, the praharas of the day and the praharas of the
//    night will be of equal length (three hours each). In other regions, where
//    the relative length of day and night varies according to the season, the
//    praharas of the day will be longer or shorter than the praharas of the
//    night." Four run sunrise->sunset, four sunset->next sunrise.
//  - Names. Purvahna / Madhyahna / Aparahna / Sayahna by day and Pradosha /
//    Nishitha / Triyama / Usha by night, attested at bhaktibharat.com and
//    thedivineindia.com independently of any app listing.
//
// TWO DISCLOSED DIVERGENCES -- recorded, not silently resolved:
//
//  1. GHATI CONVENTION. This engine uses the fixed 24-minute ghati, so
//     dinamana (daylight measured in ghatis) VARIES with season and latitude.
//     That variation is the point: classical panchangs print dinamana only
//     because it moves. A competing "30-ghati clock" instead divides daylight
//     into 30 parts and night into 30, making dinamana 30 by construction.
//     Both are in circulation. The fixed ghati ships because it is the
//     convention the Ishta Kaal x2.5 rule and its worked examples assume, and
//     `dinamana` is surfaced precisely so a reader can see which is in force.
//
//  2. PRAHAR DURATION. A contemporary operational scheme pins prahars to fixed
//     clock hours (3-6am, 6-9am, 9-12 ...) and, in doing so, swaps Madhyahna
//     and Aparahna relative to the traditional sunrise-anchored order. This
//     engine implements the traditional proportional scheme.
//
// CONSEQUENCE WORTH STATING: prahars are proportional while ghatis are fixed,
// so a day prahar is exactly 7.5 ghatis only at the equinox. The two units are
// not reconciled here because the tradition does not reconcile them.
//
// NO NEW ASTRONOMY. Every value below is derived from the sunrise and sunset
// instants CosmicEngine already solves, and every entry point fails closed
// wherever sunrise does not exist -- the same rule the rest of the app follows.

// MARK: - Sexagesimal duration

/// A duration in the ghati system. Ghati = 24 minutes exactly, pala (vighati,
/// kala) = 24 seconds, vipala (lipta, vikala) = 0.4 seconds.
struct GhatiPala: Equatable {
    let ghati: Int
    let pala: Int
    let vipala: Int

    static let secondsPerVipala: Double = 0.4
    static let secondsPerPala: Double = 24
    static let secondsPerGhati: Double = 1_440
    /// A full day and night. Named because the 60-ghati day is the invariant
    /// the whole system rests on.
    static let ghatisPerDay = 60

    /// Negative intervals clamp to zero: an Ishta Kaal is measured forward
    /// from a sunrise that has already happened, so a negative value would
    /// mean the caller picked the wrong Vedic day rather than a real duration.
    init(interval: TimeInterval) {
        let totalVipala = max(0, Int((interval / Self.secondsPerVipala).rounded()))
        ghati = totalVipala / 3_600
        pala = (totalVipala % 3_600) / 60
        vipala = totalVipala % 60
    }

    init(ghati: Int, pala: Int, vipala: Int) {
        self.ghati = ghati
        self.pala = pala
        self.vipala = vipala
    }

    var interval: TimeInterval {
        Double(ghati) * Self.secondsPerGhati
            + Double(pala) * Self.secondsPerPala
            + Double(vipala) * Self.secondsPerVipala
    }

    /// "25 gh 12 pa 30 vi" — the reading a Hindu clock shows.
    var text: String { "\(ghati) gh \(pala) pa \(vipala) vi" }

    /// Ghati and pala only, for surfaces that update once a minute.
    var shortText: String { "\(ghati) gh \(pala) pa" }
}

// MARK: - Prahar

struct Prahar: Equatable, Identifiable {
    /// 1...8, counted from the first prahar after sunrise.
    let number: Int
    let name: String
    let isDay: Bool
    let start: Date
    let end: Date

    var id: Int { number }
    var duration: TimeInterval { end.timeIntervalSince(start) }

    func contains(_ instant: Date) -> Bool {
        instant >= start && instant < end
    }
}

/// Daylight and night length in ghatis — the pair that makes the fixed-ghati
/// convention visible instead of implicit.
struct DayNightMeasure: Equatable {
    let dinamana: GhatiPala
    let ratrimana: GhatiPala
}

// MARK: - Engine

enum TraditionalClock {

    static let dayPraharNames = ["Purvahna", "Madhyahna", "Aparahna", "Sayahna"]
    static let nightPraharNames = ["Pradosha", "Nishitha", "Triyama", "Usha"]

    /// The sunrise/sunset pair bounding the Vedic day that begins on
    /// `context`'s civil day, plus the following sunrise that closes its night.
    private static func bounds(
        context: CalculationContext
    ) -> (sunrise: Date, sunset: Date, nextSunrise: Date)? {
        guard let today = CosmicEngine.getSunriseSunset(context: context),
              let tomorrow = CosmicEngine.getSunriseSunset(context: context.advancedByLocalDays(1)) else {
            return nil
        }
        return (today.sunrise, today.sunset, tomorrow.sunrise)
    }

    /// The context whose sunrise opens the Vedic day containing `instant`.
    /// An instant before today's sunrise belongs to YESTERDAY's Vedic day —
    /// 03:00 is late in the previous day's Usha prahar, not early in today's
    /// Purvahna, and its Ishta Kaal is around 52 ghatis, not a negative one.
    private static func vedicDayContext(
        containing instant: Date,
        location context: CalculationContext
    ) -> CalculationContext? {
        let onInstantsDay = CalculationContext(
            localDay: instant,
            latitude: context.latitude,
            longitude: context.longitude,
            timeZoneIdentifier: context.timeZoneIdentifier
        )
        guard let today = CosmicEngine.getSunriseSunset(context: onInstantsDay) else { return nil }
        return instant >= today.sunrise ? onInstantsDay : onInstantsDay.advancedByLocalDays(-1)
    }

    // MARK: Prahars

    /// The eight prahars of the Vedic day beginning at `context`'s sunrise:
    /// four equal quarters of the actual daylight arc, then four equal
    /// quarters of the actual night. Empty when sunrise does not exist — the
    /// app never fabricates a sunrise-derived schedule.
    static func prahars(context: CalculationContext) -> [Prahar] {
        guard let bounds = bounds(context: context) else { return [] }

        let dayQuarter = bounds.sunset.timeIntervalSince(bounds.sunrise) / 4
        let nightQuarter = bounds.nextSunrise.timeIntervalSince(bounds.sunset) / 4
        guard dayQuarter > 0, nightQuarter > 0 else { return [] }

        let day = (0..<4).map { index in
            Prahar(
                number: index + 1,
                name: dayPraharNames[index],
                isDay: true,
                start: bounds.sunrise.addingTimeInterval(Double(index) * dayQuarter),
                end: bounds.sunrise.addingTimeInterval(Double(index + 1) * dayQuarter)
            )
        }
        let night = (0..<4).map { index in
            Prahar(
                number: index + 5,
                name: nightPraharNames[index],
                isDay: false,
                start: bounds.sunset.addingTimeInterval(Double(index) * nightQuarter),
                end: bounds.sunset.addingTimeInterval(Double(index + 1) * nightQuarter)
            )
        }
        return day + night
    }

    /// The prahar running at `instant`, resolved against whichever Vedic day
    /// actually contains it.
    static func prahar(at instant: Date, context: CalculationContext) -> Prahar? {
        guard let dayContext = vedicDayContext(containing: instant, location: context) else { return nil }
        return prahars(context: dayContext).first { $0.contains(instant) }
    }

    // MARK: Ishta Kaal

    /// Ishta Kaal: elapsed time from the Vedic day's sunrise to `instant`, in
    /// fixed ghati-pala-vipala. Returns the sunrise it was measured from so a
    /// caller can show the anchor rather than an unexplained number.
    static func ishtaKaal(
        at instant: Date,
        context: CalculationContext
    ) -> (sunrise: Date, elapsed: TimeInterval, value: GhatiPala)? {
        guard let dayContext = vedicDayContext(containing: instant, location: context),
              let solar = CosmicEngine.getSunriseSunset(context: dayContext) else {
            return nil
        }
        let elapsed = instant.timeIntervalSince(solar.sunrise)
        return (solar.sunrise, elapsed, GhatiPala(interval: elapsed))
    }

    // MARK: Dinamana / Ratrimana

    /// Daylight and night length in fixed ghatis. Under this engine's
    /// convention these move with the season; under the competing 30-ghati
    /// clock they would both be a constant 30.
    static func dayNightMeasure(context: CalculationContext) -> DayNightMeasure? {
        guard let bounds = bounds(context: context) else { return nil }
        return DayNightMeasure(
            dinamana: GhatiPala(interval: bounds.sunset.timeIntervalSince(bounds.sunrise)),
            ratrimana: GhatiPala(interval: bounds.nextSunrise.timeIntervalSince(bounds.sunset))
        )
    }
}
