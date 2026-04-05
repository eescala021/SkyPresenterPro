import SwiftUI

struct MediaView: View {
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var pdfManager: PDFManager
    @EnvironmentObject var bibleManager: BibleManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var announcementManager: AnnouncementManager

    @State private var selectedItemID: MediaItem.ID?
    @State private var selectedPage: Int = 0
    @State private var recognizedText: String = ""
    @State private var detectedVerseMatches: [BibleReferenceMatch] = []
    @State private var selectedDetectedVerseKey: String?
    @State private var isRecognizingText: Bool = false

    private var selectedItem: MediaItem? {
        pdfManager.items.first { $0.id == selectedItemID } ?? pdfManager.items.first
    }

    var body: some View {
        VStack(spacing: 12) {
            mediaToolbar

            HStack(spacing: 12) {
                libraryPanel
                    .frame(width: 260)

                centerConsole

                if displayManager.presentationModuleSettings.showsInspectorPanel {
                    livePanel
                        .frame(width: 190)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.92, green: 0.94, blue: 0.97))
        .animation(.easeInOut(duration: 0.22), value: selectedItemID)
        .animation(.easeInOut(duration: 0.22), value: selectedPage)
        .onAppear {
            selectedItemID = pdfManager.items.first?.id
        }
        .onChange(of: displayManager.currentMediaProjection?.source) { _, _ in
            syncSelectionToProjectedMedia()
        }
        .onReceive(NotificationCenter.default.publisher(for: .projectorNext)) { _ in
            stepMedia(1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .projectorPrevious)) { _ in
            stepMedia(-1)
        }
        .task(id: recognitionKey) {
            try? await Task.sleep(nanoseconds: 120_000_000)
            await analyzeSelectedSlideText()
        }
    }

    private var mediaToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MODULO DE PRESENTACIONES")
                    .font(.system(size: 18, weight: .bold))
                Text("PDFS, POWERPOINTS E INSUMOS PARA PRESENTAR EN VIVO")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let selectedItem {
                Text(selectedItem.kind == .pdf ? "PDF" : selectedItem.kind.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.76))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.90, green: 0.94, blue: 1.00))
                    .clipShape(Capsule())
            }

            Button("Importar archivos") {
                pdfManager.importMedia()
            }
            .buttonStyle(.borderedProminent)

            if let error = pdfManager.lastImportError {
                Text(error)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var centerConsole: some View {
        VStack(spacing: 12) {
            previewPanel
                .frame(maxHeight: .infinity)

            if displayManager.presentationModuleSettings.showsFilmstrip {
                filmstripPanel
                    .frame(height: 164)
            }
        }
    }

    private var libraryPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Biblioteca")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(pdfManager.items.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(pdfManager.items) { item in
                        Button(action: {
                            selectedItemID = item.id
                            selectedPage = 0
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .lineLimit(2)
                                        Text(item.kind.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                HStack {
                                    Text(item.kind == .pdf ? "\(pdfManager.pageCount(for: item)) páginas" : "Recurso único")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            .padding(12)
                            .background(selectedItemID == item.id ? Color.blue.opacity(0.16) : Color.white.opacity(0.86))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedItemID == item.id ? Color.blue.opacity(0.38) : Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selectedItemID == item.id ? 1.0 : 0.985)
                        .contextMenu {
                            Button("Eliminar", role: .destructive) {
                                pdfManager.removeItem(id: item.id)
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var previewPanel: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("En directo")
                        .font(.system(size: 20, weight: .bold))
                        .contentTransition(.interpolate)
                    Text(previewStatusSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .contentTransition(.interpolate)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button("Anterior") {
                        stepMedia(-1, autoProject: false)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canStepBackward)

                    Button("Siguiente") {
                        stepMedia(1, autoProject: false)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canStepForward)

                    Button("Proyectar") {
                        projectSelected()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedItem == nil || previewImage == nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ZStack {
                projectorMonitorSurface
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                compactInfoPill(title: "PROYECTANDO", value: displayManager.isProjectorActive ? "SI" : "NO")
                compactInfoPill(title: "PÁGINA", value: selectedItem.map { pageLabel(for: $0, page: selectedPage) } ?? "-")
                if displayManager.presentationModuleSettings.allowsVerseShortcut && !detectedVerseMatches.isEmpty {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 8) {
                            ForEach(detectedVerseMatches, id: \.identityKey) { match in
                                Button {
                                    selectedDetectedVerseKey = match.identityKey
                                } label: {
                                    Text(match.reference.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .lineLimit(1)
                                }
                                .buttonStyle(.bordered)
                                .tint(selectedDetectedVerseKey == match.identityKey ? .blue : nil)
                            }
                        }
                    }

                    Button {
                        projectSelectedDetectedVerse()
                    } label: {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("p", modifiers: [.command])
                }
                Spacer()
                Button("Limpiar") {
                    displayManager.clearProjection()
                }
                .buttonStyle(.bordered)
                .disabled(!displayManager.isProjectorActive)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var livePanel: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Control")
                    .font(.system(size: 15, weight: .bold))

                infoRow(title: "Estado", value: livePanelStateLabel)
                infoRow(title: "Archivo", value: selectedItem?.title ?? "Sin selección")
                infoRow(title: "Página", value: selectedItem.map { pageLabel(for: $0, page: selectedPage) } ?? "-")

                Button("Limpiar proyección") {
                    displayManager.clearProjection()
                }
                .buttonStyle(.bordered)
                .disabled(!displayManager.isProjectorActive)
            }
            .padding(16)
            .background(panelBackground)
            .frame(height: 150, alignment: .top)

            if displayManager.presentationModuleSettings.showsDetectionPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Versículo detectado")
                        .font(.system(size: 15, weight: .bold))

                    if isRecognizingText && displayManager.presentationModuleSettings.analyzesTextForVerses {
                        ProgressView("Analizando texto")
                            .controlSize(.small)
                    } else if !detectedVerseMatches.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(detectedVerseMatches, id: \.identityKey) { match in
                                    Button {
                                        selectedDetectedVerseKey = match.identityKey
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(match.reference)
                                                .font(.system(size: 12, weight: .bold))
                                            Text(match.verseText)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                                .lineLimit(3)
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(selectedDetectedVerseKey == match.identityKey ? Color.blue.opacity(0.14) : Color.white.opacity(0.65))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        Text("⌘P proyecta el versículo seleccionado. ESC vuelve a la diapositiva.")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.20, green: 0.54, blue: 0.89))
                    } else if !recognizedText.isEmpty {
                        Text("No se encontró una referencia bíblica válida en esta diapositiva.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Selecciona una página para analizar el texto.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(panelBackground)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var filmstripPanel: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 10) {
                HStack {
                    Text("Tira de páginas")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Button {
                        stepMedia(-1, autoProject: false)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!canStepBackward)
                    Button {
                        stepMedia(1, autoProject: false)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!canStepForward)
                    Text("Un clic selecciona • doble clic proyecta")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(filmstripIndexes, id: \.self) { page in
                            Button {
                                selectedPage = page
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.white.opacity(0.92))

                                        if let image = thumbnailImage(for: page) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .padding(8)
                                        } else {
                                            Image(systemName: "doc.richtext")
                                                .font(.system(size: 24, weight: .light))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(width: 150, height: 86)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(selectedPage == page ? Color.blue.opacity(0.45) : Color.black.opacity(0.08), lineWidth: selectedPage == page ? 2 : 1)
                                    )

                                    Text(filmstripLabel(for: page))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(selectedPage == page ? 1.0 : 0.975)
                            .id(page)
                            .simultaneousGesture(TapGesture(count: 2).onEnded {
                                selectedPage = page
                                projectSelected()
                            })
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onChange(of: selectedPage) { _, page in
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(page, anchor: .center)
                }
            }
            .onChange(of: displayManager.currentMediaProjection?.source) { _, _ in
                syncSelectionToProjectedMedia()
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(selectedPage, anchor: .center)
                }
            }
        }
    }

    private func compactInfoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.96, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var filmstripIndexes: [Int] {
        guard let selectedItem else { return [] }
        let count = max(pdfManager.pageCount(for: selectedItem), 1)
        return Array(0..<count)
    }

    private var previewImage: NSImage? {
        guard let selectedItem else { return nil }
        return pdfManager.image(for: selectedItem, pageIndex: selectedPage)
    }

    private var selectedSubtitle: String {
        guard let selectedItem else { return "Sin selección" }
        return selectedItem.kind == .pdf ? pageLabel(for: selectedItem, page: selectedPage) : selectedItem.kind.rawValue
    }

    private var isBibleOverlayOnPresentation: Bool {
        guard let source = displayManager.currentProjection?.source.lowercased() else { return false }
        return source.hasPrefix("bible-from-media:") && displayManager.canRestorePresentationProjection
    }

    private var previewStatusSubtitle: String {
        if isBibleOverlayOnPresentation {
            return "Versículo bíblico sobrepuesto con tema Biblia"
        }
        if displayManager.projectionMode == .media {
            return "Salida enlazada al proyector"
        }
        return selectedItem?.title ?? "Selecciona una presentación"
    }

    private var livePanelStateLabel: String {
        if isBibleOverlayOnPresentation {
            return "Versículo sobrepuesto"
        }
        return displayManager.projectionMode == .media ? "Proyectando" : "En espera"
    }

    private var canStepBackward: Bool {
        let state = projectedOrSelectedState
        guard let item = state.item else { return false }
        if item.kind == .pdf {
            return state.page > 0
        }
        guard let index = pdfManager.items.firstIndex(where: { $0.id == item.id }) else { return false }
        return index > 0
    }

    private var canStepForward: Bool {
        let state = projectedOrSelectedState
        guard let item = state.item else { return false }
        if item.kind == .pdf {
            return state.page < max(pdfManager.pageCount(for: item) - 1, 0)
        }
        guard let index = pdfManager.items.firstIndex(where: { $0.id == item.id }) else { return false }
        return index < pdfManager.items.count - 1
    }

    private func pageLabel(for item: MediaItem, page: Int) -> String {
        item.kind == .pdf ? "Página \(page + 1) de \(max(pdfManager.pageCount(for: item), 1))" : item.kind.rawValue
    }

    private func filmstripLabel(for page: Int) -> String {
        guard let selectedItem else { return "" }
        return selectedItem.kind == .pdf ? "Página \(page + 1)" : selectedItem.kind.rawValue
    }

    private func thumbnailImage(for page: Int) -> NSImage? {
        guard let selectedItem else { return nil }
        return pdfManager.image(for: selectedItem, pageIndex: page, targetSize: CGSize(width: 320, height: 180))
    }

    private var projectorMonitorSurface: some View {
        ZStack {
            Color.black.opacity(0.08)

            Projector(isExternalDisplay: true, previewFitsContainer: true)
                .environmentObject(displayManager)
                .environmentObject(themeManager)
                .environmentObject(announcementManager)
                .allowsHitTesting(false)
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                HStack {
                    Label("Monitor espejo", systemImage: "rectangle.on.rectangle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.94))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.56))
                        .clipShape(Capsule())
                    Spacer()
                }
                Spacer()
            }
            .padding(10)
        }
    }

    private func projectSelected() {
        guard let selectedItem,
              let image = pdfManager.image(for: selectedItem, pageIndex: selectedPage) else { return }
        let subtitle = selectedItem.kind == .pdf ? "Página \(selectedPage + 1)" : selectedItem.kind.rawValue
        displayManager.projectMedia(
            source: "media:\(selectedItem.id.uuidString):\(selectedPage)",
            title: selectedItem.title,
            subtitle: subtitle,
            image: image
        )
        syncSelectionToProjectedMedia()
    }

    private func stepMedia(_ direction: Int, autoProject: Bool = true) {
        let state = projectedOrSelectedState
        guard let item = state.item else { return }
        if item.kind == .pdf {
            let count = pdfManager.pageCount(for: item)
            let nextPage = min(max(state.page + direction, 0), max(count - 1, 0))
            selectedItemID = item.id
            selectedPage = nextPage
            if autoProject {
                projectSelected()
            }
        } else {
            let all = pdfManager.items
            guard let index = all.firstIndex(where: { $0.id == item.id }) else { return }
            let next = min(max(index + direction, 0), all.count - 1)
            selectedItemID = all[next].id
            selectedPage = 0
            if autoProject {
                projectSelected()
            }
        }
    }

    private var projectedOrSelectedState: (item: MediaItem?, page: Int) {
        guard
            displayManager.projectionMode == .media,
            let source = displayManager.currentMediaProjection?.source,
            let state = mediaState(from: source)
        else {
            return (selectedItem, selectedPage)
        }
        return state
    }

    private func syncSelectionToProjectedMedia() {
        guard
            displayManager.projectionMode == .media,
            let source = displayManager.currentMediaProjection?.source,
            let state = mediaState(from: source)
        else {
            return
        }
        selectedItemID = state.item?.id
        selectedPage = state.page
    }

    private var recognitionKey: String {
        "\(selectedItemID?.uuidString ?? "none")-\(selectedPage)"
    }

    @MainActor
    private func analyzeSelectedSlideText() async {
        guard displayManager.presentationModuleSettings.analyzesTextForVerses else {
            recognizedText = ""
            detectedVerseMatches = []
            selectedDetectedVerseKey = nil
            isRecognizingText = false
            return
        }
        guard let selectedItem else {
            recognizedText = ""
            detectedVerseMatches = []
            selectedDetectedVerseKey = nil
            return
        }

        isRecognizingText = true
        let text = await pdfManager.recognizedText(for: selectedItem, pageIndex: selectedPage)
        recognizedText = text
        detectedVerseMatches = bibleManager.detectReferences(in: text)
        selectedDetectedVerseKey = detectedVerseMatches.first?.identityKey
        isRecognizingText = false
    }

    private func projectSelectedDetectedVerse() {
        guard let match = detectedVerseMatches.first(where: { $0.identityKey == selectedDetectedVerseKey }) ?? detectedVerseMatches.first else {
            return
        }
        displayManager.projectDetectedBibleVerseFromMedia(match)
    }

    private func mediaState(from source: String) -> (item: MediaItem?, page: Int)? {
        let components = source.components(separatedBy: ":")
        guard components.count == 3, components[0] == "media", let uuid = UUID(uuidString: components[1]) else {
            return nil
        }
        let page = Int(components[2]) ?? 0
        let item = pdfManager.items.first { $0.id == uuid }
        return (item, page)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .multilineTextAlignment(.trailing)
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.90))
    }
}
