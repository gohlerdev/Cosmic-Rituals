import Foundation

/// The complete civil-time and geographic context for one Panchang calculation.
///
/// `Date` is an absolute instant, while the UI selects a civil calendar day. Keeping
/// the calendar and time zone beside the coordinates prevents that selected day from
/// silently becoming the previous UTC day in eastern time zones.
struct CalculationContext: Equatable, Sendable {
    static let dailySnapshotReferenceHour = 12
    static let dailySnapshotDisclosure = "Daily Panchang reference · sampled at 12:00 PM local time"

    let localDay: Date
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    init(localDay: Date, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        self.localDay = localDay
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = TimeZone(identifier: timeZoneIdentifier)?.identifier ?? TimeZone.gmt.identifier
    }

    init(localDay: Date, location: RitualLocation) {
        self.init(
            localDay: localDay,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: location.timeZoneIdentifier
        )
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .gmt
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2 // Monday; shared by week and month views.
        return calendar
    }

    var localDayStart: Date {
        calendar.startOfDay(for: localDay)
    }

    /// A deterministic instant for day-level lunar calculations.
    /// Noon exists on ordinary DST-transition days and does not inherit a hidden
    /// time component from whichever date picker last changed the selection.
    var localNoon: Date {
        calendar.date(
            bySettingHour: Self.dailySnapshotReferenceHour,
            minute: 0,
            second: 0,
            of: localDayStart
        ) ?? localDayStart
    }

    var localDayComponents: DateComponents {
        calendar.dateComponents([.year, .month, .day, .weekday], from: localDayStart)
    }

    func advancedByLocalDays(_ days: Int) -> CalculationContext {
        let advanced = calendar.date(byAdding: .day, value: days, to: localDayStart) ?? localDayStart
        return CalculationContext(
            localDay: advanced,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}

/// Centralized presentation helpers. Every visible civil date or clock time is
/// formatted in the active calculation location's time zone, never implicitly in
/// the device zone.
extension Date {
    func ritualShortTime(in timeZone: TimeZone, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    func ritualCompleteDate(in timeZone: TimeZone, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    func ritualDate(
        template: String,
        in timeZone: TimeZone,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: self)
    }
}
