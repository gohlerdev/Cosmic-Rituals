# Rituals Experience Design QA

## Scope

Three persisted Panchang Experience modes: Ritual Now, Vedic Ledger, and Five-Limb Focus. The experience choice remains independent from the six existing color themes.

## Visual sources

- `/Users/psy/Documents/Gohler/Cosmic-Design-Samples-2026-07-23/Rituals/ritual-now.png`
- `/Users/psy/Documents/Gohler/Cosmic-Design-Samples-2026-07-23/Rituals/vedic-ledger.png`
- `/Users/psy/Documents/Gohler/Cosmic-Design-Samples-2026-07-23/Rituals/five-limb-focus.png`

## Verified implementation captures

- `/Users/psy/Documents/Gohler/Experience-QA-2026-07-23/Rituals/final-ritual-now.png`
- `/Users/psy/Documents/Gohler/Experience-QA-2026-07-23/Rituals/final-vedic-ledger.png`
- `/Users/psy/Documents/Gohler/Experience-QA-2026-07-23/Rituals/final-five-limb-focus.png`

## Same-input comparisons

- `/Users/psy/Documents/Gohler/Experience-QA-2026-07-23/comparisons/final-rituals-now.png`
- `/Users/psy/Documents/Gohler/Experience-QA-2026-07-23/comparisons/final-rituals-ledger.png`
- `/Users/psy/Documents/Gohler/Experience-QA-2026-07-23/comparisons/final-rituals-five-limb.png`

## Test state and normalization

- Simulator: iPhone 17, iOS 26.5, 1206 x 2622 pixels, status time 9:41.
- Data: live Panchang result for Thursday, 23 July 2026, including tithi transition time and the existing Timing/Muhurta/Calendar destinations.
- Ritual Now and Five-Limb Focus were captured in Obsidian Gold; Vedic Ledger was captured in Cloud Dancer to match its approved editorial-light source.
- Each implementation capture was scaled without cropping to 853 x 1844 and paired with its approved source in one comparison image.
- Full-view comparison was sufficient because the corrected issues were duplicated navigation, first-fold density, and placement of the fixed destination bar.

## Findings and fix history

1. The first implementation stacked a native title, a second large custom header, and a top tab rail, pushing the selected experience below the first fold.
2. The final build keeps one compact title and moves all four existing destinations into a persistent iOS 26 grouped-glass bottom bar.
3. The first destination now reads Panchang with an eye symbol, matching the approved information architecture.
4. Toolbar actions have explicit VoiceOver labels and hints; the Five-Limb focus card includes its end time in accessibility output.
5. Transition copy now names the next tithi and time. The editorial ledger was tightened so all five limb rows remain visible above the pinned navigation at launch.
6. Final comparisons show three materially distinct, data-backed experiences with working detail actions and no duplicated chrome.

## Result

final result: passed
