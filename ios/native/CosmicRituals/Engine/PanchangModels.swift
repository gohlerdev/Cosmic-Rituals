import Foundation

// MARK: - Celestial Bodies
//
// The nine grahas of Vedic astrology. In Cosmic Rituals they appear only as the
// nakshatra (and Vimshottari dasha) lords surfaced in the Panchang reading.

enum CelestialBody: String, CaseIterable, Codable {
    case sun = "Sun"
    case moon = "Moon"
    case mars = "Mars"
    case mercury = "Mercury"
    case jupiter = "Jupiter"
    case venus = "Venus"
    case saturn = "Saturn"
    case rahu = "Rahu"
    case ketu = "Ketu"

    var symbol: String {
        switch self {
        case .sun:     return "☉"
        case .moon:    return "☽"
        case .mars:    return "♂"
        case .mercury: return "☿"
        case .jupiter: return "♃"
        case .venus:   return "♀"
        case .saturn:  return "♄"
        case .rahu:    return "☊"
        case .ketu:    return "☋"
        }
    }
}

// MARK: - Zodiac Sign

struct ZodiacSign: Equatable {
    let index: Int
    let name: String
    let symbol: String
    let element: String
    let quality: String

    static let all: [ZodiacSign] = [
        ZodiacSign(index: 0,  name: "Aries",       symbol: "♈", element: "Fire",  quality: "Cardinal"),
        ZodiacSign(index: 1,  name: "Taurus",      symbol: "♉", element: "Earth", quality: "Fixed"),
        ZodiacSign(index: 2,  name: "Gemini",       symbol: "♊", element: "Air",   quality: "Mutable"),
        ZodiacSign(index: 3,  name: "Cancer",       symbol: "♋", element: "Water", quality: "Cardinal"),
        ZodiacSign(index: 4,  name: "Leo",          symbol: "♌", element: "Fire",  quality: "Fixed"),
        ZodiacSign(index: 5,  name: "Virgo",        symbol: "♍", element: "Earth", quality: "Mutable"),
        ZodiacSign(index: 6,  name: "Libra",        symbol: "♎", element: "Air",   quality: "Cardinal"),
        ZodiacSign(index: 7,  name: "Scorpio",      symbol: "♏", element: "Water", quality: "Fixed"),
        ZodiacSign(index: 8,  name: "Sagittarius",  symbol: "♐", element: "Fire",  quality: "Mutable"),
        ZodiacSign(index: 9,  name: "Capricorn",    symbol: "♑", element: "Earth", quality: "Cardinal"),
        ZodiacSign(index: 10, name: "Aquarius",     symbol: "♒", element: "Air",   quality: "Fixed"),
        ZodiacSign(index: 11, name: "Pisces",       symbol: "♓", element: "Water", quality: "Mutable"),
    ]

    static func fromIndex(_ i: Int) -> ZodiacSign { all[((i % 12) + 12) % 12] }
}

// MARK: - Panchang Transitions

enum PanchangLimbKind: String, CaseIterable, Codable, Sendable {
    case tithi
    case nakshatra
    case yoga
    case karana
}

/// The next exact boundary for one changing Panchang limb.
///
/// Daily labels alone are incomplete because a limb can change at any instant
/// between one sunrise and the next. Keeping the current and next names beside
/// the solved boundary makes the value self-describing for the app, exports,
/// widgets, and accessibility output.
struct PanchangTransition: Codable, Equatable, Sendable {
    let kind: PanchangLimbKind
    let currentName: String
    let nextName: String
    let endTime: Date
}

struct PanchangTransitions: Codable, Equatable, Sendable {
    let tithi: PanchangTransition?
    let nakshatra: PanchangTransition?
    let yoga: PanchangTransition?
    let karana: PanchangTransition?

    static let unavailable = PanchangTransitions(
        tithi: nil,
        nakshatra: nil,
        yoga: nil,
        karana: nil
    )

    var chronological: [PanchangTransition] {
        [tithi, nakshatra, yoga, karana]
            .compactMap { $0 }
            .sorted { $0.endTime < $1.endTime }
    }

    func transition(for kind: PanchangLimbKind) -> PanchangTransition? {
        switch kind {
        case .tithi: return tithi
        case .nakshatra: return nakshatra
        case .yoga: return yoga
        case .karana: return karana
        }
    }
}

// MARK: - Panchang (Five Limbs of the Vedic Day)

struct Panchang: Codable {
    let date: Date
    let tithiIndex: Int
    let tithiName: String
    let nakshatraIndex: Int
    let nakshatraName: String
    /// The Sun's own sidereal nakshatra, distinct from `nakshatraIndex` (the
    /// Moon's), needed for Ravi Yoga's Sun-to-Moon nakshatra count.
    let sunNakshatraIndex: Int
    let yogaIndex: Int
    let yogaName: String
    let karanaIndex: Int
    let karanaName: String
    let weekdayName: String
    let moonSignIndex: Int
    let moonSignName: String
    let sunriseTime: Date?
    let sunsetTime: Date?
    let transitions: PanchangTransitions

    static let tithiNames = [
        "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
        "Shashthi","Saptami","Ashtami","Navami","Dashami",
        "Ekadashi","Dvadashi","Trayodashi","Chaturdashi","Purnima",
        "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
        "Shashthi","Saptami","Ashtami","Navami","Dashami",
        "Ekadashi","Dvadashi","Trayodashi","Chaturdashi","Amavasya"
    ]

    static let nakshatraNames = [
        "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra",
        "Punarvasu","Pushya","Ashlesha","Magha","Purva Phalguni","Uttara Phalguni",
        "Hasta","Chitra","Swati","Vishakha","Anuradha","Jyeshtha",
        "Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishtha","Shatabhisha",
        "Purva Bhadrapada","Uttara Bhadrapada","Revati"
    ]

    static let yogaNames = [
        "Vishkambha","Priti","Ayushman","Saubhagya","Shobhana","Atiganda","Sukarman",
        "Dhriti","Shula","Ganda","Vriddhi","Dhruva","Vyaghata","Harshana","Vajra",
        "Siddhi","Vyatipata","Variyan","Parigha","Shiva","Siddha","Sadhya","Shubha",
        "Shukla","Brahma","Indra","Vaidhriti"
    ]

    static let karanaNames = [
        "Bava","Balava","Kaulava","Taitila","Garija","Vanija","Vishti",
        "Shakuni","Chatushpada","Naga","Kimstughna"
    ]

    func referenceDisclosure(in timeZone: TimeZone) -> String {
        if let sunriseTime {
            return "Panchang day begins at sunrise · \(sunriseTime.ritualShortTime(in: timeZone)) local time"
        }
        return "Sunrise unavailable · sampled at \(date.ritualShortTime(in: timeZone)) local time"
    }
}

// MARK: - Nakshatra Result

struct NakshatraResult: Codable {
    let nakshatraIndex: Int
    let nakshatraName: String
    let pada: Int
    let nakshatraLord: CelestialBody
    let symbol: String
    let gana: String
    let degree: Double

    static let lords: [CelestialBody] = [
        .ketu,.venus,.sun,.moon,.mars,.rahu,
        .jupiter,.saturn,.mercury,.ketu,.venus,.sun,
        .moon,.mars,.rahu,.jupiter,.saturn,.mercury,
        .ketu,.venus,.sun,.moon,.mars,.rahu,
        .jupiter,.saturn,.mercury
    ]

    static let symbols = [
        "🐴","🐘","🔪","🛞","🦌","💎","🏹","🌸","🐍","👑",
        "🛏","🍃","✋","🪆","🐄","🎭","🪷","🦂","🌿","🐘",
        "🐘","🦅","🥁","💫","🛡","🐟","🐟"
    ]

    static let ganas = [
        "Deva","Manushya","Rakshasa","Deva","Manushya","Rakshasa",
        "Deva","Deva","Rakshasa","Rakshasa","Manushya","Manushya",
        "Deva","Rakshasa","Deva","Rakshasa","Deva","Rakshasa",
        "Rakshasa","Manushya","Manushya","Deva","Rakshasa","Deva",
        "Manushya","Manushya","Deva"
    ]
}

// MARK: - Muhurta

enum MuhurtaQuality: String {
    case excellent     = "Excellent"
    case auspicious    = "Auspicious"
    case mixed         = "Mixed"
    case inauspicious  = "Inauspicious"

    var emoji: String {
        switch self {
        case .excellent:    return "★★"
        case .auspicious:   return "★"
        case .mixed:        return "◐"
        case .inauspicious: return "✕"
        }
    }
}

struct Muhurta: Identifiable {
    let id: Int
    let name: String
    let quality: MuhurtaQuality
    let purpose: String
    let startTime: Date
    let endTime: Date
    let isDay: Bool

    var isCurrent: Bool {
        let now = Date()
        return now >= startTime && now < endTime
    }
    var durationMinutes: Double { endTime.timeIntervalSince(startTime) / 60 }
}

// MARK: - Choghadiya

enum ChoghadiyaQuality: String, CaseIterable, Identifiable {
    case amrit = "Amrit"
    case shubh = "Shubh"
    case labh  = "Labh"
    case char  = "Char"
    case udveg = "Udveg"
    case rog   = "Rog"
    case kaal  = "Kaal"

    var id: String { rawValue }

    var planet: CelestialBody {
        switch self {
        case .amrit: return .moon
        case .shubh: return .jupiter
        case .labh:  return .mercury
        case .char:  return .venus
        case .udveg: return .sun
        case .rog:   return .mars
        case .kaal:  return .saturn
        }
    }

    var muhurtaQuality: MuhurtaQuality {
        switch self {
        case .amrit:            return .excellent
        case .shubh, .labh:    return .auspicious
        case .char:             return .mixed
        case .udveg, .rog, .kaal: return .inauspicious
        }
    }

    var detail: String {
        switch self {
        case .amrit: return "Nectar — excellent for all work"
        case .shubh: return "Auspicious — good for new beginnings"
        case .labh:  return "Gain — favourable for business"
        case .char:  return "Movable — suitable for travel"
        case .udveg: return "Anxiety — avoid important work"
        case .rog:   return "Disease — inauspicious period"
        case .kaal:  return "Death — highly inauspicious"
        }
    }
}

struct Choghadiya: Identifiable {
    let id: Int
    let quality: ChoghadiyaQuality
    let startTime: Date
    let endTime: Date
    let isDay: Bool

    var isCurrent: Bool {
        let now = Date()
        return now >= startTime && now < endTime
    }
}

// MARK: - Hora

struct Hora: Identifiable {
    let id: Int
    let planet: CelestialBody
    let startTime: Date
    let endTime: Date
    let isDay: Bool

    var isCurrent: Bool {
        let now = Date()
        return now >= startTime && now < endTime
    }
}

// MARK: - Graha Positions

struct GrahaPosition: Identifiable {
    let id = UUID()
    let body: CelestialBody
    let siderealDegree: Double   // 0–360 sidereal ecliptic longitude
    let signIndex: Int           // 0–11
    let signName: String
    let signSymbol: String
    let degreeInSign: Double     // 0–30
    let isRetrograde: Bool
}

// MARK: - Vedic Calendar Extended Info

struct VedicCalendarInfo {
    // Traditional calendar systems
    let vikramSamvat: Int
    let shakaSamvat: Int
    let amantaMasa: String        // South Indian / Gujarat naming (new-moon based)
    let purnimantaMasa: String    // North Indian naming (full-moon based)

    // Cosmic positioning
    let ayana: String             // Uttarayan or Dakshinayan (sidereal)
    let vedaRitu: String          // Vasanta/Grishma/Varsha/Sharad/Hemanta/Shishira (sidereal)
    let drikRitu: String          // Tropical season (Drik system)

    // Daily yogas and quality
    let anandadiYoga: String
    let anandadiIsAuspicious: Bool
    let anandadiMeaning: String

    // Amrit Kaal (auspicious nectar window = Amrit Choghadiya)
    let amritKaalStart: Date?
    let amritKaalEnd: Date?

    // Chandrashtama (for birth nakshatra users)
    let chandrashtamaNakshatra: String  // the nakshatra that is 8th from birth
    let isCurrentlyChandrashtama: Bool  // if today's Moon nakshatra = chandrashtama
}

// MARK: - Helpers

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
