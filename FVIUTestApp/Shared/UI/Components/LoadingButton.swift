import SwiftUI

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                }

                Text(title)
                    .font(AppTypography.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 18))
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}
