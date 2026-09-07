import SwiftUI

enum RitualResponsiveLayout {
    static func usesIconOnlyDestinations(for dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    static func locationMetadataLines(
        sourceDescription: String,
        timeZoneIdentifier: String,
        for dynamicTypeSize: DynamicTypeSize
    ) -> [String] {
        if dynamicTypeSize.isAccessibilitySize {
            return [sourceDescription, timeZoneIdentifier]
        }
        return ["\(sourceDescription) · \(timeZoneIdentifier)"]
    }
}

struct LocationContextBar: View {
    @ObservedObject var manager: LocationManager
    let action: () -> Void
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var metadataLines: [String] {
        RitualResponsiveLayout.locationMetadataLines(
            sourceDescription: manager.activeLocation.sourceDescription,
            timeZoneIdentifier: manager.activeLocation.timeZoneIdentifier,
            for: dynamicTypeSize
        )
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: manager.activeLocation.source == .current ? "location.fill" : "mappin.and.ellipse")
                    .foregroundStyle(theme.primary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(manager.activeLocation.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.semanticPrimaryText)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    ForEach(Array(metadataLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(theme.semanticSecondaryText)
                            .lineLimit(index == metadataLines.count - 1 ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.semanticSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(theme.surface.opacity(theme.isLight ? 0.96 : 0.88))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.semanticDivider)
                    .frame(height: 0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .accessibilityLabel("Calculation location")
        .accessibilityValue(
            "\(manager.activeLocation.name), \(manager.activeLocation.sourceDescription), \(manager.activeLocation.timeZoneIdentifier)"
        )
        .accessibilityHint("Choose current location or an offline city")
    }
}

struct RitualLocationPicker: View {
    @ObservedObject var manager: LocationManager
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @StateObject private var catalog = WorldCityCatalogModel()

    private var normalizedQuery: String { WorldCityCatalog.normalized(query) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        manager.requestLocation()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                    .disabled(manager.state == .requesting)

                    if manager.state == .denied || manager.state == .restricted {
                        Button("Open Location Settings") { manager.openSystemSettings() }
                    }

                    LabeledContent("Active") {
                        Text(manager.activeLocation.name)
                            .multilineTextAlignment(.trailing)
                    }
                    Text(manager.state.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Location Source")
                } footer: {
                    Text("Current Location uses the device time zone. Offline cities include their own time zone and work without a network connection.")
                }

                Section {
                    offlineCatalogContent
                } header: {
                    Text(query.isEmpty ? "Popular Offline Cities" : "Offline City Results")
                } footer: {
                    if case .loaded = catalog.state {
                        Text("\(catalog.catalogCount.formatted()) cities stored on this device · up to \(WorldCityCatalog.resultLimit) results")
                    }
                }

                Section("Data Attribution") {
                    Text(WorldCityCatalog.attribution)
                        .font(.footnote)
                    Link("GeoNames", destination: URL(string: "https://www.geonames.org/")!)
                    Link("Creative Commons Attribution 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                }
            }
            .searchable(text: $query, prompt: "Search offline cities")
            .onChange(of: query, initial: true) { _, newQuery in
                catalog.updateQuery(newQuery)
            }
            .task {
                catalog.loadIfNeeded()
            }
            .navigationTitle("Calculation Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var offlineCatalogContent: some View {
        switch catalog.state {
        case .idle, .loading:
            HStack(spacing: 12) {
                ProgressView()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Loading Offline Catalog")
                    Text("Preparing about 34,000 cities…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

        case .failed(let message):
            ContentUnavailableView {
                Label("Catalog Unavailable", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { catalog.retry() }
            }

        case .loaded where normalizedQuery.count == 1:
            ContentUnavailableView(
                "Keep Typing",
                systemImage: "text.magnifyingglass",
                description: Text("Enter at least two letters to search the complete offline catalog.")
            )

        case .loaded where !normalizedQuery.isEmpty && catalog.results.isEmpty:
            ContentUnavailableView(
                "No City Found",
                systemImage: "mappin.slash",
                description: Text("Check the spelling or try a nearby city. The active location has not changed.")
            )

        case .loaded:
            ForEach(catalog.results) { city in
                Button {
                    manager.select(city)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .foregroundStyle(.primary)
                            Text(city.timeZoneIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if city.id == manager.activeLocation.withSource(.manual).id,
                           manager.activeLocation.source != .current {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityHint("Use this city for all Panchang calculations")
            }
        }
    }
}

struct SolarScheduleUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Solar Schedule Unavailable",
            systemImage: "sun.horizon.fill",
            description: Text("This latitude and date has no usable sunrise/sunset pair. Cosmic Rituals does not invent substitute times.")
        )
        .accessibilityElement(children: .combine)
    }
}
