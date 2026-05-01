import Foundation

struct BibleVersionDescriptor: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let language: String
    let source: BibleVersionSource
    let fileName: String?
    let importedAt: Date?

    var displayLabel: String {
        language.isEmpty ? name : "\(name) · \(language)"
    }
}

enum BibleVersionSource: String, Codable {
    case builtIn
    case imported
}

enum BibleVersionSlot: String, CaseIterable, Identifiable, Codable {
    case primary
    case secondary
    case tertiary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .primary:
            return "V1"
        case .secondary:
            return "V2"
        case .tertiary:
            return "V3"
        }
    }
}

struct BibleVersionContainer: Identifiable, Equatable {
    let slot: BibleVersionSlot
    let version: BibleVersionDescriptor?
    let verses: [BibleVerse]

    var id: BibleVersionSlot { slot }
}
