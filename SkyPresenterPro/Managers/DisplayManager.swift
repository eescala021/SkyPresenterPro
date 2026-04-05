import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct ProjectionPayload: Equatable {
    let source: String
    let reference: String
    let body: String
    let backgroundOverride: ProjectionBackgroundOverride?

    init(
        source: String,
        reference: String,
        body: String,
        backgroundOverride: ProjectionBackgroundOverride? = nil
    ) {
        self.source = source
        self.reference = reference
        self.body = body
        self.backgroundOverride = backgroundOverride
    }
}

struct ProjectionBackgroundOverride: Equatable {
    let assetID: UUID
    let assetKind: ThemeAsset.AssetKind
}

struct MediaProjection: Equatable {
    let source: String
    let title: String
    let subtitle: String
}

struct LogoAsset: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let fileName: String
}

struct BibleProjectionSettings: Codable, Equatable {
    var showsVersionInReference: Bool = true
    var emphasizesSelectedVersion: Bool = true
    var showsImportBadge: Bool = true
    var bodyScaleMultiplier: Double = 1.10
    var referenceScaleMultiplier: Double = 1.10
}

struct SongModuleSettings: Codable, Equatable {
    var showsHistoryPanel: Bool = true
    var showsFilmstrip: Bool = true
    var showsLiveActionsPanel: Bool = true
    var showsLibraryPanel: Bool = true
    var showsCurrentAndNextPreview: Bool = false
}

struct PresentationModuleSettings: Codable, Equatable {
    var analyzesTextForVerses: Bool = true
    var showsDetectionPanel: Bool = true
    var allowsVerseShortcut: Bool = true
    var showsFilmstrip: Bool = true
    var showsInspectorPanel: Bool = true
}

struct ProjectionColorSetting: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: NSColor) {
        let resolved = color.usingColorSpace(.deviceRGB) ?? .white
        self.red = resolved.redComponent
        self.green = resolved.greenComponent
        self.blue = resolved.blueComponent
        self.alpha = resolved.alphaComponent
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct ProjectionStyleSettings: Codable, Equatable {
    var usesAutoTextSize: Bool = true
    var manualTextSize: Double = 88
    var minimumAutoTextSize: Double = 85
    var maximumAutoTextSize: Double = 132
    var usesAutoTextOpacity: Bool = true
    var manualTextOpacity: Double = 0.98
    var textColor: ProjectionColorSetting = ProjectionColorSetting(red: 1, green: 1, blue: 1)
    var shadowOpacity: Double = 0.58
    var shadowRadius: Double = 10
    var shadowOffsetY: Double = 4
    var usesBlackTextBackground: Bool = true
    var usesAutoBackgroundOpacity: Bool = true
    var manualBackgroundOpacity: Double = 0.72
    var referenceScale: Double = 0.42
    var referenceOpacity: Double = 0.82
    var lineSpacing: Double = 10
    var textWidthRatio: Double = 0.90
    var textHorizontalPadding: Double = 18
    var referenceTopInset: Double = 28
    var contentVerticalOffset: Double = 0
    var textBlockCornerRadius: Double = 4
    var bibleTextWidthRatio: Double = 0.90
    var songTextWidthRatio: Double = 0.92

    static let `default` = ProjectionStyleSettings()
}

enum ProjectionMode: Equatable {
    case content
    case media
    case logo
    case blankTheme
    case blackout
}

extension Notification.Name {
    static let projectorNext = Notification.Name("projectorNext")
    static let projectorPrevious = Notification.Name("projectorPrevious")
    static let remoteNavigateNext = Notification.Name("remoteNavigateNext")
    static let remoteNavigatePrevious = Notification.Name("remoteNavigatePrevious")
    static let openSongEditor = Notification.Name("openSongEditor")
}

final class DisplayManager: ObservableObject {
    private struct LogoLibraryStore: Codable {
        var logoLibrary: [LogoAsset]
        var activeLogoID: UUID?
    }

    @Published var bibleProjectionSettings: BibleProjectionSettings {
        didSet {
            persistBibleProjectionSettings()
        }
    }
    @Published var projectionStyleSettings: ProjectionStyleSettings {
        didSet {
            persistProjectionStyleSettings()
        }
    }
    @Published var songModuleSettings: SongModuleSettings {
        didSet {
            persistSongModuleSettings()
        }
    }
    @Published var presentationModuleSettings: PresentationModuleSettings {
        didSet {
            persistPresentationModuleSettings()
        }
    }
    @Published private(set) var currentProjection: ProjectionPayload?
    @Published private(set) var currentMediaProjection: MediaProjection?
    @Published var projectionMode: ProjectionMode = .content
    @Published var logoShowsClock: Bool = false
    @Published var churchName: String = "Tu Iglesia" {
        didSet { persistChurchName() }
    }
    @Published private(set) var logoImage: NSImage?
    @Published private(set) var currentMediaImage: NSImage?
    @Published private(set) var logoLibrary: [LogoAsset] = []
    @Published var activeLogoID: LogoAsset.ID? {
        didSet {
            loadActiveLogo()
            persistLogoLibrary()
        }
    }

    private static let bibleProjectionSettingsKey = "DisplayManager.bibleProjectionSettings"
    private static let projectionStyleSettingsKey = "DisplayManager.projectionStyleSettings"
    private static let churchNameKey = "DisplayManager.churchName"
    private static let songModuleSettingsKey = "DisplayManager.songModuleSettings"
    private static let presentationModuleSettingsKey = "DisplayManager.presentationModuleSettings"
    private static let logoImageDataKey = "DisplayManager.logoImageData"
    private static let logoLibraryKey = "DisplayManager.logoLibrary"
    private static let activeLogoKey = "DisplayManager.activeLogoID"
    private let logosDirectory: URL
    private let logoMetadataURL: URL
    private var returnMediaProjection: MediaProjection?
    private var returnMediaImage: NSImage?
    private var logoThumbnailCache: [UUID: NSImage] = [:]

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.logosDirectory = appSupport.appendingPathComponent("SkyPresenterPro/logos", isDirectory: true)
        self.logoMetadataURL = logosDirectory.appendingPathComponent("logo-library.json")
        try? FileManager.default.createDirectory(at: logosDirectory, withIntermediateDirectories: true)
        self.bibleProjectionSettings = Self.loadBibleProjectionSettings()
        self.projectionStyleSettings = Self.loadProjectionStyleSettings()
        self.songModuleSettings = Self.loadSongModuleSettings()
        self.presentationModuleSettings = Self.loadPresentationModuleSettings()

        let savedName = UserDefaults.standard.string(forKey: Self.churchNameKey)
        if let savedName, !savedName.isEmpty {
            self.churchName = savedName
        }

        loadPersistedLogos()
        migrateLegacyLogoIfNeeded()
    }

    var currentText: String {
        guard let currentProjection else { return "" }
        if currentProjection.reference.isEmpty {
            return currentProjection.body
        }
        return "\(currentProjection.reference)\n\(currentProjection.body)"
    }

    var isProjectorActive: Bool {
        switch projectionMode {
        case .logo, .blankTheme, .blackout:
            return true
        case .content:
            return currentProjection != nil
        case .media:
            return currentMediaProjection != nil
        }
    }

    var contentBackgroundMediaImage: NSImage? {
        nil
    }

    func project(
        source: String,
        reference: String,
        body: String,
        backgroundOverride: ProjectionBackgroundOverride? = nil
    ) {
        projectionMode = .content
        currentMediaProjection = nil
        currentMediaImage = nil
        currentProjection = ProjectionPayload(
            source: source,
            reference: reference,
            body: body,
            backgroundOverride: backgroundOverride
        )
    }

    func projectMedia(source: String, title: String, subtitle: String, image: NSImage) {
        clearTemporaryMediaReturn()
        projectionMode = .media
        currentProjection = nil
        currentMediaProjection = MediaProjection(source: source, title: title, subtitle: subtitle)
        currentMediaImage = image
    }

    func projectDetectedBibleVerseFromMedia(_ match: BibleReferenceMatch) {
        guard let currentMediaProjection, let currentMediaImage else { return }
        returnMediaProjection = currentMediaProjection
        returnMediaImage = currentMediaImage
        projectionMode = .content
        currentProjection = ProjectionPayload(
            source: "bible-from-media:\(currentMediaProjection.source)",
            reference: match.reference,
            body: match.verseText
        )
    }

    var canRestorePresentationProjection: Bool {
        returnMediaProjection != nil && returnMediaImage != nil
    }

    @discardableResult
    func restorePresentationProjectionIfNeeded() -> Bool {
        guard let returnMediaProjection, let returnMediaImage else { return false }
        projectionMode = .media
        currentProjection = nil
        currentMediaProjection = returnMediaProjection
        currentMediaImage = returnMediaImage
        clearTemporaryMediaReturn()
        return true
    }

    func updateText(_ newText: String) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearProjection()
            return
        }

        let lines = trimmed.components(separatedBy: "\n")
        if lines.count > 1 {
            project(source: "manual", reference: lines[0], body: lines.dropFirst().joined(separator: "\n"))
        } else {
            project(source: "manual", reference: "", body: trimmed)
        }
    }

    func clearProjection() {
        projectionMode = .content
        currentProjection = nil
        currentMediaProjection = nil
        currentMediaImage = nil
        clearTemporaryMediaReturn()
    }

    func endProjection() {
        clearTemporaryMediaReturn()
        currentProjection = nil
        currentMediaProjection = nil
        currentMediaImage = nil
        showStartupScreen()
    }

    func showLogo() {
        logoShowsClock = false
        projectionMode = .logo
    }

    func showBlankTheme() {
        logoShowsClock = false
        projectionMode = .blankTheme
    }

    func showBlackout() {
        logoShowsClock = false
        projectionMode = .blackout
    }

    func showStartupScreen() {
        logoShowsClock = true
        projectionMode = .logo
    }

    func updateChurchName(_ value: String) {
        churchName = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Tu Iglesia" : value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func importLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }

        let imported = panel.urls.compactMap { copyLogo(from: $0) }
        guard !imported.isEmpty else { return }
        logoLibrary.append(contentsOf: imported)
        activeLogoID = imported.last?.id
        persistLogoLibrary()
    }

    func removeLogo() {
        guard let activeLogo else { return }
        try? FileManager.default.removeItem(at: logoURL(for: activeLogo))
        logoLibrary.removeAll { $0.id == activeLogo.id }
        activeLogoID = logoLibrary.last?.id
        if logoLibrary.isEmpty {
            logoImage = nil
        }
        persistLogoLibrary()
    }

    func resetProjectionStyleSettings() {
        projectionStyleSettings = .default
    }

    func applyBibleClassicProjectionPreset() {
        projectionStyleSettings.bibleTextWidthRatio = 0.90
        projectionStyleSettings.textHorizontalPadding = 16
        projectionStyleSettings.lineSpacing = 8
        bibleProjectionSettings.bodyScaleMultiplier = 1.10
        bibleProjectionSettings.referenceScaleMultiplier = 1.10
    }

    func applySongWideProjectionPreset() {
        projectionStyleSettings.songTextWidthRatio = 0.94
        projectionStyleSettings.textHorizontalPadding = 16
        projectionStyleSettings.lineSpacing = 8
    }

    private func persistBibleProjectionSettings() {
        guard let data = try? JSONEncoder().encode(bibleProjectionSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.bibleProjectionSettingsKey)
    }

    private func persistProjectionStyleSettings() {
        guard let data = try? JSONEncoder().encode(projectionStyleSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.projectionStyleSettingsKey)
    }

    private func persistSongModuleSettings() {
        guard let data = try? JSONEncoder().encode(songModuleSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.songModuleSettingsKey)
    }

    private func persistPresentationModuleSettings() {
        guard let data = try? JSONEncoder().encode(presentationModuleSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.presentationModuleSettingsKey)
    }

    private func persistChurchName() {
        UserDefaults.standard.set(churchName, forKey: Self.churchNameKey)
    }

    private static func loadBibleProjectionSettings() -> BibleProjectionSettings {
        guard
            let data = UserDefaults.standard.data(forKey: bibleProjectionSettingsKey),
            let settings = try? JSONDecoder().decode(BibleProjectionSettings.self, from: data)
        else {
            return BibleProjectionSettings()
        }
        return settings
    }

    private static func loadProjectionStyleSettings() -> ProjectionStyleSettings {
        guard
            let data = UserDefaults.standard.data(forKey: projectionStyleSettingsKey),
            let settings = try? JSONDecoder().decode(ProjectionStyleSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    private static func loadSongModuleSettings() -> SongModuleSettings {
        guard
            let data = UserDefaults.standard.data(forKey: songModuleSettingsKey),
            let settings = try? JSONDecoder().decode(SongModuleSettings.self, from: data)
        else {
            return SongModuleSettings()
        }
        return settings
    }

    private static func loadPresentationModuleSettings() -> PresentationModuleSettings {
        guard
            let data = UserDefaults.standard.data(forKey: presentationModuleSettingsKey),
            let settings = try? JSONDecoder().decode(PresentationModuleSettings.self, from: data)
        else {
            return PresentationModuleSettings()
        }
        return settings
    }

    private func clearTemporaryMediaReturn() {
        returnMediaProjection = nil
        returnMediaImage = nil
    }

    private var activeLogo: LogoAsset? {
        logoLibrary.first { $0.id == activeLogoID } ?? logoLibrary.first
    }

    private func copyLogo(from url: URL) -> LogoAsset? {
        let id = UUID()
        let ext = url.pathExtension.isEmpty ? "png" : url.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = logosDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return LogoAsset(id: id, title: url.deletingPathExtension().lastPathComponent, fileName: fileName)
        } catch {
            return nil
        }
    }

    private func logoURL(for asset: LogoAsset) -> URL {
        logosDirectory.appendingPathComponent(asset.fileName)
    }

    private func loadPersistedLogos() {
        if let data = try? Data(contentsOf: logoMetadataURL),
           let decoded = try? JSONDecoder().decode(LogoLibraryStore.self, from: data) {
            logoLibrary = decoded.logoLibrary.filter { FileManager.default.fileExists(atPath: logoURL(for: $0).path) }
            activeLogoID = decoded.activeLogoID ?? logoLibrary.first?.id
            loadActiveLogo()
            return
        }

        if let data = UserDefaults.standard.data(forKey: Self.logoLibraryKey),
           let decoded = try? JSONDecoder().decode([LogoAsset].self, from: data) {
            logoLibrary = decoded.filter { FileManager.default.fileExists(atPath: logoURL(for: $0).path) }
        }
        if let active = UserDefaults.standard.string(forKey: Self.activeLogoKey),
           let uuid = UUID(uuidString: active) {
            activeLogoID = uuid
        } else {
            activeLogoID = logoLibrary.first?.id
        }
        persistLogoLibrary()
        loadActiveLogo()
    }

    private func persistLogoLibrary() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(LogoLibraryStore(logoLibrary: logoLibrary, activeLogoID: activeLogoID)) else { return }
        try? data.write(to: logoMetadataURL, options: .atomic)
        UserDefaults.standard.removeObject(forKey: Self.logoLibraryKey)
        UserDefaults.standard.set(activeLogoID?.uuidString, forKey: Self.activeLogoKey)
    }

    private func loadActiveLogo() {
        guard let asset = activeLogo else {
            logoImage = nil
            return
        }
        logoImage = NSImage(contentsOf: logoURL(for: asset))
        if let logoImage {
            logoThumbnailCache[asset.id] = logoImage
        }
    }

    func logoThumbnail(for asset: LogoAsset) -> NSImage? {
        if let cached = logoThumbnailCache[asset.id] {
            return cached
        }
        guard let image = NSImage(contentsOf: logoURL(for: asset)) else { return nil }
        logoThumbnailCache[asset.id] = image
        return image
    }

    private func migrateLegacyLogoIfNeeded() {
        guard logoLibrary.isEmpty,
              let legacyData = UserDefaults.standard.data(forKey: Self.logoImageDataKey) else { return }
        let id = UUID()
        let fileName = "\(id.uuidString).png"
        let destination = logosDirectory.appendingPathComponent(fileName)
        do {
            try legacyData.write(to: destination)
            let migrated = LogoAsset(id: id, title: "Logo 1", fileName: fileName)
            logoLibrary = [migrated]
            activeLogoID = migrated.id
            persistLogoLibrary()
            UserDefaults.standard.removeObject(forKey: Self.logoImageDataKey)
        } catch {
            logoImage = NSImage(data: legacyData)
        }
    }
}
