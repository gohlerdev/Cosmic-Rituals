import Foundation

// MARK: - Vara-Nakshatra Combination Yogas
//
// The Sun and Moon's sidereal positions already drive tithi, nakshatra, yoga,
// and karana independently; these are the classical combination rules formed
// when a specific weekday coincides with a specific nakshatra (or, for Ravi
// Yoga, a specific angular relationship between the Sun's and Moon's own
// nakshatras) -- the same "cross-reference already-computed positions"
// pattern as a natal chart's yogas, applied to the Panchang day itself.
//
// Sources (multiple independent, mutually consistent references, cross-checked
// before implementation):
//  - Sarvartha Siddhi Yoga table: cited to Jyotir Nibandha.
//  - Amrit Siddhi Yoga table (one nakshatra per weekday, each a member of that
//    weekday's Sarvartha Siddhi set): cited to Kalamrita and Muhurta Parijata.
//  - Ravi Yoga: Sun-nakshatra-to-Moon-nakshatra inclusive count in the
//    27-nakshatra cycle; forms at counts 4, 6, 9, 10, 13, or 20.
//  - Guru Pushya Yoga: Thursday coinciding with Pushya nakshatra.

/// Nakshatra indices use `Panchang.nakshatraNames`' order (0 = Ashwini ... 26 = Revati).
enum PanchangYogaEngine {

    private static let sarvarthaSiddhiNakshatraIndices: [String: Set<Int>] = [
        "Sunday":    [12, 18, 11, 20, 25, 7, 8],  // Hasta, Mula, Uttara Phalguni, Uttara Ashadha, Uttara Bhadrapada, Pushya, Ashlesha
        "Monday":    [21, 3, 4, 7, 16],             // Shravana, Rohini, Mrigashira, Pushya, Anuradha
        "Tuesday":   [0, 25, 2, 8],                 // Ashvini, Uttara Bhadrapada, Krittika, Ashlesha
        "Wednesday": [3, 16, 12, 2, 4],             // Rohini, Anuradha, Hasta, Krittika, Mrigashira
        "Thursday":  [26, 16, 0, 6, 7],             // Revati, Anuradha, Ashvini, Punarvasu, Pushya
        "Friday":    [26, 16, 0, 6, 21],            // Revati, Anuradha, Ashvini, Punarvasu, Shravana
        "Saturday":  [21, 3, 14],                   // Shravana, Rohini, Swati
    ]

    private static let amritSiddhiNakshatraIndex: [String: Int] = [
        "Sunday": 12,    // Hasta
        "Monday": 4,     // Mrigashira
        "Tuesday": 0,    // Ashvini
        "Wednesday": 16, // Anuradha
        "Thursday": 7,   // Pushya
        "Friday": 26,    // Revati
        "Saturday": 3,   // Rohini
    ]

    private static let pushyaNakshatraIndex = 7
    private static let raviYogaCounts: Set<Int> = [4, 6, 9, 10, 13, 20]

    static func evaluate(panchang: Panchang) -> [PanchangYogaMatch] {
        var matches: [PanchangYogaMatch] = []

        if sarvarthaSiddhiNakshatraIndices[panchang.weekdayName]?.contains(panchang.nakshatraIndex) == true {
            matches.append(PanchangYogaMatch(
                id: "sarvarthaSiddhi",
                name: "Sarvartha Siddhi Yoga",
                summary: "\(panchang.weekdayName) with \(panchang.nakshatraName) nakshatra is traditionally held to favor undertakings of every kind."
            ))
        }

        if amritSiddhiNakshatraIndex[panchang.weekdayName] == panchang.nakshatraIndex {
            matches.append(PanchangYogaMatch(
                id: "amritSiddhi",
                name: "Amrit Siddhi Yoga",
                summary: "\(panchang.weekdayName) with \(panchang.nakshatraName) nakshatra is a stronger, narrower case of Sarvartha Siddhi Yoga."
            ))
        }

        if panchang.weekdayName == "Thursday" && panchang.nakshatraIndex == pushyaNakshatraIndex {
            matches.append(PanchangYogaMatch(
                id: "guruPushya",
                name: "Guru Pushya Yoga",
                summary: "Pushya nakshatra falling on Thursday is traditionally considered favorable for durable and long-term undertakings."
            ))
        }

        if raviYogaCounts.contains(nakshatraCount(from: panchang.sunNakshatraIndex, to: panchang.nakshatraIndex)) {
            matches.append(PanchangYogaMatch(
                id: "raviYoga",
                name: "Ravi Yoga",
                summary: "The Sun's and Moon's nakshatras stand in a classical Ravi Yoga relationship today."
            ))
        }

        return matches
    }

    /// Inclusive nakshatra count from `start` to `end` around the 27-nakshatra
    /// cycle (counting the start itself as 1), the convention Ravi Yoga's
    /// published count thresholds are stated in.
    static func nakshatraCount(from start: Int, to end: Int) -> Int {
        ((end - start + 27) % 27) + 1
    }

    /// Total (weekday, nakshatra) pairs in the Sarvartha Siddhi table, exposed
    /// so tests can assert against the actual table rather than against a
    /// second, independently-maintained count that could silently drift from it.
    static var sarvarthaSiddhiPairCount: Int {
        sarvarthaSiddhiNakshatraIndices.values.reduce(0) { $0 + $1.count }
    }
}

struct PanchangYogaMatch: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let summary: String
}

// MARK: - Weekday advisories

/// Disha Shula: the direction classically avoided for beginning a journey on
/// each weekday. A fixed lookup with no astronomy. Table cross-checked across
/// multiple independent, mutually consistent published sources (mpanchang,
/// anytimeastro, drikpanchang's daily value) before implementation:
/// Sunday/Friday west, Monday/Saturday east, Tuesday/Wednesday north,
/// Thursday south.
enum DishaShula {
    static let directionByWeekday: [String: String] = [
        "Sunday": "West",
        "Monday": "East",
        "Tuesday": "North",
        "Wednesday": "North",
        "Thursday": "South",
        "Friday": "West",
        "Saturday": "East",
    ]

    static func direction(forWeekdayName weekdayName: String) -> String? {
        directionByWeekday[weekdayName]
    }
}

/// Bhadra (Vishti karana) — the one karana classically treated as a standing
/// caution for new undertakings. No new astronomy: the karana index and its
/// solved end time already exist on the Panchang; this only names the state.
enum BhadraAdvisory {
    /// Panchang.karanaNames index of Vishti.
    static let vishtiKaranaIndex = 6

    static func isActive(karanaIndex: Int) -> Bool {
        karanaIndex == vishtiKaranaIndex
    }

    /// Every Vishti span of the Panchang day, from the karana timeline. The
    /// karana changes roughly twice per civil day, so Bhadra regularly BEGINS
    /// mid-day; the previous sunrise-snapshot check missed any window that
    /// opened after sunrise, while published dailies list every span.
    static func vishtiWindows(context: CalculationContext) -> [PanchangLimbWindow] {
        CosmicEngine.limbWindows(for: .karana, context: context)
            .filter { $0.name == Panchang.karanaNames[vishtiKaranaIndex] }
    }
}

/// Decides whether the visible day should follow the calendar forward when
/// the app returns to the foreground (or midnight passes): only when the
/// user was looking at what was then "today" -- a deliberately selected past
/// or future date is never yanked away.
enum PanchangDayRollover {
    static func shouldAdvance(
        selectedDate: Date,
        knownToday: Date,
        now: Date,
        timeZone: TimeZone
    ) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(selectedDate, inSameDayAs: knownToday)
            && !calendar.isDate(now, inSameDayAs: knownToday)
    }
}
