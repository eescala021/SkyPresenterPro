import AppKit
import AVFoundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Models

enum GradientPreset: String, Codable, CaseIterable, Identifiable {
    case midnight
    case deepBlue
    case purple
    case warmSunset
    case forest
    case ocean
    case charcoal
    case aurora

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight:   return "Medianoche"
        case .deepBlue:   return "Azul Profundo"
        case .purple:     return "Púrpura"
        case .warmSunset: return "Atardecer"
        case .forest:     return "Bosque"
        case .ocean:      return "Océano"
        case .charcoal:   return "Carbón"
        case .aurora:     return "Aurora"
        }
    }

    var colors: [Color] {
        switch self {
        case .midnight:
            return [Color.black, Color(red: 0.04, green: 0.06, blue: 0.10), Color(red: 0.01, green: 0.02, blue: 0.04)]
        case .deepBlue:
            return [Color(red: 0.02, green: 0.05, blue: 0.18), Color(red: 0.04, green: 0.10, blue: 0.28), Color(red: 0.01, green: 0.03, blue: 0.12)]
        case .purple:
            return [Color(red: 0.12, green: 0.02, blue: 0.18), Color(red: 0.22, green: 0.06, blue: 0.30), Color(red: 0.08, green: 0.01, blue: 0.14)]
        case .warmSunset:
            return [Color(red: 0.22, green: 0.06, blue: 0.04), Color(red: 0.32, green: 0.10, blue: 0.06), Color(red: 0.14, green: 0.03, blue: 0.02)]
        case .forest:
            return [Color(red: 0.02, green: 0.10, blue: 0.06), Color(red: 0.04, green: 0.18, blue: 0.10), Color(red: 0.01, green: 0.06, blue: 0.03)]
        case .ocean:
            return [Color(red: 0.01, green: 0.08, blue: 0.16), Color(red: 0.02, green: 0.14, blue: 0.26), Color(red: 0.01, green: 0.04, blue: 0.10)]
        case .charcoal:
            return [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.14, green: 0.14, blue: 0.14), Color(red: 0.04, green: 0.04, blue: 0.04)]
        case .aurora:
            return [Color(red: 0.02, green: 0.06, blue: 0.14), Color(red: 0.06, green: 0.16, blue: 0.22), Color(red: 0.04, green: 0.10, blue: 0.12)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum BackgroundKind: String, Codable {
    case gradient
    case image
    case video
}

struct BackgroundThemeSettings: Codable {
    var kind: BackgroundKind = .gradient
    var gradientPreset: GradientPreset = .midnight
}

struct ThemeAsset: Identifiable, Hashable, Codable {
    enum AssetKind: String, Codable {
        case image
        case video
    }

    let id: UUID
    let title: String
    let fileName: String
    let kind: AssetKind
}

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    private struct ThemeAssetMetadataStore: Codable {
        var imageLibrary: [ThemeAsset]
        var videoLibrary: [ThemeAsset]
        var activeImageID: UUID?
        var activeVideoID: UUID?
    }

    @Published var themeSettings: BackgroundThemeSettings {
        didSet { persistSettings() }
    }
    @Published private(set) var backgroundImage: NSImage?
    @Published private(set) var videoURL: URL?
    @Published private(set) var videoThumbnail: NSImage?
    @Published private(set) var imageLibrary: [ThemeAsset] = []
    @Published private(set) var videoLibrary: [ThemeAsset] = []
    @Published var activeImageID: ThemeAsset.ID? {
        didSet {
            loadActiveImage()
            persistAssetMetadata()
        }
    }
    @Published var activeVideoID: ThemeAsset.ID? {
        didSet {
            loadActiveVideo()
            persistAssetMetadata()
        }
    }

    private static let settingsKey = "ThemeManager.settings"
    private static let imageLibraryKey = "ThemeManager.imageLibrary"
    private static let videoLibraryKey = "ThemeManager.videoLibrary"
    private static let activeImageKey = "ThemeManager.activeImageID"
    private static let activeVideoKey = "ThemeManager.activeVideoID"

    private let themesDirectory: URL
    private let metadataURL: URL
    private var imageThumbnailCache: [UUID: NSImage] = [:]
    private var videoThumbnailCache: [UUID: NSImage] = [:]
    private var videoThumbnailRequests: Set<UUID> = []

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.themesDirectory = appSupport.appendingPathComponent("SkyPresenterPro/themes", isDirectory: true)
        self.metadataURL = themesDirectory.appendingPathComponent("theme-assets.json")

        // Load persisted settings
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(BackgroundThemeSettings.self, from: data) {
            self.themeSettings = decoded
        } else {
            self.themeSettings = BackgroundThemeSettings()
        }

        createDirectoriesIfNeeded()
        loadPersistedAssets()
    }

    // MARK: - Import Image

    func importBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Seleccionar Imagen de Fondo"

        guard panel.runModal() == .OK else { return }

        let imported = panel.urls.compactMap { copyAsset(from: $0, kind: .image) }
        guard !imported.isEmpty else { return }
        imageLibrary.append(contentsOf: imported)
        activeImageID = imported.last?.id
        themeSettings.kind = .image
        persistAssetMetadata()
    }

    func removeBackgroundImage() {
        guard let asset = activeImageAsset else { return }
        try? FileManager.default.removeItem(at: assetURL(for: asset))
        imageLibrary.removeAll { $0.id == asset.id }
        activeImageID = imageLibrary.last?.id
        if themeSettings.kind == .image {
            themeSettings.kind = .gradient
        }
        persistAssetMetadata()
    }

    // MARK: - Import Video

    func importBackgroundVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "mp4") ?? .movie,
            UTType(filenameExtension: "mov") ?? .movie,
            .movie
        ]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Seleccionar Video de Fondo"

        guard panel.runModal() == .OK else { return }

        let imported = panel.urls.compactMap { copyAsset(from: $0, kind: .video) }
        guard !imported.isEmpty else { return }
        videoLibrary.append(contentsOf: imported)
        activeVideoID = imported.last?.id
        themeSettings.kind = .video
        persistAssetMetadata()
    }

    func removeBackgroundVideo() {
        guard let asset = activeVideoAsset else { return }
        try? FileManager.default.removeItem(at: assetURL(for: asset))
        videoLibrary.removeAll { $0.id == asset.id }
        activeVideoID = videoLibrary.last?.id
        if themeSettings.kind == .video {
            themeSettings.kind = .gradient
        }
        persistAssetMetadata()
    }

    // MARK: - Gradient Selection

    func selectGradient(_ preset: GradientPreset) {
        themeSettings.kind = .gradient
        themeSettings.gradientPreset = preset
    }

    func selectImageBackground(_ id: ThemeAsset.ID? = nil) {
        if let id {
            activeImageID = id
        }
        guard activeImageAsset != nil else { return }
        themeSettings.kind = .image
    }

    func selectVideoBackground(_ id: ThemeAsset.ID? = nil) {
        if let id {
            activeVideoID = id
        }
        guard activeVideoAsset != nil else { return }
        themeSettings.kind = .video
    }

    func resetToDefault() {
        themeSettings = BackgroundThemeSettings()
    }

    func preheatActiveAssets() {
        if let asset = activeImageAsset {
            _ = imageThumbnail(for: asset)
        }
        if let asset = activeVideoAsset {
            _ = videoThumbnail(for: asset)
        }
    }

    @discardableResult
    func importBackupAssets(
        from backupThemesDirectory: URL,
        imageLibrary importedImageLibrary: [ThemeAsset],
        videoLibrary importedVideoLibrary: [ThemeAsset],
        activeImageID importedActiveImageID: ThemeAsset.ID?,
        activeVideoID importedActiveVideoID: ThemeAsset.ID?
    ) throws -> Int {
        guard FileManager.default.fileExists(atPath: backupThemesDirectory.path) else { return 0 }

        var importedCount = 0

        for asset in importedImageLibrary + importedVideoLibrary {
            let sourceURL = backupThemesDirectory.appendingPathComponent(asset.fileName)
            let destinationURL = themesDirectory.appendingPathComponent(asset.fileName)
            guard FileManager.default.fileExists(atPath: sourceURL.path) else { continue }

            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                importedCount += 1
            }
        }

        let existingImageIDs = Set(imageLibrary.map(\.id))
        let existingVideoIDs = Set(videoLibrary.map(\.id))

        imageLibrary.append(contentsOf: importedImageLibrary.filter { !existingImageIDs.contains($0.id) })
        videoLibrary.append(contentsOf: importedVideoLibrary.filter { !existingVideoIDs.contains($0.id) })

        if activeImageID == nil, let importedActiveImageID, imageLibrary.contains(where: { $0.id == importedActiveImageID }) {
            activeImageID = importedActiveImageID
        }

        if activeVideoID == nil, let importedActiveVideoID, videoLibrary.contains(where: { $0.id == importedActiveVideoID }) {
            activeVideoID = importedActiveVideoID
        }

        persistAssetMetadata()
        loadPersistedAssets()
        return importedCount
    }

    // MARK: - Private

    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: themesDirectory, withIntermediateDirectories: true)
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(themeSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    private func loadPersistedAssets() {
        let metadata = loadThemeAssetMetadata()
        imageLibrary = metadata.imageLibrary.filter { FileManager.default.fileExists(atPath: assetURL(for: $0).path) }
        videoLibrary = metadata.videoLibrary.filter { FileManager.default.fileExists(atPath: assetURL(for: $0).path) }
        activeImageID = metadata.activeImageID ?? imageLibrary.first?.id
        activeVideoID = metadata.activeVideoID ?? videoLibrary.first?.id

        loadActiveImage()
        loadActiveVideo()
    }

    private func persistAssetMetadata() {
        let store = ThemeAssetMetadataStore(
            imageLibrary: imageLibrary,
            videoLibrary: videoLibrary,
            activeImageID: activeImageID,
            activeVideoID: activeVideoID
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(store) {
            try? data.write(to: metadataURL, options: Data.WritingOptions.atomic)
        }

        UserDefaults.standard.removeObject(forKey: Self.imageLibraryKey)
        UserDefaults.standard.removeObject(forKey: Self.videoLibraryKey)
        UserDefaults.standard.set(activeImageID?.uuidString, forKey: Self.activeImageKey)
        UserDefaults.standard.set(activeVideoID?.uuidString, forKey: Self.activeVideoKey)
    }

    private func loadThemeAssetMetadata() -> ThemeAssetMetadataStore {
        if let data = try? Data(contentsOf: metadataURL),
           let decoded = try? JSONDecoder().decode(ThemeAssetMetadataStore.self, from: data) {
            return decoded
        }

        let migrated = migrateLegacyThemeAssetMetadata()
        if let migrated {
            return migrated
        }

        return ThemeAssetMetadataStore(
            imageLibrary: [],
            videoLibrary: [],
            activeImageID: nil,
            activeVideoID: nil
        )
    }

    private func migrateLegacyThemeAssetMetadata() -> ThemeAssetMetadataStore? {
        let defaults = UserDefaults.standard
        let imageLibrary: [ThemeAsset]
        if let data = defaults.data(forKey: Self.imageLibraryKey),
           let decoded = try? JSONDecoder().decode([ThemeAsset].self, from: data) {
            imageLibrary = decoded
        } else {
            imageLibrary = []
        }

        let videoLibrary: [ThemeAsset]
        if let data = defaults.data(forKey: Self.videoLibraryKey),
           let decoded = try? JSONDecoder().decode([ThemeAsset].self, from: data) {
            videoLibrary = decoded
        } else {
            videoLibrary = []
        }

        let activeImageID = defaults.string(forKey: Self.activeImageKey).flatMap(UUID.init(uuidString:))
        let activeVideoID = defaults.string(forKey: Self.activeVideoKey).flatMap(UUID.init(uuidString:))

        guard !imageLibrary.isEmpty || !videoLibrary.isEmpty || activeImageID != nil || activeVideoID != nil else {
            return nil
        }

        let store = ThemeAssetMetadataStore(
            imageLibrary: imageLibrary,
            videoLibrary: videoLibrary,
            activeImageID: activeImageID,
            activeVideoID: activeVideoID
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(store) {
            try? data.write(to: metadataURL, options: Data.WritingOptions.atomic)
        }

        defaults.removeObject(forKey: Self.imageLibraryKey)
        defaults.removeObject(forKey: Self.videoLibraryKey)
        return store
    }

    private var activeImageAsset: ThemeAsset? {
        imageLibrary.first { $0.id == activeImageID } ?? imageLibrary.first
    }

    private var activeVideoAsset: ThemeAsset? {
        videoLibrary.first { $0.id == activeVideoID } ?? videoLibrary.first
    }

    private func loadActiveImage() {
        guard let asset = activeImageAsset else {
            backgroundImage = nil
            return
        }
        backgroundImage = NSImage(contentsOf: assetURL(for: asset))
        if let backgroundImage {
            imageThumbnailCache[asset.id] = backgroundImage
        }
    }

    private func loadActiveVideo() {
        guard let asset = activeVideoAsset else {
            videoURL = nil
            videoThumbnail = nil
            return
        }
        let url = assetURL(for: asset)
        videoURL = url
        generateVideoThumbnail(from: url)
    }

    private func copyAsset(from url: URL, kind: ThemeAsset.AssetKind) -> ThemeAsset? {
        let id = UUID()
        let ext = url.pathExtension.isEmpty ? (kind == .image ? "png" : "mp4") : url.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = themesDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return ThemeAsset(id: id, title: url.deletingPathExtension().lastPathComponent, fileName: fileName, kind: kind)
        } catch {
            return nil
        }
    }

    private func assetURL(for asset: ThemeAsset) -> URL {
        themesDirectory.appendingPathComponent(asset.fileName)
    }

    private func generateVideoThumbnail(from url: URL) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)

        let time = CMTime(seconds: 1, preferredTimescale: 600)
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, _, _ in
            guard let cgImage else { return }
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            DispatchQueue.main.async {
                if self?.videoURL == url {
                    self?.videoThumbnail = nsImage
                    if let asset = self?.videoLibrary.first(where: { self?.assetURL(for: $0) == url }) {
                        self?.videoThumbnailCache[asset.id] = nsImage
                    }
                }
            }
        }
    }

    func imageThumbnail(for asset: ThemeAsset) -> NSImage? {
        if let cached = imageThumbnailCache[asset.id] {
            return cached
        }
        guard asset.kind == .image, let image = NSImage(contentsOf: assetURL(for: asset)) else {
            return nil
        }
        imageThumbnailCache[asset.id] = image
        return image
    }

    func videoThumbnail(for asset: ThemeAsset) -> NSImage? {
        if let cached = videoThumbnailCache[asset.id] {
            return cached
        }

        if !videoThumbnailRequests.contains(asset.id) {
            videoThumbnailRequests.insert(asset.id)
            let url = assetURL(for: asset)
            let time = CMTime(seconds: 1, preferredTimescale: 600)

            Task { [weak self] in
                guard let self else { return }
                let image = await self.generateVideoThumbnailImage(from: url, at: time)
                await MainActor.run {
                    self.videoThumbnailRequests.remove(asset.id)
                    guard let image else { return }
                    self.videoThumbnailCache[asset.id] = image
                    self.objectWillChange.send()
                }
            }
        }

        return nil
    }

    var hasImportedImage: Bool { !imageLibrary.isEmpty }
    var hasImportedVideo: Bool { !videoLibrary.isEmpty }

    func backgroundImage(for override: ProjectionBackgroundOverride?) -> NSImage? {
        guard let override else { return backgroundImage }
        switch override.assetKind {
        case .image:
            guard let asset = imageLibrary.first(where: { $0.id == override.assetID }) else { return backgroundImage }
            return imageThumbnail(for: asset)
        case .video:
            guard let asset = videoLibrary.first(where: { $0.id == override.assetID }) else { return backgroundImage }
            return videoThumbnail(for: asset) ?? videoThumbnailCache[asset.id] ?? backgroundImage
        }
    }

    func backgroundVideoURL(for override: ProjectionBackgroundOverride?) -> URL? {
        guard let override else { return videoURL }
        guard override.assetKind == .video,
              let asset = videoLibrary.first(where: { $0.id == override.assetID }) else { return nil }
        return assetURL(for: asset)
    }

    func backgroundLabel(for assetID: UUID?, kind: ThemeAsset.AssetKind?) -> String {
        guard let assetID, let kind else { return "Tema global" }
        switch kind {
        case .image:
            return imageLibrary.first(where: { $0.id == assetID })?.title ?? "Imagen específica"
        case .video:
            return videoLibrary.first(where: { $0.id == assetID })?.title ?? "Video específico"
        }
    }
}

private extension ThemeManager {
    func generateVideoThumbnailImage(from url: URL, at time: CMTime) async -> NSImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)

        guard let cgImage = try? await generator.image(at: time).image else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
