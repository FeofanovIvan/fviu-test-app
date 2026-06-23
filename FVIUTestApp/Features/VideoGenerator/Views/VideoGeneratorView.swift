//
//  VideoGeneratorView.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import AVFoundation
import PhotosUI
import Photos
import SwiftUI

struct VideoGeneratorView: View {
    @StateObject private var viewModel: VideoGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotosPickerPresented = false
    @State private var isSelectedPhotoLoading = false
    @State private var activePhotoSlotIndex = 0

    init(viewModel: VideoGeneratorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                switch viewModel.state {
                case .loading:
                    VideoGeneratingView()
                case .success(let generation):
                    ScrollView {
                        VideoResultView(generation: generation) {
                            viewModel.replaceResult()
                        }
                    }
                case .error(let error):
                    VideoGenerationErrorView(error: error) {
                        viewModel.replaceResult()
                    }
                default:
                    editorContent
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedPhotoItem) { item in
            Task { await loadPhoto(from: item) }
        }
        .photosPicker(isPresented: $isPhotosPickerPresented, selection: $selectedPhotoItem, matching: .images)
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

            if !viewModel.state.isLoading {
                Text(headerTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 56)
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 16)
        .padding(.bottom, AppSpacing.small)
        .background(.black.opacity(0.18))
    }

    private var headerTitle: String {
        if case .success = viewModel.state {
            return L10n.result
        }
        return viewModel.selectedTemplate.title
    }

    private var editorContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Metrics.sectionSpacing) {
                previewImage
                photoPickerSection
                settingsSection
                createButton
            }
            .padding(.horizontal, Metrics.screenHorizontalPadding)
            .padding(.top, Metrics.contentTopPadding)
            .padding(.bottom, Metrics.contentBottomPadding)
        }
    }

    private var previewImage: some View {
        GeometryReader { proxy in

            let carouselHeight = proxy.size.height

            TemplatePagingCarousel(viewModel: viewModel)
                .frame(height: carouselHeight)
        }
        .frame(
            height: UIScreen.main.bounds.height * 0.45
        )
        .padding(.horizontal, -Metrics.screenHorizontalPadding)
    }

    @ViewBuilder
    private var photoPickerSection: some View {
        HStack {
            ForEach(0..<viewModel.selectedTemplate.requiredPhotoCount, id: \.self) { index in
                PhotoSlot(
                    photo: viewModel.photo(at: index),
                    isLoading: isSelectedPhotoLoading && activePhotoSlotIndex == index,
                    onPick: {
                        Task {
                            let granted = await viewModel.requestPhotoAccessForPicker()
                            if granted {
                                activePhotoSlotIndex = index
                                isPhotosPickerPresented = true
                            }
                        }
                    },
                    onRemove: {
                        if activePhotoSlotIndex == index {
                            selectedPhotoItem = nil
                        }
                        viewModel.removePhoto(at: index)
                    }
                )
            }

            Spacer()
        }
    }

    private var settingsSection: some View {
        VStack(spacing: Metrics.optionRowSpacing) {
            SettingMenuRow(title: L10n.format, value: viewModel.selectedAspectRatio.rawValue) {
                ForEach(VideoAspectRatio.allCases) { ratio in
                    Button(ratio.rawValue) {
                        viewModel.selectedAspectRatio = ratio
                    }
                }
            }

            SettingMenuRow(title: L10n.quality, value: viewModel.selectedQuality.rawValue) {
                ForEach(VideoQuality.allCases) { quality in
                    Button(quality.rawValue) {
                        viewModel.selectedQuality = quality
                    }
                }
            }
        }
    }

    private var createButton: some View {
        Button {
            Task { await viewModel.generate() }
        } label: {
            Text(L10n.create)
                .font(.system(size: Metrics.createButtonFont, weight: .semibold))
                .frame(width: Metrics.createButtonWidth, height: Metrics.createButtonHeight)
                .foregroundStyle(viewModel.canGenerate ? Color.white : AppColors.primaryText.opacity(0.16))
                .background {
                    if viewModel.canGenerate {
                        LinearGradient(
                            colors: [AppColors.gradientBlue, AppColors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        AppColors.glassDark.opacity(0.55)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Metrics.createButtonCornerRadius))
        }
        .disabled(!viewModel.canGenerate)
        .padding(.top, Metrics.createButtonTopPadding)
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isSelectedPhotoLoading = true
        defer { isSelectedPhotoLoading = false }

        viewModel.removePhoto(at: activePhotoSlotIndex)

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        viewModel.setPhoto(SelectedVideoPhoto(data: data), at: activePhotoSlotIndex)
    }

}

private enum Metrics {
    private static let scale = ScreenScale.bounded

    static var screenHorizontalPadding: CGFloat { 16 * scale }
    static var contentTopPadding: CGFloat { 14 * scale }
    static var contentBottomPadding: CGFloat { 28 * scale }
    static var sectionSpacing: CGFloat { 18 * scale }

    static var previewSpacing: CGFloat { 14 * scale }
    static var previewCornerRadius: CGFloat { 20 * scale }

    static var photoSlotSize: CGFloat { 82 * scale }
    static var photoSlotCornerRadius: CGFloat { 18 * scale }
    static var photoSlotBorderWidth: CGFloat { 2 * scale }
    static var photoSlotIconFont: CGFloat { 30 * scale }
    static var photoSlotSpinnerSize: CGFloat { 28 * scale }
    static var photoSlotSpinnerLineWidth: CGFloat { 3 * scale }
    static var photoRemoveButtonSize: CGFloat { 26 * scale }
    static var photoRemoveIconFont: CGFloat { 14 * scale }

    static var optionRowSpacing: CGFloat { 12 * scale }
    static var optionRowWidth: CGFloat { 358 * scale }
    static var optionRowHeight: CGFloat { 54 * scale }
    static var optionRowFont: CGFloat { 20 * scale }
    static var optionRowHorizontalPadding: CGFloat { 16 * scale }
    static var optionRowCornerRadius: CGFloat { 20 * scale }

    static var createButtonWidth: CGFloat { 358 * scale }
    static var createButtonHeight: CGFloat { 50 * scale }
    static var createButtonFont: CGFloat { 17 * scale }
    static var createButtonCornerRadius: CGFloat { 24 * scale }
    static var createButtonTopPadding: CGFloat { 30 * scale }

    static var generatingTopSpacing: CGFloat { 90 * scale }
    static var generatingCanvasWidth: CGFloat { 316 * scale }
    static var generatingCanvasHeight: CGFloat { 446 * scale }
    static var generatingOrbSize: CGFloat { 274 * scale }
    static var generatingTitleTopPadding: CGFloat { 40 * scale }
    static var generatingTextSpacing: CGFloat { 8 * scale }
    static var generatingTitleFont: CGFloat { 20 * scale }
    static var generatingTitleHeight: CGFloat { 24 * scale }
    static var generatingSubtitleFont: CGFloat { 16 * scale }
    static var generatingSubtitleWidth: CGFloat { 344 * scale }
    static var generatingSubtitleHeight: CGFloat { 19 * scale }

    static var resultPreviewWidth: CGFloat { 358 * scale }
    static var resultPreviewHeight: CGFloat { 611 * scale }
    static var resultPreviewCornerRadius: CGFloat { 20 * scale }
    static var resultButtonSpacing: CGFloat { 16 * scale }
    static var resultButtonWidth: CGFloat { 171 * scale }
    static var resultButtonHeight: CGFloat { 50 * scale }
    static var resultButtonCornerRadius: CGFloat { 24 * scale }
    static var resultButtonFont: CGFloat { 16 * scale }
    static var resultReplaceWidth: CGFloat { 109 * scale }
    static var resultReplaceHeight: CGFloat { 40 * scale }
    static var resultReplaceTopPadding: CGFloat { 16 * scale }
    static var resultReplaceTrailingPadding: CGFloat { 16 * scale }
    static var resultReplaceCornerRadius: CGFloat { 24 * scale }
    static var resultReplaceIconSize: CGFloat { 20 * scale }
    static var resultReplaceFont: CGFloat { 14 * scale }
    static var resultPlayIconSize: CGFloat { 88 * scale }
    static var resultNotificationWidth: CGFloat { 239 * scale }
    static var resultNotificationHeight: CGFloat { 134 * scale }
    static var resultNotificationCornerRadius: CGFloat { 20 * scale }
    static var resultNotificationIconFont: CGFloat { 34 * scale }
    static var resultNotificationFont: CGFloat { 16 * scale }
}

private struct TemplatePagingCarousel: View {
    @ObservedObject var viewModel: VideoGeneratorViewModel

    @State private var dragOffset: CGFloat = 0

    private let aspectRatio: CGFloat = 9.0 / 16.0

    private var templates: [VideoTemplate] {
        viewModel.carouselTemplates
    }

    private func pageWidth(cardWidth: CGFloat) -> CGFloat {
        cardWidth + Metrics.previewSpacing
    }

    private var selectedIndex: Int {
        templates.firstIndex(of: viewModel.selectedTemplate) ?? 0
    }

    private var previousTemplate: VideoTemplate? {
        let previousIndex = selectedIndex - 1
        guard templates.indices.contains(previousIndex) else { return nil }
        return templates[previousIndex]
    }

    private var nextTemplate: VideoTemplate? {
        let nextIndex = selectedIndex + 1
        guard templates.indices.contains(nextIndex) else { return nil }
        return templates[nextIndex]
    }

    var body: some View {
        GeometryReader { proxy in

            let cardHeight = proxy.size.height * 0.98
            let cardWidth = cardHeight * aspectRatio
            let pageWidth = pageWidth(cardWidth: cardWidth)

            ZStack {
                if let previousTemplate {
                    RemoteVideoFramePreview(url: previousTemplate.previewURL)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.previewCornerRadius))
                        .clipped()
                        .offset(x: -pageWidth + dragOffset)
                }

                if let nextTemplate {
                    RemoteVideoFramePreview(url: nextTemplate.previewURL)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.previewCornerRadius))
                        .clipped()
                        .offset(x: pageWidth + dragOffset)
                }

                RemoteVideoThumbnail(
                    url: viewModel.selectedTemplate.previewURL,
                    isActive: true,
                    isOnScreen: true
                )
                .frame(
                    width: cardWidth,
                    height: cardHeight
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Metrics.previewCornerRadius
                    )
                )
                .clipped()
                .offset(x: dragOffset)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            .contentShape(Rectangle())
            .animation(
                .spring(
                    response: 0.32,
                    dampingFraction: 0.86
                ),
                value: viewModel.selectedTemplate.id
            )
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in

                        dragOffset = max(
                            min(
                                value.translation.width,
                                pageWidth
                            ),
                            -pageWidth
                        )
                    }
                    .onEnded { value in

                        let threshold = pageWidth * 0.22
                        let translation = abs(value.predictedEndTranslation.width) > abs(value.translation.width)
                            ? value.predictedEndTranslation.width
                            : value.translation.width

                        let nextIndex: Int

                        if translation < -threshold {

                            nextIndex = min(
                                selectedIndex + 1,
                                templates.count - 1
                            )

                        } else if translation > threshold {

                            nextIndex = max(
                                selectedIndex - 1,
                                0
                            )

                        } else {

                            nextIndex = selectedIndex
                        }

                        withAnimation(
                            .spring(
                                response: 0.32,
                                dampingFraction: 0.86
                            )
                        ) {
                            if templates.indices.contains(nextIndex) {
                                viewModel.selectTemplate(templates[nextIndex])
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .clipped()
    }
}

private struct RemoteVideoFramePreview: View {
    let url: URL?

    @State private var image: UIImage?
    @State private var requestID = UUID()
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: Metrics.previewCornerRadius)
                    .fill(AppColors.glassDark.opacity(0.35))
            }
        }
        .clipped()
        .onAppear { loadFrame() }
        .onDisappear { cancelLoading() }
        .onChange(of: url) { _ in loadFrame() }
    }

    @MainActor
    private func loadFrame() {
        loadTask?.cancel()
        image = nil

        guard let url else {
            loadTask = nil
            return
        }

        let id = UUID()
        requestID = id

        loadTask = Task {
            do {
                let localURL = try await VideoPreviewPrefetcher.shared.localURL(for: url, priority: .prefetch)
                guard !Task.isCancelled else { return }
                let frame = await makeFrame(from: localURL)
                await MainActor.run {
                    guard requestID == id else { return }
                    image = frame
                }
            } catch {
            }
        }
    }

    private func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }

    private func makeFrame(from localURL: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            let asset = AVAsset(url: localURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 720, height: 1280)

            do {
                let frameTime = CMTime(seconds: 0.2, preferredTimescale: 600)
                let cgImage = try generator.copyCGImage(at: frameTime, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                return nil
            }
        }.value
    }
}

private struct PhotoSlot: View {
    let photo: SelectedVideoPhoto?
    let isLoading: Bool
    let onPick: () -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isLoading {
                LoadingSpinner()
                    .frame(width: Metrics.photoSlotSize, height: Metrics.photoSlotSize)
                    .background(AppColors.glassDark.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.photoSlotCornerRadius))
            } else if let photo, let image = UIImage(data: photo.data) {
                Button(action: onPick) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Metrics.photoSlotSize, height: Metrics.photoSlotSize)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.photoSlotCornerRadius))
                }
                .buttonStyle(.plain)

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: Metrics.photoRemoveIconFont, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.gradientBlue, AppColors.gradientPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: Metrics.photoRemoveButtonSize, height: Metrics.photoRemoveButtonSize)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .offset(x: Metrics.photoRemoveButtonSize * 0.28, y: -Metrics.photoRemoveButtonSize * 0.28)
            } else {
                Button(action: onPick) {
                    Image(systemName: "plus")
                        .font(.system(size: Metrics.photoSlotIconFont, weight: .regular))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: Metrics.photoSlotSize, height: Metrics.photoSlotSize)
                        .background(
                            RoundedRectangle(cornerRadius: Metrics.photoSlotCornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: Metrics.photoSlotBorderWidth
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct LoadingSpinner: View {
    @State private var rotation: Angle = .degrees(0)

    var body: some View {
        Circle()
            .trim(from: 0.08, to: 0.82)
            .stroke(
                AngularGradient(
                    colors: [
                        AppColors.gradientBlue,
                        AppColors.gradientPink,
                        AppColors.gradientBlue.opacity(0.05)
                    ],
                    center: .center,
                    angle: .degrees(23.2)
                ),
                style: StrokeStyle(lineWidth: Metrics.photoSlotSpinnerLineWidth, lineCap: .round)
            )
            .frame(width: Metrics.photoSlotSpinnerSize, height: Metrics.photoSlotSpinnerSize)
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    rotation = .degrees(360)
                }
            }
    }
}

private struct SettingMenuRow<Content: View>: View {
    let title: String
    let value: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: Metrics.optionRowFont, weight: .regular))
                    .foregroundStyle(AppColors.primaryText.opacity(0.55))
                Spacer()
                Text(value)
                    .font(.system(size: Metrics.optionRowFont, weight: .regular))
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.horizontal, Metrics.optionRowHorizontalPadding)
            .frame(width: Metrics.optionRowWidth, height: Metrics.optionRowHeight)
            .background(AppColors.glassDark.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: Metrics.optionRowCornerRadius))
        }
    }
}

private struct VideoGeneratingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: Metrics.generatingTopSpacing)

            ZStack {
                Color.black
                GeneratingOrb()
            }
            .frame(width: Metrics.generatingCanvasWidth, height: Metrics.generatingCanvasHeight)

            VStack(spacing: Metrics.generatingTextSpacing) {
                Text(L10n.generating)
                    .font(.system(size: Metrics.generatingTitleFont, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(height: Metrics.generatingTitleHeight)

                Text(L10n.videoGeneratingSubtitle)
                    .font(.system(size: Metrics.generatingSubtitleFont, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: Metrics.generatingSubtitleWidth, height: Metrics.generatingSubtitleHeight)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Metrics.generatingTitleTopPadding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct VideoGenerationErrorView: View {
    let error: AppError
    let retry: () -> Void

    var body: some View {
        VStack {
            Spacer()

            ErrorStateView(error: error, retry: retry)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GeneratingOrb: View {
    @State private var rotation: Angle = .degrees(0)

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            AppColors.gradientBlue.opacity(0.42),
                            AppColors.gradientPink.opacity(0.5),
                            Color.black.opacity(0)
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: Metrics.generatingOrbSize * 0.58
                    )
                )

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            AppColors.gradientPink.opacity(0.72),
                            AppColors.gradientBlue.opacity(0.55),
                            Color.white.opacity(0.9)
                        ],
                        center: .center
                    ),
                    lineWidth: 18
                )
                .blur(radius: 2)
                .rotationEffect(rotation)

            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 8)
                .blur(radius: 6)
                .scaleEffect(0.82)
        }
        .frame(width: Metrics.generatingOrbSize, height: Metrics.generatingOrbSize)
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                rotation = .degrees(360)
            }
        }
    }
}

private struct VideoResultView: View {
    let generation: VideoGeneration
    let onReplace: () -> Void
    @State private var isSavedNotificationPresented = false
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var loopObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            VStack(spacing: Metrics.resultButtonSpacing) {
                resultPreview

                HStack(spacing: Metrics.resultButtonSpacing) {
                    ShareLink(item: resultShareItem) {
                        Text(L10n.share)
                            .frame(width: Metrics.resultButtonWidth, height: Metrics.resultButtonHeight)
                    }
                    .buttonStyle(ResultButtonStyle(isPrimary: false))

                    Button {
                        Task { await saveResultToGallery() }
                    } label: {
                        Text(L10n.download)
                            .frame(width: Metrics.resultButtonWidth, height: Metrics.resultButtonHeight)
                    }
                    .buttonStyle(ResultButtonStyle(isPrimary: true))
                }
            }

            if isSavedNotificationPresented {
                Color.black.opacity(0.58)
                    .ignoresSafeArea()
                    .transition(.opacity)

                SavedVideoNotification()
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSavedNotificationPresented)
    }

    private var resultPreview: some View {
        ZStack {
            resultArtwork

            if !isPlaying {
                Image(systemName: "play.fill")
                    .font(.system(size: Metrics.resultPlayIconSize, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: onReplace) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: Metrics.resultReplaceIconSize, weight: .regular))

                            Text(L10n.replace)
                                .font(.system(size: Metrics.resultReplaceFont, weight: .regular))
                        }
                        .foregroundStyle(Color.white)
                        .frame(width: Metrics.resultReplaceWidth, height: Metrics.resultReplaceHeight)
                        .background(Color.white.opacity(0.36), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, Metrics.resultReplaceTopPadding)
                .padding(.trailing, Metrics.resultReplaceTrailingPadding)

                Spacer()
            }
        }
        .frame(width: Metrics.resultPreviewWidth, height: Metrics.resultPreviewHeight)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.resultPreviewCornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { togglePlayback() }
        .onAppear { preparePlayer() }
        .onDisappear { teardownPlayer() }
    }

    @ViewBuilder
    private var resultArtwork: some View {
        if let player {
            VideoPlayerLayerView(player: player)
                .frame(width: Metrics.resultPreviewWidth, height: Metrics.resultPreviewHeight)
                .clipped()
        } else {
            fallbackResultArtwork
        }
    }

    private var fallbackResultArtwork: some View {
        Image("VideoTemplateSample")
            .resizable()
            .scaledToFill()
            .frame(width: Metrics.resultPreviewWidth, height: Metrics.resultPreviewHeight)
            .clipped()
    }

    private var resultURL: URL? {
        if case .ready(let url) = generation.status {
            return url
        }
        return nil
    }

    private func preparePlayer() {
        guard player == nil, let resultURL else { return }

        let item = AVPlayerItem(url: resultURL)
        let newPlayer = AVPlayer(playerItem: item)

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
        }

        player = newPlayer
    }

    private func teardownPlayer() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObserver = nil
        player?.pause()
        player = nil
        isPlaying = false
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func saveResultToGallery() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let resolvedStatus = status == .notDetermined ? await PHPhotoLibrary.requestAuthorization(for: .addOnly) : status
        guard resolvedStatus == .authorized || resolvedStatus == .limited else {
            return
        }

        guard let resultURL else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: resultURL)
            guard !data.isEmpty else {
                throw AppError(title: L10n.videoGenerationErrorTitle, message: L10n.videoGenerationErrorMessage)
            }

            let fileExtension = resultURL.pathExtension.isEmpty ? "mp4" : resultURL.pathExtension
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)
            try data.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            }

            isSavedNotificationPresented = true
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    isSavedNotificationPresented = false
                }
            }
        } catch {
            #if DEBUG
            debugPrint("Video save to gallery failed:", error)
            #endif
            isSavedNotificationPresented = false
        }
    }

    private var resultShareItem: URL {
        if case .ready(let url?) = generation.status {
            return url
        }
        return URL(string: "https://nebulaapps.site")!
    }
}

private struct SavedVideoNotification: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: Metrics.resultNotificationIconFont, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(L10n.videoSavedToGallery)
                .font(.system(size: Metrics.resultNotificationFont, weight: .regular))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(width: Metrics.resultNotificationWidth, height: Metrics.resultNotificationHeight)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.11, blue: 0.13),
                    Color(red: 0.23, green: 0.17, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Metrics.resultNotificationCornerRadius)
        )
    }
}

private struct ResultButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Metrics.resultButtonFont, weight: .semibold))
            .foregroundStyle(.white)
            .background {
                if isPrimary {
                    LinearGradient(
                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    AppColors.glassDark.opacity(0.6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Metrics.resultButtonCornerRadius))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
