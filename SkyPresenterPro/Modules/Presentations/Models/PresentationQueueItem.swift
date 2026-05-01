import Foundation

/// Elemento de la cola de servicio del módulo Presentaciones.
/// Encapsula un documento y el índice de diapositiva desde el que iniciar la proyección.
struct PresentationQueueItem: Identifiable, Equatable, Hashable {
    let id: UUID
    var document: PresentationDocument
    var startSlideIndex: Int
    var addedAt: Date

    init(
        id: UUID = UUID(),
        document: PresentationDocument,
        startSlideIndex: Int = 0,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.document = document
        self.startSlideIndex = startSlideIndex
        self.addedAt = addedAt
    }
}
