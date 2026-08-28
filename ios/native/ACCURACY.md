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
| Julian date | Epoch-based UT Julian date (sub-second; the earlier component conversion truncated to whole seconds) | Absolute instant |
| Time scale (Delta T) | Espenak-Meeus piecewise polynomials convert UT to Terrestrial Time before every Sun/Moon series evaluation; without this every limb end time lagged ~70-75 s in 2026. The 2005-2050 branch is that model's projection and reads a few seconds above measured IERS Delta T -- far inside the published +-12 minute envelope. | Applied internally; Meeus book fixtures pin the TT entry points directly |
| Sun longitude | Meeus chapter 25 apparent ecliptic longitude | Offline compact ephemeris |
| Moon longitude | Complete Meeus table 47.A longitude series plus the leading nutation term, giving apparent-of-date in the same frame as the Sun | Offline compact ephemeris |
| Sidereal conversion | Lahiri (Chitra Paksha) ayanamsha polynomial | Named in Settings and exports |
| Sunrise / sunset | Meeus chapter 15 solar altitude crossing at -0.8333 degrees, from the same chapter 25 apparent longitude used for the five limbs (not a separately maintained approximation) | No result for polar day/night |
| Moonrise / moonset | Meeus chapter 15 iterated crossing, re-evaluating the Moon's apparent position (Table 47.A longitude plus the complete Table 47.B latitude) at every trial instant; standard altitude uses the TRUE horizontal parallax from the Table 47.A distance series (transcribed from two agreeing open-source lineages, pinned to the book's 368409.7 km example), h0 = 0.7275 pi - 34' | A day with no moonrise or moonset shows that fact; it is not smoothed over |
| Limb transitions | Bracketed 56-step boundary solve for each limb | Tithi, Nakshatra, Yoga, and Karana independently |
| Limb windows (day timeline) | The same solver run backward to the running limb's start and forward across the sunrise-to-sunrise day, listing every window including kshaya spans that touch no sunrise; civil-day anchors stand in where sunrise does not exist | The Day Timeline card |
| Varjyam / Amrit Kalam | Per-nakshatra start ghatis (duration 1/15 of the nakshatra span) from the dominant daily-panchang practice table: Drik Panchang Thyajyam tutorial and the Telugu oursubhakaryam table agree, empirically confirmed to within 0.05 ghati against prokerala.com 2026 dailies (Ujjain, Lahiri) on eight dates including both two-Varjyam days. The Prashna Marga (B.V. Raman) Varjyam column and Madhaveeya Amrit column are distinct classical variants the dailies do not use and are NOT implemented; the dailies' Anuradha Amrit value (34) is used where the book prints 28. | Rows in the Day Timeline card |
| Anandadi yoga | 28-name cycle with Abhijit inserted after Uttara Ashadha, counted from the weekday's anchor nakshatra (Ashwini/Mrigashira/Ashlesha/Hasta/Anuradha/Uttara Ashadha/Shatabhisha). The 28-vs-27 count was settled empirically: Thursday+Dhanishta prints Shrivatsa and Tuesday+Ashwini prints Amrita in the 2026 dailies, both only consistent with the inserted count. The quarantined 9-name prototype used a (weekday+nakshatra) mod 9 formula that is simply wrong and remains dead. | Per-nakshatra rows in the Day Timeline card |
| Sankranti | Bisection on the sidereal (Lahiri) Sun crossing each 30-degree boundary, from the same five-limb apparent longitude | Fixtures: Drik Panchang 2026 instants (Makar 14 Jan 15:13 IST, Mesha 14 Apr 09:39, Karka 16 Jul 23:45), with Prokerala's systematically ~9-10-minute-earlier values recorded beside them as a stable inter-source divergence. SANKRANTI INSTANTS CARRY A WIDER ENVELOPE THAN THE LIMB TIMES: the Sun alone drives them at ~0.04 deg/hour, so the compact model's ~0.01-degree solar error amplifies to tens of minutes (measured: 29-44 min early vs Drik at two 2026 sankrantis, within 12 min at a third), where the Moon-driven limbs stay near a minute. Fixture tolerance is one hour, no sankranti clock time is displayed, and the masa/Adhika/year classification is unaffected unless a sankranti falls within that margin of a lunation boundary |
| Lunar month / years | New-moon (elongation-0) lunations; the Amanta masa named by the sankranti inside it (Mesha maps to Chaitra), Adhika when none, the rare Kshaya when two (last 1983, next expected 2124 per published series); Purnimanta shifts name in Krishna paksha; Vikram (CE+57) and Shaka (CE-78) increment at Chaitra Shukla Pratipada | Fixtures: Adhika Jyeshtha 2026-05-17..06-15 (AdhikMaas.com, HinduPad, Drik's Adhika Purnima 31 May) and the published 2026-08-27 day (Amanta Shravana, VS 2083, Shaka 1948). Gujarat's Kartika-anchored Vikram year and the tropical-solstice Ayana are named divergences, not implemented; this construction replaces the quarantined sun-sign approximation, which stays dead |
| Panchaka / Ganda Mula | Moon-transit Panchaka: sidereal Moon 300-360 degrees (Dhanishtha's second half through Revati), type named by the weekday the period began (Sunday Roga, Monday Raja, Tuesday Agni, Friday Chora, Saturday Mrityu; Wednesday/Thursday starts unnamed). One published table shifting every weekday is an outlier and not implemented; the mod-9 Panchaka-Rahita muhurta filter is a different construct this app does not compute. Ganda Mula: the six Mercury/Ketu junction nakshatras, uniform across sources. | Badges in the Day Timeline card |
| Muhurta / Choghadiya / Hora | Proportional local day and night divisions | Requires real sunrise, sunset, and next sunrise |
| Rahu Kala / Yamaganda / Gulika | Weekday-specific eighths of local daylight | Requires real sunrise and sunset |
| Abhijit | Eighth of 15 daylight muhurtas | Scales with daylight; omitted on Wednesday |
| Brahma Muhurta | 96 to 48 minutes before sunrise | Requires real sunrise |
| Dur Muhurta | Weekday-specific day/night division table | Tuesday second period uses the night division |

The numerical boundary solver converges to sub-second resolution. That describes
the solver, not the absolute accuracy of the compact astronomical model. The UI
uses a conservative plus-or-minus 12 minute validation envelope for externally
published civil-time comparisons.

## Traditional timekeeping: prahars, Ishta Kaal, ghati counters

`TraditionalClock` adds no astronomy. Every value is derived from the sunrise
and sunset instants already solved elsewhere, and every entry point returns
nil or an empty list where sunrise does not exist.

| Quantity | Method | Note |
|---|---|---|
| Prahar (1-8) | Four equal quarters of the actual daylight arc, then four of the actual night | Proportional, not three-hour blocks |
| Ishta Kaal | Elapsed time from the Vedic day's sunrise, in fixed ghati-pala-vipala | Pre-dawn instants resolve to the previous Vedic day |
| Dinamana / Ratrimana | Daylight and night length in fixed ghatis | Varies with season and latitude by construction |
| Units | 1 ghati = 24 min = 60 pala (vighati, kala); 1 pala = 60 vipala (lipta, vikala); 60 ghatis = one day and night | Sexagesimal throughout |

Definitions were verified against multiple independent sources before
implementation. The capability was identified from a competitor listing; none
of the definitions were taken from it. The unit ratios and the alternate unit
names are attested at sankul.org/ghati; the Ishta Kaal x2.5-per-hour rule was
cross-checked against a published worked example (sunrise 06:30, instant 16:30
-> 10 hours -> exactly 25 ghatis); the proportional prahar construction is
stated explicitly by Wikipedia's "Prahara" article, which notes prahars are
three hours each only near the equator; and the eight names are attested at
bhaktibharat.com and thedivineindia.com independently of any app listing.

**Two disclosed divergences, surfaced in the app rather than silently resolved:**

1. **Ghati convention.** The fixed 24-minute ghati ships, so dinamana moves
   through the year — which is the reason classical panchangs print dinamana at
   all. A competing "30-ghati clock" divides daylight into 30 parts and night
   into 30, making dinamana a constant 30 by construction. Both are in
   circulation. The fixed ghati is the convention the Ishta Kaal rule and its
   worked examples assume, and dinamana is displayed precisely so a reader can
   see which convention is in force.
2. **Prahar duration.** A contemporary operational scheme pins prahars to fixed
   clock hours (3-6am, 6-9am, ...) and in doing so swaps Madhyahna and Aparahna
   relative to the traditional sunrise-anchored order. The traditional
   proportional scheme is what ships.

Consequence worth stating plainly: prahars are proportional while ghatis are
fixed, so a day prahar equals 7.5 ghatis only at the equinox. The two units are
not reconciled here because the tradition does not reconcile them.

Both decisions carry negative controls. Reimplementing prahars as fixed
three-hour blocks turns four tests red, and switching dinamana to the
proportional 30-ghati reading turns two red.

## Regional solar months (Tamil, Kerala, Bengal, Odisha)

`RegionalSolarCalendarEngine` names the solar month each region actually uses,
from the same sankranti solver as the lunisolar calendar. The four day-1 rules
follow Dershowitz & Reingold's formalization ("Indian Calendrical
Calculations", eqs. 25-28), read from the paper itself:

| Region | Critical moment | 2026 new-year fixture |
|---|---|---|
| Odisha (any-time rule) | next sunrise — the sunrise-to-sunrise day containing the sankranti | Baisakha 1 = 14 April (Pana Sankranti) |
| Tamil Nadu | sunset of the current day | Chithirai 1 = 14 April (Puthandu) |
| Kerala | sunrise + 3/5 of daylight | Chingam 1 = 17 August, Kollam 1202 |
| Bengal | next civil midnight | Boishakh 1 = 15 April, San 1433 |

Era years ship only where verified: Kollam (CE − 824 from Chingam, − 825
before) and the Bengali San (CE − 593 from Boishakh, − 594 before). The Tamil
sixty-year name cycle and Odisha's anka regnal year are not implemented.

**Three disclosed limits.** (1) Bengal's 23:36–00:24 temporal-time special
zone has month- and weekday-dependent sub-rules the consulted source does not
publish; a sankranti inside that window (apparent midnight ± 24 temporal
minutes) is flagged, never silently resolved. (2) Bangladesh's reformed civil
calendar pins Pohela Boishakh to 14 April by fixed month lengths — a different
construction from the astronomical rule computed here, which matches the West
Bengal traditional 15 April 2026. (3) Day-1 determination inherits the
sankranti solver's ±60-minute envelope, so any month start whose sankranti
lies within that margin of the rule's critical moment carries a visible
uncertainty flag. Kerala's historically distinct critical longitude is noted;
every reckoning here runs from the single disclosed Lahiri chokepoint.

Negative controls: collapsing the Tamil rule into the any-time rule, moving
Bengal's start to the sankranti's own day, and flattening the Kollam offset
each turn dedicated tests red.

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
