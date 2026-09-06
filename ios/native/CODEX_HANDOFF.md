# Codex build brief — Cosmic Rituals

Written 2026-09-06 as a handoff. Everything here is source-verified and ready to
build. Read `CLAUDE.md` first, then this. `CAPABILITY_RESEARCH.md` holds the
evidence behind each item; `ACCURACY.md` holds the method provenance for what is
already shipped.

## Non-negotiables

These are correctness constraints, not style preferences. A change that breaks
one of them is wrong even if it compiles and the tests pass.

1. **The engine never imports SwiftUI; the views never do astronomy.**
2. **Never synthesize classical content.** If a rule is not in a named printed
   source, it does not ship. No "reasonable interpretation", no filling a gap
   from a web summary, no generating a mantra or a katha.
3. **When traditions disagree, disclose the divergence.** Do not silently pick a
   school. The shipped pattern is a named school as a value type plus a visible
   note. See `AyanamshaSchools.swift` and the Bengal panjika disclosure in
   `PanchangView.swift` for the house style.
4. **Every fixture records its external source beside the expected value.** When
   a fixture fails, fix the engine or justify the fixture against its source.
   Never retune an expectation to match new output.
5. **Negative control before you call a rule tested.** Sabotage the rule, confirm
   the specific tests you expect go red actually go red, then restore and verify
   the file is byte-identical. A control that stays green means the test is
   vacuous. This has caught three vacuous tests in this codebase already.
6. **`xcrun xcresulttool get test-results summary --format json` is the pass/fail
   authority.** Do not grep xcodebuild stdout; it has reported success over a
   failing suite here.
7. **Status vocabulary is precise**: planned, implemented, built, tested,
   user-confirmed, uploaded, testing, release candidate, release-approved, live.
   A green build is not a tested product.
8. **Do not perform any distribution action.** No TestFlight upload, no App Store
   Connect mutation, no review submission. Those are the owner's, per action.

## Build and test

```
xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build-for-testing

xcodebuild -project CosmicRituals.xcodeproj -scheme CosmicRituals \
  -destination 'platform=iOS Simulator,id=0C0C1AF9-DC21-436C-9D27-88432EF15BB2' \
  CODE_SIGNING_ALLOWED=NO -derivedDataPath .derived-data test
```

Suite at handoff: 188 tests, zero failures. New files under `CosmicRituals/` are
picked up automatically by the synchronized root group; do not hand-edit
`project.pbxproj`.

---

## R1 — Split the two Panchakas · effort S · Now

**The problem.** The app ships one thing called Panchaka and the name is wrong.

**Verified.** Raman, *Muhurta*, ch. IV (3-0) distinguishes two rules:
- *Nakshatra Panchak* — the Moon transiting Dhanishta second half through
  Revati. **This is what the app currently computes and mislabels.**
- *Panchak* proper — an arithmetic dosha. Sum tithi number, weekday number,
  nakshatra number and lagna number, divide by 9, and the remainder selects the
  dosha (Mrityu, Agni, Raja, Chora, Roga). Kalaprakasika's Panchakam is the same
  construction (2-1).

**Where.** The rule lives in `CosmicRituals/Engine/PanchangSpecialWindows.swift`;
the surface string is in `CosmicRituals/Views/PanchangView.swift`.

**Do.** Rename the shipped rule to Nakshatra Panchak everywhere, including the
user-facing string and the test names. Add a disclosure line stating that the
arithmetic Panchak is a distinct rule requiring the ascendant, which this app
does not compute.

**Do not.** Implement the arithmetic rule. It needs the lagna, which is blocked
by `CLAUDE.md` line 11 and an open owner decision. See "Blocked" below.

**Acceptance.** A test asserting the user-facing label is "Nakshatra Panchak",
and a presentation-truth test asserting the disclosure text is present.

---

## R2 — Chandrabala and Tarabala verse citations · effort S · Now

**Verified.** Muhurta Chintamani, Gochara-prakarana (Haridas Sanskrit Series
185), read in Sanskrit because the Sharma English edition is print-only:
- vv. 1-4: the Moon is auspicious in houses 1, 3, 6, 7, 10, 11 counted from the
  janma rashi. **This is exactly `chandrabalaFavorableCounts`**
  at `CosmicRituals/Engine/PersonalStarEngine.swift:95` as shipped, so this is a
  citation upgrade, not a rule change.
- vv. 11-12: Tarabala counts from the birth nakshatra, mod 9, over three cycles.
- Kalaprakasika ch. XXXIII pp. 166-167 corroborates Tarabala. Raman confirms it
  needs no natal chart and that the *name nakshatra* substitutes when birth data
  is unknown.

**Do.**
1. Add both citations to the engine headers and to `ACCURACY.md`.
2. Add a disclosure for the Chandrabala **vedha cancellation** clause: an
   occupied counterpart house cancels the transit result, paired 10/4, 3/9,
   11/8, 1/5, 6/12, 7/2. This app does not compute planetary positions, so the
   clause cannot be evaluated. Say that on the surface rather than implying the
   Chandrabala shown is complete.
3. Optionally offer the name-nakshatra fallback for Tarabala when no birth
   nakshatra is set. Label it as the fallback, with its source.

**Acceptance.** A test asserting the favorable set equals `[1,3,6,7,10,11]` with
the verse reference in the test name, plus a presentation-truth test for the
vedha disclosure.

---

## R3 — Name the sunrise convention · effort S · Now

**Verified 3-0.** Drik Panchang applies atmospheric refraction, uses the sun's
**upper limb**, and ignores observer elevation unless the user opts in. The
app's −0.8333° altitude threshold is that same convention. The disc-centre
alternative shifts sunrise by roughly two minutes.

Two competing claims were **refuted 0-3**: that Drik uses the disc centre, and
that it ignores refraction. Do not reintroduce either.

**Do.** State the convention on the calculation surface, next to the existing
sunrise-anchoring note: upper limb, refraction included, elevation excluded, and
the approximate two-minute size of the alternative.

**Acceptance.** Presentation-truth test for the disclosure string.

---

## R4 — Gaudiya Ekadashi corroborating citation · effort S · Now

**Verified 3-0.** Hari Bhakti Vilasa's arunodaya test is two muhurtas, 1 h 36
min, which is exactly the four ghatikas `VrataDecisionEngine` implements. The
ISKCON Calendar Committee research paper paraphrases without giving a verse
locus, so cite it as corroboration beside Kane, not as the primary source.

**Do.** Add the citation to the engine header and `ACCURACY.md`.

---

## R5 — Surface Ekadashi and Janmashtami · effort M · Next

**Status.** `VrataDecisionEngine` is implemented and tested. Neither result
appears anywhere in the UI. This is wiring, not new astronomy.

**Do.**
1. On the panchang surface, show today's Ekadashi when one falls, with **both**
   the smarta and the vaishnava day, and the reason they differ.
2. Flag kshaya Ekadashi explicitly. In 2026 the Yogini (10/11 July) and
   Prabodhini (20/21 November) splits are kshaya, and 26 May is an
   arunodaya-vedha split, so both of Kane's clauses are live and the UI must not
   collapse them into one label.
3. Add Janmashtami to the festival list via the Tithitattva cascade.
4. Never present one tradition's day as *the* date.

**Acceptance.** Extend `VrataDecisionTests` with the presentation strings, and
add a UI test that is time-independent. Note the trap that bit the prahar UI
test: a test run before sunrise sees the live-counter refusal path. Do not write
a test whose result depends on wall-clock time.

---

## R6 — Kalaprakasika Janmashtami as a second school · effort M · Next

**Verified 3-0.** Kalaprakasika ch. XLIII pp. 237-238 decides Sreejayanthi by
**moonrise**, not by nishita, and takes the later of two tithis when both touch
one day. That is a genuinely different South Indian school, not a variant
reading.

**Do.** Add it as a named school beside the Tithitattva cascade, using the
existing moonrise engine. Show both results when they differ. Follow the
`AyanamshaSchool` pattern: a value type per school, no default that hides the
other.

**Guard.** The moonrise code is currently quarantined. Per `CLAUDE.md` it may
only be surfaced once it has independent fixtures and a visible precision
disclosure. Ship those in the same change or do not ship the feature.

---

## Blocked — do not build

- **Anything requiring the ascendant.** `CLAUDE.md` line 11 forbids reintroducing
  ascendant machinery, and the owner has not yet decided whether to carve an
  exception. This blocks the arithmetic Panchak (R1) and all event-muhurta.
  Cycle-3 evidence **refuted 0-3** the claim that classical electional practice
  judges from panchanga limbs plus the moment's rising sign alone, which weakens
  the case for an electional-only exception. Leave it alone until the owner
  rules.
- **Muhurta Chintamani in English.** Sharma, Sagar 1996, is print-only.

## Do not act on these — refuted

- Drik uses the centre of the solar disc (0-3).
- Drik ignores refraction (0-3).
- A Kalaprakasika Varjyam ghatika-per-nakshatra table (1-2). The app's Varjyam
  stays labelled "standard almanac convention" until a verse-level source exists.
- Numeric vedha thresholds by tithi (1-2).
- Dharma Sindhu condensation claims (0-3).

## Unresearched, not refuted

The full printed daily page — Agnivasa, Shivavasa, Homahuti, Baana, Yogini, the
Tamil Amrita/Siddha/Marana yogas, Nalla Neram, Gowri Panchangam. Zero claims
survived verification. These need the almanacs read directly, not another web
search. Do not implement any of them from a vendor page.
