import Foundation

// MARK: - Sidereal schools: which ayanamsha the day is measured from
//
// The app computes every limb, muhurta, and nakshatra from ONE sidereal
// chokepoint (`CosmicEngine.siderealize`), and that chokepoint has always
// been Lahiri. Professional panchang software instead treats the ayanamsha as
// a user-visible choice, because a few arcminutes can move a nakshatra
// boundary -- and therefore a muhurta -- across a day.
//
// WHICH LAHIRI. "Lahiri" is not one number. The Swiss Ephemeris source
// (sweph.h, `ayanamsa[]`) documents two definitions in the same comment: the
// NOVA / Robert Hand anchoring {J1900, 360 - 337.53953} = 22.460470 deg, and
// the Calendar Reform Committee / Indian Astronomical Ephemeris anchoring
// {2435553.5, 23.250182778 - 0.004658035}. THIS APP IMPLEMENTS THE NOVA
// VARIANT: its polynomial run back one Julian century gives 22.460204 deg at
// J1900, which agrees with the NOVA value to 0.96 arcsec. That is now stated
// rather than left implicit -- a reader comparing against a CRC-based
// almanac is comparing against a different Lahiri.
//
// HOW THE ALTERNATIVES ARE DERIVED. Every school here is anchored at J1900 in
// the same Swiss Ephemeris table, under the same Newcomb-family precession,
// so the DIFFERENCE between two of them is a constant the precession model
// cancels out of. The offsets are therefore exact subtractions of published
// constants, not an independent precession model this app would have to
// verify separately:
//
//   Lahiri  (NOVA, J1900)       360 - 337.53953   = 22.460470
//   Raman   (SE_SIDM_RAMAN)     360 - 338.98556   = 21.014440  -> -1.446030 deg
//   KP      (SE_SIDM_KRISHNAMURTI) 360 - 337.636111 = 22.363889 -> -0.096581 deg
//
// Both offsets corroborate independently published comparisons (Raman about
// 1.45 deg below Lahiri; KP about 6 arcminutes below).
//
// DELIBERATELY ABSENT. Fagan/Bradley is Western sidereal, anchored at a
// different epoch under a different precession model, and is not a panchang
// school -- it is not offered. Nor is any school whose constant this project
// has not read at source: a school that cannot be cited does not ship.

enum AyanamshaSchool: String, CaseIterable, Identifiable, Sendable {
    case lahiri
    case raman
    case krishnamurti

    var id: String { rawValue }

    /// The app's default, and the school every published fixture is pinned to.
    static let `default`: AyanamshaSchool = .lahiri

    var title: String {
        switch self {
        case .lahiri: return "Lahiri (Chitra Paksha)"
        case .raman: return "Raman"
        case .krishnamurti: return "Krishnamurti (KP)"
        }
    }

    /// Degrees to add to the Lahiri ayanamsha to obtain this school's.
    /// Zero for Lahiri itself by construction.
    var offsetFromLahiriDegrees: Double {
        switch self {
        case .lahiri: return 0
        case .raman: return (360 - 338.98556) - (360 - 337.53953)
        case .krishnamurti: return (360 - 337.636111) - (360 - 337.53953)
        }
    }

    /// The offset in arcminutes, for display.
    var offsetArcminutes: Double { offsetFromLahiriDegrees * 60 }

    var citation: String {
        switch self {
        case .lahiri:
            return "Swiss Ephemeris sweph.h, SE_SIDM_LAHIRI comment: the NOVA / Robert Hand anchoring {J1900, 360 − 337.53953}. This app's polynomial matches that variant to under an arcsecond; the Calendar Reform Committee anchoring is a different Lahiri."
        case .raman:
            return "Swiss Ephemeris sweph.h, SE_SIDM_RAMAN: {J1900, 360 − 338.98556}, Newcomb precession — the same epoch and precession family as the Lahiri row, so the difference is a constant."
        case .krishnamurti:
            return "Swiss Ephemeris sweph.h, SE_SIDM_KRISHNAMURTI: {J1900, 360 − 337.636111}, Newcomb precession — same epoch and family as the Lahiri row."
        }
    }
}

extension CosmicEngine {

    /// The ayanamsha of a given school at a Julian date.
    static func ayanamsha(year: Double, school: AyanamshaSchool) -> Double {
        lahiriAyanamsha(year: year) + school.offsetFromLahiriDegrees
    }

    /// Sidereal longitude under a chosen school. The two-argument
    /// `siderealize` remains Lahiri, so every published fixture and every
    /// existing call site keeps its meaning untouched.
    static func siderealize(_ tropical: Double, jd: Double, school: AyanamshaSchool) -> Double {
        let year = 2000.0 + (jd - J2000) / 365.25
        return normalize360(tropical - ayanamsha(year: year, school: school))
    }
}

// MARK: - What actually changes when the school changes

/// One school's reading of the day's two most boundary-sensitive limbs.
struct SiderealSchoolReading: Equatable, Identifiable {
    let school: AyanamshaSchool
    /// 0-26, Ashwini..Revati, at the Panchang reference instant.
    let moonNakshatraIndex: Int
    let moonNakshatraName: String
    /// 1-4.
    let moonPada: Int
    /// The Moon's sidereal longitude, for readers who want the raw number.
    let moonSiderealDegrees: Double

    var id: String { school.rawValue }
}

enum SiderealSchoolComparison {

    /// Each school's reading of the day, at the Panchang's own sunrise
    /// reference instant. Empty when sunrise does not exist -- the same
    /// fail-closed rule the rest of the app follows.
    static func readings(context: CalculationContext) -> [SiderealSchoolReading] {
        let reference = CosmicEngine.panchangReferenceDate(for: context)
        let jd = CosmicEngine.julianDateFromDate(reference)
        let tropicalMoon = CosmicEngine.moonLongitude(jd: jd)

        return AyanamshaSchool.allCases.map { school in
            let sidereal = CosmicEngine.siderealize(tropicalMoon, jd: jd, school: school)
            let nakshatra = CosmicEngine.getNakshatraPada(sidereal)
            return SiderealSchoolReading(
                school: school,
                moonNakshatraIndex: nakshatra.nakshatraIndex,
                moonNakshatraName: nakshatra.nakshatraName,
                moonPada: nakshatra.pada,
                moonSiderealDegrees: sidereal
            )
        }
    }

    /// True when the schools do not agree on the Moon's nakshatra today --
    /// the case worth surfacing, because it moves every nakshatra-derived
    /// window.
    static func nakshatraDisagrees(context: CalculationContext) -> Bool {
        let all = readings(context: context)
        return Set(all.map(\.moonNakshatraIndex)).count > 1
    }

    /// True when the schools agree on the nakshatra but not on the pada --
    /// a quieter divergence that still moves pada-keyed readings.
    static func padaDisagrees(context: CalculationContext) -> Bool {
        let all = readings(context: context)
        guard Set(all.map(\.moonNakshatraIndex)).count == 1 else { return false }
        return Set(all.map(\.moonPada)).count > 1
    }
}
