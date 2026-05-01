import Combine
import SwiftUI

/// Servicio de cola del módulo Presentaciones.
/// Mantiene la lista ordenada de documentos programados para proyección durante el servicio.
@MainActor
final class PresentationQueueService: ObservableObject {
    @Published var items: [PresentationQueueItem] = []

    func add(_ document: PresentationDocument) {
        items.append(PresentationQueueItem(document: document))
    }

    func remove(_ item: PresentationQueueItem) {
        items.removeAll { $0.id == item.id }
    }

    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: offsets, toOffset: destination)
    }

    func clear() {
        items.removeAll()
    }
}
