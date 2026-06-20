import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                settingsHeader

                Button {
                    if !viewModel.hasPremiumAccess {
                        viewModel.openPaywall()
                    }
                } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: viewModel.hasPremiumAccess ? "checkmark.seal.fill" : "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                viewModel.hasPremiumAccess
                                    ? AnyShapeStyle(AppColors.success)
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [AppColors.gradientBlue, AppColors.gradientPink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.premiumHintTitle)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.primaryText)

                            Text(viewModel.hasPremiumAccess ? L10n.premiumActiveMessage : L10n.premiumRequiredMessage)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.secondaryText)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        if !viewModel.hasPremiumAccess {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.mutedText)
                        }
                    }
                    .padding(AppSpacing.medium)
                    .background(AppColors.elevatedBackground, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                }
                .buttonStyle(.plain)
                .padding(AppSpacing.screen)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var settingsHeader: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 28, height: 38)
                }
                .accessibilityLabel(L10n.back)

                Spacer()
            }

            Text(L10n.settingsTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 56)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 16)
        .padding(.bottom, AppSpacing.small)
        .background(.black.opacity(0.18))
    }
}
