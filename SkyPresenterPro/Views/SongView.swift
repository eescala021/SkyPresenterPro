import AppKit
import SwiftUI
import UniformTypeIdentifiers

private func mainScreenInterfaceScale() -> CGFloat {
    let frame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1512, height: 982)
    let widthScale = frame.width / 1512
    let heightScale = frame.height / 982
    return min(max(min(widthScale, heightScale), 0.90), 1.18)
}

private enum SongEditorTextAlignment: String, CaseIterable {
    case left
    case center

    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        }
    }
}

private struct SongEditorTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var alignment: SongEditorTextAlignment
    @Binding var spellCheckingEnabled: Bool
    let fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.string = text
        configure(textView: textView)
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        configure(textView: textView)
    }

    private func configure(textView: NSTextView) {
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .medium)
        textView.alignment = alignment.nsTextAlignment
        textView.isContinuousSpellCheckingEnabled = spellCheckingEnabled
        textView.isAutomaticSpellingCorrectionEnabled = spellCheckingEnabled

        let range = NSRange(location: 0, length: textView.string.utf16.count)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment.nsTextAlignment
        paragraphStyle.lineSpacing = 4
        textView.textStorage?.beginEditing()
        textView.textStorage?.setAttributes(
            [
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: NSColor.labelColor
            ],
            range: range
        )
        textView.textStorage?.endEditing()
        textView.typingAttributes = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.labelColor
        ]
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}

// MARK: - SongSlidePreview

private struct SongSlidePreview: View {
    let slide: SongPresentationSlide
    let isSelected: Bool
    let isProjected: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var displayManager: DisplayManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                miniBackground
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                ProjectionContentCanvas(
                    payload: ProjectionPayload(
                        source: "preview",
                        reference: slide.reference,
                        body: slide.body,
                        backgroundOverride: slide.backgroundAssetID.flatMap { assetID in
                            slide.backgroundAssetKind.map { ProjectionBackgroundOverride(assetID: assetID, assetKind: $0) }
                        }
                    ),
                    settings: displayManager.projectionStyleSettings,
                    size: CGSize(width: geo.size.width * 3, height: geo.size.height * 3)
                )
                .scaleEffect(0.33)
                .allowsHitTesting(false)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(borderColor, lineWidth: isProjected ? 3 : (isSelected ? 2 : 1))
        )
        .overlay(alignment: .topLeading) {
            Text(slide.title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .padding(5)
        }
    }

    @ViewBuilder
    private var miniBackground: some View {
        if let override = slide.backgroundAssetID.flatMap({ assetID in
            slide.backgroundAssetKind.map { ProjectionBackgroundOverride(assetID: assetID, assetKind: $0) }
        }) {
            if let image = themeManager.backgroundImage(for: override) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                themeManager.themeSettings.gradientPreset.gradient
            }
        } else {
            switch themeManager.themeSettings.kind {
            case .gradient:
                themeManager.themeSettings.gradientPreset.gradient
            case .image:
                if let image = themeManager.backgroundImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    GradientPreset.midnight.gradient
                }
            case .video:
                if let thumb = themeManager.videoThumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    GradientPreset.midnight.gradient
                }
            }
        }
    }

    private var borderColor: Color {
        if isProjected { return .green }
        if isSelected { return .blue }
        return .black.opacity(0.15)
    }
}

private struct ColumnResizeHandle: View {
    @Binding var width: Double
    let minWidth: Double
    let maxWidth: Double
    @State private var startWidth: Double?

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.10))
                    .frame(width: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if startWidth == nil {
                            startWidth = width
                        }
                        let proposed = (startWidth ?? width) + Double(value.translation.width)
                        width = min(maxWidth, max(minWidth, proposed))
                    }
                    .onEnded { _ in
                        startWidth = nil
                    }
            )
    }
}

// MARK: - SongEditorSheet

private struct SongEditorSheet: View {
    @ObservedObject var viewState: SongViewState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDraftIndex: Int = 0
    @State private var editorAlignment: SongEditorTextAlignment = .left
    @State private var spellCheckingEnabled: Bool = true
    @FocusState private var editorFocus: EditorFocus?

    private enum EditorFocus: Hashable {
        case title
        case author
        case key
        case lyrics
        case slideLabel
    }

    private var interfaceScale: CGFloat {
        mainScreenInterfaceScale()
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * interfaceScale
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, scaled(18))
                .padding(.vertical, scaled(12))

            Divider()

            HStack(spacing: 0) {
                sectionListPanel
                    .frame(width: scaled(260))

                Divider()

                editorPanel
            }
        }
        .frame(width: scaled(1440), height: scaled(860))
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.92, green: 0.94, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            clampSelectedIndex()
            viewState.setInteractionContext(.editingLyrics)
        }
        .onChange(of: viewState.editDraft?.sections.count ?? 0) { _, _ in
            clampSelectedIndex()
        }
        .onChange(of: editorFocus) { _, newValue in
            switch newValue {
            case .title, .author, .key:
                viewState.setInteractionContext(.editingMetadata)
            case .lyrics:
                viewState.setInteractionContext(.editingLyrics)
            case .slideLabel:
                viewState.setInteractionContext(.editingSlideLabel)
            case nil:
                viewState.setInteractionContext(.editingLyrics)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: scaled(14)) {
            VStack(alignment: .leading, spacing: 3) {
                Text(viewState.editDraft?.songID != nil ? "Canción" : "Nueva canción")
                    .font(.system(size: scaled(18), weight: .bold))
                Text("Editor en tiempo real · Doble Enter crea una nueva diapositiva")
                    .font(.system(size: scaled(11), weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                editorToolButton(systemName: "square.and.arrow.down") {
                    viewState.saveEdit(stayOpen: true)
                }
                .help("Guardar")
                .disabled(viewState.editDraft?.title.trimmingCharacters(in: .whitespaces).isEmpty ?? true)

                editorToolButton(systemName: "text.alignleft") {
                    editorAlignment = .left
                }
                .help("Justificar a la izquierda solo el editor")

                editorToolButton(systemName: "text.aligncenter") {
                    editorAlignment = .center
                }
                .help("Centrar solo el editor")

                editorTextGlyphButton("AA") {
                    uppercaseAllSlides()
                }
                .help("Cambiar a mayúsculas")

                editorTextGlyphButton("aa") {
                    lowercaseAllSlides()
                }
                .help("Cambiar a minúsculas")

                editorToolButton(systemName: spellCheckingEnabled ? "textformat.abc.dottedunderline" : "textformat.abc") {
                    spellCheckingEnabled.toggle()
                }
                .help("Corrector ortográfico")

                editorToolButton(systemName: "rectangle.grid.2x2") {
                    appendNewSlide()
                }
                .help("Nueva diapositiva")

                editorToolButton(systemName: "plus.square.on.square") {
                    duplicateSection(at: selectedDraftIndex)
                }
                .help("Duplicar diapositiva")
                .disabled(selectedDraftSection == nil)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                Button("Cancelar") {
                    viewState.cancelEdit()
                }
                .keyboardShortcut(.cancelAction)

                Button("Guardar y cerrar") {
                    viewState.saveEdit()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(viewState.editDraft?.title.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            }
        }
    }

    private var statsCard: some View {
        HStack(spacing: 10) {
            editorMetricCard(title: "Diapositivas", value: "\(viewState.editDraft?.sections.count ?? 0)")
            editorMetricCard(title: "Tono", value: viewState.editDraft?.key.isEmpty == false ? (viewState.editDraft?.key ?? "") : "--")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var sectionListPanel: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Diapositivas")
                            .font(.system(size: 14, weight: .bold))
                    Text("Cada bloque separado por doble Enter genera una diapositiva. Selecciona una para editarla y reordenar el flujo.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    contextBadge(text: "\(viewState.editDraft?.sections.count ?? 0)", color: Color(red: 0.20, green: 0.54, blue: 0.89))
                }

                HStack(spacing: 8) {
                    Button("Duplicar") {
                        duplicateSection(at: selectedDraftIndex)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(selectedDraftSection == nil)

                    Button("Eliminar", role: .destructive) {
                        deleteSection(at: selectedDraftIndex)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled((viewState.editDraft?.sections.count ?? 0) <= 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array((viewState.editDraft?.sections ?? []).enumerated()), id: \.element.id) { index, section in
                        Button(action: { selectedDraftIndex = index }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(section.displayTitle(index: index))
                                        .font(.system(size: 12, weight: .bold))
                                    Spacer()
                                    Text("#\(index + 1)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                Text(section.lyricsText.isEmpty ? "Diapositiva vacía" : section.lyricsText)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(section.lyricsText.isEmpty ? .secondary : Color(red: 0.21, green: 0.25, blue: 0.33))
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(selectedDraftIndex == index ? Color.blue.opacity(0.14) : Color.white.opacity(0.88))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selectedDraftIndex == index ? Color.blue.opacity(0.4) : Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Duplicar") { duplicateSection(at: index) }
                            Button("Eliminar", role: .destructive) { deleteSection(at: index) }
                        }
                    }
                }
                .padding(10)
            }
        }
        .background(Color.white.opacity(0.72))
    }

    private var editorPanel: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                metadataPanel
                lyricsEditorCard
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            selectedSlideInspector
                .frame(width: scaled(410))
        }
        .padding(18)
    }

    private var metadataPanel: some View {
        HStack(spacing: 10) {
            editorField(title: "Título", placeholder: "Título de la alabanza", text: Binding(
                get: { viewState.editDraft?.title ?? "" },
                set: { viewState.editDraft?.title = $0 }
            ))
            .focused($editorFocus, equals: .title)

            editorField(title: "Autor", placeholder: "Autor / Ministerio", text: Binding(
                get: { viewState.editDraft?.author ?? "" },
                set: { viewState.editDraft?.author = $0 }
            ))
            .focused($editorFocus, equals: .author)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tono")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                TextField("Ej: G", text: Binding(
                    get: { viewState.editDraft?.key ?? "" },
                    set: { viewState.editDraft?.key = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .focused($editorFocus, equals: .key)
            }
            .frame(width: 84)
        }
        .overlay(alignment: .trailing) {
            Text("METADATOS")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.trailing, 8)
                .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var lyricsEditorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Letra corrida")
                        .font(.system(size: 13, weight: .bold))
                    Text("Escribe la letra corrida. El editor segmenta en vivo, actualiza miniaturas y mantiene la ventana limpia.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                contextBadge(text: "DOBLE ENTER", color: Color(red: 0.60, green: 0.38, blue: 0.18))
            }

            SongEditorTextView(
                text: Binding(
                    get: { viewState.draftLyricsText },
                    set: { viewState.updateDraftLyrics($0) }
                ),
                alignment: $editorAlignment,
                spellCheckingEnabled: $spellCheckingEnabled,
                fontSize: scaled(17)
            )
            .focused($editorFocus, equals: .lyrics)
            .padding(10)
            .background(
                LinearGradient(
                    colors: [Color.white, Color(red: 0.985, green: 0.987, blue: 0.995)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var selectedSlideInspector: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Temas y vista")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("INSPECTOR")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.secondary)
            }

            Text("La miniatura, el preview y el fondo de la diapositiva se actualizan mientras editas.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            if !(viewState.editDraft?.sections.isEmpty ?? true) {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ],
                        spacing: 8
                    ) {
                        ForEach(Array((viewState.editDraft?.sections ?? []).enumerated()), id: \.element.id) { index, section in
                            Button {
                                selectedDraftIndex = index
                            } label: {
                                SongSlidePreview(
                                    slide: SongPresentationSlide(
                                        id: section.id.uuidString,
                                        source: "song:editor-grid-preview",
                                        title: section.displayTitle(index: index),
                                        reference: "",
                                        body: section.lyricsText.isEmpty ? " " : section.lyricsText,
                                        presenterNotes: "",
                                        backgroundAssetID: section.backgroundAssetID,
                                        backgroundAssetKind: section.backgroundAssetKind
                                    ),
                                    isSelected: selectedDraftIndex == index,
                                    isProjected: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 190)
            }

            if let section = selectedDraftSection {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Diapositiva seleccionada")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    SongSlidePreview(
                        slide: SongPresentationSlide(
                            id: section.id.uuidString,
                            source: "song:editor-preview",
                            title: section.displayTitle(index: selectedDraftIndex),
                            reference: section.displayTitle(index: selectedDraftIndex),
                            body: section.lyricsText,
                            presenterNotes: "",
                            backgroundAssetID: section.backgroundAssetID,
                            backgroundAssetKind: section.backgroundAssetKind
                        ),
                        isSelected: true,
                        isProjected: false
                    )
                    .frame(height: 150)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rótulo opcional")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Ej: Coro, Verso 2, Puente", text: Binding(
                        get: { section.title },
                        set: { viewState.updateDraftSectionTitle(at: selectedDraftIndex, title: $0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .focused($editorFocus, equals: .slideLabel)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Fondo de esta diapositiva")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(themeManager.backgroundLabel(for: section.backgroundAssetID, kind: section.backgroundAssetKind))
                        .font(.system(size: 12, weight: .bold))

                    HStack(spacing: 8) {
                        Button("Tema global") {
                            viewState.updateDraftSectionBackground(at: selectedDraftIndex, assetID: nil, assetKind: nil)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Menu("Imagen") {
                            ForEach(themeManager.imageLibrary) { asset in
                                Button(asset.title) {
                                    viewState.updateDraftSectionBackground(
                                        at: selectedDraftIndex,
                                        assetID: asset.id,
                                        assetKind: .image
                                    )
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Menu("Video") {
                            ForEach(themeManager.videoLibrary) { asset in
                                Button(asset.title) {
                                    viewState.updateDraftSectionBackground(
                                        at: selectedDraftIndex,
                                        assetID: asset.id,
                                        assetKind: .video
                                    )
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    editorAssetStrip(
                        title: "Imágenes",
                        assets: themeManager.imageLibrary,
                        kind: .image
                    )

                    editorAssetStrip(
                        title: "Videos",
                        assets: themeManager.videoLibrary,
                        kind: .video
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Vista rápida")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(section.displayTitle(index: selectedDraftIndex))
                        .font(.system(size: 13, weight: .bold))
                    Text(section.lyricsText.isEmpty ? "Esta diapositiva todavía está vacía." : section.lyricsText)
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Acciones")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Button("Duplicar diapositiva") {
                        duplicateSection(at: selectedDraftIndex)
                    }
                    .buttonStyle(.bordered)

                    Button("Eliminar diapositiva", role: .destructive) {
                        deleteSection(at: selectedDraftIndex)
                    }
                    .buttonStyle(.bordered)
                    .disabled((viewState.editDraft?.sections.count ?? 0) <= 1)
                }
            } else {
                Text("Empieza escribiendo la letra para generar diapositivas.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var selectedDraftSection: SongSectionDraft? {
        guard let sections = viewState.editDraft?.sections, sections.indices.contains(selectedDraftIndex) else { return nil }
        return sections[selectedDraftIndex]
    }

    private func editorField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func editorToolButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.bordered)
    }

    private func editorTextGlyphButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.bordered)
    }

    private func appendNewSlide() {
        var text = viewState.draftLyricsText
        if !text.isEmpty && !text.hasSuffix("\n\n") {
            text.append(text.hasSuffix("\n") ? "\n" : "\n\n")
        }
        if text.isEmpty {
            text = "\n\n"
        }
        viewState.updateDraftLyrics(text)
        selectedDraftIndex = max((viewState.editDraft?.sections.count ?? 1) - 1, 0)
    }

    private func duplicateSection(at index: Int) {
        viewState.duplicateDraftSection(at: index)
        selectedDraftIndex = min(index + 1, (viewState.editDraft?.sections.count ?? 1) - 1)
    }

    private func deleteSection(at index: Int) {
        viewState.deleteDraftSection(at: index)
        clampSelectedIndex()
    }

    private func clampSelectedIndex() {
        let count = viewState.editDraft?.sections.count ?? 0
        selectedDraftIndex = count == 0 ? 0 : min(selectedDraftIndex, count - 1)
    }

    private func uppercaseSelectedSlide() {
        guard var draft = viewState.editDraft, draft.sections.indices.contains(selectedDraftIndex) else { return }
        draft.sections[selectedDraftIndex].lyricsText = draft.sections[selectedDraftIndex].lyricsText.uppercased(with: Locale(identifier: "es"))
        viewState.editDraft = draft
    }

    private func uppercaseAllSlides() {
        guard var draft = viewState.editDraft else { return }
        draft.sections = draft.sections.map { section in
            var updatedSection = section
            updatedSection.lyricsText = section.lyricsText.uppercased(with: Locale(identifier: "es"))
            return updatedSection
        }
        viewState.editDraft = draft
    }

    private func lowercaseAllSlides() {
        guard var draft = viewState.editDraft else { return }
        draft.sections = draft.sections.map { section in
            var updatedSection = section
            updatedSection.lyricsText = section.lyricsText.lowercased(with: Locale(identifier: "es"))
            return updatedSection
        }
        viewState.editDraft = draft
    }

    private var contextColor: Color {
        switch viewState.interactionContext {
        case .browsing:
            return .secondary
        case .searching:
            return Color(red: 0.76, green: 0.44, blue: 0.16)
        case .editingMetadata:
            return Color(red: 0.20, green: 0.54, blue: 0.89)
        case .editingLyrics:
            return Color(red: 0.18, green: 0.63, blue: 0.38)
        case .editingSlideLabel:
            return Color(red: 0.60, green: 0.38, blue: 0.18)
        case .navigatingSlides:
            return Color(red: 0.14, green: 0.56, blue: 0.72)
        }
    }

    private func contextBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }

    private func editorMetricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.97, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func editorAssetStrip(title: String, assets: [ThemeAsset], kind: ThemeAsset.AssetKind) -> some View {
        if !assets.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(assets.prefix(8)) { asset in
                            Button {
                                viewState.updateDraftSectionBackground(
                                    at: selectedDraftIndex,
                                    assetID: asset.id,
                                    assetKind: kind
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Group {
                                        if kind == .image, let image = themeManager.imageThumbnail(for: asset) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else if kind == .video, let image = themeManager.videoThumbnail(for: asset) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.black.opacity(0.08))
                                                .overlay(
                                                    Image(systemName: kind == .image ? "photo" : "video")
                                                        .foregroundColor(.secondary)
                                                )
                                        }
                                    }
                                    .frame(width: 92, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                    Text(asset.title)
                                        .font(.system(size: 9, weight: .semibold))
                                        .lineLimit(1)
                                        .frame(width: 92, alignment: .leading)
                                }
                                .padding(6)
                                .background(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SongView

struct SongView: View {
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var announcementManager: AnnouncementManager
    @StateObject private var viewState = SongViewState()
    @FocusState private var librarySearchFocused: Bool
    @State private var draggedQueueSongID: SongItem.ID?
    @State private var draggedLibrarySongID: SongItem.ID?
    @State private var libraryMode: LibraryMode = .lyrics
    @AppStorage("song.column.libraryWidth") private var libraryColumnWidth: Double = 280
    @AppStorage("song.column.previewWidth") private var previewColumnWidth: Double = 320
    @AppStorage("song.column.serviceWidth") private var serviceColumnWidth: Double = 320

    private var interfaceScale: CGFloat {
        mainScreenInterfaceScale()
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * interfaceScale
    }

    private enum LibraryMode: String, CaseIterable {
        case lyrics = "Letras"
        case text = "Texto"
    }

    var body: some View {
        VStack(spacing: 8) {
            topToolbar
            mainConsole

            if displayManager.songModuleSettings.showsFilmstrip && isSongProjectionActive {
                bottomFilmstrip
                    .frame(height: scaled(142))
            }
        }
        .padding(8)
        .background(Color(red: 0.90, green: 0.91, blue: 0.93))
        .animation(.easeInOut(duration: 0.22), value: viewState.selectedSongID)
        .animation(.easeInOut(duration: 0.22), value: viewState.selectedSectionID)
        .animation(.easeInOut(duration: 0.22), value: viewState.searchText)
        .onAppear {
            viewState.configure(songManager: songManager, displayManager: displayManager, themeManager: themeManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .projectorNext)) { _ in
            viewState.stepSection(1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .projectorPrevious)) { _ in
            viewState.stepSection(-1)
        }
        .sheet(isPresented: $viewState.isEditing, onDismiss: {
            viewState.cancelEdit()
        }) {
            SongEditorSheet(viewState: viewState)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSongEditor)) { _ in
            if viewState.selectedSong == nil {
                viewState.beginNewSong()
            } else {
                viewState.beginEditing()
            }
        }
    }

    private var mainConsole: some View {
        HStack(spacing: 0) {
            if displayManager.songModuleSettings.showsLibraryPanel {
                leftSidebar
                    .frame(width: CGFloat(libraryColumnWidth))
                ColumnResizeHandle(
                    width: $libraryColumnWidth,
                    minWidth: 220,
                    maxWidth: 420
                )
            }

            lyricsColumnPanel
                .frame(minWidth: scaled(600))

            ColumnResizeHandle(
                width: $previewColumnWidth,
                minWidth: 280,
                maxWidth: 440
            )

            livePreviewPanel
                .frame(width: CGFloat(previewColumnWidth))

            ColumnResizeHandle(
                width: $serviceColumnWidth,
                minWidth: 260,
                maxWidth: 420
            )

            serviceQueueColumn
                .frame(width: CGFloat(serviceColumnWidth))
        }
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.18), lineWidth: 1)
        )
    }

    private var topToolbar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: scaled(14), weight: .bold))
                        .foregroundColor(.black.opacity(0.75))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MODULO DE ALABANZAS")
                            .font(.system(size: scaled(15), weight: .bold))
                        Text("LETRAS · HISTORIAL · PROYECCIÓN")
                            .font(.system(size: scaled(10), weight: .semibold))
                            .foregroundColor(.black.opacity(0.55))
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    ribbonGroup(title: "Biblioteca") {
                        Button {
                            viewState.beginNewSong()
                        } label: {
                            Label("Nueva", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)

                        Button("Importar") {
                            songManager.importSong()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Editor") {
                            if viewState.selectedSong == nil {
                                viewState.beginNewSong()
                            } else {
                                viewState.beginEditing()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    ribbonGroup(title: "Salida") {
                        transportButton(systemName: "backward.fill") {
                            viewState.stepSection(-1)
                        }

                        Button {
                            if let active = viewState.activeSection {
                                viewState.projectSection(active)
                            }
                        } label: {
                            Label("Proyectar", systemImage: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewState.activeSection == nil)

                        transportButton(systemName: "forward.fill") {
                            viewState.stepSection(1)
                        }
                    }
                }

                contextPill
            }

            HStack(spacing: 14) {
                Text("Visualización:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Monitor de exhibición")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)

                Divider().frame(height: 12)

                Text("Ver como:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Público")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    metricChip(title: "Biblioteca", value: "\(viewState.filteredSongs.count)")
                    metricChip(title: "Servicio", value: "\(songManager.queuedSongs.count)")
                    metricChip(title: "Slides", value: "\(viewState.presentationSlides.count)")
                }
            }
            .padding(.top, 1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(panelBackground)
    }

    private func transportButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: scaled(12), weight: .bold))
                .frame(width: scaled(32), height: scaled(32))
        }
        .buttonStyle(.bordered)
    }

    private func ribbonGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: scaled(8), weight: .heavy))
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                content()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Left Sidebar

    private var leftSidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(LibraryMode.allCases, id: \.rawValue) { mode in
                    Button {
                        libraryMode = mode
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(libraryMode == mode ? Color.white : Color(red: 0.92, green: 0.93, blue: 0.95))
                            .foregroundColor(libraryMode == mode ? Color.primary : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1), alignment: .bottom)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Letras")
                            .font(.system(size: 15, weight: .bold))
                        Text("BIBLIOTECA")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.black.opacity(0.55))
                    }
                    Spacer()
                    Text("\(viewState.filteredSongs.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }

                TextField("Buscar alabanza", text: $viewState.searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($librarySearchFocused)
                    .onChange(of: librarySearchFocused) { _, isFocused in
                        viewState.setInteractionContext(isFocused ? .searching : .browsing)
                    }

                Text("Filtra por título, autor o contenido de la letra.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    compactLibraryMetric(title: "Total", value: "\(songManager.songs.count)")
                    compactLibraryMetric(title: "Filtradas", value: "\(viewState.filteredSongs.count)")
                    compactLibraryMetric(title: "Tocadas", value: "\(songManager.playedSongIDs.count)")
                }

                HStack(spacing: 8) {
                    Button(action: { viewState.beginNewSong() }) {
                        Label("Nueva", systemImage: "plus")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.bordered)

                    Button("Importar") {
                        songManager.importSong()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Servicio") {
                        if let songID = viewState.selectedSongID {
                            songManager.enqueueSong(songID)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewState.selectedSongID == nil)
                }
            }
            .padding(14)
            .background(panelBackground)

            Divider()

            if libraryMode == .lyrics {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewState.filteredSongs) { song in
                            Button(action: { viewState.selectSong(song.id) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(song.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .lineLimit(2)
                                        Spacer()
                                        if !song.key.isEmpty {
                                            Text(song.key)
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 4)
                                                .background(Color(red: 0.21, green: 0.49, blue: 0.86))
                                                .clipShape(Capsule())
                                        }
                                        if songManager.playedSongIDs.contains(song.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color(red: 0.20, green: 0.64, blue: 0.38))
                                        }
                                    }

                                    if !song.author.isEmpty {
                                        Text(song.author)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Text(songPreviewSnippet(song))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.black.opacity(0.56))
                                        .lineLimit(2)

                                    HStack {
                                        Text("\(song.presentationSlides.count) diapositivas")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        if let bpm = song.bpm {
                                            Text("•")
                                                .foregroundColor(.secondary)
                                            Text("\(bpm) BPM")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(song.sections.count > 0 ? "\(song.sections.count) líneas" : "Sin letra")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(viewState.selectedSongID == song.id ? Color.blue.opacity(0.16) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(viewState.selectedSongID == song.id ? Color.blue.opacity(0.45) : Color.black.opacity(0.10), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .draggable(song.id.uuidString)
                            .onDrag {
                                draggedLibrarySongID = song.id
                                return NSItemProvider(object: song.id.uuidString as NSString)
                            }
                            .contextMenu {
                                Button("Editar") {
                                    viewState.selectSong(song.id)
                                    viewState.beginEditing()
                                }
                                Divider()
                                Button("Eliminar", role: .destructive) {
                                    songManager.removeSong(id: song.id)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                .background(panelBackground)
            } else {
                ScrollView {
                    Text(viewState.selectedSong.map(songPreviewSnippet) ?? "Selecciona una alabanza para ver el texto corrido.")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                }
                .background(panelBackground)
            }
        }
    }

    private var serviceQueueColumn: some View {
        VStack(spacing: 0) {
            serviceQueuePanel
                .padding(10)
            Spacer(minLength: 0)
        }
        .background(panelBackground)
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first else { return false }
            return handleQueueStringDrop(first, targetID: nil)
        }
        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
            handleQueueColumnDrop(providers: providers)
        }
    }

    // MARK: Center Panel

    private var lyricsColumnPanel: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Módulo de letra")
                        .font(.system(size: 14, weight: .bold))
                    Text(viewState.selectedSong?.title ?? "Selecciona una alabanza")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("Un clic selecciona · doble clic proyecta")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.black.opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if let song = viewState.selectedSong {
                Divider()

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(2)
                        if !song.author.isEmpty {
                            Text(song.author)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black.opacity(0.60))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        infoBadge(text: "\(viewState.presentationSlides.count) diapositivas", color: Color(red: 0.19, green: 0.50, blue: 0.84))
                        if !song.key.isEmpty {
                            infoBadge(text: "TONO \(song.key)", color: Color(red: 0.22, green: 0.61, blue: 0.41))
                        }
                        if let bpm = song.bpm {
                            infoBadge(text: "\(bpm) BPM", color: Color(red: 0.76, green: 0.46, blue: 0.16))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewState.presentationSlides.enumerated()), id: \.element.id) { index, slide in
                            Button {
                                viewState.selectedSectionID = slide.id
                                viewState.setInteractionContext(.navigatingSlides)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Text(String(format: "%02d", index))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(slide.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? slide.title : slide.body)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.18, green: 0.21, blue: 0.27))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(3)

                                        HStack(spacing: 6) {
                                            Text(slide.title.uppercased())
                                                .font(.system(size: 10, weight: .heavy))
                                                .foregroundColor(.secondary)

                                            if viewState.isProjected(slide) {
                                                Text("EN SALIDA")
                                                    .font(.system(size: 9, weight: .black))
                                                    .foregroundColor(Color(red: 0.14, green: 0.56, blue: 0.31))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                                .background(historyRowBackground(slide: slide))
                                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .id(slide.id)
                            .simultaneousGesture(TapGesture(count: 2).onEnded {
                                viewState.projectSection(slide)
                            })
                        }
                    }
                    .padding(8)
                }
                .onChange(of: viewState.selectedSectionID) { _, sectionID in
                    guard let sectionID else { return }
                    withAnimation(.easeInOut(duration: 0.16)) {
                        proxy.scrollTo(sectionID, anchor: .center)
                    }
                }
                .onAppear {
                    if let sectionID = viewState.selectedSectionID {
                        proxy.scrollTo(sectionID, anchor: .center)
                    }
                }
            }
        }
        .background(panelBackground)
    }

    private var livePreviewPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("En directo")
                        .font(.system(size: 14, weight: .bold))
                    Text(displayManager.songModuleSettings.showsCurrentAndNextPreview ? "Actual + siguiente" : "Diapositiva actual")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge
            }

            projectorPreviewCard(title: "En directo") {
                projectorMonitorSurface
            }
            .frame(height: 210)

            if displayManager.songModuleSettings.showsCurrentAndNextPreview {
                projectorPreviewCard(title: "Siguiente") {
                    upcomingSongSlidePreview
                        .allowsHitTesting(false)
                }
                .frame(height: 150)
            }

            if displayManager.songModuleSettings.showsLiveActionsPanel {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        transportButton(systemName: "backward.fill") {
                            viewState.stepSection(-1)
                        }
                        Button {
                            if let active = viewState.activeSection {
                                viewState.projectSection(active)
                            }
                        } label: {
                            Label("Proyectar", systemImage: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewState.activeSection == nil)
                        transportButton(systemName: "forward.fill") {
                            viewState.stepSection(1)
                        }
                        Spacer()
                        if let index = effectiveCurrentSlideIndex {
                            Text("\(index + 1) / \(effectiveSlides.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black.opacity(0.55))
                        }
                    }

                    if let active = viewState.activeSection {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(active.title.uppercased())
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.secondary)
                            Text(active.body.isEmpty ? "DIAPOSITIVA EN BLANCO" : active.body)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    }

                    Button("Limpiar") {
                        displayManager.clearProjection()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!displayManager.isProjectorActive)
                }
            }
        }
            .padding(10)
            .background(panelBackground)
    }

    private func projectorPreviewCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.secondary)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )
        }
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
                .clipped()

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

    @ViewBuilder
    private var upcomingSongSlidePreview: some View {
        GeometryReader { geo in
            ZStack {
                songPreviewBackground
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                ProjectionContentCanvas(
                    payload: effectiveNextSlide.map { slide in
                        ProjectionPayload(
                            source: slide.source,
                            reference: slide.reference,
                            body: slide.body,
                            backgroundOverride: slide.backgroundAssetID.flatMap { assetID in
                                slide.backgroundAssetKind.map { ProjectionBackgroundOverride(assetID: assetID, assetKind: $0) }
                            }
                        )
                    },
                    settings: displayManager.projectionStyleSettings,
                    size: geo.size
                )
            }
        }
    }

    private var serviceQueuePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Servicio")
                        .font(.system(size: 16, weight: .bold))
                    Text("PLAYLIST · ARRASTRA PARA REORDENAR")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.black.opacity(0.55))
                }
                Spacer()
                Text("\(songManager.queuedSongs.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Button("Añadir seleccionada") {
                    if let songID = viewState.selectedSongID {
                        songManager.enqueueSong(songID)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewState.selectedSongID == nil)

                Button("Limpiar cola", role: .destructive) {
                    songManager.clearQueue()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(songManager.queuedSongs.isEmpty)
            }
            .padding(8)
            .background(Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if songManager.queuedSongs.isEmpty {
                Text("Añade canciones para organizar el servicio.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .padding(12)
                    .background(Color.white.opacity(0.66))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(songManager.queuedSongs.enumerated()), id: \.element.id) { index, song in
                            serviceQueueRow(index: index, song: song)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: .infinity)
            }

            if let current = songManager.queuedSongs.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Siguiente sugerida")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.secondary)
                    Text(current.title)
                        .font(.system(size: 13, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(current.author.isEmpty ? "Sin autor" : current.author)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if !songManager.playedSongIDs.isEmpty {
                Divider()

                HStack {
                    Text("Tocadas")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Limpiar tocadas") {
                        songManager.clearPlayedMarks()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .background(panelBackground)
    }

    private func handleQueueDrop(providers: [NSItemProvider], targetID: SongItem.ID) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let value: String?
            if let data = item as? Data {
                value = String(data: data, encoding: .utf8)
            } else if let string = item as? String {
                value = string
            } else if let string = item as? NSString {
                value = string as String
            } else {
                value = nil
            }

            guard
                let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                !rawValue.isEmpty
            else { return }

            DispatchQueue.main.async {
                _ = handleQueueStringDrop(rawValue, targetID: targetID)
            }
        }
        return true
    }

    private func handleQueueColumnDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let value: String?
            if let data = item as? Data {
                value = String(data: data, encoding: .utf8)
            } else if let string = item as? String {
                value = string
            } else if let string = item as? NSString {
                value = string as String
            } else {
                value = nil
            }

            guard
                let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                !rawValue.isEmpty
            else { return }

            DispatchQueue.main.async {
                _ = handleQueueStringDrop(rawValue, targetID: nil)
            }
        }
        return true
    }

    private func handleQueueStringDrop(_ rawValue: String, targetID: SongItem.ID?) -> Bool {
        guard let sourceID = UUID(uuidString: rawValue) else { return false }

        draggedQueueSongID = nil
        draggedLibrarySongID = nil

        if !songManager.songs.contains(where: { $0.id == sourceID }) {
            return false
        }

        if let targetID,
           let toIndex = songManager.queuedSongs.firstIndex(where: { $0.id == targetID }) {
            if let fromIndex = songManager.queuedSongs.firstIndex(where: { $0.id == sourceID }) {
                guard fromIndex != toIndex else { return false }
                songManager.moveQueueItem(from: fromIndex, to: toIndex)
                return true
            }

            songManager.enqueueSong(sourceID)
            if let insertedIndex = songManager.queuedSongs.firstIndex(where: { $0.id == sourceID }),
               insertedIndex != toIndex {
                songManager.moveQueueItem(from: insertedIndex, to: toIndex)
            }
            return true
        }

        if !songManager.serviceQueue.contains(sourceID) {
            songManager.enqueueSong(sourceID)
        }
        return true
    }

    @ViewBuilder
    private func serviceQueueRow(index: Int, song: SongItem) -> some View {
        let isPlayed = songManager.playedSongIDs.contains(song.id)
        let isSelected = viewState.selectedSongID == song.id
        let isDragging = draggedQueueSongID == song.id

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 6) {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(.secondary)
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .frame(width: 24)

                Button {
                    viewState.selectSong(song.id)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(song.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.16, green: 0.19, blue: 0.24))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)

                            Spacer(minLength: 0)

                            if isPlayed {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.20, green: 0.64, blue: 0.38))
                                    .padding(.top, 1)
                            }
                        }

                        HStack(spacing: 8) {
                            Text(song.author.isEmpty ? "Sin autor" : song.author)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            if !song.key.isEmpty {
                                smallServicePill(song.key)
                            }
                            smallServicePill("\(song.presentationSlides.count) slides")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                serviceMoveButton(systemName: "chevron.up", disabled: index == 0) {
                    songManager.moveQueueItem(from: index, to: max(index - 1, 0))
                }

                serviceMoveButton(systemName: "chevron.down", disabled: index == songManager.queuedSongs.count - 1) {
                    songManager.moveQueueItem(from: index, to: min(index + 1, songManager.queuedSongs.count - 1))
                }

                Spacer(minLength: 0)

                Button(role: .destructive) {
                    songManager.dequeueSong(song.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isDragging ? Color.blue.opacity(0.12) : Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.35) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onDrag {
            draggedQueueSongID = song.id
            return NSItemProvider(object: song.id.uuidString as NSString)
        }
        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
            handleQueueDrop(providers: providers, targetID: song.id)
        }
    }

    @ViewBuilder
    private func serviceMoveButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(disabled)
    }

    private var historyPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Historial / Diapositivas")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("Doble clic para proyectar")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)

            Divider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(viewState.presentationSlides.enumerated()), id: \.element.id) { index, slide in
                        Button {
                            viewState.selectedSectionID = slide.id
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Text(String(format: "%02d", index))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(slide.body.isEmpty ? slide.title : slide.body)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)

                                    Text(slide.title)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(historyRowBackground(slide: slide))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(viewState.selectedSectionID == slide.id ? 1.0 : 0.985)
                        .simultaneousGesture(TapGesture(count: 2).onEnded {
                            viewState.projectSection(slide)
                        })
                    }
                }
                .padding(8)
            }
        }
        .background(panelBackground)
    }

    private func infoBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }

    private func metricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func compactLibraryMetric(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func songPreviewSnippet(_ song: SongItem) -> String {
        song.sections
            .map(\.bodyText)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func historyRowBackground(slide: SongPresentationSlide) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                viewState.selectedSectionID == slide.id
                ? Color.blue.opacity(0.15)
                : (viewState.isProjected(slide) ? Color.green.opacity(0.14) : Color.white.opacity(0.62))
            )
    }

    private var bottomFilmstrip: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 10) {
                HStack {
                    Text("Tira de Diapositivas")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Button {
                        viewState.stepSection(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled((effectiveCurrentSlideIndex ?? 0) <= 0)
                    Button {
                        viewState.stepSection(1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled((effectiveCurrentSlideIndex ?? 0) >= max(effectiveSlides.count - 1, 0))
                    Text("Un clic selecciona • doble clic proyecta")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black.opacity(0.55))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewState.presentationSlides.enumerated()), id: \.element.id) { index, slide in
                            VStack(spacing: 8) {
                                SongSlidePreview(
                                    slide: slide,
                                    isSelected: viewState.selectedSectionID == slide.id,
                                    isProjected: viewState.isProjected(slide)
                                )
                                .frame(width: scaled(210))
                                .scaleEffect(viewState.selectedSectionID == slide.id ? 1.0 : 0.97)

                                VStack(spacing: 4) {
                                    Text(slide.body.isEmpty ? slide.title : slide.body)
                                        .font(.system(size: scaled(12), weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.24))
                                        .lineLimit(3)
                                        .frame(maxWidth: .infinity)

                                    Text("\(index + 1)")
                                        .font(.system(size: scaled(10), weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.72))
                                        .clipShape(Capsule())
                                }
                                .frame(width: scaled(210))
                            }
                            .id(slide.id)
                            .onTapGesture(count: 1) {
                                viewState.selectedSectionID = slide.id
                            }
                            .simultaneousGesture(TapGesture(count: 2).onEnded {
                                viewState.projectSection(slide)
                            })
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }
            }
            .background(panelBackground)
            .animation(.easeInOut(duration: 0.18), value: viewState.selectedSectionID)
            .onChange(of: viewState.selectedSectionID) { _, slideID in
                guard let slideID else { return }
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(slideID, anchor: .center)
                }
            }
            .onChange(of: displayManager.currentProjection?.source) { _, source in
                guard let source,
                      let slide = viewState.presentationSlides.first(where: { $0.source == source }) else { return }
                viewState.selectedSectionID = slide.id
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(slide.id, anchor: .center)
                }
            }
        }
    }

    private func smallServicePill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Color(red: 0.34, green: 0.38, blue: 0.46))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.86))
            .clipShape(Capsule())
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    private var contextPill: some View {
        Label(viewState.interactionContext.rawValue.uppercased(), systemImage: contextIcon)
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(contextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(contextColor.opacity(0.10))
            .clipShape(Capsule())
    }

    private var contextIcon: String {
        switch viewState.interactionContext {
        case .browsing:
            return "square.grid.2x2"
        case .searching:
            return "magnifyingglass"
        case .editingMetadata:
            return "square.and.pencil"
        case .editingLyrics:
            return "text.cursor"
        case .editingSlideLabel:
            return "tag"
        case .navigatingSlides:
            return "play.rectangle"
        }
    }

    private var contextColor: Color {
        switch viewState.interactionContext {
        case .browsing:
            return .secondary
        case .searching:
            return Color(red: 0.76, green: 0.44, blue: 0.16)
        case .editingMetadata:
            return Color(red: 0.20, green: 0.54, blue: 0.89)
        case .editingLyrics:
            return Color(red: 0.18, green: 0.63, blue: 0.38)
        case .editingSlideLabel:
            return Color(red: 0.60, green: 0.38, blue: 0.18)
        case .navigatingSlides:
            return Color(red: 0.14, green: 0.56, blue: 0.72)
        }
    }

    private var statusBadge: some View {
        Circle()
            .fill(isSongProjectionActive ? Color(red: 0.13, green: 0.59, blue: 0.28) : Color(red: 0.18, green: 0.47, blue: 0.88))
            .frame(width: 10, height: 10)
    }

    private var activeSlideIndex: Int? {
        guard let active = viewState.activeSection else { return nil }
        return viewState.presentationSlides.firstIndex(where: { $0.id == active.id })
    }

    private var activeSectionTitle: String {
        viewState.activeSection?.title ?? "En directo"
    }

    private var activeSectionBody: String {
        guard let active = viewState.activeSection else { return "Selecciona una sección" }
        if active.title == "Final en blanco" {
            return " "
        }
        return active.body
    }

    private var isSongProjectionActive: Bool {
        displayManager.projectionMode == .content && displayManager.currentProjection?.source.hasPrefix("song:") == true
    }

    private var effectiveSlides: [SongPresentationSlide] {
        projectedSong?.presentationSlides ?? viewState.presentationSlides
    }

    private var projectedSong: SongItem? {
        guard let source = displayManager.currentProjection?.source, source.hasPrefix("song:") else { return nil }
        return songManager.songs.first { song in
            song.presentationSlides.contains { $0.source == source }
        }
    }

    private var effectiveCurrentSlide: SongPresentationSlide? {
        if let source = displayManager.currentProjection?.source,
           let slide = effectiveSlides.first(where: { $0.source == source }) {
            return slide
        }
        return viewState.activeSection
    }

    private var effectiveCurrentSlideIndex: Int? {
        guard let effectiveCurrentSlide else { return nil }
        return effectiveSlides.firstIndex(where: { $0.id == effectiveCurrentSlide.id })
    }

    private var effectiveNextSlide: SongPresentationSlide? {
        guard let effectiveCurrentSlideIndex else { return nil }
        let nextIndex = effectiveCurrentSlideIndex + 1
        guard effectiveSlides.indices.contains(nextIndex) else { return nil }
        return effectiveSlides[nextIndex]
    }

    @ViewBuilder
    private var songPreviewBackground: some View {
        switch themeManager.themeSettings.kind {
        case .gradient:
            themeManager.themeSettings.gradientPreset.gradient
        case .image:
            if let image = themeManager.backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                GradientPreset.midnight.gradient
            }
        case .video:
            if let thumb = themeManager.videoThumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                GradientPreset.midnight.gradient
            }
        }
    }
}
