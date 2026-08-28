import Foundation

// MARK: - Personal star relations (Tarabala, Chandrabala, Chandrashtama)
//
// All three cross-reference the user's BIRTH star with positions the engine
// already computes for the day. Rules cross-checked across multiple mutually
// consistent published sources before implementation (drikpanchang tarabalam
// and chandrabalam tables, mypanchang's Tarabalam Chakra, astroved, prokerala,
// trsiyengar):
//  - Tarabala: count inclusively from the birth nakshatra to the day's Moon
//    nakshatra in the 27-cycle, take mod 9 with remainder 0 read as 9.
//    Names: Janma, Sampat, Vipat, Kshema, Pratyari, Sadhaka, Naidhana,
//    Mitra, Parama Mitra. Favorable: 2, 4, 6, 8, 9. Unfavorable: 3, 5, 7.
//    JANMA's classification genuinely diverges across sources (drikpanchang
//    "Not Good", astroved "Mixed", one source reserves it for spiritual
//    initiation) -- it is labelled mixed here with the divergence disclosed.
//  - Chandrashtama: the day's Moon occupying the 8th RASHI counted from the
//    janma rashi (the nakshatra-specific "peak star" lists published by some
//    sources are a refinement inside that 8th sign, not a competing rule).
//  - Chandrabala: present when the day Moon's sign counted inclusively from
//    the janma rashi is 1, 3, 6, 7, 10, or 11. The unfavorable counts carry
//    a further classical remediability split that is deliberately not
//    modelled; no grade is invented for them beyond "absent".

enum TaraQuality: String {
    case favorable = "Favorable"
    case unfavorable = "Unfavorable"
    case mixed = "Mixed"
}

struct TaraResult: Equatable {
    let taraNumber: Int      // 1...9
    let name: String
    let quality: TaraQuality
    let note: String
}

enum PersonalStarEngine {

    static let taraNames = [
        "Janma", "Sampat", "Vipat", "Kshema", "Pratyari",
        "Sadhaka", "Naidhana", "Mitra", "Parama Mitra",
    ]

    /// Inclusive count from the birth star to the day star, mod 9 with a zero
    /// remainder read as 9 -- the convention every checked source shares.
    static func taraNumber(birthNakshatraIndex: Int, dayNakshatraIndex: Int) -> Int {
        let count = ((dayNakshatraIndex - birthNakshatraIndex + 27) % 27) + 1
        let remainder = count % 9
        return remainder == 0 ? 9 : remainder
    }

    static func tarabala(birthNakshatraIndex: Int, dayNakshatraIndex: Int) -> TaraResult {
        let number = taraNumber(birthNakshatraIndex: birthNakshatraIndex, dayNakshatraIndex: dayNakshatraIndex)
        let name = taraNames[number - 1]
        let quality: TaraQuality
        let note: String
        switch number {
        case 2, 4, 6, 8, 9:
            quality = .favorable
            note = "Traditionally supportive for undertakings."
        case 3, 5, 7:
            quality = .unfavorable
            note = "Traditionally avoided for new undertakings."
        default: // 1 — Janma
            quality = .mixed
            note = "Sources genuinely differ on Janma: some grade it unfavorable, others mixed, and some reserve it for inward or spiritual work. It is shown as mixed rather than forcing one school's verdict."
        }
        return TaraResult(taraNumber: number, name: name, quality: quality, note: note)
    }

    /// The janma rashi from birth nakshatra + pada: 108 padas map 9-per-sign,
    /// so rashi = (nakshatra*4 + pada-1) / 9. Krittika pada 1 is Aries while
    /// padas 2-4 are Taurus, the classical boundary case.
    static func janmaRashiIndex(birthNakshatraIndex: Int, pada: Int) -> Int {
        let padaIndex = birthNakshatraIndex * 4 + (pada - 1).clamped(to: 0...3)
        return (padaIndex.clamped(to: 0...107)) / 9
    }

    /// Inclusive sign count from the janma rashi to the day Moon's sign.
    static func chandraCount(janmaRashiIndex: Int, dayMoonSignIndex: Int) -> Int {
        ((dayMoonSignIndex - janmaRashiIndex + 12) % 12) + 1
    }

    static let chandrabalaFavorableCounts: Set<Int> = [1, 3, 6, 7, 10, 11]

    static func hasChandrabala(janmaRashiIndex: Int, dayMoonSignIndex: Int) -> Bool {
        chandrabalaFavorableCounts.contains(
            chandraCount(janmaRashiIndex: janmaRashiIndex, dayMoonSignIndex: dayMoonSignIndex)
        )
    }

    static func isChandrashtama(janmaRashiIndex: Int, dayMoonSignIndex: Int) -> Bool {
        chandraCount(janmaRashiIndex: janmaRashiIndex, dayMoonSignIndex: dayMoonSignIndex) == 8
    }
}
