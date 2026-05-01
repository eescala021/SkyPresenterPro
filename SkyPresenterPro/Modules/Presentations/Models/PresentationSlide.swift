import Foundation

/// Representa una diapositiva individual dentro de un PresentationDocument.
/// Referencia la página del PDF por su índice, junto con notas opcionales del operador.
struct PresentationSlide: Identifiable, Equatable, Hashable {
    let id: UUID
    let documentID: UUID

    /// Índice base-0 de la página en el PDF.
    let pageIndex: Int

    /// Notas del operador opcionales para esta diapositiva.
    var notes: String?

    /// Número de página legible para el usuario (base-1).
    var pageNumber: Int { pageIndex + 1 }

    init(
        id: UUID = UUID(),
        documentID: UUID,
        pageIndex: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.documentID = documentID
        self.pageIndex = pageIndex
        self.notes = notes
    }
}
