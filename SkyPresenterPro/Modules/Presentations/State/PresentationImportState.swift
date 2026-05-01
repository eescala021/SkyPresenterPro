import Foundation

/// Estado transitorio del flujo de importación de presentaciones.
/// Utilizado por PresentationImportViewModel para seguimiento del proceso de importación.
struct PresentationImportState {
    var selectedFileURL: URL?
    var isImporting: Bool = false
    var progress: Double = 0.0
    var statusMessage: String = ""
    var didImportSuccessfully: Bool = false

    mutating func reset() {
        selectedFileURL = nil
        isImporting = false
        progress = 0.0
        statusMessage = ""
        didImportSuccessfully = false
    }
}
