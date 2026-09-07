import SwiftUI

struct PoojaVidhiLibraryView: View {
    let dayContext: RitualDayContext?
    let changeLocation: (() -> Void)?
    @State private var query = ""
    @State private var selectedCategory: PoojaCategory?
    @Environment(\.cosmicTheme) private var theme
    @EnvironmentObject private var ritualSessionStore: RitualSessionStore

    init(dayContext: RitualDayContext? = nil, changeLocation: (() -> Void)? = nil) {
        self.dayContext = dayContext
        self.changeLocation = changeLocation
    }

    private var results: [PoojaVidhi] {
        PoojaVidhiCatalog.search(query, category: selectedCategory)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                libraryHeader
                if let dayContext {
                    RitualDayContextCard(context: dayContext, changeLocation: changeLocation)
                }
                if let session = ritualSessionStore.mostRecentUnfinishedSession,
                   let vidhi = PoojaVidhiCatalog.vidhi(id: session.id) {
                    NavigationLink {
                        if session.status == .inProgress {
                            GuidedPoojaView(vidhi: vidhi)
                        } else {
                            PoojaVidhiDetailView(vidhi: vidhi)
                        }
                    } label: {
                        PoojaResumeCard(vidhi: vidhi, session: session)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("pooja.resume.\(vidhi.id)")
                }
                categoryPicker

                if results.isEmpty {
                    ContentUnavailableView(
                        "No matching Pooja Vidhi",
                        systemImage: "magnifyingglass",
                        description: Text("Try a deity, occasion, purpose, or clear the category filter.")
                    )
                    .foregroundStyle(theme.semanticPrimaryText)
                    .padding(.vertical, 40)
                } else {
                    HStack {
                        Text("\(results.count) guides")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.semanticSecondaryText)
                        Spacer()
                        Text("Available offline")
                            .font(.caption2)
                            .foregroundStyle(theme.semanticTertiaryText)
                    }
                    .padding(.horizontal, 4)

                    ForEach(results) { vidhi in
                        NavigationLink {
                            PoojaVidhiDetailView(vidhi: vidhi)
                        } label: {
                            PoojaVidhiLibraryCard(vidhi: vidhi)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("pooja.vidhi.\(vidhi.id)")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .searchable(text: $query, prompt: "Deity, occasion, mantra, purpose")
        .accessibilityIdentifier("pooja.library")
    }

    private var libraryHeader: some View {
        CosmicGlassCard(cornerRadius: 24, accentBorder: true) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.16))
                            .frame(width: 48, height: 48)
                        Image(systemName: "hands.and.sparkles.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(theme.primary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pooja Vidhis")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(theme.semanticPrimaryText)
                        Text("Prepare · understand · proceed step by step")
                            .font(.subheadline)
                            .foregroundStyle(theme.semanticSecondaryText)
                    }
                }

                Label("Household guidance, not one universal rite", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.primary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { libraryTrustPills }
                    VStack(alignment: .leading, spacing: 8) { libraryTrustPills }
                }

                Text(PoojaContentPolicy.householdScope)
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pooja Vidhis. \(PoojaVidhiCatalog.all.count) offline household and preparation guides. Family and temple tradition takes precedence.")
    }

    @ViewBuilder
    private var libraryTrustPills: some View {
        PoojaMetadataPill(text: "\(PoojaVidhiCatalog.all.count) guided rites", symbol: "hands.and.sparkles.fill")
        PoojaMetadataPill(text: "Source adapted", symbol: "books.vertical.fill")
        PoojaMetadataPill(text: "Offline", symbol: "lock.shield.fill")
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryButton(nil, title: "All", symbol: "square.grid.2x2.fill")
                ForEach(PoojaCategory.allCases) { category in
                    categoryButton(category, title: category.displayName, symbol: category.symbol)
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityLabel("Filter Pooja Vidhis")
    }

    @ViewBuilder
    private func categoryButton(_ category: PoojaCategory?, title: String, symbol: String) -> some View {
        let isSelected = selectedCategory == category
        let button = Button {
            withAnimation(.snappy(duration: 0.22)) {
                selectedCategory = category
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 38)
                .foregroundStyle(isSelected ? theme.selectedControlForeground : theme.semanticSecondaryText)
        }
        if isSelected {
            button
                .buttonStyle(.glassProminent)
                .tint(theme.primary)
                .accessibilityValue("Selected")
        } else {
            button
                .buttonStyle(.glass)
                .tint(theme.surfaceElevated)
                .accessibilityValue("Not selected")
        }
    }
}

private struct RitualDayContextCard: View {
    let context: RitualDayContext
    let changeLocation: (() -> Void)?
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CosmicGlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Ritual context", systemImage: "sunrise.fill")
                        .font(.headline)
                        .foregroundStyle(theme.semanticPrimaryText)
                    Spacer()
                    Text("CALCULATED")
                        .font(.caption2.weight(.black))
                        .tracking(1.1)
                        .foregroundStyle(theme.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.civilDate)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.semanticPrimaryText)
                    ForEach(
                        Array(
                            RitualResponsiveLayout.locationMetadataLines(
                                sourceDescription: context.locationName,
                                timeZoneIdentifier: context.timeZoneIdentifier,
                                for: dynamicTypeSize
                            ).enumerated()
                        ),
                        id: \.offset
                    ) { _, line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(theme.semanticSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if dynamicTypeSize > .large {
                    VStack(alignment: .leading, spacing: 8) { contextPills }
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { contextPills }
                        VStack(alignment: .leading, spacing: 8) { contextPills }
                    }
                }
                Text("Use these sunrise-anchored facts to confirm timing with your family, temple, or practitioner. They do not make one Pooja universally required today.")
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let changeLocation {
                    Button(action: changeLocation) {
                        Label("Change calculation location", systemImage: "mappin.and.ellipse")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 42)
                    }
                    .buttonStyle(.glass)
                    .accessibilityHint("Recalculates the ritual context for another saved or offline city")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pooja.dayContext")
    }

    @ViewBuilder
    private var contextPills: some View {
        PoojaMetadataPill(text: context.tithiName, symbol: "moonphase.first.quarter")
        PoojaMetadataPill(text: context.nakshatraName, symbol: "sparkles")
        PoojaMetadataPill(text: context.sunriseDisclosure, symbol: "sunrise.fill")
    }
}

private struct PoojaResumeCard: View {
    let vidhi: PoojaVidhi
    let session: RitualSession
    @Environment(\.cosmicTheme) private var theme

    private var detail: String {
        switch session.status {
        case .preparing: return "Continue preparing materials"
        case .inProgress: return "Resume step \(session.currentStepIndex + 1) of \(vidhi.steps.count)"
        case .completed: return "Completed"
        }
    }

    var body: some View {
        CosmicGlassCard(cornerRadius: 22, accentBorder: true) {
            HStack(spacing: 13) {
                Image(systemName: session.status == .inProgress ? "play.fill" : "checklist")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.selectedControlForeground)
                    .frame(width: 46, height: 46)
                    .background(theme.primary, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Continue your ritual")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.primary)
                    Text(vidhi.title)
                        .font(.headline)
                        .foregroundStyle(theme.semanticPrimaryText)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(theme.semanticSecondaryText)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.semanticTertiaryText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Continue \(vidhi.title). \(detail). Progress is saved on this device.")
    }
}

private struct PoojaVidhiLibraryCard: View {
    let vidhi: PoojaVidhi
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        CosmicGlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(vidhi.category.accent.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: vidhi.category.symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(vidhi.category.accent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vidhi.title)
                            .font(.headline)
                            .foregroundStyle(theme.semanticPrimaryText)
                            .multilineTextAlignment(.leading)
                        Text(vidhi.sacredFocus)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.primary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.semanticTertiaryText)
                        .padding(.top, 6)
                }

                Text(vidhi.summary)
                    .font(.subheadline)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { metadataPills }
                    VStack(alignment: .leading, spacing: 7) { metadataPills }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vidhi.title), \(vidhi.sacredFocus), \(vidhi.durationText), \(vidhi.practiceLevel.displayName). \(vidhi.summary)")
        .accessibilityHint("Opens preparation, materials, steps, mantras, and guidance")
    }

    @ViewBuilder
    private var metadataPills: some View {
        PoojaMetadataPill(text: vidhi.durationText, symbol: "clock")
        PoojaMetadataPill(text: vidhi.practiceLevel.displayName, symbol: vidhi.practiceLevel == .priestRecommended ? "person.badge.shield.checkmark.fill" : "house.fill")
    }
}

struct PoojaVidhiDetailView: View {
    let vidhi: PoojaVidhi
    @Environment(\.cosmicTheme) private var theme
    @EnvironmentObject private var ritualSessionStore: RitualSessionStore

    private var session: RitualSession { ritualSessionStore.session(for: vidhi) }
    private var preparedMaterialIDs: Set<String> { session.preparedMaterialIDs }

    private var preparationProgress: Double {
        readiness.requiredPreparationProgress
    }

    private var readiness: PoojaReadiness {
        vidhi.readiness(preparedMaterialIDs: preparedMaterialIDs)
    }

    var body: some View {
        ZStack {
            RitualSanctuaryBackground()
            ScrollView {
                LazyVStack(spacing: 16) {
                    hero
                    readinessSection
                    practiceBoundary
                    preparationSection
                    materialsSection
                    stepsSection
                    safetySection
                    sourcesSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 104)
            }
        }
        .navigationTitle(vidhi.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: vidhi.shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share Pooja Vidhi")
            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                GuidedPoojaView(vidhi: vidhi)
            } label: {
                Label(
                    beginActionTitle,
                    systemImage: beginActionSymbol
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
            }
            .buttonStyle(.glassProminent)
            .tint(theme.primary)
            .foregroundStyle(theme.selectedControlForeground)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .accessibilityIdentifier("pooja.begin.\(vidhi.id)")
        }
    }

    private var beginActionTitle: String {
        if session.status == .inProgress {
            return "Resume step \(session.currentStepIndex + 1) of \(vidhi.steps.count)"
        }
        if session.status == .completed {
            return "Begin this Pooja again"
        }
        if vidhi.practiceLevel == .priestRecommended {
            return "Open ceremony guide"
        }
        if readiness.hasPreparedRequiredMaterials {
            return "Begin guided Pooja"
        }
        return "Review guide · \(readiness.remainingRequiredMaterialCount) required left"
    }

    private var beginActionSymbol: String {
        readiness.hasPreparedRequiredMaterials ? "play.fill" : "book.pages.fill"
    }

    private var hero: some View {
        CosmicGlassCard(cornerRadius: 24, accentBorder: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(vidhi.category.accent.opacity(0.16))
                            .frame(width: 56, height: 56)
                        Image(systemName: vidhi.category.symbol)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(vidhi.category.accent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vidhi.sacredFocus)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(theme.semanticPrimaryText)
                        Text(vidhi.purpose)
                            .font(.caption)
                            .foregroundStyle(theme.semanticSecondaryText)
                    }
                }

                Text(vidhi.summary)
                    .font(.body)
                    .foregroundStyle(theme.semanticPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { detailMetadataPills }
                    VStack(alignment: .leading, spacing: 8) { detailMetadataPills }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(vidhi.occasions, id: \.self) { occasion in
                            Text(occasion)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(theme.semanticSecondaryText)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(theme.surfaceElevated.opacity(0.72), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var detailMetadataPills: some View {
        PoojaMetadataPill(text: vidhi.durationText, symbol: "clock")
        PoojaMetadataPill(text: "\(vidhi.steps.count) steps", symbol: "list.number")
        PoojaMetadataPill(text: vidhi.practiceLevel.displayName, symbol: vidhi.practiceLevel == .priestRecommended ? "person.badge.shield.checkmark.fill" : "house.fill")
    }

    private var readinessSection: some View {
        PoojaSectionCard(title: "Ritual readiness", symbol: "checkmark.seal.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: readiness.requiredPreparationProgress)
                    .tint(readiness.hasPreparedRequiredMaterials ? .green : theme.primary)
                    .accessibilityHidden(true)

                readinessRow(
                    title: "Materials",
                    detail: readiness.materialStatus,
                    symbol: readiness.hasPreparedRequiredMaterials ? "checkmark.circle.fill" : "circle.dotted",
                    color: readiness.hasPreparedRequiredMaterials ? .green : theme.primary
                )
                readinessRow(
                    title: "Practice boundary",
                    detail: readiness.practiceStatus,
                    symbol: vidhi.practiceLevel == .priestRecommended ? "person.badge.shield.checkmark.fill" : "house.fill",
                    color: vidhi.practiceLevel == .priestRecommended ? .orange : theme.tertiary
                )
                readinessRow(
                    title: "Provenance",
                    detail: readiness.sourceStatus,
                    symbol: "books.vertical.fill",
                    color: theme.secondary
                )
            }
        }
    }

    private func readinessRow(title: String, detail: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.semanticPrimaryText)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var practiceBoundary: some View {
        CosmicGlassCard(cornerRadius: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: vidhi.practiceLevel == .priestRecommended ? "person.badge.shield.checkmark.fill" : "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(vidhi.practiceLevel == .priestRecommended ? .orange : theme.primary)
                VStack(alignment: .leading, spacing: 5) {
                    Text(vidhi.practiceLevel.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.semanticPrimaryText)
                    Text(vidhi.practiceLevel.guidance)
                        .font(.caption)
                        .foregroundStyle(theme.semanticSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(vidhi.traditionNote)
                        .font(.caption)
                        .foregroundStyle(theme.semanticTertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var preparationSection: some View {
        PoojaSectionCard(title: "Before you begin", symbol: "checklist") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(vidhi.preparation.enumerated()), id: \.offset) { index, item in
                    PoojaNumberedLine(number: index + 1, text: item)
                }
            }
        }
    }

    private var materialsSection: some View {
        PoojaSectionCard(title: "Prepare materials", symbol: "basket.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: preparationProgress)
                    .tint(theme.primary)
                    .accessibilityHidden(true)

                HStack {
                    Text("Required \(readiness.preparedRequiredMaterialCount)/\(readiness.requiredMaterialCount)")
                    Spacer()
                    Text("Optional \(readiness.preparedOptionalMaterialCount)/\(readiness.optionalMaterialCount)")
                }
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(theme.semanticTertiaryText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Materials prepared")
                .accessibilityValue("\(readiness.preparedRequiredMaterialCount) of \(readiness.requiredMaterialCount) required, \(readiness.preparedOptionalMaterialCount) of \(readiness.optionalMaterialCount) optional")

                ForEach(vidhi.materials) { material in
                    Button {
                        ritualSessionStore.toggleMaterial(material.id, for: vidhi)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: preparedMaterialIDs.contains(material.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(preparedMaterialIDs.contains(material.id) ? theme.primary : theme.semanticTertiaryText)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(material.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(theme.semanticPrimaryText)
                                    if material.isRequired {
                                        Text("REQUIRED")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Text(material.purpose)
                                    .font(.caption)
                                    .foregroundStyle(theme.semanticSecondaryText)
                                if let alternative = material.alternative {
                                    Text("Alternative: \(alternative)")
                                        .font(.caption2)
                                        .foregroundStyle(theme.semanticTertiaryText)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(material.name)
                    .accessibilityValue(preparedMaterialIDs.contains(material.id) ? "Prepared" : "Not prepared")
                    .accessibilityHint("Toggles the preparation checklist")

                    if material.id != vidhi.materials.last?.id {
                        Divider().overlay(theme.semanticDivider)
                    }
                }
            }
        }
    }

    private var stepsSection: some View {
        PoojaSectionCard(title: "Pooja sequence", symbol: "list.number") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(vidhi.steps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.number)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.selectedControlForeground)
                            .frame(width: 28, height: 28)
                            .background(theme.primary, in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(step.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.semanticPrimaryText)
                                Spacer()
                                Text("~\(step.estimatedMinutes)m")
                                    .font(.caption2)
                                    .foregroundStyle(theme.semanticTertiaryText)
                            }
                            Text(step.instruction)
                                .font(.caption)
                                .foregroundStyle(theme.semanticSecondaryText)
                                .lineLimit(3)
                            if let mantra = step.mantra {
                                Label(mantra.transliteration, systemImage: "text.quote")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(theme.primary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var safetySection: some View {
        PoojaSectionCard(title: "Safety and respectful closure", symbol: "shield.lefthalf.filled") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(vidhi.safetyNotes, id: \.self) { note in
                    Label {
                        Text(note)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                }

                Divider().overlay(theme.semanticDivider)

                ForEach(vidhi.completion, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(theme.semanticSecondaryText)
                        .labelStyle(PoojaTopAlignedLabelStyle(color: theme.primary))
                }
            }
        }
    }

    private var sourcesSection: some View {
        PoojaSectionCard(title: "Tradition and sources", symbol: "books.vertical.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text(PoojaContentPolicy.mantraScope)
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)

                Text(PoojaContentPolicy.inclusionScope)
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)

                Label(PoojaContentPolicy.reviewStatus, systemImage: "person.badge.clock.fill")
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .labelStyle(PoojaTopAlignedLabelStyle(color: .orange))

                ForEach(vidhi.sourceNotes) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        if let url = URL(string: source.urlString) {
                            Link(destination: url) {
                                HStack {
                                    Text(source.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(theme.primary)
                            }
                        } else {
                            Text(source.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.semanticPrimaryText)
                        }
                        Text(source.detail)
                            .font(.caption2)
                            .foregroundStyle(theme.semanticTertiaryText)
                    }
                }

                Text("Source review: \(PoojaContentPolicy.sourceReviewDate)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(theme.semanticTertiaryText)
            }
        }
    }
}

struct GuidedPoojaView: View {
    let vidhi: PoojaVidhi
    @Environment(\.cosmicTheme) private var theme
    @EnvironmentObject private var ritualSessionStore: RitualSessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var session: RitualSession { ritualSessionStore.session(for: vidhi) }
    private var currentStepIndex: Int { session.currentStepIndex }
    private var isComplete: Bool { session.status == .completed }

    private var currentStep: PoojaStep {
        vidhi.steps[currentStepIndex.clamped(to: 0...(vidhi.steps.count - 1))]
    }

    var body: some View {
        ZStack {
            RitualSanctuaryBackground()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        Color.clear.frame(height: 1).id("guidedPoojaTop")
                        progressHeader
                        if isComplete {
                            completionView
                        } else {
                            currentStepCard
                            if vidhi.practiceLevel == .priestRecommended {
                                priestBoundary
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 108)
                }
                .onChange(of: currentStepIndex) { _, _ in
                    if reduceMotion {
                        proxy.scrollTo("guidedPoojaTop", anchor: .top)
                    } else {
                        withAnimation(.snappy) { proxy.scrollTo("guidedPoojaTop", anchor: .top) }
                    }
                }
            }
        }
        .navigationTitle(isComplete ? "Pooja complete" : "Step \(currentStep.number) of \(vidhi.steps.count)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !isComplete { navigationControls }
        }
        .onAppear {
            if session.status != .inProgress {
                ritualSessionStore.begin(vidhi)
            }
        }
        .sensoryFeedback(.success, trigger: isComplete)
        .accessibilityIdentifier("pooja.guided.\(vidhi.id)")
    }

    private var progressHeader: some View {
        CosmicGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vidhi.title)
                            .font(.headline)
                            .foregroundStyle(theme.semanticPrimaryText)
                        Text(isComplete ? "Respectful closure" : currentStep.title)
                            .font(.caption)
                            .foregroundStyle(theme.semanticSecondaryText)
                    }
                    Spacer()
                    Text(isComplete ? "Done" : "\(currentStep.number)/\(vidhi.steps.count)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(theme.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Pooja progress. \(vidhi.title). \(isComplete ? "Respectful closure" : currentStep.title)")
                .accessibilityValue(isComplete ? "Complete" : "Step \(currentStep.number) of \(vidhi.steps.count)")
                ProgressView(value: isComplete ? 1 : Double(currentStep.number), total: Double(vidhi.steps.count))
                    .tint(theme.primary)
                    .accessibilityHidden(true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 7) {
                        guidedBoundaryLabel
                        Spacer(minLength: 6)
                        guidedSourceLabelView
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        guidedBoundaryLabel
                        guidedSourceLabelView
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.semanticSecondaryText)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var guidedSourceLabel: String {
        let noun = vidhi.sourceNotes.count == 1 ? "source" : "sources"
        return "\(vidhi.sourceNotes.count) \(noun)"
    }

    private var guidedBoundaryLabel: some View {
        Label(
            vidhi.practiceLevel == .priestRecommended ? "Practitioner-led boundary" : "Household adaptation",
            systemImage: vidhi.practiceLevel == .priestRecommended ? "person.badge.shield.checkmark.fill" : "house.fill"
        )
    }

    private var guidedSourceLabelView: some View {
        Label(guidedSourceLabel, systemImage: "books.vertical.fill")
    }

    private var currentStepCard: some View {
        CosmicGlassCard(cornerRadius: 26, accentBorder: true) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    Text("\(currentStep.number)")
                        .font(.title2.monospacedDigit().weight(.bold))
                        .foregroundStyle(theme.selectedControlForeground)
                        .frame(width: 48, height: 48)
                        .background(theme.primary, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentStep.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(theme.semanticPrimaryText)
                        Label("About \(currentStep.estimatedMinutes) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(theme.semanticSecondaryText)
                    }
                }

                Text(currentStep.instruction)
                    .font(.title3)
                    .foregroundStyle(theme.semanticPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let mantra = currentStep.mantra {
                    mantraCard(mantra)
                }

                if let note = currentStep.note {
                    Label {
                        Text(note)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .padding(12)
                    .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func mantraCard(_ mantra: PoojaMantra) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(mantra.title, systemImage: "text.quote")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.primary)
            Text(mantra.devanagari)
                .font(.title2.weight(.semibold))
                .foregroundStyle(theme.semanticPrimaryText)
                .textSelection(.enabled)
            Text(mantra.transliteration)
                .font(.body.italic())
                .foregroundStyle(theme.semanticPrimaryText)
                .textSelection(.enabled)
            Divider().overlay(theme.semanticDivider)
            Text(mantra.meaning)
                .font(.subheadline)
                .foregroundStyle(theme.semanticSecondaryText)
            Label(mantra.repetition, systemImage: "repeat")
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.semanticTertiaryText)
        }
        .padding(14)
        .background(theme.surfaceElevated.opacity(0.74), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mantra.title). \(mantra.transliteration). Meaning: \(mantra.meaning). \(mantra.repetition)")
    }

    private var priestBoundary: some View {
        CosmicGlassCard(cornerRadius: 18) {
            Label {
                Text("Pause whenever the guide reaches officiant-led mantras, homa, nyasa, kalasha installation, or formal visarjana. Follow the qualified priest or your received family procedure.")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
            .foregroundStyle(theme.semanticSecondaryText)
        }
    }

    private var navigationControls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    nextButton
                    previousButton
                }
            } else {
                HStack(spacing: 12) {
                    previousButton
                    nextButton
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var previousButton: some View {
        Button {
            ritualSessionStore.previousStep(in: vidhi)
        } label: {
            Label("Previous", systemImage: "chevron.left")
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
        }
        .buttonStyle(.glass)
        .disabled(currentStepIndex == 0)
    }

    private var nextButton: some View {
        Button {
            ritualSessionStore.advance(in: vidhi)
        } label: {
            Label(
                currentStepIndex == vidhi.steps.count - 1 ? "Complete" : "Next",
                systemImage: currentStepIndex == vidhi.steps.count - 1 ? "checkmark" : "chevron.right"
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
        }
        .buttonStyle(.glassProminent)
        .tint(theme.primary)
        .foregroundStyle(theme.selectedControlForeground)
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            CosmicGlassCard(cornerRadius: 26, accentBorder: true) {
                VStack(spacing: 16) {
                    Image(systemName: "hands.and.sparkles.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Text("Pooja complete")
                        .font(.title.bold())
                        .foregroundStyle(theme.semanticPrimaryText)
                    Text("Sit quietly before clearing the space. Let the intention continue through thoughtful action.")
                        .font(.body)
                        .foregroundStyle(theme.semanticSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            PoojaSectionCard(title: "Close respectfully", symbol: "checkmark.seal.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vidhi.completion, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(theme.semanticSecondaryText)
                            .labelStyle(PoojaTopAlignedLabelStyle(color: theme.primary))
                    }
                }
            }

            Button {
                ritualSessionStore.restartGuidedPractice(vidhi)
            } label: {
                Label("Review from the beginning", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
            }
            .buttonStyle(.glass)
        }
    }
}

private struct PoojaSectionCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    init(title: String, symbol: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content
    }

    var body: some View {
        CosmicGlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                CosmicSectionHeader(title: title, icon: symbol)
                content()
            }
        }
    }
}

private struct PoojaMetadataPill: View {
    let text: String
    let symbol: String
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption2.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(theme.semanticSecondaryText)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(theme.surfaceElevated.opacity(0.74), in: Capsule())
    }
}

private struct PoojaNumberedLine: View {
    let number: Int
    let text: String
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(theme.primary)
                .frame(width: 22, height: 22)
                .background(theme.primary.opacity(0.12), in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(theme.semanticSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PoojaTopAlignedLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 9) {
            configuration.icon
                .foregroundStyle(color)
                .padding(.top, 1)
            configuration.title
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension PoojaCategory {
    var accent: Color {
        switch self {
        case .daily: return .yellow
        case .deity: return .orange
        case .festival: return .pink
        case .vrata: return .purple
        case .lifeEvent: return .teal
        case .planetary: return .indigo
        }
    }
}

#Preview("Pooja library") {
    NavigationStack {
        ZStack {
            RitualSanctuaryBackground()
            PoojaVidhiLibraryView()
        }
        .navigationTitle("Pooja")
    }
    .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
    .environmentObject(RitualSessionStore(defaults: nil))
    .preferredColorScheme(.dark)
}

#Preview("Lakshmi Vidhi") {
    NavigationStack {
        PoojaVidhiDetailView(vidhi: PoojaVidhiCatalog.all[2])
    }
    .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
    .environmentObject(RitualSessionStore(defaults: nil))
    .preferredColorScheme(.dark)
}

#Preview("Guided Pooja") {
    NavigationStack {
        GuidedPoojaView(vidhi: PoojaVidhiCatalog.all[1])
    }
    .environment(\.cosmicTheme, CosmicColorScheme.cloudDancer)
    .environmentObject(RitualSessionStore(defaults: nil))
    .preferredColorScheme(.light)
}
