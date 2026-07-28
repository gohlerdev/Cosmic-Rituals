import Foundation

enum PoojaCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case daily
    case deity
    case festival
    case vrata
    case lifeEvent
    case planetary

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .deity: return "Deity"
        case .festival: return "Festival"
        case .vrata: return "Vrata"
        case .lifeEvent: return "Life event"
        case .planetary: return "Planetary"
        }
    }

    var symbol: String {
        switch self {
        case .daily: return "sunrise.fill"
        case .deity: return "sparkles"
        case .festival: return "flame.fill"
        case .vrata: return "moon.stars.fill"
        case .lifeEvent: return "house.fill"
        case .planetary: return "circle.hexagongrid.fill"
        }
    }
}

enum PoojaPracticeLevel: String, Hashable, Sendable {
    case simpleHousehold
    case extendedHousehold
    case priestRecommended

    var displayName: String {
        switch self {
        case .simpleHousehold: return "Simple household"
        case .extendedHousehold: return "Extended household"
        case .priestRecommended: return "Priest recommended"
        }
    }

    var guidance: String {
        switch self {
        case .simpleHousehold:
            return "A respectful home sequence using public name-mantras and simple offerings."
        case .extendedHousehold:
            return "Suitable at home when the family already observes this practice; a priest may guide local variations."
        case .priestRecommended:
            return "This guide prepares the household and explains the sequence. Formal sankalpa, homa, nyasa, and lineage mantras should be led by a qualified priest."
        }
    }
}

struct PoojaMaterial: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let purpose: String
    let isRequired: Bool
    let alternative: String?
}

struct PoojaMantra: Hashable, Sendable {
    let title: String
    let devanagari: String
    let transliteration: String
    let meaning: String
    let repetition: String
}

struct PoojaStep: Identifiable, Hashable, Sendable {
    let number: Int
    let title: String
    let instruction: String
    let mantra: PoojaMantra?
    let note: String?
    let estimatedMinutes: Int

    var id: Int { number }
}

struct PoojaSourceNote: Identifiable, Hashable, Sendable {
    let title: String
    let detail: String
    let urlString: String

    var id: String { urlString }
}

/// A factual, derived preparation state. It deliberately avoids a single
/// decorative "confidence" score: readiness depends on concrete materials,
/// the practice boundary, and visible source context.
struct PoojaReadiness: Equatable, Sendable {
    let requiredMaterialCount: Int
    let preparedRequiredMaterialCount: Int
    let optionalMaterialCount: Int
    let preparedOptionalMaterialCount: Int
    let sourceCount: Int
    let practiceLevel: PoojaPracticeLevel

    var remainingRequiredMaterialCount: Int {
        max(0, requiredMaterialCount - preparedRequiredMaterialCount)
    }

    var requiredPreparationProgress: Double {
        guard requiredMaterialCount > 0 else { return 1 }
        return Double(preparedRequiredMaterialCount) / Double(requiredMaterialCount)
    }

    var hasPreparedRequiredMaterials: Bool {
        remainingRequiredMaterialCount == 0
    }

    var materialStatus: String {
        if hasPreparedRequiredMaterials {
            switch requiredMaterialCount {
            case 0:
                return "No required materials"
            case 1:
                return "Required material marked ready"
            default:
                return "All \(requiredMaterialCount) required materials marked ready"
            }
        }
        let noun = remainingRequiredMaterialCount == 1 ? "item" : "items"
        return "\(remainingRequiredMaterialCount) required \(noun) left to review"
    }

    var practiceStatus: String {
        practiceLevel == .priestRecommended
            ? "Qualified practitioner recommended"
            : practiceLevel.displayName
    }

    var sourceStatus: String {
        let noun = sourceCount == 1 ? "reference" : "references"
        return "\(sourceCount) cited \(noun) · reviewed \(PoojaContentPolicy.sourceReviewDate)"
    }
}

struct PoojaVidhi: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let sacredFocus: String
    let summary: String
    let purpose: String
    let category: PoojaCategory
    let practiceLevel: PoojaPracticeLevel
    let durationMinutes: ClosedRange<Int>
    let occasions: [String]
    let preparation: [String]
    let materials: [PoojaMaterial]
    let steps: [PoojaStep]
    let completion: [String]
    let safetyNotes: [String]
    let traditionNote: String
    let sourceNotes: [PoojaSourceNote]

    var durationText: String {
        if durationMinutes.lowerBound == durationMinutes.upperBound {
            return "\(durationMinutes.lowerBound) min"
        }
        return "\(durationMinutes.lowerBound)–\(durationMinutes.upperBound) min"
    }

    var searchableText: String {
        ([title, sacredFocus, summary, purpose, category.displayName, practiceLevel.displayName]
            + occasions
            + preparation
            + materials.flatMap { [$0.name, $0.purpose, $0.alternative ?? ""] }
            + steps.flatMap { step in
                [step.title, step.instruction, step.note ?? "", step.mantra?.devanagari ?? "",
                 step.mantra?.transliteration ?? "", step.mantra?.meaning ?? ""]
            })
            .joined(separator: " ")
    }

    func readiness(preparedMaterialIDs: Set<String>) -> PoojaReadiness {
        let required = materials.filter(\.isRequired)
        let optional = materials.filter { !$0.isRequired }
        return PoojaReadiness(
            requiredMaterialCount: required.count,
            preparedRequiredMaterialCount: required.filter { preparedMaterialIDs.contains($0.id) }.count,
            optionalMaterialCount: optional.count,
            preparedOptionalMaterialCount: optional.filter { preparedMaterialIDs.contains($0.id) }.count,
            sourceCount: sourceNotes.count,
            practiceLevel: practiceLevel
        )
    }

    var shareText: String {
        """
        \(title) · \(durationText)
        \(summary)

        \(steps.map { "\($0.number). \($0.title): \($0.instruction)" }.joined(separator: "\n"))

        Household reference from Cosmic Rituals. Family, temple, and sampradaya practice may differ.
        """
    }
}

enum PoojaContentPolicy {
    static let sourceReviewDate = "2026-07-28"
    static let reviewStatus = "Source-adapted household reference, not a sampradaya-specific certification. Confirm formal rites and received practice with a qualified practitioner."
    static let householdScope = "These are inclusive household reference sequences, not claims of one universal or canonical Pooja Vidhi. Family, temple, regional, and sampradaya practice takes precedence."
    static let inclusionScope = "The app does not restrict participation by caste, gender, menstruation, marital status, or birth. A person may sit, stand, bow, or adapt movements for safety, disability, age, and comfort."
    static let mantraScope = "Only short public name-mantras are used. Initiatory bija-mantras, nyasa, fire rites, and lineage-restricted recitations are intentionally omitted. Meaning is shown so a person may pray in a familiar language if Sanskrit pronunciation is uncertain."
    static let safetyScope = "A flame, incense, water, food, and flowers are optional when unsafe or unavailable. Never leave a flame unattended, keep smoke away from sensitive people and animals, and check food offerings for allergies before sharing prasada."
}

enum PoojaVidhiCatalog {
    private static let householdPujaSource = PoojaSourceNote(
        title: "Himalayan Academy · Home Puja",
        detail: "Used for the common preparation, offering, prasada, and quiet-closing pattern. Its detailed Ganesha rite is Saiva-lineage specific and is not generalized here.",
        urlString: "https://www.himalayanacademy.com/media/books/home-puja_ei/web/ch24a.html"
    )

    private static let dailyPracticeSource = PoojaSourceNote(
        title: "BAPS Swaminarayan Sanstha · Daily Puja",
        detail: "Used as a second reference for cleanliness, a steady daily practice, meditation, prayer, and respectful closure. Sect-specific elements remain identified as such and are not copied into the general sequence.",
        urlString: "https://www.baps.org/Spiritual-Living/Hindu-Practices/Daily-Puja.aspx"
    )

    private static let lakshmiSource = PoojaSourceNote(
        title: "Drik Panchang · Lakshmi Shodashopachara Puja",
        detail: "Used to check the traditional progression from dhyana and avahana through offerings and closure. The app presents a shorter household Panchopachara form, not the full sixteen-offering rite.",
        urlString: "https://www.drikpanchang.com/festivals/lakshmipuja/info/lakshmi-puja-vidhi.html"
    )

    private static let navratriSource = PoojaSourceNote(
        title: "Drik Panchang · Durga Puja Vidhi",
        detail: "Used to confirm the broad Navratri worship progression. Ghatasthapana and lineage-specific Shodashopachara mantras are outside the simple household guide.",
        urlString: "https://www.drikpanchang.com/navratri/durga-puja/puja-vidhi/durga-puja-vidhi.html"
    )

    private static let satyanarayanaSource = PoojaSourceNote(
        title: "Drik Panchang · Satyanarayana Puja Vidhi",
        detail: "Used to check the Vishnu-centered vrata sequence. A complete vrata includes the locally received katha and may include priest-led steps.",
        urlString: "https://www.drikpanchang.com/hindu-gods/trimurti/lord-vishnu/puja-vidhi/satyanarayan-puja-vidhi.html"
    )

    static let all: [PoojaVidhi] = [
        householdVidhi(
            id: "daily-panchopachara",
            title: "Daily Panchopachara Pooja",
            sacredFocus: "Ishta Devata",
            summary: "A calm, compact daily practice of centering, intention, five symbolic offerings, prayer, and respectful closure.",
            purpose: "Daily devotion, gratitude, and a steady home-shrine rhythm.",
            category: .daily,
            practiceLevel: .simpleHousehold,
            duration: 8...15,
            occasions: ["Every day", "Morning prayer", "Evening prayer", "Gratitude"],
            specificMaterials: [],
            focusPreparation: "Place the murti or image of your chosen form of the Divine on a clean, stable surface.",
            invocation: "With folded hands, welcome your Ishta Devata in the way your family uses. If you have no received invocation, a sincere welcome in your own language is sufficient.",
            offering: "Offer fragrance or sandalwood, one flower, incense if suitable, a safely placed lamp, and a small food or water offering. Each is optional when unavailable.",
            mantra: PoojaMantra(
                title: "Universal offering prayer",
                devanagari: "ॐ नमः",
                transliteration: "Om namaḥ",
                meaning: "Reverence to the Divine.",
                repetition: "Repeat slowly 3, 9, or 11 times"
            ),
            closingPrayer: "Offer gratitude, ask forgiveness for errors, bow, and sit quietly before returning to the day.",
            traditionNote: "Panchopachara names five modes of hospitality; their exact order and substances vary. This neutral home sequence does not replace a received family paddhati.",
            sources: [householdPujaSource, dailyPracticeSource]
        ),
        householdVidhi(
            id: "ganesha-home",
            title: "Shri Ganesha Pooja",
            sacredFocus: "Ganesha",
            summary: "A simple home Pooja honoring Ganesha before a new undertaking or as a regular devotional practice.",
            purpose: "Clarity, an auspicious beginning, humility, and removal of inner obstacles.",
            category: .deity,
            practiceLevel: .simpleHousehold,
            duration: 15...25,
            occasions: ["New beginning", "Before study", "Before travel", "Ganesha Chaturthi", "Wednesday"],
            specificMaterials: [
                material("durva", "Durva grass or a fresh flower", "Traditional Ganesha offering", required: false, alternative: "Any clean, respectfully offered flower"),
                material("modaka", "Modaka or a simple sweet", "Naivedya", required: false, alternative: "Fruit or water")
            ],
            focusPreparation: "Place a Ganesha murti or image on a clean altar. Keep liquids away from paper images and electronics.",
            invocation: "Contemplate Ganesha as compassionate wisdom. Invite his presence with folded hands; elaborate avahana mudras are not required for this household form.",
            offering: "Offer sandalwood or fragrance, durva or a flower, incense if appropriate, lamp light, and fruit or a sweet.",
            mantra: PoojaMantra(
                title: "Ganesha name-mantra",
                devanagari: "ॐ गणपतये नमः",
                transliteration: "Om gaṇapataye namaḥ",
                meaning: "Reverence to Ganapati, lord of the hosts.",
                repetition: "Repeat 11 or 21 times, without rushing"
            ),
            closingPrayer: "Pray for wisdom to recognize and work through obstacles, perform a gentle namaskara, and share the offering as prasada.",
            traditionNote: "This is a short public household form. The longer Sanskrit Ganesha Pooja published by Himalayan Academy belongs to a specific Saiva teaching context and should be learned from that source or a teacher.",
            sources: [householdPujaSource]
        ),
        householdVidhi(
            id: "lakshmi-home",
            title: "Mahalakshmi Pooja",
            sacredFocus: "Mahalakshmi",
            summary: "A household Lakshmi Pooja centered on gratitude, ethical abundance, hospitality, and care for the home.",
            purpose: "Gratitude for sustenance and a prayer for well-being, generosity, and wise stewardship.",
            category: .deity,
            practiceLevel: .simpleHousehold,
            duration: 20...30,
            occasions: ["Friday", "Diwali", "Varalakshmi Vrata", "At home", "New home", "Prosperity", "Gratitude"],
            specificMaterials: [
                material("lotus", "Lotus or another fresh flower", "Floral offering", required: false, alternative: "A clean local flower"),
                material("coin", "Clean coin or account book", "Symbol of responsible resources", required: false, alternative: nil),
                material("sweet", "Fruit or vegetarian sweet", "Naivedya", required: false, alternative: "Water")
            ],
            focusPreparation: "Clean the worship area and place Lakshmi's murti or image securely. Treat cleaning as preparation, not as a guarantee of material gain.",
            invocation: "Meditate on Lakshmi seated on a lotus, embodying auspiciousness, generosity, beauty, and well-being. Welcome her with folded hands.",
            offering: "Offer fragrance, a flower, gentle incense if suitable, lamp light, and fruit or a sweet. Full bathing and sixteen-offering rites are omitted from this home guide.",
            mantra: PoojaMantra(
                title: "Lakshmi name-mantra",
                devanagari: "ॐ महालक्ष्म्यै नमः",
                transliteration: "Om mahālakṣmyai namaḥ",
                meaning: "Reverence to Mahalakshmi.",
                repetition: "Repeat 11 or 21 times with attention to meaning"
            ),
            closingPrayer: "Express gratitude, commit to a concrete act of generosity or responsible care, offer namaskara, and share prasada.",
            traditionNote: "The full Diwali Shodashopachara sequence contains sixteen formal offerings and longer mantras. This app intentionally provides a shorter Panchopachara household form.",
            sources: [lakshmiSource, householdPujaSource]
        ),
        householdVidhi(
            id: "shiva-home",
            title: "Shiva Pooja",
            sacredFocus: "Shiva",
            summary: "A contemplative Shiva Pooja using water, bilva or flowers, lamp light, mantra, and silence.",
            purpose: "Stillness, self-reflection, compassion, and release of unhelpful habits.",
            category: .deity,
            practiceLevel: .simpleHousehold,
            duration: 15...30,
            occasions: ["Monday", "Pradosha", "Mahashivaratri", "Meditation", "Peace"],
            specificMaterials: [
                material("bilva", "Bilva leaves", "Traditional Shiva offering", required: false, alternative: "A clean flower or leaf accepted in your family tradition"),
                material("abhisheka-water", "Separate clean water", "Optional abhisheka for a suitable Shiva Linga", required: false, alternative: nil)
            ],
            focusPreparation: "Use a stable Shiva murti, image, or a Shiva Linga already worshipped in your household. Never pour liquid over a framed image or electrical surface.",
            invocation: "Sit quietly and contemplate Shiva as auspicious stillness and compassionate awareness. Welcome the Divine presence without attempting lineage-specific nyasa.",
            offering: "If your household custom permits, offer a small stream of clean water to a suitable Linga over a catch tray. Otherwise offer water symbolically, then fragrance, bilva or a flower, lamp light, and fruit.",
            mantra: PoojaMantra(
                title: "Shiva name-mantra",
                devanagari: "ॐ शिवाय नमः",
                transliteration: "Om śivāya namaḥ",
                meaning: "Reverence to Shiva, the auspicious one.",
                repetition: "Repeat 11, 21, or 108 times according to comfort"
            ),
            closingPrayer: "Rest in silence, ask that insight become compassionate action, bow, and respectfully clear any offered water.",
            traditionNote: "Abhisheka substances and rules differ widely. This guide uses only clean water and makes abhisheka optional; follow the practice received from your family or temple.",
            sources: [householdPujaSource]
        ),
        householdVidhi(
            id: "vishnu-home",
            title: "Vishnu Pooja",
            sacredFocus: "Vishnu or Narayana",
            summary: "A simple Vishnu Pooja of welcome, Tulsi or flowers, lamp, naivedya, mantra, and gratitude.",
            purpose: "Steadiness, preservation of dharma, gratitude, and service.",
            category: .deity,
            practiceLevel: .simpleHousehold,
            duration: 15...25,
            occasions: ["Thursday", "Ekadashi", "Vaikuntha Ekadashi", "Peace", "Family prayer"],
            specificMaterials: [
                material("tulsi", "Tulsi leaf", "Traditional Vishnu offering", required: false, alternative: "A clean flower accepted in your tradition"),
                material("fruit-vishnu", "Fruit or simple sattvic food", "Naivedya", required: false, alternative: "Water")
            ],
            focusPreparation: "Place a Vishnu or Narayana murti or image on a clean, stable altar. Prepare food without ingredients your family excludes from worship.",
            invocation: "Contemplate Vishnu as the sustaining presence within life and welcome him with folded hands.",
            offering: "Offer water, sandalwood or fragrance, Tulsi or a flower, incense if suitable, lamp light, and naivedya.",
            mantra: PoojaMantra(
                title: "Vishnu name-mantra",
                devanagari: "ॐ विष्णवे नमः",
                transliteration: "Om viṣṇave namaḥ",
                meaning: "Reverence to Vishnu.",
                repetition: "Repeat 11 or 21 times"
            ),
            closingPrayer: "Pray for the strength to uphold what sustains life, offer namaskara, and share prasada mindfully.",
            traditionNote: "Vaishnava sampradayas differ in mantra, tilaka, food rules, and offering sequence. Those received practices take precedence over this general guide.",
            sources: [householdPujaSource]
        ),
        householdVidhi(
            id: "durga-navratri-home",
            title: "Durga & Navratri Pooja",
            sacredFocus: "Durga",
            summary: "A simple daily Navratri or household Durga Pooja focused on courage, compassionate protection, and disciplined devotion.",
            purpose: "Courage, protection, dignity, and reverence for the Divine Mother.",
            category: .festival,
            practiceLevel: .extendedHousehold,
            duration: 20...35,
            occasions: ["Navratri", "Friday", "Ashtami", "Durga Puja", "Protection", "Courage"],
            specificMaterials: [
                material("red-flower", "Red or seasonal flower", "Floral offering", required: false, alternative: "Any clean flower"),
                material("kalasha", "Kalasha and sprouting grains", "Optional Navratri observance", required: false, alternative: "Omit unless this is an established household practice")
            ],
            focusPreparation: "Place Durga's murti or image securely. If maintaining a Navratri kalasha, follow the practice learned from your family or priest rather than improvising installation or visarjana.",
            invocation: "Contemplate Durga as compassionate strength that protects dignity and dharma. Welcome her in your own words or with the public name-mantra below.",
            offering: "Offer water, fragrance, a red or seasonal flower, incense if suitable, lamp light, and fruit or a simple sweet.",
            mantra: PoojaMantra(
                title: "Durga name-mantra",
                devanagari: "ॐ दुर्गायै नमः",
                transliteration: "Om durgāyai namaḥ",
                meaning: "Reverence to Durga.",
                repetition: "Repeat 11 or 21 times"
            ),
            closingPrayer: "Pray that strength be joined with compassion, offer namaskara, and conclude without moving an installed kalasha casually.",
            traditionNote: "Navratri forms, fasting, Ghatasthapana, Kumari Puja, and visarjana vary by region and lineage. Fasting is optional and is not prescribed by this app; health needs take priority.",
            sources: [navratriSource, householdPujaSource]
        ),
        householdVidhi(
            id: "hanuman-home",
            title: "Hanuman Pooja",
            sacredFocus: "Hanuman",
            summary: "A home Pooja honoring Hanuman through simple offerings, name-mantra, prayer, and optional familiar devotional reading.",
            purpose: "Courage, disciplined service, resilience, and devotion.",
            category: .deity,
            practiceLevel: .simpleHousehold,
            duration: 15...30,
            occasions: ["Tuesday", "Saturday", "Hanuman Jayanti", "Courage", "Service"],
            specificMaterials: [
                material("hanuman-flower", "Red or orange flower", "Floral offering", required: false, alternative: "Any clean flower"),
                material("hanuman-reading", "Hanuman Chalisa or a familiar prayer book", "Optional devotional reading", required: false, alternative: nil)
            ],
            focusPreparation: "Place Hanuman's murti or image on a clean altar. Do not apply oil or sindoor to a murti unless its material and your established custom allow it.",
            invocation: "Contemplate Hanuman as strength guided by humility and selfless service, then welcome him with folded hands.",
            offering: "Offer water, fragrance, a flower, lamp light, and fruit. Read a familiar prayer only if you can do so respectfully and without rushing.",
            mantra: PoojaMantra(
                title: "Hanuman name-mantra",
                devanagari: "ॐ हनुमते नमः",
                transliteration: "Om hanumate namaḥ",
                meaning: "Reverence to Hanuman.",
                repetition: "Repeat 11 or 21 times"
            ),
            closingPrayer: "Ask for strength to serve wisely, offer namaskara, and carry one act of disciplined kindness into the day.",
            traditionNote: "Offerings and longer recitations differ by region. This guide deliberately does not prescribe sindoor, oil, or restricted ritual applications.",
            sources: [householdPujaSource]
        ),
        householdVidhi(
            id: "saraswati-home",
            title: "Saraswati Pooja",
            sacredFocus: "Saraswati",
            summary: "A gentle Pooja for learning, music, language, discernment, and respectful use of knowledge.",
            purpose: "Clarity in learning, creativity, truthful speech, and humility before knowledge.",
            category: .deity,
            practiceLevel: .simpleHousehold,
            duration: 15...25,
            occasions: ["Vasant Panchami", "Before study", "New course", "Music", "Examination", "Learning"],
            specificMaterials: [
                material("book", "Book, notebook, or instrument", "Symbol of learning", required: false, alternative: nil),
                material("white-flower", "White or pale flower", "Floral offering", required: false, alternative: "Any clean flower")
            ],
            focusPreparation: "Place Saraswati's image and the book or instrument nearby on a clean cloth. Keep food, water, oil, and flame safely separated from books and instruments.",
            invocation: "Contemplate Saraswati as wisdom, language, music, and clear discernment. Welcome her with folded hands.",
            offering: "Offer fragrance, a flower, safely placed lamp light, and fruit or water. Touch the learning object only with clean, dry hands.",
            mantra: PoojaMantra(
                title: "Saraswati name-mantra",
                devanagari: "ॐ सरस्वत्यै नमः",
                transliteration: "Om sarasvatyai namaḥ",
                meaning: "Reverence to Saraswati.",
                repetition: "Repeat 11 or 21 times"
            ),
            closingPrayer: "Pray to use knowledge truthfully and for benefit, bow, then begin a short period of attentive study or practice.",
            traditionNote: "Vasant Panchami customs differ across regions and schools. This is a simple devotional guide, not a substitute for a school or family ceremony.",
            sources: [householdPujaSource]
        ),
        suryaArghya,
        satyanarayana,
        grihaPravesh,
        navagraha
    ]

    static func vidhi(id: String) -> PoojaVidhi? {
        all.first { $0.id == id }
    }

    static func search(_ query: String, category: PoojaCategory? = nil) -> [PoojaVidhi] {
        let candidates = category.map { selected in all.filter { $0.category == selected } } ?? all
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return candidates }
        let tokens = normalizedQuery.split(separator: " ").map(String.init)

        return candidates
            .filter { vidhi in
                let corpus = normalized(vidhi.searchableText)
                return tokens.allSatisfy(corpus.contains)
            }
            .sorted { lhs, rhs in
                let lhsTitle = normalized(lhs.title)
                let rhsTitle = normalized(rhs.title)
                let lhsPrefix = lhsTitle.hasPrefix(normalizedQuery)
                let rhsPrefix = rhsTitle.hasPrefix(normalizedQuery)
                if lhsPrefix != rhsPrefix { return lhsPrefix }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    static var validationIssues: [String] {
        var issues: [String] = []
        let ids = all.map(\.id)
        if Set(ids).count != ids.count { issues.append("Catalog IDs must be unique") }

        for vidhi in all {
            if vidhi.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("\(vidhi.id): title is empty")
            }
            if vidhi.steps.count < 8 { issues.append("\(vidhi.id): fewer than eight steps") }
            if vidhi.materials.count < 5 { issues.append("\(vidhi.id): incomplete materials") }
            if vidhi.sourceNotes.isEmpty { issues.append("\(vidhi.id): missing source transparency") }
            if vidhi.safetyNotes.isEmpty { issues.append("\(vidhi.id): missing safety notes") }
            if vidhi.steps.map(\.number) != Array(1...vidhi.steps.count) {
                issues.append("\(vidhi.id): steps are not sequential")
            }
            for step in vidhi.steps {
                if let mantra = step.mantra,
                   [mantra.devanagari, mantra.transliteration, mantra.meaning, mantra.repetition]
                    .contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    issues.append("\(vidhi.id): incomplete mantra at step \(step.number)")
                }
            }
        }
        return issues
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func householdVidhi(
        id: String,
        title: String,
        sacredFocus: String,
        summary: String,
        purpose: String,
        category: PoojaCategory,
        practiceLevel: PoojaPracticeLevel,
        duration: ClosedRange<Int>,
        occasions: [String],
        specificMaterials: [PoojaMaterial],
        focusPreparation: String,
        invocation: String,
        offering: String,
        mantra: PoojaMantra,
        closingPrayer: String,
        traditionNote: String,
        sources: [PoojaSourceNote]
    ) -> PoojaVidhi {
        PoojaVidhi(
            id: id,
            title: title,
            sacredFocus: sacredFocus,
            summary: summary,
            purpose: purpose,
            category: category,
            practiceLevel: practiceLevel,
            durationMinutes: duration,
            occasions: occasions,
            preparation: [
                "Choose a time when you can remain unhurried and attentive.",
                "Bathe or wash hands and face, wear clean clothing, and clean the worship surface.",
                focusPreparation,
                "Gather every item before lighting a lamp so the ritual is not left unattended."
            ],
            materials: commonMaterials + specificMaterials,
            steps: [
                step(1, "Prepare the sacred space", focusPreparation, minutes: 2),
                step(2, "Settle and centre", "Sit or stand comfortably. Take three natural breaths, reduce distractions, and bring attention to the sacred focus.", note: "No breath retention or forceful breathing is required.", minutes: 1),
                step(3, "Purify symbolically", "Sprinkle a few drops of clean water around the offering area or simply hold the intention of cleanliness when water is unsuitable.", minutes: 1),
                step(4, "State the sankalpa", "Name the place, day, your name if desired, and a clear devotional intention. Avoid promises or vows you may not be able to keep.", note: "A sincere statement in your own language is valid for this household guide.", minutes: 2),
                step(5, "Remember Ganesha and the teachers", "Offer a brief namaskara to Ganesha, your family tradition, teachers, and all who preserved the practice. This is remembrance, not a separate elaborate rite.", minutes: 1),
                step(6, "Dhyana and welcome", invocation, minutes: 2),
                step(7, "Offer respectful hospitality", offering, note: "Offer only what is clean, safe, and permitted in your household practice.", minutes: 4),
                step(8, "Recite with meaning", "Read the mantra once before repeating it. Pronounce gently; if uncertain, pray using its meaning in a language you know.", mantra: mantra, minutes: 4),
                step(9, "Offer naivedya and quiet prayer", "Place the food or water offering before the sacred focus. Pause quietly; do not taste it before offering.", note: "Keep allergens separate and never give unsafe foods to children or animals.", minutes: 2),
                step(10, "Show the light safely", "If a lamp is lit, move it in small clockwise circles at a safe distance, or simply hold folded hands before a stationary lamp. A battery lamp or no flame is acceptable.", note: "Keep hair, sleeves, decorations, children, and animals away from flame.", minutes: 2),
                step(11, "Pray and offer namaskara", closingPrayer, minutes: 2),
                step(12, "Close and share prasada", "Thank the sacred presence, sit quietly for a moment, extinguish unsafe flames without leaving smoke, and share the offering respectfully.", note: "Do not discard ritual water, flowers, oil, or food where they create litter, plumbing problems, fire risk, or harm to wildlife.", minutes: 2)
            ],
            completion: [
                "Sit quietly for at least a few breaths before clearing the altar.",
                "Share safe food offerings as prasada; refrigerate perishables promptly.",
                "Return reusable items clean and dry. Compost flowers only where locally appropriate.",
                "Let the intention continue through one concrete, ethical action."
            ],
            safetyNotes: [PoojaContentPolicy.safetyScope, "Do not ingest ash, oils, powders, flowers, or ritual water unless you know they are food-safe."],
            traditionNote: traditionNote,
            sourceNotes: sources
        )
    }

    private static var commonMaterials: [PoojaMaterial] {
        [
            material("focus", "Murti, image, or other sacred focus", "A stable focus for devotion", required: true, alternative: "A clean, empty space used with reverence"),
            material("water", "Clean water and a small spoon", "Symbolic purification and offering", required: false, alternative: "Omit where spills are unsafe"),
            material("flower", "Fresh flower, petals, or a clean leaf", "Floral offering", required: false, alternative: "A mental offering"),
            material("lamp", "Stable oil/ghee lamp or battery lamp", "Light offering", required: false, alternative: "No flame"),
            material("incense", "Incense with a fireproof holder", "Fragrance offering", required: false, alternative: "Sandalwood paste, a flower, or no fragrance"),
            material("naivedya", "Fruit, simple vegetarian food, or water", "Naivedya and prasada", required: false, alternative: "Clean water")
        ]
    }

    private static let suryaArghya = PoojaVidhi(
        id: "surya-arghya",
        title: "Surya Arghya",
        sacredFocus: "Surya",
        summary: "A short sunrise practice offering water with gratitude for light, time, health-supporting routine, and life.",
        purpose: "Gratitude, disciplined morning attention, and reverence for the visible Sun.",
        category: .daily,
        practiceLevel: .simpleHousehold,
        durationMinutes: 5...10,
        occasions: ["Sunrise", "Sunday", "Daily practice", "Gratitude"],
        preparation: ["Choose a safe, non-slip place with drainage or use a basin indoors.", "Know the local sunrise from the app, but do not look directly at the Sun.", "Use a small amount of clean water."],
        materials: [
            material("surya-water", "Small vessel of clean water", "Arghya", required: true, alternative: "A symbolic folded-hands offering when water cannot be poured"),
            material("surya-basin", "Basin or safe soil area", "Collects the water without creating a slip hazard", required: true, alternative: nil),
            material("surya-flower", "Flower", "Optional offering", required: false, alternative: "Mental offering"),
            material("surya-cloth", "Clean cloth", "Dry hands and any spills", required: false, alternative: nil),
            material("surya-focus", "Open sky or a well-lit window", "Direction of attention", required: false, alternative: "Face east without viewing the Sun")
        ],
        steps: [
            step(1, "Choose a safe place", "Stand where poured water cannot make a walkway slippery or contaminate shared space.", minutes: 1),
            step(2, "Face the morning light", "Face east around local sunrise. Keep your gaze below or away from the Sun; never stare at it.", minutes: 1),
            step(3, "Set the intention", "Offer gratitude for light, time, warmth, and the conditions that support life.", minutes: 1),
            step(4, "Hold the water", "Hold a small vessel steadily with both hands at chest level.", minutes: 1),
            step(5, "Recite the name-mantra", "Recite gently or use its meaning in your own language.", mantra: PoojaMantra(title: "Surya name-mantra", devanagari: "ॐ सूर्याय नमः", transliteration: "Om sūryāya namaḥ", meaning: "Reverence to Surya.", repetition: "Repeat 3 or 11 times"), minutes: 2),
            step(6, "Offer the water", "Pour a thin stream into the basin or safe soil while keeping eyes away from direct sunlight.", note: "Do not pour from balconies, into public walkways, or where water can damage property.", minutes: 1),
            step(7, "Offer namaskara", "Bring palms together and bow gently.", minutes: 1),
            step(8, "Close responsibly", "Wipe spills, reuse collected clean water where appropriate, and leave the place safe.", minutes: 1)
        ],
        completion: ["Carry the practice into a consistent, safe morning routine.", "Do not interpret the ritual as medical treatment or a substitute for sun-safety guidance."],
        safetyNotes: ["Never look directly at the Sun. This app does not provide eye-safety or medical advice.", "Prevent slips and do not pour water where it may fall on people, property, or electrical equipment."],
        traditionNote: "Surya worship has Vedic, Puranic, yogic, and regional forms. This is a minimal public name-mantra and water-offering practice, not Sandhyavandana or a Vedic rite.",
        sourceNotes: [householdPujaSource]
    )

    private static let satyanarayana = PoojaVidhi(
        id: "satyanarayana-vrata",
        title: "Satyanarayana Vrata Pooja",
        sacredFocus: "Satyanarayana, a form of Vishnu",
        summary: "A preparation-aware guide to the Vishnu-centered vrata, including worship, katha, naivedya, community participation, and closure.",
        purpose: "Gratitude, truthfulness, family prayer, and fulfillment of a consciously undertaken vrata.",
        category: .vrata,
        practiceLevel: .priestRecommended,
        durationMinutes: 60...120,
        occasions: ["Purnima", "Family milestone", "Thanksgiving", "New beginning", "Vrata"],
        preparation: ["Confirm the date, form of sankalpa, katha text, and food practice with the priest or family tradition.", "Invite participants without pressuring anyone to fast.", "Plan safe seating, food hygiene, and enough time for the complete katha."],
        materials: commonMaterials + [
            material("satya-katha", "Received Satyanarayana Katha text", "Essential narrative recitation", required: true, alternative: "Arrange a priest or trusted family reader"),
            material("satya-kalasha", "Kalasha materials", "Used in many established forms", required: false, alternative: "Follow the officiant's list"),
            material("satya-prasada", "Family-tradition prasada ingredients", "Naivedya and distribution", required: true, alternative: "Adapt allergens with the officiant before the vrata")
        ],
        steps: [
            step(1, "Confirm the received procedure", "Agree on the vrata text, sankalpa, language, food rules, and officiant before the day.", minutes: 5),
            step(2, "Prepare the home and altar", "Clean the area, arrange safe seating, and gather the complete materials list.", minutes: 10),
            step(3, "State the sankalpa", "The officiant or family elder states the intention without making coercive or impossible promises.", minutes: 5),
            step(4, "Begin with Ganesha remembrance", "Offer a brief Ganesha prayer according to the received procedure.", minutes: 5),
            step(5, "Kalasha and Vishnu worship", "Follow the officiant for kalasha installation and the chosen Vishnu or Satyanarayana offering sequence.", note: "Do not improvise Vedic or lineage mantras from the app.", minutes: 20),
            step(6, "Recite the public name-mantra", "Use the name-mantra during a pause if it agrees with the officiant's procedure.", mantra: PoojaMantra(title: "Satyanarayana name-mantra", devanagari: "ॐ सत्यनारायणाय नमः", transliteration: "Om satyanārāyaṇāya namaḥ", meaning: "Reverence to Satyanarayana.", repetition: "As directed, or 11 times in a simple household pause"), minutes: 5),
            step(7, "Listen to the complete katha", "Read or hear the complete locally received Satyanarayana Katha attentively; do not replace it with an app-generated summary.", minutes: 30),
            step(8, "Offer naivedya and arati", "Present the prepared food and light safely according to the household procedure.", minutes: 10),
            step(9, "Pray for truthful living", "Connect the vrata to honest speech, responsible action, gratitude, and service.", minutes: 5),
            step(10, "Complete and share prasada", "Close through the officiant's visarjana or concluding prayer, then distribute prasada with allergy awareness.", minutes: 10)
        ],
        completion: ["Complete the whole katha form agreed at sankalpa.", "Share prasada without food pressure.", "Fulfill only the ethical, practical commitments consciously made."],
        safetyNotes: [PoojaContentPolicy.safetyScope, "Fasting is not required by this app. Health needs, medication schedules, pregnancy, age, and eating-disorder risk take priority."],
        traditionNote: "Vrata details and katha recensions differ. This app explains the structure but intentionally does not synthesize a supposedly universal katha or priestly mantra sequence.",
        sourceNotes: [satyanarayanaSource, householdPujaSource]
    )

    private static let grihaPravesh = PoojaVidhi(
        id: "griha-pravesh",
        title: "Griha Pravesh Preparation",
        sacredFocus: "The Divine, Vastu Purusha, and household deities",
        summary: "A truthful household preparation and ceremony map for entering a new home, with formal rites clearly reserved for a qualified priest.",
        purpose: "Gratitude, a mindful beginning, household safety, hospitality, and prayer for harmonious living.",
        category: .lifeEvent,
        practiceLevel: .priestRecommended,
        durationMinutes: 60...180,
        occasions: ["New home", "First entry", "Housewarming", "Vastu Shanti", "Life event"],
        preparation: ["Confirm that the property is legally accessible, structurally safe, ventilated, and has working utilities.", "Choose the muhurta using the home's exact location and the family's tradition; the app's general Panchang is not a substitute for a complete electional chart.", "Ask the officiant for the exact materials, fire-safety plan, and local smoke rules."],
        materials: commonMaterials + [
            material("griha-keys", "Keys and essential property documents", "Practical readiness", required: true, alternative: nil),
            material("griha-safety", "Fireproof homa area and extinguisher if homa is planned", "Fire safety", required: true, alternative: "Omit homa where unsafe or prohibited"),
            material("griha-kalasha", "Kalasha and doorway items", "Tradition-specific entry observance", required: false, alternative: "Use the officiant's list")
        ],
        steps: [
            step(1, "Complete practical safety checks", "Verify permission to enter, utilities, ventilation, alarms, exits, and a clear walking path before ritual decoration.", minutes: 10),
            step(2, "Confirm muhurta and officiant", "Provide the exact address, time zone, household details, and tradition to the qualified person choosing the formal time.", minutes: 5),
            step(3, "Clean without creating hazards", "Clean the entrance and worship area; secure rangoli, cords, lamps, and vessels so no one can trip.", minutes: 10),
            step(4, "Prepare the doorway welcome", "Arrange the locally received doorway observance and enter in the order guided by the family or officiant.", minutes: 5),
            step(5, "Begin with Ganesha remembrance", "Offer a simple prayer for clarity and a safe beginning.", minutes: 5),
            step(6, "Perform kalasha or Vastu worship", "Follow the officiant for kalasha sthapana, Vastu Puja, Navagraha Puja, or other formal components.", note: "These components vary and are not generated by the app.", minutes: 30),
            step(7, "Conduct homa only when safe", "A trained officiant manages any fire rite under property rules with ventilation and extinguishing equipment.", note: "Never improvise an indoor homa from written app steps.", minutes: 30),
            step(8, "Offer household prayer", "Each resident may express gratitude and one intention for how the home will be cared for.", minutes: 10),
            step(9, "Prepare food safely", "If boiling milk or cooking prasada is customary, supervise the stove and keep handles, children, garments, and decorations away from heat.", minutes: 15),
            step(10, "Close, ventilate, and welcome", "Complete the officiant's closing, extinguish every flame, ventilate smoke, clear hazards, and welcome guests without crowding exits.", minutes: 10)
        ],
        completion: ["Confirm all flame, embers, gas, and electrical appliances are safe.", "Keep one accessible area quiet for elders, children, disabled guests, and anyone sensitive to smoke.", "Begin the household with an act of hospitality or service."],
        safetyNotes: ["Property, fire, smoke, occupancy, and food-safety rules override ceremonial preference.", "A formal homa, Vastu Shanti, or priestly sankalpa must not be improvised from this app."],
        traditionNote: "Griha Pravesh varies substantially by region, family, property type, and priestly school. The app provides a ceremony map and safety checklist, not a universal formal paddhati.",
        sourceNotes: [householdPujaSource]
    )

    private static let navagraha = PoojaVidhi(
        id: "navagraha-pooja",
        title: "Navagraha Pooja Preparation",
        sacredFocus: "The nine grahas",
        summary: "A preparation and overview guide that keeps formal Navagraha worship, homa, donations, and remedial claims within qualified tradition.",
        purpose: "Contemplation of time, consequence, responsibility, and harmony—not fear-based guarantees.",
        category: .planetary,
        practiceLevel: .priestRecommended,
        durationMinutes: 45...120,
        occasions: ["Navagraha", "Temple observance", "Life transition", "Planetary prayer"],
        preparation: ["Ask a qualified practitioner why the rite is recommended and what tradition will be followed.", "Reject guarantees, fear-based sales, or demands for unaffordable gems and donations.", "Confirm whether the rite is temple-based, household worship, or homa."],
        materials: commonMaterials + [
            material("navagraha-list", "Officiant-provided materials list", "Tradition-specific colors, grains, flowers, or cloth", required: true, alternative: nil),
            material("navagraha-donation", "Optional ethical donation", "Service or charity", required: false, alternative: "A practical act of service within your means"),
            material("navagraha-fire", "Approved homa setup if applicable", "Priest-led fire rite", required: false, alternative: "Temple rite or no fire")
        ],
        steps: [
            step(1, "Clarify the purpose", "State the concern in practical terms and separate spiritual reflection from medical, legal, or financial decisions.", minutes: 5),
            step(2, "Choose a qualified setting", "Prefer an established temple, family priest, or transparent practitioner who explains lineage and costs.", minutes: 5),
            step(3, "Prepare safely", "Use the provided materials list and arrange flame, smoke, food, and accessibility safeguards.", minutes: 10),
            step(4, "State a non-fearful sankalpa", "Frame the intention around wisdom, responsibility, patience, and ethical action rather than guaranteed outcomes.", minutes: 5),
            step(5, "Begin with customary preliminaries", "Follow the officiant for Ganesha, kalasha, and purification steps.", minutes: 10),
            step(6, "Honor the grahas in sequence", "Follow the received order, names, offerings, and pronunciation. The app does not generate bija-mantras or substitute chants.", minutes: 25),
            step(7, "Conduct homa only through the officiant", "If included, maintain local fire rules and never leave embers unattended.", minutes: 20),
            step(8, "Connect prayer to conduct", "Identify one grounded action: accountability, service, budgeting, rest, reconciliation, or professional help where needed.", minutes: 5),
            step(9, "Offer ethical dana if desired", "Give voluntarily and within your means; do not treat payment or gemstones as a guaranteed cure.", minutes: 5),
            step(10, "Close and document the practice", "Complete the officiant's prayer, extinguish flames, and record the lineage or text used for future consistency.", minutes: 5)
        ],
        completion: ["Keep a note of the officiant, tradition, and text used.", "Do not replace evidence-based medical, legal, safety, or financial action with ritual remedies.", "Prefer voluntary service over fear-driven spending."],
        safetyNotes: ["No Pooja, gemstone, donation, or mantra guarantees an outcome.", "Formal homa and lineage mantras require qualified guidance and safe facilities."],
        traditionNote: "Navagraha procedures and mantra systems vary. The app intentionally provides an ethical preparation map rather than a fabricated universal ritual.",
        sourceNotes: [householdPujaSource]
    )

    private static func material(
        _ id: String,
        _ name: String,
        _ purpose: String,
        required: Bool,
        alternative: String?
    ) -> PoojaMaterial {
        PoojaMaterial(id: id, name: name, purpose: purpose, isRequired: required, alternative: alternative)
    }

    private static func step(
        _ number: Int,
        _ title: String,
        _ instruction: String,
        mantra: PoojaMantra? = nil,
        note: String? = nil,
        minutes: Int
    ) -> PoojaStep {
        PoojaStep(number: number, title: title, instruction: instruction, mantra: mantra, note: note, estimatedMinutes: minutes)
    }
}
