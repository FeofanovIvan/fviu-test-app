//
//  VideoCatalogView.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import SwiftUI

struct VideoCatalogView: View {
    @StateObject private var viewModel: VideoCatalogViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: VideoCatalogViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                catalogHeader
                content
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .alert(
            L10n.photoAccessAlertTitle,
            isPresented: $viewModel.isPhotoAccessDeniedAlertPresented
        ) {
            Button(L10n.photoAccessCancel, role: .cancel) {}
            Button(L10n.photoAccessAllow) {
                PhotoAccessSettingsLink.open()
            }
        } message: {
            Text(L10n.photoAccessAlertMessage)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView(title: L10n.videoCatalogLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let error):
            ErrorStateView(error: error) {
                Task { await viewModel.retry() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .success:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    categoryTabs
                    templateGrid
                }
                .padding(AppSpacing.screen)
            }
        }
    }

    private var catalogHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 28, height: 38)
            }
            .accessibilityLabel(L10n.back)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Image("ImageToImageIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }

            Text(L10n.videoCatalogTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                viewModel.openHistory()
            } label: {
                Image("VideoHistoryToggleIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel(L10n.videoHistoryTitle)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 16)
        .padding(.bottom, AppSpacing.small)
        .background(.black.opacity(0.18))
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategory == category

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.selectCategory(category)
                        }
                    } label: {
                        Text(category)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : AppColors.secondaryText)
                            .padding(.horizontal, AppSpacing.medium)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(
                                        isSelected
                                            ? AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [AppColors.gradientBlue, AppColors.gradientPink],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            : AnyShapeStyle(AppColors.cardBackground)
                                    )
                            }
                    }
                }
            }
        }
    }

    private var templateGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(CatalogTemplateCard.cardWidth), spacing: CatalogTemplateCard.gridGap),
                GridItem(.fixed(CatalogTemplateCard.cardWidth), spacing: CatalogTemplateCard.gridGap)
            ],
            alignment: .center,
            spacing: CatalogTemplateCard.gridGap
        ) {
            ForEach(viewModel.templatesInSelectedCategory) { template in
                CatalogTemplateCard(template: template) {
                    Task { await viewModel.openTemplate(template) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct CatalogTemplateCard: View {
    private static let referenceCardWidth: CGFloat = 171
    private static let referenceCardHeight: CGFloat = 232
    private static let referenceCornerRadius: CGFloat = 24
    private static let referenceGap: CGFloat = 8
    private static let scale = ScreenScale.width

    static var cardWidth: CGFloat { referenceCardWidth * scale }
    static var cardHeight: CGFloat { referenceCardHeight * scale }
    static var cornerRadius: CGFloat { referenceCornerRadius * scale }
    static var gridGap: CGFloat { referenceGap * scale }

    let template: VideoTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RemoteVideoThumbnail(url: template.previewURL)
                    .frame(width: Self.cardWidth, height: Self.cardHeight)
                    .clipped()

                LinearGradient(colors: [.clear, .black.opacity(0.62)], startPoint: .center, endPoint: .bottom)

                Text(template.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(AppSpacing.small)
                    .lineLimit(1)
            }
            .frame(width: Self.cardWidth, height: Self.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}
