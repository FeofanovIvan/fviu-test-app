//
//  VideoFileCache.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 23/06/26.
//
import CryptoKit
import Foundation

actor VideoFileCache {
    static let shared = VideoFileCache()

    private let videoDirectory: URL

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.httpMaximumConnectionsPerHost = 3
        return URLSession(configuration: configuration)
    }()

    private init() {
        let cachesRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let root = cachesRoot.appendingPathComponent("VideoPreviewCache", isDirectory: true)
        videoDirectory = root.appendingPathComponent("Videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
    }

    func existingLocalURL(for remoteURL: URL) -> URL? {
        let destination = videoFileURL(for: remoteURL)
        return FileManager.default.fileExists(atPath: destination.path) ? destination : nil
    }

    func download(_ remoteURL: URL) async throws -> URL {
        if let existing = existingLocalURL(for: remoteURL) {
            return existing
        }
        try Task.checkCancellation()

        let destination = videoFileURL(for: remoteURL)
        let (tempURL, response) = try await Self.session.download(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    private func videoFileURL(for remoteURL: URL) -> URL {
        let fileExtension = remoteURL.pathExtension.isEmpty ? "mp4" : remoteURL.pathExtension
        return videoDirectory.appendingPathComponent(hash(remoteURL)).appendingPathExtension(fileExtension)
    }

    private func hash(_ remoteURL: URL) -> String {
        let digest = SHA256.hash(data: Data(remoteURL.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
