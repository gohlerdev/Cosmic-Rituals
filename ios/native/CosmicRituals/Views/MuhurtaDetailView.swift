import SwiftUI

/// Full classical detail for a single muhurta — presiding deity, resonance, timing,
/// description, and the traditional favourable / to-avoid activities. Presented as a
/// sheet when a muhurta row (or the "now" banner) is tapped.
struct MuhurtaDetailView: View {
    let muhurta: Muhurta
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone

    private var qualityColor: Color {
        switch muhurta.quality {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return .orange
        case .inauspicious: return .red
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicStarfieldBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        if let info = muhurta.info {
                            deityCard(info)
                            descriptionCard(info)
                            activitiesCard(info)
                        } else {
                            fallbackCard
                        }
                        Text("Traditional muhurta guidance — symbolic context, not prediction. For ritually precise timing consult a qualified Jyotishi.")
                            .font(.caption2).foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24).padding(.bottom, 24)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Muhurta \(muhurta.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Cards

    private var header: some View {
        CosmicGlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(muhurta.isDay ? "☀️ Day muhurta" : "🌙 Night muhurta")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(muhurta.quality.emoji + " " + muhurta.quality.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(qualityColor)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(qualityColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(muhurta.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.primary)
                Text(muhurta.purpose)
                    .font(.subheadline).foregroundStyle(.secondary)

                Divider().padding(.vertical, 2)

                HStack(spacing: 8) {
                    CosmicIcon(.clock, size: 15, color: .secondary)
                    Text(muhurta.startTime.ritualShortTime(in: timeZone))
                    Text("→")
                    Text(muhurta.endTime.ritualShortTime(in: timeZone))
                    Spacer()
                    Text("~\(Int(muhurta.durationMinutes.rounded())) min")
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

                if muhurta.isCurrent {
                    HStack(spacing: 6) {
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Text("Active now").font(.caption.bold()).foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func deityCard(_ info: MuhurtaInfo) -> some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                CosmicSectionHeader(title: "Presiding Deity", icon: "sparkles")
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Devata").font(.caption2).foregroundStyle(.tertiary)
                        Text(info.deity).font(.subheadline.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Resonance").font(.caption2).foregroundStyle(.tertiary)
                        Text(info.resonance).font(.subheadline.bold())
                            .foregroundStyle(theme.primary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func descriptionCard(_ info: MuhurtaInfo) -> some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                CosmicSectionHeader(title: "The Hour", icon: "scroll.fill")
                Text(info.detail)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
    }

    private func activitiesCard(_ info: MuhurtaInfo) -> some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                CosmicSectionHeader(title: "Activities", icon: "checkmark.circle.fill")
                activityBlock(title: "Favourable", color: .green, symbol: "checkmark", items: info.favorable)
                Divider()
                activityBlock(title: "Best avoided", color: .red, symbol: "xmark", items: info.avoid)
            }
        }
        .padding(.horizontal)
    }

    private func activityBlock(title: String, color: Color, symbol: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: symbol)
                        .font(.caption2.bold())
                        .foregroundStyle(color)
                        .frame(width: 16)
                        .padding(.top, 2)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var fallbackCard: some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                CosmicSectionHeader(title: "The Hour", icon: "scroll.fill")
                Text(muhurta.purpose).font(.callout).foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }
}
