import AppIntents
import Foundation

enum IntentCalculationContext {
    static func resolve(for day: Date, defaults: UserDefaults = .standard) -> (CalculationContext, RitualLocation)? {
        guard let location = RitualLocationStore.load(defaults: defaults) else { return nil }
        return (CalculationContext(localDay: day, location: location), location)
    }
}

private func shortTime(_ date: Date, in timeZone: TimeZone) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = timeZone
    return formatter.string(from: date)
}

// MARK: - "What's the muhurta right now?" Intent

struct CurrentMuhurtaIntent: AppIntent {
    static let title: LocalizedStringResource = "Current Muhurta"
    static let description = IntentDescription("Tell me what the current muhurta is and its quality.")

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        guard let (context, location) = IntentCalculationContext.resolve(for: Date()) else {
            let reply = "Open Cosmic Rituals and choose a calculation location before using this shortcut."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        let muhurtas = CosmicEngine.getMuhurtas(context: context)
        guard !muhurtas.isEmpty else {
            let reply = "Sunrise-based timing is unavailable for \(location.name) today."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        if let current = muhurtas.first(where: { $0.isCurrent }) {
            let endTime = shortTime(current.endTime, in: context.timeZone)
            let reply = "\(current.name) muhurta — \(current.quality.rawValue). \(current.purpose) It runs until \(endTime)."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        } else {
            return .result(value: "No muhurta active right now.", dialog: "No muhurta is active right now.")
        }
    }
}

// MARK: - Daily Panchang Snapshot Intent

struct TodayPanchangIntent: AppIntent {
    static let title: LocalizedStringResource = "Daily Panchang Snapshot"
    static let description = IntentDescription("Get the five limbs sampled at local noon: Vara, Tithi, Nakshatra, Yoga, and Karana.")

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        guard let (context, location) = IntentCalculationContext.resolve(for: Date()) else {
            let reply = "Open Cosmic Rituals and choose a calculation location before using this shortcut."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        let p = CosmicEngine.getPanchang(context: context)
        let summary = "Daily reference for \(location.name), sampled at 12:00 PM local time. \(p.weekdayName). Tithi: \(p.tithiName). Nakshatra: \(p.nakshatraName). Yoga: \(p.yogaName). Karana: \(p.karanaName)."
        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

// MARK: - "When's the next auspicious time?" Intent

struct NextAuspiciousTimeIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Auspicious Muhurta"
    static let description = IntentDescription("Find the next excellent or auspicious muhurta today.")

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let now = Date()
        guard let (context, location) = IntentCalculationContext.resolve(for: now) else {
            let reply = "Open Cosmic Rituals and choose a calculation location before using this shortcut."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        let muhurtas = CosmicEngine.getMuhurtas(context: context)
        guard !muhurtas.isEmpty else {
            let reply = "Sunrise-based timing is unavailable for \(location.name) today."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        let upcoming = muhurtas.first {
            ($0.quality == .excellent || $0.quality == .auspicious) && $0.endTime > now
        }
        if let m = upcoming {
            let when = m.isCurrent ? "right now" : "at \(shortTime(m.startTime, in: context.timeZone))"
            let reply = "The next auspicious muhurta is \(m.name) — \(m.quality.rawValue) — \(when)."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        } else {
            return .result(value: "No more auspicious muhurtas today.", dialog: "No more auspicious muhurtas today.")
        }
    }
}

// MARK: - Shortcut Provider

struct CosmicShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CurrentMuhurtaIntent(),
            phrases: [
                "What's the muhurta right now in \(.applicationName)",
                "Current muhurta in \(.applicationName)",
                "What muhurta is it in \(.applicationName)"
            ],
            shortTitle: "Current Muhurta",
            systemImageName: "clock.badge.checkmark.fill"
        )
        AppShortcut(
            intent: TodayPanchangIntent(),
            phrases: [
                "Daily Panchang snapshot in \(.applicationName)",
                "Panchang noon reference in \(.applicationName)",
                "Vedic day snapshot in \(.applicationName)"
            ],
            shortTitle: "Daily Snapshot",
            systemImageName: "hand.raised.fill"
        )
        AppShortcut(
            intent: NextAuspiciousTimeIntent(),
            phrases: [
                "When's the next auspicious time in \(.applicationName)",
                "Next good muhurta in \(.applicationName)",
                "Best time today in \(.applicationName)"
            ],
            shortTitle: "Next Auspicious Time",
            systemImageName: "star.circle.fill"
        )
    }
}
