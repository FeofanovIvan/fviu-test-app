import AVFoundation
import SwiftUI

struct VideoHistoryView: View {
    @StateObject private var viewModel: VideoHistoryViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: VideoHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.generations.isEmpty {
                    emptyState
                } else {
                    historyGrid
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var header: some View {
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

            Text(L10n.videoHistoryTitle)
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

    private var historyGrid: some View {
        ScrollView(showsIndicators: false) {
            HStack(alignment: .top, spacing: Metrics.gridSpacing) {
                LazyVStack(spacing: Metrics.gridSpacing) {
                    ForEach(leftColumnItems) { generation in
                        VideoHistoryThumbnail(generation: generation, isTall: false)
                    }
                }

                LazyVStack(spacing: Metrics.gridSpacing) {
                    ForEach(rightColumnItems) { generation in
                        VideoHistoryThumbnail(generation: generation, isTall: true)
                    }
                }
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.gridTopPadding)
            .padding(.bottom, Metrics.bottomPadding)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Metrics.emptyTextSpacing) {
            Spacer()

            Image("PaywallImageToImage")
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.emptyIconSize, height: Metrics.emptyIconSize)

            Text(L10n.noVideosTitle)
                .font(.system(size: Metrics.emptyTitleFont, weight: .bold))
                .foregroundStyle(AppColors.primaryText)

            Text(L10n.noVideosMessage)
                .font(.system(size: Metrics.emptyMessageFont, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppSpacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var leftColumnItems: [VideoGeneration] {
        viewModel.generations.enumerated().compactMap { index, item in
            index.isMultiple(of: 2) ? item : nil
        }
    }

    private var rightColumnItems: [VideoGeneration] {
        viewModel.generations.enumerated().compactMap { index, item in
            index.isMultiple(of: 2) ? nil : item
        }
    }
}

private struct VideoHistoryThumbnail: View {
    let generation: VideoGeneration
    let isTall: Bool
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackImage
            }
        }
        .frame(width: Metrics.thumbnailWidth, height: isTall ? Metrics.tallThumbnailHeight : Metrics.shortThumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbnailCornerRadius))
        .clipped()
        .task(id: resultURL) {
            await loadThumbnail()
        }
    }

    private var fallbackImage: some View {
        Image("VideoTemplateSample")
            .resizable()
            .scaledToFill()
    }

    private var resultURL: URL? {
        if case .ready(let url) = generation.status {
            return url
        }
        return nil
    }

    /// History thumbnails show a real frame grabbed from the generated video rather than the
    /// video itself — `AsyncImage` can't decode video data, so this generates a still frame via
    /// `AVAssetImageGenerator` instead of silently falling back to the bundled mock artwork.
    private func loadThumbnail() async {
        guard let resultURL else { return }

        let asset = AVURLAsset(url: resultURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try await generator.image(at: .zero).image
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            thumbnail = nil
        }
    }
}

private enum Metrics {
    private static let scale = ScreenScale.bounded

    static var horizontalPadding: CGFloat { 16 * scale }
    static var gridTopPadding: CGFloat { 24 * scale }
    static var gridSpacing: CGFloat { 8 * scale }
    static var bottomPadding: CGFloat { 32 * scale }
    static var thumbnailWidth: CGFloat { 175 * scale }
    static var shortThumbnailHeight: CGFloat { 206 * scale }
    static var tallThumbnailHeight: CGFloat { 284 * scale }
    static var thumbnailCornerRadius: CGFloat { 12 * scale }
    static var emptyIconSize: CGFloat { 64 * scale }
    static var emptyTextSpacing: CGFloat { 8 * scale }
    static var emptyTitleFont: CGFloat { 28 * scale }
    static var emptyMessageFont: CGFloat { 16 * scale }
}
