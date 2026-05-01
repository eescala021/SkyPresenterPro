import AppKit
import AVFoundation
import ImageIO
import SwiftUI

struct MediaLibraryThumbnailView<Placeholder: View>: View {
    let item: MediaLibraryItem
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: NSImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .apply(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .onAppear(perform: loadThumbnail)
        .onChange(of: item.id) { _, _ in
            loadThumbnail()
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadThumbnail() {
        loadTask?.cancel()
        image = nil

        let currentItem = item
        loadTask = Task(priority: .utility) {
            let thumbnail = await ProjectionMediaThumbnailService.shared.thumbnail(for: currentItem)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                if item.id == currentItem.id {
                    image = thumbnail
                }
            }
        }
    }
}

actor ProjectionMediaThumbnailService {
    static let shared = ProjectionMediaThumbnailService()

    private let cache = NSCache<NSString, NSImage>()
    private var inFlightTasks: [String: Task<NSImage?, Never>] = [:]
    private let previewSize = CGSize(width: 640, height: 360)

    private init() {
        cache.countLimit = 128
        cache.totalCostLimit = 96 * 1024 * 1024
    }

    func thumbnail(for item: MediaLibraryItem) async -> NSImage? {
        let key = "\(item.kind.rawValue)|\(item.filePath)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let taskKey = key as String
        if let task = inFlightTasks[taskKey] {
            return await task.value
        }

        let task = Task(priority: .utility) { [previewSize] in
            switch item.kind {
            case .image:
                return Self.loadImageThumbnail(at: item.filePath, maxPixelSize: previewSize)
            case .video:
                return await Self.generateVideoThumbnail(at: item.filePath, maxPixelSize: previewSize)
            }
        }
        inFlightTasks[taskKey] = task

        let result = await task.value
        inFlightTasks[taskKey] = nil

        if let result {
            cache.setObject(result, forKey: key, cost: result.cacheCost)
        }

        return result
    }

    nonisolated private static func loadImageThumbnail(at path: String, maxPixelSize: CGSize) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return NSImage(contentsOfFile: path)
        }

        let maxDimension = max(maxPixelSize.width, maxPixelSize.height)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            return NSImage(cgImage: cgImage, size: .zero)
        }

        return NSImage(contentsOfFile: path)
    }

    nonisolated private static func generateVideoThumbnail(at path: String, maxPixelSize: CGSize) async -> NSImage? {
        let asset = ProjectionVideoAssetCache.shared.asset(for: path)
        do {
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = maxPixelSize
            generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)
            generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)

            for second in candidateCaptureSeconds(duration: durationSeconds) {
                let captureTime = CMTime(seconds: second, preferredTimescale: 600)
                if let image = try await generateCGImage(using: generator, at: captureTime) {
                    return NSImage(cgImage: image, size: .zero)
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    nonisolated private static func candidateCaptureSeconds(duration: Double) -> [Double] {
        guard duration.isFinite, duration > 0 else {
            return [0.5, 1.0]
        }

        let trimmedDuration = max(0.6, duration - 0.1)
        return [
            min(1.0, trimmedDuration),
            min(max(0.35, duration * 0.15), trimmedDuration),
            min(max(0.75, duration * 0.35), trimmedDuration),
            min(max(1.2, duration * 0.6), trimmedDuration)
        ]
    }

    nonisolated private static func generateCGImage(
        using generator: AVAssetImageGenerator,
        at time: CMTime
    ) async throws -> CGImage? {
        try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { image, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
}
