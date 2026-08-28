import SwiftUI

// MARK: - Monthly Vedic Calendar

struct MonthlyCalendarCalculationSignature: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    init(context: CalculationContext) {
        latitude = context.latitude
        longitude = context.longitude
        timeZoneIdentifier = context.timeZoneIdentifier
    }
}

struct MonthlyCalendarView: View {
    @Binding var selectedDate: Date
    let calculationContext: CalculationContext
    @Environment(\.cosmicTheme) private var theme

    @State private var displayMonth = Date()
    @State private var panchangCache: [Date: Panchang] = [:]

    private var calendar: Calendar {
        calculationContext.calendar
    }

    private var calculationSignature: MonthlyCalendarCalculationSignature {
        MonthlyCalendarCalculationSignature(context: calculationContext)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthHeader
                weekdayHeader
                monthGrid
                legendCard
            }
            .padding(.vertical)
        }
        .onAppear {
            displayMonth = selectedDate
            refreshCache()
        }
        .onChange(of: selectedDate) { _, newValue in
            guard !calendar.isDate(newValue, equalTo: displayMonth, toGranularity: .month) else { return }
            displayMonth = newValue
        }
        .onChange(of: displayMonth) { _, _ in refreshCache() }
        .onChange(of: calculationSignature) { _, _ in
            // A city/GPS change can keep the same visible month while changing
            // every civil-time Panchang value. Never leave that cache stale.
            displayMonth = selectedDate
            refreshCache()
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        CosmicGlassCard {
            HStack {
                Button {
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(theme.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")
                .accessibilityHint("Shows the previous month's sunrise snapshots")

                Spacer()

                VStack(spacing: 2) {
                    Text(displayMonth.ritualDate(template: "MMMM", in: calculationContext.timeZone))
                        .font(.title2.bold())
                    Text(displayMonth.ritualDate(template: "y", in: calculationContext.timeZone))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(theme.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next month")
                .accessibilityHint("Shows the next month's sunrise snapshots")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Mo","Tu","We","Th","Fr","Sa","Su"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
            ForEach(days.indices, id: \.self) { i in
                if let day = days[i] {
                    DayCell(date: day,
                            panchang: panchangCache[calendar.startOfDay(for: day)],
                            calendar: calendar,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(day)) {
                        selectedDate = day
                    }
                } else {
                    Color.clear.frame(height: 60)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Legend

    private var legendCard: some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                CosmicSectionHeader(title: "Sunrise Snapshot Legend", icon: "circle.grid.2x2.fill")
                HStack(spacing: 16) {
                    legendItem(.green,  "Favourable yoga")
                    legendItem(.red,    "Caution yoga")
                }
                HStack(spacing: 16) {
                    legendItem(.purple, "Purnima / Ekadashi")
                    legendItem(.gray,   "Amavasya")
                }
            }
        }
        .padding(.horizontal)
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        let firstWeekday = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in range {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: firstDay) {
                days.append(date)
            }
        }
        // Pad to complete rows
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func refreshCache() {
        var cache: [Date: Panchang] = [:]
        for day in daysInMonth().compactMap({ $0 }) {
            let key = calendar.startOfDay(for: day)
            let context = CalculationContext(
                localDay: day,
                latitude: calculationContext.latitude,
                longitude: calculationContext.longitude,
                timeZoneIdentifier: calculationContext.timeZoneIdentifier
            )
            // Month cells need the sunrise snapshot, not four sub-second boundary
            // solves per day. Detailed transitions are computed only on the daily view.
            cache[key] = CosmicEngine.getPanchang(context: context, includeTransitions: false)
        }
        panchangCache = cache
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let panchang: Panchang?
    let calendar: Calendar
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    @Environment(\.cosmicTheme) private var theme

    private var yogaDetail: YogaDetail {
        YogaDetail.from(yogaIndex: panchang?.yogaIndex ?? 0)
    }

    private var qualityColor: Color {
        let t = panchang?.tithiIndex ?? 0
        if t == 14 || t == 10 || t == 25 { return .purple }  // Purnima or Ekadashi
        if t == 29 { return .gray }                           // Amavasya
        return yogaDetail.isAuspicious ? .green : .red
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                // Day number
                ZStack {
                    if isSelected {
                        Circle().fill(theme.primary).frame(width: 26, height: 26)
                    } else if isToday {
                        Circle().stroke(theme.primary, lineWidth: 1.5).frame(width: 26, height: 26)
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 13, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundStyle(isSelected ? theme.selectedControlForeground : .primary)
                }

                // Tithi name (abbreviated)
                Text(shortTithi(panchang?.tithiIndex ?? 0))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Quality dot
                Circle()
                    .fill(qualityColor)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                isSelected ? theme.primary.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isToday
                            ? "Today, \(date.ritualCompleteDate(in: calendar.timeZone))"
                            : date.ritualCompleteDate(in: calendar.timeZone))
        .accessibilityValue("At sunrise, \(panchang?.tithiName ?? "Panchang unavailable"), \(yogaDetail.isAuspicious ? "favourable yoga" : "caution yoga")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Selects this date for every Panchang calculation")
    }

    private func shortTithi(_ idx: Int) -> String {
        let names = Panchang.tithiNames
        let name = names[idx.clamped(to: 0...29)]
        if name == "Purnima" { return "PM" }
        if name == "Amavasya" { return "AM" }
        return String(name.prefix(4))
    }
}
