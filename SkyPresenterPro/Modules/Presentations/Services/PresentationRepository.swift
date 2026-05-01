// Archivo: PresentationRepository.swift
// Función: Define la fuente de datos del módulo Presentaciones con persistencia JSON.
// Contiene: PresentationRepository, DefaultPresentationRepository.
// Uso: Carga y guarda documentos de presentación en Application Support entre sesiones.

import Foundation

// MARK: - Protocol

protocol PresentationRepository {
    func loadDocuments() -> [PresentationDocument]
    func saveDocuments(_ documents: [PresentationDocument])
}

// MARK: - Default Implementation (JSON en Application Support)

struct DefaultPresentationRepository: PresentationRepository {

    // ~/Library/Application Support/SkyPresenterPro/presentations.json
    private var storeURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("presentations.json")
    }

    func loadDocuments() -> [PresentationDocument] {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: storeURL)
            let documents = try JSONDecoder().decode([PresentationDocument].self, from: data)
            // Filtra documentos cuyo archivo fuente ya no existe en disco
            return documents.filter { doc in
                guard let url = doc.sourceURL else { return true }
                return FileManager.default.fileExists(atPath: url.path)
            }
        } catch {
            // Si el archivo está corrupto simplemente empezamos vacío
            return []
        }
    }

    func saveDocuments(_ documents: [PresentationDocument]) {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            // Fallo silencioso en guardado — se puede extender con ErrorManager
        }
    }
}
