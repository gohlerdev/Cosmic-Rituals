import SwiftUI

struct PanchangView: View {
    @State private var selectedDate = Date()
    @State private var knownToday = Date()
    @State private var lunarInfo: LunarMonthInfo?
    @Environment(\.scenePhase) private var scenePhase
    @State private var dayBundle: DailyPanchangBundle?
    @State private var detailMuhurta: Muhurta?
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
    @AppStorage("ritualBirthNakshatraIndex") private var birthNakshatraIndex = -1
    @AppStorage("ritualBirthPada") private var birthPada = 1
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
                            ChoghadiyaHoraView(
                                choghadiya: choghadiya,
                                hora: hora,
                                prahars: prahars,
                                dayNightMeasure: dayNightMeasure
                            )
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
                ThemePickerSheet(variantRaw: $variantRaw, experienceRaw: $experienceRaw, birthNakshatraIndex: $birthNakshatraIndex, birthPada: $birthPada)
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
        // The app previously kept showing Monday's Panchang when reopened on
        // Wednesday: nothing refreshed the selected day. Follow the calendar
        // forward on foreground return and at midnight -- but only when the
        // user was looking at what was then "today", never yanking away a
        // deliberately selected date.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            advanceDayIfStale()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            advanceDayIfStale()
        }
        .task(id: calculationContext) {
            let context = calculationContext
            lunarInfo = nil
            let info = await Task.detached(priority: .utility) {
                LunarCalendarEngine.monthInfo(context: context)
            }.value
            if context == calculationContext { lunarInfo = info }
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

    /// Every value derived from the selected day and location, computed once
    /// and tagged with the context that produced it. The previous shape tagged
    /// only the Panchang snapshot: muhurtas, solar times, Choghadiya, and Hora
    /// were bare state, so a location change could render one frame of the new
    /// context's Panchang against the old location's timings. It also left
    /// nine engine calls (including the full lunar series) running inside the
    /// render path on every minute tick.
    private struct DailyPanchangBundle {
        let context: CalculationContext
        let panchang: Panchang
        let muhurtas: [Muhurta]
        let sunriseSunset: (Date, Date)?
        let choghadiya: [Choghadiya]
        let hora: [Hora]
        let brahmaMuhurta: (start: Date, end: Date)?
        let abhijitMuhurta: (start: Date, end: Date)?
        let moonNakshatra: NakshatraResult
        let sunNakshatra: NakshatraResult
        let moonRiseSet: (moonrise: Date?, moonset: Date?)
        let durMuhurtas: [(start: Date, end: Date, label: String)]
        let rahuKala: (start: Date, end: Date)?
        let yamaganda: (start: Date, end: Date)?
        let gulikaKala: (start: Date, end: Date)?
        let limbWindows: [PanchangLimbKind: [PanchangLimbWindow]]
        let varjyam: [PanchangSpecialWindows.SpecialWindow]
        let amritKalam: [PanchangSpecialWindows.SpecialWindow]
        let panchaka: (typeName: String?, active: Bool)
        let prahars: [Prahar]
        let dayNightMeasure: DayNightMeasure?

        static func compute(for context: CalculationContext) -> DailyPanchangBundle {
            DailyPanchangBundle(
                context: context,
                panchang: CosmicEngine.getPanchang(context: context),
                muhurtas: CosmicEngine.getMuhurtas(context: context),
                sunriseSunset: CosmicEngine.getSunriseSunset(context: context),
                choghadiya: CosmicEngine.getChoghadiya(context: context),
                hora: CosmicEngine.getHora(context: context),
                brahmaMuhurta: CosmicEngine.getBrahmaMuhurta(context: context),
                abhijitMuhurta: CosmicEngine.getAbhijitMuhurta(context: context),
                moonNakshatra: CosmicEngine.getMoonNakshatraPada(context: context),
                sunNakshatra: CosmicEngine.getSunNakshatra(context: context),
                moonRiseSet: CelestialRiseSet.moonRiseSet(context: context),
                durMuhurtas: CosmicEngine.getDurMuhurta(context: context),
                rahuKala: CosmicEngine.getRahuKala(context: context),
                yamaganda: CosmicEngine.getYamaganda(context: context),
                gulikaKala: CosmicEngine.getGulikaKala(context: context),
                limbWindows: Dictionary(uniqueKeysWithValues: PanchangLimbKind.allCases.map {
                    ($0, CosmicEngine.limbWindows(for: $0, context: context))
                }),
                varjyam: PanchangSpecialWindows.varjyam(context: context),
                amritKalam: PanchangSpecialWindows.amritKalam(context: context),
                panchaka: PanchangSpecialWindows.panchaka(context: context),
                prahars: TraditionalClock.prahars(context: context),
                dayNightMeasure: TraditionalClock.dayNightMeasure(context: context)
            )
        }
    }

    /// Self-heals exactly like the old resolvedPanchang: if the cached bundle
    /// was built for a different context (location or date changed but
    /// recompute has not run yet), compute fresh rather than render stale
    /// values for one frame.
    private var resolvedBundle: DailyPanchangBundle {
        let context = calculationContext
        if let dayBundle, dayBundle.context == context {
            return dayBundle
        }
        return .compute(for: context)
    }

    private var resolvedPanchang: Panchang { resolvedBundle.panchang }
    private var muhurtas: [Muhurta] { resolvedBundle.muhurtas }
    private var sunriseSunset: (Date, Date)? { resolvedBundle.sunriseSunset }
    private var choghadiya: [Choghadiya] { resolvedBundle.choghadiya }
    private var hora: [Hora] { resolvedBundle.hora }
    private var prahars: [Prahar] { resolvedBundle.prahars }
    private var dayNightMeasure: DayNightMeasure? { resolvedBundle.dayNightMeasure }

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
                            if let brahma = resolvedBundle.brahmaMuhurta {
                                HStack(spacing: 6) {
                                    CosmicIcon(name: "moon.zzz.fill", size: 13, color: .purple)
                                    Text("Brahma Muhurta")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(shortTime(brahma.start)) – \(shortTime(brahma.end))")
                                        .font(.caption.bold()).foregroundStyle(.purple)
                                }
                            }
                            if let abhijit = resolvedBundle.abhijitMuhurta {
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
                        // Moonrise/moonset are NOT sunrise-based: during polar
                        // day or night the Moon still genuinely rises and sets
                        // on many dates, so these rows render regardless of
                        // whether the Sun does.
                        Divider()
                        let moonEvents = resolvedBundle.moonRiseSet
                        HStack(spacing: 6) {
                            CosmicIcon(name: "moon.haze.fill", size: 13, color: .cyan)
                            Text("Moonrise").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(moonEvents.moonrise.map { shortTime($0) } ?? "None this day")
                                .font(.caption.bold()).foregroundStyle(.cyan)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("panchang.moonrise")
                        HStack(spacing: 6) {
                            CosmicIcon(name: "moon.fill", size: 13, color: .indigo)
                            Text("Moonset").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(moonEvents.moonset.map { shortTime($0) } ?? "None this day")
                                .font(.caption.bold()).foregroundStyle(.indigo)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("panchang.moonset")
                        if moonEvents.moonrise == nil || moonEvents.moonset == nil {
                            Text("About once a lunar month the rise or set slips past midnight and a civil day genuinely has none.")
                                .font(.caption2).foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal)

                CosmicGlassCard(cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        CosmicSectionHeader(title: "Nakshatra Detail", icon: "star.fill")
                        let nak = resolvedBundle.moonNakshatra

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

                personalStarsCard(for: p)

                lunarCalendarCard

                dayTimelineCard

                inauspiciousKalaCard

            }
            .padding(.vertical)
        }
    }

    /// Tarabala / Chandrabala / Chandrashtama for the configured birth star.
    /// Hidden until the user sets a birth nakshatra in Settings.
    @ViewBuilder
    private func personalStarsCard(for panchang: Panchang) -> some View {
        if (0..<27).contains(birthNakshatraIndex) {
            let tara = PersonalStarEngine.tarabala(
                birthNakshatraIndex: birthNakshatraIndex,
                dayNakshatraIndex: panchang.nakshatraIndex
            )
            let janmaRashi = PersonalStarEngine.janmaRashiIndex(
                birthNakshatraIndex: birthNakshatraIndex, pada: birthPada
            )
            let chandrashtama = PersonalStarEngine.isChandrashtama(
                janmaRashiIndex: janmaRashi, dayMoonSignIndex: panchang.moonSignIndex
            )
            let chandrabala = PersonalStarEngine.hasChandrabala(
                janmaRashiIndex: janmaRashi, dayMoonSignIndex: panchang.moonSignIndex
            )
            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    CosmicSectionHeader(title: "Personal Stars", icon: "person.crop.circle.badge.moon")
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tarabala · \(tara.name) (\(tara.taraNumber) of 9)")
                                .font(.subheadline.bold())
                                .foregroundStyle(tara.quality == .favorable ? .green : tara.quality == .unfavorable ? .orange : .yellow)
                            Text(tara.note)
                                .font(.caption2).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("panchang.personal.tarabala")
                    Divider()
                    HStack(spacing: 6) {
                        CosmicIcon(name: chandrabala ? "moon.stars.fill" : "moon", size: 13, color: chandrabala ? .green : .secondary)
                        Text(chandrabala
                             ? "Chandrabala present — the Moon sits in a supportive sign from your janma rashi."
                             : "Chandrabala absent today.")
                            .font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if chandrashtama {
                        HStack(spacing: 6) {
                            CosmicIcon(name: "exclamationmark.triangle.fill", size: 13, color: .red)
                            Text("Chandrashtama: the Moon transits the 8th sign from your janma rashi — traditionally a day for lighter commitments.")
                                .font(.caption.bold()).foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text("Computed from your saved birth nakshatra (\(Panchang.nakshatraNames[birthNakshatraIndex]), pada \(birthPada)). Traditional day-quality context, not a prediction or an obligation.")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func panchangYogaCard(for panchang: Panchang) -> some View {
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        if !matches.isEmpty {
            // Every one of these yogas depends on the Moon's nakshatra, so
            // none outlasts the nakshatra itself even when the weekday does.
            let nakshatraEndsLabel = panchang.transitions.nakshatra.map {
                " (until \($0.endTime.ritualTransitionLabel(relativeTo: panchang.date, in: calculationContext.timeZone)))"
            } ?? ""
            CosmicGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    CosmicSectionHeader(title: "Auspicious Combinations", icon: "sparkles")
                    ForEach(matches) { match in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(match.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.primary)
                            Text(match.summary + nakshatraEndsLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("panchang.yoga.\(match.id)")
                        if match.id != matches.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal)
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
        let nak = resolvedBundle.moonNakshatra
        let sunNak = resolvedBundle.sunNakshatra
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
                // Engine-side selection with an explicit clock: never a
                // window that already ended, never a mixed or inauspicious
                // window, quality before currency.
                let best = MuhurtaRecommendation.best(
                    matchingKeywords: keywords, in: muhurtas, now: Date()
                )

                if let best {
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
                    Text("No excellent or auspicious muhurta for \(selectedActivity) remains today.")
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

    /// Masa (Amanta and Purnimanta), paksha, Adhika, Vikram/Shaka years, and
    /// Ayana -- the real lunisolar construction (sankranti-inside-lunation),
    /// replacing the quarantined sun-sign approximation, computed off-main.
    @ViewBuilder
    private var lunarCalendarCard: some View {
        CosmicGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                CosmicSectionHeader(title: "Lunar Calendar", icon: "moon.stars.fill")
                if let info = lunarInfo {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Amanta").font(.caption2).foregroundStyle(.tertiary)
                            Text(info.amantaMasaName).font(.subheadline.bold())
                        }
                        Divider().frame(height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Purnimanta").font(.caption2).foregroundStyle(.tertiary)
                            Text(info.purnimantaMasaName).font(.subheadline.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(info.pakshaName).font(.caption.bold()).foregroundStyle(theme.primary)
                            Text(LunarCalendarEngine.ayanaName(context: calculationContext))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("panchang.lunarmonth")
                    if info.isAdhika {
                        Text("ADHIKA MASA — this lunation contains no sankranti and borrows the following month's name; observances follow regional convention.")
                            .font(.system(size: 9, weight: .black)).foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if info.isKshaya {
                        Text("KSHAYA MASA — two sankrantis fall in this rare lunation.")
                            .font(.system(size: 9, weight: .black)).foregroundStyle(.red)
                    }
                    HStack(spacing: 12) {
                        Text("Vikram Samvat \(String(info.vikramYear))")
                        Text("Shaka \(String(info.shakaYear))")
                    }
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                    Text("Years increment at Chaitra Shukla Pratipada (North-Indian anchor; Gujarat's Kartika-anchored Vikram variant differs). Ayana follows the sidereal Sun, the Makar-Sankranti tradition; the solstice-based reckoning differs.")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Computing the lunisolar month…")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    /// Every limb window of the Panchang day -- the block a printed daily
    /// panchang publishes: each tithi/nakshatra/yoga/karana with its start
    /// and end, including kshaya windows that never touch a sunrise and
    /// vriddhi values spanning both.
    private var dayTimelineCard: some View {
        let bundle = resolvedBundle
        let anchor = bundle.panchang.date
        let kinds: [(PanchangLimbKind, String)] = [
            (.tithi, "Tithi"), (.nakshatra, "Nakshatra"), (.yoga, "Yoga"), (.karana, "Karana"),
        ]
        return CosmicGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                CosmicSectionHeader(title: "Day Timeline", icon: "timeline.selection")
                Text("Every limb window from this sunrise to the next, as a printed panchang lists them.")
                    .font(.caption2).foregroundStyle(.secondary)
                specialWindowRows(bundle: bundle, anchor: anchor)
                Divider()
                ForEach(kinds, id: \.0) { kind, label in
                    if let windows = bundle.limbWindows[kind], !windows.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                            ForEach(windows.indices, id: \.self) { index in
                                let window = windows[index]
                                HStack(spacing: 6) {
                                    Text(window.name)
                                        .font(.caption.bold())
                                        .foregroundStyle(theme.primary)
                                    Spacer()
                                    Text("\(window.startTime.ritualTransitionLabel(relativeTo: anchor, in: calculationContext.timeZone)) – \(window.endTime.ritualTransitionLabel(relativeTo: anchor, in: calculationContext.timeZone))")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                        if kind != .karana { Divider() }
                    }
                }
            }
        }
        .padding(.horizontal)
        .accessibilityIdentifier("panchang.daytimeline")
    }

    /// Varjyam / Amrit Kalam spans, the Anandadi day-yoga per nakshatra,
    /// and the Ganda Mula / Panchaka flags. All table-driven from
    /// independently verified sources (see ACCURACY.md).
    @ViewBuilder
    private func specialWindowRows(bundle: DailyPanchangBundle, anchor: Date) -> some View {
        let weekday = calculationContext.localDayComponents.weekday ?? 1
        VStack(alignment: .leading, spacing: 4) {
            ForEach(bundle.varjyam.indices, id: \.self) { index in
                let window = bundle.varjyam[index]
                HStack(spacing: 6) {
                    Text("Varjyam").font(.caption.bold()).foregroundStyle(.red)
                    Text("(\(window.nakshatraName))").font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(window.startTime.ritualTransitionLabel(relativeTo: anchor, in: calculationContext.timeZone)) – \(window.endTime.ritualTransitionLabel(relativeTo: anchor, in: calculationContext.timeZone))")
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("panchang.varjyam.\(index)")
            }
            ForEach(bundle.amritKalam.indices, id: \.self) { index in
                let window = bundle.amritKalam[index]
                HStack(spacing: 6) {
                    Text("Amrit Kalam").font(.caption.bold()).foregroundStyle(.green)
                    Text("(\(window.nakshatraName))").font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(window.startTime.ritualTransitionLabel(relativeTo: anchor, in: calculationContext.timeZone)) – \(window.endTime.ritualTransitionLabel(relativeTo: anchor, in: calculationContext.timeZone))")
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("panchang.amritkalam.\(index)")
            }
            if let nakWindows = bundle.limbWindows[.nakshatra] {
                ForEach(nakWindows.indices, id: \.self) { index in
                    let window = nakWindows[index]
                    if let nakIndex = nakshatraIndex(named: window.name),
                       let yogaIndex = PanchangSpecialWindows.anandadiIndex(weekday: weekday, nakshatraIndex: nakIndex) {
                        let yoga = PanchangSpecialWindows.anandadiYogas[yogaIndex]
                        HStack(spacing: 6) {
                            Text("Anandadi").font(.caption.bold()).foregroundStyle(.purple)
                            Text("\(yoga.name)\(yoga.isAuspicious ? "" : " · caution") during \(window.name)")
                                .font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            HStack(spacing: 8) {
                if let nakIndex = nakshatraIndex(named: bundle.panchang.nakshatraName),
                   PanchangSpecialWindows.isGandaMula(nakshatraIndex: nakIndex) {
                    Text("GANDA MULA NAKSHATRA")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.orange)
                }
                if bundle.panchaka.active {
                    Text("PANCHAKA\(bundle.panchaka.typeName.map { " · \($0)" } ?? "")")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func nakshatraIndex(named name: String) -> Int? {
        Panchang.nakshatraNames.firstIndex(of: name)
    }

    private var inauspiciousKalaCard: some View {
        let bundle = resolvedBundle
        let durMuhurtas = bundle.durMuhurtas
        let rahuKala = bundle.rahuKala
        let yamaganda = bundle.yamaganda
        let gulikaKala = bundle.gulikaKala

        let panchang = bundle.panchang
        let dishaShula = DishaShula.direction(forWeekdayName: panchang.weekdayName)

        return CosmicGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                CosmicSectionHeader(title: "Inauspicious Periods", icon: "exclamationmark.triangle")
                let vishtiWindows = bundle.limbWindows[.karana]?.filter {
                    $0.name == Panchang.karanaNames[BhadraAdvisory.vishtiKaranaIndex]
                } ?? []
                if !vishtiWindows.isEmpty {
                    ForEach(vishtiWindows.indices, id: \.self) { index in
                        let window = vishtiWindows[index]
                        HStack(spacing: 6) {
                            CosmicIcon(name: "hand.raised.fill", size: 13, color: .red)
                            Text("Bhadra (Vishti karana)\(window.startTime <= now && now < window.endTime ? " — running now" : "")")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                            Spacer()
                            Text("\(window.startTime.ritualTransitionLabel(relativeTo: panchang.date, in: calculationContext.timeZone)) – \(window.endTime.ritualTransitionLabel(relativeTo: panchang.date, in: calculationContext.timeZone))")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("panchang.bhadra.\(index)")
                    }
                    Text("Vishti is the one karana classically treated as a standing caution for new undertakings; every span of this Panchang day is listed.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Divider()
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rahu Kala").font(.caption2).foregroundStyle(.tertiary)
                        Text(kalaTimeString(rahuKala))
                            .font(.subheadline.bold()).foregroundStyle(.red)
                        Text("Avoid new beginnings").font(.caption2).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("panchang.rahukala")
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yamaganda").font(.caption2).foregroundStyle(.tertiary)
                        Text(kalaTimeString(yamaganda))
                            .font(.subheadline.bold()).foregroundStyle(.orange)
                        Text("Inauspicious period").font(.caption2).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("panchang.yamaganda")
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gulika Kala").font(.caption2).foregroundStyle(.tertiary)
                    Text(kalaTimeString(gulikaKala))
                        .font(.subheadline.bold()).foregroundStyle(.purple)
                    Text("Son of Saturn — highly inauspicious").font(.caption2).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("panchang.gulikakala")
                if let dishaShula {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disha Shula").font(.caption2).foregroundStyle(.tertiary)
                        Text("Avoid starting travel toward the \(dishaShula)")
                            .font(.subheadline.bold()).foregroundStyle(.teal)
                        Text("Traditional weekday travel-direction caution; not a prohibition.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("panchang.dishashula")
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
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("panchang.durmuhurta")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func recompute() {
        dayBundle = .compute(for: calculationContext)
    }

    private func advanceDayIfStale() {
        let current = Date()
        if PanchangDayRollover.shouldAdvance(
            selectedDate: selectedDate,
            knownToday: knownToday,
            now: current,
            timeZone: calculationContext.timeZone
        ) {
            selectedDate = current  // recompute follows via onChange
        }
        knownToday = current
        now = current
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
    @Binding var birthNakshatraIndex: Int
    @Binding var birthPada: Int
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

                        // Birth star: unlocks the Personal Stars card
                        // (Tarabala, Chandrabala, Chandrashtama). Optional,
                        // stored on device only.
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Birth Nakshatra (optional)")
                                .font(.caption.bold()).foregroundStyle(theme.semanticSecondaryText)
                            Text("From your birth chart. Enables the personal Tarabala, Chandrabala, and Chandrashtama reading for each day. Stored only on this device.")
                                .font(.caption).foregroundStyle(theme.semanticSecondaryText)
                            Picker("Birth nakshatra", selection: $birthNakshatraIndex) {
                                Text("Not set").tag(-1)
                                ForEach(0..<27, id: \.self) { index in
                                    Text(Panchang.nakshatraNames[index]).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("settings.birthNakshatra")
                            if birthNakshatraIndex >= 0 {
                                Picker("Pada", selection: $birthPada) {
                                    ForEach(1...4, id: \.self) { pada in
                                        Text("Pada \(pada)").tag(pada)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityIdentifier("settings.birthPada")
                                Text("The pada decides your janma rashi when a nakshatra spans two signs, which Chandrabala and Chandrashtama depend on.")
                                    .font(.caption2).foregroundStyle(theme.semanticSecondaryText)
                            }
                        }
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
                            Text("Privacy & Support")
                                .font(.caption.bold())
                                .foregroundStyle(theme.semanticSecondaryText)
                                .padding(.bottom, 6)
                            Label("Free, with no accounts and no purchases", systemImage: "gift.fill")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .accessibilityLabel("This app is free. There are no accounts and no purchases.")
                            Link(destination: AppLinks.privacyPolicyURL) {
                                Label("Privacy policy", systemImage: "hand.raised.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            Link(destination: AppLinks.termsOfUseURL) {
                                Label("Terms of use", systemImage: "doc.text.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            Link(destination: AppLinks.supportURL) {
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
