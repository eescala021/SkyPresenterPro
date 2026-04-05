import AVFoundation
import AppKit
import SwiftUI

struct VideoLoopView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> VideoLoopNSView {
        let view = VideoLoopNSView()
        view.configure(url: url)
        return view
    }

    func updateNSView(_ nsView: VideoLoopNSView, context: Context) {
        if nsView.currentURL != url {
            nsView.configure(url: url)
        }
    }

    static func dismantleNSView(_ nsView: VideoLoopNSView, coordinator: ()) {
        nsView.cleanup()
    }
}

final class VideoLoopNSView: NSView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private(set) var currentURL: URL?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func configure(url: URL) {
        cleanup()
        currentURL = url

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(items: [item])
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none

        let templateItem = AVPlayerItem(url: url)
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer?.addSublayer(layer)

        self.player = queuePlayer
        self.looper = playerLooper
        self.playerLayer = layer

        queuePlayer.play()
    }

    func cleanup() {
        player?.pause()
        player = nil
        looper = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        currentURL = nil
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
}
