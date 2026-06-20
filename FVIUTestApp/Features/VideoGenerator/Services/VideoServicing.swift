import Foundation

protocol VideoServicing {
    func generateVideo(
        prompt: String,
        userID: String,
        aspectRatio: VideoAspectRatio,
        quality: VideoQuality
    ) async throws -> VideoGeneration
}
