import Foundation

/// Drives the "AI Video" template browse screen — the first screen of the video module: category
/// tabs + a grid of templates. Selecting a template pushes `.videoTemplateDetail(id)`, where the
/// actual photo/settings/generate flow happens (`VideoGeneratorViewModel`).
@MainActor
final class VideoCatalogViewModel: ObservableObject {
    @Published var selectedCategory: String
    /// Drives the in-app fallback alert. iOS only shows its own "Allow Access to Photos?" dialog
    /// once per install — after the user denies it, `requestAuthorization` returns `.denied`
    /// immediately with no UI. So every repeat tap while access is missing surfaces this alert
    /// instead, which offers a direct path to Settings.
    @Published var isPhotoAccessDeniedAlertPresented = false

    private weak var appState: AppState?
    private let photoAccessManager: PhotoLibraryAccessManaging

    let categories = VideoTemplateCatalog.availableCategories

    init(appState: AppState, photoAccessManager: PhotoLibraryAccessManaging) {
        self.appState = appState
        self.photoAccessManager = photoAccessManager
        self.selectedCategory = VideoTemplateCatalog.availableCategories.first ?? "Popular"
    }

    var templatesInSelectedCategory: [VideoTemplate] {
        VideoTemplateCatalog.templates(in: selectedCategory)
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    /// Selecting a template needs gallery access (the next screen lets the user pick a source
    /// photo), so this asks for it up front. We stay on this screen either way — on success we
    /// push the next screen, on denial we show our own alert and let the user tap the template
    /// again once they've enabled access (the native alert won't reappear by itself).
    func openTemplate(_ template: VideoTemplate) async {
        guard let appState else { return }
        guard appState.hasPremiumAccess else {
            appState.presentPaywall(afterPurchase: .videoTemplateDetail(template.id))
            return
        }

        let hasAccess = photoAccessManager.isAuthorized ? true : await photoAccessManager.requestAccess()
        guard hasAccess else {
            isPhotoAccessDeniedAlertPresented = true
            return
        }

        appState.navigateToPremiumRoute(.videoTemplateDetail(template.id))
    }

    func openHistory() {
        appState?.navigateToPremiumRoute(.videoHistory)
    }
}
