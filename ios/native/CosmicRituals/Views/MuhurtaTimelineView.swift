import SwiftUI

// MARK: - Muhurta Timeline

struct MuhurtaTimelineView: View {
    let muhurtas: [Muhurta]
    var onTap: ((Muhurta) -> Void)? = nil
    @Environment(\.timeZone) private var timeZone
    @Environment(\.cosmicTheme) private var theme

    private var span: (start: Date, end: Date)? {
        guard let f = muhurtas.first, let l = muhurtas.last else { return nil }
        return (f.startTime, l.endTime)
    }

    var body: some View {
        guard let span else { return AnyView(EmptyView()) }
        return AnyView(
            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    CosmicSectionHeader(title: "Muhurta Timeline", icon: "chart.bar.fill")

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Segment bars
                            ForEach(muhurtas) { m in
                                let x0 = xFrac(m.startTime, span: span) * geo.size.width
                                let x1 = xFrac(m.endTime,   span: span) * geo.size.width
                                Button { onTap?(m) } label: {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(qualityColor(m.quality).opacity(m.isCurrent ? 1.0 : 0.55))
                                        .frame(width: max(2, x1 - x0 - 1), height: 44)
                                }
                                .buttonStyle(.plain)
                                .offset(x: x0)
                                .accessibilityLabel("\(m.name), \(m.quality.rawValue)")
                                .accessibilityValue(
                                    "\(m.startTime.ritualShortTime(in: timeZone)) to \(m.endTime.ritualShortTime(in: timeZone))"
                                )
                                .accessibilityHint("Opens muhurta details")
                            }

                            // Sunrise / sunset divider (day→night boundary)
                            if let night = muhurtas.first(where: { !$0.isDay }) {
                                let x = xFrac(night.startTime, span: span) * geo.size.width
                                Rectangle()
                                    .fill(timelineMarker.opacity(0.3))
                                    .frame(width: 1, height: 44)
                                    .offset(x: x)
                            }

                            // "Now" cursor
                            let now = Date()
                            if now >= span.start && now < span.end {
                                let nowX = xFrac(now, span: span) * geo.size.width
                                VStack(spacing: 0) {
                                    Circle().fill(timelineMarker).frame(width: 6, height: 6)
                                    Rectangle().fill(timelineMarker).frame(width: 2, height: 38)
                                }
                                .offset(x: nowX - 1)
                            }
                        }
                        // Give the ZStack the full proposed width. Without this explicit
                        // frame, its layout width collapses to one short segment and the
                        // clip shape hides every later muhurta in the 24-hour sequence.
                        .frame(width: geo.size.width, height: 44, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .frame(height: 44)

                    // Time labels
                    if let first = muhurtas.first, let last = muhurtas.last {
                        HStack {
                            Text(first.startTime.ritualShortTime(in: timeZone))
                            Spacer()
                            Text("Sunset")
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text(last.endTime.ritualShortTime(in: timeZone))
                        }
                        .font(.system(size: 9)).foregroundStyle(.secondary).monospacedDigit()
                    }

                    // Legend
                    HStack(spacing: 12) {
                        legendDot(.yellow,  "Excellent")
                        legendDot(.green,   "Auspicious")
                        legendDot(.orange,  "Mixed")
                        legendDot(.red,     "Avoid")
                    }
                }
            }
        )
    }

    private func xFrac(_ date: Date, span: (start: Date, end: Date)) -> CGFloat {
        let total = span.end.timeIntervalSince(span.start)
        guard total > 0 else { return 0 }
        return CGFloat(date.timeIntervalSince(span.start) / total)
    }

    private func qualityColor(_ q: MuhurtaQuality) -> Color {
        switch q {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return .orange
        case .inauspicious: return .red
        }
    }

    private var timelineMarker: Color {
        theme.isLight ? theme.onSurface : .white
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }
}
