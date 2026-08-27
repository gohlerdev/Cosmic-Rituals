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
| Moon longitude | Complete Meeus table 47.A longitude series plus the leading nutation term, giving apparent-of-date in the same frame as the Sun | Offline compact ephemeris |
| Sidereal conversion | Lahiri (Chitra Paksha) ayanamsha polynomial | Named in Settings and exports |
| Sunrise / sunset | Meeus chapter 15 solar altitude crossing at -0.8333 degrees, from the same chapter 25 apparent longitude used for the five limbs (not a separately maintained approximation) | No result for polar day/night |
| Moonrise / moonset | Meeus chapter 15 iterated crossing, re-evaluating the Moon's apparent position (Table 47.A longitude plus the complete Table 47.B latitude) at every trial instant; standard altitude uses the book's mean +0.125 degrees since the distance series is not carried (about one minute worst case) | A day with no moonrise or moonset shows that fact; it is not smoothed over |
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

## Personal star relations

When the user saves a birth nakshatra (and pada) in Settings, the app reads
three classical relations against the day already computed. Rules were
cross-checked across multiple independent, mutually consistent sources
(drikpanchang tarabalam and chandrabalam tables, mypanchang's Tarabalam
Chakra, prokerala, trsiyengar) before implementation:

- Tarabala: inclusive count from birth star to the day's Moon star, mod 9
  (zero read as 9). Taras 2/4/6/8/9 favorable, 3/5/7 unfavorable. Janma
  (1) is displayed as MIXED because the checked sources genuinely disagree
  on it -- the divergence is stated in the card rather than resolved by us.
- Janma rashi derives from nakshatra + pada (108 padas, nine per sign);
  the pada picker exists precisely because boundary nakshatras like
  Krittika span two signs.
- Chandrabala: present at inclusive sign counts 1, 3, 6, 7, 10, 11 from
  the janma rashi. The classical remediability split among the unfavorable
  counts is deliberately not modelled.
- Chandrashtama: the day Moon in the 8th sign from the janma rashi.

The birth nakshatra is stored only on this device and the card is absent
until it is set.

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
- Choghadiya and Hora: published Mumbai Friday sequence and clock times for
  every quality/planet and both day and night halves.
- Moon latitude: Meeus's own Example 47.a (beta = -3.229126 at JD 2448724.5),
  with the Table 47.B transcription cross-checked between two independent
  open-source lineages. Moonrise/moonset: US Naval Observatory API fixtures
  for New Delhi (rise and set) and Tokyo (rise plus a genuine no-moonset
  day), on a date where USNO's solar times exactly reproduce this suite's
  existing timeanddate and NAOJ fixtures.
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
and low-precision Graha-position work for future development. (Moonrise and
moonset shipped separately via the verified CelestialRiseSet path above; the
old low-precision moonrise prototype remains unused and must not be revived.)
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
