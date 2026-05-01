// Archivo: BibleHistoryService.swift
// Función: Mantiene el historial reciente de navegación bíblica con persistencia en UserDefaults.
// Contiene: BibleHistoryService.
// Uso: Se usa para poblar el panel derecho de historial y accesos recientes entre sesiones.

import Combine
import SwiftUI

@MainActor
final class BibleHistoryService: ObservableObject {

    @Published private(set) var items: [BibleReference] = []

    private let storageKey = "bible_history"
    private let maxItems = 20

    init() {
        load()
    }

    func add(_ reference: BibleReference) {
        items.removeAll { $0 == reference }
        items.insert(reference, at: 0)

        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        let payload = items.map {
            StoredBibleReference(book: $0.book, chapter: $0.chapter, verse: $0.verse)
        }
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let payload = try? JSONDecoder().decode([StoredBibleReference].self, from: data)
        else {
            items = []
            return
        }
        items = payload.map { BibleReference(book: $0.book, chapter: $0.chapter, verse: $0.verse) }
    }
}

private struct StoredBibleReference: Codable {
    let book: String
    let chapter: Int
    let verse: Int?
}
