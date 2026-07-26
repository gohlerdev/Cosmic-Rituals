import Foundation

// MARK: - Tithi Detail

struct TithiDetail {
    let index: Int           // 0–29
    let paksha: String       // Shukla / Krishna
    let deity: String
    let qualityClass: String // Nanda / Bhadra / Jaya / Rikta / Purna
    let qualityMeaning: String
    let guidance: String
    let favorable: [String]
    let avoid: [String]

    static func from(tithiIndex: Int) -> TithiDetail {
        all[tithiIndex.clamped(to: 0...29)]
    }

    static let all: [TithiDetail] = [
        // Shukla Paksha (waxing)
        TithiDetail(index: 0,  paksha: "Shukla", deity: "Brahma",          qualityClass: "Nanda",  qualityMeaning: "Joy & pleasure",
                    guidance: "The first day of the waxing fortnight — excellent for sowing new seeds in any area of life.",
                    favorable: ["Initiating new projects", "Worship of Brahma", "Learning new skills", "Short journeys"],
                    avoid: ["Fasting excessively", "Funeral rites"]),
        TithiDetail(index: 1,  paksha: "Shukla", deity: "Vidhatr",         qualityClass: "Bhadra", qualityMeaning: "Auspicious welfare",
                    guidance: "Blessed by the cosmic creator — good for building, cultivation, and establishing firm foundations.",
                    favorable: ["Agriculture & planting", "Building & construction", "Family rituals", "Learning"],
                    avoid: ["Travel to the west", "Destructive activities"]),
        TithiDetail(index: 2,  paksha: "Shukla", deity: "Gauri (Parvati)", qualityClass: "Jaya",   qualityMeaning: "Victory",
                    guidance: "Ruled by Gauri — an auspicious day for marriage, beauty, and feminine energies.",
                    favorable: ["Marriage & betrothal", "Beauty & adornment", "Jewellery", "Worship of Devi"],
                    avoid: ["Aggressive ventures", "Fasting on this night"]),
        TithiDetail(index: 3,  paksha: "Shukla", deity: "Ganesha",         qualityClass: "Rikta",  qualityMeaning: "Empty (reduce activity)",
                    guidance: "Chaturthi belongs to Ganesha — ideal for worship but considered inauspicious for starting new ventures.",
                    favorable: ["Ganesha puja & sankalpa", "Removing obstacles", "Charity"],
                    avoid: ["New business ventures", "Moongazing (Ganesha Chaturthi legend)", "Major decisions"]),
        TithiDetail(index: 4,  paksha: "Shukla", deity: "Naga (serpents)", qualityClass: "Purna",  qualityMeaning: "Fullness & completion",
                    guidance: "A powerful day of completeness — all undertakings carry added momentum and fruition.",
                    favorable: ["Completing projects", "Mantra siddhi", "Ceremonies", "Government work"],
                    avoid: ["Procrastination", "Starting what you cannot finish"]),
        TithiDetail(index: 5,  paksha: "Shukla", deity: "Kartikeya",       qualityClass: "Nanda",  qualityMeaning: "Joy & pleasure",
                    guidance: "Ruled by Kartikeya — excellent for activities requiring courage, discipline, and martial focus.",
                    favorable: ["Sports & martial arts", "Military matters", "Boldness in pursuit", "Worship of Skanda"],
                    avoid: ["Passive activities", "Indulgence"]),
        TithiDetail(index: 6,  paksha: "Shukla", deity: "Surya (Sun)",     qualityClass: "Bhadra", qualityMeaning: "Auspicious welfare",
                    guidance: "Governed by the Sun — ideal for government matters, authority, and leadership activities.",
                    favorable: ["Government dealings", "Leadership actions", "Sun worship", "Fame & reputation"],
                    avoid: ["Hiding or secretive actions", "Humility-seeking endeavours"]),
        TithiDetail(index: 7,  paksha: "Shukla", deity: "Shiva (Rudra)",   qualityClass: "Jaya",   qualityMeaning: "Victory",
                    guidance: "Ashtami is a powerful day of Shiva's energy — great for transformation and spiritual practice.",
                    favorable: ["Shiva worship & abhisheka", "Spiritual discipline", "Clearing debts", "Surgery if needed"],
                    avoid: ["Celebrations of a festive nature", "Beginning new relationships"]),
        TithiDetail(index: 8,  paksha: "Shukla", deity: "Durga",           qualityClass: "Rikta",  qualityMeaning: "Empty (reduce activity)",
                    guidance: "Navami is sacred to Durga — powerful for devotion but generally considered inauspicious for worldly starts.",
                    favorable: ["Devi sadhana", "Navarna mantra japa", "Charitable gifts to women"],
                    avoid: ["New business", "Long journeys", "Marriage"]),
        TithiDetail(index: 9,  paksha: "Shukla", deity: "Yama (Dharmaraj)", qualityClass: "Purna", qualityMeaning: "Fullness & completion",
                    guidance: "Dashami brings the full energy of righteousness — ideal for legal matters and ancestral honouring.",
                    favorable: ["Legal proceedings", "Ancestral rites", "Dharmic work", "Completing pending duties"],
                    avoid: ["Unethical activities", "Hiding the truth"]),
        TithiDetail(index: 10, paksha: "Shukla", deity: "Vishnu (Hari)",   qualityClass: "Nanda",  qualityMeaning: "Joy & pleasure",
                    guidance: "Ekadashi is the most sacred tithi of Vishnu — supreme for fasting, devotion, and spiritual study.",
                    favorable: ["Ekadashi vrat (fasting)", "Vishnu puja", "Spiritual study", "Charity & donations"],
                    avoid: ["Eating grain (traditional fast day)", "Worldly indulgences", "Arguments"]),
        TithiDetail(index: 11, paksha: "Shukla", deity: "Vishnu (Hari)",   qualityClass: "Bhadra", qualityMeaning: "Auspicious welfare",
                    guidance: "Dvadashi breaks the Ekadashi fast — Vishnu's blessing continues; excellent for gifting and Vaishnava ceremonies.",
                    favorable: ["Breaking Ekadashi fast (parana)", "Gift-giving", "Vaishnava rites", "New clothes"],
                    avoid: ["Fasting again immediately", "Harsh speech"]),
        TithiDetail(index: 12, paksha: "Shukla", deity: "Kama (Cupid)",    qualityClass: "Jaya",   qualityMeaning: "Victory",
                    guidance: "Trayodashi is associated with love and beauty — ideal for romantic matters and artistic creation.",
                    favorable: ["Romance & courtship", "Arts & music", "Beautification", "Pradosha vrat (Shiva)"],
                    avoid: ["Conflicts in relationships", "Harsh austerities"]),
        TithiDetail(index: 13, paksha: "Shukla", deity: "Shiva & Kali",    qualityClass: "Rikta",  qualityMeaning: "Empty (reduce activity)",
                    guidance: "Chaturdashi before Purnima — powerful but intense; best for Shiva and Kali worship, not new beginnings.",
                    favorable: ["Shivaratri observance", "Tantric practices", "Ending harmful patterns"],
                    avoid: ["Auspicious starts", "Celebration", "Travel at night"]),
        TithiDetail(index: 14, paksha: "Shukla", deity: "Chandra (Moon)",  qualityClass: "Purna",  qualityMeaning: "Fullness & completion",
                    guidance: "Purnima (Full Moon) is the most auspicious tithi — brilliant for all ceremonies, worship, and celebrations.",
                    favorable: ["All auspicious ceremonies", "Full Moon puja", "Sacred baths", "Community gatherings", "Meditation"],
                    avoid: ["Fasting without purpose", "Isolation"]),
        // Krishna Paksha (waning)
        TithiDetail(index: 15, paksha: "Krishna", deity: "Brahma",          qualityClass: "Nanda",  qualityMeaning: "Joy & pleasure",
                    guidance: "First day of the waning fortnight — energy begins to turn inward; good for reflective new starts.",
                    favorable: ["Inward projects", "Learning", "Bhajan & kirtana"],
                    avoid: ["Aggressive expansion", "Public launches"]),
        TithiDetail(index: 16, paksha: "Krishna", deity: "Vidhatr",         qualityClass: "Bhadra", qualityMeaning: "Auspicious welfare",
                    guidance: "Consolidation is favoured — building on foundations laid, reviewing ongoing work.",
                    favorable: ["Review & refine", "Family duties", "Agricultural activities"],
                    avoid: ["Travel west", "New risky investments"]),
        TithiDetail(index: 17, paksha: "Krishna", deity: "Gauri",           qualityClass: "Jaya",   qualityMeaning: "Victory",
                    guidance: "Devi's grace in the waning fortnight — feminine energy is strong; good for devotion and inner beauty.",
                    favorable: ["Devi worship", "Aesthetic work", "Reconciliation"],
                    avoid: ["Conflict", "Cutting hair on this day (some traditions)"]),
        TithiDetail(index: 18, paksha: "Krishna", deity: "Ganesha",         qualityClass: "Rikta",  qualityMeaning: "Empty (reduce activity)",
                    guidance: "Ganesha's waning Chaturthi — Sankashti; fasting and prayer for obstacle removal is very powerful.",
                    favorable: ["Sankashti Chaturthi vrat", "Ganesha puja", "Obstacle clearing"],
                    avoid: ["New ventures", "Moonrise before eating (Sankashti tradition)"]),
        TithiDetail(index: 19, paksha: "Krishna", deity: "Naga",            qualityClass: "Purna",  qualityMeaning: "Fullness & completion",
                    guidance: "Completion energy in the waning cycle — good for finishing projects and expressing gratitude.",
                    favorable: ["Completing work", "Ancestral gratitude", "Serpent deity worship"],
                    avoid: ["Procrastination", "Wasted energy"]),
        TithiDetail(index: 20, paksha: "Krishna", deity: "Kartikeya",       qualityClass: "Nanda",  qualityMeaning: "Joy & pleasure",
                    guidance: "Courage and discipline in the waning period — good for structured practice and self-improvement.",
                    favorable: ["Physical training", "Discipline routines", "Spiritual courage"],
                    avoid: ["Sloth", "Excessive indulgence"]),
        TithiDetail(index: 21, paksha: "Krishna", deity: "Surya",           qualityClass: "Bhadra", qualityMeaning: "Auspicious welfare",
                    guidance: "Sun's governance in the waning fortnight — inner authority; good for addressing established duties.",
                    favorable: ["Honouring superiors", "Government dealings", "Surya namaskar"],
                    avoid: ["Hiding from responsibility"]),
        TithiDetail(index: 22, paksha: "Krishna", deity: "Shiva",           qualityClass: "Jaya",   qualityMeaning: "Victory",
                    guidance: "Krishna Ashtami (Janmashtami if lunar month aligns) — extremely auspicious for Shiva and Krishna worship.",
                    favorable: ["Shiva & Krishna bhakti", "Fasting (Janmashtami)", "Midnight puja", "Transformation work"],
                    avoid: ["Frivolous activities on this night"]),
        TithiDetail(index: 23, paksha: "Krishna", deity: "Durga",           qualityClass: "Rikta",  qualityMeaning: "Empty (reduce activity)",
                    guidance: "Devi's powerful waning energy — protective practices are favoured; avoid starting new ventures.",
                    favorable: ["Devi kavach recitation", "Protective practices", "Charitable acts"],
                    avoid: ["New beginnings", "Risky investments"]),
        TithiDetail(index: 24, paksha: "Krishna", deity: "Yama",            qualityClass: "Purna",  qualityMeaning: "Fullness & completion",
                    guidance: "Completing karmic cycles; ancestral work has heightened potency in the waning phase.",
                    favorable: ["Shraddha rites", "Clearing old debts", "Righteous acts"],
                    avoid: ["Unethical shortcuts"]),
        TithiDetail(index: 25, paksha: "Krishna", deity: "Vishnu",          qualityClass: "Nanda",  qualityMeaning: "Joy & pleasure",
                    guidance: "Vishnu's blessing in the waning cycle — devotion, charity, and fasting bring spiritual merit.",
                    favorable: ["Ekadashi (Krishna) vrat", "Vishnu puja", "Giving in charity"],
                    avoid: ["Grain on Ekadashi", "Arguments"]),
        TithiDetail(index: 26, paksha: "Krishna", deity: "Vishnu",          qualityClass: "Bhadra", qualityMeaning: "Auspicious welfare",
                    guidance: "Parana day — the fast is broken; Vaishnava observances continue.",
                    favorable: ["Parana (breaking fast)", "Charitable gifting", "Devotional singing"],
                    avoid: ["Overeating", "Harsh words"]),
        TithiDetail(index: 27, paksha: "Krishna", deity: "Kama",            qualityClass: "Jaya",   qualityMeaning: "Victory",
                    guidance: "Romantic and artistic energies are still present even in the waning phase.",
                    favorable: ["Arts", "Music & dance", "Devotional love poetry"],
                    avoid: ["Cold, harsh communications"]),
        TithiDetail(index: 28, paksha: "Krishna", deity: "Shiva & Kali",    qualityClass: "Rikta",  qualityMeaning: "Empty (reduce activity)",
                    guidance: "The dark Chaturdashi before Amavasya — intense Shiva and Kali energy; not for worldly starts.",
                    favorable: ["Masik Shivaratri observance", "Kali puja", "Releasing what no longer serves"],
                    avoid: ["Celebrations", "New ventures", "Travel at night"]),
        TithiDetail(index: 29, paksha: "Krishna", deity: "Pitrs (ancestors)", qualityClass: "Purna", qualityMeaning: "Fullness & completion",
                    guidance: "Amavasya (New Moon) — the most potent tithi for ancestral rites. The Moon and Sun are together.",
                    favorable: ["Amavasya tarpana", "Ancestral worship", "Fasting", "Charity to Brahmins"],
                    avoid: ["Auspicious starts", "Celebrations", "Major decisions"]),
    ]
}

// MARK: - Yoga Detail

struct YogaDetail {
    let index: Int
    let name: String
    let deity: String
    let isAuspicious: Bool
    let meaning: String
    let guidance: String

    static func from(yogaIndex: Int) -> YogaDetail { all[yogaIndex.clamped(to: 0...26)] }

    static let all: [YogaDetail] = [
        YogaDetail(index: 0,  name: "Vishkambha", deity: "Yama",       isAuspicious: false,
                   meaning: "Obstruction",      guidance: "Heavy, obstructive energy. Avoid starting new work. Good for clearing debts and obstacles."),
        YogaDetail(index: 1,  name: "Priti",      deity: "Vishnu",     isAuspicious: true,
                   meaning: "Affection",         guidance: "A day of love and warmth. Excellent for friendships, romantic partnerships, and reconciliation."),
        YogaDetail(index: 2,  name: "Ayushman",   deity: "Brahma",     isAuspicious: true,
                   meaning: "Long life",         guidance: "Favourable for health-related activities, new health routines, and life-giving ceremonies."),
        YogaDetail(index: 3,  name: "Saubhagya",  deity: "Lakshmi",    isAuspicious: true,
                   meaning: "Good fortune",      guidance: "Lucky energy all around. Excellent for business, financial decisions, and auspicious beginnings."),
        YogaDetail(index: 4,  name: "Shobhana",   deity: "Brihaspati", isAuspicious: true,
                   meaning: "Brilliant",         guidance: "Shining energy; great for ceremonies, learning, teaching, and anything requiring clarity."),
        YogaDetail(index: 5,  name: "Atiganda",   deity: "Chandra",    isAuspicious: false,
                   meaning: "Danger in excess",  guidance: "Proceed with caution — there is a tendency for situations to escalate unexpectedly."),
        YogaDetail(index: 6,  name: "Sukarman",   deity: "Indra",      isAuspicious: true,
                   meaning: "Good action",       guidance: "Excellent for all good deeds, karma yoga, skilled labour, and meritorious acts."),
        YogaDetail(index: 7,  name: "Dhriti",     deity: "Jala",       isAuspicious: true,
                   meaning: "Steadiness",        guidance: "Stable, persevering energy — ideal for long-term projects, commitments, and building routines."),
        YogaDetail(index: 8,  name: "Shula",      deity: "Sarpas",     isAuspicious: false,
                   meaning: "Sharp pain",        guidance: "Avoid major decisions and unnecessary conflict. Good for piercing through illusions in meditation."),
        YogaDetail(index: 9,  name: "Ganda",      deity: "Agni",       isAuspicious: false,
                   meaning: "Knot / obstacle",   guidance: "Tangled energy — don't force things. Better to pause and address hidden knots before acting."),
        YogaDetail(index: 10, name: "Vriddhi",    deity: "Surya",      isAuspicious: true,
                   meaning: "Growth",            guidance: "All growth-oriented activities are blessed — business expansion, new ventures, and education."),
        YogaDetail(index: 11, name: "Dhruva",     deity: "Brahma",     isAuspicious: true,
                   meaning: "Fixed / stable",    guidance: "The most stable yoga — ideal for permanent decisions, property, long-term commitments."),
        YogaDetail(index: 12, name: "Vyaghata",   deity: "Vayu",       isAuspicious: false,
                   meaning: "Striking",          guidance: "Volatile energy. Avoid travel and confrontation. Good for vigorous physical exercise."),
        YogaDetail(index: 13, name: "Harshana",   deity: "Bhaga",      isAuspicious: true,
                   meaning: "Delight",           guidance: "A happy, fortunate yoga. Great for celebrations, entertainment, and bringing joy to others."),
        YogaDetail(index: 14, name: "Vajra",      deity: "Indra",      isAuspicious: false,
                   meaning: "Thunderbolt",       guidance: "Intense, cutting energy. Avoid rash decisions. Good for decisive, concentrated spiritual practice."),
        YogaDetail(index: 15, name: "Siddhi",     deity: "Ganesha",    isAuspicious: true,
                   meaning: "Achievement",       guidance: "Excellent for completing important tasks — whatever is started has a high chance of success."),
        YogaDetail(index: 16, name: "Vyatipata",  deity: "Vishnu",     isAuspicious: false,
                   meaning: "Calamity",          guidance: "One of the most inauspicious yogas. Rest, pray, and avoid all new important undertakings."),
        YogaDetail(index: 17, name: "Variyan",    deity: "Mitra",      isAuspicious: true,
                   meaning: "Superior",          guidance: "Comfortable, pleasant energy. Good for rest, enjoyment, and connecting with friends."),
        YogaDetail(index: 18, name: "Parigha",    deity: "Vishvakarma", isAuspicious: false,
                   meaning: "Hindrance",         guidance: "An obstructing yoga — things may hit barriers. Use this for review and preparation only."),
        YogaDetail(index: 19, name: "Shiva",      deity: "Shiva",      isAuspicious: true,
                   meaning: "Auspicious",        guidance: "Blessed by Shiva — excellent for spiritual practices, healing, and long-distance travel."),
        YogaDetail(index: 20, name: "Siddha",     deity: "Ganesha",    isAuspicious: true,
                   meaning: "Accomplished",      guidance: "High success energy. Good for completing goals, exams, and public presentations."),
        YogaDetail(index: 21, name: "Sadhya",     deity: "Chandra",    isAuspicious: true,
                   meaning: "Achievable",        guidance: "Steady, attainable energy — great for setting realistic goals and making gradual progress."),
        YogaDetail(index: 22, name: "Shubha",     deity: "Lakshmi",    isAuspicious: true,
                   meaning: "Auspicious",        guidance: "One of the most auspicious yogas — all good activities are greatly supported."),
        YogaDetail(index: 23, name: "Shukla",     deity: "Parvati",    isAuspicious: true,
                   meaning: "Bright / pure",     guidance: "Pure, luminous energy. Excellent for spiritual initiation, learning, and ceremonies of purity."),
        YogaDetail(index: 24, name: "Brahma",     deity: "Brahma",     isAuspicious: true,
                   meaning: "Creator",           guidance: "Supremely auspicious for creative work, beginning major life projects, and sacred ceremonies."),
        YogaDetail(index: 25, name: "Indra",      deity: "Indra",      isAuspicious: true,
                   meaning: "Sovereign",         guidance: "Kingly energy — excellent for leadership, authority matters, and commanding presence."),
        YogaDetail(index: 26, name: "Vaidhriti",  deity: "Varuna",     isAuspicious: false,
                   meaning: "Poorly sustained",  guidance: "The most inauspicious yoga. Rest, meditate, and avoid all important undertakings today."),
    ]
}

// MARK: - Karana Detail

struct KaranaDetail {
    let index: Int
    let name: String
    let isFixed: Bool
    let deity: String
    let guidance: String

    static func from(karanaIndex: Int) -> KaranaDetail { all[karanaIndex.clamped(to: 0...10)] }

    static let all: [KaranaDetail] = [
        KaranaDetail(index: 0,  name: "Bava",       isFixed: false, deity: "Indra",
                     guidance: "Movable; favours bold action, new beginnings, and powerful initiatives."),
        KaranaDetail(index: 1,  name: "Balava",      isFixed: false, deity: "Brahma",
                     guidance: "Movable; pleasant energy for social activities, meetings, and forming alliances."),
        KaranaDetail(index: 2,  name: "Kaulava",     isFixed: false, deity: "Mitra",
                     guidance: "Movable; good for family matters, domestic activities, and gentle beginnings."),
        KaranaDetail(index: 3,  name: "Taitila",     isFixed: false, deity: "Aryaman",
                     guidance: "Movable; supports stability in partnerships, legal work, and lasting agreements."),
        KaranaDetail(index: 4,  name: "Garija",      isFixed: false, deity: "Tvashtr",
                     guidance: "Movable; excellent for creative work, crafts, artisanship, and technical skill."),
        KaranaDetail(index: 5,  name: "Vanija",      isFixed: false, deity: "Varuna",
                     guidance: "Movable; the merchant's karana — ideal for commerce, trade, and business dealings."),
        KaranaDetail(index: 6,  name: "Vishti (Bhadra)", isFixed: false, deity: "Yama",
                     guidance: "Movable but inauspicious — avoid new starts; good only for destructive or ending work."),
        KaranaDetail(index: 7,  name: "Shakuni",     isFixed: true,  deity: "Kali",
                     guidance: "Fixed; inauspicious and ominous. Avoid important work during this karana."),
        KaranaDetail(index: 8,  name: "Chatushpada", isFixed: true,  deity: "Vishnu",
                     guidance: "Fixed; mixed results. Animal husbandry and agricultural work are supported."),
        KaranaDetail(index: 9,  name: "Naga",        isFixed: true,  deity: "Naga",
                     guidance: "Fixed; avoid new beginnings. Subtle, serpentine energy — good for inner work only."),
        KaranaDetail(index: 10, name: "Kimstughna",  isFixed: true,  deity: "Brahma",
                     guidance: "Fixed; occurs at the beginning of the bright fortnight. Generally considered auspicious for sacred beginnings."),
    ]
}
