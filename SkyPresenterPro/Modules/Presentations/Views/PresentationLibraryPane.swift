import SwiftUI

/// Panel lateral izquierdo del módulo Presentaciones.
/// Muestra la biblioteca de documentos importados con campo de búsqueda y menú contextual.
struct PresentationLibraryPane: View {
    @EnvironmentObject private var viewModel: PresentationViewModel
    @State private var showImportWindow = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderView(title: "Presentaciones", subtitle: "Biblioteca")

            SearchFieldRow(
                text: $viewModel.searchText,
                placeholder: "Buscar presentación..."
            )

            if viewModel.filteredDocuments.isEmpty {
                PresentationEmptyStateView(
                    text: "No hay presentaciones.\nImporta un PDF para comenzar."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.filteredDocuments) { document in
                            PresentationDocumentRow(
                                document: document,
                                isSelected: viewModel.selectedDocumentID == document.id
                            )
                            .onTapGesture {
                                viewModel.selectDocument(document)
                            }
                            .contextMenu {
                                Button("Agregar al servicio") {
                                    viewModel.addToQueue(document)
                                }
                                Divider()
                                Button("Eliminar", role: .destructive) {
                                    viewModel.removeDocument(document)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Button("Importar PDF") {
                showImportWindow = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.md)
        .sheet(isPresented: $showImportWindow) {
            PresentationImportWindow()
                .environmentObject(viewModel)
        }
    }
}
