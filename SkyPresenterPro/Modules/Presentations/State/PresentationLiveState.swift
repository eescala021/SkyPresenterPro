import Foundation

/// Estado en directo del módulo Presentaciones.
/// Rastrea el documento activo y los índices de diapositiva actual y preparada.
struct PresentationLiveState {
    var currentDocumentID: UUID?
    var selectedSlideIndex: Int?
    var preparedSlideIndex: Int?
}
