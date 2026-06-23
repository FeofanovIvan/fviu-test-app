//
//  VideoHistoryStore.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

final class VideoHistoryStore: VideoHistoryStoring {
    private let userDefaults: UserDefaults
    private let key = "video.generation.history"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func generations() -> [VideoGeneration] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([VideoGeneration].self, from: data)) ?? []
    }

    func save(_ generation: VideoGeneration) {
        var items = generations().filter { $0.id != generation.id }
        items.insert(generation, at: 0)
        persist(Array(items.prefix(40)))
    }

    func delete(_ generation: VideoGeneration) {
        persist(generations().filter { $0.id != generation.id })
    }

    private func persist(_ generations: [VideoGeneration]) {
        let data = try? JSONEncoder().encode(generations)
        userDefaults.set(data, forKey: key)
    }
}
