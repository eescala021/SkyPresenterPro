import Foundation

enum WorshipSongEditorService {
    static func normalizeEditableText(_ text: String) -> String {
        let normalizedNewlines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return normalizedNewlines.uppercased(with: Locale(identifier: "es"))
    }

    static func generateSlides(from rawText: String) -> [WorshipSongEditorPreviewSlide] {
        let normalized = normalizeEditableText(rawText)
        let paragraphs = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var slides: [WorshipSongEditorPreviewSlide] = []

        for (sectionIndex, paragraph) in paragraphs.enumerated() {
            let lines = paragraph
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard !lines.isEmpty else { continue }

            let title = inferredSectionTitle(for: lines.first ?? "", index: sectionIndex)
            let contentLines = sanitizedContentLines(from: lines)
            guard !contentLines.isEmpty else { continue }

            for chunk in chunkedLines(contentLines) {
                slides.append(
                    WorshipSongEditorPreviewSlide(
                        id: UUID(),
                        sectionIndex: sectionIndex,
                        sectionTitle: title,
                        lines: chunk
                    )
                )
            }
        }

        return slides
    }

    static func buildSections(from rawText: String) -> [WorshipSection] {
        let slides = generateSlides(from: rawText)
        return slides.enumerated().map { index, slide in
            WorshipSection(
                title: slide.sectionTitle.isEmpty ? "DIAPOSITIVA \(index + 1)" : slide.sectionTitle,
                lines: slide.lines
            )
        }
    }

    private static func inferredSectionTitle(for firstLine: String, index: Int) -> String {
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            return String(trimmed.dropFirst().dropLast())
        }

        if trimmed.hasPrefix("VERSO") || trimmed.hasPrefix("CORO") || trimmed.hasPrefix("PUENTE") {
            return trimmed
        }

        return "DIAPOSITIVA \(index + 1)"
    }

    private static func sanitizedContentLines(from lines: [String]) -> [String] {
        guard let first = lines.first else { return [] }
        if first.hasPrefix("[") && first.hasSuffix("]") {
            return Array(lines.dropFirst())
        }
        return lines
    }

    private static func chunkedLines(_ lines: [String]) -> [[String]] {
        var result: [[String]] = []
        var current: [String] = []

        for line in lines {
            current.append(line)
            if current.count == 4 {
                result.append(current)
                current = []
            }
        }

        if !current.isEmpty {
            result.append(current)
        }

        return result
    }
}
