//
//  AppContainer.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let appState: AppState
    let networkClient: NetworkClientProtocol
    let subscriptionManager: SubscriptionManaging
    let apphudManager: ApphudManaging
    let chatService: ChatServicing
    let chatHistoryStore: ChatHistoryStoring
    let videoService: VideoServicing
    let videoHistoryStore: VideoHistoryStoring
    let videoTemplateStore: VideoTemplateStore
    let photoAccessManager: PhotoLibraryAccessManaging

    init(
        appState: AppState,
        networkClient: NetworkClientProtocol,
        subscriptionManager: SubscriptionManaging,
        apphudManager: ApphudManaging,
        chatService: ChatServicing,
        chatHistoryStore: ChatHistoryStoring,
        videoService: VideoServicing,
        videoHistoryStore: VideoHistoryStoring,
        videoTemplateStore: VideoTemplateStore,
        photoAccessManager: PhotoLibraryAccessManaging
    ) {
        self.appState = appState
        self.networkClient = networkClient
        self.subscriptionManager = subscriptionManager
        self.apphudManager = apphudManager
        self.chatService = chatService
        self.chatHistoryStore = chatHistoryStore
        self.videoService = videoService
        self.videoHistoryStore = videoHistoryStore
        self.videoTemplateStore = videoTemplateStore
        self.photoAccessManager = photoAccessManager
    }

    static func live() -> AppContainer {
        let appState = AppState()
        let networkClient = NetworkClient()
        let apphudManager = ApphudManager()
        let subscriptionManager = SubscriptionManager(apphudManager: apphudManager)
        let videoService = VideoService(networkClient: networkClient)

        return AppContainer(
            appState: appState,
            networkClient: networkClient,
            subscriptionManager: subscriptionManager,
            apphudManager: apphudManager,
            chatService: ChatService(networkClient: networkClient),
            chatHistoryStore: ChatHistoryStore(),
            videoService: videoService,
            videoHistoryStore: VideoHistoryStore(),
            videoTemplateStore: VideoTemplateStore(videoService: videoService),
            photoAccessManager: PhotoLibraryAccessManager()
        )
    }

    func bootstrap() async {
        await apphudManager.configure(apiKey: AppConfig.apphudAPIKey)
        let hasPremium = await subscriptionManager.refreshSubscriptionStatus()
        appState.updatePremiumAccess(hasPremium)

        Task { [weak self] in
            await self?.videoTemplateStore.loadIfNeeded()
        }

        Task { [weak self] in
            guard let self else { return }
            for await hasPremium in subscriptionManager.subscriptionUpdates {
                if hasPremium {
                    appState.handlePremiumAccessGranted()
                } else {
                    appState.handlePremiumAccessRevoked()
                }
            }
        }
    }

    func makeChatViewModel(sessionID: UUID? = nil) -> ChatViewModel {
        ChatViewModel(
            chatService: chatService,
            appState: appState,
            subscriptionManager: subscriptionManager,
            historyStore: chatHistoryStore,
            sessionID: sessionID
        )
    }

    func makeChatHistoryViewModel() -> ChatHistoryViewModel {
        ChatHistoryViewModel(
            historyStore: chatHistoryStore,
            appState: appState
        )
    }

    func makeVideoCatalogViewModel() -> VideoCatalogViewModel {
        VideoCatalogViewModel(
            appState: appState,
            photoAccessManager: photoAccessManager,
            templateStore: videoTemplateStore
        )
    }

    func makeVideoGeneratorViewModel(templateID: UUID) -> VideoGeneratorViewModel {
        VideoGeneratorViewModel(
            videoService: videoService,
            appState: appState,
            subscriptionManager: subscriptionManager,
            historyStore: videoHistoryStore,
            photoAccessManager: photoAccessManager,
            templateStore: videoTemplateStore,
            templateID: templateID
        )
    }

    func makeVideoHistoryViewModel() -> VideoHistoryViewModel {
        VideoHistoryViewModel(
            historyStore: videoHistoryStore,
            appState: appState
        )
    }

    func makePaywallViewModel() -> PaywallViewModel {
        PaywallViewModel(
            subscriptionManager: subscriptionManager,
            appState: appState
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            subscriptionManager: subscriptionManager,
            appState: appState
        )
    }
}
