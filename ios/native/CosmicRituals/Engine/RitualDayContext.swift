import Foundation

/// A display-ready receipt of the day and place used by the Panchang engine.
/// It deliberately carries facts, not a claim that a specific rite is required
/// or universally auspicious on that day.
struct RitualDayContext: Equatable, Sendable {
    let civilDate: String
    let locationName: String
    let timeZoneIdentifier: String
    let tithiName: String
    let nakshatraName: String
    let sunriseTime: String?

    var sunriseDisclosure: String {
        sunriseTime.map { "Sunrise \($0)" } ?? "Sunrise unavailable at this latitude"
    }
}
