import XCTest
@testable import CosmicRituals

/// Verifies PanchangYogaEngine's Vara-Nakshatra tables against the classical
/// rule itself (checked against multiple independent, mutually consistent
/// published sources before implementation), not against whatever the code
/// happens to compute.
final class PanchangYogaEngineTests: XCTestCase {

    private func makePanchang(
        weekdayName: String,
        nakshatraIndex: Int,
        sunNakshatraIndex: Int = 0
    ) -> Panchang {
        Panchang(
            date: Date(timeIntervalSince1970: 0),
            tithiIndex: 0,
            tithiName: Panchang.tithiNames[0],
            nakshatraIndex: nakshatraIndex,
            nakshatraName: Panchang.nakshatraNames[nakshatraIndex],
            sunNakshatraIndex: sunNakshatraIndex,
            yogaIndex: 0,
            yogaName: Panchang.yogaNames[0],
            karanaIndex: 0,
            karanaName: Panchang.karanaNames[0],
            weekdayName: weekdayName,
            moonSignIndex: 0,
            moonSignName: "Aries",
            sunriseTime: nil,
            sunsetTime: nil,
            transitions: .unavailable
        )
    }

    // MARK: - Sarvartha Siddhi Yoga

    /// Every published (weekday, nakshatra) pair in the Jyotir Nibandha table
    /// must be independently reachable, not just the first one tested.
    func testEverySarvarthaSiddhiPairIsReachable() {
        let pairs: [(String, Int)] = [
            ("Sunday", 12), ("Sunday", 18), ("Sunday", 11), ("Sunday", 20), ("Sunday", 25), ("Sunday", 7), ("Sunday", 8),
            ("Monday", 21), ("Monday", 3), ("Monday", 4), ("Monday", 7), ("Monday", 16),
            ("Tuesday", 0), ("Tuesday", 25), ("Tuesday", 2), ("Tuesday", 8),
            ("Wednesday", 3), ("Wednesday", 16), ("Wednesday", 12), ("Wednesday", 2), ("Wednesday", 4),
            ("Thursday", 26), ("Thursday", 16), ("Thursday", 0), ("Thursday", 6), ("Thursday", 7),
            ("Friday", 26), ("Friday", 16), ("Friday", 0), ("Friday", 6), ("Friday", 21),
            ("Saturday", 21), ("Saturday", 3), ("Saturday", 14),
        ]
        XCTAssertEqual(pairs.count, 34, "the published table has 34 pairs; a pair was added or dropped by mistake")
        for (weekday, nakshatra) in pairs {
            let panchang = makePanchang(weekdayName: weekday, nakshatraIndex: nakshatra)
            let matches = PanchangYogaEngine.evaluate(panchang: panchang)
            XCTAssertTrue(matches.contains { $0.id == "sarvarthaSiddhi" }, "\(weekday) + \(Panchang.nakshatraNames[nakshatra]) should form Sarvartha Siddhi Yoga")
        }
    }

    func testNakshatraNotInTodaysSarvarthaSiddhiListDoesNotMatch() {
        // Sunday's list is [Hasta, Mula, Uttara Phalguni, Uttara Ashadha, Uttara
        // Bhadrapada, Pushya, Ashlesha] -- Rohini (index 3) is not a member.
        let panchang = makePanchang(weekdayName: "Sunday", nakshatraIndex: 3)
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        XCTAssertFalse(matches.contains { $0.id == "sarvarthaSiddhi" })
    }

    // MARK: - Amrit Siddhi Yoga

    /// Every published (weekday, nakshatra) pair, and each is also a member
    /// of that weekday's Sarvartha Siddhi set -- the documented relationship
    /// between the two yogas, not a coincidence of this implementation.
    func testEveryAmritSiddhiPairIsReachableAndIsASarvarthaSiddhiMember() {
        let pairs: [(String, Int)] = [
            ("Sunday", 12), ("Monday", 4), ("Tuesday", 0), ("Wednesday", 16),
            ("Thursday", 7), ("Friday", 26), ("Saturday", 3),
        ]
        for (weekday, nakshatra) in pairs {
            let panchang = makePanchang(weekdayName: weekday, nakshatraIndex: nakshatra)
            let matches = PanchangYogaEngine.evaluate(panchang: panchang)
            XCTAssertTrue(matches.contains { $0.id == "amritSiddhi" }, "\(weekday) + \(Panchang.nakshatraNames[nakshatra]) should form Amrit Siddhi Yoga")
            XCTAssertTrue(matches.contains { $0.id == "sarvarthaSiddhi" }, "\(weekday) + \(Panchang.nakshatraNames[nakshatra]) is documented as also being a Sarvartha Siddhi pair")
        }
    }

    func testAmritSiddhiRequiresTheExactNakshatraNotJustTheWeekday() {
        // Sunday's Amrit Siddhi nakshatra is Hasta (12); Ashlesha (8) is a
        // Sarvartha Siddhi member for Sunday but not the Amrit Siddhi one.
        let panchang = makePanchang(weekdayName: "Sunday", nakshatraIndex: 8)
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        XCTAssertTrue(matches.contains { $0.id == "sarvarthaSiddhi" })
        XCTAssertFalse(matches.contains { $0.id == "amritSiddhi" })
    }

    // MARK: - Guru Pushya Yoga

    func testPushyaOnThursdayFormsGuruPushyaYoga() {
        let panchang = makePanchang(weekdayName: "Thursday", nakshatraIndex: 7)
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        XCTAssertTrue(matches.contains { $0.id == "guruPushya" })
    }

    func testPushyaOnAnyOtherWeekdayDoesNotFormGuruPushyaYoga() {
        for weekday in ["Sunday", "Monday", "Tuesday", "Wednesday", "Friday", "Saturday"] {
            let panchang = makePanchang(weekdayName: weekday, nakshatraIndex: 7)
            let matches = PanchangYogaEngine.evaluate(panchang: panchang)
            XCTAssertFalse(matches.contains { $0.id == "guruPushya" }, weekday)
        }
    }

    func testThursdayWithoutPushyaDoesNotFormGuruPushyaYoga() {
        let panchang = makePanchang(weekdayName: "Thursday", nakshatraIndex: 0)
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        XCTAssertFalse(matches.contains { $0.id == "guruPushya" })
    }

    // MARK: - Ravi Yoga

    func testNakshatraCountWrapsAroundTheTwentySevenNakshatraCycle() {
        XCTAssertEqual(PanchangYogaEngine.nakshatraCount(from: 0, to: 0), 1)
        XCTAssertEqual(PanchangYogaEngine.nakshatraCount(from: 0, to: 3), 4)
        // From Revati (26) to Ashwini (0) is 2: Revati counts as 1, Ashwini as 2.
        XCTAssertEqual(PanchangYogaEngine.nakshatraCount(from: 26, to: 0), 2)
    }

    /// Every published trigger count (4, 6, 9, 10, 13, 20) forms the yoga.
    func testEveryPublishedRaviYogaCountFormsTheYoga() {
        for count in [4, 6, 9, 10, 13, 20] {
            let moonIndex = (count - 1) % 27
            let panchang = makePanchang(weekdayName: "Monday", nakshatraIndex: moonIndex, sunNakshatraIndex: 0)
            XCTAssertEqual(PanchangYogaEngine.nakshatraCount(from: 0, to: moonIndex), count)
            let matches = PanchangYogaEngine.evaluate(panchang: panchang)
            XCTAssertTrue(matches.contains { $0.id == "raviYoga" }, "count \(count) should form Ravi Yoga")
        }
    }

    func testACountNotInThePublishedListDoesNotFormRaviYoga() {
        // Count 5 (Sun-nakshatra 0, Moon-nakshatra 4) is not in {4,6,9,10,13,20}.
        let panchang = makePanchang(weekdayName: "Monday", nakshatraIndex: 4, sunNakshatraIndex: 0)
        XCTAssertEqual(PanchangYogaEngine.nakshatraCount(from: 0, to: 4), 5)
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        XCTAssertFalse(matches.contains { $0.id == "raviYoga" })
    }

    // MARK: - No false positives

    func testAChartWithNoneOfTheseCombinationsReportsNoYogas() {
        // Tuesday + Bharani (index 1): not in any table, and Sun/Moon count
        // (0 to 1 => count 2) is not a Ravi Yoga count.
        let panchang = makePanchang(weekdayName: "Tuesday", nakshatraIndex: 1, sunNakshatraIndex: 0)
        let matches = PanchangYogaEngine.evaluate(panchang: panchang)
        XCTAssertTrue(matches.isEmpty)
    }
}
