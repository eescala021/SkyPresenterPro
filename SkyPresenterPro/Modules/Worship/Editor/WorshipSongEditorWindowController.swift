import AppKit
import SwiftUI

@MainActor
final class WorshipSongEditorWindowController: NSWindowController {
    static let shared = WorshipSongEditorWindowController()

    private let editorViewModel = WorshipSongEditorViewModel()
    private var hostingView: NSHostingView<WorshipSongEditorWindow>?

    private init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show(
        for worshipViewModel: WorshipViewModel,
        themeResolver: ThemeResolver,
        themeManager: ThemeManager,
        mediaLibraryManager: MediaLibraryManager,
        externalDisplayManager: ExternalDisplayManager
    ) {
        guard let song = worshipViewModel.selectedSong else { return }

        prepareWindowIfNeeded(
            themeResolver: themeResolver,
            themeManager: themeManager,
            mediaLibraryManager: mediaLibraryManager,
            externalDisplayManager: externalDisplayManager
        )

        editorViewModel.configure(
            song: song,
            worshipViewModel: worshipViewModel,
            themeResolver: themeResolver,
            themeManager: themeManager,
            mediaLibraryManager: mediaLibraryManager,
            closeHandler: { [weak self] in
                self?.close()
            }
        )

        showWindow(nil)
        window?.title = "Editor PRO · \(song.title)"
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func prepareWindowIfNeeded(
        themeResolver: ThemeResolver,
        themeManager: ThemeManager,
        mediaLibraryManager: MediaLibraryManager,
        externalDisplayManager: ExternalDisplayManager
    ) {
        guard window == nil else { return }

        let contentView = WorshipSongEditorWindow(viewModel: editorViewModel)
            .environmentObject(themeResolver)
            .environmentObject(themeManager)
            .environmentObject(mediaLibraryManager)
            .environmentObject(externalDisplayManager)

        let hostingView = NSHostingView(rootView: contentView)
        self.hostingView = hostingView

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1320, height: 860),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Editor PRO de Alabanzas"
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.setFrameAutosaveName("WorshipSongEditorWindow")
        panel.contentView = hostingView
        panel.minSize = NSSize(width: 1120, height: 760)
        panel.center()
        self.window = panel
    }

    override func close() {
        if editorViewModel.requestClose() {
            super.close()
        }
    }
}

@MainActor
final class WorshipSongEditorViewModel: ObservableObject {
    @Published var draft: WorshipSongEditorDraft?
    @Published private(set) var slides: [WorshipSongEditorPreviewSlide] = []
    @Published var selectedSlideID: UUID?
    @Published var message: String = ""
    @Published var isErrorMessage = false

    private weak var worshipViewModel: WorshipViewModel?
    private weak var themeResolver: ThemeResolver?
    private weak var themeManager: ThemeManager?
    private weak var mediaLibraryManager: MediaLibraryManager?
    private var closeHandler: (() -> Void)?
    private var originalSongSignature = ""
    private var originalSongThemeID: UUID?
    private var originalSongBackgroundID: UUID?
    private var originalSectionThemeIDs: [UUID: UUID] = [:]
    private var originalSectionBackgroundIDs: [UUID: UUID] = [:]

    var canSave: Bool {
        guard let draft else { return false }
        return !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !slides.isEmpty
    }

    var availableThemes: [ProjectionTheme] {
        themeManager?.themes(for: .worship) ?? []
    }

    var availableBackgrounds: [MediaLibraryItem] {
        let manager = mediaLibraryManager
        return (manager?.imageItems ?? []) + (manager?.videoItems ?? [])
    }

    func configure(
        song: WorshipSong,
        worshipViewModel: WorshipViewModel,
        themeResolver: ThemeResolver,
        themeManager: ThemeManager,
        mediaLibraryManager: MediaLibraryManager,
        closeHandler: @escaping () -> Void
    ) {
        self.worshipViewModel = worshipViewModel
        self.themeResolver = themeResolver
        self.themeManager = themeManager
        self.mediaLibraryManager = mediaLibraryManager
        self.closeHandler = closeHandler

        originalSongSignature = Self.signature(for: song)
        originalSongThemeID = themeResolver.theme(for: .song(song.id), source: .worship, songID: song.id).id
        originalSongBackgroundID = mediaLibraryManager.backgroundItem(for: .worship, songID: song.id)?.id
        originalSectionThemeIDs = Dictionary(uniqueKeysWithValues: song.sections.map { ($0.id, themeResolver.theme(for: .section($0.id), source: .worship, songID: song.id, sectionID: $0.id).id) })
        originalSectionBackgroundIDs = Dictionary(uniqueKeysWithValues: song.sections.compactMap { section in
            mediaLibraryManager.backgroundItem(for: .worship, songID: song.id, sectionID: section.id).map { (section.id, $0.id) }
        })

        var draft = WorshipSongEditorDraft(song: song, selectedThemeID: originalSongThemeID)
        for (index, section) in song.sections.enumerated() {
            if let backgroundID = originalSectionBackgroundIDs[section.id] {
                draft.slideBackgroundItemIDs[index] = backgroundID
            }
        }

        self.draft = draft
        regenerateSlides()
        message = "Editor listo."
        isErrorMessage = false
    }

    func updateTitle(_ value: String) {
        draft?.title = value
        objectWillChange.send()
    }

    func updateArtist(_ value: String) {
        draft?.artist = value
        objectWillChange.send()
    }

    func updateNote(_ value: String) {
        draft?.note = value
        objectWillChange.send()
    }

    func updateAuthor(_ value: String) {
        draft?.author = value
        objectWillChange.send()
    }

    func updateCopyright(_ value: String) {
        draft?.copyright = value
        objectWillChange.send()
    }

    func updateRawText(_ value: String) {
        let normalized = WorshipSongEditorService.normalizeEditableText(value)
        guard draft?.rawText != normalized else { return }
        draft?.rawText = normalized
        regenerateSlides()
    }

    func selectSlide(_ slide: WorshipSongEditorPreviewSlide) {
        selectedSlideID = slide.id
    }

    func selectTheme(_ theme: ProjectionTheme?) {
        draft?.selectedThemeID = theme?.id
        objectWillChange.send()
    }

    func applyBackground(_ item: MediaLibraryItem?, to slide: WorshipSongEditorPreviewSlide) {
        draft?.slideBackgroundItemIDs[slide.sectionIndex] = item?.id
        objectWillChange.send()
    }

    func clearBackground(for slide: WorshipSongEditorPreviewSlide) {
        draft?.slideBackgroundItemIDs.removeValue(forKey: slide.sectionIndex)
        objectWillChange.send()
    }

    func applyBackgroundToAll(_ item: MediaLibraryItem?) {
        guard let draft else { return }
        var updated = draft.slideBackgroundItemIDs
        for slide in slides {
            updated[slide.sectionIndex] = item?.id
        }
        self.draft?.slideBackgroundItemIDs = updated
        objectWillChange.send()
    }

    func save() {
        guard
            let draft,
            let worshipViewModel,
            let themeResolver,
            let mediaLibraryManager,
            let selectedTheme = availableThemes.first(where: { $0.id == draft.selectedThemeID }) ?? availableThemes.first,
            let songIndex = worshipViewModel.songs.firstIndex(where: { $0.id == draft.songID })
        else {
            return
        }

        let sections = WorshipSongEditorService.buildSections(from: draft.rawText)
        guard !sections.isEmpty else {
            message = "No hay diapositivas válidas para guardar."
            isErrorMessage = true
            return
        }

        worshipViewModel.songs[songIndex].title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        worshipViewModel.songs[songIndex].artist = draft.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        worshipViewModel.songs[songIndex].note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        worshipViewModel.songs[songIndex].author = draft.author.trimmingCharacters(in: .whitespacesAndNewlines)
        worshipViewModel.songs[songIndex].copyright = draft.copyright.trimmingCharacters(in: .whitespacesAndNewlines)
        worshipViewModel.songs[songIndex].rawText = draft.rawText
        worshipViewModel.songs[songIndex].sections = sections

        if let selectedTheme {
            themeResolver.setTheme(selectedTheme, forSong: draft.songID)
        }

        for existingSectionID in originalSectionThemeIDs.keys {
            themeResolver.clearSectionTheme(existingSectionID)
        }

        for existingSectionID in originalSectionBackgroundIDs.keys {
            mediaLibraryManager.setBackground(nil, forSection: existingSectionID)
        }

        for (index, section) in sections.enumerated() {
            if let backgroundID = draft.slideBackgroundItemIDs[index],
               let item = availableBackgrounds.first(where: { $0.id == backgroundID }) {
                mediaLibraryManager.setBackground(item, forSection: section.id)
            }
        }

        worshipViewModel.selectSong(worshipViewModel.songs[songIndex])
        worshipViewModel.rebuildSelectedSongFromEditor()
        originalSongSignature = Self.signature(for: worshipViewModel.songs[songIndex])
        message = "Canción guardada correctamente."
        isErrorMessage = false
    }

    func cancel() {
        closeHandler?()
    }

    func requestClose() -> Bool {
        guard hasUnsavedChanges else { return true }
        let alert = NSAlert()
        alert.messageText = "Cerrar editor"
        alert.informativeText = "Hay cambios sin guardar. Puedes guardar antes de cerrar o descartar los cambios."
        alert.addButton(withTitle: "Guardar")
        alert.addButton(withTitle: "Descartar")
        alert.addButton(withTitle: "Cancelar")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            save()
            return !isErrorMessage
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    func previewSlide(for slide: WorshipSongEditorPreviewSlide) -> ProjectionSlide {
        ProjectionSlide(lines: slide.lines, notes: draft?.note.isEmpty == false ? [draft?.note ?? ""] : [])
    }

    func previewTheme(for slide: WorshipSongEditorPreviewSlide) -> ProjectionTheme? {
        guard let draft, let selectedThemeID = draft.selectedThemeID else { return nil }
        return availableThemes.first(where: { $0.id == selectedThemeID })
    }

    func previewBackground(for slide: WorshipSongEditorPreviewSlide) -> MediaLibraryItem? {
        guard let itemID = draft?.slideBackgroundItemIDs[slide.sectionIndex] else { return nil }
        return availableBackgrounds.first(where: { $0.id == itemID })
    }

    private var hasUnsavedChanges: Bool {
        guard let draft else { return false }
        let song = WorshipSong(
            id: draft.songID,
            title: draft.title,
            artist: draft.artist,
            note: draft.note,
            author: draft.author,
            copyright: draft.copyright,
            rawText: draft.rawText,
            sections: WorshipSongEditorService.buildSections(from: draft.rawText)
        )
        return Self.signature(for: song) != originalSongSignature
    }

    private func regenerateSlides() {
        guard let rawText = draft?.rawText else {
            slides = []
            return
        }
        slides = WorshipSongEditorService.generateSlides(from: rawText)
        selectedSlideID = slides.first?.id
        message = slides.isEmpty ? "Sin diapositivas detectadas." : "\(slides.count) diapositivas generadas."
        isErrorMessage = slides.isEmpty
    }

    private static func signature(for song: WorshipSong) -> String {
        [
            song.title,
            song.artist,
            song.note,
            song.author,
            song.copyright,
            song.rawText,
            song.sections.map(\.title).joined(separator: "|"),
            song.sections.flatMap(\.lines).joined(separator: "|")
        ].joined(separator: "||")
    }
}
