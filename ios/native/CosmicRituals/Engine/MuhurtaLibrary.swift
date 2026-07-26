import Foundation

// MARK: - Muhurta Info (rich descriptive layer)
//
// The engine's `muhurtaData` carries each muhurta's name, quality, and a one-line
// purpose. This library adds the deeper classical detail surfaced in the detail sheet:
// the presiding deity (devata), the planetary / elemental resonance, a fuller
// description, and the traditional favourable / to-avoid activities.
//
// Attributions follow the classical ahoratra (day-night) scheme of thirty muhurtas.
// Several muhurta names carry regional variants; the tone here is symbolic and
// traditional, never predictive.

struct MuhurtaInfo {
    let id: Int              // 1...30, matches Muhurta.id
    let deity: String        // presiding devata
    let resonance: String    // short planetary / elemental resonance
    let detail: String       // 1–2 sentence richer description
    let favorable: [String]  // ideal / traditionally supported activities
    let avoid: [String]      // activities to avoid
}

enum MuhurtaLibrary {

    static func info(for id: Int) -> MuhurtaInfo? { byID[id] }

    static let byID: [Int: MuhurtaInfo] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    static let all: [MuhurtaInfo] = [

        // ───────────────── Day muhurtas 1–15 (Sunrise → Sunset) ─────────────────

        MuhurtaInfo(
            id: 1, deity: "Rudra (Shiva)", resonance: "Fierce transformative fire",
            detail: "The day opens under Rudra, the storm-form of Shiva — intense, dissolving and unsettled. An hour of endings rather than beginnings.",
            favorable: ["Ending or dismantling what is finished", "Demolition & clearing", "Fierce Shiva sadhana & mantra"],
            avoid: ["New ventures & launches", "Weddings and auspicious rites", "Signing agreements"]),

        MuhurtaInfo(
            id: 2, deity: "Ahi — the cosmic serpent (Naga)", resonance: "Coiled, hidden Kundalini current",
            detail: "Ruled by the serpent: subtle, secretive and slippery. Outcomes coil back on themselves and delays hide in the grass.",
            favorable: ["Occult & tantric study", "Work with medicine or subtle energy", "Guarding secrets"],
            avoid: ["Beginnings", "Travel", "Trusting new alliances"]),

        MuhurtaInfo(
            id: 3, deity: "Mitra — Aditya of friendship", resonance: "Solar harmony",
            detail: "Mitra, lord of honoured bonds and contracts, blesses sincere cooperation and warm agreements.",
            favorable: ["Alliances & partnerships", "Meetings & reconciliation", "Contracts of goodwill"],
            avoid: ["Solitary high-risk moves", "Conflict & litigation"]),

        MuhurtaInfo(
            id: 4, deity: "The Pitris (ancestors)", resonance: "Lunar-ancestral, southward",
            detail: "The ancestral hour, turned toward the departed and the roots of the family line — sacred for remembrance, not for celebration.",
            favorable: ["Shraddha & tarpana (ancestral rites)", "Charity in ancestors' names", "Honouring elders"],
            avoid: ["Weddings & new beginnings", "Festivities", "Housewarming"]),

        MuhurtaInfo(
            id: 5, deity: "The Ashta Vasus", resonance: "Earthy abundance",
            detail: "The eight Vasus preside — givers of dwelling, wealth and material steadiness.",
            favorable: ["Financial dealings & investment", "Buying property or valuables", "Trade & commerce"],
            avoid: ["Reckless spending", "Gambling"]),

        MuhurtaInfo(
            id: 6, deity: "Varada — the boon-giver", resonance: "Ceremonial air",
            detail: "A ceremonial, moderately favourable window — good for preparing rites and steady routine, though not the day's peak.",
            favorable: ["Ritual preparation & vows", "Setting up ceremonies", "Ordinary routine work"],
            avoid: ["High-stakes launches", "Major financial commitments"]),

        MuhurtaInfo(
            id: 7, deity: "The Vishvadevas (the all-gods)", resonance: "Collective divine blessing",
            detail: "The Vishvadevas, the whole assembly of gods, sanctify worship and universal offerings.",
            favorable: ["Worship, puja & yajna", "Community & charitable acts", "Vows & pilgrimage"],
            avoid: ["Selfish or deceptive dealings"]),

        MuhurtaInfo(
            id: 8, deity: "Brahma (the ordainer)", resonance: "Creative order — Jupiter-like",
            detail: "Vidhi, near midday, is Brahma's own 'victorious' muhurta (Abhijit) — the auspicious hour that overcomes most flaws.",
            favorable: ["New undertakings & launches", "Education & learning", "Signing contracts", "Important decisions"],
            avoid: ["Idleness — its power is wasted if unused"]),

        MuhurtaInfo(
            id: 9, deity: "Satamukhi — 'the hundred-faced'", resonance: "Scattered, dispersive",
            detail: "A hundred-faced window where attention fragments and energy leaks in every direction.",
            favorable: ["Clearing many small tasks", "Undemanding routine"],
            avoid: ["Focused, singular ventures", "Important launches"]),

        MuhurtaInfo(
            id: 10, deity: "Puruhuta (Indra)", resonance: "Royal power — Sun / Jupiter",
            detail: "Puruhuta, the much-invoked Indra, lends royal force to bold and consequential tasks.",
            favorable: ["Leadership & bold action", "Career moves & authority", "Competitions"],
            avoid: ["Timid half-measures", "Underhanded acts"]),

        MuhurtaInfo(
            id: 11, deity: "Vahini — the bearing current", resonance: "Restless flux",
            detail: "A flowing, restless hour: currents shift underfoot and stability is scarce.",
            favorable: ["Movement & transport", "Adaptive, in-motion work"],
            avoid: ["Major decisions", "Long-term commitments"]),

        MuhurtaInfo(
            id: 12, deity: "Naktanakara — 'the night-maker'", resonance: "Fading light, obstacles",
            detail: "As the day begins to tilt, hidden obstacles gather — a shadowed, unfavourable window.",
            favorable: ["Winding down", "Quiet introspection"],
            avoid: ["Beginnings", "Signing & buying", "Travel"]),

        MuhurtaInfo(
            id: 13, deity: "Varuna — lord of waters & cosmic law", resonance: "Oceanic, watery",
            detail: "Varuna, keeper of the waters and of rita (cosmic order), favours flow, cleansing and truth.",
            favorable: ["Water rites & purification", "Travel by or over water", "Oaths & truth-telling"],
            avoid: ["Deception", "Risky fire-related work"]),

        MuhurtaInfo(
            id: 14, deity: "Aryaman — Aditya of noble bonds", resonance: "Solar nobility",
            detail: "Aryaman, guardian of marriage and honourable ties, blesses commitments made in good faith.",
            favorable: ["Marriage & betrothal", "Partnerships & legal matters", "Community bonds"],
            avoid: ["Breaking ties", "Dishonourable dealings"]),

        MuhurtaInfo(
            id: 15, deity: "Bhaga — Aditya of fortune & delight", resonance: "Solar bounty — Venusian joy",
            detail: "Bhaga, dispenser of fortune and shared delight, crowns the daylight with prosperity and pleasure.",
            favorable: ["Prosperity & luxury purchases", "Celebrations & enjoyment", "Wealth ceremonies"],
            avoid: ["Austere or harsh undertakings"]),

        // ───────────────── Night muhurtas 16–30 (Sunset → Sunrise) ─────────────────

        MuhurtaInfo(
            id: 16, deity: "Girisha (Shiva of the mountain)", resonance: "Still, ascetic darkness",
            detail: "Nightfall opens under Girisha, the mountain-dwelling Shiva — austere and inward, not for worldly gain.",
            favorable: ["Meditation & tapas", "Shiva worship", "Solitude"],
            avoid: ["Worldly beginnings", "Socialising for advantage"]),

        MuhurtaInfo(
            id: 17, deity: "Aja Ekapada (the one-footed unborn)", resonance: "Fixed, mysterious",
            detail: "The 'unborn one-foot', a Rudra form: a fixed, enigmatic current suited to contemplation over action.",
            favorable: ["Deep study & mantra", "Steadying practices"],
            avoid: ["Movement & travel", "New initiatives"]),

        MuhurtaInfo(
            id: 18, deity: "Ahirbudhnya — serpent of the deep", resonance: "Abyssal subconscious",
            detail: "The dragon of the depths rules a subtle hour for the subconscious, dreams and hidden currents.",
            favorable: ["Dream & subconscious work", "Introspection", "Kundalini practice"],
            avoid: ["Surface, material decisions"]),

        MuhurtaInfo(
            id: 19, deity: "Pushan — the nourisher", resonance: "Nourishing, protective",
            detail: "Pushya, the nourisher, ranks among the most auspicious of all muhurtas — protective and life-giving (yet, by classical rule, avoided for marriage).",
            favorable: ["Nearly all auspicious acts", "Healing, medicine & nourishment", "Learning & sowing"],
            avoid: ["Marriage (the classical Pushya exception)"]),

        MuhurtaInfo(
            id: 20, deity: "The Ashwini Kumaras (divine physicians)", resonance: "Swift healing — Ketu",
            detail: "The Ashwini twins, physicians of the gods, bring speed, vigour and healing.",
            favorable: ["Medicine & healing", "Travel & swift action", "Energetic new ventures"],
            avoid: ["Slow, deliberative matters"]),

        MuhurtaInfo(
            id: 21, deity: "Yama — lord of death & dharma", resonance: "Saturnine restraint",
            detail: "Yama, lord of death and cosmic justice, rules the most inauspicious night muhurta — a time to pause, not to begin.",
            favorable: ["Reflection on dharma", "Honouring the departed"],
            avoid: ["All auspicious beginnings", "Travel", "Celebrations & launches"]),

        MuhurtaInfo(
            id: 22, deity: "Agni — the sacred fire", resonance: "Purifying fire — Mars",
            detail: "Agni purifies and carries offerings skyward — potent for fire-rites, though sharp-edged for delicate matters.",
            favorable: ["Homa & fire ceremonies", "Purification rituals", "Preparing sacred food"],
            avoid: ["Water-related work", "Delicate diplomacy"]),

        MuhurtaInfo(
            id: 23, deity: "Vidhatri (Brahma as arranger)", resonance: "Creative ordering",
            detail: "Vidhatri, the divine arranger, favours creation, craft and the shaping of new forms.",
            favorable: ["Creative & artistic work", "Planning & design", "Craft and making"],
            avoid: ["Destructive acts"]),

        MuhurtaInfo(
            id: 24, deity: "Kanda — the knot / obstacle", resonance: "Blocked, knotted",
            detail: "A knotted, obstacle-laden hour where efforts snag and delays multiply.",
            favorable: ["Patience & maintenance", "Untangling existing problems"],
            avoid: ["Beginnings", "Important commitments"]),

        MuhurtaInfo(
            id: 25, deity: "Aditi — boundless mother of the gods", resonance: "Expansive freedom",
            detail: "Aditi, the limitless mother, opens space, freedom and fresh possibility.",
            favorable: ["Beginnings needing freedom", "Release & liberation", "Fertility & motherhood rites"],
            avoid: ["Confining or restrictive acts"]),

        MuhurtaInfo(
            id: 26, deity: "Jiva / Brihaspati & Amrita (nectar)", resonance: "Jupiterian grace",
            detail: "The nectar-hour of Brihaspati — supremely auspicious, blessing life, wisdom and longevity.",
            favorable: ["Highly auspicious acts of every kind", "Spiritual initiation", "Healing & longevity rites", "Study of scripture"],
            avoid: ["Squandering it on trivial pursuits"]),

        MuhurtaInfo(
            id: 27, deity: "Vishnu — the preserver", resonance: "Sustaining harmony",
            detail: "Vishnu, the all-preserver, sustains and protects — excellent for devotion and steady growth.",
            favorable: ["Devotion & worship", "Sustaining ongoing ventures", "Preservation & charity"],
            avoid: ["Destructive or divisive acts"]),

        MuhurtaInfo(
            id: 28, deity: "Dyumadgadyuti — 'the radiant'", resonance: "Luminous fame",
            detail: "A radiant, shining hour that favours brilliance, recognition and visible success.",
            favorable: ["Efforts toward fame & recognition", "Performances & launches", "Ambitious endeavours"],
            avoid: ["Hidden or shady dealings"]),

        MuhurtaInfo(
            id: 29, deity: "Brahma (the creator)", resonance: "Pure creative wisdom",
            detail: "The Brahma muhurta, the sacred pre-dawn window, is prized above all for meditation, study and the deepest undertakings.",
            favorable: ["Meditation & spiritual practice", "Study & memorisation", "Any auspicious beginning"],
            avoid: ["Sleeping through it", "Sensual indulgence"]),

        MuhurtaInfo(
            id: 30, deity: "Samudra — the ocean", resonance: "Deep, turbulent waters",
            detail: "The final hour belongs to the ocean — vast and turbulent, closing the night on an unsettled note.",
            favorable: ["Winding down before dawn", "Water rites at night's edge"],
            avoid: ["Important beginnings", "Major decisions before rest"]),
    ]
}

// MARK: - Convenience

extension Muhurta {
    /// The rich classical detail for this muhurta, if available.
    var info: MuhurtaInfo? { MuhurtaLibrary.info(for: id) }
}
