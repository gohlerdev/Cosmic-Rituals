// Lightweight subset of CosmicEngine needed by the widget extension.
// Pure math — no UIKit, no SwiftUI beyond what WidgetKit provides.
import Foundation

// MARK: - Minimal Type Aliases

enum WidgetMuhurtaQuality: String {
    case excellent    = "Excellent"
    case auspicious   = "Auspicious"
    case mixed        = "Mixed"
    case inauspicious = "Inauspicious"

    var emoji: String {
        switch self {
        case .excellent:    return "✨"
        case .auspicious:   return "🌿"
        case .mixed:        return "〰"
        case .inauspicious: return "⚠"
        }
    }
}

struct WidgetMuhurta {
    let name: String
    let purpose: String
    let quality: WidgetMuhurtaQuality
    let startTime: Date
    let endTime: Date
}

// MARK: - Julian Date

private let J2000 = 2451545.0

private func jd(from date: Date) -> Double {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    var y = c.year ?? 2000, m = c.month ?? 1
    if m <= 2 { y -= 1; m += 12 }
    let A = Int(Double(y) / 100)
    let B = 2 - A + Int(Double(A) / 4)
    let hr = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60 + Double(c.second ?? 0) / 3600
    let day = Double(c.day ?? 1) + hr / 24.0
    return Double(Int(365.25 * Double(y + 4716))) + Double(Int(30.6001 * Double(m + 1))) + day + Double(B) - 1524.5
}

private func norm360(_ d: Double) -> Double {
    var v = d.truncatingRemainder(dividingBy: 360); if v < 0 { v += 360 }; return v
}

private let DEG = Double.pi / 180

// MARK: - Sun & Moon (abridged from Meeus)

private func sunLon(jd: Double) -> Double {
    let T  = (jd - J2000) / 36525
    let L0 = norm360(280.46646 + 36000.76983 * T)
    let M  = norm360(357.52911 + 35999.05029 * T) * DEG
    let C  = (1.914602 - 0.004817 * T) * sin(M) + 0.019993 * sin(2 * M)
    return norm360(L0 + C)
}

private func moonLon(jd: Double) -> Double {
    let T  = (jd - J2000) / 36525
    let L  = norm360(218.3164477 + 481267.88123421 * T)
    let M  = norm360(357.5291 + 35999.0503 * T) * DEG
    let Mm = norm360(134.9634 + 477198.8676 * T) * DEG
    let D  = norm360(297.8502 + 445267.1115 * T) * DEG
    let F  = norm360(93.2721 + 483202.0175 * T) * DEG
    let corr = 6.289 * sin(Mm) - 1.274 * sin(2 * D - Mm) + 0.658 * sin(2 * D)
             - 0.214 * sin(2 * Mm) - 0.186 * sin(M) - 0.114 * sin(2 * F)
    return norm360(L + corr)
}

// MARK: - Sunrise / Sunset (NOAA simplified)

private func solarDeclination(jd: Double) -> Double {
    let T     = (jd - J2000) / 36525
    let L     = norm360(280.46646 + 36000.76983 * T)
    let M_deg = norm360(357.52911 + 35999.05029 * T)
    let M     = M_deg * DEG
    let C     = (1.914602 - 0.004817 * T) * sin(M) + 0.019993 * sin(2 * M)
    let sunLonDeg = L + C
    let obliq = (23.439 - 0.0000004 * (jd - J2000)) * DEG
    return asin(sin(obliq) * sin(sunLonDeg * DEG)) / DEG
}

func widgetSunriseSunset(date: Date, latDeg: Double, lonDeg: Double) -> (sunrise: Date, sunset: Date)? {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    let comps = cal.dateComponents([.year, .month, .day], from: date)
    let julD = jd(from: cal.date(from: comps) ?? date)
    let decl = solarDeclination(jd: julD) * DEG
    let lat  = latDeg * DEG

    let cosH = (cos(90.833 * DEG) - sin(lat) * sin(decl)) / (cos(lat) * cos(decl))
    guard cosH >= -1 && cosH <= 1 else { return nil }

    let H    = acos(cosH) / DEG
    let noon = 12.0 + (360 - lonDeg) / 15.0  // rough local solar noon in UT

    let riseHour = noon - H / 15
    let setHour  = noon + H / 15

    func toDate(_ utcHour: Double) -> Date? {
        let h   = Int(utcHour); let m = Int((utcHour - Double(h)) * 60)
        var dc  = comps; dc.hour = h; dc.minute = m; dc.second = 0
        return cal.date(from: dc)
    }
    guard let r = toDate(riseHour), let s = toDate(setHour) else { return nil }
    return (r, s)
}

// MARK: - Muhurta names (abridged — same table as MuhurtaLibrary)

private let dayMuhurtaNames: [(String, String, WidgetMuhurtaQuality)] = [
    ("Rudra",       "Fierce; avoid new beginnings",            .inauspicious),
    ("Ahi",         "Serpent power; use for reflection",       .inauspicious),
    ("Mitra",       "Friendship and alliances",                .auspicious),
    ("Pitru",       "Ancestral blessings",                     .mixed),
    ("Vasu",        "Wealth and prosperity",                   .auspicious),
    ("Vara",        "Auspicious; favors rituals",              .auspicious),
    ("Vishwedeva",  "All-divine; excellent for ceremonies",    .excellent),
    ("Vidhi",       "Method and order; mixed",                 .mixed),
    ("Sutamukhi",   "Nurturing speech and relations",         .auspicious),
    ("Puruhuta",    "Many-gifted; auspicious for worship",    .excellent),
    ("Vahini",      "Flowing energy; good for travel",        .auspicious),
    ("Naktanakara", "Night-like; inauspicious",               .inauspicious),
    ("Varuna",      "Water lord; purification",               .auspicious),
    ("Aryaman",     "Nobility and honour; excellent",          .excellent),
    ("Bhaga",       "Good fortune; highly auspicious",        .excellent),
]

private let nightMuhurtaNames: [(String, String, WidgetMuhurtaQuality)] = [
    ("Girish",      "Shiva's hour; spiritual practice",        .auspicious),
    ("Ajapada",     "Stillness and introspection",             .mixed),
    ("Ahirbudhnya", "Deep waters; creative depth",             .auspicious),
    ("Pushya",      "Nourishment; extremely auspicious",       .excellent),
    ("Ashwini",     "Swift healing and new starts",            .excellent),
    ("Yama",        "Death lord; avoid auspicious acts",       .inauspicious),
    ("Agni",        "Fire lord; purification rites",           .mixed),
    ("Vidhatr",     "Creator; good for learning",              .auspicious),
    ("Kanda",       "Bulb/root; planting seeds",               .mixed),
    ("Aditi",       "Infinity; spiritual devotion",            .excellent),
    ("Jiva",        "Life force; highly auspicious",           .excellent),
    ("Vishnu",      "Preservation; excellent for all",         .excellent),
    ("Dyumadgadyuti","Brilliant; auspicious activities",       .auspicious),
    ("Brahma",      "Creator energy; study & creation",        .excellent),
    ("Samudram",    "Ocean depth; mixed results",              .mixed),
]

// MARK: - Widget Muhurta List

func widgetMuhurtas(date: Date, latDeg: Double, lonDeg: Double) -> [WidgetMuhurta] {
    guard let ss = widgetSunriseSunset(date: date, latDeg: latDeg, lonDeg: lonDeg),
          let ssNext = widgetSunriseSunset(date: date.addingTimeInterval(86400), latDeg: latDeg, lonDeg: lonDeg)
    else { return [] }

    let dayLen   = ss.sunset.timeIntervalSince(ss.sunrise) / 15
    let nightLen = ssNext.sunrise.timeIntervalSince(ss.sunset) / 15
    var result: [WidgetMuhurta] = []

    for i in 0..<15 {
        let start = ss.sunrise.addingTimeInterval(Double(i) * dayLen)
        let (name, purpose, quality) = dayMuhurtaNames[i]
        result.append(WidgetMuhurta(name: name, purpose: purpose, quality: quality,
                                    startTime: start, endTime: start.addingTimeInterval(dayLen)))
    }
    for i in 0..<15 {
        let start = ss.sunset.addingTimeInterval(Double(i) * nightLen)
        let (name, purpose, quality) = nightMuhurtaNames[i]
        result.append(WidgetMuhurta(name: name, purpose: purpose, quality: quality,
                                    startTime: start, endTime: start.addingTimeInterval(nightLen)))
    }
    return result
}

func currentWidgetMuhurta(date: Date, latDeg: Double, lonDeg: Double) -> WidgetMuhurta? {
    let all = widgetMuhurtas(date: date, latDeg: latDeg, lonDeg: lonDeg)
    return all.first { date >= $0.startTime && date < $0.endTime }
}

// MARK: - Panchang (minimal)

struct WidgetPanchang {
    let weekday: String
    let tithiName: String
    let nakshatraName: String
    let yogaName: String
    let karanaName: String
    let moonSign: String
}

private let tithiNames = [
    "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
    "Shashthi","Saptami","Ashtami","Navami","Dashami",
    "Ekadashi","Dwadashi","Trayodashi","Chaturdashi","Purnima",
    "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
    "Shashthi","Saptami","Ashtami","Navami","Dashami",
    "Ekadashi","Dwadashi","Trayodashi","Chaturdashi","Amavasya"
]

private let nakshatraNames = [
    "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra",
    "Punarvasu","Pushya","Ashlesha","Magha","Purva Phalguni","Uttara Phalguni",
    "Hasta","Chitra","Swati","Vishakha","Anuradha","Jyeshtha",
    "Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishtha","Shatabhisha",
    "Purva Bhadrapada","Uttara Bhadrapada","Revati"
]

private let yogaNames = [
    "Vishkambha","Preeti","Ayushman","Saubhagya","Shobhana","Atiganda","Sukarman",
    "Dhriti","Shoola","Ganda","Vriddhi","Dhruva","Vyaghata","Harshana","Vajra",
    "Siddhi","Vyatipata","Variyana","Parigha","Shiva","Siddha","Sadhya","Shubha",
    "Shukla","Brahma","Indra","Vaidhriti"
]

private let karanaNames = [
    "Bava","Balava","Kaulava","Taitila","Gara","Vanija","Vishti",
    "Bava","Balava","Kaulava","Taitila"
]

private let rashiNames = [
    "Mesha (Aries)","Vrishabha (Taurus)","Mithuna (Gemini)","Karka (Cancer)",
    "Simha (Leo)","Kanya (Virgo)","Tula (Libra)","Vrischika (Scorpio)",
    "Dhanu (Sagittarius)","Makara (Capricorn)","Kumbha (Aquarius)","Meena (Pisces)"
]

private let lahiriC0 = 23.85709239
private let lahiriC1 = 50.25792860
private let lahiriC2 = 0.0222

private func lahiriAyanamsha(_ jdVal: Double) -> Double {
    let t = 2000.0 + (jdVal - J2000) / 365.25 - 2000.0
    return lahiriC0 + (lahiriC1 * t + lahiriC2 * t * t) / 3600.0
}

private func sidereal(_ tropical: Double, jdVal: Double) -> Double {
    let yr = 2000.0 + (jdVal - J2000) / 365.25
    return norm360(tropical - lahiriAyanamsha(jdVal))
}

func widgetPanchang(date: Date) -> WidgetPanchang {
    let jdVal = jd(from: date)
    let sLon  = sidereal(sunLon(jd: jdVal), jdVal: jdVal)
    let mLon  = sidereal(moonLon(jd: jdVal), jdVal: jdVal)

    let elong    = norm360(moonLon(jd: jdVal) - sunLon(jd: jdVal))
    let tithiIdx = min(Int(elong / 12), 29)
    let nakIdx   = min(Int(mLon / (360.0 / 27)), 26)
    let yogaDeg  = norm360(sLon + mLon)
    let yogaIdx  = min(Int(yogaDeg / (360.0 / 27)), 26)
    let karanaIdx = (tithiIdx * 2) % 11
    let rashiIdx  = Int(mLon / 30) % 12

    let cal = Calendar.current
    let wd  = cal.component(.weekday, from: date)
    let weekdays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    return WidgetPanchang(
        weekday: weekdays[(wd - 1) % 7],
        tithiName: tithiNames[tithiIdx],
        nakshatraName: nakshatraNames[nakIdx],
        yogaName: yogaNames[yogaIdx],
        karanaName: karanaNames[karanaIdx],
        moonSign: rashiNames[rashiIdx]
    )
}
