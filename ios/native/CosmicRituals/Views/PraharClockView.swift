import SwiftUI

/// The traditional Hindu clock: the eight prahars of the Vedic day, a live
/// Ishta Kaal in ghati-pala-vipala, and the day's dinamana / ratrimana.
///
/// All astronomy is done by TraditionalClock; this view only formats and
/// counts. The one rule it enforces on its own is honesty about liveness:
/// a running ghati counter means nothing while the user is browsing another
/// date, so it appears only when the day on screen is the day now running.
struct PraharClockView: View {
    let prahars: [Prahar]
    let measure: DayNightMeasure?

    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    /// The Vedic day on screen: its opening sunrise and the sunrise that ends it.
    private var vedicDay: (sunrise: Date, nextSunrise: Date)? {
        guard let first = prahars.first, let last = prahars.last else { return nil }
        return (first.start, last.end)
    }

    private func isRunning(at now: Date) -> Bool {
        guard let day = vedicDay else { return false }
        return now >= day.sunrise && now < day.nextSunrise
    }

    var body: some View {
        VStack(spacing: 14) {
            if prahars.isEmpty {
                unavailableNote
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ishtaKaalCard(now: context.date)
                        .padding(.horizontal)
                }
                praharCard(title: "Day Prahars", icon: "sun.max.fill", isDay: true)
                praharCard(title: "Night Prahars", icon: "moon.stars.fill", isDay: false)
                measureCard
                conventionFooter
            }
        }
    }

    // MARK: - Ishta Kaal

    @ViewBuilder
    private func ishtaKaalCard(now: Date) -> some View {
        let live = isRunning(at: now)
        CosmicGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    if live {
                        Circle().fill(.green).frame(width: 8, height: 8)
                            .overlay(Circle().fill(.green.opacity(0.4)).scaleEffect(1.8))
                        Text("ISHTA KAAL").font(.caption.bold()).foregroundStyle(.green)
                    } else {
                        CosmicIcon(.clock, size: 13, color: .secondary)
                        Text("ISHTA KAAL").font(.caption.bold()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let day = vedicDay {
                        Text("from sunrise \(day.sunrise.ritualShortTime(in: timeZone))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                if live, let day = vedicDay {
                    let elapsed = GhatiPala(interval: now.timeIntervalSince(day.sunrise))
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        unit(elapsed.ghati, "ghati")
                        unit(elapsed.pala, "pala")
                        unit(elapsed.vipala, "vipala")
                        Spacer()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "Ishta Kaal \(elapsed.ghati) ghati \(elapsed.pala) pala \(elapsed.vipala) vipala")

                    if let current = prahars.first(where: { $0.contains(now) }) {
                        Text("\(current.name) · prahar \(current.number) of 8")
                            .font(.subheadline).foregroundStyle(theme.semanticPrimaryText)
                    }
                } else {
                    // Not the running day: show the anchor, never a fake count.
                    Text("Shown for the selected day. The live count runs only while that day is the one in progress.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func unit(_ value: Int, _ name: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)")
                .font(.system(.title, design: .monospaced).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(theme.semanticPrimaryText)
            Text(name).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Prahar tables

    private func praharCard(title: String, icon: String, isDay: Bool) -> some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                CosmicSectionHeader(title: title, icon: icon)
                ForEach(prahars.filter { $0.isDay == isDay }) { prahar in
                    PraharRow(prahar: prahar, timeZone: timeZone)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Dinamana / Ratrimana

    @ViewBuilder
    private var measureCard: some View {
        if let measure {
            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    CosmicSectionHeader(title: "Day and Night Length", icon: "circle.lefthalf.filled")
                    CosmicStatRow(label: "Dinamana (daylight)", value: measure.dinamana.shortText)
                    CosmicStatRow(label: "Ratrimana (night)", value: measure.ratrimana.shortText)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Disclosure

    private var conventionFooter: some View {
        VStack(spacing: 6) {
            Text("Four prahars divide the actual daylight and four the actual night, so a prahar is three hours only near the equator.")
            Text("Ghati, pala and vipala are fixed units — 1 ghati is 24 minutes and 60 ghatis make a day and night — which is why dinamana moves through the year. A competing reckoning divides daylight into 30 ghatis instead, fixing dinamana at 30 on every date.")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private var unavailableNote: some View {
        Text("Prahars, Ishta Kaal, and dinamana are measured from sunrise. This location and date have no sunrise, so none are shown.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
    }
}

private struct PraharRow: View {
    let prahar: Prahar
    let timeZone: TimeZone

    @Environment(\.cosmicTheme) private var theme

    private var isCurrent: Bool { prahar.contains(Date()) }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(prahar.number)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            Text(prahar.name)
                .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                .foregroundStyle(isCurrent ? theme.primary : theme.semanticPrimaryText)
            Spacer()
            Text(prahar.start.ritualShortTime(in: timeZone))
            Text("→")
            Text(prahar.end.ritualShortTime(in: timeZone))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Prahar \(prahar.number), \(prahar.name), \(prahar.start.ritualShortTime(in: timeZone)) to \(prahar.end.ritualShortTime(in: timeZone))")
    }
}
