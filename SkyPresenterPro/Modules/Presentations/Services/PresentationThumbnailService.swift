import AppKit
import Foundation
import PDFKit

/// Genera y cachea miniaturas NSImage de páginas PDF para su visualización en la UI.
/// Las miniaturas se generan de forma lazy y se almacenan en memoria por sesión.
@MainActor
final class PresentationThumbnailService: ObservableObject {

    private var cache: [String: NSImage] = [:]
    private let thumbnailSize = CGSize(width: 320, height: 180)

    /// Devuelve la miniatura para la página indicada del documento.
    /// Si no está en caché la genera y la almacena para futuras consultas.
    func thumbnail(for document: PresentationDocument, slideIndex: Int) -> NSImage? {
        guard let url = document.fileURL else { return nil }

        let key = "\(url.path):\(slideIndex)"
        if let cached = cache[key] { return cached }

        let image = generateThumbnail(url: url, pageIndex: slideIndex)
        if let image { cache[key] = image }
        return image
    }

    /// Vacía la caché de miniaturas para liberar memoria.
    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private

    private func generateThumbnail(url: URL, pageIndex: Int) -> NSImage? {
        guard let pdfDocument = PDFDocument(url: url),
              let page = pdfDocument.page(at: pageIndex) else { return nil }
        return page.thumbnail(of: thumbnailSize, for: .mediaBox)
    }
}
