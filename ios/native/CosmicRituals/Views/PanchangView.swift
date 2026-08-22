import SwiftUI

struct PanchangView: View {
    @State private var selectedDate = Date()
    @State private var panchangSnapshot: (context: CalculationContext, value: Panchang)?
    @State private var muhurtas: [Muhurta] = []
    @State private var detailMuhurta: Muhurta?
    @State private var sunriseSunset: (Date, Date)?
    @State private var choghadiya: [Choghadiya] = []
    @State private var hora: [Hora] = []
    @State private var showThemePicker = false
    @State private var showLocationPicker = false
    @State private var selectedActivity: String = "Business"
    @State private var showTithiDetail = false
    @State private var showYogaDetail = false
    @State private var showKaranaDetail = false
    @State private var panchangPDF: PanchangPDF? = nil
    @State private var now = Date()   // ticked every minute to drive live "NOW" indicators
    @StateObject private var locationManager = LocationManager()
    @AppStorage("ritualSelectedDestination") private var selectedTab = 0
    @AppStorage("cosmicThemeVariant") private var variantRaw = CosmicThemeVariant.cosmicDark.rawValue
    @AppStorage("ritualExperienceMode") private var experienceRaw = RitualExperienceMode.ritualNow.rawValue
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                VStack(spacing: 0) {
                    if selectedTab != 3 {
                        LocationContextBar(manager: locationManager) {
                            showLocationPicker = true
                        }
                    }
                    if selectedTab == 0 {
                        panchangScrollView
                    } else if selectedTab == 1 {
                        if choghadiya.isEmpty && hora.isEmpty {
                            SolarScheduleUnavailableView()
                        } else {
                            ChoghadiyaHoraView(choghadiya: choghadiya, hora: hora)
                        }
                    } else if selectedTab == 2 {
                        muhurtaScrollView
                    } else if selectedTab == 3 {
                        PoojaVidhiLibraryView(
                            dayContext: poojaDayContext,
                            changeLocation: { showLocationPicker = true }
                        )
                    } else {
                        MonthlyCalendarView(selectedDate: $selectedDate, calculationContext: calculationContext)
                    }
                }
            }
            .navigationTitle(RitualDestinationDescriptor.all[selectedTab.clamped(to: 0...(RitualDestinationDescriptor.all.count - 1))].title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        if selectedTab != 3 {
                            ShareLink(item: panchangSummary,
                                      subject: Text("Panchang for \(selectedDate.ritualDate(template: "yMd", in: calculationContext.timeZone))")) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Share Panchang summary")
                            .accessibilityHint("Opens the system share sheet")
                            Group {
                                if let pdf = panchangPDF {
                                    ShareLink(item: pdf, preview: SharePreview("Panchang PDF",
                                              image: Image(systemName: "doc.richtext.fill"))) {
                                        Image(systemName: "doc.richtext.fill")
                                            .foregroundStyle(theme.primary)
                                    }
                                    .accessibilityLabel("Share Panchang PDF")
                                    .accessibilityHint("Opens the system share sheet with the generated PDF")
                                } else {
                                    ProgressView()
                                        .controlSize(.small)
                                        .accessibilityLabel("Preparing Panchang PDF")
                                }
                            }
                        }
                        Button { showThemePicker = true } label: {
                            CosmicIcon(.settings, size: 20)
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Choose the Panchang experience, color theme, and birth nakshatra")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if selectedTab != 3 {
                        Button { showLocationPicker = true } label: {
                            Image(systemName: locationManager.activeLocation.source == .current
                                  ? "location.fill" : "mappin.and.ellipse")
                                .foregroundStyle(locationManager.activeLocation.source == .current ? theme.primary : .secondary)
                        }
                        .accessibilityLabel("Calculation location")
                        .accessibilityValue(locationManager.activeLocation.name)
                        .accessibilityHint("Choose current location or an offline city")
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, theme.background.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 12)
                        .allowsHitTesting(false)
                    RitualDestinationBar(selection: $selectedTab)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerSheet(variantRaw: $variantRaw, experienceRaw: $experienceRaw)
            }
            .sheet(isPresented: $showLocationPicker) {
                RitualLocationPicker(manager: locationManager)
            }
            .sheet(isPresented: $showTithiDetail) {
                let p = resolvedPanchang
                TithiDetailSheet(tithiIndex: p.tithiIndex)
            }
            .sheet(isPresented: $showYogaDetail) {
                let p = resolvedPanchang
                YogaDetailSheet(yogaIndex: p.yogaIndex)
            }
            .sheet(isPresented: $showKaranaDetail) {
                let p = resolvedPanchang
                KaranaDetailSheet(karanaIndex: p.karanaIndex)
            }
        }
        .onAppear {
            if !RitualDestinationDescriptor.all.indices.contains(selectedTab) {
                selectedTab = 0
            }
            recompute()
            Task {
                await NotificationManager.shared.clearPendingRitualNotifications()
            }
        }
        .onChange(of: selectedDate) { _, _ in recompute() }
        .onChange(of: locationManager.activeLocation) { oldLocation, newLocation in
            let sourceTimeZone = TimeZone(identifier: oldLocation.timeZoneIdentifier) ?? .gmt
            let targetTimeZone = TimeZone(identifier: newLocation.timeZoneIdentifier) ?? .gmt
            let translatedDate = selectedDate.ritualCivilDay(
                preservingDateFrom: sourceTimeZone,
                into: targetTimeZone
            )
            if translatedDate == selectedDate {
                recompute()
            } else {
                selectedDate = translatedDate
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { date in
            now = date   // tick forces a re-render so isCurrent badges stay accurate
        }
        .task(id: calculationContext) {
            let context = calculationContext
            panchangPDF = nil
            let data = await Task.detached(priority: .utility) {
                PanchangPDFExporter.generatePDF(context: context)
            }.value
            guard !Task.isCancelled, calculationContext == context else { return }
            panchangPDF = PanchangPDF(data: data)
        }
        .environment(\.timeZone, calculationContext.timeZone)
    }

    // MARK: - Experience

    private var activeExperience: RitualExperienceMode {
        RitualExperienceMode(rawValue: experienceRaw) ?? .ritualNow
    }

    private var calculationContext: CalculationContext {
        locationManager.calculationContext(for: selectedDate)
    }

    private var resolvedPanchang: Panchang {
        let context = calculationContext
        if let snapshot = panchangSnapshot, snapshot.context == context {
            return snapshot.value
        }
        return CosmicEngine.getPanchang(context: context)
    }

    private var poojaDayContext: RitualDayContext {
        let panchang = resolvedPanchang
        let timeZone = calculationContext.timeZone
        return RitualDayContext(
            civilDate: selectedDate.ritualCompleteDate(in: timeZone),
            locationName: locationManager.activeLocation.name,
            timeZoneIdentifier: timeZone.identifier,
            tithiName: panchang.tithiName,
            nakshatraName: panchang.nakshatraName,
            sunriseTime: panchang.sunriseTime?.ritualShortTime(in: timeZone)
        )
    }

    // MARK: - Panchang five limbs

    private var panchangScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                let p = resolvedPanchang

                PanchangExperienceHome(
                    mode: activeExperience,
                    selectedDate: $selectedDate,
                    panchang: p,
                    showTithiDetail: { showTithiDetail = true },
                    showYogaDetail: { showYogaDetail = true },
                    showKaranaDetail: { showKaranaDetail = true }
                )
                .padding(.horizontal)
                .padding(.top, 12)

                PanchangTransitionTimeline(
                    referenceDate: p.date,
                    transitions: p.transitions.chronological
                )
                .padding(.horizontal)

                // Solar values are shown only when real rise/set events exist.
                CosmicGlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        CosmicSectionHeader(title: "Solar Times", icon: "sun.horizon.fill")
                        if let rise = sunriseSunset?.0, let set = sunriseSunset?.1 {
                            HStack(spacing: 0) {
                                solarTimeCell(icon: "sunrise.fill", color: .orange, label: "Sunrise", time: rise)
                                Divider().frame(height: 40)
                                solarTimeCell(icon: "sunset.fill", color: .red, label: "Sunset", time: set)
                            }
                            Divider()
                            if let brahma = CosmicEngine.getBrahmaMuhurta(context: calculationContext) {
                                HStack(spacing: 6) {
                                    CosmicIcon(name: "moon.zzz.fill", size: 13, color: .purple)
                                    Text("Brahma Muhurta")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(shortTime(brahma.start)) – \(shortTime(brahma.end))")
                                        .font(.caption.bold()).foregroundStyle(.purple)
                                }
                            }
                            if let abhijit = CosmicEngine.getAbhijitMuhurta(context: calculationContext) {
                                HStack(spacing: 6) {
                                    CosmicIcon(name: "sun.max.circle.fill", size: 13, color: .yellow)
                                    Text("Abhijit Muhurta")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(shortTime(abhijit.start)) – \(shortTime(abhijit.end))")
                                        .font(.caption.bold()).foregroundStyle(.yellow)
                                }
                            } else if p.weekdayName == "Wednesday" {
                                Label("Abhijit is not observed as auspicious on Wednesday.",
                                      systemImage: "sun.max.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Label("Sunrise-based schedules are unavailable for this latitude and date.",
                                  systemImage: "sun.horizon.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                CosmicGlassCard(cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        CosmicSectionHeader(title: "Nakshatra Detail", icon: "star.fill")
                        let nak = CosmicEngine.getMoonNakshatraPada(context: calculationContext)

                        HStack(alignment: .top, spacing: 16) {
                            Text(nak.symbol).font(.system(size: 52))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(nak.nakshatraName).font(.title2.bold())
                                HStack(spacing: 6) {
                                    CosmicIcon(.person, size: 13, color: .secondary)
                                    Text(nak.nakshatraLord.rawValue + " dasha lord")
                                }
                                .font(.caption).foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    CosmicIcon(.vedic, size: 13, color: .secondary)
                                    Text("Gana: " + nak.gana)
                                }
                                .font(.caption).foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    CosmicIcon(.varga, size: 13, color: .secondary)
                                    Text("Pada \(nak.pada) of 4")
                                }
                                .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        Divider()
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Moon Sign").font(.caption2).foregroundStyle(.tertiary)
                                Text(ZodiacSign.fromIndex(p.moonSignIndex).name + " " +
                                     ZodiacSign.fromIndex(p.moonSignIndex).symbol)
                                    .font(.subheadline.bold())
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Tithi Phase").font(.caption2).foregroundStyle(.tertiary)
                                Text(p.tithiIndex < 15 ? "Shukla Paksha (Waxing)" : "Krishna Paksha (Waning)")
                                    .font(.caption.bold())
                                    .foregroundStyle(p.tithiIndex < 15 ? theme.primary : .secondary)
                            }
                        }

                    }
                }
                .padding(.horizontal)

                panchangYogaCard(for: p)

                inauspiciousKalaCard

            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func panchangYogaCard(for panchang: Panchang) -> some View {
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        if !matches.isEmpty {
            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    CosmicSectionHeader(title: "Auspicious Combinations", icon: "sparkles")
                    ForEach(matches) { match in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(match.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.primary)
                            Text(match.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if match.id != matches.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Upcoming Festivals

    private var upcomingFestivalsCard: some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                CosmicSectionHeader(title: "Upcoming Festivals", icon: "sparkle")
                let occurrences = FestivalEngine.upcomingFestivals(from: selectedDate, count: 6)
                if occurrences.isEmpty {
                    Text("No festivals found in the next 365 days.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(occurrences) { occ in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 2) {
                                Text(occ.date.ritualDate(template: "d", in: calculationContext.timeZone))
                                    .font(.title3.bold())
                                Text(occ.date.ritualDate(template: "MMM", in: calculationContext.timeZone))
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            .frame(width: 36)
                            .padding(.vertical, 4)
                            .background(categoryColor(occ.festival.category).opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(occ.festival.name)
                                    .font(.subheadline.bold())
                                    .lineLimit(2)
                                Text(occ.festival.category.rawValue)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(categoryColor(occ.festival.category))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(categoryColor(occ.festival.category).opacity(0.15), in: Capsule())
                            }
                            Spacer()
                        }
                        if occ.id != occurrences.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func categoryColor(_ cat: FestivalCategory) -> Color {
        switch cat {
        case .major:     return theme.primary
        case .vrat:      return .orange
        case .regional:  return .purple
        case .solar:     return .yellow
        case .ancestral: return .gray
        }
    }

    // MARK: - 30 Muhurtas

    private var muhurtaScrollView: some View {
        ScrollView {
            VStack(spacing: 14) {
                CosmicGlassCard {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .tint(theme.primary)
                }
                .padding(.horizontal)

                if muhurtas.isEmpty {
                    SolarScheduleUnavailableView()
                        .padding(.horizontal)
                } else {
                    if let current = muhurtas.first(where: { $0.isCurrent }) {
                        Button { detailMuhurta = current } label: {
                            currentMuhurtaBanner(current)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "Active now, muhurta \(current.id), \(current.name), \(current.quality.rawValue), " +
                            "\(shortTime(current.startTime)) to \(shortTime(current.endTime)), " +
                            "\(current.isDay ? "day" : "night") muhurta, \(current.purpose)"
                        )
                        .accessibilityHint("Opens muhurta details")
                        .padding(.horizontal)
                    }

                    muhurtaSummaryBar.padding(.horizontal)

                    MuhurtaTimelineView(muhurtas: muhurtas) { m in detailMuhurta = m }
                        .padding(.horizontal)

                    bestTimeTodayCard.padding(.horizontal)

                    CosmicGlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            CosmicSectionHeader(title: "Day Muhurtas (Sunrise → Sunset)", icon: "sun.max.fill")
                            ForEach(muhurtas.filter { $0.isDay }) { m in
                                Button { detailMuhurta = m } label: { MuhurtaRow(muhurta: m) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)

                    CosmicGlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            CosmicSectionHeader(title: "Night Muhurtas (Sunset → Sunrise)", icon: "moon.stars.fill")
                            ForEach(muhurtas.filter { !$0.isDay }) { m in
                                Button { detailMuhurta = m } label: { MuhurtaRow(muhurta: m) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Text("Muhurta times computed using local sunrise/sunset. For precise timings consult a qualified Jyotishi.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 20)
            }
            .padding(.top)
        }
        .sheet(item: $detailMuhurta) { m in
            MuhurtaDetailView(muhurta: m)
        }
    }

    private func currentMuhurtaBanner(_ m: Muhurta) -> some View {
        CosmicGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                        .overlay(Circle().fill(.green.opacity(0.4)).scaleEffect(1.8))
                    Text("NOW · Muhurta \(m.id)")
                        .font(.caption.bold()).foregroundStyle(.green)
                    Spacer()
                    Text(m.quality.emoji + " " + m.quality.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(qualityColor(m.quality))
                }
                Text(m.name).font(.title2.bold()).foregroundStyle(theme.primary)
                Text(m.purpose).font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    HStack(spacing: 6) {
                        CosmicIcon(.clock, size: 13, color: .secondary)
                        Text(shortTime(m.startTime))
                    }
                    Text("→")
                    Text(shortTime(m.endTime))
                    Spacer()
                    Text(m.isDay ? "☀️ Day" : "🌙 Night").font(.caption)
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Share

    private var panchangSummary: String {
        let p = resolvedPanchang
        let nak = CosmicEngine.getMoonNakshatraPada(context: calculationContext)
        let sunNak = CosmicEngine.getSunNakshatra(context: calculationContext)
        let sunSignIdx = Int(sunNak.degree / 30.0) % 12
        let df = selectedDate.ritualCompleteDate(in: calculationContext.timeZone)

        var lines: [String] = [
            "🌟 Panchang — \(df)",
            "Reference: \(p.referenceDisclosure(in: calculationContext.timeZone))",
            "",
            "✦ Vara (Weekday): \(p.weekdayName)",
            "✦ Tithi: \(p.tithiIndex < 15 ? "Shukla" : "Krishna") \(p.tithiName)" +
                (p.transitions.tithi.map { " (ends \($0.endTime.ritualTransitionLabel(relativeTo: p.date, in: calculationContext.timeZone)))" } ?? ""),
            "✦ Nakshatra: \(p.nakshatraName) (pada \(nak.pada))" +
                (p.transitions.nakshatra.map { " (ends \($0.endTime.ritualTransitionLabel(relativeTo: p.date, in: calculationContext.timeZone)))" } ?? ""),
            "✦ Yoga: \(p.yogaName)" +
                (p.transitions.yoga.map { " (ends \($0.endTime.ritualTransitionLabel(relativeTo: p.date, in: calculationContext.timeZone)))" } ?? ""),
            "✦ Karana: \(p.karanaName)" +
                (p.transitions.karana.map { " (ends \($0.endTime.ritualTransitionLabel(relativeTo: p.date, in: calculationContext.timeZone)))" } ?? ""),
            "",
            "☀ Surya Rashi: \(ZodiacSign.fromIndex(sunSignIdx).name)",
            "☀ Surya Nakshatra: \(sunNak.nakshatraName)",
            "🌙 Chandra Rashi: \(p.moonSignName)",
        ]

        if let rise = sunriseSunset?.0, let set = sunriseSunset?.1 {
            lines += [
                "",
                "🌅 Sunrise: \(shortTime(rise))",
                "🌇 Sunset: \(shortTime(set))",
            ]
        }

        lines += [
            "",
            "Generated by Cosmic Rituals • on-device, private"
        ]
        return lines.joined(separator: "\n")
    }

    // MARK: - Best Time Today

    private let activities = ["Travel", "Business", "Health", "Ceremony", "Study", "New Venture"]

    private let activityKeywords: [String: [String]] = [
        "Travel":      ["travel", "journey", "expedition", "movement", "speed"],
        "Business":    ["business", "financial", "commerce", "contract", "prosperity", "alliances", "deal", "agreements"],
        "Health":      ["health", "medicine", "healing", "medical", "therapy"],
        "Ceremony":    ["wedding", "ceremony", "ritual", "worship", "rites", "sacred", "auspicious rites"],
        "Study":       ["study", "learning", "education", "knowledge", "wisdom", "scholarship"],
        "New Venture": ["new venture", "new beginning", "launch", "start", "enterprise", "undertaking"]
    ]

    private var bestTimeTodayCard: some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                CosmicSectionHeader(title: "Best Time Today", icon: "star.circle.fill")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activities, id: \.self) { act in
                            Button {
                                if reduceMotion {
                                    selectedActivity = act
                                } else {
                                    withAnimation(.spring(duration: 0.25)) { selectedActivity = act }
                                }
                            } label: {
                                Text(act)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 44)
                                    .background(selectedActivity == act ? theme.primary : Color.primary.opacity(0.08),
                                                in: Capsule())
                                    .foregroundStyle(selectedActivity == act ? theme.selectedControlForeground : .primary)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Capsule())
                            .accessibilityValue(selectedActivity == act ? "Selected" : "Not selected")
                        }
                    }
                    .padding(.horizontal, 2)
                }

                let keywords = activityKeywords[selectedActivity] ?? []
                let matches = muhurtas
                    .filter { m in
                        guard let info = MuhurtaLibrary.info(for: m.id) else { return false }
                        let fav = info.favorable.joined(separator: " ").lowercased()
                        return keywords.contains { fav.contains($0) }
                    }
                    .sorted {
                        // Prefer current, then upcoming, then by quality
                        if $0.isCurrent { return true }
                        if $1.isCurrent { return false }
                        let qOrder: [MuhurtaQuality] = [.excellent, .auspicious, .mixed, .inauspicious]
                        let q0 = qOrder.firstIndex(of: $0.quality) ?? 3
                        let q1 = qOrder.firstIndex(of: $1.quality) ?? 3
                        if q0 != q1 { return q0 < q1 }
                        return $0.startTime < $1.startTime
                    }

                if let best = matches.first {
                    Button {
                        detailMuhurta = best
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    if best.isCurrent {
                                        Circle().fill(.green).frame(width: 7, height: 7)
                                        Text("NOW").font(.system(size: 8, weight: .black))
                                            .foregroundStyle(.green)
                                    }
                                    Text(best.quality.emoji + " " + best.quality.rawValue)
                                        .font(.caption.bold())
                                        .foregroundStyle(qualityColor(best.quality))
                                }
                                Text(best.name).font(.headline.bold()).foregroundStyle(theme.primary)
                                Text(best.purpose).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(shortTime(best.startTime))
                                    .font(.subheadline.bold()).monospacedDigit()
                                Text("→ " + shortTime(best.endTime))
                                    .font(.caption).foregroundStyle(.tertiary).monospacedDigit()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: 44)
                        .padding(10)
                        .background(qualityColor(best.quality).opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Best time for \(selectedActivity): \(best.name), \(best.quality.rawValue), " +
                        "\(shortTime(best.startTime)) to \(shortTime(best.endTime))"
                    )
                    .accessibilityHint("Opens muhurta details")
                } else {
                    Text("No matching muhurta found for \(selectedActivity) today.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var muhurtaSummaryBar: some View {
        let excellent    = muhurtas.filter { $0.quality == .excellent }.count
        let auspicious   = muhurtas.filter { $0.quality == .auspicious }.count
        let mixed        = muhurtas.filter { $0.quality == .mixed }.count
        let inauspicious = muhurtas.filter { $0.quality == .inauspicious }.count

        return HStack(spacing: 8) {
            MuhurtaSummaryPill(label: "★★ Excellent",  spokenLabel: "excellent",   count: excellent,    color: .yellow)
            MuhurtaSummaryPill(label: "★ Auspicious",  spokenLabel: "auspicious",  count: auspicious,   color: .green)
            MuhurtaSummaryPill(label: "◐ Mixed",       spokenLabel: "mixed",       count: mixed,        color: .orange)
            MuhurtaSummaryPill(label: "✕ Avoid",       spokenLabel: "to avoid",    count: inauspicious, color: .red)
        }
    }

    private var inauspiciousKalaCard: some View {
        let durMuhurtas = CosmicEngine.getDurMuhurta(context: calculationContext)
        let rahuKala = CosmicEngine.getRahuKala(context: calculationContext)
        let yamaganda = CosmicEngine.getYamaganda(context: calculationContext)
        let gulikaKala = CosmicEngine.getGulikaKala(context: calculationContext)

        return CosmicGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                CosmicSectionHeader(title: "Inauspicious Periods", icon: "exclamationmark.triangle")
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rahu Kala").font(.caption2).foregroundStyle(.tertiary)
                        Text(kalaTimeString(rahuKala))
                            .font(.subheadline.bold()).foregroundStyle(.red)
                        Text("Avoid new beginnings").font(.caption2).foregroundStyle(.secondary)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yamaganda").font(.caption2).foregroundStyle(.tertiary)
                        Text(kalaTimeString(yamaganda))
                            .font(.subheadline.bold()).foregroundStyle(.orange)
                        Text("Inauspicious period").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gulika Kala").font(.caption2).foregroundStyle(.tertiary)
                    Text(kalaTimeString(gulikaKala))
                        .font(.subheadline.bold()).foregroundStyle(.purple)
                    Text("Son of Saturn — highly inauspicious").font(.caption2).foregroundStyle(.secondary)
                }
                if !durMuhurtas.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dur Muhurta").font(.caption2).foregroundStyle(.tertiary)
                        HStack(spacing: 10) {
                            ForEach(durMuhurtas.indices, id: \.self) { i in
                                let dm = durMuhurtas[i]
                                Text("\(shortTime(dm.start)) – \(shortTime(dm.end))")
                                    .font(.subheadline.bold()).foregroundStyle(.pink)
                                if i < durMuhurtas.count - 1 {
                                    Text("·").foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Text("Classical inauspicious window").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Vedic Calendar Card

    @ViewBuilder
    private func vedicCalendarCard(_ vi: VedicCalendarInfo) -> some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                CosmicSectionHeader(title: "Vedic Calendar", icon: "calendar.badge.clock")

                // Samvat row
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vikram Samvat").font(.caption2).foregroundStyle(.tertiary)
                        Text("\(vi.vikramSamvat)").font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider().frame(height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shaka Samvat").font(.caption2).foregroundStyle(.tertiary)
                        Text("\(vi.shakaSamvat)").font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                }

                Divider()

                // Masa row
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Amanta Masa").font(.caption2).foregroundStyle(.tertiary)
                        Text(vi.amantaMasa).font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider().frame(height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Purnimanta Masa").font(.caption2).foregroundStyle(.tertiary)
                        Text(vi.purnimantaMasa).font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                }

                Divider()

                // Ritu + Ayana row
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vedic Ritu (Sidereal)").font(.caption2).foregroundStyle(.tertiary)
                        Text(vi.vedaRitu).font(.subheadline.bold())
                        Text(vi.drikRitu + " (Drik)").font(.system(size: 10)).foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider().frame(height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ayana").font(.caption2).foregroundStyle(.tertiary)
                        Text(vi.ayana)
                            .font(.subheadline.bold())
                            .foregroundStyle(vi.ayana == "Uttarayan" ? .yellow : .cyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                }

                Divider()

                // Anandadi Yoga
                HStack(spacing: 8) {
                    Circle()
                        .fill(vi.anandadiIsAuspicious ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("Anandadi Yoga:").font(.caption2).foregroundStyle(.tertiary)
                            Text(vi.anandadiYoga)
                                .font(.caption.bold())
                                .foregroundStyle(vi.anandadiIsAuspicious ? .green : .red)
                        }
                        Text(vi.anandadiMeaning).font(.caption2).foregroundStyle(.secondary)
                    }
                }

                // Amrit Kaal
                if let start = vi.amritKaalStart, let end = vi.amritKaalEnd {
                    Divider()
                    HStack(spacing: 8) {
                        CosmicIcon(name: "drop.fill", size: 13, color: .cyan)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Amrit Kaal").font(.caption2).foregroundStyle(.tertiary)
                            Text("\(shortTime(start)) – \(shortTime(end))")
                                .font(.subheadline.bold()).foregroundStyle(.cyan)
                            Text("Nectar time — excellent for all activities").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }

                // Chandrashtama (only if birth nakshatra is set)
                if !vi.chandrashtamaNakshatra.isEmpty {
                    Divider()
                    HStack(spacing: 8) {
                        CosmicIcon(name: vi.isCurrentlyChandrashtama ? "exclamationmark.triangle.fill" : "moon.haze.fill",
                                   size: 13, color: vi.isCurrentlyChandrashtama ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Chandrashtama (8th nakshatra)").font(.caption2).foregroundStyle(.tertiary)
                            Text(vi.chandrashtamaNakshatra)
                                .font(.caption.bold())
                                .foregroundStyle(vi.isCurrentlyChandrashtama ? .orange : .primary)
                            Text(vi.isCurrentlyChandrashtama
                                 ? "Active today — avoid major decisions"
                                 : "Not active today")
                                .font(.caption2)
                                .foregroundStyle(vi.isCurrentlyChandrashtama ? .orange : .secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func recompute() {
        let context = calculationContext
        panchangSnapshot = (context, CosmicEngine.getPanchang(context: context))
        muhurtas = CosmicEngine.getMuhurtas(context: context)
        sunriseSunset = CosmicEngine.getSunriseSunset(context: context)
        choghadiya = CosmicEngine.getChoghadiya(context: context)
        hora = CosmicEngine.getHora(context: context)
    }

    private func solarTimeCell(icon: String, color: Color, label: String, time: Date) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.headline).foregroundStyle(color)
                .accessibilityHidden(true)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
            Text(shortTime(time))
                .font(.subheadline.bold()).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(shortTime(time))")
    }

    private func shortTime(_ date: Date) -> String {
        date.ritualShortTime(in: calculationContext.timeZone)
    }

    private func qualityColor(_ q: MuhurtaQuality) -> Color {
        switch q {
        case .excellent:    return .yellow
        case .auspicious:   return .green
        case .mixed:        return .orange
        case .inauspicious: return .red
        }
    }

    private func kalaTimeString(_ period: (start: Date, end: Date)?) -> String {
        guard let period else { return "Unavailable" }
        return "\(shortTime(period.start)) – \(shortTime(period.end))"
    }
}

// MARK: - Theme Picker Sheet

private struct ThemePickerSheet: View {
    @Binding var variantRaw: String
    @Binding var experienceRaw: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                RitualSanctuaryBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Experience layout (independent from color appearance)
                        Text("Panchang Experience")
                            .font(.caption.bold()).foregroundStyle(theme.semanticSecondaryText)
                            .padding(.horizontal)
                        Text("Choose how the same Vedic data is organized. This does not change your color theme.")
                            .font(.caption).foregroundStyle(theme.semanticSecondaryText)
                            .padding(.horizontal)
                        RitualExperiencePicker(selectionRaw: $experienceRaw)
                            .padding(.horizontal)

                        Divider().overlay(theme.semanticDivider).padding(.horizontal)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Notifications Off", systemImage: "bell.slash.fill")
                                .font(.caption.bold())
                                .foregroundStyle(theme.semanticPrimaryText)
                            Text("Automatic ritual alerts are not enabled in this build. This prevents stale timings after a date or location change.")
                                .font(.caption)
                                .foregroundStyle(theme.semanticSecondaryText)
                        }
                        .padding(.horizontal)

                        Divider().overlay(theme.semanticDivider).padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Calculation Integrity", systemImage: "checkmark.shield.fill")
                                .font(.caption.bold())
                                .foregroundStyle(theme.semanticPrimaryText)

                            integrityRow(
                                title: "Daily reference",
                                detail: "Selected location's sunrise; local noon only when no sunrise exists"
                            )
                            integrityRow(
                                title: "Five limbs",
                                detail: "Meeus Sun and Moon series · Lahiri (Chitra Paksha) ayanamsha"
                            )
                            integrityRow(
                                title: "Transitions",
                                detail: "Tithi, Nakshatra, Yoga, and Karana solved independently"
                            )
                            integrityRow(
                                title: "Privacy",
                                detail: "All calculations and the city catalog stay on device"
                            )

                            Text("The numerical boundary solver has sub-second resolution. The compact offline ephemeris is checked against published civil-time fixtures with a conservative ±12 minute validation envelope. Regional observance rules can differ; confirm ceremonial timings with a qualified practitioner.")
                                .font(.caption)
                                .foregroundStyle(theme.semanticSecondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)

                        Divider().overlay(theme.semanticDivider).padding(.horizontal)

                        // Appearance
                        Text("Color Theme").font(.caption.bold()).foregroundStyle(theme.semanticSecondaryText)
                            .padding(.horizontal)
                        VStack(spacing: 6) {
                            ForEach(CosmicThemeVariant.allCases) { variant in
                                themeRow(variant)
                            }
                        }
                        .padding(.horizontal)

                        Divider().overlay(theme.semanticDivider).padding(.horizontal)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data Attribution")
                                .font(.caption.bold())
                                .foregroundStyle(theme.semanticSecondaryText)
                            Text(WorldCityCatalog.attribution)
                                .font(.caption)
                                .foregroundStyle(theme.semanticSecondaryText)
                            Link("GeoNames · CC BY 4.0", destination: URL(string: "https://www.geonames.org/")!)
                                .font(.caption)
                        }
                        .padding(.horizontal)

                        Divider().overlay(theme.semanticDivider).padding(.horizontal)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Subscription & Support")
                                .font(.caption.bold())
                                .foregroundStyle(theme.semanticSecondaryText)
                                .padding(.bottom, 6)
                            Link(destination: SubscriptionCatalog.manageSubscriptionsURL) {
                                Label("Manage subscription", systemImage: "creditcard.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            Link(destination: SubscriptionCatalog.privacyPolicyURL) {
                                Label("Privacy policy", systemImage: "hand.raised.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            Link(destination: SubscriptionCatalog.termsOfUseURL) {
                                Label("Terms of use", systemImage: "doc.text.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            Link(destination: SubscriptionCatalog.supportURL) {
                                Label("Support", systemImage: "questionmark.circle.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .environment(\.colorScheme, theme.colorScheme)
            .tint(theme.primary)
        }
    }

    private func themeRow(_ variant: CosmicThemeVariant) -> some View {
        let scheme = variant.colorScheme
        let isSelected = variantRaw == variant.rawValue
        return Button {
            variantRaw = variant.rawValue
        } label: {
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Circle().fill(scheme.primary).frame(width: 16, height: 16)
                    Circle().fill(scheme.secondary).frame(width: 12, height: 12)
                    Circle().fill(scheme.tertiary).frame(width: 9, height: 9)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(isSelected ? theme.primary : theme.semanticPrimaryText)
                    Text(scheme.isLight ? "Light" : "Dark")
                        .font(.caption2).foregroundStyle(theme.semanticSecondaryText)
                }
                Spacer()
                if isSelected {
                    CosmicIcon(.check, size: 18, color: theme.primary)
                }
            }
            .padding(14)
            .background(
                theme.surfaceElevated.opacity(theme.isLight ? 0.94 : 0.38),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? theme.primary.opacity(0.62) : theme.semanticBorder,
                        lineWidth: isSelected ? 1.0 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(variant.displayName) theme, \(scheme.isLight ? "light appearance" : "dark appearance")")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func integrityRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.semanticPrimaryText)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(theme.semanticSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Supporting Views

struct PanchangLimbRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            CosmicIcon(name: icon, size: 20, color: color)
                .frame(width: 22)
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
    }
}

struct MuhurtaRow: View {
    let muhurta: Muhurta
    @Environment(\.cosmicTheme) private var theme
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
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(muhurta.isCurrent ? theme.primary.opacity(0.2) : qualityColor.opacity(0.10))
                    .frame(width: 32, height: 32)
                Text("\(muhurta.id)")
                    .font(.caption2.bold())
                    .foregroundStyle(muhurta.isCurrent ? theme.primary : qualityColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(muhurta.name).font(.caption.bold())
                    if muhurta.isCurrent {
                        Text("NOW")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(.green).clipShape(Capsule())
                    }
                }
                Text(muhurta.purpose)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(muhurta.quality.emoji).font(.caption)
                Text(muhurta.startTime.ritualShortTime(in: timeZone))
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .background(muhurta.isCurrent ? theme.primary.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
        .accessibilityHint("Opens muhurta details")
    }

    private var spokenSummary: String {
        var parts = ["Muhurta \(muhurta.id)", muhurta.name, muhurta.quality.rawValue]
        if muhurta.isCurrent { parts.append("active now") }
        parts.append("\(muhurta.startTime.ritualShortTime(in: timeZone)) to \(muhurta.endTime.ritualShortTime(in: timeZone))")
        parts.append(muhurta.purpose)
        return parts.joined(separator: ", ")
    }
}

struct MuhurtaSummaryPill: View {
    let label: String
    let spokenLabel: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.headline.bold()).foregroundStyle(color)
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(spokenLabel) \(count == 1 ? "muhurta" : "muhurtas")")
    }
}
