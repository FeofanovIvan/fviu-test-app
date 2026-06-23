//
//  EmptyStateView.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.accent)

            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.large)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}
