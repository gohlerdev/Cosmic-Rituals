# Cosmic Rituals

A native SwiftUI app for the Vedic **Panchang** — the five limbs of the day — and the
thirty day & night **muhurtas**. A sister concern of **Cosmic Astrology**, sharing its
cosmic-glass look and its sidereal (Lahiri ayanamsha) ephemeris.

## Features

- **Pancha Anga (Five Limbs)** for any date: Vara (weekday), Tithi (lunar day),
  Nakshatra, Yoga, and Karana.
- **Sunrise-anchored day model** with independently solved Tithi, Nakshatra, Yoga,
  and Karana transition times, plus a truthful polar fallback.
- **Nakshatra detail** — the Moon's nakshatra with its symbol, gana, ruling (dasha) lord,
  pada (1–4), Moon sign, and Shukla/Krishna paksha phase.
- **30 Muhurtas** — all fifteen day and fifteen night windows, each named and tagged by
  classical auspiciousness (Excellent / Auspicious / Mixed / Avoid), with the **current**
  muhurta highlighted live against the clock.
- **Auspicious & inauspicious kala** — Rahu Kala and Yamaganda for the weekday.
- **12 offline Pooja Vidhis** — searchable daily, deity, festival, vrata, life-event,
  and planetary guides with materials, preparation, ordered steps, Devanagari,
  transliteration, mantra meaning, safety, respectful closure, and guided mode.
- **Tradition-aware ritual boundaries** — household guides are separated from
  priest-recommended rites; initiatory mantras, homa instructions, and universalized
  claims are intentionally excluded.
- **StoreKit 2 Premium access** — verified App Store entitlements, transaction updates,
  restore purchases, localized subscription UI, and eligible 14-day introductory
  trials. No local trial timer or unverified receipt fallback.

## Build & run

Open `CosmicRituals.xcodeproj` in **Xcode 26+** and run the `CosmicRituals` scheme on an
iOS 26 simulator or device.

- Deployment target: **iOS 26** (the muhurta summary pills use the `.glassEffect` API).
- No third-party dependencies; everything is computed on-device and fully offline.

## Layout

```
CosmicRituals/
├── App/        @main entry → RootView
├── Engine/     pure-Foundation Panchang ephemeris + Pooja catalog/models
├── Theme/      shared cosmic-glass theme & components
└── Views/      RootView + PanchangView
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the engine details and exactly what was
imported from the parent Cosmic Astrology app.

See [POOJA_CONTENT.md](POOJA_CONTENT.md) for the ritual-content contract, source
provenance, inclusion policy, and the household/priest boundary.

See [SUBSCRIPTION_RELEASE.md](SUBSCRIPTION_RELEASE.md) for product identifiers,
entitlement behavior, App Store Connect setup, policy URLs, and the sandbox test matrix.

## Accuracy and integrity

Positions use Meeus algorithms with the Lahiri (Chitra Paksha) ayanamsha. Muhurta
windows are derived from sunrise and sunset for the explicitly selected location
and IANA time zone. Independent civil-time fixtures cover solar events, all four
limb transitions, Dur Muhurta, Abhijit, DST, and polar behavior.

See [ACCURACY.md](ACCURACY.md) for method provenance, validation tolerances, and
features that are intentionally not presented as reference-grade. For
consequential ceremonial timing, confirm the chosen convention with a qualified
practitioner.
