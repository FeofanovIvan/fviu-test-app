//
//  RemoteVideoThumbnail.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import AVFoundation
import SwiftUI

struct RemoteVideoThumbnail: View {
    let url: URL?
    var isActive: Bool = true
    var isOnScreen: Bool = true

    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    @State private var requestID = UUID()
    @State private var loadTask: Task<Void, Never>?
    @State private var loadedURL: URL?

    var body: some View {
        Group {
            if let player {
                VideoPlayerLayerView(player: player, videoGravity: .resizeAspectFill)
            } else {
                placeholder
            }
        }
        .clipped()
        .onAppear { sync() }
        .onDisappear { teardown() }
        .onChange(of: isOnScreen) { _ in sync() }
        .onChange(of: isActive) { _ in applyPlaybackState() }
        .onChange(of: url) { _ in sync() }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [AppColors.gradientBlue.opacity(0.35), AppColors.gradientPink.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor
    private func sync() {
        loadTask?.cancel()
        let id = UUID()
        requestID = id

        guard let url, isOnScreen || isActive else {
            loadTask = nil
            teardownPlayer()
            return
        }

        loadTask = Task {
            await loadAndPrepare(url: url, requestID: id)
        }
    }

    @MainActor
    private func loadAndPrepare(url: URL, requestID id: UUID) async {
        do {
            let priority: PreviewPriority = isActive ? .active : .prefetch
            let localURL = try await VideoPreviewPrefetcher.shared.localURL(for: url, priority: priority)
            guard requestID == id else { return }
            preparePlayer(localURL)
        } catch is CancellationError {
        } catch {
        }
    }

    @MainActor
    private func preparePlayer(_ localURL: URL) {
        if loadedURL != localURL {
            teardownPlayer()
            loadedURL = localURL
        }

        guard player == nil else {
            applyPlaybackState()
            return
        }

        let item = AVPlayerItem(url: localURL)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = true
        newPlayer.actionAtItemEnd = .none

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }

        player = newPlayer
        applyPlaybackState()
    }

    @MainActor
    private func applyPlaybackState() {
        guard let player else { return }
        if isActive {
            player.play()
        } else {
            player.pause()
        }
    }

    private func teardown() {
        loadTask?.cancel()
        loadTask = nil
        teardownPlayer()
    }

    @MainActor
    private func teardownPlayer() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObserver = nil
        player?.pause()
        player = nil
        loadedURL = nil
    }
}
