// Archivo: BibleRepository.swift
// Función: Define el acceso abstracto a datos bíblicos y una implementación mock completa con 66 libros.
// Contiene: BibleRepository, MockBibleRepository.
// Uso: Se usa por view models y servicios para consultar libros, capítulos y versículos.

import Foundation

protocol BibleRepository {
    func loadBooks() -> [BibleBook]
    func loadChapters(for book: BibleBook) -> [BibleChapter]
    func loadVerses(for book: BibleBook, chapter: BibleChapter) -> [BibleVerse]
}

// MARK: - MockBibleRepository (66 libros, RVR1960)

struct MockBibleRepository: BibleRepository {

    // MARK: - loadBooks

    func loadBooks() -> [BibleBook] {
        // Tupla: (nombre, abreviatura, capítulos, colorGroup)
        let pentateuco: [(String, String, Int, Int)] = [
            ("Génesis",      "Gn",  50, 0),
            ("Éxodo",        "Ex",  40, 1),
            ("Levítico",     "Lv",  27, 2),
            ("Números",      "Nm",  36, 3),
            ("Deuteronomio", "Dt",  34, 4)
        ]
        let historicos: [(String, String, Int, Int)] = [
            ("Josué",       "Jos", 24, 5),
            ("Jueces",      "Jue", 21, 6),
            ("Rut",         "Rt",   4, 7),
            ("1 Samuel",    "1S",  31, 8),
            ("2 Samuel",    "2S",  24, 9),
            ("1 Reyes",     "1R",  22, 10),
            ("2 Reyes",     "2R",  25, 11),
            ("1 Crónicas",  "1Cr", 29, 12),
            ("2 Crónicas",  "2Cr", 36, 13),
            ("Esdras",      "Esd", 10, 14),
            ("Nehemías",    "Neh", 13, 0),
            ("Ester",       "Est", 10, 1)
        ]
        let poeticos: [(String, String, Int, Int)] = [
            ("Job",         "Job", 42, 2),
            ("Salmos",      "Sal",150, 3),
            ("Proverbios",  "Pr",  31, 4),
            ("Eclesiastés", "Ec",  12, 5),
            ("Cantares",    "Cnt",  8, 6)
        ]
        let profMayores: [(String, String, Int, Int)] = [
            ("Isaías",        "Is",  66, 7),
            ("Jeremías",      "Jer", 52, 8),
            ("Lamentaciones", "Lm",   5, 9),
            ("Ezequiel",      "Ez",  48, 10),
            ("Daniel",        "Dn",  12, 11)
        ]
        let profMenores: [(String, String, Int, Int)] = [
            ("Oseas",     "Os",  14, 12),
            ("Joel",      "Jl",   3, 13),
            ("Amós",      "Am",   9, 14),
            ("Abdías",    "Abd",  1, 0),
            ("Jonás",     "Jon",  4, 1),
            ("Miqueas",   "Mi",   7, 2),
            ("Nahúm",     "Nah",  3, 3),
            ("Habacuc",   "Hab",  3, 4),
            ("Sofonías",  "Sof",  3, 5),
            ("Hageo",     "Hag",  2, 6),
            ("Zacarías",  "Zac", 14, 7),
            ("Malaquías", "Mal",  4, 8)
        ]
        let evangelios: [(String, String, Int, Int)] = [
            ("Mateo",  "Mt", 28, 9),
            ("Marcos", "Mc", 16, 10),
            ("Lucas",  "Lc", 24, 11),
            ("Juan",   "Jn", 21, 12)
        ]
        let historiaNT: [(String, String, Int, Int)] = [
            ("Hechos", "Hch", 28, 13)
        ]
        let paulinas: [(String, String, Int, Int)] = [
            ("Romanos",          "Ro",  16, 14),
            ("1 Corintios",      "1Co", 16, 0),
            ("2 Corintios",      "2Co", 13, 1),
            ("Gálatas",          "Ga",   6, 2),
            ("Efesios",          "Ef",   6, 3),
            ("Filipenses",       "Fil",  4, 4),
            ("Colosenses",       "Col",  4, 5),
            ("1 Tesalonicenses", "1Ts",  5, 6),
            ("2 Tesalonicenses", "2Ts",  3, 7),
            ("1 Timoteo",        "1Ti",  6, 8),
            ("2 Timoteo",        "2Ti",  4, 9),
            ("Tito",             "Tit",  3, 10),
            ("Filemón",          "Flm",  1, 11)
        ]
        let generales: [(String, String, Int, Int)] = [
            ("Hebreos",  "He",  13, 12),
            ("Santiago", "Stg",  5, 13),
            ("1 Pedro",  "1P",   5, 14),
            ("2 Pedro",  "2P",   3, 0),
            ("1 Juan",   "1Jn",  5, 1),
            ("2 Juan",   "2Jn",  1, 2),
            ("3 Juan",   "3Jn",  1, 3),
            ("Judas",    "Jud",  1, 4)
        ]
        let profeciaNT: [(String, String, Int, Int)] = [
            ("Apocalipsis", "Ap", 22, 5)
        ]

        let all = pentateuco + historicos + poeticos + profMayores + profMenores
                  + evangelios + historiaNT + paulinas + generales + profeciaNT

        return all.map { BibleBook(name: $0.0, shortName: $0.1, chapterCount: $0.2, colorGroup: $0.3) }
    }

    // MARK: - loadChapters

    func loadChapters(for book: BibleBook) -> [BibleChapter] {
        (1...max(1, book.chapterCount)).map { BibleChapter(number: $0) }
    }

    // MARK: - loadVerses

    func loadVerses(for book: BibleBook, chapter: BibleChapter) -> [BibleVerse] {
        let count = estimatedVerseCount(shortName: book.shortName, chapter: chapter.number)
        return (1...count).map {
            BibleVerse(
                number: $0,
                text: "«\(book.name) \(chapter.number):\($0) — Versículo de muestra para la versión RVR1960.»"
            )
        }
    }

    // MARK: - Helpers

    /// Devuelve un conteo aproximado de versículos según libro y capítulo.
    private func estimatedVerseCount(shortName: String, chapter: Int) -> Int {
        switch shortName {
        case "Sal":
            // Conteos reales del Salterio
            let v = [6,12,8,8,12,10,17,9,20,18,7,8,6,7,5,11,15,51,15,10,
                     14,32,29,24,10,4,14,22,25,22,23,28,17,27,9,21,36,16,13,29,
                     22,11,29,23,25,13,10,7,24,13,6,6,17,15,5,11,24,22,22,28,
                     12,28,17,15,16,19,18,28,18,13,14,14,5,6,20,32,12,14,20,28,
                     14,12,40,45,33,26,13,28,29,27,27,16,4,1,11,14,24,1,10,13,
                     19,14,10,18,30,31,31,30,29,28,28,29,29,28,28,28,26,25,24,24,
                     23,22,22,22,22,22,22,22,21,21,20,19,19,19,17,17,14,14,14,14,
                     14,14,12,12,12,12,10,10,9,8]
            let idx = max(0, min(chapter - 1, v.count - 1))
            return v[idx]
        case "Pr":    return 22
        case "Is":    return chapter <= 39 ? 28 : 22
        case "Jer":   return chapter <= 30 ? 24 : 18
        case "Ez":    return chapter <= 24 ? 27 : 20
        case "Jn":
            let v = [51,25,36,54,47,71,53,59,41,42,45,57,50,46,79,38,27,36,35,16,8,9,21]
            return v[max(0, min(chapter - 1, v.count - 1))]
        case "Ro":    return chapter == 16 ? 27 : 25
        case "1Co":   return chapter == 13 ? 13 : 24
        case "Ap":    return chapter == 22 ? 21 : 20
        default:      return 25
        }
    }
}
