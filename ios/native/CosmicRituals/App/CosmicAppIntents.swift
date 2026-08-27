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

private func spokenTransition(
    _ transition: PanchangTransition?,
    relativeTo referenceDate: Date,
    in timeZone: TimeZone
) -> String {
    guard let transition else { return "transition unavailable" }
    let ending = transition.endTime.ritualTransitionLabel(relativeTo: referenceDate, in: timeZone)
    return "\(transition.currentName) until \(ending), then \(transition.nextName)"
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
    static let description = IntentDescription("Get the five limbs at local sunrise, with their next transition times.")

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        guard let (context, location) = IntentCalculationContext.resolve(for: Date()) else {
            let reply = "Open Cosmic Rituals and choose a calculation location before using this shortcut."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        let p = CosmicEngine.getPanchang(context: context)
        let reference = p.sunriseTime == nil
            ? "Sunrise is unavailable; this snapshot uses \(shortTime(p.date, in: context.timeZone)) local time."
            : "The Panchang day begins at local sunrise."
        let summary = "Daily reference for \(location.name). \(reference) \(p.weekdayName). Tithi: \(spokenTransition(p.transitions.tithi, relativeTo: p.date, in: context.timeZone)). Nakshatra: \(spokenTransition(p.transitions.nakshatra, relativeTo: p.date, in: context.timeZone)). Yoga: \(spokenTransition(p.transitions.yoga, relativeTo: p.date, in: context.timeZone)). Karana: \(spokenTransition(p.transitions.karana, relativeTo: p.date, in: context.timeZone))."
        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

// MARK: - "When's the next auspicious time?" Intent

struct InauspiciousPeriodsIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Inauspicious Kalas"
    static let description = IntentDescription("Rahu Kala, Yamaganda, and Gulika Kala for today, and whether one is running now.")

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let now = Date()
        guard let (context, location) = IntentCalculationContext.resolve(for: now) else {
            let reply = "Open Cosmic Rituals and choose a calculation location before using this shortcut."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        let kalas: [(String, (start: Date, end: Date)?)] = [
            ("Rahu Kala", CosmicEngine.getRahuKala(context: context)),
            ("Yamaganda", CosmicEngine.getYamaganda(context: context)),
            ("Gulika Kala", CosmicEngine.getGulikaKala(context: context)),
        ]
        guard kalas.contains(where: { $0.1 != nil }) else {
            let reply = "No sunrise exists for \(location.name) today, so the sunrise-based kalas do not exist."
            return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
        }
        var parts: [String] = []
        var runningNow: String?
        for (name, window) in kalas {
            guard let window else { continue }
            parts.append("\(name) \(shortTime(window.start, in: context.timeZone))–\(shortTime(window.end, in: context.timeZone))")
            if window.start <= now, now < window.end { runningNow = name }
        }
        let status = runningNow.map { "\($0) is running right now. " } ?? ""
        let reply = status + "Today at \(location.name): " + parts.joined(separator: ", ") + "."
        return .result(value: reply, dialog: IntentDialog(stringLiteral: reply))
    }
}

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
            var reply = "The next auspicious muhurta is \(m.name) — \(m.quality.rawValue) — \(when)."
            // The screen shows the kala card next to the muhurta list; a
            // voice answer must carry the same caveat instead of silently
            // recommending a window that overlaps Rahu Kala.
            if let rahu = CosmicEngine.getRahuKala(context: context),
               m.startTime < rahu.end, rahu.start < m.endTime {
                reply += " Note: it overlaps Rahu Kala (\(shortTime(rahu.start, in: context.timeZone))–\(shortTime(rahu.end, in: context.timeZone))), which tradition treats as inauspicious."
            }
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
                "Panchang sunrise reference in \(.applicationName)",
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
        AppShortcut(
            intent: InauspiciousPeriodsIntent(),
            phrases: [
                "When is Rahu Kala in \(.applicationName)",
                "Is now inauspicious in \(.applicationName)",
                "Today's inauspicious times in \(.applicationName)"
            ],
            shortTitle: "Inauspicious Kalas",
            systemImageName: "exclamationmark.triangle.fill"
        )
    }
}
