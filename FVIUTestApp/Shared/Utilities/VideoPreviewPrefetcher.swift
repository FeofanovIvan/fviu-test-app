//
//  VideoPreviewPrefetcher.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 23/06/26.
//
import Foundation

enum PreviewPriority: Int, Comparable {
    case active = 0
    case prefetch = 1

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

actor VideoPreviewPrefetcher {
    static let shared = VideoPreviewPrefetcher()

    private let maxConcurrent: Int
    private var activeCount = 0
    private var activeDownloads: [URL: DownloadEntry] = [:]
    private var pending: [PendingRequest] = []
    private var waiterCounts: [URL: Int] = [:]

    private struct DownloadEntry {
        let generation: UUID
        let task: Task<URL, Error>
    }

    private struct PendingRequest {
        let id: UUID
        let url: URL
        let priority: PreviewPriority
        let continuation: CheckedContinuation<URL, Error>
    }

    init(maxConcurrent: Int = 3) {
        self.maxConcurrent = maxConcurrent
    }

    func localURL(for url: URL, priority: PreviewPriority) async throws -> URL {
        if let cached = await VideoFileCache.shared.existingLocalURL(for: url) {
            return cached
        }

        let entry: DownloadEntry
        if let existing = activeDownloads[url], !existing.task.isCancelled {
            entry = existing
        } else if activeCount < maxConcurrent {
            entry = start(url)
        } else {
            let id = UUID()
            return try await withTaskCancellationHandler(
                operation: {
                    try await withCheckedThrowingContinuation { continuation in
                        pending.append(PendingRequest(id: id, url: url, priority: priority, continuation: continuation))
                    }
                },
                onCancel: { [weak self] in
                    Task { await self?.dropPending(id: id) }
                }
            )
        }

        waiterCounts[url, default: 0] += 1
        return try await withTaskCancellationHandler(
            operation: { try await entry.task.value },
            onCancel: { [weak self] in
                Task { await self?.releaseWaiter(for: url) }
            }
        )
    }

    private func releaseWaiter(for url: URL) {
        let remaining = (waiterCounts[url] ?? 1) - 1
        if remaining > 0 {
            waiterCounts[url] = remaining
            return
        }
        waiterCounts[url] = nil
        activeDownloads[url]?.task.cancel()
    }

    private func dropPending(id: UUID) {
        guard let index = pending.firstIndex(where: { $0.id == id }) else { return }
        let request = pending.remove(at: index)
        request.continuation.resume(throwing: CancellationError())
    }

    private func start(_ url: URL) -> DownloadEntry {
        activeCount += 1
        let generation = UUID()
        let task = Task<URL, Error> { try await VideoFileCache.shared.download(url) }
        let entry = DownloadEntry(generation: generation, task: task)
        activeDownloads[url] = entry

        Task {
            _ = try? await task.value
            self.finish(url, generation: generation)
        }

        return entry
    }

    private func finish(_ url: URL, generation: UUID) {
        if activeDownloads[url]?.generation == generation {
            activeDownloads[url] = nil
            waiterCounts[url] = nil
        }
        activeCount -= 1
        startNextPending()
    }

    private func startNextPending() {
        guard activeCount < maxConcurrent, !pending.isEmpty else { return }

        guard let bestIndex = pending.indices.min(by: { pending[$0].priority < pending[$1].priority }) else { return }
        let request = pending.remove(at: bestIndex)

        activeCount += 1
        let generation = UUID()
        let task = Task<URL, Error> { try await VideoFileCache.shared.download(request.url) }
        activeDownloads[request.url] = DownloadEntry(generation: generation, task: task)

        Task {
            do {
                let result = try await task.value
                request.continuation.resume(returning: result)
            } catch {
                request.continuation.resume(throwing: error)
            }
            finish(request.url, generation: generation)
        }
    }
}
