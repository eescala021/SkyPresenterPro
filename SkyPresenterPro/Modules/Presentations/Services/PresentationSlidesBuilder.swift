import Foundation

/// Construye un array de ProjectionSlide a partir de un PresentationDocument.
/// Utilizado por el ProjectionEngine para gestionar la cola de proyección del módulo.
enum PresentationSlidesBuilder {

    /// Genera la cola de diapositivas para proyección:
    /// diapositiva de título + una por cada página del documento + diapositiva en blanco final.
    static func build(document: PresentationDocument) -> [ProjectionSlide] {
        let titleSlide = ProjectionSlide(
            title: document.title,
            subtitle: document.author.isEmpty ? nil : document.author,
            lines: []
        )

        let pageSlides = document.slides.map { slide in
            ProjectionSlide(
                title: nil,
                subtitle: nil,
                lines: [],
                notes: slide.notes.map { [$0] } ?? [],
                reference: "Diapositiva \(slide.pageNumber) / \(document.pageCount)"
            )
        }

        let blankSlide = ProjectionSlide(isBlank: true)

        return [titleSlide] + pageSlides + [blankSlide]
    }
}
