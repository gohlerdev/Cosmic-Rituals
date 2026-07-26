import SwiftUI

struct ChoghadiyaHoraView: View {
    let choghadiya: [Choghadiya]
    let hora: [Hora]
    @State private var segment = 0   // 0 = Choghadiya, 1 = Hora
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CosmicSegmentedTabs(
                    tabs: [("Choghadiya", "clock.fill"), ("Hora", "star.circle.fill")],
                    selection: $segment
                )
                .padding(.horizontal)

                if segment == 0 {
                    choghadiyaSection
                } else {
                    horaSection
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Choghadiya

    private var choghadiyaSection: some View {
        VStack(spacing: 14) {
            if let current = choghadiya.first(where: { $0.isCurrent }) {
                currentChoghadiyaBanner(current)
                    .padding(.horizontal)
            }

            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    CosmicSectionHeader(title: "Day Choghadiya", icon: "sun.max.fill")
                    ForEach(choghadiya.filter { $0.isDay }) { c in
                        ChoghadiyaRow(item: c)
                    }
                }
            }
            .padding(.horizontal)

            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    CosmicSectionHeader(title: "Night Choghadiya", icon: "moon.stars.fill")
                    ForEach(choghadiya.filter { !$0.isDay }) { c in
                        ChoghadiyaRow(item: c)
                    }
                }
            }
            .padding(.horizontal)

            Text("Choghadiya periods are computed from local sunrise and sunset.")
                .font(.caption2).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 8)
        }
    }

    private func currentChoghadiyaBanner(_ c: Choghadiya) -> some View {
        CosmicGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                        .overlay(Circle().fill(.green.opacity(0.4)).scaleEffect(1.8))
                    Text("NOW")
                        .font(.caption.bold()).foregroundStyle(.green)
                    Spacer()
                    Text(c.isDay ? "☀ Day" : "🌙 Night")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(c.quality.rawValue)
                        .font(.title.bold())
                        .foregroundStyle(choghadiyaColor(c.quality))
                    Text(c.quality.planet.rawValue)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Text(c.quality.detail)
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    CosmicIcon(.clock, size: 13, color: .secondary)
                    Text(c.startTime.ritualShortTime(in: timeZone))
                    Text("→")
                    Text(c.endTime.ritualShortTime(in: timeZone))
                    Spacer()
                    qualityBadge(c.quality)
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Hora

    private var horaSection: some View {
        VStack(spacing: 14) {
            if let current = hora.first(where: { $0.isCurrent }) {
                currentHoraBanner(current)
                    .padding(.horizontal)
            }

            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    CosmicSectionHeader(title: "Day Hora", icon: "sun.max.fill")
                    ForEach(hora.filter { $0.isDay }) { h in
                        HoraRow(item: h)
                    }
                }
            }
            .padding(.horizontal)

            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    CosmicSectionHeader(title: "Night Hora", icon: "moon.stars.fill")
                    ForEach(hora.filter { !$0.isDay }) { h in
                        HoraRow(item: h)
                    }
                }
            }
            .padding(.horizontal)

            Text("Planetary hours follow the Chaldean sequence from the day lord at sunrise.")
                .font(.caption2).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 8)
        }
    }

    private func currentHoraBanner(_ h: Hora) -> some View {
        CosmicGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                        .overlay(Circle().fill(.green.opacity(0.4)).scaleEffect(1.8))
                    Text("NOW · Hora \(h.id)")
                        .font(.caption.bold()).foregroundStyle(.green)
                    Spacer()
                    Text(h.isDay ? "☀ Day" : "🌙 Night")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(h.planet.symbol).font(.title2)
                    Text(h.planet.rawValue + " Hora")
                        .font(.title2.bold()).foregroundStyle(theme.primary)
                }
                HStack {
                    CosmicIcon(.clock, size: 13, color: .secondary)
                    Text(h.startTime.ritualShortTime(in: timeZone))
                    Text("→")
                    Text(h.endTime.ritualShortTime(in: timeZone))
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    func choghadiyaColor(_ q: ChoghadiyaQuality) -> Color {
        switch q.muhurtaQuality {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return Color.indigo
        case .inauspicious: return .red
        }
    }

    @ViewBuilder
    func qualityBadge(_ q: ChoghadiyaQuality) -> some View {
        let label: String = {
            switch q.muhurtaQuality {
            case .excellent:    return "Excellent"
            case .auspicious:   return "Auspicious"
            case .mixed:        return "Neutral"
            case .inauspicious: return "Avoid"
            }
        }()
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(choghadiyaColor(q))
            .clipShape(Capsule())
    }
}

// MARK: - Choghadiya Row

struct ChoghadiyaRow: View {
    let item: Choghadiya
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    private func color(_ q: ChoghadiyaQuality) -> Color {
        switch q.muhurtaQuality {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return Color.indigo
        case .inauspicious: return .red
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color(item.quality).opacity(item.isCurrent ? 1.0 : 0.4))
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.quality.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(item.isCurrent ? color(item.quality) : .primary)
                    if item.isCurrent {
                        Text("NOW")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(.green).clipShape(Capsule())
                    }
                }
                Text(item.quality.planet.rawValue)
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.startTime.ritualShortTime(in: timeZone))
                    .font(.system(size: 11).monospacedDigit())
                Text(item.endTime.ritualShortTime(in: timeZone))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .background(item.isCurrent ? color(item.quality).opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Hora Row

struct HoraRow: View {
    let item: Hora
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(item.isCurrent ? theme.primary.opacity(0.2) : Color.primary.opacity(0.06))
                    .frame(width: 32, height: 32)
                Text(item.planet.symbol)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.planet.rawValue + " Hora")
                        .font(.subheadline.bold())
                        .foregroundStyle(item.isCurrent ? theme.primary : .primary)
                    if item.isCurrent {
                        Text("NOW")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(.green).clipShape(Capsule())
                    }
                }
                Text("Hora \(item.id)")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.startTime.ritualShortTime(in: timeZone))
                    .font(.system(size: 11).monospacedDigit())
                Text(item.endTime.ritualShortTime(in: timeZone))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .background(item.isCurrent ? theme.primary.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
