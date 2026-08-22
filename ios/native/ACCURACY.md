# Calculation accuracy and provenance

Cosmic Rituals is an offline Panchang application. It favors deterministic,
location-aware calculations and explicit limits over unexplained precision.

## Daily reference convention

- A Panchang day is anchored to sunrise at the selected calculation location.
- Tithi, Nakshatra, Yoga, Karana, Moon sign, and the displayed Pada are evaluated
  at that sunrise instant.
- If sunrise does not exist for the selected latitude and civil date, the app
  does not fabricate sunrise-based schedules. The five-limb snapshot falls back
  to 12:00 PM local civil time and labels that fallback in the interface.
- Dates and clock times are formatted in the calculation location's IANA time
  zone, including daylight-saving transitions. They never silently inherit the
  device time zone.

## Astronomical methods

| Quantity | Current method | Presentation contract |
|---|---|---|
| Julian date | Gregorian UTC conversion based on Meeus chapter 7 | Absolute instant |
| Sun longitude | Meeus chapter 25 apparent ecliptic longitude | Offline compact ephemeris |
| Moon longitude | Complete Meeus table 47.A longitude series | Offline compact ephemeris |
| Sidereal conversion | Lahiri (Chitra Paksha) ayanamsha polynomial | Named in Settings and exports |
| Sunrise / sunset | Meeus chapter 15 solar altitude crossing at -0.8333 degrees, from the same chapter 25 apparent longitude used for the five limbs (not a separately maintained approximation) | No result for polar day/night |
| Limb transitions | Bracketed 56-step boundary solve for each limb | Tithi, Nakshatra, Yoga, and Karana independently |
| Muhurta / Choghadiya / Hora | Proportional local day and night divisions | Requires real sunrise, sunset, and next sunrise |
| Rahu Kala / Yamaganda / Gulika | Weekday-specific eighths of local daylight | Requires real sunrise and sunset |
| Abhijit | Eighth of 15 daylight muhurtas | Scales with daylight; omitted on Wednesday |
| Brahma Muhurta | 96 to 48 minutes before sunrise | Requires real sunrise |
| Dur Muhurta | Weekday-specific day/night division table | Tuesday second period uses the night division |

The numerical boundary solver converges to sub-second resolution. That describes
the solver, not the absolute accuracy of the compact astronomical model. The UI
uses a conservative plus-or-minus 12 minute validation envelope for externally
published civil-time comparisons.

## Vara-Nakshatra combination yogas

`PanchangYogaEngine` cross-references the weekday and the already-computed
Moon (and, for Ravi Yoga, Sun) nakshatra against classical combination rules.
Sources were cross-checked across multiple independent, mutually consistent
references before implementation, not taken from a single site:

| Yoga | Rule | Cited to |
|---|---|---|
| Sarvartha Siddhi | Fixed table of 34 (weekday, nakshatra) pairs | Jyotir Nibandha |
| Amrit Siddhi | One nakshatra per weekday, each also a Sarvartha Siddhi member | Kalamrita, Muhurta Parijata |
| Guru Pushya | Pushya nakshatra on Thursday | Standard Panchang convention |
| Ravi Yoga | Sun-nakshatra-to-Moon-nakshatra inclusive count of 4, 6, 9, 10, 13, or 20 in the 27-nakshatra cycle | Standard Panchang convention |

## Regression evidence

The native test target includes independent fixtures whose expected values are
recorded beside their sources:

- Sunrise and sunset: New Delhi, Tokyo, Los Angeles, and New York on a DST
  transition day.
- Five-limb transitions: Paris on 21 July 2026, covering Tithi, Nakshatra, Yoga,
  and Karana.
- Rahu Kala, Yamaganda, Gulika, and Dur Muhurta: published Mumbai Friday
  fixtures, plus Hyderabad Tuesday Dur Muhurta including its night period.
- Abhijit Muhurta: Mumbai on Friday, plus the Wednesday omission rule.
- Boundary invariants: multiple seasons and time zones verify that every solved
  transition changes from its declared current value to its declared next value.
- Civil-time invariants: selected-day preservation east and west of UTC, DST day
  advancement, civil-day preservation when changing locations, and explicit
  polar fallback behavior.

Run the evidence with:

```bash
xcodebuild \
  -project CosmicRituals.xcodeproj \
  -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Deliberately not claimed as reference-grade

The repository preserves experimental festival, extended Vedic-calendar,
moonrise/moonset, and low-precision Graha-position work for future development.
Those calculations are not routed into the shipping navigation and must not be
described as available or reference-grade until they have independent fixtures,
regional rule handling where applicable, and visible precision disclosures.

The WidgetKit source is also not a shipping widget until an extension target,
App Group, signing capability, and end-to-end tests are present.

## Practical limits

- Atmospheric refraction, observer elevation, terrain, and local horizon
  obstruction can shift observed sunrise and sunset.
- A compact offline ephemeris is not a replacement for JPL or Swiss Ephemeris
  data when arcsecond-level planetary positions are required.
- Festival and vrata observance can depend on regional school, sunrise/tithi
  precedence, and event-specific rules; a simple date or tithi lookup is not
  sufficient.
- Ritual interpretation is traditional and symbolic. For consequential
  ceremonial timing, users should confirm the chosen convention with a qualified
  practitioner.
