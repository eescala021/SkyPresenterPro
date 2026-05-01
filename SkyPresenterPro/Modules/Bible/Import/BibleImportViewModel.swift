import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class BibleImportViewModel: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var bibleName: String = ""
    @Published var selectedLanguage: BibleVersionLanguage = .es
    @Published var alias: String = ""
    @Published var selectedSlot: BibleVersionSlot = .primary
    @Published var isImporting: Bool = false
    @Published var importStatusMessage: String = ""
    @Published var didImportSuccessfully: Bool = false

    func prepareImport(url: URL, preferredSlot: BibleVersionSlot? = nil, currentAlias: String? = nil) {
        selectedFileURL = url
        bibleName = suggestedBibleName(from: url)
        alias = currentAlias ?? ""
        if let preferredSlot {
            selectedSlot = preferredSlot
        }
        importStatusMessage = ""
        didImportSuccessfully = false
    }

    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml, .json, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            prepareImport(url: url, preferredSlot: selectedSlot, currentAlias: alias)
        }
    }

    var canImport: Bool {
        selectedFileURL != nil && !bibleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isImporting
    }

    var importRequest: BibleVersionImportRequest? {
        guard let selectedFileURL else { return nil }
        let trimmedName = bibleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        return BibleVersionImportRequest(
            fileURL: selectedFileURL,
            metadata: BibleVersionImportMetadata(
                name: trimmedName,
                language: selectedLanguage
            ),
            slot: selectedSlot,
            alias: alias.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func markImportStarted() {
        isImporting = true
        didImportSuccessfully = false
        importStatusMessage = "Importando Biblia XML..."
    }

    func markImportFinished(message: String, success: Bool) {
        isImporting = false
        didImportSuccessfully = success
        importStatusMessage = message
    }

    func reset() {
        selectedFileURL = nil
        bibleName = ""
        selectedLanguage = .es
        alias = ""
        selectedSlot = .primary
        isImporting = false
        importStatusMessage = ""
        didImportSuccessfully = false
    }

    private func suggestedBibleName(from url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
