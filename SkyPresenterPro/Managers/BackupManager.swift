import AppKit
import CryptoKit
import Combine
import Foundation

struct BackupManifest: Codable {
    let appVersion: String
    let publicLaunchTarget: String
    let createdAt: Date
    let reason: String
    let bundleIdentifier: String
    let checksumSHA256: String
    let includesApplicationSupport: Bool
    let includesPreferences: Bool
}

struct BackupImportScanSummary: Identifiable {
    let id = UUID()
    let packageURL: URL
    let songsDetected: Int
    let imageAssetsDetected: Int
    let videoAssetsDetected: Int
}

struct BackupImportResult {
    let songs: SongImportResult
    let importedAssetsCount: Int
}

final class BackupManager: ObservableObject {
    @Published private(set) var latestBackupURL: URL?
    @Published private(set) var lastBackupErrorMessage: String?
    @Published private(set) var lastScanSummary: BackupImportScanSummary?
    @Published private(set) var preferredBackupDirectory: URL
    @Published private(set) var selectedRestorePackageURL: URL?

    private let fileManager = FileManager.default
    private let appSupportRoot: URL
    private let workspaceRoot: URL
    private let backupsRoot: URL
    private let bundleIdentifier: String
    private static let preferredBackupDirectoryKey = "BackupManager.preferredBackupDirectory"

    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.appSupportRoot = appSupport
        self.workspaceRoot = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        self.backupsRoot = workspaceRoot.appendingPathComponent("Backups", isDirectory: true)
        self.bundleIdentifier = Bundle.main.bundleIdentifier ?? "SkyPresenterPro"
        if let storedPath = UserDefaults.standard.string(forKey: Self.preferredBackupDirectoryKey) {
            self.preferredBackupDirectory = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            self.preferredBackupDirectory = self.backupsRoot
        }
        try? fileManager.createDirectory(at: backupsRoot, withIntermediateDirectories: true)
        self.latestBackupURL = Self.resolveLatestBackup(in: backupsRoot)
    }

    func performAutoSnapshot() {
        do {
            _ = try createAtomicBackup(reason: "auto-snapshot")
            rotateAutomaticBackups(keeping: 5)
        } catch {
            // Snapshot preventivo: nunca debe interrumpir el cierre de la app.
        }
    }

    @discardableResult
    func createManualBackup() -> URL? {
        do {
            let url = try createAtomicBackup(reason: "manual-backup", destinationDirectory: preferredBackupDirectory)
            lastBackupErrorMessage = nil
            return url
        } catch {
            lastBackupErrorMessage = "No se pudo crear el respaldo manual."
            return nil
        }
    }

    @discardableResult
    func createAtomicBackup(reason: String, destinationDirectory: URL? = nil) throws -> URL {
        let outputDirectory = destinationDirectory ?? backupsRoot
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let timestamp = Self.timestampFormatter.string(from: .now)
        let packageURL = outputDirectory.appendingPathComponent("SkyPresenterPro-\(timestamp)-\(reason).worshipzip", isDirectory: true)

        if fileManager.fileExists(atPath: packageURL.path) {
            try fileManager.removeItem(at: packageURL)
        }

        try fileManager.createDirectory(at: packageURL, withIntermediateDirectories: true)

        let databaseURL = packageURL.appendingPathComponent("Database", isDirectory: true)
        let configurationURL = packageURL.appendingPathComponent("Configuration", isDirectory: true)
        let assetsURL = packageURL.appendingPathComponent("Assets", isDirectory: true)

        try fileManager.createDirectory(at: databaseURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: configurationURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: workspaceRoot.path) {
            try copyContents(of: workspaceRoot, into: assetsURL)
        }

        try writePreferencesSnapshot(to: configurationURL.appendingPathComponent("preferences.json"))

        let checksum = try computeDirectoryChecksum(for: packageURL)
        let manifest = BackupManifest(
            appVersion: SkyPresenterVersion.internalRelease,
            publicLaunchTarget: SkyPresenterVersion.publicLaunchTarget,
            createdAt: .now,
            reason: reason,
            bundleIdentifier: bundleIdentifier,
            checksumSHA256: checksum,
            includesApplicationSupport: fileManager.fileExists(atPath: workspaceRoot.path),
            includesPreferences: true
        )

        let manifestData = try JSONEncoder.pretty.encode(manifest)
        try manifestData.write(to: packageURL.appendingPathComponent("manifest.json"), options: .atomic)

        latestBackupURL = packageURL
        lastBackupErrorMessage = nil
        return packageURL
    }

    func rotateAutomaticBackups(keeping count: Int) {
        guard count > 0 else { return }
        let urls = (try? fileManager.contentsOfDirectory(
            at: backupsRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        let automatic = urls
            .filter { $0.lastPathComponent.contains("auto-snapshot") }
            .sorted {
                let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhs > rhs
            }

        guard automatic.count > count else { return }
        for stale in automatic.dropFirst(count) {
            try? fileManager.removeItem(at: stale)
        }
        latestBackupURL = Self.resolveLatestBackup(in: backupsRoot)
    }

    func openBackupsFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([preferredBackupDirectory])
    }

    @discardableResult
    func selectBackupDestinationDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Seleccionar carpeta de respaldo"
        panel.prompt = "Usar carpeta"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        preferredBackupDirectory = url
        UserDefaults.standard.set(url.path, forKey: Self.preferredBackupDirectoryKey)
        latestBackupURL = Self.resolveLatestBackup(in: url)
        return url
    }

    func selectBackupPackage() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Seleccionar respaldo SkyPresenter"
        panel.prompt = "Abrir"

        guard panel.runModal() == .OK else { return nil }
        selectedRestorePackageURL = panel.url
        return panel.url
    }

    func scanBackup(at packageURL: URL) throws -> BackupImportScanSummary {
        let songs = try loadSongsFromBackup(packageURL: packageURL)
        let themeMetadata = try loadThemeBackupMetadata(packageURL: packageURL)

        let summary = BackupImportScanSummary(
            packageURL: packageURL,
            songsDetected: songs.count,
            imageAssetsDetected: themeMetadata.imageLibrary.count,
            videoAssetsDetected: themeMetadata.videoLibrary.count
        )
        lastScanSummary = summary
        lastBackupErrorMessage = nil
        return summary
    }

    func importBackup(
        from packageURL: URL,
        policy: SongImportConflictPolicy,
        songManager: SongManager,
        themeManager: ThemeManager
    ) throws -> BackupImportResult {
        let importedSongs = try loadSongsFromBackup(packageURL: packageURL)
        let songResult = songManager.importSongs(importedSongs, policy: policy)

        let themeMetadata = try loadThemeBackupMetadata(packageURL: packageURL)
        let importedAssetsCount = try themeManager.importBackupAssets(
            from: packageURL.appendingPathComponent("Assets/themes", isDirectory: true),
            imageLibrary: themeMetadata.imageLibrary,
            videoLibrary: themeMetadata.videoLibrary,
            activeImageID: themeMetadata.activeImageID,
            activeVideoID: themeMetadata.activeVideoID
        )

        lastBackupErrorMessage = nil
        return BackupImportResult(songs: songResult, importedAssetsCount: importedAssetsCount)
    }

    var backupsFolderURL: URL {
        preferredBackupDirectory
    }

    var latestBackupDisplayName: String {
        latestBackupURL?.lastPathComponent ?? "Sin respaldos aún"
    }

    var latestBackupTimestampLabel: String {
        guard let latestBackupURL,
              let date = (try? latestBackupURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
        else {
            return "No disponible"
        }
        return Self.displayFormatter.string(from: date)
    }

    private func writePreferencesSnapshot(to url: URL) throws {
        let domain = UserDefaults.standard.persistentDomain(forName: bundleIdentifier) ?? [:]
        let jsonSafeDomain = domain.compactMapValues { makeJSONSafe($0) }
        let data = try JSONSerialization.data(withJSONObject: jsonSafeDomain, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    private func copyContents(of sourceDirectory: URL, into destinationDirectory: URL) throws {
        let urls = try fileManager.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for sourceURL in urls {
            let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent, isDirectory: true)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private func computeDirectoryChecksum(for directoryURL: URL) throws -> String {
        let fileURLs = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])?
            .compactMap { $0 as? URL }
            .filter {
                let values = try? $0.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true
            }
            .sorted { $0.path < $1.path } ?? []

        var hasher = SHA256()
        for fileURL in fileURLs where fileURL.lastPathComponent != "manifest.json" {
            hasher.update(data: Data(fileURL.path.utf8))
            let data = try Data(contentsOf: fileURL)
            hasher.update(data: data)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static func resolveLatestBackup(in directory: URL) -> URL? {
        let fileManager = FileManager.default
        let urls = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return urls.max {
            let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhs < rhs
        }
    }

    private func loadSongsFromBackup(packageURL: URL) throws -> [SongItem] {
        let songsJSONURL = packageURL.appendingPathComponent("Assets/songs.json")

        if let database = WorshipSongDatabaseStore.load(from: songsJSONURL) {
            return database.songs.map { $0.toSongItem() }
        }

        if let data = try? Data(contentsOf: songsJSONURL),
           let decoded = try? JSONDecoder().decode([SongItem].self, from: data) {
            return decoded
        }

        throw NSError(domain: "BackupManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "El respaldo no contiene canciones importables."])
    }

    private func loadThemeBackupMetadata(packageURL: URL) throws -> ThemeBackupMetadata {
        let themeAssetsURL = packageURL.appendingPathComponent("Assets/themes/theme-assets.json")
        if let data = try? Data(contentsOf: themeAssetsURL),
           let decoded = try? JSONDecoder().decode(ThemeBackupMetadata.self, from: data) {
            return decoded
        }

        let preferencesURL = packageURL.appendingPathComponent("Configuration/preferences.json")
        guard let data = try? Data(contentsOf: preferencesURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return ThemeBackupMetadata()
        }

        return ThemeBackupMetadata(
            imageLibrary: decodeThemeAssets(forKey: "ThemeManager.imageLibrary", from: object),
            videoLibrary: decodeThemeAssets(forKey: "ThemeManager.videoLibrary", from: object),
            activeImageID: decodeUUID(forKey: "ThemeManager.activeImageID", from: object),
            activeVideoID: decodeUUID(forKey: "ThemeManager.activeVideoID", from: object)
        )
    }

    private func decodeThemeAssets(forKey key: String, from dictionary: [String: Any]) -> [ThemeAsset] {
        guard let base64 = dictionary[key] as? String,
              let data = Data(base64Encoded: base64),
              let decoded = try? JSONDecoder().decode([ThemeAsset].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private func decodeUUID(forKey key: String, from dictionary: [String: Any]) -> UUID? {
        guard let rawValue = dictionary[key] as? String else { return nil }
        return UUID(uuidString: rawValue)
    }

    private func makeJSONSafe(_ value: Any) -> Any? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number
        case let bool as Bool:
            return bool
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let data as Data:
            return data.base64EncodedString()
        case let url as URL:
            return url.path
        case let array as [Any]:
            return array.compactMap { makeJSONSafe($0) }
        case let dictionary as [String: Any]:
            return dictionary.compactMapValues { makeJSONSafe($0) }
        default:
            return String(describing: value)
        }
    }
}

private struct ThemeBackupMetadata {
    var imageLibrary: [ThemeAsset] = []
    var videoLibrary: [ThemeAsset] = []
    var activeImageID: UUID?
    var activeVideoID: UUID?
}

extension ThemeBackupMetadata: Codable {}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
