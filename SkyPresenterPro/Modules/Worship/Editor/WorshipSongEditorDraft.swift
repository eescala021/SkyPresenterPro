import Foundation

struct WorshipSongEditorPreviewSlide: Identifiable, Equatable {
    let id: UUID
    let sectionIndex: Int
    let sectionTitle: String
    let lines: [String]
}

struct WorshipSongEditorDraft {
    var songID: UUID
    var title: String
    var artist: String
    var note: String
    var author: String
    var copyright: String
    var rawText: String
    var selectedThemeID: UUID?
    var slideBackgroundItemIDs: [Int: UUID]

    init(song: WorshipSong, selectedThemeID: UUID? = nil) {
        songID = song.id
        title = song.title
        artist = song.artist
        note = song.note
        author = song.author
        copyright = song.copyright
        rawText = song.rawText
        self.selectedThemeID = selectedThemeID
        slideBackgroundItemIDs = [:]
    }
}
