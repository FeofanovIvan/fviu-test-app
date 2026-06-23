//
//  VideoTemplateStore.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
final class VideoTemplateStore: ObservableObject {
    @Published private(set) var state: LoadableState<[VideoTemplate]> = .idle

    private let videoService: VideoServicing
    private let userID: String

    init(videoService: VideoServicing, userID: String = UUID().uuidString) {
        self.videoService = videoService
        self.userID = userID
    }

    private var templates: [VideoTemplate] {
        if case .success(let templates) = state {
            return templates
        }
        return []
    }

    var availableCategories: [String] {
        var seen = Set<String>()
        return templates.map(\.category).filter { seen.insert($0).inserted }
    }

    func templates(in category: String) -> [VideoTemplate] {
        templates.filter { $0.category == category }
    }

    func template(id: UUID) -> VideoTemplate? {
        templates.first { $0.id == id }
    }

    func loadIfNeeded() async {
        switch state {
        case .idle, .error:
            await load()
        case .loading, .success:
            return
        }
    }

    func reload() async {
        await load()
    }

    private func load() async {
        state = .loading
        do {
            let templates = try await videoService.fetchTemplates(userID: userID)
            state = .success(templates)
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.unknown)
        }
    }
}
