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
    /// In-app fallback for the "Create" tap: iOS only shows its own access dialog once, so once
    /// the user has denied it we show this alert every time instead, with a path to Settings.
    @Published var isPhotoAccessDeniedAlertPresented = false

    private let videoService: VideoServicing
    private weak var appState: AppState?
    private let subscriptionManager: SubscriptionManaging
    private let historyStore: VideoHistoryStoring
    private let photoAccessManager: PhotoLibraryAccessManaging
    private let userID: String

    init(
        videoService: VideoServicing,
        appState: AppState,
        subscriptionManager: SubscriptionManaging,
        historyStore: VideoHistoryStoring,
        photoAccessManager: PhotoLibraryAccessManaging,
        templateID: UUID,
        userID: String = UUID().uuidString
    ) {
        self.videoService = videoService
        self.appState = appState
        self.subscriptionManager = subscriptionManager
        self.historyStore = historyStore
        self.photoAccessManager = photoAccessManager
        self.userID = userID
        self.history = historyStore.generations()

        let template = VideoTemplateCatalog.template(id: templateID) ?? VideoTemplateCatalog.templates[0]
        self.selectedTemplate = template
        self.prompt = template.prompt
        self.selectedPhotos = Array(repeating: nil, count: template.requiredPhotoCount)
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedPhotos.prefix(selectedTemplate.requiredPhotoCount).allSatisfy { $0 != nil } && !state.isLoading
    }

    /// Templates the header carousel pages through — the same category as the selected template,
    /// so swiping sideways stays inside the set the user already chose to browse on the catalog.
    var carouselTemplates: [VideoTemplate] {
        VideoTemplateCatalog.templates(in: selectedTemplate.category)
    }

    func selectTemplate(_ template: VideoTemplate) {
        selectedTemplate = template
        prompt = template.prompt
        resizeSelectedPhotos(for: template.requiredPhotoCount)
        state = .idle
    }

    /// Gate for the "+" add-photo button specifically. Unlike `generate()`, a denial here sends
    /// the user back to the catalog screen instead of keeping them on this one — that's the
    /// confirmed behavior for this exact entry point (the actual gallery-access trigger).
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

        // Re-checked on every tap rather than once at screen entry: access may have been denied
        // earlier, or revoked since. We stay on this screen either way; on denial we surface our
        // own alert (the native one only shows once per install) instead of bouncing the user away.
        let hasPhotoAccess = photoAccessManager.isAuthorized ? true : await photoAccessManager.requestAccess()
        guard hasPhotoAccess else {
            isPhotoAccessDeniedAlertPresented = true
            return
        }

        let hasAccess = await subscriptionManager.refreshSubscriptionStatus() || (appState?.hasPremiumAccess ?? false)
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
}
