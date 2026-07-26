import Foundation

// MARK: - Festival (lunisolar keyed)
//
// Festivals are keyed to (lunarMonth, tithiIndex) where:
//   lunarMonth: 1=Chaitra, 2=Vaishakha, 3=Jyeshtha, 4=Ashadha,
//               5=Shravana, 6=Bhadrapada, 7=Ashvin, 8=Kartika,
//               9=Margashirsha, 10=Pausha, 11=Magha, 12=Phalguna
//   tithiIndex: 0-29 (Shukla 1 = 0 … Amavasya = 29)
//
// Special cases:
//   lunarMonth == -1: computed dynamically (e.g. Ekadashis, Shivaratri)
//   tithiIndex == -1: date varies (e.g. solar entry festivals)

struct Festival: Identifiable {
    let id = UUID()
    let name: String
    let lunarMonth: Int     // 1–12 or -1 for dynamic
    let tithiIndex: Int     // 0–29 or -1 for variable
    let description: String
    let category: FestivalCategory
}

enum FestivalCategory: String {
    case major      = "Major"
    case vrat       = "Vrat/Fast"
    case regional   = "Regional"
    case solar      = "Solar"
    case ancestral  = "Ancestral"
}

// MARK: - Festival Engine

enum FestivalEngine {

    static let festivals: [Festival] = [
        // Chaitra (Month 1)
        Festival(name: "Ugadi / Gudi Padwa / Chaitra Navratri begins",
                 lunarMonth: 1, tithiIndex: 0,
                 description: "New Year in the Hindu lunisolar calendar. Navratri begins; Brahma worshipped.",
                 category: .major),
        Festival(name: "Ram Navami",
                 lunarMonth: 1, tithiIndex: 8,
                 description: "Birthday of Lord Rama. Day of devotion, reading of Ramayana, fasting.",
                 category: .major),
        Festival(name: "Hanuman Jayanti",
                 lunarMonth: 1, tithiIndex: 14,
                 description: "Birthday of Hanuman on Chaitra Purnima. Hanuman temples overflow with devotees.",
                 category: .major),

        // Vaishakha (Month 2)
        Festival(name: "Akshaya Tritiya (Akha Teej)",
                 lunarMonth: 2, tithiIndex: 2,
                 description: "One of the most auspicious days of the year. Excellent for starting new ventures, buying gold, weddings.",
                 category: .major),
        Festival(name: "Buddha Purnima",
                 lunarMonth: 2, tithiIndex: 14,
                 description: "Birthday and enlightenment anniversary of Gautama Buddha. Sacred to Buddhists worldwide.",
                 category: .major),

        // Jyeshtha (Month 3)
        Festival(name: "Nirjala Ekadashi",
                 lunarMonth: 3, tithiIndex: 10,
                 description: "The strictest Ekadashi — fasting without even water. Said to be equivalent to all Ekadashis combined.",
                 category: .vrat),
        Festival(name: "Ganga Dussehra",
                 lunarMonth: 3, tithiIndex: 9,
                 description: "Sacred bathing day in the Ganga. Commemorates the river's descent to Earth.",
                 category: .major),
        Festival(name: "Vat Savitri Purnima",
                 lunarMonth: 3, tithiIndex: 14,
                 description: "Married women fast and tie threads around a banyan tree for the long life of their husbands.",
                 category: .vrat),

        // Ashadha (Month 4)
        Festival(name: "Guru Purnima",
                 lunarMonth: 4, tithiIndex: 14,
                 description: "Day dedicated to honouring one's guru and the lineage of teachers. Offerings and puja for the teacher.",
                 category: .major),
        Festival(name: "Rath Yatra",
                 lunarMonth: 4, tithiIndex: 1,
                 description: "Jagannath Rath Yatra at Puri. The chariots of Jagannath, Balabhadra, and Subhadra are pulled through the streets.",
                 category: .major),

        // Shravana (Month 5)
        Festival(name: "Nag Panchami",
                 lunarMonth: 5, tithiIndex: 4,
                 description: "Worship of serpent deities. Milk is offered to live snakes and snake idols.",
                 category: .major),
        Festival(name: "Raksha Bandhan",
                 lunarMonth: 5, tithiIndex: 14,
                 description: "Sisters tie a protective thread (rakhi) on their brother's wrist. A celebration of sibling love.",
                 category: .major),
        Festival(name: "Shravana Mondays (Somvar Vrat)",
                 lunarMonth: 5, tithiIndex: -1,
                 description: "All Mondays of the month of Shravana are sacred to Shiva. Fasting and abhisheka are very auspicious.",
                 category: .vrat),

        // Bhadrapada (Month 6)
        Festival(name: "Ganesh Chaturthi",
                 lunarMonth: 6, tithiIndex: 3,
                 description: "Ganesha's birthday. 10-day celebration culminating in Ananta Chaturdashi. One of the biggest festivals of India.",
                 category: .major),
        Festival(name: "Janmashtami",
                 lunarMonth: 6, tithiIndex: 22,
                 description: "Birthday of Lord Krishna. Midnight celebrations, fasting, and devotional singing.",
                 category: .major),
        Festival(name: "Hartalika Teej",
                 lunarMonth: 6, tithiIndex: 2,
                 description: "Women fast for marital happiness. Gauri and Shiva are worshipped.",
                 category: .vrat),
        Festival(name: "Onam (approximate)",
                 lunarMonth: 6, tithiIndex: -1,
                 description: "Kerala's harvest festival. Ten days of celebrations around the star Thiruvonam (Shravana nakshatra).",
                 category: .regional),

        // Ashvin (Month 7)
        Festival(name: "Shardiya Navratri begins",
                 lunarMonth: 7, tithiIndex: 0,
                 description: "Nine nights of Goddess Durga worship. The most widely celebrated Navratri of the year.",
                 category: .major),
        Festival(name: "Durgashtami",
                 lunarMonth: 7, tithiIndex: 7,
                 description: "The 8th day of Navratri. The fiercest form of Devi (Mahagauri) is worshipped.",
                 category: .major),
        Festival(name: "Maha Navami",
                 lunarMonth: 7, tithiIndex: 8,
                 description: "The 9th day — Saraswati puja, Ayudha Puja. Culmination of Navratri.",
                 category: .major),
        Festival(name: "Dussehra (Vijayadashami)",
                 lunarMonth: 7, tithiIndex: 9,
                 description: "Victory of good over evil. Ravana effigies burnt. Rama's victory over Ravana celebrated.",
                 category: .major),
        Festival(name: "Pitru Paksha (Mahalaya) ends",
                 lunarMonth: 7, tithiIndex: 29,
                 description: "The 15-day period for ancestral rites (Shraddha) ends. Mahalaya Amavasya is the most important day.",
                 category: .ancestral),
        Festival(name: "Sharad Purnima / Kojagari Purnima",
                 lunarMonth: 7, tithiIndex: 14,
                 description: "Lakshmi walks the earth. Kheer is kept under moonlight. A night of abundance and devotion.",
                 category: .major),

        // Kartika (Month 8)
        Festival(name: "Karva Chauth",
                 lunarMonth: 8, tithiIndex: 3,
                 description: "Married women fast from sunrise to moonrise for their husband's longevity.",
                 category: .vrat),
        Festival(name: "Dhanteras",
                 lunarMonth: 8, tithiIndex: 27,
                 description: "First day of Diwali — Lakshmi and Kuber worshipped. Gold and silver purchased.",
                 category: .major),
        Festival(name: "Naraka Chaturdashi (Choti Diwali)",
                 lunarMonth: 8, tithiIndex: 28,
                 description: "Krishna's victory over Narakasura. Oil bath before sunrise, crackers, lights.",
                 category: .major),
        Festival(name: "Diwali (Lakshmi Puja)",
                 lunarMonth: 8, tithiIndex: 29,
                 description: "The Festival of Lights. Lakshmi worshipped. Fireworks, diyas, family gatherings.",
                 category: .major),
        Festival(name: "Govardhan Puja",
                 lunarMonth: 8, tithiIndex: 0,
                 description: "Krishna's lifting of Govardhan Hill. Annakut (mountain of food offerings).",
                 category: .major),
        Festival(name: "Bhai Dooj",
                 lunarMonth: 8, tithiIndex: 1,
                 description: "Sisters pray for their brothers. Brothers give gifts. Yama's sister Yamuna welcomed him.",
                 category: .major),
        Festival(name: "Dev Uthani Ekadashi (Devutthana)",
                 lunarMonth: 8, tithiIndex: 10,
                 description: "Vishnu awakens from his cosmic sleep. Tulsi Vivah. Auspicious season for weddings resumes.",
                 category: .major),
        Festival(name: "Kartik Purnima",
                 lunarMonth: 8, tithiIndex: 14,
                 description: "One of the most sacred Purnimas. Sacred bath in the Ganga. Guru Nanak Jayanti falls here.",
                 category: .major),

        // Margashirsha (Month 9)
        Festival(name: "Vivah Panchami",
                 lunarMonth: 9, tithiIndex: 4,
                 description: "Celestial marriage of Rama and Sita. Ramayana readings and celebrations.",
                 category: .major),
        Festival(name: "Geeta Jayanti / Mokshada Ekadashi",
                 lunarMonth: 9, tithiIndex: 10,
                 description: "The Bhagavad Gita was revealed on this day. Reading the Gita is supremely auspicious.",
                 category: .major),

        // Pausha (Month 10)
        Festival(name: "Putrada Ekadashi",
                 lunarMonth: 10, tithiIndex: 10,
                 description: "Fasting for the blessing of progeny. Vishnu worshipped.",
                 category: .vrat),
        Festival(name: "Makar Sankranti",
                 lunarMonth: -1, tithiIndex: -1,
                 description: "Sun enters Capricorn (Makar). Harvest festival. Sesame sweets, kite-flying, holy baths.",
                 category: .solar),

        // Magha (Month 11)
        Festival(name: "Vasant Panchami (Saraswati Puja)",
                 lunarMonth: 11, tithiIndex: 4,
                 description: "Saraswati's birthday. Books, instruments, and tools worshipped. Beginning of spring.",
                 category: .major),
        Festival(name: "Magha Purnima",
                 lunarMonth: 11, tithiIndex: 14,
                 description: "Sacred bathing in the Ganga. Bathing here on this day is said to grant liberation.",
                 category: .major),
        Festival(name: "Maha Shivaratri",
                 lunarMonth: 11, tithiIndex: 27,
                 description: "The great night of Shiva. Overnight fasting, vigil, and Shiva abhisheka with Panchamrita.",
                 category: .major),

        // Phalguna (Month 12)
        Festival(name: "Holi (Holika Dahan)",
                 lunarMonth: 12, tithiIndex: 14,
                 description: "Bonfire on Purnima night — Holika burnt. The next day is Rangwali Holi (colours).",
                 category: .major),
        Festival(name: "Amalaki Ekadashi",
                 lunarMonth: 12, tithiIndex: 10,
                 description: "Fasting and worship of the Amla tree (Indian gooseberry) as a form of Vishnu.",
                 category: .vrat),
    ]

    // MARK: - Fetch upcoming festivals

    static func upcomingFestivals(from date: Date, count: Int = 8) -> [FestivalOccurrence] {
        var results: [FestivalOccurrence] = []
        var check = date
        var daysSearched = 0

        while results.count < count && daysSearched < 365 {
            let p = CosmicEngine.getPanchang(date: check)
            let lm = lunarMonth(tithiIndex: p.tithiIndex, date: check)

            for f in festivals {
                if f.lunarMonth == -1 { continue }  // skip dynamic (Makar Sankranti, etc.)
                if f.tithiIndex == -1 { continue }

                if f.lunarMonth == lm && f.tithiIndex == p.tithiIndex {
                    if !results.contains(where: { $0.festival.name == f.name }) {
                        results.append(FestivalOccurrence(festival: f, date: check))
                    }
                }
            }

            check = check.addingTimeInterval(86400)
            daysSearched += 1
        }

        return results.sorted { $0.date < $1.date }
    }

    // Approximate lunar month from a Gregorian date and tithi index.
    // We count roughly 29.5-day lunations from the reference Chaitra 1 (2024-04-09).
    private static func lunarMonth(tithiIndex: Int, date: Date) -> Int {
        let refDate = Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 9))!
        let daysSinceRef = date.timeIntervalSince(refDate) / 86400
        let lunationsSince = daysSinceRef / 29.5306
        let monthsSince = Int(lunationsSince.rounded(.down))
        let lm = ((monthsSince % 12) + 12) % 12 + 1  // 1–12
        return lm
    }
}

struct FestivalOccurrence: Identifiable {
    let id = UUID()
    let festival: Festival
    let date: Date
}
