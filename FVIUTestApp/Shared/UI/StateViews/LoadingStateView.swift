import SwiftUI

struct LoadingStateView: View {
    let title: String

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .tint(AppColors.accent)

            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(AppSpacing.screen)
    }
}
