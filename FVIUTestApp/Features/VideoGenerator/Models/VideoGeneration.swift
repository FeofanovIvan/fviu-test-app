//
//  VideoGeneration.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

enum VideoAspectRatio: String, CaseIterable, Codable, Identifiable {
    case portrait = "9:16"
    case square = "1:1"
    case landscape = "16:9"

    var id: String { rawValue }
}

enum VideoQuality: String, CaseIterable, Codable, Identifiable {
    case p360 = "360p"
    case p540 = "540p"
    case p720 = "720p"
    case p1080 = "1080p"

    var id: String { rawValue }
}

struct VideoTemplate: Identifiable, Equatable {
    let id: UUID
    let title: String
    let category: String
    let prompt: String
    let previewURL: URL?
    let requiredPhotoCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        prompt: String,
        previewURL: URL? = nil,
        requiredPhotoCount: Int = 1
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.prompt = prompt
        self.previewURL = previewURL
        self.requiredPhotoCount = requiredPhotoCount
    }

    static let placeholder = VideoTemplate(
        title: "",
        category: "",
        prompt: ""
    )
}

struct SelectedVideoPhoto: Equatable {
    let data: Data
}

struct VideoGeneration: Identifiable, Equatable, Codable {
    enum Status: Equatable {
        case preparing
        case generating
        case finalizing
        case ready(URL?)
    }

    let id: UUID
    let prompt: String
    let status: Status
    let createdAt: Date
    let aspectRatio: VideoAspectRatio
    let quality: VideoQuality

    init(
        id: UUID = UUID(),
        prompt: String,
        status: Status,
        createdAt: Date = .now,
        aspectRatio: VideoAspectRatio = .portrait,
        quality: VideoQuality = .p540
    ) {
        self.id = id
        self.prompt = prompt
        self.status = status
        self.createdAt = createdAt
        self.aspectRatio = aspectRatio
        self.quality = quality
    }
}

extension VideoGeneration.Status: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case url
    }

    private enum StatusType: String, Codable {
        case preparing
        case generating
        case finalizing
        case ready
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StatusType.self, forKey: .type)

        switch type {
        case .preparing:
            self = .preparing
        case .generating:
            self = .generating
        case .finalizing:
            self = .finalizing
        case .ready:
            self = .ready(try container.decodeIfPresent(URL.self, forKey: .url))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .preparing:
            try container.encode(StatusType.preparing, forKey: .type)
        case .generating:
            try container.encode(StatusType.generating, forKey: .type)
        case .finalizing:
            try container.encode(StatusType.finalizing, forKey: .type)
        case .ready(let url):
            try container.encode(StatusType.ready, forKey: .type)
            try container.encodeIfPresent(url, forKey: .url)
        }
    }
}
