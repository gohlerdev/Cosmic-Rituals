import StoreKit
import SwiftUI

struct SubscriptionGateView: View {
    @ObservedObject var store: SubscriptionStore
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        ZStack {
            RitualSanctuaryBackground()
            switch store.accessState {
            case .storeUnavailable(let message):
                unavailableView(message: message)
            case .checking, .locked, .entitled, .testingAccess:
                subscriptionStoreView
            }

            if store.accessState == .checking {
                loadingOverlay
            }
        }
        .accessibilityIdentifier("subscription.gate")
    }

    private var subscriptionStoreView: some View {
        SubscriptionStoreView(productIDs: SubscriptionCatalog.productIDs) {
            marketingHeader
        }
        .subscriptionStoreControlStyle(.picker)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .cancellation)
        .subscriptionStorePolicyDestination(url: SubscriptionCatalog.privacyPolicyURL, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: SubscriptionCatalog.termsOfUseURL, for: .termsOfService)
        .subscriptionStorePolicyForegroundStyle(theme.semanticSecondaryText)
        .tint(theme.primary)
    }

    private var marketingHeader: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(theme.primary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(store.isEligibleForRequestedTrial ? "Your first 14 days are free" : "Cosmic Rituals Premium")
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.semanticPrimaryText)
                    .multilineTextAlignment(.center)
                Text("Precise Panchang, local muhurta intelligence, the complete offline Pooja library, calendar, sharing, and shortcuts.")
                    .font(.body)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                benefit("Location-aware Panchang and transition times", symbol: "location.fill")
                benefit("All 30 day and night muhurtas", symbol: "clock.badge.checkmark.fill")
                benefit("12 sourced Pooja Vidhis available offline", symbol: "hands.and.sparkles.fill")
                benefit("Private by design — calculations stay on device", symbol: "lock.shield.fill")
            }
            .frame(maxWidth: 560)

            if store.isEligibleForRequestedTrial {
                Text("Choose a plan to begin the 14-day free trial. After the trial, it renews automatically at the displayed price unless cancelled.")
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
    }

    private func benefit(_ text: String, symbol: String) -> some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(theme.primary)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(theme.semanticPrimaryText)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(theme.primary)
            Text("Checking App Store access…")
                .font(.subheadline)
                .foregroundStyle(theme.semanticSecondaryText)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checking App Store access")
    }

    private func unavailableView(message: String) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                marketingHeader

                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(theme.primary)
                        .accessibilityHidden(true)

                    Text("The App Store is unavailable")
                        .font(.title3.bold())
                        .foregroundStyle(theme.semanticPrimaryText)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(theme.semanticSecondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Label("Try again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(theme.primary)
                    .foregroundStyle(theme.selectedControlForeground)
                    .disabled(store.isRefreshing)

                    Button("Restore purchases") {
                        Task { await store.restorePurchases() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .disabled(store.isRefreshing)

                    Text("A connection is required to start a subscription. Existing verified access is preserved when product information cannot load.")
                        .font(.caption)
                        .foregroundStyle(theme.semanticSecondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityElement(children: .contain)

                HStack(spacing: 18) {
                    Link(destination: SubscriptionCatalog.privacyPolicyURL) {
                        Text("Privacy")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    Link(destination: SubscriptionCatalog.termsOfUseURL) {
                        Text("Terms")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    Link(destination: SubscriptionCatalog.supportURL) {
                        Text("Support")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.semanticSecondaryText)
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("subscription.unavailable")
    }
}

#Preview("Eligible trial") {
    SubscriptionGateView(
        store: SubscriptionStore(accessState: .locked, listensForTransactions: false)
    )
    .environment(\.cosmicTheme, CosmicColorScheme.obsidianGold)
    .preferredColorScheme(.dark)
}

#Preview("Store unavailable") {
    SubscriptionGateView(
        store: SubscriptionStore(
            accessState: .storeUnavailable("The App Store could not load subscription options."),
            listensForTransactions: false
        )
    )
    .environment(\.cosmicTheme, CosmicColorScheme.cloudDancer)
    .preferredColorScheme(.light)
}
