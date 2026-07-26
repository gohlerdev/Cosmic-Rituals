# Architecture

Cosmic Rituals is a small, layered SwiftUI app — the **Panchang** sister concern of
Cosmic Astrology. The golden rule is the same as the rest of the family: a clean split
between **a pure engine** (deterministic, testable, UI-free) and **a presentation layer**
(SwiftUI + the shared cosmic-glass theme). The engine never imports SwiftUI; the views
never do astronomy.

```
CosmicRituals/
├── App/
│   └── CosmicRitualsApp.swift     @main · WindowGroup → RootView
├── Engine/                         ← pure Foundation, no SwiftUI
│   ├── PanchangModels.swift        ZodiacSign, Panchang, NakshatraResult, Muhurta(+Quality), CelestialBody
│   ├── CosmicEngine.swift          Panchang-focused ephemeris (sidereal, Lahiri ayanamsha)
│   └── MuhurtaLibrary.swift        rich per-muhurta detail: deity, resonance, favourable/avoid
├── Theme/
│   └── CosmicTheme.swift           shared cosmic-glass palette + reusable components
└── Views/
    ├── RootView.swift              hosts PanchangView in the cosmic theme
    ├── PanchangView.swift          Five Limbs + 30 Muhurtas, with live "now" timing
    └── MuhurtaDetailView.swift     tap-through sheet: deity, description, favourable/avoid
```

## Muhurta detail layer

The engine's `muhurtaData` carries each muhurta's name, quality and one-line purpose.
`MuhurtaLibrary` (keyed by muhurta id 1–30) adds the deeper classical detail — presiding
**deity**, planetary/elemental **resonance**, a fuller description, and the traditional
**favourable** and **to-avoid** activity lists — exposed via `muhurta.info`. Tapping any
muhurta row (or the live "now" banner) presents `MuhurtaDetailView` with this content.
Attributions follow the classical ahoratra scheme; the tone is symbolic, never predictive.

## What was imported (and what wasn't)

This app is a focused extraction from the **Cosmic Astrology** iOS port
(`ios/old/CosmicAstrology`). Only the Panchang feature and its direct dependencies were
brought over:

- **`CosmicEngine.swift`** is the *Panchang slice* of the parent engine. It keeps the
  Julian-date / ayanamsha / Sun / Moon math, the nakshatra-pada resolver, the five-limb
  `getPanchang`, sunrise/sunset, and the thirty-muhurta builder. The natal-chart,
  Vimshottari-dasha, ascendant, and divisional-chart machinery were intentionally
  **left behind** in the parent app.
- **`PanchangModels.swift`** is the *Panchang slice* of the parent `AstroModel.swift` —
  only the value types the Panchang screen touches. `CelestialBody` is retained because a
  nakshatra reports its (dasha) lord.
- **`CosmicTheme.swift`** is the shared theme/component library, copied verbatim so the
  app looks identical to its siblings.
- **`PanchangView.swift`** is copied verbatim from the parent.

## Data flow

`RootView` hosts `PanchangView`, which owns a `selectedDate` and a sub-tab selection
(Five Limbs / 30 Muhurtas). On appear and on any date change it asks the engine for the
day's facts — the computation is cheap and side-effect-free, so there is no view model
or persistence.

```
selectedDate ──▶ CosmicEngine.getPanchang(date:)  ──▶ Five Limbs section
             └─▶ CosmicEngine.getMuhurtas(date:)  ──▶ 30 Muhurtas section (live "now")
```

## The engine

`CosmicEngine` is a sidereal Vedic ephemeris using the **Lahiri (Chitra Paksha)**
ayanamsha and Meeus algorithms (Sun §25, Moon §47 47-term series). `getPanchang` derives
the five limbs from the Sun/Moon sidereal longitudes: **tithi** (12° elongation steps),
**nakshatra** (Moon's 13°20′ segment + pada), **yoga** (Sun+Moon), **karana** (half-tithi),
and **vara** (weekday). `getMuhurtas` divides the local day/night (from NOAA sunrise/sunset)
into 15 + 15 named windows, each tagged with its classical auspiciousness and marked
`isCurrent` against the clock.

> Muhurta timings use a Delhi default location (28.61° N, 77.21° E). For other locations,
> pass `latDeg`/`lonDeg` to `getMuhurtas`.

## Theme

The "glass" look layers translucent material, a gradient hairline stroke, and a coloured
glow over an animated starfield (`CosmicStarfieldBackground`). The muhurta summary pills
use the iOS 26 `.glassEffect` API, so — like the parent Cosmic Astrology app — the target
deploys to **iOS 26**.

## Project file

`CosmicRituals.xcodeproj` uses a **file-system–synchronized root group**
(`PBXFileSystemSynchronizedRootGroup`, Xcode 16+). New files added under `CosmicRituals/`
are picked up automatically — no `project.pbxproj` edits required. `Info.plist` is
generated from build settings (`GENERATE_INFOPLIST_FILE = YES`). Bundle id:
`com.cosmic.rituals`.
