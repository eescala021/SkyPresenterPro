import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct Verse: Hashable, Codable {
    let number: Int
    let text: String
}

struct Chapter: Hashable, Codable {
    let number: Int
    var verses: [Verse]
}

struct BibleBook: Hashable, Codable {
    let number: Int
    let name: String
    var chapters: [Chapter]
}

struct BibleVersionSlot: Identifiable, Hashable, Codable {
    let id: Int
    var title: String
    var language: String
    var sourceBadge: String?
    var books: [BibleBook]
    var databasePath: String?
    var libraryItemID: UUID?

    var isLoaded: Bool {
        databasePath != nil || !books.isEmpty
    }
}

enum BibleLanguageOption: String, CaseIterable, Codable, Identifiable {
    case spanish = "ES"
    case english = "EN"
    case portuguese = "PT"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "Inglés"
        case .portuguese: return "Portugués"
        }
    }
}

struct BibleLibraryItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var alias: String
    var language: String
    var sourceBadge: String?
    var databasePath: String

    var displayTitle: String {
        alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? name : alias
    }
}

struct BibleReferenceMatch: Equatable {
    let versionIndex: Int
    let versionTitle: String
    let bookIndex: Int
    let bookName: String
    let chapter: Int
    let verse: Int
    let verseText: String

    var reference: String {
        "\(bookName) \(chapter):\(verse) (\(versionTitle))"
    }

    var identityKey: String {
        "\(versionTitle)|\(bookIndex)|\(chapter)|\(verse)"
    }
}

struct BibleReferenceSelection: Equatable {
    let versionIndex: Int
    let versionTitle: String
    let bookIndex: Int
    let bookName: String
    let chapter: Int
    let verse: Int?
    let verseText: String?

    var reference: String {
        if let verse {
            return "\(bookName) \(chapter):\(verse) (\(versionTitle))"
        }
        return "\(bookName) \(chapter) (\(versionTitle))"
    }
}

struct BibleFavorite: Identifiable, Hashable, Codable {
    let id: String
    let versionIndex: Int
    let versionTitle: String
    let bookIndex: Int
    let bookName: String
    let chapter: Int
    let verse: Int
    let verseText: String

    var reference: String {
        "\(bookName) \(chapter):\(verse) (\(versionTitle))"
    }
}

final class BibleManager: NSObject, ObservableObject {
    @Published var versions: [BibleVersionSlot]
    @Published var library: [BibleLibraryItem]
    @Published var isImporting: Bool = false
    @Published var lastImportError: String?

    private static let persistedVersionsKey = "BibleManager.persistedVersionMetadata"
    private static let persistedVersionsContentKey = "BibleManager.persistedVersionContent"
    private let versionsStorageURL: URL
    private let libraryStorageURL: URL
    private let sqliteStore: BibleSQLiteStore

    override init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.versionsStorageURL = directory.appendingPathComponent("bible-versions.json")
        self.libraryStorageURL = directory.appendingPathComponent("bible-library.json")
        self.sqliteStore = BibleSQLiteStore(directoryURL: directory.appendingPathComponent("BibleSQLite", isDirectory: true))
        self.versions = Self.loadPersistedVersions(defaults: Self.defaultVersions(), storageURL: versionsStorageURL)
        self.library = Self.loadPersistedLibrary(storageURL: libraryStorageURL)
        super.init()
        Self.removeLegacyBibleDefaultsBlob()
        migrateLegacySlotsIntoLibraryIfNeeded()
        migrateLoadedVersionsToSQLiteIfNeeded()
    }

    func version(at index: Int) -> BibleVersionSlot? {
        guard versions.indices.contains(index) else { return nil }
        return versions[index]
    }

    func books(at versionIndex: Int) -> [BibleBookMetadata] {
        guard let url = databaseURL(for: versionIndex) else { return [] }
        return sqliteStore.books(at: url)
    }

    func chapterCount(at versionIndex: Int, bookIndex: Int) -> Int {
        guard let url = databaseURL(for: versionIndex) else { return 0 }
        return sqliteStore.chapterCount(at: url, bookNumber: bookIndex)
    }

    func verseCount(at versionIndex: Int, bookIndex: Int, chapter: Int) -> Int {
        guard let url = databaseURL(for: versionIndex) else { return 0 }
        return sqliteStore.verseCount(at: url, bookNumber: bookIndex, chapter: chapter)
    }

    func verses(at versionIndex: Int, bookIndex: Int, chapter: Int) -> [Verse] {
        guard let url = databaseURL(for: versionIndex) else { return [] }
        return sqliteStore.verses(at: url, bookNumber: bookIndex, chapter: chapter)
    }

    func verseText(at versionIndex: Int, bookIndex: Int, chapter: Int, verse: Int) -> String? {
        guard let url = databaseURL(for: versionIndex) else { return nil }
        return sqliteStore.verseText(at: url, bookNumber: bookIndex, chapter: chapter, verse: verse)
    }

    func searchVerses(query: String, at versionIndex: Int, limit: Int = 20) -> [BibleSQLiteStore.BibleSearchResult] {
        guard let url = databaseURL(for: versionIndex) else { return [] }
        return sqliteStore.search(query: query, at: url, limit: limit)
    }

    func detectReference(in recognizedText: String) -> BibleReferenceMatch? {
        if let selection = resolveReferenceSelection(in: recognizedText) {
            return selection.verseMatch
        }

        let normalized = Self.normalizeReferenceString(recognizedText)
        guard !normalized.isEmpty else { return nil }

        for version in versions where version.isLoaded {
            let availableBooks = books(at: version.id)
            for alias in Self.bookAliases {
                guard normalized.contains(alias.alias) else { continue }
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: alias.alias))\\s+(\\d{1,3})\\s*[:.]\\s*(\\d{1,3})\\b"
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
                guard let match = regex.firstMatch(in: normalized, range: range),
                      let chapterRange = Range(match.range(at: 1), in: normalized),
                      let verseRange = Range(match.range(at: 2), in: normalized),
                      let chapter = Int(normalized[chapterRange]),
                      let verse = Int(normalized[verseRange]),
                      availableBooks.contains(where: { $0.number == alias.bookIndex }),
                      chapter > 0,
                      chapter <= chapterCount(at: version.id, bookIndex: alias.bookIndex),
                      let verseText = verseText(at: version.id, bookIndex: alias.bookIndex, chapter: chapter, verse: verse)
                else { continue }

                let bookName = availableBooks.first(where: { $0.number == alias.bookIndex })?.name ?? "Libro \(alias.bookIndex)"
                return BibleReferenceMatch(
                    versionIndex: version.id,
                    versionTitle: version.title,
                    bookIndex: alias.bookIndex,
                    bookName: bookName,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText
                )
            }
        }

        return nil
    }

    func resolveReferenceSelection(in query: String, preferredVersionIndex: Int? = nil) -> BibleReferenceSelection? {
        let normalized = Self.normalizeReferenceString(query)
        guard !normalized.isEmpty else { return nil }

        var orderedVersions = Array(versions.enumerated()).filter { $0.element.isLoaded }
        if let preferredVersionIndex,
           let preferredPosition = orderedVersions.firstIndex(where: { $0.offset == preferredVersionIndex }) {
            let preferred = orderedVersions.remove(at: preferredPosition)
            orderedVersions.insert(preferred, at: 0)
        }

        for (versionIndex, version) in orderedVersions {
            let availableBooks = books(at: versionIndex)
            for alias in Self.bookAliases {
                guard normalized.contains(alias.alias) else { continue }
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: alias.alias))\\s+(\\d{1,3})(?:\\s*[:.]\\s*(\\d{1,3}))?\\b"
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
                guard let match = regex.firstMatch(in: normalized, range: range),
                      let chapterRange = Range(match.range(at: 1), in: normalized),
                      let chapter = Int(normalized[chapterRange]),
                      availableBooks.contains(where: { $0.number == alias.bookIndex }),
                      chapter > 0,
                      chapter <= chapterCount(at: versionIndex, bookIndex: alias.bookIndex)
                else { continue }

                let bookName = availableBooks.first(where: { $0.number == alias.bookIndex })?.name ?? "Libro \(alias.bookIndex)"
                if let verseRange = Range(match.range(at: 2), in: normalized),
                   let verse = Int(normalized[verseRange]),
                   let verseText = verseText(at: versionIndex, bookIndex: alias.bookIndex, chapter: chapter, verse: verse) {
                    return BibleReferenceSelection(
                        versionIndex: versionIndex,
                        versionTitle: version.title,
                        bookIndex: alias.bookIndex,
                        bookName: bookName,
                        chapter: chapter,
                        verse: verse,
                        verseText: verseText
                    )
                }

                return BibleReferenceSelection(
                    versionIndex: versionIndex,
                    versionTitle: version.title,
                    bookIndex: alias.bookIndex,
                    bookName: bookName,
                    chapter: chapter,
                    verse: nil,
                    verseText: nil
                )
            }
        }

        return nil
    }

    func detectReferences(in recognizedText: String) -> [BibleReferenceMatch] {
        let normalized = Self.normalizeReferenceString(recognizedText)
        guard !normalized.isEmpty else { return [] }

        struct Candidate {
            let location: Int
            let match: BibleReferenceMatch
        }

        var candidates: [Candidate] = []
        for version in versions where version.isLoaded {
            let availableBooks = books(at: version.id)
            for alias in Self.bookAliases {
                guard normalized.contains(alias.alias) else { continue }
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: alias.alias))\\s+(\\d{1,3})\\s*[:.]\\s*(\\d{1,3})\\b"
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)

                for regexMatch in regex.matches(in: normalized, range: range) {
                    guard let chapterRange = Range(regexMatch.range(at: 1), in: normalized),
                          let verseRange = Range(regexMatch.range(at: 2), in: normalized),
                          let chapter = Int(normalized[chapterRange]),
                          let verse = Int(normalized[verseRange]),
                          availableBooks.contains(where: { $0.number == alias.bookIndex }),
                          chapter > 0,
                          chapter <= chapterCount(at: version.id, bookIndex: alias.bookIndex),
                          let verseText = verseText(at: version.id, bookIndex: alias.bookIndex, chapter: chapter, verse: verse)
                    else { continue }

                    let bookName = availableBooks.first(where: { $0.number == alias.bookIndex })?.name ?? "Libro \(alias.bookIndex)"
                    candidates.append(
                        Candidate(
                            location: regexMatch.range.location,
                            match: BibleReferenceMatch(
                                versionIndex: version.id,
                                versionTitle: version.title,
                                bookIndex: alias.bookIndex,
                                bookName: bookName,
                                chapter: chapter,
                                verse: verse,
                                verseText: verseText
                            )
                        )
                    )
                }
            }
        }

        let ordered = candidates.sorted { $0.location < $1.location }.map(\.match)
        var unique: [BibleReferenceMatch] = []
        var seen: Set<String> = []
        for match in ordered where seen.insert(match.identityKey).inserted {
            unique.append(match)
        }
        return unique
    }

    func renameVersion(at index: Int, title: String) {
        guard versions.indices.contains(index) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        versions[index].title = trimmed
        persistAllVersions()
    }

    func resetVersion(at index: Int) {
        guard versions.indices.contains(index) else { return }
        versions[index] = BibleVersionSlot(
            id: index,
            title: "VERS \(index + 1)",
            language: "",
            sourceBadge: nil,
            books: [],
            databasePath: nil,
            libraryItemID: nil
        )
        persistAllVersions()
    }

    var canImportMoreBibles: Bool {
        library.count < 10
    }

    func importBibleToLibrary(name: String, alias: String, language: BibleLanguageOption) {
        guard canImportMoreBibles else {
            lastImportError = "La biblioteca admite hasta 10 biblias importadas."
            return
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.title = "Seleccionar Biblia Zefania XML"
        panel.message = "Elige un archivo XML para agregarlo a la biblioteca."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            await parseAndStoreBible(
                from: url,
                slotIndex: nil,
                customName: name,
                alias: alias,
                language: language.rawValue,
                imported: true
            )
        }
    }

    func assignLibraryItem(_ itemID: UUID, toSlot slotIndex: Int) {
        guard versions.indices.contains(slotIndex),
              let item = library.first(where: { $0.id == itemID }) else { return }
        versions[slotIndex].title = item.displayTitle
        versions[slotIndex].language = item.language
        versions[slotIndex].sourceBadge = item.sourceBadge
        versions[slotIndex].databasePath = item.databasePath
        versions[slotIndex].books = []
        versions[slotIndex].libraryItemID = item.id
        persistAllVersions()
    }

    func updateLibraryItem(id: UUID, name: String, alias: String, language: BibleLanguageOption) {
        guard let index = library.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedAlias.isEmpty else { return }
        library[index].name = trimmedName
        library[index].alias = trimmedAlias
        library[index].language = language.rawValue
        syncSlotsWithLibraryItem(library[index])
        persistLibrary()
        persistAllVersions()
    }

    func deleteLibraryItem(id: UUID) {
        guard let index = library.firstIndex(where: { $0.id == id }) else { return }
        let item = library.remove(at: index)
        for slotIndex in versions.indices where versions[slotIndex].libraryItemID == id {
            resetVersion(at: slotIndex)
        }
        try? FileManager.default.removeItem(atPath: item.databasePath)
        persistLibrary()
        persistAllVersions()
    }

    func moveLibraryItems(from source: IndexSet, to destination: Int) {
        library.move(fromOffsets: source, toOffset: destination)
        persistLibrary()
    }

    func loadBundledBible(fileName: String = "biblia", into slotIndex: Int = 0, fallbackName: String = "VERS 1", language: String = "ES") {
        if versions.indices.contains(slotIndex), versions[slotIndex].isLoaded {
            return
        }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "xml") else {
            lastImportError = "No se encontró \(fileName).xml en el paquete."
            return
        }

        Task {
            await parseAndStoreBible(
                from: url,
                slotIndex: slotIndex,
                customName: persistedTitle(for: slotIndex) ?? fallbackName,
                alias: persistedTitle(for: slotIndex) ?? fallbackName,
                language: language,
                imported: false
            )
        }
    }

    @MainActor
    private func storeVersion(_ version: BibleVersionSlot, at index: Int) {
        guard versions.indices.contains(index) else { return }
        versions[index] = version
        persistAllVersions()
    }

    private func persistedTitle(for index: Int) -> String? {
        guard versions.indices.contains(index) else { return nil }
        let title = versions[index].title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }

    private func persistLibrary() {
        guard let data = try? JSONEncoder().encode(library) else { return }
        try? data.write(to: libraryStorageURL, options: .atomic)
    }

    private func persistVersionMetadata() {
        let payload = versions.map {
            PersistedBibleVersionMetadata(
                id: $0.id,
                title: $0.title,
                language: $0.language,
                sourceBadge: $0.sourceBadge,
                libraryItemID: $0.libraryItemID
            )
        }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: Self.persistedVersionsKey)
    }

    private func persistAllVersions() {
        persistVersionMetadata()
        let compactVersions = versions.map { version -> BibleVersionSlot in
            var copy = version
            copy.books = []
            return copy
        }
        guard let data = try? JSONEncoder().encode(compactVersions) else { return }
        try? data.write(to: versionsStorageURL, options: .atomic)
        UserDefaults.standard.removeObject(forKey: Self.persistedVersionsContentKey)
    }

    private static func defaultVersions() -> [BibleVersionSlot] {
        [
            BibleVersionSlot(id: 0, title: "VERS 1", language: "ES", sourceBadge: nil, books: [], databasePath: nil, libraryItemID: nil),
            BibleVersionSlot(id: 1, title: "VERS 2", language: "", sourceBadge: nil, books: [], databasePath: nil, libraryItemID: nil),
            BibleVersionSlot(id: 2, title: "VERS 3", language: "", sourceBadge: nil, books: [], databasePath: nil, libraryItemID: nil)
        ]
    }

    private static func loadPersistedLibrary(storageURL: URL) -> [BibleLibraryItem] {
        guard let data = try? Data(contentsOf: storageURL),
              let persisted = try? JSONDecoder().decode([BibleLibraryItem].self, from: data) else {
            return []
        }
        return persisted.filter { FileManager.default.fileExists(atPath: $0.databasePath) }
    }

    private static func loadPersistedVersions(defaults: [BibleVersionSlot], storageURL: URL) -> [BibleVersionSlot] {
        if let data = try? Data(contentsOf: storageURL),
           let persisted = try? JSONDecoder().decode([BibleVersionSlot].self, from: data),
           !persisted.isEmpty {
            return persisted
        }

        if let data = UserDefaults.standard.data(forKey: persistedVersionsContentKey),
           let persisted = try? JSONDecoder().decode([BibleVersionSlot].self, from: data),
           !persisted.isEmpty {
            try? data.write(to: storageURL, options: .atomic)
            UserDefaults.standard.removeObject(forKey: persistedVersionsContentKey)
            return persisted
        }

        guard
            let data = UserDefaults.standard.data(forKey: persistedVersionsKey),
            let persisted = try? JSONDecoder().decode([PersistedBibleVersionMetadata].self, from: data)
        else {
            return defaults
        }

        var resolved = defaults
        for entry in persisted {
            guard resolved.indices.contains(entry.id) else { continue }
            resolved[entry.id].title = entry.title
            resolved[entry.id].language = entry.language
            resolved[entry.id].sourceBadge = entry.sourceBadge
            resolved[entry.id].libraryItemID = entry.libraryItemID
        }
        return resolved
    }

    private static func removeLegacyBibleDefaultsBlob() {
        if UserDefaults.standard.data(forKey: persistedVersionsContentKey) != nil {
            UserDefaults.standard.removeObject(forKey: persistedVersionsContentKey)
        }
    }

    private static func normalizeReferenceString(_ input: String) -> String {
        let normalized = input
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es"))
            .replacingOccurrences(of: "\n", with: " ")
            .lowercased()
        return normalized.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let bookAliases: [(alias: String, bookIndex: Int)] = [
        ("genesis", 1), ("gen", 1), ("gn", 1),
        ("exodo", 2), ("exo", 2), ("ex", 2),
        ("levitico", 3), ("lev", 3), ("lv", 3),
        ("numeros", 4), ("num", 4), ("nm", 4),
        ("deuteronomio", 5), ("deut", 5), ("dt", 5),
        ("josue", 6), ("jos", 6),
        ("jueces", 7), ("jue", 7), ("jdc", 7),
        ("rut", 8), ("rt", 8),
        ("1 samuel", 9), ("1 sam", 9), ("1sa", 9), ("1sm", 9),
        ("2 samuel", 10), ("2 sam", 10), ("2sa", 10), ("2sm", 10),
        ("1 reyes", 11), ("1 rey", 11), ("1re", 11),
        ("2 reyes", 12), ("2 rey", 12), ("2re", 12),
        ("1 cronicas", 13), ("1 cro", 13), ("1cr", 13),
        ("2 cronicas", 14), ("2 cro", 14), ("2cr", 14),
        ("esdras", 15), ("esd", 15),
        ("nehemias", 16), ("ne", 16),
        ("ester", 17), ("est", 17),
        ("job", 18),
        ("salmos", 19), ("salmo", 19), ("sal", 19),
        ("proverbios", 20), ("prov", 20), ("pr", 20),
        ("eclesiastes", 21), ("ecl", 21),
        ("cantares", 22), ("cantares de salomon", 22), ("cant", 22),
        ("isaias", 23), ("is", 23),
        ("jeremias", 24), ("jr", 24),
        ("lamentaciones", 25), ("lam", 25),
        ("ezequiel", 26), ("ez", 26),
        ("daniel", 27), ("dn", 27),
        ("oseas", 28), ("os", 28),
        ("joel", 29), ("jl", 29),
        ("amos", 30), ("am", 30),
        ("abdias", 31), ("abd", 31),
        ("jonas", 32), ("jon", 32),
        ("miqueas", 33), ("miq", 33),
        ("nahum", 34), ("na", 34),
        ("habacuc", 35), ("hab", 35),
        ("sofonias", 36), ("sof", 36),
        ("hageo", 37), ("hag", 37),
        ("zacarias", 38), ("zac", 38),
        ("malaquias", 39), ("mal", 39),
        ("mateo", 40), ("mt", 40),
        ("marcos", 41), ("mc", 41),
        ("lucas", 42), ("lc", 42),
        ("juan", 43), ("jn", 43),
        ("hechos", 44), ("hch", 44),
        ("romanos", 45), ("rom", 45),
        ("1 corintios", 46), ("1 cor", 46), ("1co", 46),
        ("2 corintios", 47), ("2 cor", 47), ("2co", 47),
        ("galatas", 48), ("gal", 48),
        ("efesios", 49), ("ef", 49),
        ("filipenses", 50), ("fil", 50),
        ("colosenses", 51), ("col", 51),
        ("1 tesalonicenses", 52), ("1 tes", 52), ("1tes", 52),
        ("2 tesalonicenses", 53), ("2 tes", 53), ("2tes", 53),
        ("1 timoteo", 54), ("1 tim", 54), ("1tim", 54),
        ("2 timoteo", 55), ("2 tim", 55), ("2tim", 55),
        ("tito", 56), ("tit", 56),
        ("filemon", 57), ("flm", 57),
        ("hebreos", 58), ("heb", 58),
        ("santiago", 59), ("st", 59),
        ("1 pedro", 60), ("1 ped", 60), ("1pe", 60),
        ("2 pedro", 61), ("2 ped", 61), ("2pe", 61),
        ("1 juan", 62), ("1 jn", 62), ("1jn", 62),
        ("2 juan", 63), ("2 jn", 63), ("2jn", 63),
        ("3 juan", 64), ("3 jn", 64), ("3jn", 64),
        ("judas", 65), ("jud", 65),
        ("apocalipsis", 66), ("apo", 66), ("ap", 66)
    ]

    private func parseAndStoreBible(
        from url: URL,
        slotIndex: Int?,
        customName: String,
        alias: String,
        language: String,
        imported: Bool
    ) async {
        await MainActor.run {
            isImporting = true
            lastImportError = nil
        }

        do {
            let books = try await BibleXMLParser.parse(url: url)
            let resolvedName = customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Biblia importada"
                : customName.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? resolvedName
                : alias.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedLanguage = language.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let libraryID = UUID()
            let databaseURL = try sqliteStore.buildDatabase(named: "bible-library-\(libraryID.uuidString)", books: books)

            let libraryItem = BibleLibraryItem(
                id: libraryID,
                name: resolvedName,
                alias: resolvedAlias,
                language: resolvedLanguage,
                sourceBadge: imported ? "IMPORTADO DESDE ARCHIVO ZEFANIA XML" : nil,
                databasePath: databaseURL.path
            )

            await MainActor.run {
                library.append(libraryItem)
                persistLibrary()
                if let slotIndex {
                    assignLibraryItem(libraryItem.id, toSlot: slotIndex)
                }
                isImporting = false
            }
        } catch {
            await MainActor.run {
                lastImportError = "No se pudo importar la Biblia XML."
                isImporting = false
            }
        }
    }

    private func databaseURL(for versionIndex: Int) -> URL? {
        guard let version = version(at: versionIndex) else { return nil }
        if let path = version.databasePath, FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    private func migrateLoadedVersionsToSQLiteIfNeeded() {
        var didChange = false
        for index in versions.indices {
            if versions[index].databasePath == nil, !versions[index].books.isEmpty {
                if let url = try? sqliteStore.buildDatabase(for: index, books: versions[index].books) {
                    versions[index].databasePath = url.path
                    didChange = true
                }
            }
        }
        if didChange {
            persistAllVersions()
        }
    }

    private func migrateLegacySlotsIntoLibraryIfNeeded() {
        var libraryChanged = false
        var slotsChanged = false

        for index in versions.indices where versions[index].libraryItemID == nil {
            guard let path = versions[index].databasePath, FileManager.default.fileExists(atPath: path) else { continue }
            if let existing = library.first(where: { $0.databasePath == path }) {
                versions[index].libraryItemID = existing.id
                versions[index].title = existing.displayTitle
                versions[index].language = existing.language
                versions[index].sourceBadge = existing.sourceBadge
                slotsChanged = true
                continue
            }

            let item = BibleLibraryItem(
                id: UUID(),
                name: versions[index].title,
                alias: versions[index].title,
                language: versions[index].language,
                sourceBadge: versions[index].sourceBadge,
                databasePath: path
            )
            library.append(item)
            versions[index].libraryItemID = item.id
            slotsChanged = true
            libraryChanged = true
        }

        if libraryChanged { persistLibrary() }
        if slotsChanged { persistAllVersions() }
    }

    private func syncSlotsWithLibraryItem(_ item: BibleLibraryItem) {
        for index in versions.indices where versions[index].libraryItemID == item.id {
            versions[index].title = item.displayTitle
            versions[index].language = item.language
            versions[index].sourceBadge = item.sourceBadge
            versions[index].databasePath = item.databasePath
            versions[index].books = []
        }
    }
}

private struct PersistedBibleVersionMetadata: Codable {
    let id: Int
    let title: String
    let language: String
    let sourceBadge: String?
    let libraryItemID: UUID?
}

@MainActor
final class BibleViewState: ObservableObject {
    @Published var selectedVersionIndex: Int = 0
    @Published var selectedBookIndex: Int = 1
    @Published var selectedChapter: Int = 1
    @Published var selectedVerse: Int?
    @Published var chapterPage: Int = 0
    @Published var versePage: Int = 0
    @Published var searchText: String = ""
    @Published var quickJumpText: String = "1"
    @Published var favorites: [BibleFavorite] = []
    @Published var lastSearchFeedback: String = ""

    let chapterPageSize = 38
    let versePageSize = 30

    private weak var bibleManager: BibleManager?
    private weak var displayManager: DisplayManager?
    private let favoritesStorageURL: URL

    let bookNames = [
        "Gn", "Ex", "Lv", "Nm", "Dt", "Jos", "Jue", "Rt", "1Sm", "2Sm", "1Re", "2Re", "1Cr", "2Cr", "Esd", "Ne", "Est",
        "Job", "Sal", "Pr", "Ecl", "Cant", "Is", "Jr", "Lam", "Ez", "Dn",
        "Os", "Jl", "Am", "Abd", "Jon", "Miq", "Na", "Hab", "Sof", "Hag", "Zac", "Mal",
        "Mt", "Mc", "Lc", "Jn", "Hch",
        "Rom", "1Co", "2Co", "Gal", "Ef", "Fil", "Col", "1Tes", "2Tes", "1Tim", "2Tim", "Tit", "Flm",
        "Heb", "St", "1Pe", "2Pe", "1Jn", "2Jn", "3Jn", "Jud", "Ap"
    ]

    let fullBookNames = [
        "Génesis", "Éxodo", "Levítico", "Números", "Deuteronomio", "Josué", "Jueces", "Rut", "1 Samuel", "2 Samuel", "1 Reyes", "2 Reyes", "1 Crónicas", "2 Crónicas", "Esdras", "Nehemías", "Ester",
        "Job", "Salmos", "Proverbios", "Eclesiastés", "Cantares", "Isaías", "Jeremías", "Lamentaciones", "Ezequiel", "Daniel",
        "Oseas", "Joel", "Amós", "Abdías", "Jonás", "Miqueas", "Nahum", "Habacuc", "Sofonías", "Hageo", "Zacarías", "Malaquías",
        "Mateo", "Marcos", "Lucas", "Juan", "Hechos",
        "Romanos", "1 Corintios", "2 Corintios", "Gálatas", "Efesios", "Filipenses", "Colosenses", "1 Tesalonicenses", "2 Tesalonicenses", "1 Timoteo", "2 Timoteo", "Tito", "Filemón",
        "Hebreos", "Santiago", "1 Pedro", "2 Pedro", "1 Juan", "2 Juan", "3 Juan", "Judas", "Apocalipsis"
    ]

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.favoritesStorageURL = directory.appendingPathComponent("bible-favorites.json")
        self.favorites = Self.loadFavorites(from: favoritesStorageURL)
    }

    func configure(bibleManager: BibleManager, displayManager: DisplayManager) {
        self.bibleManager = bibleManager
        self.displayManager = displayManager
    }

    var currentVersion: BibleVersionSlot? {
        bibleManager?.version(at: selectedVersionIndex)
    }

    var currentBooks: [BibleBookMetadata] {
        bibleManager?.books(at: selectedVersionIndex) ?? []
    }

    var currentBook: BibleBookMetadata? {
        guard selectedBookIndex > 0 else { return nil }
        return currentBooks.first(where: { $0.number == selectedBookIndex })
    }

    var currentChapterCount: Int {
        bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0
    }

    var currentVerses: [Verse] {
        guard selectedChapter > 0 else { return [] }
        return bibleManager?.verses(at: selectedVersionIndex, bookIndex: selectedBookIndex, chapter: selectedChapter) ?? []
    }

    var visibleBookIndexes: [Int] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Array(1...66) }

        let matches = (1...66).filter { index in
            let shortName = index <= bookNames.count ? bookNames[index - 1] : ""
            let fullName = index <= fullBookNames.count ? fullBookNames[index - 1] : ""
            return shortName.localizedCaseInsensitiveContains(query) || fullName.localizedCaseInsensitiveContains(query)
        }

        return matches.isEmpty ? Array(1...66) : matches
    }

    var chapterPageCount: Int {
        let total = bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0
        return max(1, Int(ceil(Double(max(total, 1)) / Double(chapterPageSize))))
    }

    var versePageCount: Int {
        max(1, Int(ceil(Double(max(currentVerses.count, 1)) / Double(versePageSize))))
    }

    var chapterItems: [PageItem] {
        pagedItems(total: bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0, page: chapterPage, pageSize: chapterPageSize)
    }

    var verseItems: [PageItem] {
        pagedItems(total: currentVerses.count, page: versePage, pageSize: versePageSize)
    }

    var projectedSourceKey: String? {
        displayManager?.currentProjection?.source
    }

    var chapterNeedsPagination: Bool {
        (bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0) > chapterPageSize
    }

    var verseNeedsPagination: Bool {
        currentVerses.count > versePageSize
    }

    var selectionTitle: String {
        let version = currentVersion?.title ?? "VERS 1"
        let book = selectedBookIndex > 0 && selectedBookIndex <= fullBookNames.count ? fullBookNames[selectedBookIndex - 1] : "Biblia"
        let verseLabel = selectedVerse.map { ":\($0)" } ?? ""
        return "\(version) · \(book) \(selectedChapter)\(verseLabel)"
    }

    var currentBookTitle: String {
        selectedBookIndex > 0 && selectedBookIndex <= fullBookNames.count ? fullBookNames[selectedBookIndex - 1] : "Biblia"
    }

    var emptyBibleMessage: String {
        if bibleManager?.isImporting == true {
            return "Importando Biblia..."
        }
        return "Esta versión aún no tiene una Biblia cargada."
    }

    var searchPlaceholder: String {
        "Buscar libro o referencia"
    }

    var selectedFavoriteID: String? {
        guard let selectedVerse else { return nil }
        return favoriteID(
            versionIndex: selectedVersionIndex,
            bookIndex: selectedBookIndex,
            chapter: selectedChapter,
            verse: selectedVerse
        )
    }

    var isSelectedVerseFavorite: Bool {
        guard let selectedFavoriteID else { return false }
        return favorites.contains(where: { $0.id == selectedFavoriteID })
    }

    func selectVersion(_ index: Int) {
        selectedVersionIndex = index
        resetSelectionForVersion()
    }

    func selectBook(_ index: Int) {
        selectedBookIndex = index
        selectedChapter = 1
        selectedVerse = nil
        chapterPage = 0
        versePage = 0
        quickJumpText = "1"
    }

    func resetSelectionForVersion() {
        selectedBookIndex = 1
        selectedChapter = 1
        selectedVerse = nil
        chapterPage = 0
        versePage = 0
        quickJumpText = "1"
    }

    func jumpToChapter() {
        let total = bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0
        guard let chapter = Int(quickJumpText), chapter > 0, chapter <= total else { return }
        selectedChapter = chapter
        selectedVerse = nil
        chapterPage = (chapter - 1) / chapterPageSize
        versePage = 0
    }

    func applySearchQuery() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            lastSearchFeedback = ""
            return
        }

        if let selection = bibleManager?.resolveReferenceSelection(in: query, preferredVersionIndex: selectedVersionIndex) {
            selectVersion(selection.versionIndex)
            selectBook(selection.bookIndex)
            selectChapter(selection.chapter)
            if let verse = selection.verse {
                selectVerse(verse)
                projectVerse(verse)
                lastSearchFeedback = "Referencia encontrada: \(selection.reference)"
            } else {
                lastSearchFeedback = "Capítulo cargado: \(selection.reference)"
            }
            return
        }

        let searchResults = bibleManager?.searchVerses(query: query, at: selectedVersionIndex, limit: 1) ?? []
        if let first = searchResults.first {
            selectBook(first.bookIndex)
            selectChapter(first.chapter)
            selectVerse(first.verse)
            projectVerse(first.verse)
            lastSearchFeedback = "Coincidencia encontrada: \(first.bookName) \(first.chapter):\(first.verse)"
            return
        }

        lastSearchFeedback = "Sin coincidencia exacta. Mostrando libros filtrados."
    }

    func syncPagesForVerse(_ number: Int) {
        guard number > 0 else { return }
        versePage = (number - 1) / versePageSize
    }

    func selectVerse(_ number: Int) {
        selectedVerse = number
        syncPagesForVerse(number)
    }

    func selectChapter(_ number: Int) {
        selectedChapter = number
        selectedVerse = nil
        versePage = 0
        quickJumpText = "\(number)"
    }

    func moveChapterPageForward() {
        chapterPage = min(chapterPage + 1, chapterPageCount - 1)
    }

    func moveChapterPageBackward() {
        chapterPage = max(chapterPage - 1, 0)
    }

    func moveVersePageForward() {
        versePage = min(versePage + 1, versePageCount - 1)
    }

    func moveVersePageBackward() {
        versePage = max(versePage - 1, 0)
    }

    func handleProjectionAdvance(step: Int) {
        guard !currentBooks.isEmpty else { return }
        let baseVerse = selectedVerse ?? displayManager?.currentProjection.flatMap(extractProjectedVerse) ?? 1

        let nextVerse = baseVerse + step

        if nextVerse > currentVerses.count {
            // Advance to next chapter or next book
            let chapterTotal = bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0
            if selectedChapter < chapterTotal {
                // Next chapter, verse 1
                let nextChapter = selectedChapter + 1
                selectChapter(nextChapter)
                chapterPage = (nextChapter - 1) / chapterPageSize
                selectedVerse = 1
                versePage = 0
                projectVerse(1)
            } else if selectedBookIndex < currentBooks.count {
                // Next book, chapter 1, verse 1
                selectBook(selectedBookIndex + 1)
                selectedVerse = 1
                projectVerse(1)
            }
            // else: already at last verse of last chapter of last book - do nothing
        } else if nextVerse < 1 {
            // Retreat to previous chapter or previous book
            if selectedChapter > 1 {
                // Previous chapter, last verse
                let prevChapter = selectedChapter - 1
                selectChapter(prevChapter)
                chapterPage = (prevChapter - 1) / chapterPageSize
                let lastVerse = currentVerses.count
                selectedVerse = lastVerse
                syncPagesForVerse(lastVerse)
                projectVerse(lastVerse)
            } else if selectedBookIndex > 1 {
                // Previous book, last chapter, last verse
                selectBook(selectedBookIndex - 1)
                let chapterTotal = bibleManager?.chapterCount(at: selectedVersionIndex, bookIndex: selectedBookIndex) ?? 0
                if chapterTotal > 0 {
                    let lastChapter = chapterTotal
                    selectChapter(lastChapter)
                    chapterPage = (lastChapter - 1) / chapterPageSize
                    let lastVerse = currentVerses.count
                    selectedVerse = lastVerse
                    syncPagesForVerse(lastVerse)
                    projectVerse(lastVerse)
                }
            }
            // else: already at first verse of first chapter of first book - do nothing
        } else {
            // Normal navigation within the same chapter
            selectedVerse = nextVerse
            syncPagesForVerse(nextVerse)
            projectVerse(nextVerse)
        }
    }

    func isProjectedVerse(_ number: Int) -> Bool {
        projectedSourceKey == bibleProjectionKey(for: number)
    }

    func bibleProjectionKey(for verse: Int) -> String {
        "bible:\(selectedVersionIndex):\(selectedBookIndex):\(selectedChapter):\(verse)"
    }

    func projectVerse(_ verseNumber: Int) {
        guard
            let displayManager,
            let text = bibleManager?.verseText(at: selectedVersionIndex, bookIndex: selectedBookIndex, chapter: selectedChapter, verse: verseNumber)
        else { return }
        let bookShort = selectedBookIndex > 0 && selectedBookIndex <= bookNames.count ? bookNames[selectedBookIndex - 1] : ""
        let bookFull = selectedBookIndex > 0 && selectedBookIndex <= fullBookNames.count ? fullBookNames[selectedBookIndex - 1] : bookShort
        let versionSuffix = displayManager.bibleProjectionSettings.showsVersionInReference
            ? " (\(currentVersion?.title ?? "VERS 1"))"
            : ""
        displayManager.project(
            source: bibleProjectionKey(for: verseNumber),
            reference: "\(bookFull) \(selectedChapter):\(verseNumber)\(versionSuffix)",
            body: text
        )
    }

    func toggleFavorite(for verseNumber: Int) {
        if let existingIndex = favorites.firstIndex(where: {
            $0.id == favoriteID(
                versionIndex: selectedVersionIndex,
                bookIndex: selectedBookIndex,
                chapter: selectedChapter,
                verse: verseNumber
            )
        }) {
            favorites.remove(at: existingIndex)
            persistFavorites()
            return
        }

        guard let verseText = currentVerses.first(where: { $0.number == verseNumber })?.text else { return }
        let favorite = BibleFavorite(
            id: favoriteID(
                versionIndex: selectedVersionIndex,
                bookIndex: selectedBookIndex,
                chapter: selectedChapter,
                verse: verseNumber
            ),
            versionIndex: selectedVersionIndex,
            versionTitle: currentVersion?.title ?? "VERS 1",
            bookIndex: selectedBookIndex,
            bookName: selectedBookIndex > 0 && selectedBookIndex <= fullBookNames.count ? fullBookNames[selectedBookIndex - 1] : "Biblia",
            chapter: selectedChapter,
            verse: verseNumber,
            verseText: verseText
        )
        favorites.append(favorite)
        persistFavorites()
    }

    func projectFavorite(_ favorite: BibleFavorite) {
        selectVersion(favorite.versionIndex)
        selectBook(favorite.bookIndex)
        selectChapter(favorite.chapter)
        selectVerse(favorite.verse)
        projectVerse(favorite.verse)
    }

    func selectFavorite(_ favorite: BibleFavorite) {
        selectVersion(favorite.versionIndex)
        selectBook(favorite.bookIndex)
        selectChapter(favorite.chapter)
        selectVerse(favorite.verse)
    }

    func removeFavorite(_ favorite: BibleFavorite) {
        favorites.removeAll { $0.id == favorite.id }
        persistFavorites()
    }

    func extractProjectedVerse(from payload: ProjectionPayload) -> Int? {
        guard payload.source.hasPrefix("bible:") else { return nil }
        return Int(payload.source.split(separator: ":").last ?? "")
    }

    func pagedItems(total: Int, page: Int, pageSize: Int) -> [PageItem] {
        guard total > 0 else { return [] }
        guard total > pageSize else { return (1...total).map(PageItem.number) }

        let start = page * pageSize + 1
        let end = min(start + pageSize - 1, total)
        var items: [PageItem] = []

        if page > 0 {
            items.append(.prev)
        }
        items.append(contentsOf: (start...end).map(PageItem.number))
        if end < total {
            items.append(.next)
        }
        return items
    }

    private func favoriteID(versionIndex: Int, bookIndex: Int, chapter: Int, verse: Int) -> String {
        "\(versionIndex):\(bookIndex):\(chapter):\(verse)"
    }

    private func persistFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        try? data.write(to: favoritesStorageURL, options: .atomic)
    }

    private static func loadFavorites(from url: URL) -> [BibleFavorite] {
        guard
            let data = try? Data(contentsOf: url),
            let favorites = try? JSONDecoder().decode([BibleFavorite].self, from: data)
        else {
            return []
        }
        return favorites
    }

}

private extension BibleReferenceSelection {
    var verseMatch: BibleReferenceMatch? {
        guard let verse, let verseText else { return nil }
        return BibleReferenceMatch(
            versionIndex: versionIndex,
            versionTitle: versionTitle,
            bookIndex: bookIndex,
            bookName: bookName,
            chapter: chapter,
            verse: verse,
            verseText: verseText
        )
    }
}

private final class BibleXMLParser: NSObject, XMLParserDelegate {
    nonisolated(unsafe) private var books: [BibleBook] = []
    nonisolated(unsafe) private var currentBook: BibleBook?
    nonisolated(unsafe) private var currentChapter: Chapter?
    nonisolated(unsafe) private var currentVerseNumber: Int = 0
    nonisolated(unsafe) private var currentVerseText: String = ""

    static func parse(url: URL) async throws -> [BibleBook] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let parser = XMLParser(contentsOf: url) else {
                        throw NSError(domain: "BibleXMLParser", code: 1)
                    }

                    let delegate = BibleXMLParser()
                    parser.delegate = delegate

                    if parser.parse() {
                        continuation.resume(returning: delegate.books)
                    } else {
                        continuation.resume(throwing: parser.parserError ?? NSError(domain: "BibleXMLParser", code: 2))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    nonisolated func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "BIBLEBOOK" {
            let number = Int(attributeDict["bnumber"] ?? "0") ?? 0
            let name = attributeDict["bname"] ?? "Desconocido"
            currentBook = BibleBook(number: number, name: name, chapters: [])
        } else if elementName == "CHAPTER" {
            let number = Int(attributeDict["cnumber"] ?? "0") ?? 0
            currentChapter = Chapter(number: number, verses: [])
        } else if elementName == "VERS" {
            currentVerseNumber = Int(attributeDict["vnumber"] ?? "0") ?? 0
            currentVerseText = ""
        }
    }

    nonisolated func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentVerseText += string
    }

    nonisolated func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "VERS" {
            let cleanText = currentVerseText.trimmingCharacters(in: .whitespacesAndNewlines)
            currentChapter?.verses.append(Verse(number: currentVerseNumber, text: cleanText))
        } else if elementName == "CHAPTER" {
            if let chapter = currentChapter {
                currentBook?.chapters.append(chapter)
            }
            currentChapter = nil
        } else if elementName == "BIBLEBOOK" {
            if let book = currentBook {
                books.append(book)
            }
            currentBook = nil
        }
    }
}
