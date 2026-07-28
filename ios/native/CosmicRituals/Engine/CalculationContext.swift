import Foundation

/// The complete civil-time and geographic context for one Panchang calculation.
///
/// `Date` is an absolute instant, while the UI selects a civil calendar day. Keeping
/// the calendar and time zone beside the coordinates prevents that selected day from
/// silently becoming the previous UTC day in eastern time zones.
struct CalculationContext: Equatable, Sendable {
    static let polarFallbackReferenceHour = 12

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

    /// Deterministic fallback for dates and latitudes where sunrise is unavailable.
    /// Noon exists on ordinary DST-transition days and does not inherit a hidden
    /// time component from whichever date picker last changed the selection.
    var localNoon: Date {
        calendar.date(
            bySettingHour: Self.polarFallbackReferenceHour,
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
    /// Reinterprets the source location's year-month-day in another time zone.
    /// The selected Panchang value is a civil day, not an instant; using local
    /// noon avoids nonexistent-midnight edge cases on historical clock changes.
    func ritualCivilDay(
        preservingDateFrom sourceTimeZone: TimeZone,
        into targetTimeZone: TimeZone
    ) -> Date {
        var sourceCalendar = Calendar(identifier: .gregorian)
        sourceCalendar.timeZone = sourceTimeZone
        let day = sourceCalendar.dateComponents([.year, .month, .day], from: self)

        var targetCalendar = Calendar(identifier: .gregorian)
        targetCalendar.timeZone = targetTimeZone
        var targetComponents = day
        targetComponents.hour = CalculationContext.polarFallbackReferenceHour
        return targetCalendar.date(from: targetComponents) ?? self
    }

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

    /// A clock time for same-day events and an unambiguous civil date plus time
    /// when an astronomical transition falls after midnight in the active place.
    func ritualTransitionLabel(
        relativeTo referenceDate: Date,
        in timeZone: TimeZone,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let time = ritualShortTime(in: timeZone, locale: locale)
        guard !calendar.isDate(self, inSameDayAs: referenceDate) else { return time }
        let civilDate = ritualDate(template: "EEE d MMM", in: timeZone, locale: locale)
        return "\(civilDate) · \(time)"
    }
}
