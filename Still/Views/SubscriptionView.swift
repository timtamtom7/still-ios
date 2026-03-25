import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @State private var selectedProduct: StoreProduct?
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showRestoreAlert: Bool = false
    @State private var didRestore: Bool = false

    private let subscription = SubscriptionService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Current status
                        currentStatusSection

                        // Features
                        featuresSection

                        // Pricing
                        pricingSection

                        // Actions
                        actionsSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Still Pro")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Purchase Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Restore Complete", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                Text(didRestore ? "Your Pro subscription has been restored." : "No previous purchases found.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.amberGlow, AppColors.amber, Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: AppColors.amberGlow.opacity(0.5), radius: 30)

                Image(systemName: subscription.isProActive ? "checkmark" : "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(subscription.isProActive ? AppColors.background : AppColors.amber)
            }

            VStack(spacing: 4) {
                Text(subscription.isProActive ? "You're Pro" : "Unlock Still Pro")
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text(subscription.isProActive ? "Thank you for your support" : "Deepen your reflection practice")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Current Status

    private var currentStatusSection: some View {
        Group {
            if subscription.isProActive {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.amber)

                        Text("Pro Member")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.amber)

                        Spacer()
                    }

                    if let expires = subscription.proExpiresAt {
                        Text("Renews \(formatDate(expires))")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)

                        Text("Free Plan")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()
                    }

                    Text("\(subscription.remainingReflectionsThisWeek) reflections remaining this week")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Resets in \(subscription.daysUntilWeekReset) day(s)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Everything in Pro")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "Unlimited Reflections",
                    description: "Reflect as often as you need, without weekly limits"
                )

                FeatureRow(
                    icon: "book.closed",
                    title: "Legacy Document",
                    description: "Export your reflections as a beautiful document"
                )

                FeatureRow(
                    icon: "gift",
                    title: "Gift Reflections",
                    description: "Share meaningful reflections with loved ones"
                )

                FeatureRow(
                    icon: "heart",
                    title: "Memorial Mode",
                    description: "Hold space for someone you've lost"
                )

                FeatureRow(
                    icon: "waveform",
                    title: "Extended Ambient Sounds",
                    description: "Access all ambient soundscapes"
                )
            }
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 8) {
                ProductCard(
                    title: "Pro Yearly",
                    price: "$29.99/year",
                    subtitle: "Best value — $2.50/month",
                    isSelected: selectedProduct == .yearly,
                    savings: "Save 50%"
                ) {
                    selectedProduct = .yearly
                }

                ProductCard(
                    title: "Pro Monthly",
                    price: "$4.99/month",
                    subtitle: "Flexible option",
                    isSelected: selectedProduct == .monthly,
                    savings: nil
                ) {
                    selectedProduct = .monthly
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if subscription.isProActive {
                Button {
                    // Cancel flow would go here
                } label: {
                    Text("Manage Subscription")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                Button {
                    purchasePro()
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.background))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start Pro")
                                .font(AppTypography.button)
                        }
                    }
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.amber)
                    .cornerRadius(24)
                }
                .disabled(selectedProduct == nil || isPurchasing)

                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Text("Cancel anytime. Auto-renews unless turned off 24h before period ends.")
                .font(.system(size: 10))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func purchasePro() {
        isPurchasing = true

        // Simulate purchase (in real app, use StoreKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            subscription.activatePro()
            isPurchasing = false
            selectedProduct = nil
        }
    }

    private func restorePurchases() {
        Task {
            let restored = await subscription.restorePurchases()
            didRestore = restored
            showRestoreAlert = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Store Product

enum StoreProduct {
    case yearly
    case monthly
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.amber)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.amber.opacity(0.6))
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(10)
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let title: String
    let price: String
    let subtitle: String
    let isSelected: Bool
    let savings: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textPrimary)

                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColors.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.amber)
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text(price)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppColors.amber : AppColors.textSecondary)
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.amber : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
