import Foundation
import SQLite3

struct BibleBookMetadata: Hashable {
    let number: Int
    let name: String
}

final class BibleSQLiteStore {
    private let directoryURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func databaseURL(for slotIndex: Int) -> URL {
        directoryURL.appendingPathComponent("bible-slot-\(slotIndex).sqlite")
    }

    func buildDatabase(for slotIndex: Int, books: [BibleBook]) throws -> URL {
        try buildDatabase(at: databaseURL(for: slotIndex), books: books)
    }

    func buildDatabase(named fileName: String, books: [BibleBook]) throws -> URL {
        try buildDatabase(at: directoryURL.appendingPathComponent("\(fileName).sqlite"), books: books)
    }

    private func buildDatabase(at url: URL, books: [BibleBook]) throws -> URL {
        try? FileManager.default.removeItem(at: url)

        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            defer { sqlite3_close(db) }
            throw NSError(domain: "BibleSQLiteStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo abrir la base de datos bíblica."])
        }
        defer { sqlite3_close(db) }

        try execute(
            """
            PRAGMA journal_mode=WAL;
            PRAGMA synchronous=NORMAL;
            CREATE TABLE IF NOT EXISTS books (
                number INTEGER PRIMARY KEY,
                name TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS chapters (
                book_number INTEGER NOT NULL,
                chapter INTEGER NOT NULL,
                verse_count INTEGER NOT NULL,
                PRIMARY KEY(book_number, chapter)
            );
            CREATE TABLE IF NOT EXISTS verses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                book_number INTEGER NOT NULL,
                book_name TEXT NOT NULL,
                chapter INTEGER NOT NULL,
                verse INTEGER NOT NULL,
                text TEXT NOT NULL,
                normalized_text TEXT NOT NULL
            );
            CREATE UNIQUE INDEX IF NOT EXISTS idx_verses_reference
            ON verses(book_number, chapter, verse);
            CREATE INDEX IF NOT EXISTS idx_chapters_book
            ON chapters(book_number, chapter);
            CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts
            USING fts5(book_name, text, normalized_text, content='', tokenize='unicode61 remove_diacritics 2');
            """,
            db: db
        )

        try execute("BEGIN IMMEDIATE TRANSACTION;", db: db)
        defer { sqlite3_exec(db, "COMMIT;", nil, nil, nil) }

        let insertBook = try prepare("INSERT INTO books(number, name) VALUES (?, ?);", db: db)
        let insertChapter = try prepare("INSERT INTO chapters(book_number, chapter, verse_count) VALUES (?, ?, ?);", db: db)
        let insertVerse = try prepare("INSERT INTO verses(book_number, book_name, chapter, verse, text, normalized_text) VALUES (?, ?, ?, ?, ?, ?);", db: db)
        let insertFTS = try prepare("INSERT INTO verses_fts(rowid, book_name, text, normalized_text) VALUES (?, ?, ?, ?);", db: db)
        defer {
            sqlite3_finalize(insertBook)
            sqlite3_finalize(insertChapter)
            sqlite3_finalize(insertVerse)
            sqlite3_finalize(insertFTS)
        }

        for book in books {
            bindAndStep(insertBook) { stmt in
                sqlite3_bind_int(stmt, 1, Int32(book.number))
                sqlite3_bind_text(stmt, 2, (book.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            }

            for chapter in book.chapters {
                bindAndStep(insertChapter) { stmt in
                    sqlite3_bind_int(stmt, 1, Int32(book.number))
                    sqlite3_bind_int(stmt, 2, Int32(chapter.number))
                    sqlite3_bind_int(stmt, 3, Int32(chapter.verses.count))
                }

                for verse in chapter.verses {
                    let normalized = Self.normalizeSearchText(verse.text)
                    bindAndStep(insertVerse) { stmt in
                        sqlite3_bind_int(stmt, 1, Int32(book.number))
                        sqlite3_bind_text(stmt, 2, (book.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_int(stmt, 3, Int32(chapter.number))
                        sqlite3_bind_int(stmt, 4, Int32(verse.number))
                        sqlite3_bind_text(stmt, 5, (verse.text as NSString).utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_text(stmt, 6, (normalized as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    }

                    let rowID = sqlite3_last_insert_rowid(db)
                    bindAndStep(insertFTS) { stmt in
                        sqlite3_bind_int64(stmt, 1, rowID)
                        sqlite3_bind_text(stmt, 2, (book.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_text(stmt, 3, (verse.text as NSString).utf8String, -1, SQLITE_TRANSIENT)
                        sqlite3_bind_text(stmt, 4, (normalized as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    }
                }
            }
        }

        return url
    }

    func books(at url: URL) -> [BibleBookMetadata] {
        query(url: url, sql: "SELECT number, name FROM books ORDER BY number;") { stmt in
            BibleBookMetadata(
                number: Int(sqlite3_column_int(stmt, 0)),
                name: Self.string(from: stmt, column: 1)
            )
        }
    }

    func chapterCount(at url: URL, bookNumber: Int) -> Int {
        scalarInt(url: url, sql: "SELECT COUNT(*) FROM chapters WHERE book_number = ?;", bindings: [bookNumber])
    }

    func verseCount(at url: URL, bookNumber: Int, chapter: Int) -> Int {
        scalarInt(url: url, sql: "SELECT verse_count FROM chapters WHERE book_number = ? AND chapter = ? LIMIT 1;", bindings: [bookNumber, chapter])
    }

    func verses(at url: URL, bookNumber: Int, chapter: Int) -> [Verse] {
        query(
            url: url,
            sql: "SELECT verse, text FROM verses WHERE book_number = ? AND chapter = ? ORDER BY verse;",
            bindings: [bookNumber, chapter]
        ) { stmt in
            Verse(
                number: Int(sqlite3_column_int(stmt, 0)),
                text: Self.string(from: stmt, column: 1)
            )
        }
    }

    func verseText(at url: URL, bookNumber: Int, chapter: Int, verse: Int) -> String? {
        scalarString(
            url: url,
            sql: "SELECT text FROM verses WHERE book_number = ? AND chapter = ? AND verse = ? LIMIT 1;",
            bindings: [bookNumber, chapter, verse]
        )
    }

    func search(query searchQuery: String, at url: URL, limit: Int = 20) -> [BibleSearchResult] {
        let normalized = Self.normalizeSearchText(searchQuery)
        guard !normalized.isEmpty else { return [] }
        return query(
            url: url,
            sql: """
            SELECT v.book_number, v.book_name, v.chapter, v.verse, v.text
            FROM verses_fts f
            JOIN verses v ON v.id = f.rowid
            WHERE verses_fts MATCH ?
            LIMIT ?;
            """,
            textBindings: [normalized, "\(max(limit, 1))"]
        ) { stmt in
            BibleSearchResult(
                bookIndex: Int(sqlite3_column_int(stmt, 0)),
                bookName: Self.string(from: stmt, column: 1),
                chapter: Int(sqlite3_column_int(stmt, 2)),
                verse: Int(sqlite3_column_int(stmt, 3)),
                verseText: Self.string(from: stmt, column: 4)
            )
        }
    }

    static func normalizeSearchText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es"))
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    struct BibleSearchResult: Hashable {
        let bookIndex: Int
        let bookName: String
        let chapter: Int
        let verse: Int
        let verseText: String
    }

    private func query<T>(url: URL, sql: String, bindings: [Int] = [], textBindings: [String] = [], map: (OpaquePointer) -> T) -> [T] {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            sqlite3_close(db)
            return []
        }
        defer { sqlite3_close(db) }
        guard let stmt = try? prepare(sql, db: db) else { return [] }
        defer { sqlite3_finalize(stmt) }
        bind(bindings, textBindings: textBindings, to: stmt)
        var items: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            items.append(map(stmt))
        }
        return items
    }

    private func scalarInt(url: URL, sql: String, bindings: [Int]) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            sqlite3_close(db)
            return 0
        }
        defer { sqlite3_close(db) }
        guard let stmt = try? prepare(sql, db: db) else { return 0 }
        defer { sqlite3_finalize(stmt) }
        bind(bindings, textBindings: [], to: stmt)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    private func scalarString(url: URL, sql: String, bindings: [Int]) -> String? {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }
        guard let stmt = try? prepare(sql, db: db) else { return nil }
        defer { sqlite3_finalize(stmt) }
        bind(bindings, textBindings: [], to: stmt)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return Self.string(from: stmt, column: 0)
    }

    private func execute(_ sql: String, db: OpaquePointer) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw NSError(domain: "BibleSQLiteStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo ejecutar SQL."])
        }
    }

    private func prepare(_ sql: String, db: OpaquePointer) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            throw NSError(domain: "BibleSQLiteStore", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo preparar SQL."])
        }
        return stmt
    }

    private func bind(_ bindings: [Int], textBindings: [String], to stmt: OpaquePointer) {
        var index: Int32 = 1
        for value in bindings {
            sqlite3_bind_int(stmt, index, Int32(value))
            index += 1
        }
        for value in textBindings {
            sqlite3_bind_text(stmt, index, (value as NSString).utf8String, -1, SQLITE_TRANSIENT)
            index += 1
        }
    }

    private func bindAndStep(_ stmt: OpaquePointer, binder: (OpaquePointer) -> Void) {
        sqlite3_reset(stmt)
        sqlite3_clear_bindings(stmt)
        binder(stmt)
        sqlite3_step(stmt)
    }

    private static func string(from stmt: OpaquePointer, column: Int32) -> String {
        guard let value = sqlite3_column_text(stmt, column) else { return "" }
        return String(cString: value)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
