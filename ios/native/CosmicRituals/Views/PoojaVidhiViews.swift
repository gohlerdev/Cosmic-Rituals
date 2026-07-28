import SwiftUI

struct PoojaVidhiLibraryView: View {
    @State private var query = ""
    @State private var selectedCategory: PoojaCategory?
    @Environment(\.cosmicTheme) private var theme

    private var results: [PoojaVidhi] {
        PoojaVidhiCatalog.search(query, category: selectedCategory)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                libraryHeader
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

                Text(PoojaContentPolicy.householdScope)
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pooja Vidhis. Twelve offline household and preparation guides. Family and temple tradition takes precedence.")
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
    @State private var preparedMaterialIDs: Set<String> = []
    @Environment(\.cosmicTheme) private var theme

    private var preparationProgress: Double {
        guard !vidhi.materials.isEmpty else { return 0 }
        return Double(preparedMaterialIDs.count) / Double(vidhi.materials.count)
    }

    var body: some View {
        ZStack {
            CosmicStarfieldBackground()
            ScrollView {
                LazyVStack(spacing: 16) {
                    hero
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
                    vidhi.practiceLevel == .priestRecommended ? "Open ceremony guide" : "Begin guided Pooja",
                    systemImage: "play.fill"
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
                    .accessibilityLabel("Materials prepared")
                    .accessibilityValue("\(preparedMaterialIDs.count) of \(vidhi.materials.count)")

                ForEach(vidhi.materials) { material in
                    Button {
                        if preparedMaterialIDs.contains(material.id) {
                            preparedMaterialIDs.remove(material.id)
                        } else {
                            preparedMaterialIDs.insert(material.id)
                        }
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
                                            .font(.system(size: 9, weight: .bold))
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
    @State private var currentStepIndex = 0
    @State private var isComplete = false
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var currentStep: PoojaStep {
        vidhi.steps[currentStepIndex.clamped(to: 0...(vidhi.steps.count - 1))]
    }

    var body: some View {
        ZStack {
            CosmicStarfieldBackground()
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
                ProgressView(value: isComplete ? 1 : Double(currentStep.number), total: Double(vidhi.steps.count))
                    .tint(theme.primary)
                    .accessibilityLabel("Pooja progress")
                    .accessibilityValue(isComplete ? "Complete" : "Step \(currentStep.number) of \(vidhi.steps.count)")
            }
        }
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
            currentStepIndex = max(0, currentStepIndex - 1)
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
            if currentStepIndex == vidhi.steps.count - 1 {
                isComplete = true
            } else {
                currentStepIndex += 1
            }
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
                currentStepIndex = 0
                isComplete = false
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
            CosmicStarfieldBackground()
            PoojaVidhiLibraryView()
        }
        .navigationTitle("Pooja")
    }
    .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
    .preferredColorScheme(.dark)
}

#Preview("Lakshmi Vidhi") {
    NavigationStack {
        PoojaVidhiDetailView(vidhi: PoojaVidhiCatalog.all[2])
    }
    .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
    .preferredColorScheme(.dark)
}

#Preview("Guided Pooja") {
    NavigationStack {
        GuidedPoojaView(vidhi: PoojaVidhiCatalog.all[1])
    }
    .environment(\.cosmicTheme, CosmicColorScheme.cloudDancer)
    .preferredColorScheme(.light)
}
