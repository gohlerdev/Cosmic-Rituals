import Foundation
import CoreLocation
import SwiftUI
import UIKit
import XCTest
@testable import CosmicRituals

final class CosmicEngineTests: XCTestCase {
    private static let loadedCatalog = Result { try WorldCityCatalog.load() }

    private struct SolarFixture {
        let name: String
        let latitude: Double
        let longitude: Double
        let timeZone: String
        let year: Int
        let month: Int
        let day: Int
        let expectedSunriseMinute: Int
        let expectedSunsetMinute: Int
        let toleranceMinutes: Int
    }

    /// Independent published civil-time fixtures. Sources are recorded beside the
    /// values so a future ephemeris change cannot simply update implementation and
    /// expectation together.
    private let solarFixtures: [SolarFixture] = [
        // timeanddate.com New Delhi, July 2026: 05:38 / 19:17.
        SolarFixture(name: "New Delhi", latitude: 28.6139, longitude: 77.2090,
                     timeZone: "Asia/Kolkata", year: 2026, month: 7, day: 24,
                     expectedSunriseMinute: 338, expectedSunsetMinute: 1_157, toleranceMinutes: 10),
        // National Astronomical Observatory of Japan: 04:43 / 18:52.
        SolarFixture(name: "Tokyo", latitude: 35.6762, longitude: 139.6503,
                     timeZone: "Asia/Tokyo", year: 2026, month: 7, day: 24,
                     expectedSunriseMinute: 283, expectedSunsetMinute: 1_132, toleranceMinutes: 10),
        // Griffith Observatory 2026 table, America/Los_Angeles with DST.
        SolarFixture(name: "Los Angeles", latitude: 34.0522, longitude: -118.2437,
                     timeZone: "America/Los_Angeles", year: 2026, month: 7, day: 24,
                     expectedSunriseMinute: 358, expectedSunsetMinute: 1_201, toleranceMinutes: 12),
        // timeanddate.com New York, March 2026; DST begins on this civil day.
        SolarFixture(name: "New York DST", latitude: 40.7128, longitude: -74.0060,
                     timeZone: "America/New_York", year: 2026, month: 3, day: 8,
                     expectedSunriseMinute: 438, expectedSunsetMinute: 1_135, toleranceMinutes: 12),
    ]

    func testPublishedSolarFixturesStayOnSelectedLocalDay() throws {
        for fixture in solarFixtures {
            let context = context(
                fixture.year, fixture.month, fixture.day,
                latitude: fixture.latitude,
                longitude: fixture.longitude,
                timeZone: fixture.timeZone
            )
            let result = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: context), fixture.name)
            let calendar = context.calendar

            XCTAssertTrue(calendar.isDate(result.sunrise, inSameDayAs: context.localDay), fixture.name)
            XCTAssertTrue(calendar.isDate(result.sunset, inSameDayAs: context.localDay), fixture.name)

            let rise = calendar.dateComponents([.hour, .minute], from: result.sunrise)
            let set = calendar.dateComponents([.hour, .minute], from: result.sunset)
            let riseMinute = (rise.hour ?? 0) * 60 + (rise.minute ?? 0)
            let setMinute = (set.hour ?? 0) * 60 + (set.minute ?? 0)
            XCTAssertLessThanOrEqual(abs(riseMinute - fixture.expectedSunriseMinute), fixture.toleranceMinutes, fixture.name)
            XCTAssertLessThanOrEqual(abs(setMinute - fixture.expectedSunsetMinute), fixture.toleranceMinutes, fixture.name)
        }
    }

    func testTokyoNegativeUTCHourMapsToPreviousUTCDateButCorrectLocalDay() throws {
        let context = context(2026, 7, 24, latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo")
        let sunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: context)?.sunrise)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        XCTAssertEqual(utc.component(.day, from: sunrise), 23)
        XCTAssertEqual(context.calendar.component(.day, from: sunrise), 24)
        XCTAssertEqual(context.calendar.component(.hour, from: sunrise), 4)
    }

    func testDSTContextAdvancesByCivilDay() {
        let march7 = context(2026, 3, 7, latitude: 40.7128, longitude: -74.0060, timeZone: "America/New_York")
        let march8 = march7.advancedByLocalDays(1)
        let march9 = march8.advancedByLocalDays(1)

        XCTAssertEqual(march8.localDayComponents.day, 8)
        XCTAssertEqual(march9.localDayComponents.day, 9)
        XCTAssertEqual(march7.timeZone.secondsFromGMT(for: march7.localNoon), -18_000)
        XCTAssertEqual(march8.timeZone.secondsFromGMT(for: march8.localNoon), -14_400)
    }

    func testPolarDayNeverFabricatesSchedules() {
        let svalbard = context(2026, 6, 21, latitude: 78.2232, longitude: 15.6469, timeZone: "Arctic/Longyearbyen")

        XCTAssertNil(CosmicEngine.getSunriseSunset(context: svalbard))
        XCTAssertTrue(CosmicEngine.getMuhurtas(context: svalbard).isEmpty)
        XCTAssertTrue(CosmicEngine.getChoghadiya(context: svalbard).isEmpty)
        XCTAssertTrue(CosmicEngine.getHora(context: svalbard).isEmpty)
        XCTAssertTrue(CosmicEngine.getDurMuhurta(context: svalbard).isEmpty)
    }

    func testKaranaSequenceHasOneOpeningFixedKaranaAndThreeClosingFixedKaranas() {
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 0), 10)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 1), 0)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 2), 1)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 7), 6)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 8), 0)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 56), 6)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 57), 7)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 58), 8)
        XCTAssertEqual(CosmicEngine.karanaIndex(forHalfTithiIndex: 59), 9)
    }

    func testLahiriAyanamshaMatchesSwissEphemerisReference() {
        // Swiss Ephemeris: 2020-01-01 12:00 TT = 24°08′11.3962″.
        let expected = 24.0 + 8.0 / 60.0 + 11.3962 / 3_600.0
        XCTAssertEqual(CosmicEngine.lahiriAyanamsha(year: 2020), expected, accuracy: 0.0001)
    }

    func testMeeusChapter47MoonLongitudeFixture() {
        // Meeus example 47.a, 1992-04-12 0h TD: mean geocentric
        // ecliptic longitude 133.162655°. The apparent value includes nutation
        // and is intentionally not mixed into this Table 47.A implementation.
        XCTAssertEqual(CosmicEngine.moonLongitude(jd: 2_448_724.5), 133.162655, accuracy: 0.000_02)
    }

    func testNakshatraAndPadaBoundariesDoNotDrift() {
        let nakshatraSpan = 360.0 / 27.0
        let padaSpan = 360.0 / 108.0
        let epsilon = 0.000_001

        XCTAssertEqual(CosmicEngine.getNakshatraPada(360 - epsilon).nakshatraIndex, 26)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(nakshatraSpan - epsilon).nakshatraIndex, 0)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(nakshatraSpan + epsilon).nakshatraIndex, 1)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(padaSpan - epsilon).pada, 1)
        XCTAssertEqual(CosmicEngine.getNakshatraPada(padaSpan + epsilon).pada, 2)
    }

    func testLocalContextProducesThirtyOrderedMuhurtas() throws {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let muhurtas = CosmicEngine.getMuhurtas(context: delhi)
        XCTAssertEqual(muhurtas.count, 30)
        XCTAssertTrue(zip(muhurtas, muhurtas.dropFirst()).allSatisfy {
            abs($0.endTime.timeIntervalSince($1.startTime)) < 0.001
        })
        let sunrise = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: delhi)?.sunrise)
        XCTAssertEqual(muhurtas.first?.startTime, sunrise)
    }

    func testPanchangUsesContextWeekday() {
        let tokyo = context(2026, 7, 24, latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo")
        XCTAssertEqual(CosmicEngine.getPanchang(context: tokyo).weekdayName, "Friday")
    }

    func testCompleteOfflineCatalogCountAndGlobalSearch() throws {
        let cities = try Self.loadedCatalog.get()
        XCTAssertEqual(cities.count, WorldCityCatalog.expectedCatalogCount)

        let expectations = [
            "Reykjavik": "Reykjavik, Iceland",
            "Reykjavík": "Reykjavik, Iceland",
            "Sao": "Sao Paulo, Brazil",
            "São": "Sao Paulo, Brazil",
            "Tokyo": "Tokyo, Japan",
            "Nairobi": "Nairobi, Kenya",
        ]
        for (query, expectedFirst) in expectations {
            XCTAssertEqual(
                WorldCityCatalog.search(query, in: cities).first?.name,
                expectedFirst,
                query
            )
        }
    }

    func testOfflineCatalogSearchRanksPrefixesAndCapsResults() throws {
        let sample = [
            RitualLocation(name: "Port Tokyo, Test", latitude: 0, longitude: 0, timeZoneIdentifier: "Etc/UTC", source: .manual),
            RitualLocation(name: "Oldtokyo, Test", latitude: 0, longitude: 0, timeZoneIdentifier: "Etc/UTC", source: .manual),
            RitualLocation(name: "Tokyo, Japan", latitude: 0, longitude: 0, timeZoneIdentifier: "Asia/Tokyo", source: .manual),
        ]
        XCTAssertEqual(
            WorldCityCatalog.search("tokyo", in: sample).map(\.name),
            ["Tokyo, Japan", "Port Tokyo, Test", "Oldtokyo, Test"]
        )

        let cities = try Self.loadedCatalog.get()
        let capped = WorldCityCatalog.search("san", in: cities)
        XCTAssertEqual(capped.count, WorldCityCatalog.resultLimit)
    }

    func testLocationStoreRoundTripsExplicitSource() throws {
        let suiteName = "CosmicRitualsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let tokyo = try XCTUnwrap(WorldCityCatalog.popularCities.first { $0.name == "Tokyo, Japan" })

        RitualLocationStore.save(tokyo, defaults: defaults)
        XCTAssertEqual(RitualLocationStore.load(defaults: defaults), tokyo)
    }

    func testAppIntentRequiresPersistedLocationInsteadOfDefaultingToDelhi() throws {
        let suiteName = "CosmicRitualsTests.Intent.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(IntentCalculationContext.resolve(for: Date(), defaults: defaults))

        let tokyo = try XCTUnwrap(WorldCityCatalog.popularCities.first { $0.name == "Tokyo, Japan" })
        RitualLocationStore.save(tokyo, defaults: defaults)
        let resolved = try XCTUnwrap(IntentCalculationContext.resolve(for: Date(), defaults: defaults))
        XCTAssertEqual(resolved.1, tokyo)
        XCTAssertEqual(resolved.0.timeZoneIdentifier, "Asia/Tokyo")
    }

    func testPersistedGPSCoordinateIsDowngradedUntilFreshFix() {
        let current = RitualLocation(
            name: "Current Location",
            latitude: 64.1355,
            longitude: -21.8954,
            timeZoneIdentifier: "Atlantic/Reykjavik",
            source: .current
        )
        let saved = current.asSavedCurrent()
        XCTAssertEqual(saved.source, .savedCurrent)
        XCTAssertEqual(saved.name, "Last Known Location")
        XCTAssertEqual(saved.latitude, current.latitude)
        XCTAssertEqual(saved.longitude, current.longitude)
    }

    func testGPSFixValidatorAcceptsFreshAuthorizedAccurateCoordinate() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedWhenInUse,
            coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            timestamp: now.addingTimeInterval(-30),
            horizontalAccuracy: 850,
            now: now
        ))
    }

    func testGPSFixValidatorRejectsRevokedAuthorization() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .denied,
            coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            timestamp: now,
            horizontalAccuracy: 50,
            now: now
        ))
    }

    func testGPSFixValidatorRejectsStaleAndFutureTimestamps() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let coordinate = CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)

        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedAlways,
            coordinate: coordinate,
            timestamp: now.addingTimeInterval(-(RitualGPSFixValidator.maximumAge + 1)),
            horizontalAccuracy: 50,
            now: now
        ))
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedAlways,
            coordinate: coordinate,
            timestamp: now.addingTimeInterval(RitualGPSFixValidator.maximumFutureClockSkew + 1),
            horizontalAccuracy: 50,
            now: now
        ))
    }

    func testGPSFixValidatorRejectsInvalidCoordinateAndAccuracy() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedWhenInUse,
            coordinate: CLLocationCoordinate2D(latitude: .nan, longitude: 77.2090),
            timestamp: now,
            horizontalAccuracy: 50,
            now: now
        ))
        XCTAssertNotNil(RitualGPSFixValidator.rejectionReason(
            authorizationStatus: .authorizedWhenInUse,
            coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            timestamp: now,
            horizontalAccuracy: RitualGPSFixValidator.maximumHorizontalAccuracy + 1,
            now: now
        ))
    }

    func testDailySnapshotNamingMatchesNoonReferenceSemantics() {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        XCTAssertEqual(delhi.calendar.component(.hour, from: delhi.localNoon), CalculationContext.dailySnapshotReferenceHour)
        XCTAssertEqual(RitualExperienceMode.ritualNow.displayName, "Daily Snapshot")
        XCTAssertTrue(RitualExperienceMode.ritualNow.summary.localizedCaseInsensitiveContains("noon"))
        XCTAssertTrue(CalculationContext.dailySnapshotDisclosure.localizedCaseInsensitiveContains("12:00 PM"))
    }

    func testAccessibilityLargeDestinationLayoutUsesIconsWithoutLosingLabels() {
        XCTAssertFalse(RitualResponsiveLayout.usesIconOnlyDestinations(for: .large))
        XCTAssertTrue(RitualResponsiveLayout.usesIconOnlyDestinations(for: .accessibility2))

        let titles = RitualDestinationDescriptor.all.map(\.title)
        XCTAssertEqual(titles, ["Panchang", "Timing", "Muhurtas", "Calendar"])
        XCTAssertEqual(Set(titles).count, 4)
        XCTAssertTrue(RitualDestinationDescriptor.all.allSatisfy { !$0.symbol.isEmpty })
    }

    func testAccessibilityLargeLocationMetadataKeepsFullTimeZone() {
        XCTAssertEqual(
            RitualResponsiveLayout.locationMetadataLines(
                sourceDescription: "Offline city",
                timeZoneIdentifier: "Atlantic/Reykjavik",
                for: .large
            ),
            ["Offline city · Atlantic/Reykjavik"]
        )
        XCTAssertEqual(
            RitualResponsiveLayout.locationMetadataLines(
                sourceDescription: "Offline city",
                timeZoneIdentifier: "Atlantic/Reykjavik",
                for: .accessibility2
            ),
            ["Offline city", "Atlantic/Reykjavik"]
        )
        XCTAssertEqual(
            RitualResponsiveLayout.locationMetadataLines(
                sourceDescription: "Saved last GPS coordinate",
                timeZoneIdentifier: "America/Argentina/Buenos_Aires",
                for: .accessibility5
            ).last,
            "America/Argentina/Buenos_Aires"
        )
    }

    func testDatePresentationUsesSelectedLocationTimeZone() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let instant = try XCTUnwrap(utc.date(from: DateComponents(
            year: 2026, month: 7, day: 23, hour: 20, minute: 30
        )))
        let locale = Locale(identifier: "en_US_POSIX")
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let losAngeles = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        XCTAssertEqual(instant.ritualDate(template: "d", in: tokyo, locale: locale), "24")
        XCTAssertEqual(instant.ritualDate(template: "d", in: losAngeles, locale: locale), "23")
        XCTAssertEqual(
            instant.ritualShortTime(in: tokyo, locale: locale)
                .replacingOccurrences(of: "\u{202F}", with: " "),
            "5:30 AM"
        )
        XCTAssertEqual(
            instant.ritualShortTime(in: losAngeles, locale: locale)
                .replacingOccurrences(of: "\u{202F}", with: " "),
            "1:30 PM"
        )
    }

    func testOnlyOwnedNotificationIdentifiersAreCleared() {
        XCTAssertTrue(NotificationManager.isRitualNotificationIdentifier("muhurta.2.123"))
        XCTAssertTrue(NotificationManager.isRitualNotificationIdentifier("brahma.123"))
        XCTAssertFalse(NotificationManager.isRitualNotificationIdentifier("another-feature.123"))
    }

    func testGeoNamesNoticeIsBundled() throws {
        let noticeURL = try XCTUnwrap(Bundle.main.url(forResource: "NOTICE", withExtension: "txt"))
        let notice = try String(contentsOf: noticeURL, encoding: .utf8)
        XCTAssertTrue(notice.contains("GeoNames"))
        XCTAssertTrue(notice.contains("CC BY 4.0"))
        XCTAssertTrue(notice.contains("cities15000"))

        let catalogURL = try XCTUnwrap(Bundle.main.url(forResource: "world_cities", withExtension: "tsv"))
        XCTAssertFalse(try String(contentsOf: catalogURL, encoding: .utf8).isEmpty)
        let matchingResources = Bundle.main.urls(forResourcesWithExtension: "tsv", subdirectory: nil)?
            .filter { $0.lastPathComponent == "world_cities.tsv" }
        XCTAssertEqual(matchingResources?.count, 1)
    }

    func testLightThemesKeepSemanticTextLegible() {
        let lightThemes = CosmicThemeVariant.allCases.map(\.colorScheme).filter(\.isLight)
        XCTAssertEqual(lightThemes.count, 3)
        XCTAssertEqual(CosmicThemeVariant.allCases.count - lightThemes.count, 3)

        for theme in lightThemes {
            XCTAssertEqual(theme.colorScheme, .light, theme.displayName)
            XCTAssertGreaterThanOrEqual(
                contrast(theme.semanticPrimaryText, over: theme.background),
                7.0,
                "\(theme.displayName) primary text"
            )
            XCTAssertGreaterThanOrEqual(
                contrast(theme.semanticSecondaryText, over: theme.background),
                4.5,
                "\(theme.displayName) secondary text"
            )
            XCTAssertGreaterThanOrEqual(
                contrast(theme.semanticTertiaryText, over: theme.background),
                3.0,
                "\(theme.displayName) tertiary text"
            )
        }
    }

    func testSelectedControlForegroundRemainsLegibleAcrossEveryTheme() {
        for theme in CosmicThemeVariant.allCases.map(\.colorScheme) {
            XCTAssertGreaterThanOrEqual(
                contrast(theme.selectedControlForeground, over: theme.primary),
                4.5,
                "\(theme.displayName) selected-control foreground"
            )
        }
    }

    func testMonthlyCalendarCacheIdentityChangesWithCalculationLocation() {
        let delhi = context(2026, 7, 24, latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata")
        let tokyo = context(2026, 7, 24, latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo")
        let sameDelhiNextDay = delhi.advancedByLocalDays(1)

        XCTAssertNotEqual(
            MonthlyCalendarCalculationSignature(context: delhi),
            MonthlyCalendarCalculationSignature(context: tokyo)
        )
        XCTAssertEqual(
            MonthlyCalendarCalculationSignature(context: delhi),
            MonthlyCalendarCalculationSignature(context: sameDelhiNextDay),
            "Changing only the selected day must not invalidate a whole-month location cache"
        )
    }

    func testPrivacyManifestUsesOnlyStandardAppUserDefaultsReason() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        let accessedTypes = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = try XCTUnwrap(accessedTypes.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
        })
        let reasons = try XCTUnwrap(userDefaults["NSPrivacyAccessedAPITypeReasons"] as? [String])

        XCTAssertEqual(reasons, ["CA92.1"])
    }

    private func contrast(_ foreground: Color, over background: Color) -> Double {
        let foregroundRGBA = rgba(foreground)
        let backgroundRGBA = rgba(background)
        let alpha = foregroundRGBA.alpha
        let composite = (
            red: foregroundRGBA.red * alpha + backgroundRGBA.red * (1 - alpha),
            green: foregroundRGBA.green * alpha + backgroundRGBA.green * (1 - alpha),
            blue: foregroundRGBA.blue * alpha + backgroundRGBA.blue * (1 - alpha)
        )
        let foregroundLuminance = relativeLuminance(composite)
        let backgroundLuminance = relativeLuminance((
            red: backgroundRGBA.red,
            green: backgroundRGBA.green,
            blue: backgroundRGBA.blue
        ))
        return (max(foregroundLuminance, backgroundLuminance) + 0.05)
            / (min(foregroundLuminance, backgroundLuminance) + 0.05)
    }

    private func rgba(_ color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }

    private func relativeLuminance(_ color: (red: Double, green: Double, blue: Double)) -> Double {
        func linear(_ component: Double) -> Double {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red)
            + 0.7152 * linear(color.green)
            + 0.0722 * linear(color.blue)
    }

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
        let localDay = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date(timeIntervalSince1970: 0)
        return CalculationContext(
            localDay: localDay,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone
        )
    }
}
