//
//  VideoDTOs.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

struct VideoGenerationResponse: Decodable {
    let videoId: Int
    let detail: String?
}

struct VideoGenerationStatusResponse: Decodable {
    let videoUrl: String?
    let status: String?

    var resultURL: URL? {
        videoUrl.flatMap(URL.init(string:))
    }
}

struct TemplatesCatalogResponse: Decodable {
    let templates: [VideoTemplateDTO]
}

struct VideoTemplateDTO: Codable {
    let templateId: Int
    let name: String
    let category: String
    let prompt: String
    let previewSmall: String?
    let previewLarge: String?
    let isActive: Bool
}
