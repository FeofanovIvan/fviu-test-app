import SwiftUI

struct PremiumHintView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(AppColors.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.premiumHintTitle)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(L10n.premiumHintMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()
            }
            .padding(AppSpacing.medium)
            .background(AppColors.elevatedBackground, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .buttonStyle(.plain)
    }
}
