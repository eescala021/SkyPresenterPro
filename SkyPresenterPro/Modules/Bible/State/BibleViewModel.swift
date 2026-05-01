import Combine
import SwiftUI

@MainActor
final class BibleViewModel: ObservableObject {
    private let repository: BibleRepository
    private let searchService = BibleSearchService()
    private let favoritesService = BibleFavoritesService()
    private let historyService = BibleHistoryService()
    private var projectionRouter: ProjectionCommandRouter?
    private var cancellables = Set<AnyCancellable>()

    @Published var books: [BibleBook] = []
    @Published var chapters: [BibleChapter] = []
    @Published var verses: [BibleVerse] = []
    @Published var chapterPageIndex: Int = 0
    @Published var versePageIndex: Int = 0
    @Published var filteredVerses: [BibleVerse] = []
    @Published var navigation = BibleNavigationState()
    @Published var searchText: String = ""
    @Published private(set) var favorites: [BibleReference] = []
    @Published private(set) var history: [BibleReference] = []
    @Published private(set) var availableVersions: [BibleVersionDescriptor] = []
    @Published private(set) var slotSelections: [BibleVersionSlot: String] = [:]
    @Published var selectedVerseRange: ClosedRange<Int>?

    private let selectedVersionsKey = "Bible.SelectedVersionSlots"

    init() {
        self.repository = MockBibleRepository()
        bindExternalState()
        loadAvailableVersions()
        loadBooks()
    }

    init(repository: BibleRepository) {
        self.repository = repository
        bindExternalState()
        loadAvailableVersions()
        loadBooks()
    }

    func loadMockBible() {
        loadAvailableVersions()
        loadBooks()
    }

    func loadBooks() {
        books = repository.loadBooks(versionID: primaryVersionID)
        if let resolvedBook = selectedBookFromCurrentCatalog() ?? books.first {
            selectBook(resolvedBook)
        } else {
            chapters = []
            verses = []
            filteredVerses = []
        }
    }

    func selectBook(_ book: BibleBook) {
        navigation.selectedBook = book
        chapters = repository.loadChapters(for: book, versionID: primaryVersionID)
        chapterPageIndex = 0

        if let matchingChapter = chapterMatchingSelection(in: chapters) ?? chapters.first {
            selectChapter(matchingChapter)
        } else {
            verses = []
            filteredVerses = []
            navigation.selectedVerse = nil
            selectedVerseRange = nil
        }
    }

    func selectChapter(_ chapter: BibleChapter) {
        guard let book = navigation.selectedBook else { return }

        navigation.selectedChapter = chapter
        navigation.lastInteractionAt = .now
        verses = repository.loadVerses(for: book, chapter: chapter, versionID: primaryVersionID)
        versePageIndex = 0
        applySearch()

        if let matchingVerse = verseMatchingSelection(in: displayedVerses(for: .primary)) {
            navigation.selectedVerse = matchingVerse
            selectedVerseRange = matchingVerse.number...matchingVerse.number
        } else {
            navigation.selectedVerse = nil
            selectedVerseRange = nil
        }

        if let reference = navigation.currentReference {
            historyService.add(reference)
        }

        let json = buildRemoteVersesJSON(verses: displayedVerses(for: .primary), book: book, chapter: chapter.number)
        RemoteCommandBus.shared.updateBibleVerses(bookName: book.name, chapter: chapter.number, json: json)
    }

    func selectVerse(_ verse: BibleVerse) {
        navigation.selectedVerse = verse
        selectedVerseRange = verse.number...verse.number
        navigation.lastInteractionAt = .now
    }

    func selectVersion(_ versionID: String, for slot: BibleVersionSlot) {
        slotSelections[slot] = versionID
        persistVersionSelections()
        reloadCurrentContext()
    }

    func importVersion(from url: URL) async -> Result<BibleVersionDescriptor, Error> {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let descriptor = try repository.importVersion(from: url)
            loadAvailableVersions()
            if slotSelections[.tertiary] == nil {
                slotSelections[.tertiary] = descriptor.id
                persistVersionSelections()
            }
            reloadCurrentContext()
            return .success(descriptor)
        } catch {
            return .failure(error)
        }
    }

    var chapterPageSize: Int { 50 }

    var versePageSize: Int { 40 }

    var pagedChapters: [BibleChapter] {
        pageSlice(from: chapters, pageIndex: chapterPageIndex, pageSize: chapterPageSize)
    }

    var chapterPageCount: Int {
        pageCount(for: chapters.count, pageSize: chapterPageSize)
    }

    var versePageCount: Int {
        pageCount(for: verses.count, pageSize: versePageSize)
    }

    var canGoToPreviousChapterPage: Bool {
        chapterPageIndex > 0
    }

    var canGoToNextChapterPage: Bool {
        chapterPageIndex < (chapterPageCount - 1)
    }

    func goToPreviousChapterPage() {
        guard canGoToPreviousChapterPage else { return }
        chapterPageIndex -= 1
    }

    func goToNextChapterPage() {
        guard canGoToNextChapterPage else { return }
        chapterPageIndex += 1
    }

    func applySearch() {
        filteredVerses = searchService.searchVerses(query: searchText, in: verses)
    }

    func updateSearch(_ text: String) {
        searchText = text
        applySearch()
    }

    func toggleFavorite() {
        guard let reference = navigation.currentReference else { return }
        favoritesService.toggle(reference)
    }

    func removeFavorite(_ reference: BibleReference) {
        favoritesService.remove(reference)
    }

    func clearFavorites() {
        favoritesService.clear()
    }

    func isFavorite() -> Bool {
        guard let reference = navigation.currentReference else { return false }
        return favoritesService.contains(reference)
    }

    func clearHistory() {
        historyService.clear()
    }

    func jump(to reference: BibleReference) {
        guard let book = books.first(where: { $0.name == reference.book || $0.shortName == reference.book }) else {
            return
        }

        selectBook(book)

        if let chapter = chapters.first(where: { $0.number == reference.chapter }) {
            selectChapter(chapter)
        }

        if let verseNumber = reference.verse,
           let verse = displayedVerses(for: .primary).first(where: { $0.number == verseNumber }) {
            selectVerse(verse)
        }
    }

    func buildProjectionSlides() -> [ProjectionSlide] {
        guard let reference = navigation.currentReference else { return [] }

        let versesToProject: [BibleVerse]
        if let selectedVerse = selectedVerseForSlot(.primary) {
            versesToProject = [selectedVerse]
        } else {
            versesToProject = displayedVerses(for: .primary)
        }

        return BibleProjectionBuilder.build(from: reference, verses: versesToProject)
    }

    func configureProjectionRouter(_ router: ProjectionCommandRouter) {
        projectionRouter = router
    }

    func projectCurrentSelection() {
        let slides = buildProjectionSlides()
        guard !slides.isEmpty else { return }
        navigation.lastProjectionRequestAt = .now
        projectionRouter?.project(slides: slides, source: .bible, startAt: 0)
    }

    func goToNextProjectedSlide() {
        projectionRouter?.goNext()
    }

    func goToPreviousProjectedSlide() {
        projectionRouter?.goPrevious()
    }

    func clearProjection() {
        projectionRouter?.clear()
    }

    var primaryVersionID: String {
        slotSelections[.primary] ?? availableVersions.first?.id ?? "rvr1960"
    }

    var versionContainers: [BibleVersionContainer] {
        BibleVersionSlot.allCases.map { slot in
            BibleVersionContainer(
                slot: slot,
                version: version(for: slot),
                verses: displayedVerses(for: slot)
            )
        }
    }

    func version(for slot: BibleVersionSlot) -> BibleVersionDescriptor? {
        guard let versionID = slotSelections[slot] else { return nil }
        return availableVersions.first(where: { $0.id == versionID })
    }

    func displayedVerses(for slot: BibleVersionSlot) -> [BibleVerse] {
        if slot == .primary {
            return filteredVerses.isEmpty ? verses : filteredVerses
        }

        guard let book = navigation.selectedBook,
              let chapter = navigation.selectedChapter,
              let versionID = slotSelections[slot] else {
            return []
        }

        let allVerses = repository.loadVerses(for: book, chapter: chapter, versionID: versionID)
        let numbers = Set((filteredVerses.isEmpty ? verses : filteredVerses).map(\.number))
        guard !numbers.isEmpty else { return allVerses }
        return allVerses.filter { numbers.contains($0.number) }
    }

    func selectedVerseForSlot(_ slot: BibleVersionSlot) -> BibleVerse? {
        guard let selectedNumber = navigation.selectedVerse?.number else { return nil }
        return displayedVerses(for: slot).first(where: { $0.number == selectedNumber })
    }

    func verseText(for verseNumber: Int, slot: BibleVersionSlot) -> String {
        displayedVerses(for: slot).first(where: { $0.number == verseNumber })?.text ?? "Sin versículo"
    }

    func selectPreviousVerse() {
        let verses = displayedVerses(for: .primary)
        guard !verses.isEmpty else { return }

        guard let currentVerse = navigation.selectedVerse,
              let currentIndex = verses.firstIndex(where: { $0.number == currentVerse.number }) else {
            selectVerse(verses[0])
            return
        }

        guard currentIndex > 0 else { return }
        selectVerse(verses[currentIndex - 1])
    }

    func selectNextVerse() {
        let verses = displayedVerses(for: .primary)
        guard !verses.isEmpty else { return }

        guard let currentVerse = navigation.selectedVerse,
              let currentIndex = verses.firstIndex(where: { $0.number == currentVerse.number }) else {
            selectVerse(verses[0])
            return
        }

        guard currentIndex + 1 < verses.count else { return }
        selectVerse(verses[currentIndex + 1])
    }

    private func bindExternalState() {
        favoritesService.$items
            .sink { [weak self] items in
                self?.favorites = items
            }
            .store(in: &cancellables)

        historyService.$items
            .sink { [weak self] items in
                self?.history = items
            }
            .store(in: &cancellables)
    }

    private func loadAvailableVersions() {
        availableVersions = repository.availableVersions()
        restoreVersionSelections()
    }

    private func restoreVersionSelections() {
        if let rawSelections = UserDefaults.standard.dictionary(forKey: selectedVersionsKey) as? [String: String] {
            slotSelections = rawSelections.reduce(into: [:]) { partialResult, item in
                guard let slot = BibleVersionSlot(rawValue: item.key) else { return }
                partialResult[slot] = item.value
            }
        }

        let defaults = availableVersions.map(\.id)
        guard !defaults.isEmpty else { return }
        if slotSelections[.primary] == nil {
            slotSelections[.primary] = defaults[safe: 0] ?? defaults[0]
        }
        if slotSelections[.secondary] == nil {
            slotSelections[.secondary] = defaults[safe: 1] ?? defaults[0]
        }
        if slotSelections[.tertiary] == nil {
            slotSelections[.tertiary] = defaults[safe: 2] ?? defaults[0]
        }
        persistVersionSelections()
    }

    private func persistVersionSelections() {
        let payload = slotSelections.reduce(into: [String: String]()) { partialResult, item in
            partialResult[item.key.rawValue] = item.value
        }
        UserDefaults.standard.set(payload, forKey: selectedVersionsKey)
    }

    private func reloadCurrentContext() {
        let selectedBookShortName = navigation.selectedBook?.shortName
        let selectedChapterNumber = navigation.selectedChapter?.number
        let selectedVerseNumber = navigation.selectedVerse?.number

        books = repository.loadBooks(versionID: primaryVersionID)

        if let selectedBookShortName,
           let resolvedBook = books.first(where: { $0.shortName == selectedBookShortName }) {
            navigation.selectedBook = resolvedBook
        } else {
            navigation.selectedBook = books.first
        }

        if let selectedBook = navigation.selectedBook {
            chapters = repository.loadChapters(for: selectedBook, versionID: primaryVersionID)
            if let selectedChapterNumber,
               let resolvedChapter = chapters.first(where: { $0.number == selectedChapterNumber }) {
                navigation.selectedChapter = resolvedChapter
            } else {
                navigation.selectedChapter = chapters.first
            }
        } else {
            chapters = []
            navigation.selectedChapter = nil
        }

        if let selectedBook = navigation.selectedBook,
           let selectedChapter = navigation.selectedChapter {
            verses = repository.loadVerses(for: selectedBook, chapter: selectedChapter, versionID: primaryVersionID)
            filteredVerses = searchService.searchVerses(query: searchText, in: verses)
            if let selectedVerseNumber,
               let resolvedVerse = displayedVerses(for: .primary).first(where: { $0.number == selectedVerseNumber }) {
                navigation.selectedVerse = resolvedVerse
                selectedVerseRange = resolvedVerse.number...resolvedVerse.number
            } else {
                navigation.selectedVerse = nil
                selectedVerseRange = nil
            }
        } else {
            verses = []
            filteredVerses = []
            navigation.selectedVerse = nil
            selectedVerseRange = nil
        }

        if let book = navigation.selectedBook,
           let chapter = navigation.selectedChapter {
            let json = buildRemoteVersesJSON(verses: displayedVerses(for: .primary), book: book, chapter: chapter.number)
            RemoteCommandBus.shared.updateBibleVerses(bookName: book.name, chapter: chapter.number, json: json)
        }
    }

    private func buildRemoteVersesJSON(verses: [BibleVerse], book: BibleBook, chapter: Int) -> String {
        let items = verses.map { verse -> String in
            let text = verse.text
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
            return "{\"number\":\(verse.number),\"text\":\"\(text)\"}"
        }
        return "[" + items.joined(separator: ",") + "]"
    }

    private func selectedBookFromCurrentCatalog() -> BibleBook? {
        guard let selectedBook = navigation.selectedBook else { return books.first }
        return books.first(where: { $0.shortName == selectedBook.shortName }) ?? books.first
    }

    private func chapterMatchingSelection(in chapters: [BibleChapter]) -> BibleChapter? {
        guard let selectedChapter = navigation.selectedChapter else { return nil }
        return chapters.first(where: { $0.number == selectedChapter.number })
    }

    private func verseMatchingSelection(in verses: [BibleVerse]) -> BibleVerse? {
        guard let selectedVerse = navigation.selectedVerse else { return nil }
        return verses.first(where: { $0.number == selectedVerse.number })
    }

    private func pageCount(for totalItems: Int, pageSize: Int) -> Int {
        guard totalItems > 0 else { return 1 }
        return Int(ceil(Double(totalItems) / Double(pageSize)))
    }

    private func pageSlice<T>(from items: [T], pageIndex: Int, pageSize: Int) -> [T] {
        let start = pageIndex * pageSize
        guard start < items.count else { return [] }
        let end = min(start + pageSize, items.count)
        return Array(items[start..<end])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
