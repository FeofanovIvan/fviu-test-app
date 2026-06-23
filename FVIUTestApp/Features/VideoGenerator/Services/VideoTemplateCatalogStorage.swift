//
//  VideoTemplateCatalogStorage.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 23/06/26.
//
import Foundation

actor VideoTemplateCatalogStorage {
    static let shared = VideoTemplateCatalogStorage()

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            return
        }
        let cachesRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = cachesRoot.appendingPathComponent("CatalogCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("video_templates.json")
    }

    func load() -> [VideoTemplateDTO]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([VideoTemplateDTO].self, from: data)
    }

    func save(_ templates: [VideoTemplateDTO]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
