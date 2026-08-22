import XCTest
@testable import CosmicRituals

/// Performance evidence for `NEXT_LEVEL_PLAN.md` Phase 0, which asks for recorded
/// calculation latency, monthly-calendar latency, PDF creation time, and offline-city
/// search latency rather than an impression that the app "feels fast".
///
/// No baselines are committed. These record numbers on the machine that runs them;
/// a baseline should only be set once a reference device is agreed, otherwise the
/// suite becomes machine-dependent and starts failing for reasons unrelated to the code.
final class PerformanceTests: XCTestCase {

    private static let catalog: [RitualLocation] = (try? WorldCityCatalog.load()) ?? []

    private var delhi: CalculationContext {
        context(2026, 8, 21, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
    }

    // MARK: - Daily calculation

    func testDailyPanchangCalculationLatency() {
        let target = delhi
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = CosmicEngine.getPanchang(context: target)
        }
    }

    /// The full daily surface is more than the five limbs: it is the snapshot plus every
    /// sunrise-derived schedule the Timing and Muhurtas screens read.
    func testFullDailySurfaceCalculationLatency() {
        let target = delhi
        measure(metrics: [XCTClockMetric()]) {
            _ = CosmicEngine.getPanchang(context: target)
            _ = CosmicEngine.getMuhurtas(context: target)
            _ = CosmicEngine.getChoghadiya(context: target)
            _ = CosmicEngine.getHora(context: target)
            _ = CosmicEngine.getRahuKala(context: target)
            _ = CosmicEngine.getYamaganda(context: target)
            _ = CosmicEngine.getGulikaKala(context: target)
            _ = CosmicEngine.getAbhijitMuhurta(context: target)
            _ = CosmicEngine.getBrahmaMuhurta(context: target)
            _ = CosmicEngine.getDurMuhurta(context: target)
        }
    }

    // MARK: - Monthly calendar

    /// The monthly grid deliberately skips per-day boundary solving. This records what a
    /// whole month of compact cells costs, which is the number that governs the Calendar
    /// screen's responsiveness.
    func testMonthlyCalendarLatencyForThirtyOneCompactCells() {
        let start = delhi
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for offset in 0..<31 {
                _ = CosmicEngine.getPanchang(
                    context: start.advancedByLocalDays(offset),
                    includeTransitions: false
                )
            }
        }
    }

    // MARK: - Export

    func testPanchangPDFCreationTime() {
        let target = delhi
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = PanchangPDFExporter.generatePDF(context: target)
        }
    }

    // MARK: - Offline city search

    func testOfflineCityCatalogLoadTime() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? WorldCityCatalog.load()
        }
    }

    func testOfflineCitySearchLatency() throws {
        let cities = Self.catalog
        try XCTSkipIf(cities.isEmpty, "City catalog unavailable in this bundle")

        // A short prefix is the worst realistic case: it matches many rows before ranking.
        measure(metrics: [XCTClockMetric()]) {
            _ = WorldCityCatalog.search("de", in: cities)
            _ = WorldCityCatalog.search("new", in: cities)
            _ = WorldCityCatalog.search("hyder", in: cities)
        }
    }

    func testOfflineCityCatalogIsLargeEnoughForTheSearchToBeMeaningful() throws {
        try XCTSkipIf(Self.catalog.isEmpty, "City catalog unavailable in this bundle")
        XCTAssertGreaterThan(
            Self.catalog.count,
            30_000,
            "Search latency is only meaningful against the full offline catalog"
        )
    }

    // MARK: - Helpers

    private func context(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        latitude: Double,
        longitude: Double,
        timeZone: String
    ) -> CalculationContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone) ?? .gmt
        let localDay = calendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        ) ?? Date(timeIntervalSince1970: 0)
        return CalculationContext(
            localDay: localDay,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone
        )
    }
}
