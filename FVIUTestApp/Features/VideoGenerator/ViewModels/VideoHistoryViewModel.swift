//
//  VideoHistoryViewModel.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
final class VideoHistoryViewModel: ObservableObject {
    @Published private(set) var generations: [VideoGeneration]

    private let historyStore: VideoHistoryStoring
    private weak var appState: AppState?

    init(historyStore: VideoHistoryStoring, appState: AppState) {
        self.historyStore = historyStore
        self.appState = appState
        self.generations = historyStore.generations()
    }

    func refresh() {
        generations = historyStore.generations()
    }

    func close() {
        appState?.navigateBack()
    }
}
