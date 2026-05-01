// Archivo: PresentationImportViewModel.swift
// Función: Controla el flujo de importación de documentos PDF al módulo de Presentaciones.
// Contiene: PresentationImportViewModel.
// Uso: Gestiona selección de archivo, estado de carga, errores y entrega el documento importado via callback.

import Combine
import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
final class PresentationImportViewModel: ObservableObject {

    // MARK: - Estado publicado

    @Published var selectedFileURL: URL?
    @Published var isImporting: Bool = false
    @Published var importError: String?
    @Published var importSuccess: Bool = false

    // MARK: - Callback al finalizar

    /// Se llama con el documento importado cuando la operación tiene éxito.
    var onDocumentImported: ((PresentationDocument) -> Void)?

    // MARK: - Servicios

    private let importer = PresentationPDFImporter()

    // MARK: - Seleccionar archivo

    func selectFile() {
        importError = nil
        importSuccess = false

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Seleccionar presentación PDF"
        panel.message = "Elige un archivo PDF para importarlo al módulo de Presentaciones."

        if panel.runModal() == .OK {
            selectedFileURL = panel.url
        }
    }

    // MARK: - Importar

    func importPresentation() {
        guard let url = selectedFileURL else { return }

        isImporting = true
        importError = nil
        importSuccess = false

        Task {
            do {
                let document = try await Task.detached(priority: .userInitiated) {
                    // PresentationPDFImporter es @MainActor — llamada directa en hilo principal
                    try await MainActor.run {
                        try PresentationPDFImporter().importPDF(from: url)
                    }
                }.value

                isImporting = false
                importSuccess = true
                onDocumentImported?(document)

            } catch {
                isImporting = false
                importError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: - Limpiar

    func reset() {
        selectedFileURL = nil
        isImporting = false
        importError = nil
        importSuccess = false
    }
}
