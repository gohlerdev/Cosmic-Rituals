import Combine
import Foundation

enum RitualLocationSource: String, Codable, Sendable {
    case defaultCity
    case manual
    case savedCurrent
    case current
}

struct RitualLocation: Identifiable, Codable, Hashable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let source: RitualLocationSource

    var id: String {
        "\(name)|\(latitude)|\(longitude)|\(timeZoneIdentifier)|\(source.rawValue)"
    }

    var sourceDescription: String {
        switch source {
        case .defaultCity: return "Default offline city"
        case .manual: return "Offline city"
        case .savedCurrent: return "Saved last GPS coordinate"
        case .current: return "Current location"
        }
    }

    func withSource(_ source: RitualLocationSource) -> RitualLocation {
        RitualLocation(
            name: name,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneIdentifier,
            source: source
        )
    }

    func asSavedCurrent() -> RitualLocation {
        RitualLocation(
            name: "Last Known Location",
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneIdentifier,
            source: .savedCurrent
        )
    }
}

/// Complete offline GeoNames `cities15000` catalog shared with Cosmic Astrology.
///
/// The bundled TSV is population-sorted. Search preserves that order inside each
/// relevance tier and caps results so the SwiftUI list remains responsive.
enum WorldCityCatalog {
    static let resultLimit = 40
    static let expectedCatalogCount = 33_909
    static let attribution = "City data © GeoNames, licensed under CC BY 4.0"

    static let newDelhi = RitualLocation(
        name: "New Delhi, India",
        latitude: 28.6139,
        longitude: 77.2090,
        timeZoneIdentifier: "Asia/Kolkata",
        source: .defaultCity
    )

    /// An intentionally small, immediately available list shown before a search.
    /// Full search always uses the bundled 33,909-row catalog.
    static let popularCities: [RitualLocation] = [
        newDelhi.withSource(.manual),
        RitualLocation(name: "Tokyo, Japan", latitude: 35.6895, longitude: 139.6917, timeZoneIdentifier: "Asia/Tokyo", source: .manual),
        RitualLocation(name: "London, United Kingdom", latitude: 51.5085, longitude: -0.1257, timeZoneIdentifier: "Europe/London", source: .manual),
        RitualLocation(name: "New York City, United States", latitude: 40.7143, longitude: -74.0060, timeZoneIdentifier: "America/New_York", source: .manual),
        RitualLocation(name: "Los Angeles, United States", latitude: 34.0522, longitude: -118.2437, timeZoneIdentifier: "America/Los_Angeles", source: .manual),
        RitualLocation(name: "Nairobi, Kenya", latitude: -1.2833, longitude: 36.8167, timeZoneIdentifier: "Africa/Nairobi", source: .manual),
        RitualLocation(name: "Sao Paulo, Brazil", latitude: -23.5475, longitude: -46.6361, timeZoneIdentifier: "America/Sao_Paulo", source: .manual),
        RitualLocation(name: "Sydney, Australia", latitude: -33.8678, longitude: 151.2073, timeZoneIdentifier: "Australia/Sydney", source: .manual),
    ]

    static func resourceURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: "world_cities", withExtension: "tsv")
    }

    static func load(in bundle: Bundle = .main) throws -> [RitualLocation] {
        guard let url = resourceURL(in: bundle) else {
            throw WorldCityCatalogError.resourceMissing
        }
        return try load(from: url)
    }

    static func load(from url: URL) throws -> [RitualLocation] {
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw WorldCityCatalogError.unreadableResource
        }

        let cities = parse(tsv: text)
        guard !cities.isEmpty else { throw WorldCityCatalogError.emptyCatalog }
        return cities
    }

    static func parse(tsv: String) -> [RitualLocation] {
        tsv.split(whereSeparator: \.isNewline).compactMap { row in
            let columns = row.split(separator: "\t", omittingEmptySubsequences: false)
            guard columns.count == 5,
                  let latitude = Double(columns[1]),
                  let longitude = Double(columns[2]),
                  (-90...90).contains(latitude),
                  (-180...180).contains(longitude),
                  TimeZone(identifier: String(columns[3])) != nil else {
                return nil
            }

            return RitualLocation(
                name: "\(columns[0]), \(columns[4])",
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: String(columns[3]),
                source: .manual
            )
        }
    }

    /// Normalized names and their word splits, computed once when the catalog loads.
    ///
    /// Folding 33,909 names is what a keystroke actually costs: the query itself is one
    /// string, the corpus is the whole catalog. Hoisting that work out of the loop turns
    /// each search into prefix and substring comparisons over prepared keys.
    struct SearchIndex: Sendable {
        let cities: [RitualLocation]
        fileprivate let keys: [String]
        fileprivate let words: [[Substring]]

        var count: Int { cities.count }

        init(_ cities: [RitualLocation]) {
            self.cities = cities
            var keys: [String] = []
            var words: [[Substring]] = []
            keys.reserveCapacity(cities.count)
            words.reserveCapacity(cities.count)
            for city in cities {
                let key = WorldCityCatalog.normalized(city.name)
                words.append(key.split(whereSeparator: { !$0.isLetter && !$0.isNumber }))
                keys.append(key)
            }
            self.keys = keys
            self.words = words
        }
    }

    static func search(
        _ rawQuery: String,
        in index: SearchIndex,
        limit: Int = resultLimit
    ) -> [RitualLocation] {
        let query = normalized(rawQuery)
        guard query.count >= 2, limit > 0 else { return [] }

        var directPrefix: [RitualLocation] = []
        var wordPrefix: [RitualLocation] = []
        var contains: [RitualLocation] = []

        for i in index.cities.indices {
            let key = index.keys[i]
            if key.hasPrefix(query) {
                if directPrefix.count < limit { directPrefix.append(index.cities[i]) }
                // Direct prefix matches are returned ahead of every other bucket, so once
                // they fill the limit nothing later in the catalog can change the result.
                if directPrefix.count >= limit { break }
            } else if index.words[i].contains(where: { $0.hasPrefix(query) }) {
                if wordPrefix.count < limit { wordPrefix.append(index.cities[i]) }
            } else if key.contains(query), contains.count < limit {
                contains.append(index.cities[i])
            }
        }

        return Array((directPrefix + wordPrefix + contains).prefix(limit))
    }

    /// Convenience for callers holding a plain array. Builds the index on every call, so
    /// anything searching repeatedly - the location picker above all - should keep a
    /// `SearchIndex` instead.
    static func search(
        _ rawQuery: String,
        in cities: [RitualLocation],
        limit: Int = resultLimit
    ) -> [RitualLocation] {
        search(rawQuery, in: SearchIndex(cities), limit: limit)
    }

    static func normalized(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum WorldCityCatalogError: LocalizedError {
    case resourceMissing
    case unreadableResource
    case emptyCatalog

    var errorDescription: String? {
        switch self {
        case .resourceMissing:
            return "The offline city catalog is missing from this app build."
        case .unreadableResource:
            return "The offline city catalog could not be read."
        case .emptyCatalog:
            return "The offline city catalog contains no valid locations."
        }
    }
}

enum WorldCityCatalogLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

private enum WorldCityCatalogLoadResult: Sendable {
    case success([RitualLocation])
    case failure(String)
}

/// Loads and parses the large catalog only when the picker is opened. File I/O,
/// parsing, and search all execute away from the main actor.
@MainActor
final class WorldCityCatalogModel: ObservableObject {
    @Published private(set) var state: WorldCityCatalogLoadState = .idle
    @Published private(set) var results = WorldCityCatalog.popularCities
    @Published private(set) var catalogCount = 0

    private let resourceURL: URL?
    private var cities: [RitualLocation] = []
    private var currentQuery = ""
    private var loadTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    init(resourceURL: URL? = WorldCityCatalog.resourceURL()) {
        self.resourceURL = resourceURL
    }

    func loadIfNeeded() {
        guard state == .idle else { return }
        load()
    }

    func retry() {
        loadTask?.cancel()
        state = .idle
        load()
    }

    func updateQuery(_ query: String) {
        currentQuery = query
        guard state == .loaded else { return }
        scheduleSearch(for: query)
    }

    /// Built once per catalog load. Nil until the catalog is available.
    private var searchIndex: WorldCityCatalog.SearchIndex?

    private func load() {
        state = .loading
        guard let resourceURL else {
            state = .failed(WorldCityCatalogError.resourceMissing.localizedDescription)
            return
        }

        loadTask = Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                do {
                    return WorldCityCatalogLoadResult.success(
                        try WorldCityCatalog.load(from: resourceURL)
                    )
                } catch {
                    return WorldCityCatalogLoadResult.failure(error.localizedDescription)
                }
            }.value

            guard let self, !Task.isCancelled else { return }
            switch result {
            case .success(let loadedCities):
                cities = loadedCities
                searchIndex = WorldCityCatalog.SearchIndex(loadedCities)
                catalogCount = loadedCities.count
                state = .loaded
                scheduleSearch(for: currentQuery)
            case .failure(let message):
                cities = []
                searchIndex = nil
                catalogCount = 0
                results = []
                state = .failed(message)
            }
        }
    }

    private func scheduleSearch(for rawQuery: String) {
        searchTask?.cancel()
        let normalizedQuery = WorldCityCatalog.normalized(rawQuery)

        guard !normalizedQuery.isEmpty else {
            results = WorldCityCatalog.popularCities
            return
        }
        guard normalizedQuery.count >= 2 else {
            results = []
            return
        }

        // Search the prepared index, not the raw array: the whole point of building it at
        // load time is that a keystroke must not re-fold the catalog.
        let index = searchIndex
        searchTask = Task { [weak self] in
            let matches = await Task.detached(priority: .userInitiated) {
                index.map { WorldCityCatalog.search(rawQuery, in: $0) } ?? []
            }.value

            guard let self,
                  !Task.isCancelled,
                  WorldCityCatalog.normalized(currentQuery) == normalizedQuery else { return }
            results = matches
        }
    }
}

enum RitualLocationStore {
    private static let key = "ritualActiveLocation.v2"

    static func load(defaults: UserDefaults = .standard) -> RitualLocation? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(RitualLocation.self, from: data)
    }

    static func save(_ location: RitualLocation, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(location) else { return }
        defaults.set(data, forKey: key)
    }
}
