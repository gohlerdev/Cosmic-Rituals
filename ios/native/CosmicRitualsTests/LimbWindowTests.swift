import XCTest
@testable import CosmicRituals

/// The full limb-window timeline (every tithi/nakshatra/yoga/karana span of
/// the Panchang day) built by the backward + forward boundary solver.
final class LimbWindowTests: XCTestCase {

    private func context(_ y: Int, _ m: Int, _ d: Int,
                         latitude: Double = 19.0760, longitude: Double = 72.8777,
                         timeZone: String = "Asia/Kolkata") -> CalculationContext {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timeZone)!
        return CalculationContext(
            localDay: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
            latitude: latitude, longitude: longitude,
            timeZoneIdentifier: timeZone
        )
    }

    /// Windows tile the sunrise-to-sunrise day exactly: the first window
    /// begins at or before sunrise (its limb was already running), each next
    /// window starts where the previous ended, and the last reaches past the
    /// next sunrise.
    func testWindowsTileTheDayContiguously() throws {
        let mumbai = context(2026, 7, 24)
        let today = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: mumbai))
        let tomorrow = try XCTUnwrap(CosmicEngine.getSunriseSunset(context: mumbai.advancedByLocalDays(1)))

        for kind in PanchangLimbKind.allCases {
            let windows = CosmicEngine.limbWindows(for: kind, context: mumbai)
            XCTAssertFalse(windows.isEmpty, "\(kind)")
            XCTAssertLessThanOrEqual(windows[0].startTime, today.sunrise, "\(kind) first window began at or before sunrise")
            XCTAssertGreaterThanOrEqual(windows.last!.endTime, tomorrow.sunrise, "\(kind) last window reaches the next sunrise")
            for index in 1..<windows.count {
                XCTAssertEqual(
                    windows[index].startTime, windows[index - 1].endTime,
                    "\(kind) contiguous at \(index)"
                )
            }
            for window in windows {
                XCTAssertGreaterThan(window.endTime.timeIntervalSince(window.startTime), 3_600,
                                     "\(kind) no fabricated sliver windows")
            }
        }
    }

    /// The first window must agree with the sunrise snapshot the rest of the
    /// app renders: same limb name, and its end is the same boundary the
    /// existing next-transition solver reports (which the published Drik
    /// fixtures already pin).
    func testFirstWindowAgreesWithTheSunriseSnapshot() throws {
        let mumbai = context(2026, 7, 24)
        let panchang = CosmicEngine.getPanchang(context: mumbai)

        let tithiWindows = CosmicEngine.limbWindows(for: .tithi, context: mumbai)
        XCTAssertEqual(tithiWindows.first?.name, panchang.tithiName)
        if let transition = panchang.transitions.tithi, let first = tithiWindows.first {
            XCTAssertEqual(first.endTime.timeIntervalSince(transition.endTime), 0, accuracy: 2)
        }

        let nakWindows = CosmicEngine.limbWindows(for: .nakshatra, context: mumbai)
        XCTAssertEqual(nakWindows.first?.name, panchang.nakshatraName)
    }

    /// Tithi structure over a fortnight at Mumbai: every day yields one to
    /// three windows (one = vriddhi spanning both sunrises, three = a kshaya
    /// tithi contained inside the day), names never repeat consecutively,
    /// and karana windows are about half as long as tithi windows (two
    /// karanas per tithi).
    func testFortnightStructureIsClassicallyPlausible() {
        var tithiCounts: Set<Int> = []
        for day in 10...24 {
            let ctx = context(2026, 7, day)
            let tithi = CosmicEngine.limbWindows(for: .tithi, context: ctx)
            tithiCounts.insert(tithi.count)
            XCTAssertTrue((1...3).contains(tithi.count), "2026-07-\(day): \(tithi.count) tithi windows")
            for index in 1..<tithi.count {
                XCTAssertNotEqual(tithi[index].name, tithi[index - 1].name, "2026-07-\(day)")
            }
            let karana = CosmicEngine.limbWindows(for: .karana, context: ctx)
            XCTAssertGreaterThanOrEqual(karana.count, tithi.count, "2026-07-\(day): karanas subdivide tithis")
        }
        XCTAssertTrue(tithiCounts.contains(2), "ordinary two-window days occur in any fortnight")
    }

    /// Where sunrise does not exist, the timeline anchors to the civil day
    /// (matching the snapshot's disclosed fallback) instead of vanishing —
    /// the limbs themselves are not sunrise-based.
    func testPolarDayFallsBackToCivilDayAnchors() {
        let svalbard = context(2026, 6, 21, latitude: 78.2232, longitude: 15.6469,
                               timeZone: "Arctic/Longyearbyen")
        XCTAssertNil(CosmicEngine.getSunriseSunset(context: svalbard))
        let windows = CosmicEngine.limbWindows(for: .tithi, context: svalbard)
        XCTAssertFalse(windows.isEmpty)
        for index in 1..<windows.count {
            XCTAssertEqual(windows[index].startTime, windows[index - 1].endTime)
        }
    }
}
