// Archivo: ProjectionCommandRouter.swift
// Función: Enruta comandos remotos hacia ProjectionEngine y los view models de módulos proyectables.
// Contiene: ProjectionCommandRouter
// Uso: Se integra en AppEnvironment y RemoteControlManager como adaptador entre la API remota y la lógica de proyección.
import Foundation

@MainActor
final class ProjectionCommandRouter {
    private let projectionEngine: ProjectionEngine
    private let worshipViewModel: WorshipViewModel
    private let bibleViewModel: BibleViewModel
    private let presentationViewModel: PresentationViewModel

    init(
        projectionEngine: ProjectionEngine,
        worshipViewModel: WorshipViewModel,
        bibleViewModel: BibleViewModel,
        presentationViewModel: PresentationViewModel
    ) {
        self.projectionEngine = projectionEngine
        self.worshipViewModel = worshipViewModel
        self.bibleViewModel = bibleViewModel
        self.presentationViewModel = presentationViewModel
    }

    func handle(_ command: RemoteCommand) {
        switch command {
        case .previous:
            projectionEngine.goPrevious()
        case .next:
            projectionEngine.goNext()
        case .escape:
            projectionEngine.clear()
        case .projectCurrent:
            if let currentIndex = projectionEngine.currentIndex {
                projectionEngine.project(at: currentIndex)
            } else {
                projectCurrentWorshipSelection()
            }
        case let .projectBibleVerse(_, bookIndex, chapter, verse):
            projectBibleVerse(bookIndex: bookIndex, chapter: chapter, verse: verse)
        case let .projectPresentationPage(presentationID, pageIndex):
            projectPresentationPage(presentationID: presentationID, pageIndex: pageIndex)
        }
    }

    private func projectBibleVerse(bookIndex: Int, chapter: Int, verse: Int) {
        let targetBookIndex = bookIndex - 1
        guard bibleViewModel.books.indices.contains(targetBookIndex) else {
            return
        }

        let book = bibleViewModel.books[targetBookIndex]
        let reference = BibleReference(book: book.name, chapter: chapter, verse: verse)
        let projectedVerse = BibleVerse(
            number: verse,
            text: "Texto del versículo \(verse) de \(book.name) \(chapter)."
        )
        let slides = BibleProjectionBuilder.build(from: reference, verses: [projectedVerse])
        projectionEngine.loadQueue(slides, source: .bible)
    }

    private func projectPresentationPage(presentationID: String, pageIndex: Int) {
        guard
            let document = presentationViewModel.documents.first(where: {
                $0.id.uuidString == presentationID
            })
        else {
            return
        }

        presentationViewModel.selectDocument(document)
        presentationViewModel.selectSlide(at: pageIndex)

        let slides = PresentationSlidesBuilder.build(document: document)
        let projectionIndex = pageIndex + 1

        guard slides.indices.contains(projectionIndex) else {
            return
        }

        projectionEngine.loadQueue(
            slides,
            source: .presentation,
            startAt: projectionIndex
        )
    }

    private func projectCurrentWorshipSelection() {
        guard let song = worshipViewModel.selectedSong else {
            return
        }

        let slides = WorshipSlidesBuilder.build(song: song)
        let sectionIndex = worshipViewModel.selectedSections.firstIndex { section in
            section.id == worshipViewModel.liveState.selectedSectionID
        } ?? 0

        projectionEngine.loadQueue(
            slides,
            source: .worship,
            startAt: min(sectionIndex + 1, max(slides.count - 1, 0))
        )
    }
}
