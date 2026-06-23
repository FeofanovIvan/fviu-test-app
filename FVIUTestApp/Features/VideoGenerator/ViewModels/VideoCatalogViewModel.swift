//
//  VideoCatalogViewModel.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Combine
import Foundation

@MainActor
final class VideoCatalogViewModel: ObservableObject {
    @Published var selectedCategory: String = ""
    @Published var isPhotoAccessDeniedAlertPresented = false
    @Published private(set) var state: LoadableState<[VideoTemplate]> = .idle

    private weak var appState: AppState?
    private let photoAccessManager: PhotoLibraryAccessManaging
    private let templateStore: VideoTemplateStore
    private var cancellables = Set<AnyCancellable>()

    init(
        appState: AppState,
        photoAccessManager: PhotoLibraryAccessManaging,
        templateStore: VideoTemplateStore
    ) {
        self.appState = appState
        self.photoAccessManager = photoAccessManager
        self.templateStore = templateStore
        self.state = templateStore.state

        templateStore.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
            }
            .store(in: &cancellables)
    }

    var categories: [String] { templateStore.availableCategories }

    var templatesInSelectedCategory: [VideoTemplate] {
        templateStore.templates(in: selectedCategory)
    }

    func load() async {
        await templateStore.loadIfNeeded()
        if selectedCategory.isEmpty {
            selectedCategory = categories.first ?? ""
        }
    }

    func retry() async {
        await templateStore.reload()
        if selectedCategory.isEmpty {
            selectedCategory = categories.first ?? ""
        }
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    func openTemplate(_ template: VideoTemplate) async {
        guard let appState else { return }
        guard AppConfig.isVideoAccessFree || appState.hasPremiumAccess else {
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
