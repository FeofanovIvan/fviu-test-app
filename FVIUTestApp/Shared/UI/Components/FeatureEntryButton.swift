import SwiftUI

struct FeatureEntryButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 44, height: 44)
                    .background(AppColors.elevatedBackground, in: RoundedRectangle(cornerRadius: AppRadius.small))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.mutedText)
            }
            .padding(AppSpacing.medium)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .buttonStyle(.plain)
    }
}
