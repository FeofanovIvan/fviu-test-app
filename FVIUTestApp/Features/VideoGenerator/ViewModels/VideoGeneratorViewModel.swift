//
//  VideoGeneratorViewModel.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation
import PhotosUI

@MainActor
final class VideoGeneratorViewModel: ObservableObject {
    @Published var prompt = ""
    @Published var selectedTemplate: VideoTemplate
    @Published var selectedAspectRatio: VideoAspectRatio = .landscape
    @Published var selectedQuality: VideoQuality = .p1080
    @Published var selectedPhotos: [SelectedVideoPhoto?]
    @Published private(set) var state: LoadableState<VideoGeneration> = .idle
    @Published private(set) var history: [VideoGeneration]
    @Published var isPhotoAccessDeniedAlertPresented = false

    private let videoService: VideoServicing
    private weak var appState: AppState?
    private let subscriptionManager: SubscriptionManaging
    private let historyStore: VideoHistoryStoring
    private let photoAccessManager: PhotoLibraryAccessManaging
    private let templateStore: VideoTemplateStore
    private let userID: String
    private var previewPrefetchTask: Task<Void, Never>?

    init(
        videoService: VideoServicing,
        appState: AppState,
        subscriptionManager: SubscriptionManaging,
        historyStore: VideoHistoryStoring,
        photoAccessManager: PhotoLibraryAccessManaging,
        templateStore: VideoTemplateStore,
        templateID: UUID,
        userID: String = UUID().uuidString
    ) {
        self.videoService = videoService
        self.appState = appState
        self.subscriptionManager = subscriptionManager
        self.historyStore = historyStore
        self.photoAccessManager = photoAccessManager
        self.templateStore = templateStore
        self.userID = userID
        self.history = historyStore.generations()

        let template = templateStore.template(id: templateID) ?? .placeholder
        self.selectedTemplate = template
        self.prompt = template.prompt
        self.selectedPhotos = Array(repeating: nil, count: template.requiredPhotoCount)

        prefetchTemplatesAroundSelection()
    }

    deinit {
        previewPrefetchTask?.cancel()
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedPhotos.prefix(selectedTemplate.requiredPhotoCount).allSatisfy { $0 != nil } && !state.isLoading
    }

    var carouselTemplates: [VideoTemplate] {
        templateStore.templates(in: selectedTemplate.category)
    }

    func selectTemplate(_ template: VideoTemplate) {
        selectedTemplate = template
        prompt = template.prompt
        resizeSelectedPhotos(for: template.requiredPhotoCount)
        state = .idle
        prefetchTemplatesAroundSelection()
    }

    func shouldPlayVideo(for template: VideoTemplate) -> Bool {
        template.id == selectedTemplate.id
    }

    func isVideoOnScreen(for template: VideoTemplate) -> Bool {
        guard
            let selectedIndex = carouselTemplates.firstIndex(of: selectedTemplate),
            let templateIndex = carouselTemplates.firstIndex(of: template)
        else { return false }
        return abs(templateIndex - selectedIndex) <= 2
    }

    func prefetchTemplatesAroundSelection() {
        let urls = templatesAroundSelection(radius: 0).compactMap(\.previewURL)
        guard !urls.isEmpty else { return }

        previewPrefetchTask?.cancel()
        previewPrefetchTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = try? await VideoPreviewPrefetcher.shared.localURL(for: url, priority: .prefetch)
                    }
                }
            }
        }
    }

    func requestPhotoAccessForPicker() async -> Bool {
        let hasAccess = photoAccessManager.isAuthorized ? true : await photoAccessManager.requestAccess()
        guard hasAccess else {
            appState?.navigateBack()
            return false
        }
        return true
    }

    func photo(at index: Int) -> SelectedVideoPhoto? {
        guard selectedPhotos.indices.contains(index) else { return nil }
        return selectedPhotos[index]
    }

    func setPhoto(_ photo: SelectedVideoPhoto?, at index: Int) {
        resizeSelectedPhotos(for: selectedTemplate.requiredPhotoCount)
        guard selectedPhotos.indices.contains(index) else { return }
        selectedPhotos[index] = photo
        if photo != nil, case .idle = state {
            state = .idle
        }
    }

    func removePhoto(at index: Int) {
        guard selectedPhotos.indices.contains(index) else { return }
        selectedPhotos[index] = nil
    }

    func replaceResult() {
        state = .idle
    }

    func generate() async {
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canGenerate else { return }

        let hasPhotoAccess = photoAccessManager.isAuthorized ? true : await photoAccessManager.requestAccess()
        guard hasPhotoAccess else {
            isPhotoAccessDeniedAlertPresented = true
            return
        }

        let hasAccess: Bool
        if AppConfig.isVideoAccessFree {
            hasAccess = true
        } else {
            hasAccess = await subscriptionManager.refreshSubscriptionStatus() || (appState?.hasPremiumAccess ?? false)
        }
        guard hasAccess else {
            appState?.presentPaywall()
            return
        }

        state = .loading

        do {
            let generation = try await videoService.generateVideo(
                prompt: prompt,
                userID: userID,
                aspectRatio: selectedAspectRatio,
                quality: selectedQuality
            )
            state = .success(generation)
            historyStore.save(generation)
            history = historyStore.generations()
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.unknown)
        }
    }

    func delete(_ generation: VideoGeneration) {
        historyStore.delete(generation)
        history = historyStore.generations()
    }

    private func resizeSelectedPhotos(for requiredCount: Int) {
        if selectedPhotos.count < requiredCount {
            selectedPhotos.append(contentsOf: Array(repeating: nil, count: requiredCount - selectedPhotos.count))
        } else if selectedPhotos.count > requiredCount {
            selectedPhotos = Array(selectedPhotos.prefix(requiredCount))
        }
    }

    private func templatesAroundSelection(radius: Int) -> [VideoTemplate] {
        let templates = carouselTemplates
        guard let selectedIndex = templates.firstIndex(of: selectedTemplate) else {
            return Array(templates.prefix(radius * 2 + 1))
        }

        let lowerBound = max(templates.startIndex, selectedIndex - radius)
        let upperBound = min(templates.index(before: templates.endIndex), selectedIndex + radius)
        return Array(templates[lowerBound...upperBound])
    }
}
