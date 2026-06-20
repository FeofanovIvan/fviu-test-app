import SwiftUI

struct ErrorStateView: View {
    let error: AppError
    let retry: (() -> Void)?

    init(error: AppError, retry: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppColors.warning)

            Text(error.title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)

            Text(error.message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            if let retry, let title = error.recoveryActionTitle {
                Button(title, action: retry)
                    .font(AppTypography.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, AppSpacing.large)
                    .frame(height: 48)
                    .background(AppColors.accent, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            }
        }
        .padding(AppSpacing.screen)
    }
}
