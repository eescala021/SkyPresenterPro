import AVKit
import SwiftUI

struct LoopingVideoPlayerView: NSViewRepresentable {
    let filePath: String
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = videoGravity
        view.player = context.coordinator.player
        context.coordinator.update(filePath: filePath)
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.videoGravity = videoGravity
        nsView.player = context.coordinator.player
        context.coordinator.update(filePath: filePath)
    }

    static func dismantleNSView(_ nsView: AVPlayerView, coordinator: Coordinator) {
        coordinator.stop()
        nsView.player = nil
    }

    final class Coordinator {
        let player = AVQueuePlayer()
        private var looper: AVPlayerLooper?
        private var currentPath: String?

        init() {
            player.isMuted = true
            player.actionAtItemEnd = .none
        }

        func update(filePath: String) {
            guard currentPath != filePath else { return }

            currentPath = filePath
            player.pause()
            player.removeAllItems()

            let asset = ProjectionVideoAssetCache.shared.asset(for: filePath)
            let item = AVPlayerItem(asset: asset)
            looper = AVPlayerLooper(player: player, templateItem: item)
            player.play()
        }

        func stop() {
            player.pause()
            player.removeAllItems()
            looper = nil
            currentPath = nil
        }
    }
}

final class ProjectionVideoAssetCache {
    static let shared = ProjectionVideoAssetCache()

    private let cache = NSCache<NSString, AVURLAsset>()

    private init() {
        cache.countLimit = 24
    }

    func asset(for path: String) -> AVURLAsset {
        if let cached = cache.object(forKey: path as NSString) {
            return cached
        }

        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        cache.setObject(asset, forKey: path as NSString)
        return asset
    }
}
