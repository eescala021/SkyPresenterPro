import AppKit
import Combine
import Foundation
import SQLite3
import UniformTypeIdentifiers

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Data Models

struct SongSection: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var lines: [String]
    var backgroundAssetID: UUID?
    var backgroundAssetKind: ThemeAsset.AssetKind?

    init(
        id: UUID = UUID(),
        title: String,
        lines: [String],
        backgroundAssetID: UUID? = nil,
        backgroundAssetKind: ThemeAsset.AssetKind? = nil
    ) {
        self.id = id
        self.title = title
        self.lines = lines
        self.backgroundAssetID = backgroundAssetID
        self.backgroundAssetKind = backgroundAssetKind
    }

    var label: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var bodyText: String {
        publicLines.joined(separator: "\n")
    }

    var presenterNotes: String {
        lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("//") }
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var publicLines: [String] {
        lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") }
    }

    func displayTitle(index: Int) -> String {
        label.isEmpty ? "Diapositiva \(index + 1)" : label
    }
}

struct SongItem: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var author: String
    var key: String
    var bpm: Int?
    var sections: [SongSection]

    init(id: UUID = UUID(), title: String, author: String = "", key: String, bpm: Int? = nil, sections: [SongSection]) {
        self.id = id
        self.title = title
        self.author = author
        self.key = key
        self.bpm = bpm
        self.sections = sections
    }
}

struct SongPresentationSlide: Identifiable, Hashable {
    let id: String
    let source: String
    let title: String
    let reference: String
    let body: String
    let presenterNotes: String
    let backgroundAssetID: UUID?
    let backgroundAssetKind: ThemeAsset.AssetKind?
}

enum SongImportConflictPolicy: String, CaseIterable, Identifiable {
    case skip = "Omitir"
    case overwrite = "Sobrescribir"
    case duplicate = "Duplicar"

    var id: String { rawValue }
}

struct SongImportResult {
    var importedCount: Int = 0
    var overwrittenCount: Int = 0
    var skippedCount: Int = 0
    var duplicatedCount: Int = 0
}

extension SongItem {
    var presentationSlides: [SongPresentationSlide] {
        var slides: [SongPresentationSlide] = [
            SongPresentationSlide(
                id: "song:\(id.uuidString):intro",
                source: "song:\(id.uuidString):intro",
                title: "Portada",
                reference: "",
                body: [title, author]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                presenterNotes: "",
                backgroundAssetID: nil,
                backgroundAssetKind: nil
            )
        ]

        slides.append(
            contentsOf: sections.enumerated().map { index, section in
                SongPresentationSlide(
                    id: "song:\(id.uuidString):\(section.id.uuidString)",
                    source: "song:\(id.uuidString):\(section.id.uuidString)",
                    title: section.displayTitle(index: index),
                    reference: "",
                    body: section.bodyText,
                    presenterNotes: section.presenterNotes,
                    backgroundAssetID: section.backgroundAssetID,
                    backgroundAssetKind: section.backgroundAssetKind
                )
            }
        )

        slides.append(
            SongPresentationSlide(
                id: "song:\(id.uuidString):outro",
                source: "song:\(id.uuidString):outro",
                title: "Final en blanco",
                reference: "",
                body: " ",
                presenterNotes: "",
                backgroundAssetID: nil,
                backgroundAssetKind: nil
            )
        )

        return slides
    }
}

// MARK: - SongManager

final class SongManager: ObservableObject {
    @Published var songs: [SongItem] = []
    @Published var serviceQueue: [SongItem.ID] = []
    @Published var playedSongIDs: Set<SongItem.ID> = []
    @Published var lastImportError: String?

    private static let storageKey = "SongManager.songs"
    private let songsFileURL: URL
    private let songsDatabaseURL: URL
    private let sectionBackgroundsURL: URL
    private let sqliteStore: SongSQLiteStore?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.songsFileURL = directory.appendingPathComponent("songs.json")
        self.songsDatabaseURL = directory.appendingPathComponent("songs.sqlite")
        self.sectionBackgroundsURL = directory.appendingPathComponent("song-section-backgrounds.json")
        self.sqliteStore = SongSQLiteStore(databaseURL: songsDatabaseURL)
        loadSongs()
    }

    // MARK: Persistence

    private func loadSongs() {
        if let sqliteStore,
           let storedSongs = try? sqliteStore.fetchAllSongs(),
           !storedSongs.isEmpty {
            songs = storedSongs
            serviceQueue = (try? sqliteStore.fetchServiceQueue()) ?? []
            playedSongIDs = Set((try? sqliteStore.fetchPlayedSongIDs()) ?? [])
        } else if let db = WorshipSongDatabaseStore.load(from: songsFileURL), !db.songs.isEmpty {
            songs = db.songs.map { $0.toSongItem() }
            persist()
        } else if let data = try? Data(contentsOf: songsFileURL),
                  let decoded = try? JSONDecoder().decode([SongItem].self, from: data),
                  !decoded.isEmpty {
            songs = decoded
            persist()
        } else if let data = UserDefaults.standard.data(forKey: Self.storageKey),
                  let decoded = try? JSONDecoder().decode([SongItem].self, from: data),
                  !decoded.isEmpty {
            songs = decoded
            persist()
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        } else {
            loadDefaults()
        }
        applyPersistedSectionBackgrounds()
    }

    private func persist() {
        if let sqliteStore {
            try? sqliteStore.replaceSongs(songs)
            try? sqliteStore.replaceServiceQueue(serviceQueue)
            try? sqliteStore.replacePlayedSongIDs(Array(playedSongIDs))
        }
        persistSectionBackgrounds()
    }

    private func persistSectionBackgrounds() {
        let overrides = songs
            .flatMap(\.sections)
            .reduce(into: [String: SongSectionBackgroundOverride]()) { partialResult, section in
                guard let backgroundAssetID = section.backgroundAssetID,
                      let backgroundAssetKind = section.backgroundAssetKind else { return }
                partialResult[section.id.uuidString] = SongSectionBackgroundOverride(
                    assetID: backgroundAssetID,
                    assetKind: backgroundAssetKind
                )
            }

        guard let data = try? JSONEncoder().encode(overrides) else { return }
        try? data.write(to: sectionBackgroundsURL, options: [.atomic])
    }

    private func applyPersistedSectionBackgrounds() {
        guard let data = try? Data(contentsOf: sectionBackgroundsURL),
              let overrides = try? JSONDecoder().decode([String: SongSectionBackgroundOverride].self, from: data) else { return }

        songs = songs.map { song in
            var updatedSong = song
            updatedSong.sections = song.sections.map { section in
                guard let override = overrides[section.id.uuidString] else { return section }
                var updatedSection = section
                updatedSection.backgroundAssetID = override.assetID
                updatedSection.backgroundAssetKind = override.assetKind
                return updatedSection
            }
            return updatedSong
        }
    }

    private func persistLegacyJSONSnapshot() {
        let records = songs.map { WorshipSongRecord(song: $0) }
        let database = WorshipSongDatabase(schemaVersion: 1, updatedAt: .now, songs: records)
        WorshipSongDatabaseStore.save(database, to: songsFileURL)
    }

    // MARK: CRUD

    func addSong(_ song: SongItem) {
        songs.append(song)
        persist()
    }

    func updateSong(_ song: SongItem) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return }
        songs[index] = song
        persist()
    }

    func removeSong(id: SongItem.ID) {
        songs.removeAll { $0.id == id }
        serviceQueue.removeAll { $0 == id }
        playedSongIDs.remove(id)
        persist()
    }

    func createEmptySong() -> SongItem {
        let song = SongItem(
            title: "Nueva Alabanza",
            key: "",
            sections: [SongSection(title: "", lines: [""])]
        )
        addSong(song)
        return song
    }

    func importSong() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .plainText,
            .text,
            .json,
            .xml,
            UTType(filenameExtension: "db"),
            UTType(filenameExtension: "sqlite"),
            UTType(filenameExtension: "json")
        ].compactMap { $0 }
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "Importar alabanzas"
        panel.message = "Puedes seleccionar una o varias alabanzas en TXT, JSON, XML o bases compatibles .db/.sqlite."

        guard panel.runModal() == .OK else { return }

        do {
            let importedSongs = try panel.urls.flatMap(importSongs(from:))
            guard !importedSongs.isEmpty else {
                lastImportError = "No se encontraron alabanzas válidas en los archivos seleccionados."
                return
            }
            _ = importSongs(importedSongs, policy: .duplicate)
            lastImportError = nil
        } catch {
            lastImportError = "No se pudieron importar las alabanzas seleccionadas."
        }
    }

    func searchSongs(matching query: String) -> [SongItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }

        if let sqliteStore,
           let results = try? sqliteStore.searchSongs(query: normalizedQuery),
           !results.isEmpty {
            return results
        }

        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(normalizedQuery) ||
            $0.author.localizedCaseInsensitiveContains(normalizedQuery) ||
            $0.sections.contains { $0.lines.joined(separator: " ").localizedCaseInsensitiveContains(normalizedQuery) }
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func enqueueSong(_ id: SongItem.ID) {
        guard songs.contains(where: { $0.id == id }), !serviceQueue.contains(id) else { return }
        serviceQueue.append(id)
        persist()
    }

    func dequeueSong(_ id: SongItem.ID) {
        serviceQueue.removeAll { $0 == id }
        persist()
    }

    func clearQueue() {
        serviceQueue.removeAll()
        persist()
    }

    func moveQueueItem(from source: Int, to destination: Int) {
        guard serviceQueue.indices.contains(source), source != destination else { return }
        var queue = serviceQueue
        let item = queue.remove(at: source)
        let target = min(max(destination, 0), queue.count)
        queue.insert(item, at: target)
        serviceQueue = queue
        persist()
    }

    func markSongPlayed(_ id: SongItem.ID, played: Bool = true) {
        if played {
            playedSongIDs.insert(id)
        } else {
            playedSongIDs.remove(id)
        }
        persist()
    }

    func clearPlayedMarks() {
        playedSongIDs.removeAll()
        persist()
    }

    var queuedSongs: [SongItem] {
        serviceQueue.compactMap { id in songs.first(where: { $0.id == id }) }
    }

    @discardableResult
    func importSongs(_ importedSongs: [SongItem], policy: SongImportConflictPolicy) -> SongImportResult {
        var result = SongImportResult()

        for incomingSong in importedSongs {
            if let existingIndex = songs.firstIndex(where: { songIdentityKey(for: $0) == songIdentityKey(for: incomingSong) }) {
                switch policy {
                case .skip:
                    result.skippedCount += 1
                case .overwrite:
                    let existingID = songs[existingIndex].id
                    let updatedSong = SongItem(
                        id: existingID,
                        title: incomingSong.title,
                        author: incomingSong.author,
                        key: incomingSong.key,
                        bpm: incomingSong.bpm,
                        sections: incomingSong.sections
                    )
                    songs[existingIndex] = updatedSong
                    result.overwrittenCount += 1
                case .duplicate:
                    let duplicatedSong = makeDuplicateSong(from: incomingSong)
                    songs.append(duplicatedSong)
                    result.duplicatedCount += 1
                    result.importedCount += 1
                }
            } else {
                songs.append(incomingSong)
                result.importedCount += 1
            }
        }

        persist()
        return result
    }

    private func loadDefaults() {
        songs = [
            SongItem(
                title: "Digno y Santo",
                author: "",
                key: "G",
                bpm: 72,
                sections: [
                    SongSection(title: "Verso 1", lines: ["Digno y santo, el Cordero inmolado", "nuevo canto levantaremos hoy"]),
                    SongSection(title: "Coro", lines: ["Santo, santo, santo", "Dios Todopoderoso", "el que fue, el que es y vendrá"])
                ]
            ),
            SongItem(
                title: "Cuán Grande Es Dios",
                author: "",
                key: "A",
                bpm: 76,
                sections: [
                    SongSection(title: "Verso 1", lines: ["El esplendor de un Rey", "vestido en majestad"]),
                    SongSection(title: "Coro", lines: ["Cuán grande es Dios", "cántale cuán grande es Dios"])
                ]
            )
        ]
        persist()
    }

    private func importSongs(from url: URL) throws -> [SongItem] {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "json":
            return try importSongsFromJSON(url: url)
        case "xml":
            return importSongsFromXML(url: url)
        case "db", "sqlite":
            return try importSongsFromSQLite(url: url)
        default:
            let content = try String(contentsOf: url, encoding: .utf8)
            return [SongParser.parse(text: content, fallbackTitle: url.deletingPathExtension().lastPathComponent)]
        }
    }

    private func importSongsFromJSON(url: URL) throws -> [SongItem] {
        let data = try Data(contentsOf: url)

        if let decoded = try? JSONDecoder().decode([SongItem].self, from: data), !decoded.isEmpty {
            return decoded
        }

        if let decoded = try? JSONDecoder().decode(SongItem.self, from: data) {
            return [decoded]
        }

        if let decoded = try? JSONDecoder().decode(WorshipSongDatabase.self, from: data), !decoded.songs.isEmpty {
            return decoded.songs.map { $0.toSongItem() }
        }

        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let mapped = array.compactMap(mapLooseSongDictionary)
            if !mapped.isEmpty { return mapped }
        }

        if let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let mapped = mapLooseSongDictionary(dictionary) {
            return [mapped]
        }

        throw NSError(domain: "SongManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Formato JSON de alabanzas no compatible."])
    }

    private func importSongsFromSQLite(url: URL) throws -> [SongItem] {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            sqlite3_close(db)
            throw NSError(domain: "SongManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "No se pudo abrir la base de datos de alabanzas."])
        }
        defer { sqlite3_close(db) }

        let tableNames = sqliteRows(db: db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;").compactMap {
            $0["name"] as? String
        }

        let preferredTables = tableNames.filter { name in
            let lower = name.lowercased()
            return lower.contains("song") || lower.contains("lyric") || lower.contains("hymn")
        }
        let orderedTables = preferredTables.isEmpty ? tableNames : preferredTables

        var imported: [SongItem] = []
        for table in orderedTables {
            let escapedTable = table.replacingOccurrences(of: "\"", with: "\"\"")
            let rows = sqliteRows(db: db, sql: "SELECT * FROM \"\(escapedTable)\";")
            for row in rows {
                if let mapped = mapSQLiteSongRow(row) {
                    imported.append(mapped)
                }
            }
            if !imported.isEmpty {
                break
            }
        }

        guard !imported.isEmpty else {
            throw NSError(domain: "SongManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "No se encontró una tabla compatible de alabanzas en la base seleccionada."])
        }

        return imported
    }

    private func importSongsFromXML(url: URL) -> [SongItem] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }

        let songBlocks = matches(for: "<song\\b[^>]*>(.*?)</song>", in: content)
        if !songBlocks.isEmpty {
            let mapped = songBlocks.compactMap(parseXMLSongBlock)
            if !mapped.isEmpty { return mapped }
        }

        if let mapped = parseXMLSongBlock(content) {
            return [mapped]
        }

        return []
    }

    private func parseXMLSongBlock(_ block: String) -> SongItem? {
        let title = firstMatch(for: "<title[^>]*>(.*?)</title>", in: block)?
            .decodingHTMLEntities()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let author = firstMatch(for: "<author[^>]*>(.*?)</author>", in: block)?
            .decodingHTMLEntities()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? firstMatch(for: "<authors[^>]*>(.*?)</authors>", in: block)?
            .decodingHTMLEntities()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        let verseBlocks = matches(for: "<verse\\b[^>]*>(.*?)</verse>", in: block)
        let lyricBlocks = verseBlocks.isEmpty ? matches(for: "<lines?[^>]*>(.*?)</lines?>", in: block) : verseBlocks
        let sections: [SongSection] = lyricBlocks.enumerated().compactMap { element in
            let (index, raw) = element
            let clean = raw
                .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .decodingHTMLEntities()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = clean
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !lines.isEmpty else { return nil }
            return SongSection(title: "Diapositiva \(index + 1)", lines: lines)
        }

        let bodyText = firstMatch(for: "<lyrics[^>]*>(.*?)</lyrics>", in: block)?
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .decodingHTMLEntities()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let fallbackSections: [SongSection]
        if let bodyText, !bodyText.isEmpty {
            fallbackSections = SongParser.parse(text: bodyText, fallbackTitle: title ?? "Alabanza importada").sections
        } else {
            fallbackSections = []
        }

        let resolvedSections = sections.isEmpty ? fallbackSections : sections
        guard let resolvedTitle = title, !resolvedTitle.isEmpty, !resolvedSections.isEmpty else { return nil }
        return SongItem(title: resolvedTitle, author: author, key: "", sections: resolvedSections)
    }

    private func mapLooseSongDictionary(_ payload: [String: Any]) -> SongItem? {
        let lookup = Dictionary(uniqueKeysWithValues: payload.map { ($0.key.lowercased(), $0.value) })
        let title = (lookup["title"] as? String ?? lookup["titulo"] as? String ?? lookup["name"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (lookup["author"] as? String ?? lookup["autor"] as? String ?? lookup["artist"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (lookup["key"] as? String ?? lookup["tono"] as? String ?? lookup["originalkey"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let bpm = lookup["bpm"] as? Int

        if let sectionsPayload = lookup["sections"] as? [[String: Any]] {
            let sections = sectionsPayload.compactMap { sectionPayload -> SongSection? in
                let sectionTitle = (sectionPayload["title"] as? String ?? sectionPayload["label"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let lines = sectionPayload["lines"] as? [String], !lines.isEmpty {
                    return SongSection(title: sectionTitle, lines: lines)
                }
                if let body = sectionPayload["text"] as? String ?? sectionPayload["body"] as? String {
                    return SongSection(title: sectionTitle, lines: body.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                }
                return nil
            }
            guard !title.isEmpty, !sections.isEmpty else { return nil }
            return SongItem(title: title, author: author, key: key, bpm: bpm, sections: sections)
        }

        let body = (lookup["lyrics"] as? String ??
                    lookup["letra"] as? String ??
                    lookup["text"] as? String ??
                    lookup["content"] as? String ??
                    lookup["words"] as? String ??
                    "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !body.isEmpty else { return nil }

        var song = SongParser.parse(text: body, fallbackTitle: title)
        song.author = author
        song.key = key
        song.bpm = bpm
        return song
    }

    private func mapSQLiteSongRow(_ row: [String: Any]) -> SongItem? {
        let normalized = Dictionary(uniqueKeysWithValues: row.map { ($0.key.lowercased(), $0.value) })
        return mapLooseSongDictionary(normalized)
    }

    private func sqliteRows(db: OpaquePointer, sql: String) -> [[String: Any]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            sqlite3_finalize(statement)
            return []
        }
        defer { sqlite3_finalize(statement) }

        var rows: [[String: Any]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            for column in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, column))
                switch sqlite3_column_type(statement, column) {
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(statement, column))
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int64(statement, column))
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(statement, column)
                default:
                    continue
                }
            }
            rows.append(row)
        }
        return rows
    }

    private func matches(for pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let capture = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[capture])
        }
    }

    private func firstMatch(for pattern: String, in text: String) -> String? {
        matches(for: pattern, in: text).first
    }

    private func songIdentityKey(for song: SongItem) -> String {
        [
            song.title.normalizedSearchToken,
            song.author.normalizedSearchToken
        ]
        .joined(separator: "|")
    }

    private func makeDuplicateSong(from song: SongItem) -> SongItem {
        let baseTitle = song.title.trimmingCharacters(in: .whitespacesAndNewlines)
        var attempt = 1
        var candidateTitle = "\(baseTitle) (Copia)"

        while songs.contains(where: { $0.title.compare(candidateTitle, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
            attempt += 1
            candidateTitle = "\(baseTitle) (Copia \(attempt))"
        }

        return SongItem(
            title: candidateTitle,
            author: song.author,
            key: song.key,
            bpm: song.bpm,
            sections: song.sections
        )
    }
}

// MARK: - SongParser

private enum SongParser {
    static func parse(text: String, fallbackTitle: String) -> SongItem {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let firstBlockLines = blocks.first?
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        let rawTitle = firstBlockLines.first ?? ""
        let title = rawTitle.isEmpty ? fallbackTitle : rawTitle

        // Detect author: second line of first block if it doesn't look like a section header or lyric
        var author = ""
        if firstBlockLines.count >= 2 {
            let secondLine = firstBlockLines[1]
            let lower = secondLine.lowercased()
            let isSectionHeader = lower.contains("coro") || lower.contains("verso") || lower.contains("puente")
            if !isSectionHeader && secondLine.count < 60 {
                author = secondLine
            }
        }

        var parsedSections: [SongSection] = []
        var pendingLabel = ""

        for block in blocks.dropFirst() {
            let lines = block
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard !lines.isEmpty else { continue }

            if let first = lines.first, isSectionHeader(first) {
                pendingLabel = first
                let bodyLines = Array(lines.dropFirst())
                if !bodyLines.isEmpty {
                    parsedSections.append(
                        SongSection(
                            title: pendingLabel,
                            lines: bodyLines
                        )
                    )
                    pendingLabel = ""
                }
            } else {
                parsedSections.append(
                    SongSection(
                        title: pendingLabel,
                        lines: lines
                    )
                )
                pendingLabel = ""
            }
        }

        if parsedSections.isEmpty {
            let lyricLines = normalized
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .dropFirst(author.isEmpty ? 1 : 2)

            var currentLines: [String] = []

            for line in lyricLines {
                if isSectionHeader(line) {
                    if !currentLines.isEmpty {
                        parsedSections.append(
                            SongSection(
                                title: pendingLabel,
                                lines: currentLines
                            )
                        )
                        currentLines = []
                    }
                    pendingLabel = line
                    continue
                }

                currentLines.append(line)
            }

            if !currentLines.isEmpty {
                parsedSections.append(
                    SongSection(
                        title: pendingLabel,
                        lines: currentLines
                    )
                )
            }
        }

        let sections = parsedSections.isEmpty ? [SongSection(title: "", lines: [""])] : parsedSections

        return SongItem(title: title, author: author, key: "", sections: sections)
    }

    private static func isSectionHeader(_ text: String) -> Bool {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.contains("coro") || lower.contains("verso") || lower.contains("puente")
    }
}

// MARK: - SongViewState

@MainActor
final class SongViewState: ObservableObject {
    enum InteractionContext: String {
        case browsing = "Explorando"
        case searching = "Buscando"
        case editingMetadata = "Editando datos"
        case editingLyrics = "Editando letra"
        case editingSlideLabel = "Editando rotulo"
        case navigatingSlides = "Navegando"
    }

    @Published var selectedSongID: SongItem.ID?
    @Published var selectedSectionID: String?
    @Published var searchText: String = ""
    @Published var isEditing: Bool = false
    @Published var editDraft: SongEditDraft?
    @Published var interactionContext: InteractionContext = .browsing

    weak var songManager: SongManager?
    weak var displayManager: DisplayManager?
    weak var themeManager: ThemeManager?

    func configure(songManager: SongManager, displayManager: DisplayManager, themeManager: ThemeManager) {
        self.songManager = songManager
        self.displayManager = displayManager
        self.themeManager = themeManager
        if selectedSongID == nil {
            selectedSongID = songManager.songs.first?.id
            selectedSectionID = songManager.songs.first?.presentationSlides.first?.id
        }
    }

    var filteredSongs: [SongItem] {
        guard let manager = songManager else { return [] }
        return manager.searchSongs(matching: searchText)
    }

    var selectedSong: SongItem? {
        guard let manager = songManager else { return nil }
        return manager.songs.first { $0.id == selectedSongID } ?? filteredSongs.first
    }

    var presentationSlides: [SongPresentationSlide] {
        selectedSong?.presentationSlides ?? []
    }

    var activeSection: SongPresentationSlide? {
        presentationSlides.first { $0.id == selectedSectionID } ?? presentationSlides.first
    }

    func selectSong(_ id: SongItem.ID) {
        selectedSongID = id
        selectedSectionID = songManager?.songs.first { $0.id == id }?.presentationSlides.first?.id
        themeManager?.preheatActiveAssets()
        if interactionContext != .searching {
            interactionContext = .browsing
        }
    }

    func projectSection(_ section: SongPresentationSlide) {
        guard let dm = displayManager else { return }
        selectedSectionID = section.id
        interactionContext = .navigatingSlides
        dm.project(
            source: section.source,
            reference: section.reference,
            body: section.body,
            backgroundOverride: section.backgroundAssetID.flatMap { assetID in
                section.backgroundAssetKind.map { ProjectionBackgroundOverride(assetID: assetID, assetKind: $0) }
            }
        )
        if let selectedSongID {
            songManager?.markSongPlayed(selectedSongID)
        }
    }

    func isProjected(_ section: SongPresentationSlide) -> Bool {
        displayManager?.currentProjection?.source == section.source
    }

    func stepSection(_ direction: Int) {
        guard !presentationSlides.isEmpty,
              let active = activeSection,
              let index = presentationSlides.firstIndex(where: { $0.id == active.id }) else { return }
        let next = min(max(index + direction, 0), presentationSlides.count - 1)
        let nextSection = presentationSlides[next]
        projectSection(nextSection)
    }

    // MARK: Editor

    func beginEditing() {
        guard let song = selectedSong else { return }
        editDraft = SongEditDraft(
            songID: song.id,
            title: song.title,
            author: song.author,
            key: song.key,
            sections: song.sections.map { section in
                SongSectionDraft(
                    id: section.id,
                    title: section.label,
                    lyricsText: section.bodyText,
                    backgroundAssetID: section.backgroundAssetID,
                    backgroundAssetKind: section.backgroundAssetKind
                )
            }
        )
        isEditing = true
        interactionContext = .editingLyrics
    }

    func beginNewSong() {
        editDraft = SongEditDraft(
            songID: nil,
            title: "",
            author: "",
            key: "",
            sections: [SongSectionDraft(title: "", lyricsText: "")]
        )
        isEditing = true
        interactionContext = .editingLyrics
    }

    func saveEdit(stayOpen: Bool = false) {
        guard let draft = editDraft, let manager = songManager else { return }
        let sections: [SongSection] = draft.sections.compactMap { d in
            let text = d.lyricsText.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            let lines = text
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return SongSection(
                id: d.id,
                title: title,
                lines: lines.isEmpty ? [text] : lines,
                backgroundAssetID: d.backgroundAssetID,
                backgroundAssetKind: d.backgroundAssetKind
            )
        }
        let normalizedSections = sections.isEmpty ? [SongSection(title: "", lines: [""])] : sections

        if let existingID = draft.songID {
            let updated = SongItem(id: existingID, title: draft.title, author: draft.author, key: draft.key, sections: normalizedSections)
            manager.updateSong(updated)
            selectedSongID = existingID
            if stayOpen {
                editDraft = SongEditDraft(
                    songID: updated.id,
                    title: updated.title,
                    author: updated.author,
                    key: updated.key,
                    sections: updated.sections.map { section in
                        SongSectionDraft(
                            id: section.id,
                            title: section.label,
                            lyricsText: section.bodyText,
                            backgroundAssetID: section.backgroundAssetID,
                            backgroundAssetKind: section.backgroundAssetKind
                        )
                    }
                )
                interactionContext = .editingLyrics
                return
            }
        } else {
            let newSong = SongItem(title: draft.title, author: draft.author, key: draft.key, sections: normalizedSections)
            manager.addSong(newSong)
            selectedSongID = newSong.id
            if stayOpen {
                editDraft = SongEditDraft(
                    songID: newSong.id,
                    title: newSong.title,
                    author: newSong.author,
                    key: newSong.key,
                    sections: newSong.sections.map { section in
                        SongSectionDraft(
                            id: section.id,
                            title: section.label,
                            lyricsText: section.bodyText,
                            backgroundAssetID: section.backgroundAssetID,
                            backgroundAssetKind: section.backgroundAssetKind
                        )
                    }
                )
                interactionContext = .editingLyrics
                return
            }
        }

        isEditing = false
        editDraft = nil
        interactionContext = .browsing
    }

    func cancelEdit() {
        isEditing = false
        editDraft = nil
        interactionContext = .browsing
    }

    var draftLyricsText: String {
        editDraft?.sections.map { $0.lyricsText }.joined(separator: "\n\n") ?? ""
    }

    func updateDraftLyrics(_ text: String) {
        guard var draft = editDraft else { return }
        let sections = draftSectionTexts(from: text)
        let existing = draft.sections

        draft.sections = sections.enumerated().map { index, sectionText in
            let current = existing[safe: index]
            return SongSectionDraft(
                id: current?.id ?? UUID(),
                title: current?.title ?? "",
                lyricsText: sectionText,
                backgroundAssetID: current?.backgroundAssetID,
                backgroundAssetKind: current?.backgroundAssetKind
            )
        }

        if draft.sections.isEmpty {
            draft.sections = [SongSectionDraft(title: "", lyricsText: "")]
        }

        editDraft = draft
    }

    private func draftSectionTexts(from text: String) -> [String] {
        WorshipLyricsProcessor.splitEditableSlides(from: text, maxVisibleLinesPerSlide: 4)
    }

    func updateDraftSectionTitle(at index: Int, title: String) {
        guard var draft = editDraft, draft.sections.indices.contains(index) else { return }
        draft.sections[index].title = title
        editDraft = draft
    }

    func duplicateDraftSection(at index: Int) {
        guard let section = editDraft?.sections[safe: index] else { return }
        let copy = SongSectionDraft(
            title: section.title,
            lyricsText: section.lyricsText,
            backgroundAssetID: section.backgroundAssetID,
            backgroundAssetKind: section.backgroundAssetKind
        )
        editDraft?.sections.insert(copy, at: index + 1)
    }

    func deleteDraftSection(at index: Int) {
        guard (editDraft?.sections.count ?? 0) > 1 else { return }
        editDraft?.sections.remove(at: index)
        if editDraft?.sections.isEmpty == true {
            editDraft?.sections = [SongSectionDraft(title: "", lyricsText: "")]
        }
    }

    func setInteractionContext(_ context: InteractionContext) {
        interactionContext = context
    }

    func updateDraftSectionBackground(
        at index: Int,
        assetID: UUID?,
        assetKind: ThemeAsset.AssetKind?
    ) {
        guard var draft = editDraft, draft.sections.indices.contains(index) else { return }
        draft.sections[index].backgroundAssetID = assetID
        draft.sections[index].backgroundAssetKind = assetKind
        editDraft = draft
    }
}

// MARK: - Edit Draft Models

struct SongEditDraft {
    var songID: SongItem.ID?
    var title: String
    var author: String
    var key: String
    var sections: [SongSectionDraft]
}

struct SongSectionDraft: Identifiable {
    let id: UUID
    var title: String
    var lyricsText: String
    var backgroundAssetID: UUID?
    var backgroundAssetKind: ThemeAsset.AssetKind?

    init(
        id: UUID = UUID(),
        title: String,
        lyricsText: String,
        backgroundAssetID: UUID? = nil,
        backgroundAssetKind: ThemeAsset.AssetKind? = nil
    ) {
        self.id = id
        self.title = title
        self.lyricsText = lyricsText
        self.backgroundAssetID = backgroundAssetID
        self.backgroundAssetKind = backgroundAssetKind
    }

    var label: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func displayTitle(index: Int) -> String {
        label.isEmpty ? "Diapositiva \(index + 1)" : label
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension String {
    var normalizedSearchToken: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    func decodingHTMLEntities() -> String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }
}

private struct SongSectionBackgroundOverride: Codable {
    let assetID: UUID
    let assetKind: ThemeAsset.AssetKind
}

// MARK: - Database Mapping

extension WorshipSongRecord {
    init(song: SongItem) {
        let lyrics = song.sections
            .map { section -> String in
                if section.label.isEmpty {
                    return section.lines.joined(separator: "\n")
                }
                return "[\(section.label)]\n" + section.lines.joined(separator: "\n")
            }
            .joined(separator: "\n\n")

        let inferredTags = song.sections.map { WorshipSectionTag.infer(from: $0.label) }
        self.init(
            id: song.id,
            title: song.title,
            artist: song.author,
            author: song.author,
            lyrics: lyrics,
            tags: inferredTags,
            searchTags: [song.title, song.author, song.key].filter { !$0.isEmpty }.map { WorshipLyricsProcessor.normalizeForSearch($0) },
            chordMetadata: WorshipChordMetadata(originalKey: song.key, bpm: song.bpm, chordLineHints: []),
            createdAt: .now,
            updatedAt: .now
        )
    }

    func toSongItem() -> SongItem {
        let chunks = WorshipLyricsProcessor.splitIntoChunks(from: lyrics, maxVisibleLinesPerSlide: 4)
        let sections: [SongSection]
        if chunks.isEmpty {
            sections = [SongSection(title: "", lines: [""])]
        } else {
            sections = chunks.map { chunk in
                let titleValue = chunk.title.isEmpty ? "" : chunk.title
                let contentLines = chunk.rawLines.isEmpty ? chunk.publicLines : chunk.rawLines
                return SongSection(
                    id: UUID(),
                    title: titleValue,
                    lines: contentLines
                )
            }
        }

        return SongItem(
            id: id,
            title: title,
            author: author.isEmpty ? artist : author,
            key: chordMetadata.originalKey,
            bpm: chordMetadata.bpm,
            sections: sections
        )
    }
}
// MARK: - SQLite + FTS5 Store

private final class SongSQLiteStore {
    private var db: OpaquePointer?

    init?(databaseURL: URL) {
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK else {
            sqlite3_close(db)
            db = nil
            return nil
        }
        guard createSchema() else {
            sqlite3_close(db)
            db = nil
            return nil
        }
    }

    deinit {
        sqlite3_close(db)
    }

    func fetchAllSongs() throws -> [SongItem] {
        let sql = """
        SELECT id, title, author, key_signature, bpm, lyrics, artist
        FROM songs
        ORDER BY title COLLATE NOCASE ASC;
        """
        return try fetchSongs(sql: sql, binder: nil)
    }

    func searchSongs(query: String) throws -> [SongItem] {
        let normalized = ftsQuery(from: query)
        let sql = """
        SELECT songs.id, songs.title, songs.author, songs.key_signature, songs.bpm, songs.lyrics, songs.artist
        FROM song_search
        JOIN songs ON songs.id = song_search.id
        WHERE song_search MATCH ?
        ORDER BY rank;
        """
        return try fetchSongs(sql: sql) { statement in
            self.bindText(normalized, to: statement, index: 1)
        }
    }

    func replaceSongs(_ songs: [SongItem]) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        defer { try? execute("COMMIT;") }

        try execute("DELETE FROM songs;")
        try execute("DELETE FROM song_search;")

        for song in songs {
            try upsert(song: song)
        }
    }

    func replaceServiceQueue(_ queue: [UUID]) throws {
        try execute("DELETE FROM service_queue;")
        for (index, id) in queue.enumerated() {
            let statement = try prepare("INSERT INTO service_queue(song_id, queue_index) VALUES(?, ?);")
            defer { sqlite3_finalize(statement) }
            bindText(id.uuidString, to: statement, index: 1)
            sqlite3_bind_int(statement, 2, Int32(index))
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw sqliteError(message: "No se pudo guardar la cola de servicio.")
            }
        }
    }

    func fetchServiceQueue() throws -> [UUID] {
        let statement = try prepare("SELECT song_id FROM service_queue ORDER BY queue_index ASC;")
        defer { sqlite3_finalize(statement) }
        var ids: [UUID] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let cString = sqlite3_column_text(statement, 0) else { continue }
            if let id = UUID(uuidString: String(cString: cString)) {
                ids.append(id)
            }
        }
        return ids
    }

    func replacePlayedSongIDs(_ ids: [UUID]) throws {
        try execute("DELETE FROM played_songs;")
        for id in ids {
            let statement = try prepare("INSERT INTO played_songs(song_id) VALUES(?);")
            defer { sqlite3_finalize(statement) }
            bindText(id.uuidString, to: statement, index: 1)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw sqliteError(message: "No se pudo guardar el estado de canciones tocadas.")
            }
        }
    }

    func fetchPlayedSongIDs() throws -> [UUID] {
        let statement = try prepare("SELECT song_id FROM played_songs;")
        defer { sqlite3_finalize(statement) }
        var ids: [UUID] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let cString = sqlite3_column_text(statement, 0) else { continue }
            if let id = UUID(uuidString: String(cString: cString)) {
                ids.append(id)
            }
        }
        return ids
    }

    private func createSchema() -> Bool {
        [
            """
            CREATE TABLE IF NOT EXISTS songs (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                author TEXT NOT NULL,
                artist TEXT NOT NULL,
                key_signature TEXT NOT NULL,
                bpm INTEGER,
                lyrics TEXT NOT NULL,
                tags_json TEXT NOT NULL,
                search_tags TEXT NOT NULL,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            );
            """,
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS song_search USING fts5(
                id UNINDEXED,
                title,
                author,
                artist,
                lyrics,
                search_tags
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS service_queue (
                song_id TEXT PRIMARY KEY,
                queue_index INTEGER NOT NULL
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS played_songs (
                song_id TEXT PRIMARY KEY
            );
            """
        ].allSatisfy { executeSilently($0) }
    }

    private func upsert(song: SongItem) throws {
        let record = WorshipSongRecord(song: song)
        let tagsData = try JSONEncoder().encode(record.tags.map(\.rawValue))
        let tagsString = String(data: tagsData, encoding: .utf8) ?? "[]"
        let searchTags = record.searchTags.joined(separator: " ")

        let songStatement = try prepare("""
        INSERT INTO songs(id, title, author, artist, key_signature, bpm, lyrics, tags_json, search_tags, created_at, updated_at)
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """)
        defer { sqlite3_finalize(songStatement) }
        bindText(song.id.uuidString, to: songStatement, index: 1)
        bindText(song.title, to: songStatement, index: 2)
        bindText(song.author, to: songStatement, index: 3)
        bindText(song.author, to: songStatement, index: 4)
        bindText(song.key, to: songStatement, index: 5)
        if let bpm = song.bpm {
            sqlite3_bind_int(songStatement, 6, Int32(bpm))
        } else {
            sqlite3_bind_null(songStatement, 6)
        }
        bindText(record.lyrics, to: songStatement, index: 7)
        bindText(tagsString, to: songStatement, index: 8)
        bindText(searchTags, to: songStatement, index: 9)
        sqlite3_bind_double(songStatement, 10, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(songStatement, 11, record.updatedAt.timeIntervalSince1970)
        guard sqlite3_step(songStatement) == SQLITE_DONE else {
            throw sqliteError(message: "No se pudo guardar la canción.")
        }

        let searchStatement = try prepare("""
        INSERT INTO song_search(id, title, author, artist, lyrics, search_tags)
        VALUES(?, ?, ?, ?, ?, ?);
        """)
        defer { sqlite3_finalize(searchStatement) }
        bindText(song.id.uuidString, to: searchStatement, index: 1)
        bindText(song.title, to: searchStatement, index: 2)
        bindText(song.author, to: searchStatement, index: 3)
        bindText(song.author, to: searchStatement, index: 4)
        bindText(record.lyrics, to: searchStatement, index: 5)
        bindText(searchTags, to: searchStatement, index: 6)
        guard sqlite3_step(searchStatement) == SQLITE_DONE else {
            throw sqliteError(message: "No se pudo indexar la canción.")
        }
    }

    private func fetchSongs(
        sql: String,
        binder: ((OpaquePointer?) -> Void)?
    ) throws -> [SongItem] {
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        binder?(statement)

        var items: [SongItem] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idCString = sqlite3_column_text(statement, 0),
                let titleCString = sqlite3_column_text(statement, 1),
                let authorCString = sqlite3_column_text(statement, 2),
                let keyCString = sqlite3_column_text(statement, 3),
                let lyricsCString = sqlite3_column_text(statement, 5)
            else {
                continue
            }

            let idString = String(cString: idCString)
            guard let id = UUID(uuidString: idString) else { continue }
            let title = String(cString: titleCString)
            let author = String(cString: authorCString)
            let key = String(cString: keyCString)
            let lyrics = String(cString: lyricsCString)
            let bpm = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 4))
            let artist = sqlite3_column_text(statement, 6).map { String(cString: $0) } ?? author

            let record = WorshipSongRecord(
                id: id,
                title: title,
                artist: artist,
                author: author,
                lyrics: lyrics,
                tags: [],
                searchTags: [],
                chordMetadata: WorshipChordMetadata(originalKey: key, bpm: bpm, chordLineHints: []),
                createdAt: .now,
                updatedAt: .now
            )
            items.append(record.toSongItem())
        }
        return items
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw sqliteError(message: "No se pudo preparar la consulta.")
        }
        return statement
    }

    private func execute(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw sqliteError(message: "No se pudo ejecutar la operación en la base de datos.")
        }
    }

    private func executeSilently(_ sql: String) -> Bool {
        sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK
    }

    private func bindText(_ value: String, to statement: OpaquePointer?, index: Int32) {
        sqlite3_bind_text(statement, index, (value as NSString).utf8String, -1, SQLITE_TRANSIENT)
    }

    private func sqliteError(message: String) -> NSError {
        let detail = db.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "Sin detalle"
        return NSError(domain: "SongSQLiteStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(message) \(detail)"])
    }

    private func ftsQuery(from query: String) -> String {
        let tokens = WorshipLyricsProcessor
            .normalizeForSearch(query)
            .split(whereSeparator: { $0.isWhitespace })
            .map { "\($0)*" }
        return tokens.isEmpty ? "*" : tokens.joined(separator: " ")
    }
}
