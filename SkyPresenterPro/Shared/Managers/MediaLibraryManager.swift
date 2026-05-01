import AppKit
import AVFoundation
import Combine
import Foundation
import UniformTypeIdentifiers

struct MediaLibraryItem: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case image
        case video
    }

    let id: UUID
    var name: String
    var filePath: String
    var kind: Kind
    var isDefault: Bool
    var duration: Double?

    init(
        id: UUID = UUID(),
        name: String,
        filePath: String,
        kind: Kind,
        isDefault: Bool = false,
        duration: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.kind = kind
        self.isDefault = isDefault
        self.duration = duration
    }
}

@MainActor
final class MediaLibraryManager: ObservableObject {
    @Published private(set) var imageItems: [MediaLibraryItem] = []
    @Published private(set) var videoItems: [MediaLibraryItem] = []

    private let fileManager = FileManager.default
    private let metadataFileName = "media-library.json"
    private let imagesFolderName = "Images"
    private let videosFolderName = "Videos"

    init() {
        bootstrapLibrary()
    }

    func addImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.title = "Seleccionar imágenes"

        guard panel.runModal() == .OK else { return }
        importItems(from: panel.urls, kind: .image)
    }

    func addVideos() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.title = "Seleccionar videos"

        guard panel.runModal() == .OK else { return }
        importItems(from: panel.urls, kind: .video)
    }

    func rename(_ item: MediaLibraryItem, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch item.kind {
        case .image:
            guard let index = imageItems.firstIndex(where: { $0.id == item.id }) else { return }
            imageItems[index].name = trimmed
        case .video:
            guard let index = videoItems.firstIndex(where: { $0.id == item.id }) else { return }
            videoItems[index].name = trimmed
        }

        saveMetadata()
    }

    func remove(_ item: MediaLibraryItem) {
        switch item.kind {
        case .image:
            imageItems.removeAll { $0.id == item.id }
        case .video:
            videoItems.removeAll { $0.id == item.id }
        }

        if fileManager.fileExists(atPath: item.filePath), !item.isDefault {
            try? fileManager.removeItem(atPath: item.filePath)
        }

        saveMetadata()
    }

    private func bootstrapLibrary() {
        createDirectoriesIfNeeded()
        loadMetadata()
        seedDefaultImagesIfNeeded()
        seedDefaultVideosIfNeeded()
        saveMetadata()
        generateMissingDefaultVideosIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: videosDirectoryURL, withIntermediateDirectories: true)
    }

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL),
              let library = try? JSONDecoder().decode(StoredMediaLibrary.self, from: data) else {
            imageItems = []
            videoItems = []
            return
        }

        imageItems = library.images
        videoItems = library.videos
    }

    private func saveMetadata() {
        let library = StoredMediaLibrary(images: imageItems, videos: videoItems)
        guard let data = try? JSONEncoder().encode(library) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    private func importItems(from urls: [URL], kind: MediaLibraryItem.Kind) {
        for url in urls {
            let targetDirectory = kind == .image ? imagesDirectoryURL : videosDirectoryURL
            let destination = targetDirectory.appendingPathComponent(url.lastPathComponent)

            if fileManager.fileExists(atPath: destination.path) == false {
                try? fileManager.copyItem(at: url, to: destination)
            }

            let item = MediaLibraryItem(
                name: url.deletingPathExtension().lastPathComponent,
                filePath: destination.path,
                kind: kind,
                isDefault: false,
                duration: kind == .video ? 8 : nil
            )

            switch kind {
            case .image:
                imageItems.append(item)
            case .video:
                videoItems.append(item)
            }
        }

        saveMetadata()
    }

    private func seedDefaultImagesIfNeeded() {
        guard imageItems.filter(\.isDefault).count < 10 else { return }

        let palettes: [[NSColor]] = [
            [.systemBlue, .systemTeal],
            [.systemOrange, .systemRed],
            [.systemIndigo, .black],
            [.systemBrown, .systemYellow],
            [.systemPurple, .systemPink],
            [.systemGreen, .systemTeal],
            [.systemGray, .darkGray],
            [.systemCyan, .systemBlue],
            [.systemMint, .systemIndigo],
            [.systemYellow, .systemOrange]
        ]

        var defaults: [MediaLibraryItem] = imageItems.filter(\.isDefault == false)
        let existingDefaultNames = Set(imageItems.filter(\.isDefault).map(\.name))

        for index in 0..<10 {
            let name = "Imagen Predeterminada \(index + 1)"
            guard existingDefaultNames.contains(name) == false else { continue }

            let fileURL = imagesDirectoryURL.appendingPathComponent("default-image-\(index + 1).png")
            if fileManager.fileExists(atPath: fileURL.path) == false {
                generateImage(at: fileURL, title: name, palette: palettes[index % palettes.count], index: index)
            }

            defaults.append(
                MediaLibraryItem(
                    name: name,
                    filePath: fileURL.path,
                    kind: .image,
                    isDefault: true
                )
            )
        }

        imageItems = defaults.sorted { $0.name < $1.name }
    }

    private func seedDefaultVideosIfNeeded() {
        guard videoItems.filter(\.isDefault).count < 10 else { return }

        var defaults: [MediaLibraryItem] = videoItems.filter(\.isDefault == false)
        let existingDefaultNames = Set(videoItems.filter(\.isDefault).map(\.name))

        for index in 0..<10 {
            let name = "Video Loop Predeterminado \(index + 1)"
            guard existingDefaultNames.contains(name) == false else { continue }

            let fileURL = videosDirectoryURL.appendingPathComponent("default-loop-\(index + 1).mp4")
            defaults.append(
                MediaLibraryItem(
                    name: name,
                    filePath: fileURL.path,
                    kind: .video,
                    isDefault: true,
                    duration: 8
                )
            )
        }

        videoItems = defaults.sorted { $0.name < $1.name }
    }

    private func generateMissingDefaultVideosIfNeeded() {
        let missingVideos = videoItems.filter { $0.isDefault && fileManager.fileExists(atPath: $0.filePath) == false }
        guard !missingVideos.isEmpty else { return }

        Task.detached(priority: .utility) {
            for (index, item) in missingVideos.enumerated() {
                try? Self.generateVideoLoop(
                    at: URL(fileURLWithPath: item.filePath),
                    title: item.name,
                    seed: index
                )
            }
        }
    }

    private func generateImage(at url: URL, title: String, palette: [NSColor], index: Int) {
        let size = NSSize(width: 1280, height: 720)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)
        let gradient = NSGradient(colors: palette) ?? NSGradient(starting: palette[0], ending: palette[1])
        gradient?.draw(in: rect, angle: 45)

        let overlay = NSBezierPath(roundedRect: rect.insetBy(dx: 90, dy: 90), xRadius: 24, yRadius: 24)
        NSColor.black.withAlphaComponent(0.22).setFill()
        overlay.fill()

        let circleRect = NSRect(x: 110 + CGFloat(index * 14), y: 110, width: 180, height: 180)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(ovalIn: circleRect).fill()

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 42, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.88)
        ]

        NSString(string: title).draw(at: NSPoint(x: 120, y: 540), withAttributes: titleAttributes)
        NSString(string: "SkyPresenterPro").draw(at: NSPoint(x: 122, y: 495), withAttributes: subtitleAttributes)

        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let data = bitmap.representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }
    }

    private static func generateVideoLoop(at url: URL, title: String, seed: Int) throws {
        let width = 640
        let height = 360
        let frameCount = 96
        let fps: Int32 = 12

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }

            guard let pixelBufferPool = adaptor.pixelBufferPool else { continue }
            var maybeBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybeBuffer)

            guard let pixelBuffer = maybeBuffer else { continue }
            CVPixelBufferLockBaseAddress(pixelBuffer, [])

            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            ) else {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                continue
            }

            let progress = CGFloat(frame) / CGFloat(frameCount - 1)
            let palette = Self.palette(for: seed)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)

            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: [palette.0.cgColor, palette.1.cgColor] as CFArray,
                locations: [0, 1]
            )
            context.drawLinearGradient(
                gradient!,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
                options: []
            )

            context.setFillColor(NSColor.black.withAlphaComponent(0.18).cgColor)
            context.fill(CGRect(x: 60, y: 55, width: width - 120, height: height - 110))

            context.setFillColor(NSColor.white.withAlphaComponent(0.10).cgColor)
            let movingX = 60 + progress * CGFloat(width - 180)
            context.fillEllipse(in: CGRect(x: movingX, y: 220, width: 120, height: 120))

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: NSColor.white.withAlphaComponent(0.82)
            ]

            NSGraphicsContext.saveGraphicsState()
            let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = graphicsContext
            NSString(string: title).draw(at: NSPoint(x: 90, y: 250), withAttributes: titleAttributes)
            NSString(string: "Loop infinito • 8 segundos").draw(at: NSPoint(x: 92, y: 215), withAttributes: subtitleAttributes)
            NSGraphicsContext.restoreGraphicsState()

            let presentationTime = CMTime(value: Int64(frame), timescale: fps)
            adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        }

        input.markAsFinished()
        writer.finishWriting {}
    }

    private static func palette(for seed: Int) -> (NSColor, NSColor) {
        let palettes: [(NSColor, NSColor)] = [
            (.systemBlue, .systemTeal),
            (.systemOrange, .systemPink),
            (.systemIndigo, .black),
            (.systemPurple, .systemBlue),
            (.systemGreen, .systemMint),
            (.systemRed, .systemOrange),
            (.systemBrown, .systemYellow),
            (.systemCyan, .systemIndigo),
            (.darkGray, .systemBlue),
            (.black, .systemPurple)
        ]
        return palettes[seed % palettes.count]
    }

    private var baseDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SkyPresenterPro/Media", isDirectory: true)
    }

    private var imagesDirectoryURL: URL {
        baseDirectoryURL.appendingPathComponent(imagesFolderName, isDirectory: true)
    }

    private var videosDirectoryURL: URL {
        baseDirectoryURL.appendingPathComponent(videosFolderName, isDirectory: true)
    }

    private var metadataURL: URL {
        baseDirectoryURL.appendingPathComponent(metadataFileName)
    }
}

private struct StoredMediaLibrary: Codable {
    var images: [MediaLibraryItem]
    var videos: [MediaLibraryItem]
}
