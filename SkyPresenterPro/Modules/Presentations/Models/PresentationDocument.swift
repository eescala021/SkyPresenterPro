import Foundation

/// Representa un documento de presentación importado por el usuario (tipicamente un PDF).
/// Contiene metadatos del archivo y la colección de diapositivas derivadas.
struct PresentationDocument: Identifiable, Equatable, Hashable {
    let id: UUID

    var title: String
    var author: String
    var fileURL: URL?
    var slides: [PresentationSlide]
    var importedAt: Date

    /// Número total de páginas/diapositivas del documento.
    var pageCount: Int { slides.count }

    init(
        id: UUID = UUID(),
        title: String,
        author: String = "",
        fileURL: URL? = nil,
        slides: [PresentationSlide] = [],
        importedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.fileURL = fileURL
        self.slides = slides
        self.importedAt = importedAt
    }
}
