import Foundation

// MARK: - Worship Engine Data Layer (Phase 1)

enum WorshipSectionTag: String, Codable, CaseIterable, Hashable {
    case verse = "Verso"
    case chorus = "Coro"
    case bridge = "Puente"
    case intro = "Intro"
    case outro = "Outro"
    case custom = "Custom"

    static func infer(from text: String) -> WorshipSectionTag {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.contains("verso") { return .verse }
        if lower.contains("coro") { return .chorus }
        if lower.contains("puente") { return .bridge }
        if lower.contains("intro") { return .intro }
        if lower.contains("outro") || lower.contains("final") { return .outro }
        return .custom
    }
}

struct WorshipChordMetadata: Codable, Hashable {
    var originalKey: String
    var bpm: Int?
    var chordLineHints: [String]

    init(originalKey: String = "", bpm: Int? = nil, chordLineHints: [String] = []) {
        self.originalKey = originalKey
        self.bpm = bpm
        self.chordLineHints = chordLineHints
    }
}

struct WorshipSongRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var author: String
    var lyrics: String
    var tags: [WorshipSectionTag]
    var searchTags: [String]
    var chordMetadata: WorshipChordMetadata
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "",
        author: String = "",
        lyrics: String,
        tags: [WorshipSectionTag] = [],
        searchTags: [String] = [],
        chordMetadata: WorshipChordMetadata = WorshipChordMetadata(),
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.author = author
        self.lyrics = lyrics
        self.tags = tags
        self.searchTags = searchTags
        self.chordMetadata = chordMetadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct WorshipSongDatabase: Codable {
    var schemaVersion: Int
    var updatedAt: Date
    var songs: [WorshipSongRecord]

    init(schemaVersion: Int = 1, updatedAt: Date = .now, songs: [WorshipSongRecord] = []) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.songs = songs
    }
}

enum WorshipSongDatabaseStore {
    static func load(from url: URL) -> WorshipSongDatabase? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WorshipSongDatabase.self, from: data)
    }

    static func save(_ database: WorshipSongDatabase, to url: URL) {
        guard let data = try? JSONEncoder().encode(database) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

// MARK: - Lyrics Processor (Phase 1)

struct WorshipSlideChunk: Hashable {
    var title: String
    var rawLines: [String]
    var publicLines: [String]
    var sideNotes: [String]
}

enum WorshipLyricsProcessor {
    static func splitEditableSlides(
        from text: String,
        maxVisibleLinesPerSlide: Int = 4
    ) -> [String] {
        let chunks = splitIntoChunks(from: text, maxVisibleLinesPerSlide: maxVisibleLinesPerSlide)
        let values = chunks.map { $0.rawLines.joined(separator: "\n").trimmingCharacters(in: .newlines) }
        return values.isEmpty ? [""] : values
    }

    static func splitIntoChunks(
        from text: String,
        maxVisibleLinesPerSlide: Int = 4
    ) -> [WorshipSlideChunk] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        var chunks: [WorshipSlideChunk] = []
        var currentRaw: [String] = []
        var currentPublic: [String] = []
        var currentNotes: [String] = []
        var activeTitle: String = ""

        func flushCurrent() {
            guard !currentRaw.isEmpty || !currentPublic.isEmpty || !currentNotes.isEmpty else { return }
            chunks.append(
                WorshipSlideChunk(
                    title: activeTitle,
                    rawLines: currentRaw,
                    publicLines: currentPublic,
                    sideNotes: currentNotes
                )
            )
            currentRaw.removeAll(keepingCapacity: true)
            currentPublic.removeAll(keepingCapacity: true)
            currentNotes.removeAll(keepingCapacity: true)
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isEmpty = trimmed.isEmpty

            if isEmpty {
                flushCurrent()
                continue
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let sectionTitle = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sectionTitle.isEmpty {
                    activeTitle = sectionTitle
                }
                continue
            }

            if trimmed.hasPrefix("//") {
                currentRaw.append(trimmed)
                let note = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !note.isEmpty { currentNotes.append(note) }
                continue
            }

            if currentPublic.count >= maxVisibleLinesPerSlide {
                flushCurrent()
            }

            currentRaw.append(trimmed)
            currentPublic.append(trimmed)
        }

        flushCurrent()
        return mergeShortTailChunks(chunks, maxVisibleLinesPerSlide: maxVisibleLinesPerSlide)
    }

    static func removeAccents(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "es"))
    }

    static func normalizeForSearch(_ text: String) -> String {
        removeAccents(text)
            .uppercased(with: Locale(identifier: "es"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizeProjectionText(_ text: String) -> String {
        normalizeForSearch(text)
    }

    private static func mergeShortTailChunks(_ chunks: [WorshipSlideChunk], maxVisibleLinesPerSlide: Int) -> [WorshipSlideChunk] {
        guard chunks.count > 1 else { return chunks }
        var mutable = chunks
        guard let last = mutable.last, last.publicLines.count == 1 else { return mutable }
        let previousIndex = mutable.count - 2
        guard mutable[previousIndex].publicLines.count < maxVisibleLinesPerSlide else { return mutable }

        var previous = mutable[previousIndex]
        previous.rawLines.append(contentsOf: last.rawLines)
        previous.publicLines.append(contentsOf: last.publicLines)
        previous.sideNotes.append(contentsOf: last.sideNotes)
        mutable[previousIndex] = previous
        mutable.removeLast()
        return mutable
    }
}

