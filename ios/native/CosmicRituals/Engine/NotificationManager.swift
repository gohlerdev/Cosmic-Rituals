import Foundation
import UserNotifications

// MARK: - Notification Manager

final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    /// Alerts remain intentionally disabled until the app ships an explicit,
    /// user-controlled authorization and refresh workflow. Clear identifiers from
    /// older builds so changed dates or locations cannot leave stale ritual alerts.
    func clearPendingRitualNotifications() async {
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter(Self.isRitualNotificationIdentifier)
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    static func isRitualNotificationIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix("muhurta.") || identifier.hasPrefix("brahma.")
    }
}
