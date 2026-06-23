//
//  VideoService.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

final class VideoService: VideoServicing {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func generateVideo(
        prompt: String,
        userID: String,
        aspectRatio: VideoAspectRatio,
        quality: VideoQuality
    ) async throws -> VideoGeneration {
        let createEndpoint = Endpoint(
            baseURL: AppConfig.videoBaseURL,
            path: "/api/v1/text2video",
            method: .post,
            queryItems: [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "app_id", value: AppConfig.apiApplicationID)
            ],
            bodyData: formURLEncodedData([
                "prompt": prompt,
                "duration": "5",
                "model": "v6",
                "quality": quality.rawValue.lowercased(),
                "aspect_ratio": aspectRatio.rawValue
            ]),
            contentType: "application/x-www-form-urlencoded"
        )

        do {
            let response = try await networkClient.request(createEndpoint, as: VideoGenerationResponse.self)
            let status = try await pollStatus(
                videoID: response.videoId,
                prompt: prompt,
                userID: userID,
                aspectRatio: aspectRatio,
                quality: quality
            )
            return status
        } catch let error as NetworkError {
            throw error.appError
        } catch {
            throw AppError.unknown
        }
    }

    private func pollStatus(
        videoID: Int,
        prompt: String,
        userID: String,
        aspectRatio: VideoAspectRatio,
        quality: VideoQuality
    ) async throws -> VideoGeneration {
        for _ in 0..<12 {
            let endpoint = Endpoint(
                baseURL: AppConfig.videoBaseURL,
                path: "/api/v1/status",
                queryItems: [
                    URLQueryItem(name: "id", value: String(videoID)),
                    URLQueryItem(name: "user_id", value: userID),
                    URLQueryItem(name: "app_id", value: AppConfig.apiApplicationID)
                ]
            )

            let response = try await networkClient.request(endpoint, as: VideoGenerationStatusResponse.self)
            let normalizedStatus = response.status?.lowercased() ?? ""

            if let url = response.resultURL, normalizedStatus.contains("success") || normalizedStatus.contains("ready") || normalizedStatus.contains("completed") {
                return VideoGeneration(prompt: prompt, status: .ready(url), aspectRatio: aspectRatio, quality: quality)
            }

            if normalizedStatus.contains("fail") || normalizedStatus.contains("error") {
                throw AppError(title: L10n.videoGenerationErrorTitle, message: L10n.videoGenerationErrorMessage)
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
        }

        throw AppError(title: L10n.videoGenerationErrorTitle, message: L10n.videoGenerationErrorMessage)
    }

    func fetchTemplates(userID: String) async throws -> [VideoTemplate] {
        let endpoint = Endpoint(
            baseURL: AppConfig.videoBaseURL,
            path: "/api/v1/get_templates/\(AppConfig.apiApplicationID)",
            queryItems: [
                URLQueryItem(name: "user_id", value: userID)
            ]
        )

        do {
            let response = try await networkClient.request(endpoint, as: TemplatesCatalogResponse.self)
            return response.templates
                .filter(\.isActive)
                .compactMap { dto in
                    let previewURLString = dto.previewLarge ?? dto.previewSmall
                    guard let previewURLString, let previewURL = URL(string: previewURLString) else {
                        return nil
                    }

                    return VideoTemplate(
                        title: dto.name,
                        category: dto.category,
                        prompt: dto.prompt,
                        previewURL: previewURL
                    )
                }
        } catch let error as NetworkError {
            throw error.appError
        } catch {
            throw AppError.unknown
        }
    }

    private func formURLEncodedData(_ fields: [String: String]) -> Data {
        fields
            .map { key, value in
                "\(escape(key))=\(escape(value))"
            }
            .joined(separator: "&")
            .data(using: .utf8) ?? Data()
    }

    private func escape(_ value: String) -> String {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "&+=?")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
}
