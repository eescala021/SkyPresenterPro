import AppKit
import Combine
import Foundation
import PDFKit
import UniformTypeIdentifiers
import Vision

enum MediaKind: String, Codable {
    case pdf = "PDF"
    case image = "Imagen"
}

struct MediaItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let url: URL
    let kind: MediaKind

    init(id: UUID = UUID(), title: String, url: URL, kind: MediaKind) {
        self.id = id
        self.title = title
        self.url = url
        self.kind = kind
    }
}

final class PDFManager: ObservableObject {
    private struct MediaLibraryStore: Codable {
        var items: [MediaItem]
    }

    @Published var items: [MediaItem] = []
    @Published var lastImportError: String?
    private var documentCache: [URL: PDFDocument] = [:]
    private var imageCache: [String: NSImage] = [:]
    private var textCache: [String: String] = [:]
    private static let storageKey = "PDFManager.items"
    private let mediaDirectory: URL
    private let metadataURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.mediaDirectory = appSupport.appendingPathComponent("SkyPresenterPro/media", isDirectory: true)
        self.metadataURL = mediaDirectory.appendingPathComponent("media-library.json")
        try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        loadPersistedItems()
    }

    func importMedia() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .png, .jpeg, .gif, .image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }

        let imported = panel.urls.compactMap { url -> MediaItem? in
            switch url.pathExtension.lowercased() {
            case "pdf":
                return copyImportedItem(from: url, kind: .pdf)
            case "png", "jpg", "jpeg", "gif", "heic", "webp":
                return copyImportedItem(from: url, kind: .image)
            default:
                return nil
            }
        }

        if imported.isEmpty {
            lastImportError = "No se encontraron archivos compatibles."
        } else {
            items.append(contentsOf: imported)
            persistItems()
            lastImportError = nil
        }
    }

    func removeItem(id: MediaItem.ID) {
        guard let item = items.first(where: { $0.id == id }) else {
            items.removeAll { $0.id == id }
            return
        }
        items.removeAll { $0.id == id }
        documentCache[item.url] = nil
        imageCache = imageCache.filter { !$0.key.hasPrefix(item.id.uuidString) }
        textCache = textCache.filter { !$0.key.hasPrefix(item.id.uuidString) }
        try? FileManager.default.removeItem(at: item.url)
        persistItems()
    }

    func imageData(for item: MediaItem) -> Data? {
        image(for: item, pageIndex: 0)?.tiffRepresentation
    }

    func imageData(for item: MediaItem, pageIndex: Int) -> Data? {
        image(for: item, pageIndex: pageIndex)?.tiffRepresentation
    }

    func image(for item: MediaItem, pageIndex: Int = 0) -> NSImage? {
        image(for: item, pageIndex: pageIndex, targetSize: CGSize(width: 1600, height: 900))
    }

    func image(for item: MediaItem, pageIndex: Int = 0, targetSize: CGSize) -> NSImage? {
        let key = cacheKey(for: item, pageIndex: pageIndex, targetSize: targetSize)
        if let cached = imageCache[key] {
            return cached
        }

        switch item.kind {
        case .image:
            guard let image = scaledImage(from: item.url, targetSize: targetSize) else { return nil }
            imageCache[key] = image
            return image
        case .pdf:
            guard let page = document(for: item)?.page(at: pageIndex) else { return nil }
            let image = page.thumbnail(of: targetSize, for: .mediaBox)
            imageCache[key] = image
            return image
        }
    }

    func pageCount(for item: MediaItem) -> Int {
        switch item.kind {
        case .image:
            return 1
        case .pdf:
            return document(for: item)?.pageCount ?? 0
        }
    }

    func recognizedText(for item: MediaItem, pageIndex: Int = 0) async -> String {
        let key = cacheKey(for: item, pageIndex: pageIndex, targetSize: CGSize(width: 1600, height: 900))
        if let cached = textCache[key] {
            return cached
        }

        if item.kind == .pdf,
           let pdfText = document(for: item)?.page(at: pageIndex)?.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !pdfText.isEmpty {
            await MainActor.run {
                textCache[key] = pdfText
            }
            return pdfText
        }

        guard let image = image(for: item, pageIndex: pageIndex),
              let cgImage = cgImage(for: image) else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["es-ES", "en-US"]

        do {
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])
            let text = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            await MainActor.run {
                textCache[key] = text
            }
            return text
        } catch {
            return ""
        }
    }

    private func document(for item: MediaItem) -> PDFDocument? {
        if let cached = documentCache[item.url] {
            return cached
        }
        guard let document = PDFDocument(url: item.url) else { return nil }
        documentCache[item.url] = document
        return document
    }

    private func cacheKey(for item: MediaItem, pageIndex: Int, targetSize: CGSize) -> String {
        "\(item.id.uuidString)-\(pageIndex)-\(Int(targetSize.width))x\(Int(targetSize.height))"
    }

    private func cgImage(for image: NSImage) -> CGImage? {
        var proposedRect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    private func scaledImage(from url: URL, targetSize: CGSize) -> NSImage? {
        guard let source = NSImage(contentsOf: url) else { return nil }
        let widthRatio = targetSize.width / max(source.size.width, 1)
        let heightRatio = targetSize.height / max(source.size.height, 1)
        let scale = min(widthRatio, heightRatio, 1)
        let size = CGSize(
            width: max(source.size.width * scale, 1),
            height: max(source.size.height * scale, 1)
        )

        let image = NSImage(size: size)
        image.lockFocus()
        source.draw(in: CGRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }

    private func copyImportedItem(from url: URL, kind: MediaKind) -> MediaItem? {
        let id = UUID()
        let ext = url.pathExtension.isEmpty ? fallbackExtension(for: kind) : url.pathExtension
        let destination = mediaDirectory.appendingPathComponent("\(id.uuidString).\(ext)")

        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return MediaItem(id: id, title: url.deletingPathExtension().lastPathComponent, url: destination, kind: kind)
        } catch {
            return nil
        }
    }

    private func fallbackExtension(for kind: MediaKind) -> String {
        switch kind {
        case .pdf: return "pdf"
        case .image: return "png"
        }
    }

    private func persistItems() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(MediaLibraryStore(items: items)) else { return }
        try? data.write(to: metadataURL, options: .atomic)
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    private func loadPersistedItems() {
        if let data = try? Data(contentsOf: metadataURL),
           let decoded = try? JSONDecoder().decode(MediaLibraryStore.self, from: data) {
            items = decoded.items.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            return
        }

        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) else { return }
        items = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
        persistItems()
    }
}
