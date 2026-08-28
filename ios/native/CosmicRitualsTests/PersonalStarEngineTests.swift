import XCTest
@testable import CosmicRituals

/// PersonalStarEngine's rules were cross-checked across multiple mutually
/// consistent published sources (drikpanchang tarabalam/chandrabalam tables,
/// mypanchang's Tarabalam Chakra, prokerala, trsiyengar) before
/// implementation; these tests pin the published rules themselves.
final class PersonalStarEngineTests: XCTestCase {

    // MARK: - Tarabala

    func testTaraCountingMatchesThePublishedConvention() {
        // Same star: inclusive count 1 -> Janma.
        XCTAssertEqual(PersonalStarEngine.taraNumber(birthNakshatraIndex: 0, dayNakshatraIndex: 0), 1)
        // Next star: count 2 -> Sampat.
        XCTAssertEqual(PersonalStarEngine.taraNumber(birthNakshatraIndex: 0, dayNakshatraIndex: 1), 2)
        // Count 9 -> Parama Mitra (remainder 0 read as 9).
        XCTAssertEqual(PersonalStarEngine.taraNumber(birthNakshatraIndex: 0, dayNakshatraIndex: 8), 9)
        // Count 10 wraps to tara 1 (Janma) in the second cycle.
        XCTAssertEqual(PersonalStarEngine.taraNumber(birthNakshatraIndex: 0, dayNakshatraIndex: 9), 1)
        // Wraparound across the 27-cycle: birth Revati (26), day Ashwini (0)
        // -> inclusive count 2 -> Sampat.
        XCTAssertEqual(PersonalStarEngine.taraNumber(birthNakshatraIndex: 26, dayNakshatraIndex: 0), 2)
    }

    func testTaraNamesAndQualitiesMatchThePublishedTable() {
        XCTAssertEqual(PersonalStarEngine.taraNames, [
            "Janma", "Sampat", "Vipat", "Kshema", "Pratyari",
            "Sadhaka", "Naidhana", "Mitra", "Parama Mitra",
        ])
        // Favorable: 2, 4, 6, 8, 9. Unfavorable: 3, 5, 7. Janma: mixed,
        // because the checked sources genuinely disagree on it.
        for day in 0..<9 {
            let result = PersonalStarEngine.tarabala(birthNakshatraIndex: 0, dayNakshatraIndex: day)
            let expected: TaraQuality = switch result.taraNumber {
            case 2, 4, 6, 8, 9: .favorable
            case 3, 5, 7: .unfavorable
            default: .mixed
            }
            XCTAssertEqual(result.quality, expected, "tara \(result.taraNumber)")
        }
        let janma = PersonalStarEngine.tarabala(birthNakshatraIndex: 4, dayNakshatraIndex: 4)
        XCTAssertEqual(janma.quality, .mixed)
        XCTAssertTrue(janma.note.contains("differ"), "the Janma divergence must stay disclosed")
    }

    // MARK: - Janma rashi from nakshatra + pada

    func testJanmaRashiFollowsTheNinePadasPerSignMapping() {
        // Ashwini pada 1 -> Aries.
        XCTAssertEqual(PersonalStarEngine.janmaRashiIndex(birthNakshatraIndex: 0, pada: 1), 0)
        // Krittika is the classical boundary case: pada 1 is Aries, padas
        // 2-4 are Taurus.
        XCTAssertEqual(PersonalStarEngine.janmaRashiIndex(birthNakshatraIndex: 2, pada: 1), 0)
        XCTAssertEqual(PersonalStarEngine.janmaRashiIndex(birthNakshatraIndex: 2, pada: 2), 1)
        XCTAssertEqual(PersonalStarEngine.janmaRashiIndex(birthNakshatraIndex: 2, pada: 4), 1)
        // Revati pada 4 is the last pada of Pisces.
        XCTAssertEqual(PersonalStarEngine.janmaRashiIndex(birthNakshatraIndex: 26, pada: 4), 11)
        // Every sign receives exactly nine of the 108 padas.
        var counts = [Int: Int]()
        for nak in 0..<27 {
            for pada in 1...4 {
                counts[PersonalStarEngine.janmaRashiIndex(birthNakshatraIndex: nak, pada: pada), default: 0] += 1
            }
        }
        XCTAssertEqual(counts.count, 12)
        XCTAssertTrue(counts.values.allSatisfy { $0 == 9 })
    }

    // MARK: - Chandrabala and Chandrashtama

    func testChandrabalaFavorableSetMatchesThePublishedCounts() {
        XCTAssertEqual(PersonalStarEngine.chandrabalaFavorableCounts, [1, 3, 6, 7, 10, 11])
        for daySign in 0..<12 {
            let count = PersonalStarEngine.chandraCount(janmaRashiIndex: 0, dayMoonSignIndex: daySign)
            XCTAssertEqual(count, daySign + 1)
            XCTAssertEqual(
                PersonalStarEngine.hasChandrabala(janmaRashiIndex: 0, dayMoonSignIndex: daySign),
                [1, 3, 6, 7, 10, 11].contains(count)
            )
        }
    }

    func testChandrashtamaIsTheEighthSignFromJanmaRashi() {
        // Janma rashi Aries (0): the 8th sign is Scorpio (7).
        XCTAssertTrue(PersonalStarEngine.isChandrashtama(janmaRashiIndex: 0, dayMoonSignIndex: 7))
        XCTAssertFalse(PersonalStarEngine.isChandrashtama(janmaRashiIndex: 0, dayMoonSignIndex: 6))
        // Wraparound: janma rashi Virgo (5) -> 8th is Aries (0).
        XCTAssertTrue(PersonalStarEngine.isChandrashtama(janmaRashiIndex: 5, dayMoonSignIndex: 0))
        // Chandrashtama's count (8) is never a Chandrabala count.
        XCTAssertFalse(PersonalStarEngine.chandrabalaFavorableCounts.contains(8))
    }
}
