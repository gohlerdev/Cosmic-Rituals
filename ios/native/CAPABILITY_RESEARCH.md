# Capability research — 2026-08-27

Deep multi-source research run (104 agents: 5 search angles, source fetch,
3-vote adversarial verification per claim, cited synthesis). Recorded here so
the next development cycle starts from evidence rather than memory. Confidence
and vote counts are the verification harness's own, not a summary judgement.

**Excluded from this run** because it was already planned: festival/vrata calendars.

## Summary

Across the five research questions, the verified evidence points to four concrete gap classes for Cosmic Rituals. (1) Capability: the largest honest gap is not more panchang limbs — it is the ascendant/lagna layer. Classical event-muhurta (marriage, griha pravesh, vehicle, business opening) requires lagna shuddhi and benefic/malefic house placement, so the five limbs alone cannot produce event recommendations without fabricating them; the app's own architecture (no ascendant code at all, quarantined low-precision graha positions) makes this the gating dependency for every event-muhurta feature, and mypanchang ships exactly this as Lagna Pravesh tables plus daily transits. (2) Presentation: traditional Hindu timekeeping — eight-prahar clock, Ishta Kaal, live Ghati/Vighati/Pal/Vipal — is now shipped by at least two independent vendors (Hindu Calendar and Drik Panchang's own iOS app) and is entirely absent from Cosmic Rituals, though it needs no new astronomy. (3) Regional service: serving Tamil/Malayalam/Bengali/Odia reckonings requires a solar-month layer named from the sun's rashi, layered on the sankranti solver the app already has, plus multi-school ayanamsha selection (Lahiri/Raman/KP/Thirukanitham) that the app currently hard-commits to Lahiri at a single sidereal chokepoint — and Bengal in particular has two live competing computational lineages (Bisuddhasiddhanta vs Gupta Press), so no single canonical tithi can be shown honestly there. (4) Positioning: the offline, zero-collection, no-SDK architecture is a measurable outlier — 93% of religious Android apps embed tracking SDKs, devotional apps have a documented record of monetizing worship data (Muslim Pro→X-Mode→US military contractors; pray.com's 10 SDKs plus purchased religious-affiliation data), the leading Panchang app's own App Store label declares cross-app ad tracking, and ~76% of surveyed subscription services used at least one dark pattern — while Apple's own rules confirm an on-device-only app owes no ATT prompt and can legitimately declare "Data Not Collected."

## Findings

### 1. The gating capability gap is the ascendant (lagna) layer, not more panchang limbs: honest event-muhurta for marriage, griha pravesh, vehicle purchase, shop opening, and document signing requires lagna shuddhi — ascendant purity with benefics in kendras/trikonas and malefics out — which the five limbs cannot supply. The same layer is what mypanchang ships publicly as per-city Lagna Pravesh tables and daily planetary transits.

**Confidence:** high · **Verification vote:** 3-0 (lagna shuddhi requirement); 2-1 (mypanchang Lagna Pravesh/transits)

mypanchang states plainly: "Lagna shuddhi removes most evils and without lagna shuddhi it gives all bad yogas," and specifies benefics (Mercury, Jupiter, Venus) in kendra (1/4/7/10) and trikona (5/9) with malefics (Sun, Mars, Saturn, Rahu, Ketu) out of kendras. Its Panchaka Rahita Vidhi takes FOUR inputs — tithi number, vara number, nakshatra number, and lagna sign number — summed and divided by 9, so even the panchaka screen the app could otherwise compute needs the ascendant. Independent corroboration from onlinejyotish.com (identical four-input formula, "A pure Lagna is the foundation of any auspicious Muhurta"), astroshastra.com, and atmanandanatha.in, which all describe the standard two-stage model: panchanga shuddhi picks the day, lagna shuddhi picks the time within it. A deliberate search for the opposing position ("panchanga alone sufficient") found no credible source.

The engineering split matters and was verified in-tree, correcting the original claim's framing: ASCENDANT machinery is genuinely absent (grep finds zero lagna/ascendant implementation; only a comment at Engine/CelestialRiseSet.swift:28 referencing "the family's ascendant computation"). GRAHA machinery is NOT absent — `struct GrahaPosition` exists at Engine/PanchangModels.swift:351 and `CosmicEngine.getGrahaPositions(date:)` at Engine/CosmicEngine.swift:1414, unrouted to any View and quarantined for low precision per CLAUDE.md. So planetary transits are a precision/disclosure problem, not a from-scratch build.

Useful decomposition: the lagna itself needs only sidereal time + latitude + ayanamsha — no planetary longitudes — so a Lagna Pravesh table and the Panchaka Rahita screen are reachable well before the benefic/malefic kendra test, which needs the seven grahas plus Rahu/Ketu at muhurta-grade precision. mypanchang's live Lagna table (verbatim, 1 Jan 2026, Ujjain: "Dhanus 06:01:33 Pushkara 07:31:02 Makara 08:06:43 Pushkara 08:58:40") shows the concrete shipped artifact: per-day rise times for all 12 rashis with Pushkara navamsha sub-times.

Caveats: the mypanchang/interpret.html sentence originally cited for Lagna Pravesh tables is a hedged generic ("The panchangam may also includes...") about panchangams in general — the product claim was re-verified against the live per-city tables instead. The transits half rests partly on vendor promotional copy (Pundit Mahesh Shastriji's own 2026 edition announcement). "Cannot be computed honestly" is a normative judgment consistent with the app's own no-fabrication policy, not a source assertion — commercial services do publish nakshatra/tithi-only event-muhurat lists.

**Sources:**
- http://www.mypanchang.com/interpret.html
- https://www.mypanchang.com/panchang.php?getdata=getcity&yr=2026
- https://onlinejyotish.com/astrology-tools/today-panchaka-lagnas.php
- https://www.astroshastra.com/Muhurta/muhurtakundli.php
- /Users/psy/Documents/Cosmic-Rituals/ios/native/CosmicRituals/Engine/CosmicEngine.swift
- /Users/psy/Documents/Cosmic-Rituals/ios/native/CosmicRituals/Engine/PanchangModels.swift

### 2. Traditional Hindu timekeeping UI — an eight-prahar clock (Purvanha, Madhyanha, Aparanha, Sayan, Pradosh, Nishith, Triayama, Usha), location-specific Ishta Kaal, and live Ghati/Vighati/Pal/Vipal counters — is a shipped feature at multiple independent vendors and is entirely absent from Cosmic Rituals, despite requiring no new astronomy.

**Confidence:** high · **Verification vote:** 3-0

Listing text verified verbatim (v8.7.2, updated 2026-08-13): "Unique Hindu Clock showing the eight pahars (prahars) of the day. Purvanha, Madhyanha, Aparanha, Sayan, Pradosh, Nishith, Triayama, Usha", "Ishta kaal for your place (Hindu Time)", "Shows real time Ghati, Vighati or Pal or Kal, Vipal or Lipt or Vikal", and "Sankalp Mantra and Disha Yantra (compass) showing the hindu direction for ease of doing pooja." The Apple listing for the same family (id1187338109, v5.0) independently carries the Ishta Kaal / Ghati-Vighati text and a compass. The marketing-copy objection is defeated three ways: a user review references the feature in use ("I especially like the Hindu time in which a day has 60 hours or ghatis"), and a SECOND unrelated vendor — Drik Panchang's own iOS app, id1321271821 — ships "a Vedic time keeping clock in Ghati, Pala and Vipala."

Absence verified in-tree, not assumed: grep over the repo returns no "prahar" and no "ishta". "Ghati" appears only as an internal computation unit in Engine/PanchangSpecialWindows.swift (varjyamStartGhatis / amritStartGhatis, treating a nakshatra span as 60 ghatis) — never as a user-facing live counter. No magnetometer or compass exists anywhere in the app.

Three qualifications that narrow the claim: (1) 'Differentiated' is overstated — with two vendors shipping it this is an emerging category norm, which makes the gap more real but the framing wrong. (2) The Sankalp helper is not a clean zero: PoojaVidhiCatalog.swift line 579 already has a "State the sankalpa" step and 8 sankalpa references. What is absent is an auto-composed sankalpa naming samvatsara/masa/paksha/tithi/nakshatra/desha — and that absence is a deliberate policy boundary (lines 56 and 709 push formal sankalpa to a qualified priest; CLAUDE.md and POOJA_CONTENT.md forbid synthesizing it). Any adoption must respect that. (3) Cosmic Rituals' existing Disha Shula (PanchangYogaEngine.swift) is a travel-direction rule, a different artifact from a magnetometer Disha Yantra — do not conflate them.

Practical note: prahars, Ishta Kaal, and ghati counters are all derived from the sunrise/sunset instants the app already computes to sub-second resolution. This is the cheapest high-visibility item in the whole analysis — presentation work over an existing engine, with no new fixture or accuracy exposure.

**Sources:**
- https://play.google.com/store/apps/details?id=com.alokmandavgane.hinducalendar&hl=en_US
- https://apps.apple.com/us/app/hindu-calendar-panchang/id1187338109
- https://apps.apple.com/us/app/hindu-calendar-drik-panchang/id1321271821
- /Users/psy/Documents/Cosmic-Rituals/ios/native/CosmicRituals/Engine/PanchangSpecialWindows.swift

### 3. Professional-tier panchang software treats ayanamsha as a user-selectable setting across schools — Lahiri/Chitra Paksha, Raman, Krishnamurti (KP), Thirukanitham, plus a user-defined ayanamsha parameterized by base year and annual precession rate. Cosmic Rituals hard-commits to Lahiri at a single sidereal chokepoint, locking every limb, muhurta, and nakshatra boundary to one school.

**Confidence:** medium · **Verification vote:** 2-1

Astro-Vision StarClock VX 2.0 (© 2002–2026, current) states verbatim: "various ayanamsa settings such as Chitra Paksha ayanamsa or Lahiri ayanamsa, Raman ayanamsa, Krishnamurthy ayanamsa, Thirukanitham ayanamsa along with a user defined ayanamsa," and independently confirms the most falsifiable detail — users "choose from either the Fagen-Allen ayanamsa or any other ayanamsa method of your choice by selecting the Base year and the precession per year." To defeat the single-vendor-marketing objection, a second unaffiliated package was checked: Jagannatha Hora (vedicastrologer.org, free/non-commercial, the most widely used professional Vedic desktop tool) supports Lahiri, Raman, Deva-datta, Krishnamoorthy, Usha-Shashi, Fagan, tropical, plus user-defined, and supports switching schools PER SYSTEM (Lahiri for Parashari, Krishnamurti for KP).

The Cosmic Rituals half is confirmed structurally, not inferred: Engine/CosmicEngine.swift:112 defines the only ayanamsha function `lahiriAyanamsha(year:)` over hard-coded constants (C0 = 23.85709239 at line 18), and line 1480 is the single sidereal chokepoint — `return normalize360(tropical - lahiriAyanamsha(year: year))`. Because every limb passes through that one `siderealize`, "every derived limb is locked to one school" is literally true. A repo grep for "ayanam" returns nine hits, none a Picker or @AppStorage; PanchangView.swift:1212 is a static provenance label ("Meeus Sun and Moon series · Lahiri (Chitra Paksha) ayanamsha"), not a control. ACCURACY.md:26 and ARCHITECTURE.md:92 state the same commitment.

CONFIDENCE IS MEDIUM AND "professional-tier" IS LOAD-BEARING. The split vote (2-1) and the verifier's own qualification agree: this is confirmed for desktop astrologer software, NOT for leading consumer panchang sites. Search evidence indicates DrikPanchang uses Lahiri by default with no confirmed user-facing selector, and a separate claim that a mass-market Android Hindu Calendar app ships Raman/KP ayanamsha was REFUTED 0-3. So this must not be reported as "every competitor offers this." The architectural point stands on its own regardless: the single chokepoint means multi-school support is a comparatively contained change if it is ever wanted — but every published fixture in ACCURACY.md is Lahiri-based, so a school switch would need its own fixture set per school or it becomes an unverified claim.

**Sources:**
- https://www.indianastrologysoftware.com/professional/panchang-software.php
- https://www.vedicastrologer.org/
- /Users/psy/Documents/Cosmic-Rituals/ios/native/CosmicRituals/Engine/CosmicEngine.swift
- /Users/psy/Documents/Cosmic-Rituals/ios/native/CosmicRituals/ACCURACY.md

### 4. Serving Indian regional reckonings simultaneously requires a solar-month calendar layer (Tamil/Malayalam/Bengali/Odia months named from the sun's rashi — Chiththirai, Vaikasi, Aani...) distinct from the Amanta/Purnimanta lunar split the app already computes; and Bengal has two live competing computational lineages, so no single canonical tithi or festival date can be presented there honestly.

**Confidence:** high · **Verification vote:** 3-0 (both the solar-month layer and the Bengali lineage split)

SOLAR-MONTH LAYER: mypanchang states verbatim "Tamil, Malayalam, Bengali uses solar months and the rules on how month start is determined is different, but rest of information remains same," and names them from the rashis: "Chiththirai (Mesha), Vaikasi (Vrishabha), Aani (Mithuna)...". Corroborated independently by drikpanchang.com and Wikipedia (Mesha Sankranti): the Tamil system is purely solar, months correlate to the twelve rashis, nirayana Mesha Sankranti (~14 April) begins the Tamil year, and the Tamil calendar is "structurally similar to the Malayalam, Bengali and Odia calendars."

Gap confirmed in-tree: Engine/LunarCalendarEngine.swift computes sankranti instants (`nextSankranti`, sidereal Lahiri Sun entering a rashi) and Amanta/Purnimanta masa with Adhika/Kshaya, but `masaNames` holds only the twelve Sanskrit LUNAR names. Repo-wide grep for Chiththirai/Vaikasi/Panguni/Chingam/Kollam/Boishakh/solarMonth returns zero code hits (only an unrelated `Kollam` city row in world_cities.tsv). Crucially, the sankranti solver — the hard astronomical part — already exists. The missing work is month naming plus the differing month-start conventions (Tamil/Malabar/Bengal/Odia rules on which civil day a sankranti's month begins, relative to sunrise or midnight). That is real but incremental, not a new astronomical model.

BENGALI MULTI-LINEAGE PROBLEM: the Bisuddhasiddhanta Panjika was created (Madhab Chandra Chattopadhyay, 1297 BE / 1890 AD) precisely because "The 19th century Bengali almanacs that gave details of tithi, nakshatra, etc. were generally not in conformity with the position of planets" — its stated principle being "A true panjika has to tally with the scientific observation." The competing-lineages half is NOT in that Wikipedia article and rests on three independent corroborations: Calendar Wiki ("two schools of panjika-makers in Bengal - Driksiddhanta (Bisuddhasiddhanta Panjika) and Odriksiddhanta (Gupta Press, PM Bagchi, etc.) Sometimes, they lay down different dates for particular festivals"), scroll.in journalism (Gupta Press "follows Suryasiddhanta with the original format while the version with 'corrected' scripture is called Visuddhasiddhanta"), and nityapanchangam.com. The divergence is live, not historical: for Durga Puja 2005 two different date sets circulated, with community pujas following Gupta Press and Belur Math/Ramakrishna Mission following Bisuddhasiddhanta.

Qualifications: Odia and Bengali practice is hybrid — civil/solar months for dating, Purnimanta (Odia) or lunar tithi (Bengali Panjika) for religious observance — which widens the work rather than removing it. Bangladesh's state Bengali calendar has been reformed to fixed-length rule-based months rather than true sidereal sankranti reckoning, while West Bengal's Panjika remains sidereal-solar. The 1955 Saha Calendar Reform Committee report was not checked (search budget exhausted) and would be the stronger scholarly primary source for the drik-vs-siddhantic split. Direct consequence for this app: a Bengali-serving panchang must NAME which school it computes rather than showing one canonical date — which fits the app's existing provenance-labeling discipline.

**Sources:**
- http://www.mypanchang.com/interpret.html
- https://en.wikipedia.org/wiki/Vishuddha_Siddhanta_Panjika
- https://en.wikipedia.org/wiki/Mesha_Sankranti
- https://scroll.in/
- /Users/psy/Documents/Cosmic-Rituals/ios/native/CosmicRituals/Engine/LunarCalendarEngine.swift

### 5. The offline, zero-SDK, zero-collection architecture is a measurable category outlier rather than a soft marketing point: 93% of religious Android apps (1351/1454) embed at least one tracking SDK, Google trackers appear in 78% and Facebook in 14.1%, and a Panchang app is named among the problem cases.

**Confidence:** high · **Verification vote:** 2-1 on the SDK statistics; 3-0 on the named Panchang case

Numbers extracted directly from the primary PDF (pypdf, 16 pages), not from a quote or summary — Samarasinghe, Adhikari/Kapoor, Mannan & Youssef, "No Salvation from Trackers: Privacy Analysis of Religious Websites and Mobile Apps," DPM 2022 / ESORICS workshops, Springer LNCS 13619: "1351/1454 (93%) of religious Android apps included tracking SDKs" and "a total of 7398 tracking SDKs (203 unique) on 1454 religious Android apps... most tracking SDKs in apps were also from Google (1132/1454, 78%) and Facebook (205/1454, 14.1%)." Methodology disclosed: 2512 apps scraped by religion keywords, manually filtered to 1454; static analysis via LibRadar (published precision 97.9%, ICSE'16). The "outlier" inference is logically sound — zero-SDK apps are a subset of the 7% (103/1454) with no tracking SDK, so ≤7% is a valid upper bound.

The named Panchang case (3-0, verified verbatim in §5 of the same PDF): "jainpanchang.in and orthodoxfacts.org third party domains were included in com.mosync.app Jain Panchang... religious Android apps" — flagged malicious by VirusTotal per the paper's §3.5 methodology — and "Jain Panchang requires the WRITE SECURE SETTINGS Android permission, allowing the app to read/write secure systems settings, which is not supposed to be used by third-party apps." Note the claim is precisely scoped: a third-party domain CALLED BY the app was flagged, not the app itself (Jain Panchang is not in the 29/1454 VirusTotal-flagged-app list).

FOUR QUALIFICATIONS THAT MUST TRAVEL WITH THESE NUMBERS: (1) "Tracking SDK" is LibRadar's broad third-party-library label; the paper itself notes "Google Mobile Services is used as a development aid," so part of the 93% is bundled Play Services/Firebase infrastructure — do NOT restate as "93% deliberately track users." (2) Android only; the paper analyzed no iOS apps, so this is a category-adjacent proxy, not a measurement of the App Store shelf Cosmic Rituals competes on. (3) No per-religion breakdown — the figures are pooled across four religions with no Hindu-app or panchang-app subgroup. (4) 2022 data (crawl April 26 – May 7, 2022); cite as such, not as current state. The paper also cites Peng et al. (IMC'19) warning that VirusTotal engines may misclassify domains, and jainpanchang.in is plausibly the publisher's own domain — a category flag is not proof of malware.

**Sources:**
- https://users.encs.concordia.ca/~mmannan/publications/Religious-sites-DPM2022.pdf
- https://doi.org/10.1007/978-3-031-25734-6_10

### 6. Devotional apps have a documented record of monetizing worship data, and the leading Panchang app's own App Store label declares cross-app ad tracking — making Cosmic Rituals' posture a concrete, checkable contrast rather than a vague one.

**Confidence:** high · **Verification vote:** 3-0 on both the historical cases and the App Store label

HISTORICAL CASES (verbatim from the DPM 2022 PDF): "a prayer app (Muslim Pro)... has leaked user location data to a broker (X Mode), which in turn had sold the same information to its contractors (including US military contractors)"; and "com.prayapp app that embedded 10 tracking SDKs (including Google and Facebook)... the app owners also purchase data (e.g., gender, age, ethnicity, religious affiliation) from third parties for better profiling." Independently corroborated, not circular: Vice/Motherboard performed its own network interception; US Navy Cdr. Tim Hawkins confirmed SOCOM's use of the data; Apple and Google both banned X-Mode in Dec 2020. For pray.com, BuzzFeed quotes the company's OWN privacy policy describing supplementation from "third-parties such as data analytics providers and data brokers" including "your gender, age, religious affiliation, ethnicity, marital status, household size and income, political party affiliation" — a first-party admission, the strongest evidence class available.

Contradicting evidence examined: Bitsmedia publicly denied the story ("Muslim Pro did not give your data to the US military... never will"), but that denies a DIRECT military sale and identified-data sharing, not the two-hop flow actually asserted — and Muslim Pro simultaneously announced terminating its X-Mode relationship, conceding the relationship existed. Qualification, not refutation.

APP STORE LABEL (verified on two independent regional storefronts, US and IN, ruling out summarizer error): DrikPanchang's iOS app (id1321271821, seller Adarsh Mobile Applications LLP — the official operator of drikpanchang.com, so not a knockoff) declares under Apple's standard heading "The following data may be used to track you across apps and websites owned by other companies:" — Identifiers, Usage Data. Declared collection purposes: Third-Party Advertising, Developer's Advertising or Marketing, Analytics, Product Personalization, App Functionality; identifier subtypes User ID and Device ID; usage subtypes including Advertising Data. Since Apple defines "Data Used to Track You" precisely as linking to third-party data for targeted advertising or sharing with data brokers, the cross-app-ad-tracking gloss is definitional, not editorial.

Qualifications: "market-leading" is unsourced and should be softened — DrikPanchang has 1M+ Play downloads and ~207K reviews, but mPanchang self-markets as "No. 1" and several rivals also claim 1M+; name the app directly instead. Privacy labels are developer-self-reported and unverified by Apple; no runtime SDK inspection was done (an AppBrain cross-check returned HTTP 403). The advertising/analytics purposes are declared under "Data Not Linked to You" with tracking declared separately — the claim asserts both without conflating them. Historical cases are 2020–2022 snapshots and must stay in past tense: X-Mode/Outlogic was subject to an FTC order in Jan 2024 barring sale of sensitive location data, and pray.com's current SDK set was not re-measured. Note two related sub-claims were REFUTED (0-3 and 1-2): specific DrikPanchang IAP pricing as a category price anchor, and user reviews complaining about interstitial ads and clipboard access — do not use those.

**Sources:**
- https://users.encs.concordia.ca/~mmannan/publications/Religious-sites-DPM2022.pdf
- https://www.vice.com/en/article/g5bq89/muslim-pro-location-data-military-xmode
- https://www.buzzfeednews.com/article/emilybakerwhite/apps-selling-your-prayers
- https://www.aljazeera.com/news/2020/11/18/muslim-pro-app-denies-selling-user-data-to-us-military
- https://apps.apple.com/us/app/hindu-calendar-drik-panchang/id1321271821
- https://apps.apple.com/in/app/hindu-calendar-drik-panchang/id1321271821

### 7. Apple's own rules make the on-device-only posture legally clean and declarable: an app that transmits nothing owes no AppTrackingTransparency prompt at all (not merely a deferred one) and can legitimately declare "Data Not Collected" — while every app submission must account for what any embedded third-party SDK collects, not just its own code.

**Confidence:** high · **Verification vote:** 3-0 on both the ATT exemption and the SDK accountability rule

Both quotes verified verbatim by direct fetch of Apple's developer documentation (August 2026, current). SDK ACCOUNTABILITY: "In order to submit new apps and app updates, you must provide information about your privacy practices in App Store Connect. If you use third-party code — such as advertising or analytics SDKs — you need to describe what data the third-party code collects, how the data may be used, and whether the data is used to track users." The inference that a developer must account for every embedded SDK is stated by Apple, not derived: "Developers are responsible for all code included in their apps. If you are unsure about the data collection and tracking practices of code used in your app that you didn't write, we suggest contacting the developer of the SDK" — extended explicitly to third-party SSO. The second page closes the obvious loophole: "You need to identify all of the data you or your third-party partners collect" and "even if you collect the data for reasons other than analytics or advertising, it still needs to be declared."

ATT EXEMPTION: under the heading listing uses that "are not considered tracking, and do not require user permission through the AppTrackingTransparency framework," the first bullet reads "When user or device data from your app is linked to third-party data solely on the user's device and is not sent off the device in a way that can identify the user or device." For a no-network app the stronger footing is Apple's definition of tracking itself — cross-company linking for targeted advertising or sharing with data brokers — which a fully offline app falls outside entirely. The parallel privacy-label rule hinges on data being transmitted off device, so "Data Not Collected" is a legitimate declaration.

Currency checked deliberately: a search for rescission found zero contradicting evidence, and the Aug 2026 ATT news (German Bundeskartellamt settlement, EU changes) concerns prompt wording and parity with Apple's own apps, not the definition of tracking or the exemption list. The iOS 17+ signed-SDK and privacy-manifest requirements tighten rather than relax SDK accountability.

One qualification worth keeping: ATT is independently required to READ the IDFA even with no tracking intent, so the exemption is really "no tracking AND no advertising-identifier access" — an app could compute purely on-device and still owe a prompt if it called ASIdentifierManager or embedded an ad SDK. For a no-network, no-ad-SDK app this changes nothing. The claim also establishes a declaration obligation, not that Apple audits per-SDK compliance.

**Sources:**
- https://developer.apple.com/app-store/user-privacy-and-data-use/
- https://developer.apple.com/app-store/app-privacy-details/

### 8. Subscription dark patterns have a measured prevalence baseline: an ICPEN sweep of 642 subscription websites and apps (FTC participating, conducted Jan 29–Feb 2, 2024) found ~76% used at least one possible dark pattern and ~67% used more than one, with the single most common practice being inability to turn off auto-renewal within the purchase flow.

**Confidence:** medium · **Verification vote:** 3-0 on the numbers, but attribution and interpretation both required correction

ftc.gov and icpen.org both returned HTTP 403 to direct fetch, so the primary press-release wording was confirmed through two independent secondaries quoting it verbatim. Hunton Andrews Kurth: "27 authorities from 26 countries reviewed 642 websites and mobile apps"; "approximately 76% of the websites and apps it reviewed used at least one dark pattern"; "nearly 67% used multiple dark patterns"; sweep dates January 29 to February 2, 2024. The Record independently confirms 642 sites/apps, 26 nations, 76%, and 67%. ICPEN published its own primary methodology report behind these.

TWO CORRECTIONS THE ORIGINAL CLAIM NEEDED. (a) Attribution: the 642-site subscription sweep was ICPEN's, with the FTC participating as a member. GPEN ran a SEPARATE concurrent sweep of over 1,000 sites/apps by 26 privacy authorities on privacy-related dark patterns (~97% had at least one). Writing "FTC with ICPEN/GPEN" folds GPEN into a sweep it did not conduct; cite as "ICPEN sweep (FTC participating), announced July 10, 2024." (b) These are POSSIBLE dark patterns, not adjudicated violations — the FTC stated directly that it "did not determine whether the practices were illegal" and that "there were no findings as to whether any of these instances rose to the level of law violations." Never imply 76% of subscription apps break the law.

Confidence is medium because the interpretive tail — "a measurable baseline against which an app's subscription flow can be positioned as non-extractive" — is the researcher's inference, not a source assertion, and is statistically loose: the 642 sites were each selected by participating authorities as subscription services of interest, not drawn as a random probability sample, and the flags are qualitative human judgments. Treat it as an industry prevalence indicator, not a representative benchmark.

The directly actionable detail for Cosmic Rituals' StoreKit 2 flow: the single most common practice found was the consumer's inability to turn off auto-renewal within the purchase flow, and the two dominant categories were "sneaking" and "interface interference." Note that a stronger-sounding related claim — that "sneaking" specifically appeared in 81% of studied sites — was REFUTED 0-3 and must not be used.

**Sources:**
- https://techcrunch.com/2024/07/10/ftc-study-finds-dark-patterns-used-by-a-majority-of-subscription-apps-and-websites
- https://www.hunton.com/privacy-and-information-security-law/ftc-and-consumer-protection-networks-review-use-of-dark-patterns
- https://therecord.media/ftc-audit-finds-dark-patterns-global
- https://www.icpen.org/sites/default/files/2024-07/Public%20Report%20ICPEN%20Dark%20Patterns%20Sweep.pdf
