// Archivo: PresentationImportWindow.swift
// Función: Define la ventana de importación de documentos PDF al módulo de Presentaciones.
// Contiene: PresentationImportWindow.
// Uso: Se presenta como sheet desde PresentationModuleView. Entrega el documento al PresentationViewModel del entorno.

import SwiftUI

struct PresentationImportWindow: View {

    @EnvironmentObject private var presentationViewModel: PresentationViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PresentationImportViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            // Encabezado
            VStack(alignment: .leading, spacing: 6) {
                Text("Importar presentación")
                    .font(.system(size: 24, weight: .black))

                Text("Selecciona un PDF para agregarlo al módulo de Presentaciones.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Selección de archivo
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    Button("Seleccionar archivo") {
                        viewModel.selectFile()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    if let name = viewModel.selectedFileURL?.lastPathComponent {
                        Label(name, systemImage: "doc.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                if let error = viewModel.importError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.red)
                }

                if viewModel.importSuccess {
                    Label("Importación completada.", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                }
            }

            // Indicador de progreso
            if viewModel.isImporting {
                HStack(spacing: AppSpacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generando miniaturas…")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Acciones principales
            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Spacer()

                Button("Importar") {
                    viewModel.importPresentation()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(viewModel.selectedFileURL == nil || viewModel.isImporting)
            }
        }
        .padding(AppSpacing.xl)
        .frame(minWidth: 520, minHeight: 280)
        .onAppear {
            // Conectar callback al ViewModel del entorno
            viewModel.onDocumentImported = { document in
                presentationViewModel.addDocument(document)
                dismiss()
            }
        }
    }
}
