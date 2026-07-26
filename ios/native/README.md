# Cosmic Rituals

A native SwiftUI app for the Vedic **Panchang** — the five limbs of the day — and the
thirty day & night **muhurtas**. A sister concern of **Cosmic Astrology**, sharing its
cosmic-glass look and its sidereal (Lahiri ayanamsha) ephemeris.

## Features

- **Pancha Anga (Five Limbs)** for any date: Vara (weekday), Tithi (lunar day),
  Nakshatra, Yoga, and Karana.
- **Nakshatra detail** — the Moon's nakshatra with its symbol, gana, ruling (dasha) lord,
  pada (1–4), Moon sign, and Shukla/Krishna paksha phase.
- **30 Muhurtas** — all fifteen day and fifteen night windows, each named and tagged by
  classical auspiciousness (Excellent / Auspicious / Mixed / Avoid), with the **current**
  muhurta highlighted live against the clock.
- **Auspicious & inauspicious kala** — Rahu Kala and Yamaganda for the weekday.

## Build & run

Open `CosmicRituals.xcodeproj` in **Xcode 16+** and run the `CosmicRituals` scheme on an
iOS 26 simulator or device.

- Deployment target: **iOS 26** (the muhurta summary pills use the `.glassEffect` API).
- No third-party dependencies; everything is computed on-device and fully offline.

## Layout

```
CosmicRituals/
├── App/        @main entry → RootView
├── Engine/     pure-Foundation Panchang ephemeris + models
├── Theme/      shared cosmic-glass theme & components
└── Views/      RootView + PanchangView
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the engine details and exactly what was
imported from the parent Cosmic Astrology app.

## Accuracy

Positions use Meeus algorithms with the Lahiri (Chitra Paksha) ayanamsha. Muhurta windows
are derived from local sunrise/sunset (Delhi default location). For ritually precise
timings, confirm with a qualified Jyotishi.
