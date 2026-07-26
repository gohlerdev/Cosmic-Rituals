# Cosmic Rituals — Product Roadmap

> Goal: the definitive native iOS Vedic Panchang experience — surpassing drikpanchang.com on UX
> while matching (then exceeding) it on content depth. On-device, private, no account required.

---

## Baseline (shipped — v0.1)

| Feature | Status |
|---------|--------|
| Five limbs — Vara, Tithi, Nakshatra, Yoga, Karana | ✅ |
| 30 day + night muhurtas with quality ratings | ✅ |
| Muhurta detail sheet (deity, resonance, activities) | ✅ |
| Rahu Kala + Yamaganda (computed from sunrise) | ✅ |
| Nakshatra detail — lord, gana, pada, symbol | ✅ |
| Moon sign + tithi phase (Shukla/Krishna) | ✅ |
| Animated starfield + Liquid Glass UI | ✅ |
| 6 color themes (3 dark, 3 light) | ✅ |
| Location-aware sunrise/sunset | ✅ |
| Date picker | ✅ |

---

## Phase 1 — Daily-Use Parity with drikpanchang  `[✅ shipped v0.2]`

| Feature | Status |
|---------|--------|
| 1.1 Choghadiya (8 day + 8 night periods, live highlight) | ✅ |
| 1.2 Hora (24 planetary hours, Chaldean cycle) | ✅ |
| 1.3 Moonrise & Moonset (Meeus §15 + parallax) | ✅ |
| 1.4 Gulika Kala | ✅ |
| 1.4 Dur Muhurta (Muhurta Chintamani table) | ✅ |
| 1.4 Varjyam | pending |
| 1.5 Brahma Muhurta + Abhijit Muhurta callouts | ✅ |
| 1.6 Sun sign + Sun nakshatra | ✅ |
| 1.7 Tithi transition time (binary search) | ✅ |

---

## Phase 2 — Content Depth & Discovery  `[✅ shipped v0.3]`

| Feature | Status |
|---------|--------|
| 2.1 Panchang limb detail sheets (Tithi/Yoga/Karana) | ✅ |
| 2.2 Monthly calendar view with tithi/yoga quality dots | ✅ |
| 2.3 Festival & Vrat calendar (40+ festivals) | ✅ |
| 2.4 "Best time today" card with activity picker | ✅ |
| 2.5 Muhurta timeline visualization with live cursor | ✅ |

---

## Phase 3 — Platform & Ecosystem  `[partial v0.4]`

| Feature | Status |
|---------|--------|
| 3.1 WidgetKit (small + medium) | ✅ source files ready; **add target in Xcode** |
| 3.2 Live Activity + Dynamic Island | pending (needs ActivityKit target) |
| 3.3 Notifications (muhurta + Brahma Muhurta) | ✅ |
| 3.4 Siri Shortcuts / App Intents (3 intents) | ✅ |
| 3.5 Share sheet (text + PDF export) | ✅ |

---

## Phase 4 — Advanced Jyotish  `[✅ shipped v0.5]`

| Feature | Status |
|---------|--------|
| 4.1 Planetary hora real-time display | ✅ |
| 4.2 Chandra Bala & Tara Bala | ✅ |
| 4.3 Transit alerts (Jupiter + Saturn sign change notifications) | ✅ |
| 4.3 Nine Graha Positions (Schlyter orbital elements, sidereal) | ✅ |
| 4.4 Panchang PDF export (dark-theme A4) | ✅ |
| 4.5 Apple Watch companion | pending (needs WatchOS target) |

---

## Technical Debt & Ongoing

| Item | Status |
|------|--------|
| CosmicTheme.swift (1300 lines) — split into components | pending |
| Panchang struct sunriseTime/sunsetTime always nil | pending |
| Unit tests for CosmicEngine | ✅ written; **add test target in Xcode** |
| Tithi name duplication (Pratipada appears twice) | pending |
| Varjyam (nakshatra+pada based inauspicious period) | pending |
| App Group entitlement for widget location sharing | **enable in Xcode Signing & Capabilities** |
| WidgetKit target — add in Xcode and enable App Group | **manual Xcode step** |

---

## Competitive Positioning

| Feature | DrikPanchang (web) | Cosmic Rituals |
|---------|-------------------|----------------|
| Native iOS UX | ✗ | ✅ |
| Muhurta detail (deity/activities) | Basic | ✅ Rich |
| Live animated UI | ✗ | ✅ |
| Offline / on-device | Partial | ✅ 100% |
| Choghadiya | ✅ | ✅ |
| Hora | ✅ | ✅ |
| Moonrise/Moonset | ✅ | ✅ |
| Monthly calendar | ✅ | ✅ |
| Festivals | ✅ | ✅ |
| Nine Graha Positions | ✅ | ✅ |
| Dur Muhurta | ✅ | ✅ |
| Chandra/Tara Bala | ✅ | ✅ |
| Transit alerts | ✗ | ✅ |
| Widgets | ✗ | ✅ (source ready) |
| Siri integration | ✗ | ✅ |
| PDF export | ✗ | ✅ |
| Privacy / no account | ✗ | ✅ |

---

*Last updated: 2026-07-01*
