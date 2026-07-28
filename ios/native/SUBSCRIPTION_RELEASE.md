# Subscription and release contract

Cosmic Rituals uses StoreKit 2 and App Store-signed transactions. It never starts a
local countdown or grants a trial from a device timestamp.

## Products

All products belong to the **Cosmic Rituals Premium** subscription group:

| Reference name | Product ID | Period | Launch price basis | Introductory offer |
| --- | --- | --- | --- | --- |
| Premium Annual | `com.cosmic.rituals.premium.annual` | 1 year | USD 49.99 | 2 weeks free |
| Premium Monthly | `com.cosmic.rituals.premium.monthly` | 1 month | USD 6.99 | 2 weeks free |

App Store Connect supplies localized prices and eligibility. Apple permits a two-week
free introductory offer for monthly and yearly subscriptions; each customer can redeem
only one introductory offer in a subscription group.

## Access behavior

- Access is granted only for a verified transaction returned by
  `Transaction.currentEntitlements` for one of the configured product IDs.
- Unverified transactions never unlock the app.
- Revoked and refunded transactions disappear from current entitlements and therefore
  lose access on refresh.
- Transaction updates are observed for purchases, renewals, revocations, and changes
  made on another device.
- Existing verified subscribers remain entitled if product metadata temporarily fails
  to load. A new customer sees an actionable retry state instead of an empty screen.
- Restore Purchases calls `AppStore.sync()` and the StoreKit subscription surface also
  exposes the system restore action.
- App Shortcuts use the same entitlement check and do not bypass the Premium gate.

## App Store Connect configuration

1. Create the subscription group and both product IDs exactly as shown above.
2. Add English display names and descriptions matching the bundled StoreKit fixture.
3. Configure Family Sharing for both products if the storefront agreement permits it.
4. Set the standard prices, with App Store Connect generating territory equivalents.
5. Add a **Free · 2 Weeks** introductory offer to both products for all intended
   storefronts. Set the start date to the release date with no artificial end date.
6. Add the subscriptions to version 1.0 before submission.
7. Use the published URLs below for App Privacy, Terms, and Support.

## Public URLs

- Privacy: <https://gohlerdev.github.io/Cosmic-Rituals/privacy/>
- Terms: <https://gohlerdev.github.io/Cosmic-Rituals/terms/>
- Support: <https://gohlerdev.github.io/Cosmic-Rituals/support/>

## Release test matrix

- Eligible sandbox user sees the two-week offer and localized renewal price.
- Ineligible user sees standard pricing without a free-trial claim.
- Purchase unlocks without relaunching.
- Cancelled auto-renew retains access through the paid period.
- Expired, revoked, or refunded transaction locks access after refresh.
- Billing-grace entitlement remains accessible because StoreKit includes it in current
  entitlements.
- Restore succeeds for the purchasing Apple Account and is harmless with no purchases.
- Offline launch succeeds for a locally verifiable current entitlement; first purchase
  requires App Store connectivity.

The checked-in `StoreKit/CosmicRituals.storekit` file is only a local Xcode fixture.
It lives outside the app target, so it is not bundled in release builds; its prices and
offers do not upload to App Store Connect.
