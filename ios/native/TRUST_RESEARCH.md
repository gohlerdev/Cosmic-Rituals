# Cosmic Rituals trust, completeness, and non-discrimination research

**Status:** research only; no product behavior changed

**Evidence cut:** 2026-09-07
**Scope:** `/Users/psy/Documents/Cosmic-Rituals/ios/native`

## Direct answer

Cosmic Rituals already rejects paywalls, fear-selling, compulsory fasting,
restricted participation, unsafe fire/smoke, and guaranteed outcomes. Those
are unusually strong foundations. It is not yet a source-complete ritual
authority: broad web guides are reused as support for deity-specific sequences
and mantras, and the 30-muhurta interpretation library lacks a named printed
source. The app must not let inclusive intentions substitute for ritual
provenance.

## Verified strengths

- The app is free and has a test that rejects StoreKit reintroduction.
- There is no account, analytics, advertising, tracking SDK, network client, or
  third-party package in the native target.
- The privacy manifest declares no tracking and no collected data.
- Ritual progress is minimal local `UserDefaults` state; no religious profile,
  search history, completion history, or location is persisted in that record.
- Participation is explicitly unrestricted by caste, gender, menstruation,
  marital status, or birth.
- Movement and posture can be adapted for disability, age, comfort, and safety.
- Flames, incense, water, flowers, and food are optional when unsafe or
  unavailable.
- Fasting is optional and health, pregnancy, medication, age, and eating-
  disorder considerations take priority.
- Initiatory bija mantra, nyasa, Vedic recitation, homa, formal kalasha
  installation, and lineage-specific visarjana are excluded.
- Priest-recommended guides stop at the officiant boundary.
- No ritual claims material, medical, legal, relationship, or astrological
  outcomes.

## Market check

Apple's India Search API was queried for `hindu puja`; the ten highest-rating-
count returned apps were inspected. The query mixes astrology, worship,
calendar, darshan, and mantra products, so it is a consumer-discovery sample,
not a clean category census. Store labels are developer declarations.

- 7/10 displayed “Data Used to Track You.”
- 2/10 declared collection without displaying tracking.
- 1/10 displayed “Data Not Collected.”
- 5/10 listed in-app purchases.

Sampling URL:
https://itunes.apple.com/search?term=hindu%20puja&country=in&entity=software&limit=50

The meaningful contrast is that a person can calculate a Panchang and complete
a household guide in Cosmic without account creation, data collection, or a
payment path.

## Blocking integrity findings

### 1. “Has a source note” is weaker than “this claim is sourced”

The catalog validates only that each guide has at least one `PoojaSourceNote`.
Five broad web sources support twelve guides. The general Himalayan Academy
home-puja source is reused for Ganesha, Shiva, Vishnu, Hanuman, Saraswati,
Surya, Griha Pravesh, Navagraha, and the general five-offering pattern.

That can support a declared adaptation pattern. It cannot automatically prove
every deity-specific material, mantra spelling, repetition count, invocation,
offering, step, meaning, or closure. The source model has a title, URL, and
detail but no edition, chapter, verse/page, tradition owner, claim IDs, or
exact coverage map.

The validation can therefore pass while individual cultural claims remain
unattributed.

### 2. Mantra provenance is incomplete

Every mantra includes Devanagari, transliteration, meaning, and suggested
count, which is good presentation. Those fields do not identify where the
mantra form came from, whether it is a public nama-mantra in all relevant
traditions, or who verified its transliteration and meaning. A generic guide
source is not enough.

Each mantra needs its own record: exact text, normalized Sanskrit, script,
transliteration standard, literal meaning, received/public classification,
source locus, regional or sampradaya variants, and whether a count is sourced
or merely an optional product convention.

### 3. The 30-muhurta interpretation library is unsourced and action-bearing

`MuhurtaLibrary.swift` supplies deity, planetary/elemental “resonance,” rich
description, favourable activities, and activities to avoid for all thirty
day/night muhurtas. It says the attributions follow the classical scheme but
names no text, chapter, verse, edition, or competing list. `bestTime` then uses
those activity strings to recommend a future window.

This is not harmless decorative copy. It influences when users may launch,
travel, sign, marry, demolish, or perform fire rites. Until sourced, the rich
interpretation and “Best Time” matching should be treated as blocking content,
even though the underlying sunrise-to-sunrise division is deterministic.

### 4. Safety must override textual instruction everywhere

The catalog already handles flame, smoke, allergy, food, water, wildlife, and
fasting well. The same precedence must govern any future source: a printed
ritual direction does not override medical advice, fire rules, tenancy,
environmental law, accessibility, animal safety, or consent. WHO guidance on
religious fasting confirms that risks can be material for diabetes, pregnancy,
and other conditions and that individual medical guidance matters:
https://www.emro.who.int/media/media-events/ramadan-2026.html

## Completeness without false universality

A complete ritual app should be a library of clearly bounded traditions, not a
single generated “universal” ceremony.

### Within Hindu traditions

- Household versus temple versus priest-led scope.
- Shaiva, Vaishnava, Shakta, Smarta, Ganapatya, Saura, and region/family/
  sampradaya variants where sources support them.
- North, South, East, West, and diaspora practice as named adaptations, not
  stereotypes or one geographic toggle.
- Sanskrit plus verified regional-language instructions and meaning.
- Calendar schools shown together when dates differ.
- Received or initiatory material withheld rather than generated.

### Multiple beliefs

If Cosmic Rituals expands beyond Hindu practice, every belief system needs a
separate governed content pack with its own advisors, sources, vocabulary,
calendar, permissions, sacred-text licensing, safety rules, and participation
boundaries. Buddhist, Jain, Sikh, Jewish, Christian, Muslim, Indigenous, folk,
and secular reflective practices must never be translated into Hindu ritual
objects or ranked against one another.

The user selects a tradition. The app never infers belief from name, language,
birthplace, ethnicity, or previous use. “No tradition” and secular practice
must be first-class options.

## Non-discrimination acceptance tests

1. No practice is gated by caste, ancestry, gender, menstruation, marital
   status, sexuality, fertility, disability, income, or possession of objects.
2. Every material has a no-cost/no-object alternative when the source and
   ritual meaning allow one; where it does not, the app explains rather than
   shaming.
3. Fasting is never the default and can be omitted without a failure state.
4. Instructions never require standing, kneeling, floor sitting, vision,
   hearing, speech, precise hand movement, smoke, flame, or Sanskrit fluency.
5. A user can browse without declaring a religion.
6. Search and history do not create a religious profile or leave the device.
7. One calendar/sampradaya date is never labelled “the” date when supported
   schools differ.
8. Every mantra and action-bearing instruction resolves to a claim/source
   record; missing provenance fails the build.
9. No fear result opens donations, priest booking, product sales, urgency, or
   a paid ritual path.
10. Longer, more expensive, or priest-led practice is never presented as more
    spiritually effective.

## Now

1. Replace guide-level source presence with claim-level coverage validation.
2. Audit every mantra independently.
3. Quarantine or source the 30-muhurta interpretations and `bestTime` routing.
4. Build a typed tradition-pack model before adding another lineage or belief.
5. Add safety-precedence, no-cost-equivalence, non-discrimination, and
   commercial-decoupling tests.

## Sources and limits

- Apple App Privacy definitions:
  https://developer.apple.com/app-store/app-privacy-details/
- Apple Search API sampling frame:
  https://itunes.apple.com/search?term=hindu%20puja&country=in&entity=software&limit=50
- WHO health and religious-fasting guidance:
  https://www.emro.who.int/media/media-events/ramadan-2026.html
- Current internal content ledger: `POOJA_CONTENT.md`.
- Current calculation and source ledger: `ACCURACY.md`.

This cut does not judge a belief's truth or designate one practice canonical.
It tests attribution, consent, safety, privacy, equal access, and whether the
app accurately describes the authority it possesses.
