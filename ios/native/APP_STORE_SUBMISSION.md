# App Store submission copy · version 1.0 (build 5)

> **Status: TESTING ONLY.** This is a release-preparation draft, not authorization
> to select a build for the App Store version, add the version or subscriptions for
> review, submit for App Review or Beta App Review, or release publicly. Keep the
> App Store version on manual release until explicit approval is given.

This file is the source of truth for the first Premium release. Preserve the existing
App Store Connect contact name, phone number, and email; do not invent reviewer contact
details.

## Current testing snapshot

Verified in App Store Connect on July 28, 2026:

- App version 1.0 is **Prepare for Submission**, has no App Store build selected, has
  no product-page screenshots or release metadata populated, and uses **manual release**.
- TestFlight build 1.0 (5) finished processing and is **Testing**. The internal group
  has two testers; the existing external testing group also has two testers and no
  public link. No App Review or new Beta App Review action was taken while preparing
  this checklist.
- Subscription group `22270515` (`Cosmic Rituals Premium`) and both products remain
  **Prepare for Submission** and have not been added for review.
- Annual Apple ID `6795562945`: USD 49.99 base price, all 175 storefronts, free for
  the first two weeks from July 28, 2026 with no configured end date.
- Monthly Apple ID `6795566735`: USD 6.99 base price, all 175 storefronts, free for
  the first two weeks from July 28, 2026 with no configured end date.

This is a dated evidence snapshot. Re-check every mutable App Store Connect status
before any future submission.

## Product page

**Name:** Cosmic Rituals

**Subtitle:** Panchang, Muhurta & Pooja

**Promotional text:** Plan sacred time with a location-aware Panchang, transparent
muhurta guidance, and 12 sourced, step-by-step Pooja Vidhis that remain available
offline.

**Keywords:**

`panchang,muhurta,puja,pooja,vidhi,hindu,vedic,nakshatra,tithi,calendar,mantra,festival`

**Description:**

Cosmic Rituals brings precise sacred-time planning and careful household practice into
one private, native app.

LOCATION-AWARE PANCHANG

Choose an offline city or use Current Location to calculate Vara, Tithi, Nakshatra,
Yoga, Karana, sunrise, sunset, and independently solved transition times for the civil
day and time zone you selected.

MUHURTA INTELLIGENCE

Explore all 15 daytime and 15 nighttime muhurtas, along with Rahu Kala, Yamaganda,
Gulika, Abhijit, Dur Muhurta, Choghadiya, and Hora. Current intervals are highlighted
against the clock, while polar-day limitations and calculation fallbacks are disclosed
instead of hidden.

12 OFFLINE POOJA VIDHIS

Search daily, deity, festival, vrata, life-event, and planetary guides. Each guide
provides preparation, a material checklist, ordered steps, optional short public
mantras in Devanagari and transliteration, plain-language meanings, safety notes,
respectful closure, source notes, and a focused guided mode.

TRADITION-AWARE BY DESIGN

Household guides are clearly separated from priest-recommended rites. Family, temple,
regional, and sampradaya practice takes precedence. Cosmic Rituals does not synthesize
initiatory bija-mantras, nyasa, homa, formal kalasha installation, or supposedly
universal priestly procedures.

PRIVATE AND ACCESSIBLE

Calculations, saved location preferences, Pooja searches, and checklists remain on your
device. There are no advertising, tracking, analytics, or account SDKs. The interface
supports Dynamic Type, VoiceOver labels, Reduce Motion, light and dark appearances,
iPhone, and iPad.

Cosmic Rituals Premium is available as monthly and annual auto-renewable subscriptions.
Eligible customers receive the introductory offer shown by the App Store. Payment,
renewal, eligibility, cancellation, and restoration are handled securely through Apple.

Traditional calendars and ceremonial practice vary. For consequential timing or formal
rites, confirm the convention with a qualified practitioner.

**What’s New in 1.0:**

- Location-aware Panchang with independently solved transitions
- All 30 day and night muhurtas, calendar, Hora, and Choghadiya
- 12 sourced offline Pooja Vidhis with checklists and guided mode
- Private on-device calculations and accessible cosmic-glass design
- Monthly and annual Premium plans with an eligible 14-day introductory trial

## URLs

- Privacy Policy: <https://gohlerdev.github.io/Cosmic-Rituals/privacy/>
- Terms of Use: <https://gohlerdev.github.io/Cosmic-Rituals/terms/>
- Support URL: <https://gohlerdev.github.io/Cosmic-Rituals/support/>
- Marketing URL: <https://gohlerdev.github.io/Cosmic-Rituals/>

## App Review notes

Cosmic Rituals does not require an account or demo credentials.

On first launch, the app presents the native StoreKit subscription screen. Use either
the monthly or annual sandbox product. An eligible sandbox Apple Account will see the
two-week free introductory offer; an ineligible account correctly sees standard
pricing without a free-trial claim.

Products:

- `com.cosmic.rituals.premium.annual`
- `com.cosmic.rituals.premium.monthly`

After purchase, the main experience unlocks immediately. Restore Purchases is available
on the subscription screen. Subscription management, Privacy, Terms, and Support are
also available from the in-app appearance/settings sheet.

For location testing, choose the visible offline city flow; precise location permission
is optional. The Pooja destination is the fourth item in the main navigation. Its 12
guides, sources, materials, and guided steps work offline after access is unlocked.

The app uses StoreKit-signed `Transaction.currentEntitlements`; it has no local trial
timer or reviewer bypass. It uses only Apple-provided encryption and declares no
non-exempt encryption.

## Subscription review metadata

| Product | Display name | Customer description |
| --- | --- | --- |
| Annual | Premium Annual | Full access, billed yearly after trial. |
| Monthly | Premium Monthly | Full access, billed monthly after trial. |

Use the branded subscription screen as the App Review Screenshot for both products.
The screenshot is for review only and must clearly show both plans and the service being
offered. The first auto-renewable subscriptions must be submitted with app version 1.0.

## Privacy and compliance answers

- **App Privacy:** No, the developer and third-party partners do not collect data from
  this app. Location, date, time zone, searches, preferences, and calculations are
  processed on device; Apple separately processes App Store purchases.
- **Tracking:** No.
- **Advertising identifier:** Not used.
- **Export compliance:** No non-exempt encryption. The generated Info.plist includes
  `ITSAppUsesNonExemptEncryption = NO`.
- **Login:** None.
- **User-generated content, chat, social networking, ads, gambling, contests, medical
  treatment, violence, sexual content, controlled substances:** None.
- **Unrestricted web access:** No. User-initiated links open bounded policy, source,
  support, and Apple subscription-management destinations.
- **Release:** Manual release. Keep version 1.0 unsubmitted and do not make it publicly
  available until explicit approval is given after testing.

Content-rights or new contract attestations are account-holder decisions. Confirm them
at the point App Store Connect presents the legal statement; do not infer acceptance
from this engineering checklist.
