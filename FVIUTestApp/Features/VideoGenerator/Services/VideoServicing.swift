//
//  VideoServicing.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

protocol VideoServicing {
    func generateVideo(
        prompt: String,
        userID: String,
        aspectRatio: VideoAspectRatio,
        quality: VideoQuality
    ) async throws -> VideoGeneration

    func fetchTemplates(userID: String) async throws -> [VideoTemplate]
}
