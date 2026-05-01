import Foundation

protocol WorshipRepository {
    func loadSongs() -> [WorshipSong]
    func saveSongs(_ songs: [WorshipSong]) throws
}

struct LocalWorshipRepository: WorshipRepository {
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let storageURL: URL

    init(storageRootURL: URL? = nil) {
        let root: URL
        if let storageRootURL {
            root = storageRootURL
        } else {
            let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            root = applicationSupport
                .appendingPathComponent("SkyPresenterPro", isDirectory: true)
                .appendingPathComponent("Worship", isDirectory: true)
        }

        storageURL = root.appendingPathComponent("songs.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? prepareStorage()
        try? seedIfNeeded()
    }

    func loadSongs() -> [WorshipSong] {
        guard let data = try? Data(contentsOf: storageURL),
              let songs = try? decoder.decode([WorshipSong].self, from: data) else {
            return MockWorshipRepository().loadSongs()
        }
        return songs
    }

    func saveSongs(_ songs: [WorshipSong]) throws {
        try prepareStorage()
        let data = try encoder.encode(songs)
        try data.write(to: storageURL, options: .atomic)
    }

    private func prepareStorage() throws {
        try fileManager.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    private func seedIfNeeded() throws {
        guard !fileManager.fileExists(atPath: storageURL.path) else { return }
        try saveSongs(MockWorshipRepository().loadSongs())
    }
}

struct MockWorshipRepository: WorshipRepository {
    func loadSongs() -> [WorshipSong] {
        let raw = """
        ABRE MIS OJOS OH CRISTO
        ABRE MIS OJOS TE PIDO

        YO QUIERO VERTE
        YO QUIERO VERTE

        || Coro
        SANTO, SANTO, SANTO
        """

        let sections = WorshipEditorParser.parse(
            title: "ABRE MIS OJOS OH CRISTO",
            artist: "Ministerio",
            rawText: raw
        )

        return [
            WorshipSong(
                title: "ABRE MIS OJOS OH CRISTO",
                artist: "Ministerio",
                rawText: raw,
                sections: sections
            )
        ]
    }

    func saveSongs(_ songs: [WorshipSong]) throws {
    }
}
