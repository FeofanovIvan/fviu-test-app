import Foundation

protocol VideoHistoryStoring {
    func generations() -> [VideoGeneration]
    func save(_ generation: VideoGeneration)
    func delete(_ generation: VideoGeneration)
}
