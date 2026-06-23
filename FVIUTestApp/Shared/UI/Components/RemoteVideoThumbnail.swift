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

    @State private var frame: UIImage?

    var body: some View {
        Group {
            if let frame {
                // Most PixVerse preview clips are vertical (9:16); several card slots in this app
                // (catalog grid cells, the generator's carousel) are noticeably wider than that.
                // No single crop-window placement (top/center/bottom) is correct for an arbitrary
                // source — it always throws part of the composition away. Instead this never
                // crops the actual subject: the full frame is shown with `.fit` (nothing lost),
                // and a blurred, filled copy of the same frame fills the leftover space behind it
                // so there's no empty letterboxing — the same technique album art / video players
                // use for mismatched aspect ratios.
                ZStack {
                    Image(uiImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 24)
                        .saturation(1.1)
                        .overlay(Color.black.opacity(0.25))

                    Image(uiImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .clipped()
            } else {
                placeholder
            }
        }
        .task(id: url) {
            await loadFrame()
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [AppColors.gradientBlue.opacity(0.35), AppColors.gradientPink.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func loadFrame() async {
        frame = nil
        guard let url else { return }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try await generator.image(at: .zero).image
            frame = UIImage(cgImage: cgImage)
        } catch {
            frame = nil
        }
    }
}
