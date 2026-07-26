import WidgetKit
import SwiftUI

// MARK: - Shared location helper (reads from UserDefaults group.com.cosmic.rituals)

private func widgetLocation() -> (lat: Double, lon: Double) {
    let defaults = UserDefaults(suiteName: "group.com.cosmic.rituals")
    let lat = defaults?.double(forKey: "widgetLatitude")  ?? 28.6139
    let lon = defaults?.double(forKey: "widgetLongitude") ?? 77.2090
    return (lat.isZero ? 28.6139 : lat, lon.isZero ? 77.2090 : lon)
}

// MARK: - Small Widget: Current Muhurta

struct MuhurtaEntry: TimelineEntry {
    let date: Date
    let muhurta: WidgetMuhurta?
    let timeRemaining: String
}

struct MuhurtaProvider: TimelineProvider {
    func placeholder(in context: Context) -> MuhurtaEntry {
        MuhurtaEntry(date: .now, muhurta: WidgetMuhurta(name: "Abhijit",
            purpose: "Excellent for all auspicious activities",
            quality: .excellent, startTime: .now, endTime: .now.addingTimeInterval(3600)),
            timeRemaining: "48 min")
    }

    func getSnapshot(in context: Context, completion: @escaping (MuhurtaEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MuhurtaEntry>) -> Void) {
        let loc  = widgetLocation()
        let now  = Date()
        let all  = widgetMuhurtas(date: now, latDeg: loc.lat, lonDeg: loc.lon)
        var entries: [MuhurtaEntry] = []

        for m in all {
            guard m.endTime > now else { continue }
            let start = max(m.startTime, now)
            let remaining = Int(m.endTime.timeIntervalSince(start) / 60)
            let label = remaining > 0 ? "\(remaining) min" : "ending"
            entries.append(MuhurtaEntry(date: start, muhurta: m, timeRemaining: label))
            if entries.count >= 12 { break }
        }

        if entries.isEmpty {
            entries.append(MuhurtaEntry(date: now, muhurta: nil, timeRemaining: ""))
        }

        // Reload after the last muhurta
        let nextReload = all.last?.endTime ?? now.addingTimeInterval(3600 * 12)
        completion(Timeline(entries: entries, policy: .after(nextReload)))
    }
}

// MARK: - Medium Widget: Five Limbs

struct PanchangEntry: TimelineEntry {
    let date: Date
    let panchang: WidgetPanchang
    let muhurta: WidgetMuhurta?
}

struct PanchangProvider: TimelineProvider {
    func placeholder(in context: Context) -> PanchangEntry {
        PanchangEntry(date: .now, panchang: widgetPanchang(date: .now), muhurta: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PanchangEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PanchangEntry>) -> Void) {
        let loc = widgetLocation()
        let now = Date()
        let p   = widgetPanchang(date: now)
        let m   = currentWidgetMuhurta(date: now, latDeg: loc.lat, lonDeg: loc.lon)
        let entry = PanchangEntry(date: now, panchang: p, muhurta: m)
        let next  = Calendar.current.date(byAdding: .minute, value: 48, to: now) ?? now.addingTimeInterval(2880)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Small Widget View

struct MuhurtaWidgetView: View {
    var entry: MuhurtaEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let m = entry.muhurta {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(qualityColor(m.quality))
                            .frame(width: 8, height: 8)
                        Text("NOW")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(qualityColor(m.quality))
                        Spacer()
                        Text(m.quality.emoji)
                            .font(.system(size: 14))
                    }
                    Text(m.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(m.purpose)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                    Spacer()
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(entry.timeRemaining)
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(m.quality.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(qualityColor(m.quality))
                    }
                }
                .padding(12)
            }
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.purple)
                    Text("Cosmic Rituals")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text("Open app to begin")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private func qualityColor(_ q: WidgetMuhurtaQuality) -> Color {
        switch q {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return .orange
        case .inauspicious: return .red
        }
    }
}

// MARK: - Medium Widget View

struct PanchangWidgetView: View {
    var entry: PanchangEntry

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(alignment: .top, spacing: 12) {
                // Left: panchang limbs
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pancha Anga")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.yellow.opacity(0.8))
                    limbRow("☀", entry.panchang.weekday)
                    limbRow("🌙", entry.panchang.tithiName)
                    limbRow("✦", entry.panchang.nakshatraName)
                    limbRow("◈", entry.panchang.yogaName)
                    limbRow("⊕", entry.panchang.karanaName)
                }
                Divider().background(.white.opacity(0.2))
                // Right: current muhurta
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current Muhurta")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.yellow.opacity(0.8))
                    if let m = entry.muhurta {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(qualityColor(m.quality))
                                .frame(width: 7, height: 7)
                            Text(m.quality.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(qualityColor(m.quality))
                        }
                        Text(m.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text(m.purpose)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(3)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(14)
        }
    }

    private func limbRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
    }

    private func qualityColor(_ q: WidgetMuhurtaQuality) -> Color {
        switch q {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return .orange
        case .inauspicious: return .red
        }
    }
}

// MARK: - Widget Bundle

struct CurrentMuhurtaWidget: Widget {
    let kind = "CurrentMuhurtaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MuhurtaProvider()) { entry in
            MuhurtaWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Current Muhurta")
        .description("Shows the current muhurta quality and time remaining.")
        .supportedFamilies([.systemSmall])
    }
}

struct PanchangWidget: Widget {
    let kind = "PanchangWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PanchangProvider()) { entry in
            PanchangWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Daily Panchang")
        .description("Today's five limbs and current muhurta at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct CosmicWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CurrentMuhurtaWidget()
        PanchangWidget()
    }
}
