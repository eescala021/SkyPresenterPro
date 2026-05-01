import Foundation

struct WorshipImportPreviewSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let lines: [String]
    let slideCount: Int
}

private struct WorshipParsedSection: Equatable {
    let title: String
    let lines: [String]
}

enum WorshipImportExportService {
    private static let sectionHeaderPattern = #"^\s*\[(.+)\]\s*$"#

    static func parseSong(from text: String) -> WorshipSong {
        parseSong(from: text, title: nil, artist: "")
    }

    static func parseSong(from text: String, title: String?, artist: String) -> WorshipSong {
        let semanticSections = parseSemanticSections(from: text)
        let resolvedTitle = resolvedSongTitle(explicitTitle: title, sections: semanticSections)
        let normalizedText = normalizedSongText(from: semanticSections)
        let slides = semanticSections.flatMap(generateSlides)

        return WorshipSong(
            title: resolvedTitle,
            artist: artist.trimmingCharacters(in: .whitespacesAndNewlines),
            rawText: normalizedText,
            sections: slides
        )
    }

    static func parseSections(from text: String) -> [WorshipSection] {
        parseSemanticSections(from: text).flatMap(generateSlides)
    }

    static func previewSections(from text: String) -> [WorshipImportPreviewSection] {
        parseSemanticSections(from: text).map { section in
            WorshipImportPreviewSection(
                title: section.title,
                lines: section.lines,
                slideCount: generateSlides(from: section).count
            )
        }
    }

    static func normalizeSectionTitle(_ rawTitle: String) -> String {
        let cleaned = rawTitle
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return "Sección"
        }

        let canonical = cleaned.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let collapsed = canonical.replacingOccurrences(of: "  ", with: " ")

        switch collapsed.lowercased() {
        case "c", "coro", "chorus", "hook":
            return "Coro"
        case "bridge", "puente", "puente 1":
            return "Puente"
        case "intro":
            return "Intro"
        case "outro", "ending", "final":
            return "Final"
        case "pre-coro", "precoro", "pre chorus":
            return "Pre-Coro"
        default:
            break
        }

        if let verse = normalizedIndexedTitle(in: collapsed, prefixes: ["v", "verso", "verse"], title: "Verso") {
            return verse
        }

        if let chorus = normalizedIndexedTitle(in: collapsed, prefixes: ["coro", "chorus", "c"], title: "Coro") {
            return chorus
        }

        if let bridge = normalizedIndexedTitle(in: collapsed, prefixes: ["bridge", "puente", "b"], title: "Puente") {
            return bridge
        }

        return cleaned
    }

    static func generateSlides(from section: WorshipParsedSection) -> [WorshipSection] {
        let cleanedLines = section.lines
            .map { normalizeVisibleLine($0) }
            .filter { !$0.isEmpty }

        guard !cleanedLines.isEmpty else { return [] }

        var slides: [WorshipSection] = []
        var currentChunk: [String] = []

        func flushChunk() {
            guard !currentChunk.isEmpty else { return }
            slides.append(
                WorshipSection(
                    title: section.title,
                    lines: currentChunk
                )
            )
            currentChunk.removeAll()
        }

        for line in cleanedLines {
            let projectedCount = currentChunk.count + 1
            let wouldBeTooDense = projectedCount > 4
            let longLineOverflow = currentChunk.count >= 2 && line.count > 44

            if wouldBeTooDense || longLineOverflow {
                flushChunk()
            }

            currentChunk.append(line)

            if currentChunk.count >= 3 && line.count > 54 {
                flushChunk()
            }
        }

        flushChunk()

        if slides.isEmpty {
            return [WorshipSection(title: section.title, lines: cleanedLines)]
        }

        return slides.enumerated().map { index, slide in
            let needsIndex = slides.count > 1
            return WorshipSection(
                title: needsIndex ? "\(section.title) \(index + 1)" : section.title,
                lines: slide.lines,
                operatorNotes: slide.operatorNotes
            )
        }
    }

    static func exportSong(_ song: WorshipSong) -> String {
        let semanticSections = parseSemanticSections(from: song.rawText)
        if !semanticSections.isEmpty {
            return normalizedSongText(from: semanticSections)
        }

        let fallbackSections = song.sections
            .filter { !$0.lines.isEmpty }
            .map { WorshipParsedSection(title: $0.title, lines: $0.lines) }

        return normalizedSongText(from: fallbackSections)
    }

    static func validateImportText(_ text: String) -> String? {
        let semanticSections = parseSemanticSections(from: text)
        guard !semanticSections.isEmpty else {
            return "No se detectó contenido importable."
        }
        return nil
    }

    private static func parseSemanticSections(from text: String) -> [WorshipParsedSection] {
        let normalized = normalizeRawText(text)
        let lines = normalized.components(separatedBy: "\n")

        var sections: [WorshipParsedSection] = []
        var currentTitle: String?
        var currentLines: [String] = []
        var sawExplicitHeaders = false

        func flushCurrentSection() {
            let cleanedLines = currentLines
                .map { normalizeVisibleLine($0) }
                .filter { !$0.isEmpty }

            guard !cleanedLines.isEmpty else {
                currentLines.removeAll()
                return
            }

            let resolvedTitle = normalizeSectionTitle(currentTitle ?? inferredDefaultTitle(for: sections.count))
            sections.append(WorshipParsedSection(title: resolvedTitle, lines: cleanedLines))
            currentLines.removeAll()
        }

        for rawLine in lines {
            let trimmedLine = normalizeVisibleLine(rawLine)
            if let headerTitle = detectedSectionHeader(in: rawLine) {
                flushCurrentSection()
                currentTitle = normalizeSectionTitle(headerTitle)
                sawExplicitHeaders = true
                continue
            }

            guard !trimmedLine.isEmpty else {
                if sawExplicitHeaders {
                    flushCurrentSection()
                    currentTitle = nil
                } else if currentLines.count >= 4 {
                    flushCurrentSection()
                }
                continue
            }

            currentLines.append(trimmedLine)
        }

        flushCurrentSection()

        if sections.isEmpty {
            let fallbackLines = lines
                .map { normalizeVisibleLine($0) }
                .filter { !$0.isEmpty }

            guard !fallbackLines.isEmpty else { return [] }
            return [WorshipParsedSection(title: "Verso 1", lines: fallbackLines)]
        }

        if !sawExplicitHeaders, sections.count == 1 {
            return [WorshipParsedSection(title: "Verso 1", lines: sections[0].lines)]
        }

        return sections
    }

    private static func normalizedSongText(from sections: [WorshipParsedSection]) -> String {
        sections
            .filter { !$0.lines.isEmpty }
            .map { section in
                let body = section.lines.joined(separator: "\n")
                return "[\(section.title)]\n\(body)"
            }
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func resolvedSongTitle(explicitTitle: String?, sections: [WorshipParsedSection]) -> String {
        let trimmedTitle = explicitTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        if let firstLine = sections.first?.lines.first, !firstLine.isEmpty {
            return firstLine.prefix(48).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }

        return "ALABANZA IMPORTADA"
    }

    private static func normalizeRawText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
    }

    private static func normalizeVisibleLine(_ line: String) -> String {
        var cleaned = line
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        return cleaned
    }

    private static func detectedSectionHeader(in line: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: sectionHeaderPattern) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let titleRange = Range(match.range(at: 1), in: line)
        else {
            return nil
        }

        let header = String(line[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        return header.isEmpty ? nil : header
    }

    private static func normalizedIndexedTitle(in value: String, prefixes: [String], title: String) -> String? {
        let compact = value.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        let tokens = compact.split(separator: " ").map(String.init)
        guard let first = tokens.first else { return nil }
        guard prefixes.contains(first) || prefixes.contains(compact) else { return nil }

        let suffixSource: String
        if prefixes.contains(compact) {
            suffixSource = ""
        } else if tokens.count > 1 {
            suffixSource = tokens.dropFirst().joined(separator: " ")
        } else {
            suffixSource = String(compact.dropFirst(first.count))
        }

        let suffix = suffixSource.trimmingCharacters(in: .whitespaces)
        guard !suffix.isEmpty else { return title }

        if let numeric = Int(suffix.filter(\.isNumber)) {
            return "\(title) \(numeric)"
        }

        return title
    }

    private static func inferredDefaultTitle(for index: Int) -> String {
        "Verso \(index + 1)"
    }
}
