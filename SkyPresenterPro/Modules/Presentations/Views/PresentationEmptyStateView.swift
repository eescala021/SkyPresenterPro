import SwiftUI

/// Vista de estado vacío del módulo Presentaciones.
/// Se muestra cuando no hay documentos en la biblioteca o ninguno está seleccionado.
struct PresentationEmptyStateView: View {
    let text: String

    var body: some View {
        EmptyStateCard(
            title: "Presentaciones",
            message: text
        )
    }
}
