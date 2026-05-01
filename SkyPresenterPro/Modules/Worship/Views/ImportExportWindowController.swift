import AppKit
import SwiftUI

@MainActor
final class ImportExportWindowController: NSWindowController {
    static let shared = ImportExportWindowController()

    private let panelViewModel = WorshipImportExportPanelViewModel()
    private var hostingView: NSHostingView<WorshipImportExportPanelView>?
    private weak var worshipViewModel: WorshipViewModel?

    private init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func showImport(for viewModel: WorshipViewModel) {
        worshipViewModel = viewModel
        prepareWindowIfNeeded()
        panelViewModel.configureForImport(viewModel: viewModel, closeHandler: { [weak self] in
            self?.close()
        })
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showExport(for viewModel: WorshipViewModel) {
        worshipViewModel = viewModel
        prepareWindowIfNeeded()
        panelViewModel.configureForExport(viewModel: viewModel, closeHandler: { [weak self] in
            self?.close()
        })
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func prepareWindowIfNeeded() {
        guard window == nil else { return }

        let contentView = WorshipImportExportPanelView(viewModel: panelViewModel)
        let hostingView = NSHostingView(rootView: contentView)
        self.hostingView = hostingView

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 680),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Importar / Exportar Alabanzas"
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.setFrameAutosaveName("WorshipImportExportPanel")
        panel.contentView = hostingView
        panel.minSize = NSSize(width: 840, height: 560)
        panel.center()

        self.window = panel
    }
}

@MainActor
final class WorshipImportExportPanelViewModel: ObservableObject {
    enum Mode {
        case importing
        case exporting
    }

    @Published var mode: Mode = .importing
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var text: String = ""
    @Published var previewSections: [WorshipImportPreviewSection] = []
    @Published var message: String = ""
    @Published var isErrorMessage = false

    private weak var worshipViewModel: WorshipViewModel?
    private var closeHandler: (() -> Void)?

    func configureForImport(viewModel: WorshipViewModel, closeHandler: @escaping () -> Void) {
        self.worshipViewModel = viewModel
        self.closeHandler = closeHandler
        mode = .importing
        title = ""
        artist = ""
        text = ""
        previewSections = []
        message = "Pega una letra o carga un archivo .txt."
        isErrorMessage = false
    }

    func configureForExport(viewModel: WorshipViewModel, closeHandler: @escaping () -> Void) {
        self.worshipViewModel = viewModel
        self.closeHandler = closeHandler
        mode = .exporting
        let song = viewModel.selectedSong
        title = song?.title ?? ""
        artist = song?.artist ?? ""
        text = song.map(WorshipImportExportService.exportSong) ?? ""
        previewSections = WorshipImportExportService.previewSections(from: text)
        message = song == nil ? "Selecciona una canción para exportar." : "Texto listo para copiar."
        isErrorMessage = song == nil
    }

    func textDidChange() {
        previewSections = WorshipImportExportService.previewSections(from: text)
        if let validation = WorshipImportExportService.validateImportText(text) {
            message = validation
            isErrorMessage = true
        } else {
            let slideCount = previewSections.reduce(0) { $0 + $1.slideCount }
            message = "\(previewSections.count) secciones detectadas · \(slideCount) slides estimados"
            isErrorMessage = false
        }
    }

    func loadTextFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let loadedText = try String(contentsOf: url, encoding: .utf8)
            text = loadedText
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = url.deletingPathExtension().lastPathComponent
            }
            mode = .importing
            textDidChange()
        } catch {
            message = "No se pudo cargar el archivo seleccionado."
            isErrorMessage = true
        }
    }

    func copyResult() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            message = "No hay texto para copiar."
            isErrorMessage = true
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        message = "Resultado copiado al portapapeles."
        isErrorMessage = false
    }

    func exportCurrentSong() {
        guard let song = worshipViewModel?.selectedSong else {
            message = "Selecciona una canción para exportar."
            isErrorMessage = true
            return
        }

        mode = .exporting
        title = song.title
        artist = song.artist
        text = WorshipImportExportService.exportSong(song)
        previewSections = WorshipImportExportService.previewSections(from: text)
        message = "Texto exportado correctamente."
        isErrorMessage = false
    }

    func importSong() {
        guard let worshipViewModel else { return }
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            message = "No hay texto para importar."
            isErrorMessage = true
            return
        }

        if let validation = WorshipImportExportService.validateImportText(normalizedText) {
            message = validation
            isErrorMessage = true
            return
        }

        let songTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let songArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)

        let shouldReplaceCurrent = resolveReplacementChoice(hasSelectedSong: worshipViewModel.selectedSong != nil)
        guard let shouldReplaceCurrent else { return }

        let result = worshipViewModel.importSong(
            from: normalizedText,
            title: songTitle.isEmpty ? nil : songTitle,
            artist: songArtist,
            replacingSelectedSong: shouldReplaceCurrent
        )

        message = result.message
        isErrorMessage = !result.success
        if result.success {
            mode = .exporting
            exportCurrentSong()
        }
    }

    func cancel() {
        closeHandler?()
    }

    private func resolveReplacementChoice(hasSelectedSong: Bool) -> Bool? {
        guard hasSelectedSong else { return false }

        let alert = NSAlert()
        alert.messageText = "Importar letra"
        alert.informativeText = "Puedes crear una canción nueva o reemplazar la alabanza seleccionada. No se sobrescribirá nada sin confirmación."
        alert.addButton(withTitle: "Crear nueva")
        alert.addButton(withTitle: "Reemplazar actual")
        alert.addButton(withTitle: "Cancelar")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return false
        case .alertSecondButtonReturn:
            return true
        default:
            return nil
        }
    }
}
