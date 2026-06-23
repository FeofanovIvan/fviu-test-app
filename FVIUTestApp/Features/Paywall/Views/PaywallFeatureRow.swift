//
//  PaywallFeatureRow.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import SwiftUI

struct PaywallFeatureRow: View {
    let assetName: String
    let title: String

    var body: some View {
        HStack(spacing: 17) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 32, height: 32)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(height: 32)
    }
}
