import SwiftUI

// Prototype view intentionally not routed into shipping navigation. The
// low-precision source model must meet ACCURACY.md's evidence gate first.

struct GrahaPositionsCard: View {
    let grahas: [GrahaPosition]
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                CosmicSectionHeader(title: "Graha Positions (Sidereal)", icon: "globe.asia.australia.fill")

                ForEach(grahas) { g in
                    GrahaRow(graha: g)
                    if g.id != grahas.last?.id {
                        Divider().opacity(0.4)
                    }
                }

                Text("Sidereal positions using Lahiri ayanamsha.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
    }
}

private struct GrahaRow: View {
    let graha: GrahaPosition
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            // Planet symbol
            Text(graha.body.symbol)
                .font(.system(size: 20))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(vedic(graha.body))
                        .font(.subheadline.bold())
                    if graha.isRetrograde {
                        Text("℞")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                }
                Text(english(graha.body))
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 4) {
                    Text(graha.signSymbol)
                        .font(.system(size: 16))
                    Text(graha.signName)
                        .font(.subheadline.bold())
                        .foregroundStyle(signColor(graha.signIndex))
                }
                Text(String(format: "%.1f°", graha.degreeInSign))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func vedic(_ body: CelestialBody) -> String {
        switch body {
        case .sun:     return "Surya"
        case .moon:    return "Chandra"
        case .mars:    return "Kuja"
        case .mercury: return "Budha"
        case .jupiter: return "Guru"
        case .venus:   return "Shukra"
        case .saturn:  return "Shani"
        case .rahu:    return "Rahu"
        case .ketu:    return "Ketu"
        }
    }

    private func english(_ body: CelestialBody) -> String {
        switch body {
        case .sun:     return "Sun"
        case .moon:    return "Moon"
        case .mars:    return "Mars"
        case .mercury: return "Mercury"
        case .jupiter: return "Jupiter"
        case .venus:   return "Venus"
        case .saturn:  return "Saturn"
        case .rahu:    return "North Node"
        case .ketu:    return "South Node"
        }
    }

    private func signColor(_ idx: Int) -> Color {
        let element = ZodiacSign.fromIndex(idx).element
        switch element {
        case "Fire":  return .red
        case "Earth": return .green
        case "Air":   return .cyan
        case "Water": return .blue
        default:      return .primary
        }
    }
}
