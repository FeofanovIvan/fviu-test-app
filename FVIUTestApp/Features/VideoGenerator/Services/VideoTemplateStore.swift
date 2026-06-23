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
    private let catalogStorage: VideoTemplateCatalogStorage
    private let userID: String

    init(
        videoService: VideoServicing,
        catalogStorage: VideoTemplateCatalogStorage = .shared,
        userID: String = UUID().uuidString
    ) {
        self.videoService = videoService
        self.catalogStorage = catalogStorage
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
        guard case .idle = state else { return }
        await loadFromDiskCache()
        await refreshFromServer()
    }

    func reload() async {
        await refreshFromServer()
    }

    private func loadFromDiskCache() async {
        guard let cachedDTOs = await catalogStorage.load() else {
            state = .loading
            return
        }
        state = .success(Self.mapToTemplates(cachedDTOs))
    }

    private func refreshFromServer() async {
        if templates.isEmpty {
            state = .loading
        }
        do {
            let dtos = try await videoService.fetchTemplateCatalog(userID: userID)
            await catalogStorage.save(dtos)
            state = .success(Self.mapToTemplates(dtos))
        } catch let error as AppError {
            if templates.isEmpty {
                state = .error(error)
            }
        } catch {
            if templates.isEmpty {
                state = .error(.unknown)
            }
        }
    }

    private static func mapToTemplates(_ dtos: [VideoTemplateDTO]) -> [VideoTemplate] {
        dtos
            .filter(\.isActive)
            .compactMap { dto in
                let previewURLString = dto.previewSmall ?? dto.previewLarge
                guard let previewURLString, let previewURL = URL(string: previewURLString) else {
                    return nil
                }

                return VideoTemplate(
                    id: stableID(for: dto.templateId),
                    title: dto.name,
                    category: dto.category,
                    prompt: dto.prompt,
                    previewURL: previewURL
                )
            }
    }

    private static func stableID(for templateId: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", templateId)) ?? UUID()
    }
}
