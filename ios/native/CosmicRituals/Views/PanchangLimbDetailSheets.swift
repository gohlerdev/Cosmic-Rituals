import SwiftUI

// MARK: - Tithi Detail Sheet

struct TithiDetailSheet: View {
    let tithiIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        let detail = TithiDetail.from(tithiIndex: tithiIndex)
        NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        CosmicGlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(detail.paksha + " Paksha")
                                            .font(.caption).foregroundStyle(.secondary)
                                        Text(Panchang.tithiNames[tithiIndex])
                                            .font(.largeTitle.bold()).foregroundStyle(theme.primary)
                                        Text("Tithi \(tithiIndex + 1) of 30")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(detail.qualityClass)
                                            .font(.headline.bold())
                                            .padding(.horizontal, 12).padding(.vertical, 5)
                                            .background(qualityClassColor(detail.qualityClass).opacity(0.2),
                                                        in: Capsule())
                                            .foregroundStyle(qualityClassColor(detail.qualityClass))
                                        Text(detail.qualityMeaning)
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Divider()
                                HStack(spacing: 6) {
                                    CosmicIcon(name: "person.fill", size: 13, color: .secondary)
                                    Text("Presiding deity: \(detail.deity)")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Guidance
                        CosmicGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                CosmicSectionHeader(title: "Classical Guidance", icon: "book.fill")
                                Text(detail.guidance)
                                    .font(.body).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        // Favorable
                        CosmicGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                CosmicSectionHeader(title: "Favourable Activities", icon: "checkmark.circle.fill")
                                ForEach(detail.favorable, id: \.self) { act in
                                    HStack(spacing: 8) {
                                        Circle().fill(.green).frame(width: 5, height: 5)
                                        Text(act).font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Avoid
                        CosmicGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                CosmicSectionHeader(title: "Activities to Avoid", icon: "xmark.circle.fill")
                                ForEach(detail.avoid, id: \.self) { act in
                                    HStack(spacing: 8) {
                                        Circle().fill(.red).frame(width: 5, height: 5)
                                        Text(act).font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Tithi Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func qualityClassColor(_ q: String) -> Color {
        switch q {
        case "Nanda":  return .blue
        case "Bhadra": return .green
        case "Jaya":   return .yellow
        case "Rikta":  return .red
        case "Purna":  return Color.indigo
        default:       return .primary
        }
    }
}

// MARK: - Yoga Detail Sheet

struct YogaDetailSheet: View {
    let yogaIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        let detail = YogaDetail.from(yogaIndex: yogaIndex)
        NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        CosmicGlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Yoga \(yogaIndex + 1) of 27")
                                            .font(.caption).foregroundStyle(.secondary)
                                        Text(detail.name)
                                            .font(.largeTitle.bold()).foregroundStyle(theme.primary)
                                        Text(detail.meaning)
                                            .font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(detail.isAuspicious ? "Auspicious" : "Inauspicious")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12).padding(.vertical, 5)
                                        .background((detail.isAuspicious ? Color.green : Color.red).opacity(0.2), in: Capsule())
                                        .foregroundStyle(detail.isAuspicious ? .green : .red)
                                }
                                Divider()
                                HStack(spacing: 6) {
                                    CosmicIcon(name: "person.fill", size: 13, color: .secondary)
                                    Text("Presiding deity: \(detail.deity)").font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal)

                        CosmicGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                CosmicSectionHeader(title: "Classical Guidance", icon: "book.fill")
                                Text(detail.guidance).font(.body).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Yoga Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Karana Detail Sheet

struct KaranaDetailSheet: View {
    let karanaIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        let detail = KaranaDetail.from(karanaIndex: karanaIndex)
        NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        CosmicGlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(detail.isFixed ? "Fixed Karana" : "Movable Karana")
                                            .font(.caption).foregroundStyle(.secondary)
                                        Text(detail.name)
                                            .font(.largeTitle.bold()).foregroundStyle(theme.primary)
                                    }
                                    Spacer()
                                    Text(detail.isFixed ? "Fixed" : "Movable")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12).padding(.vertical, 5)
                                        .background(Color.primary.opacity(0.1), in: Capsule())
                                }
                                Divider()
                                HStack(spacing: 6) {
                                    CosmicIcon(name: "person.fill", size: 13, color: .secondary)
                                    Text("Presiding deity: \(detail.deity)").font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal)

                        CosmicGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                CosmicSectionHeader(title: "Classical Guidance", icon: "book.fill")
                                Text(detail.guidance).font(.body).foregroundStyle(.secondary)
                                Text("Each karana is half a tithi (≈ 6° of Moon-Sun separation). The seven movable karanas cycle continuously through the lunar month, while the four fixed karanas occur once each at specific positions.")
                                    .font(.caption).foregroundStyle(.tertiary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Karana Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
