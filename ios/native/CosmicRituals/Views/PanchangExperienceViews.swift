import SwiftUI

/// The information architecture used by the Panchang home screen.
/// This choice is intentionally independent from the app's color theme.
enum RitualExperienceMode: String, CaseIterable, Identifiable {
    case ritualNow = "ritualNow"
    case vedicLedger = "vedicLedger"
    case fiveLimbFocus = "fiveLimbFocus"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ritualNow: return "Daily Snapshot"
        case .vedicLedger: return "Vedic Ledger"
        case .fiveLimbFocus: return "Five-Limb Focus"
        }
    }

    var summary: String {
        switch self {
        case .ritualNow:
            return "A glanceable local-noon reference"
        case .vedicLedger:
            return "An editorial Vedic almanac"
        case .fiveLimbFocus:
            return "One limb at a time, with deeper focus"
        }
    }

    var symbol: String {
        switch self {
        case .ritualNow: return "sparkles"
        case .vedicLedger: return "text.book.closed.fill"
        case .fiveLimbFocus: return "scope"
        }
    }
}

/// Liquid Glass belongs on interactive controls, while information surfaces remain
/// calm, opaque and legible. Earlier iOS versions receive a material fallback.
struct RitualInteractiveGlass<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = 18, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            content()
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        } else {
            content()
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 0.75)
                }
        }
    }
}

/// A content surface without Liquid Glass. This keeps long-form Panchang data
/// readable while reserving the dynamic material for controls.
private struct RitualContentSurface<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content
    @Environment(\.cosmicTheme) private var theme

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(18)
            .background(
                theme.surface.opacity(theme.isLight ? 0.94 : 0.82),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        theme.isLight ? theme.primary.opacity(0.14) : Color.white.opacity(0.08),
                        lineWidth: 0.75
                    )
            }
    }
}

struct PanchangExperienceHome: View {
    let mode: RitualExperienceMode
    @Binding var selectedDate: Date
    let panchang: Panchang
    let tithiEndTime: Date?
    let showTithiDetail: () -> Void
    let showYogaDetail: () -> Void
    let showKaranaDetail: () -> Void

    @Environment(\.cosmicTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "clock.badge.info")
                    .foregroundStyle(theme.primary)
                Text(CalculationContext.dailySnapshotDisclosure)
                    .foregroundStyle(theme.semanticSecondaryText)
                Spacer(minLength: 0)
            }
            .font(.caption2.weight(.medium))
            .accessibilityElement(children: .combine)

            Group {
                switch mode {
                case .ritualNow:
                    RitualNowExperience(
                        selectedDate: $selectedDate,
                        panchang: panchang,
                        tithiEndTime: tithiEndTime,
                        showTithiDetail: showTithiDetail,
                        showYogaDetail: showYogaDetail,
                        showKaranaDetail: showKaranaDetail
                    )
                case .vedicLedger:
                    VedicLedgerExperience(
                        selectedDate: $selectedDate,
                        panchang: panchang,
                        tithiEndTime: tithiEndTime,
                        showTithiDetail: showTithiDetail,
                        showYogaDetail: showYogaDetail,
                        showKaranaDetail: showKaranaDetail
                    )
                case .fiveLimbFocus:
                    FiveLimbFocusExperience(
                        selectedDate: $selectedDate,
                        panchang: panchang,
                        tithiEndTime: tithiEndTime,
                        showTithiDetail: showTithiDetail,
                        showYogaDetail: showYogaDetail,
                        showKaranaDetail: showKaranaDetail
                    )
                }
            }
            .id(mode)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.985)))
            .animation(reduceMotion ? nil : .snappy(duration: 0.34), value: mode)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(mode.displayName) Panchang experience")
    }
}

// MARK: - Daily Snapshot

private struct RitualNowExperience: View {
    @Binding var selectedDate: Date
    let panchang: Panchang
    let tithiEndTime: Date?
    let showTithiDetail: () -> Void
    let showYogaDetail: () -> Void
    let showKaranaDetail: () -> Void

    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                Text(selectedDate.ritualDate(template: "d", in: timeZone))
                    .font(.system(size: 86, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(theme.onSurface)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 7) {
                    Text(selectedDate.ritualDate(template: "EEEE", in: timeZone))
                        .font(.title2.weight(.bold))
                    Text(selectedDate.ritualDate(template: "MMMM y", in: timeZone))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(panchang.tithiName) · \(panchang.nakshatraName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(selectedDate.ritualCompleteDate(in: timeZone)), \(panchang.tithiName), \(panchang.nakshatraName)"
            )

            PanchangWeekStrip(selectedDate: $selectedDate, selectionStyle: .filled)

            RitualContentSurface {
                VStack(alignment: .leading, spacing: 0) {
                    Text("PANCHA ANGA")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)

                    PanchangExperienceRow(
                        symbol: "sun.max.fill", tint: .yellow,
                        label: "Vara", supporting: "Weekday", value: panchang.weekdayName
                    )
                    PanchangExperienceRow(
                        symbol: "moon.fill", tint: .blue,
                        label: "Tithi", supporting: "Lunar day", value: panchang.tithiName,
                        detail: tithiEndLabel, action: showTithiDetail
                    )
                    PanchangExperienceRow(
                        symbol: "sparkles", tint: theme.tertiary,
                        label: "Nakshatra", supporting: "Lunar mansion", value: panchang.nakshatraName
                    )
                    PanchangExperienceRow(
                        symbol: "circle.grid.cross.fill", tint: .green,
                        label: "Yoga", supporting: "Union", value: panchang.yogaName,
                        action: showYogaDetail
                    )
                    PanchangExperienceRow(
                        symbol: "divide.circle.fill", tint: .orange,
                        label: "Karana", supporting: "Half-tithi", value: panchang.karanaName,
                        isLast: true, action: showKaranaDetail
                    )
                }
            }

            Button(action: showTithiDetail) {
                RitualInteractiveGlass(cornerRadius: 20) {
                    HStack(spacing: 14) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.title2)
                            .foregroundStyle(theme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next transition")
                                .font(.headline)
                            Text(transitionDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(17)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next tithi transition, \(transitionDetail)")
            .accessibilityHint("Opens tithi details")
        }
    }

    private var tithiEndLabel: String {
        guard let tithiEndTime else { return "time unavailable" }
        return "ends \(tithiEndTime.ritualShortTime(in: timeZone))"
    }

    private var transitionDetail: String {
        guard let tithiEndTime else { return "Transition time unavailable" }
        let nextIndex = (panchang.tithiIndex + 1) % Panchang.tithiNames.count
        return "\(Panchang.tithiNames[nextIndex]) begins at \(tithiEndTime.ritualShortTime(in: timeZone))"
    }
}

// MARK: - Vedic Ledger

private struct VedicLedgerExperience: View {
    @Binding var selectedDate: Date
    let panchang: Panchang
    let tithiEndTime: Date?
    let showTithiDetail: () -> Void
    let showYogaDetail: () -> Void
    let showKaranaDetail: () -> Void

    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: -4) {
                    Text(selectedDate.ritualDate(template: "d", in: timeZone))
                        .font(.system(size: 94, weight: .light, design: .serif))
                        .minimumScaleFactor(0.72)
                    Text(selectedDate.ritualDate(template: "EEEE", in: timeZone))
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                    Text(selectedDate.ritualDate(template: "MMMM y", in: timeZone))
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(theme.primary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(theme.primary.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(theme.primary.opacity(0.09))
                            .frame(width: 70, height: 70)
                        Image(systemName: "moonphase.waning.crescent")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(theme.primary)
                    }
                    Text(panchang.tithiName)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(theme.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Tithi, \(panchang.tithiName)")
            }
            .accessibilityElement(children: .contain)

            PanchangWeekStrip(selectedDate: $selectedDate, selectionStyle: .outlined)

            VStack(alignment: .leading, spacing: 0) {
                Text("FIVE LIMBS OF THE VEDIC DAY")
                    .font(.caption.weight(.semibold))
                    .tracking(2.1)
                    .foregroundStyle(theme.primary)
                    .padding(.bottom, 10)

                LedgerLimbRow(symbol: "sun.max", tint: theme.primary, label: "Vara", value: panchang.weekdayName)
                LedgerLimbRow(symbol: "moon", tint: theme.secondary, label: "Tithi", value: panchang.tithiName, action: showTithiDetail)
                LedgerLimbRow(symbol: "sparkles", tint: theme.tertiary, label: "Nakshatra", value: panchang.nakshatraName)
                LedgerLimbRow(symbol: "circle.grid.cross", tint: theme.secondary, label: "Yoga", value: panchang.yogaName, action: showYogaDetail)
                LedgerLimbRow(symbol: "divide.circle", tint: theme.primary, label: "Karana", value: panchang.karanaName, isLast: true, action: showKaranaDetail)
            }
            .padding(.horizontal, 4)

            Button(action: showTithiDetail) {
                RitualInteractiveGlass(cornerRadius: 26) {
                    HStack(spacing: 14) {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(theme.secondary)
                        Divider().frame(height: 30)
                        Text(tithiEndTime.map {
                            "\(panchang.tithiName) ends \($0.ritualShortTime(in: timeZone))"
                        } ?? "Open \(panchang.tithiName) details")
                            .font(.system(.headline, design: .serif))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens tithi details")
        }
    }
}

// MARK: - Five-Limb Focus

private enum FocusLimb: String, CaseIterable, Identifiable {
    case vara, tithi, nakshatra, yoga, karana

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .vara: return "sun.max.fill"
        case .tithi: return "moon.fill"
        case .nakshatra: return "sparkles"
        case .yoga: return "circle.grid.cross.fill"
        case .karana: return "divide.circle.fill"
        }
    }
}

private struct FiveLimbFocusExperience: View {
    @Binding var selectedDate: Date
    let panchang: Panchang
    let tithiEndTime: Date?
    let showTithiDetail: () -> Void
    let showYogaDetail: () -> Void
    let showKaranaDetail: () -> Void

    @State private var selectedLimb: FocusLimb = .tithi
    @State private var showsAllLimbs = false
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            PanchangWeekStrip(selectedDate: $selectedDate, selectionStyle: .orb)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(focusColor.opacity(0.13))
                        .frame(width: 116, height: 116)
                    Circle()
                        .stroke(focusColor.opacity(0.32), lineWidth: 1)
                        .frame(width: 116, height: 116)
                    Image(systemName: selectedLimb.symbol)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(focusColor)
                        .symbolEffect(.pulse, options: .repeating.speed(0.16), isActive: !reduceMotion)
                }
                .accessibilityHidden(true)

                Text(selectedLimb.displayName.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(5)
                    .foregroundStyle(.secondary)
                Text(value(for: selectedLimb))
                    .font(.system(size: 46, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.68)
                    .lineLimit(1)
                if let supporting = supportingText(for: selectedLimb) {
                    Text(supporting)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .id(selectedLimb)
            .transition(.opacity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: selectedLimb)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(selectedLimbAccessibilityLabel)

            HStack(spacing: 4) {
                ForEach(FocusLimb.allCases) { limb in
                    Button {
                        selectedLimb = limb
                        showsAllLimbs = false
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: limb.symbol)
                                .font(.title2)
                                .foregroundStyle(color(for: limb))
                            Text(limb.displayName)
                                .font(.caption2.weight(selectedLimb == limb ? .bold : .medium))
                                .foregroundStyle(selectedLimb == limb ? .primary : .secondary)
                            Circle()
                                .fill(selectedLimb == limb ? Color.primary : Color.clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Focus on \(limb.displayName)")
                    .accessibilityValue(selectedLimb == limb ? "Selected" : "Not selected")
                }
            }
            .padding(.vertical, 12)
            .background(
                theme.surface.opacity(0.62),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )

            if let detailAction {
                Button(action: detailAction) {
                    RitualInteractiveGlass(cornerRadius: 18) {
                        HStack {
                            Image(systemName: selectedLimb.symbol)
                                .foregroundStyle(focusColor)
                            Text("Explore \(selectedLimb.displayName)")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(17)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens detailed \(selectedLimb.displayName) guidance")
            }

            Button {
                if reduceMotion {
                    showsAllLimbs.toggle()
                } else {
                    withAnimation(.snappy(duration: 0.3)) { showsAllLimbs.toggle() }
                }
            } label: {
                RitualInteractiveGlass(cornerRadius: 18) {
                    HStack {
                        Text(showsAllLimbs ? "Hide all five limbs" : "View all five limbs")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showsAllLimbs ? 180 : 0))
                            .foregroundStyle(.secondary)
                    }
                    .padding(17)
                }
            }
            .buttonStyle(.plain)
            .accessibilityValue(showsAllLimbs ? "Expanded" : "Collapsed")

            if showsAllLimbs {
                RitualContentSurface(cornerRadius: 20) {
                    VStack(spacing: 0) {
                        PanchangExperienceRow(symbol: FocusLimb.vara.symbol, tint: color(for: .vara), label: "Vara", supporting: nil, value: panchang.weekdayName)
                        PanchangExperienceRow(symbol: FocusLimb.tithi.symbol, tint: color(for: .tithi), label: "Tithi", supporting: nil, value: panchang.tithiName, action: showTithiDetail)
                        PanchangExperienceRow(symbol: FocusLimb.nakshatra.symbol, tint: color(for: .nakshatra), label: "Nakshatra", supporting: nil, value: panchang.nakshatraName)
                        PanchangExperienceRow(symbol: FocusLimb.yoga.symbol, tint: color(for: .yoga), label: "Yoga", supporting: nil, value: panchang.yogaName, action: showYogaDetail)
                        PanchangExperienceRow(symbol: FocusLimb.karana.symbol, tint: color(for: .karana), label: "Karana", supporting: nil, value: panchang.karanaName, isLast: true, action: showKaranaDetail)
                    }
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var detailAction: (() -> Void)? {
        switch selectedLimb {
        case .tithi: return showTithiDetail
        case .yoga: return showYogaDetail
        case .karana: return showKaranaDetail
        case .vara, .nakshatra: return nil
        }
    }

    private var focusColor: Color { color(for: selectedLimb) }

    private var selectedLimbAccessibilityLabel: String {
        [selectedLimb.displayName, value(for: selectedLimb), supportingText(for: selectedLimb)]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func value(for limb: FocusLimb) -> String {
        switch limb {
        case .vara: return panchang.weekdayName
        case .tithi: return panchang.tithiName
        case .nakshatra: return panchang.nakshatraName
        case .yoga: return panchang.yogaName
        case .karana: return panchang.karanaName
        }
    }

    private func supportingText(for limb: FocusLimb) -> String? {
        guard limb == .tithi, let tithiEndTime else { return nil }
        return "ends \(tithiEndTime.ritualShortTime(in: timeZone))"
    }

    private func color(for limb: FocusLimb) -> Color {
        switch limb {
        case .vara: return .yellow
        case .tithi: return .blue
        case .nakshatra: return theme.tertiary
        case .yoga: return .green
        case .karana: return .orange
        }
    }
}

// MARK: - Bottom Destination Navigation

struct RitualDestinationDescriptor: Equatable, Sendable {
    let title: String
    let symbol: String

    static let all = [
        RitualDestinationDescriptor(title: "Panchang", symbol: "eye.fill"),
        RitualDestinationDescriptor(title: "Timing", symbol: "clock.fill"),
        RitualDestinationDescriptor(title: "Muhurtas", symbol: "clock.badge.checkmark.fill"),
        RitualDestinationDescriptor(title: "Calendar", symbol: "calendar")
    ]
}

struct RitualDestinationBar: View {
    @Binding var selection: Int
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let destinations = RitualDestinationDescriptor.all

    private var usesIconOnlyPresentation: Bool {
        RitualResponsiveLayout.usesIconOnlyDestinations(for: dynamicTypeSize)
    }

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(destinations.indices, id: \.self) { index in
                    if selection == index {
                        destinationButton(at: index)
                            .buttonStyle(.glassProminent)
                            .tint(theme.primary)
                    } else {
                        destinationButton(at: index)
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(7)
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Panchang destinations")
    }

    private func destinationButton(at index: Int) -> some View {
        let destination = destinations[index]
        return Button {
            if reduceMotion {
                selection = index
            } else {
                withAnimation(.snappy(duration: 0.28)) {
                    selection = index
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: destination.symbol)
                    .font(.system(
                        size: usesIconOnlyPresentation ? 21 : 17,
                        weight: selection == index ? .semibold : .regular
                    ))
                if !usesIconOnlyPresentation {
                    Text(destination.title)
                        .font(.caption2.weight(selection == index ? .bold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
                }
            }
            .foregroundStyle(selection == index ? theme.background : theme.onSurface.opacity(0.78))
            .frame(maxWidth: .infinity)
            .frame(minHeight: usesIconOnlyPresentation ? 52 : 48)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(destination.title)
        .accessibilityValue(selection == index ? "Selected" : "Not selected")
        .accessibilityHint("Shows the \(destination.title) destination")
        .accessibilityIdentifier("ritual.destination.\(destination.title.lowercased())")
        .accessibilityAddTraits(selection == index ? .isSelected : [])
    }
}

// MARK: - Shared Experience Components

private enum WeekSelectionStyle {
    case filled, outlined, orb
}

private struct PanchangWeekStrip: View {
    @Binding var selectedDate: Date
    let selectionStyle: WeekSelectionStyle
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.timeZone) private var timeZone

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    private var dates: [Date] {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(dates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                Button {
                    selectedDate = date
                } label: {
                    VStack(spacing: 8) {
                        Text(date.ritualDate(template: "EEEEE", in: timeZone))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(date.ritualDate(template: "d", in: timeZone))
                            .font(.title3.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? selectedForeground : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(selectionBackground(isSelected: isSelected))
                    .overlay(selectionBorder(isSelected: isSelected))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(date.ritualCompleteDate(in: timeZone))
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Week date selector")
    }

    private var selectedForeground: Color {
        selectionStyle == .filled ? theme.background : theme.onSurface
    }

    @ViewBuilder
    private func selectionBackground(isSelected: Bool) -> some View {
        if isSelected {
            switch selectionStyle {
            case .filled:
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.primary)
            case .outlined:
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.primary.opacity(0.08))
            case .orb:
                Circle().fill(Color.primary.opacity(0.12)).padding(5)
            }
        }
    }

    @ViewBuilder
    private func selectionBorder(isSelected: Bool) -> some View {
        if isSelected, selectionStyle == .outlined {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.primary, lineWidth: 1.5)
        }
    }
}

private struct PanchangExperienceRow: View {
    let symbol: String
    let tint: Color
    let label: String
    let supporting: String?
    let value: String
    var detail: String? = nil
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { rowContent }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens \(label) details")
            } else {
                rowContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var rowContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.subheadline.weight(.semibold))
                    if let supporting {
                        Text(supporting).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(value).font(.subheadline.weight(.semibold))
                    if let detail {
                        Text(detail).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)

            if !isLast {
                Divider().padding(.leading, 41)
            }
        }
    }

    private var accessibilityText: String {
        [label, supporting, value, detail].compactMap { $0 }.joined(separator: ", ")
    }
}

private struct LedgerLimbRow: View {
    let symbol: String
    let tint: Color
    let label: String
    let value: String
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens \(label) details")
            } else {
                content
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 30)
                Text(label)
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundStyle(tint)
                Spacer()
                Text(value)
                    .font(.title3.weight(.medium))
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            if !isLast { Divider() }
        }
    }
}

// MARK: - Settings Picker

struct RitualExperiencePicker: View {
    @Binding var selectionRaw: String
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            ForEach(RitualExperienceMode.allCases) { mode in
                let isSelected = selectionRaw == mode.rawValue
                Button {
                    selectionRaw = mode.rawValue
                } label: {
                    RitualInteractiveGlass(cornerRadius: 16) {
                        HStack(spacing: 14) {
                            Image(systemName: mode.symbol)
                                .font(.title3)
                                .foregroundStyle(isSelected ? theme.primary : theme.semanticSecondaryText)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(mode.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(isSelected ? theme.primary : theme.semanticPrimaryText)
                                Text(mode.summary)
                                    .font(.caption)
                                    .foregroundStyle(theme.semanticSecondaryText)
                            }
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? theme.primary : theme.semanticTertiaryText)
                        }
                        .padding(15)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Use \(mode.displayName) experience")
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
            }
        }
    }
}
