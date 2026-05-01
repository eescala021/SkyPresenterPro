// Archivo: PresentationPDFImporter.swift
// Función: Importa archivos PDF y los convierte en documentos navegables con miniaturas en disco.
// Contiene: PresentationPDFImporter, PresentationImportError.
// Uso: Se invoca desde PresentationImportViewModel al seleccionar un PDF para importar al módulo.

import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class PresentationPDFImporter {

    private let thumbnailSize = CGSize(width: 640, height: 360)

    // MARK: - Importación principal

    /// Importa un PDF desde una URL y genera miniaturas para cada página.
    /// Las miniaturas se guardan en el directorio de caché de la app.
    func importPDF(from url: URL) throws -> PresentationDocument {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PresentationImportError.invalidFile
        }
        guard pdfDocument.pageCount > 0 else {
            throw PresentationImportError.noPages
        }

        let documentID = UUID()
        let title = url.deletingPathExtension().lastPathComponent
        let sourceFileName = url.lastPathComponent
        let cacheDir = thumbnailDirectory(for: documentID)

        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let slides: [PresentationSlide] = (0..<pdfDocument.pageCount).map { index in
            let imagePath = saveThumbnail(
                pdfDocument: pdfDocument,
                pageIndex: index,
                cacheDir: cacheDir
            )
            return PresentationSlide(
                pageIndex: index,
                title: "Diapositiva \(index + 1)",
                imagePath: imagePath
            )
        }

        return PresentationDocument(
            id: documentID,
            title: title,
            sourceFileName: sourceFileName,
            sourceURL: url,
            slideCount: slides.count,
            slides: slides
        )
    }

    /// Abre un panel de selección de archivo e importa el PDF elegido.
    /// Devuelve nil si el usuario cancela la selección.
    func selectAndImport() throws -> PresentationDocument? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Seleccionar presentación PDF"
        panel.message = "Elige un archivo PDF para importarlo al módulo de Presentaciones."

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return try importPDF(from: url)
    }

    // MARK: - Generación de miniaturas

    /// Genera y guarda la miniatura de una página como PNG en el directorio de caché.
    /// Devuelve la ruta en disco si tuvo éxito, nil si falló.
    private func saveThumbnail(
        pdfDocument: PDFDocument,
        pageIndex: Int,
        cacheDir: URL
    ) -> String? {
        guard let page = pdfDocument.page(at: pageIndex) else { return nil }

        let image = page.thumbnail(of: thumbnailSize, for: .mediaBox)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let fileURL = cacheDir.appendingPathComponent("slide_\(pageIndex).png")

        do {
            try pngData.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            return nil
        }
    }

    // MARK: - Directorio de caché

    private func thumbnailDirectory(for documentID: UUID) -> URL {
        let base = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("SkyPresenterPro")
            .appendingPathComponent("Thumbnails")
            .appendingPathComponent(documentID.uuidString)
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(documentID.uuidString)

        return base
    }
}

// MARK: - Errores de importación

enum PresentationImportError: LocalizedError {
    case invalidFile
    case unreadablePDF
    case noPages

    var errorDescription: String? {
        switch self {
        case .invalidFile:   return "El archivo no es un PDF válido."
        case .unreadablePDF: return "No se pudo leer el contenido del PDF."
        case .noPages:       return "El archivo PDF no contiene páginas."
        }
    }
}
