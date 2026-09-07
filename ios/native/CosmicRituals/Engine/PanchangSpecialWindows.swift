import Foundation

// MARK: - Varjyam, Amrit Kalam, Anandadi, Panchaka, Ganda Mula
//
// Tables verified 2026-08 against two independent source classes before
// implementation: the Drik Panchang Nakshatra-Thyajyam tutorial table and the
// Telugu oursubhakaryam table (which agree), then empirically confirmed to
// within ±0.05 ghati against published prokerala.com 2026 dailies (Ujjain,
// Lahiri) on eight dates, including both two-Varjyam days (2026-08-23:
// Mula + Purva Ashadha; 2026-09-04: Rohini + Mrigashira). Divergent classical
// variants that the published dailies do NOT use are deliberately not
// implemented and are named in ACCURACY.md: the Prashna Marga (B.V. Raman)
// Varjyam column (Ardra 11, Hasta 22, Mula 20) and its Madhaveeya Amrit
// column; the panchangbodh weekday-shifted Panchaka table.

enum PanchangSpecialWindows {

    /// Varjyam start, in ghatis of the nakshatra's own span treated as 60,
    /// indexed by nakshatra 0-26 (Ashwini...Revati). Duration is 4 ghatis
    /// (1/15 of the span). Dominant daily-panchang practice table.
    static let varjyamStartGhatis: [Double] = [
        50, 24, 30, 40, 14, 21, 30, 20, 32,
        30, 20, 18, 21, 20, 14, 14, 10, 14,
        56, 24, 20, 10, 10, 18, 16, 24, 30,
    ]

    /// Amrit Kalam start ghatis, same convention. An independent table, not a
    /// Varjyam derivation: for 23 nakshatras it equals Varjyam+24, but
    /// Ashwini/Rohini/Mula/Ardra genuinely differ, and the published dailies
    /// use 34 for Anuradha where the Prashna Marga text prints 28.
    static let amritStartGhatis: [Double] = [
        42, 48, 54, 52, 38, 35, 54, 44, 56,
        54, 44, 42, 45, 44, 38, 38, 34, 38,
        44, 48, 44, 34, 34, 42, 40, 48, 54,
    ]

    struct SpecialWindow: Equatable {
        let title: String
        let nakshatraName: String
        let startTime: Date
        let endTime: Date
    }

    /// Nakshatra index for a limb window, read from the Moon at the window's
    /// midpoint (safely inside the span).
    private static func nakshatraIndex(of window: PanchangLimbWindow) -> Int {
        let midpoint = window.startTime.addingTimeInterval(
            window.endTime.timeIntervalSince(window.startTime) / 2
        )
        let jd = CosmicEngine.julianDateFromDate(midpoint)
        let sidereal = CosmicEngine.siderealize(CosmicEngine.moonLongitude(jd: jd), jd: jd)
        return min(26, Int(sidereal / (360.0 / 27.0)))
    }

    private static func windows(
        title: String,
        startGhatis: [Double],
        context: CalculationContext
    ) -> [SpecialWindow] {
        CosmicEngine.limbWindows(for: .nakshatra, context: context).map { window in
            let span = window.endTime.timeIntervalSince(window.startTime)
            let index = nakshatraIndex(of: window)
            let start = window.startTime.addingTimeInterval(span * startGhatis[index] / 60.0)
            return SpecialWindow(
                title: title,
                nakshatraName: window.name,
                startTime: start,
                endTime: start.addingTimeInterval(span * 4.0 / 60.0)
            )
        }
    }

    /// Varjyam spans for the Panchang day (one per nakshatra window; two
    /// windows on days two nakshatras' spans land in, as published dailies
    /// show).
    static func varjyam(context: CalculationContext) -> [SpecialWindow] {
        windows(title: "Varjyam", startGhatis: varjyamStartGhatis, context: context)
    }

    static func amritKalam(context: CalculationContext) -> [SpecialWindow] {
        windows(title: "Amrit Kalam", startGhatis: amritStartGhatis, context: context)
    }

    // MARK: Anandadi yoga (28-cycle, Abhijit inserted)

    /// The 28 Anandadi yoga names with their traditional quality. Order
    /// verified against two independent Hindi listings that agree exactly.
    static let anandadiYogas: [(name: String, isAuspicious: Bool)] = [
        ("Ananda", true), ("Kaladanda", false), ("Dhumra", false), ("Dhata", true),
        ("Saumya", true), ("Dhwanksha", false), ("Dhwaja", true), ("Shrivatsa", true),
        ("Vajra", false), ("Mudgara", false), ("Chhatra", true), ("Mitra", true),
        ("Manasa", true), ("Padma", true), ("Lumbaka", false), ("Utpata", false),
        ("Mrityu", false), ("Kana", false), ("Siddhi", true), ("Shubha", true),
        ("Amrita", true), ("Musala", false), ("Gada", false), ("Matanga", true),
        ("Rakshasa", false), ("Chara", true), ("Sthira", true), ("Pravardhamana", true),
    ]

    /// Weekday anchor nakshatras (Sunday...Saturday), consistent across
    /// sources: Ashwini, Mrigashira, Ashlesha, Hasta, Anuradha,
    /// Uttara Ashadha, Shatabhisha.
    static let anandadiAnchors = [0, 4, 8, 12, 16, 20, 23]

    /// Anandadi yoga index 0-27 for a weekday (1=Sunday...7=Saturday) and
    /// nakshatra index 0-26. The count is inclusive over the 28-name cycle
    /// with Abhijit inserted between Uttara Ashadha (20) and Shravana (21):
    /// whenever the forward path from the anchor crosses that boundary the
    /// count advances one extra step. Settled empirically: Thursday +
    /// Dhanishta must give Shrivatsa (#8, not #7) and Tuesday + Ashwini
    /// Amrita (#21, not #20), as the 2026 dailies print.
    static func anandadiIndex(weekday: Int, nakshatraIndex: Int) -> Int? {
        guard (1...7).contains(weekday), (0...26).contains(nakshatraIndex) else { return nil }
        let anchor = anandadiAnchors[weekday - 1]
        let count27 = ((nakshatraIndex - anchor) % 27 + 27) % 27
        let stepsToInsertion = ((20 - anchor) % 27 + 27) % 27
        let crossesAbhijit = count27 > stepsToInsertion
        return (count27 + (crossesAbhijit ? 1 : 0)) % 28
    }

    // MARK: Panchaka (Moon-transit rule) and Ganda Mula

    /// Panchaka is active while the sidereal Moon is in Aquarius or Pisces
    /// (300°-360°: Dhanishta's second half through Revati). The dosha NAME
    /// is fixed by the weekday the five-day period BEGAN: Sunday Roga,
    /// Monday Raja, Tuesday Agni, Friday Chora, Saturday Mrityu; a period
    /// beginning Wednesday or Thursday carries no named dosha in the
    /// dominant tradition (one outlier table shifts every day and is not
    /// implemented). This is the Moon-transit Panchak of North-Indian daily
    /// practice, distinct from the mod-9 Panchaka-Rahita muhurta filter,
    /// which this app does not compute.
    static func panchaka(context: CalculationContext) -> (typeName: String?, active: Bool) {
        let reference = CosmicEngine.panchangReferenceDate(for: context)
        let jd = CosmicEngine.julianDateFromDate(reference)
        let sidereal = CosmicEngine.siderealize(CosmicEngine.moonLongitude(jd: jd), jd: jd)
        guard sidereal >= 300 else { return (nil, false) }

        // Walk back to the 300-degree entry (at most ~5.5 days at the Moon's
        // slowest); hour steps then a bisection to the crossing.
        var lower = reference
        for step in 1...(6 * 24) {
            let candidate = reference.addingTimeInterval(-Double(step) * 3_600)
            let candidateJD = CosmicEngine.julianDateFromDate(candidate)
            let longitude = CosmicEngine.siderealize(CosmicEngine.moonLongitude(jd: candidateJD), jd: candidateJD)
            if longitude < 300 {
                lower = candidate
                break
            }
        }
        var upper = lower.addingTimeInterval(3_600)
        for _ in 0..<40 {
            let midpoint = lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
            let midJD = CosmicEngine.julianDateFromDate(midpoint)
            let longitude = CosmicEngine.siderealize(CosmicEngine.moonLongitude(jd: midJD), jd: midJD)
            if longitude >= 300 { upper = midpoint } else { lower = midpoint }
        }
        var calendar = context.calendar
        calendar.timeZone = context.timeZone
        let startWeekday = calendar.component(.weekday, from: upper)
        let names: [Int: String] = [1: "Roga", 2: "Raja", 3: "Agni", 6: "Chora", 7: "Mrityu"]
        return (names[startWeekday], true)
    }

    /// The six Ganda Mula nakshatras (Mercury/Ketu junctions), uniform across
    /// sources: Ashwini, Ashlesha, Magha, Jyeshtha, Mula, Revati.
    static let gandaMulaIndices: Set<Int> = [0, 8, 9, 17, 18, 26]

    static func isGandaMula(nakshatraIndex: Int) -> Bool {
        gandaMulaIndices.contains(nakshatraIndex)
    }
}
