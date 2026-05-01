import SwiftUI

struct SettingsThemesPane: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var mediaLibraryManager: MediaLibraryManager
    @EnvironmentObject private var themeResolver: ThemeResolver

    @State private var selectedThemeID: UUID?
    @State private var selectedThemeIDs: Set<UUID> = []
    @State private var draft = ThemeEditorDraft()
    @State private var activeTab: ThemeEditorTab = .font
    @State private var themePendingDeletion: ProjectionTheme?
    @State private var isBatchSheetPresented = false
    @State private var previewText = "Santo, santo, santo\nDios todopoderoso"
    @State private var previewReference = "JUAN 3:16"
    @State private var previewComment = "Comentario del operador"

    private let columns = [
        GridItem(.adaptive(minimum: 132, maximum: 156), spacing: 10)
    ]

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    actions
                    themeGrid
                    editorCard
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            SettingsPreviewSidebar {
                livePreview
                SettingsMetricCard(
                    title: "Selección batch",
                    value: "\(selectedThemeIDs.count)",
                    detail: "Temas listos para aplicar patch selectivo.",
                    tint: selectedThemeIDs.isEmpty ? .secondary : .blue
                )
                SettingsMetricCard(
                    title: "Multimedia",
                    value: "\(mediaLibraryManager.imageItems.count + mediaLibraryManager.videoItems.count)",
                    detail: "Fondos disponibles para probar temas.",
                    tint: .orange
                )
                Spacer()
            }
            .frame(width: 300, alignment: .top)
        }
        .onAppear {
            if selectedThemeID == nil, let first = themeManager.availableThemes.first {
                selectTheme(first)
            }
        }
        .sheet(isPresented: $isBatchSheetPresented) {
            ThemeBatchPatchSheet(
                selectionCount: selectedThemeIDs.count,
                draft: draft,
                onApply: { patch in
                    themeManager.applyPatch(
                        to: selectedThemeIDs,
                        editedTheme: draft.projectionTheme(id: selectedThemeID),
                        patch: patch
                    )
                    isBatchSheetPresented = false
                },
                onCancel: {
                    isBatchSheetPresented = false
                }
            )
            .frame(width: 520, height: 620)
        }
        .alert(
            "Eliminar tema",
            isPresented: Binding(
                get: { themePendingDeletion != nil },
                set: { isPresented in
                    if !isPresented { themePendingDeletion = nil }
                }
            ),
            presenting: themePendingDeletion
        ) { theme in
            Button("Cancelar", role: .cancel) { themePendingDeletion = nil }
            Button("Eliminar", role: .destructive) { confirmDeletion(of: theme) }
        } message: { theme in
            Text("Se eliminará el tema \"\(theme.name)\" de la biblioteca.")
        }
    }

    private var header: some View {
        SettingsSectionIntro(
            eyebrow: "Theme Engine PRO",
            title: "Temas",
            subtitle: "Editor modular con preview fiel, cajas por línea y patch selectivo"
        )
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button("Nuevo tema") {
                selectedThemeID = nil
                draft = ThemeEditorDraft()
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button("Guardar") {
                saveDraft()
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button("Batch selectivo") {
                isBatchSheetPresented = true
            }
            .disabled(selectedThemeIDs.isEmpty)
            .buttonStyle(SecondaryActionButtonStyle())

            Button("Aplicar global") {
                let theme = draft.projectionTheme(id: selectedThemeID)
                themeManager.setGlobalTheme(theme)
                themeResolver.setGlobalTheme(theme)
            }
            .buttonStyle(SecondaryActionButtonStyle())

            if let theme = selectedTheme {
                Button("Eliminar") {
                    themePendingDeletion = theme
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
    }

    private var themeGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(themeManager.availableThemes) { theme in
                Button {
                    selectTheme(theme)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        themePreview(theme)
                            .frame(height: 78)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        HStack {
                            ConsoleAdaptiveText(
                                theme.name,
                                style: .compactLabel,
                                baseFont: .system(size: 11, weight: .black)
                            )
                            .foregroundStyle(selectedThemeID == theme.id ? AppColors.accent : .primary)

                            Spacer()

                            Button {
                                toggleBatchSelection(theme.id)
                            } label: {
                                Image(systemName: selectedThemeIDs.contains(theme.id) ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(selectedThemeIDs.contains(theme.id) ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        ConsoleAdaptiveText(
                            theme.scope.displayName,
                            style: .compactLabel,
                            baseFont: .system(size: 10, weight: .semibold),
                            allowsCondensing: false
                        )
                        .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                    .aspectRatio(1, contentMode: .fit)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedThemeID == theme.id ? AppColors.accent.opacity(0.10) : Color.black.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                selectedThemeIDs.contains(theme.id) ? Color.blue :
                                selectedThemeID == theme.id ? AppColors.accent : Color.black.opacity(0.08),
                                lineWidth: selectedThemeIDs.contains(theme.id) || selectedThemeID == theme.id ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var editorCard: some View {
        SettingsPanelCard(
            title: "Editor de tema PRO",
            subtitle: "Fuente, alineación, efectos, forma, comentario, referencia y visualización"
        ) {
            TextField("Nombre", text: $draft.name)
                .textFieldStyle(.roundedBorder)

            Picker("Alcance", selection: $draft.scope) {
                ForEach(ProjectionThemeScope.allCases, id: \.self) { scope in
                    Text(scope.displayName).tag(scope)
                }
            }
            .pickerStyle(.segmented)

            Picker("Sección", selection: $activeTab) {
                ForEach(ThemeEditorTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch activeTab {
                case .font:
                    fontTab
                case .effects:
                    effectsTab
                case .background:
                    backgroundTab
                case .comment:
                    commentTab
                case .reference:
                    referenceTab
                case .configuration:
                    configurationTab
                case .visualization:
                    visualizationTab
                }
            }

            HStack(spacing: 8) {
                Button("Guardar") { saveDraft() }
                    .buttonStyle(PrimaryActionButtonStyle())
                Button("Aplicar a Biblia") {
                    themeResolver.setTheme(draft.projectionTheme(id: selectedThemeID), forModule: .bible)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                Button("Aplicar a Alabanzas") {
                    themeResolver.setTheme(draft.projectionTheme(id: selectedThemeID), forModule: .worship)
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
    }

    private var fontTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Familia de fuente opcional", text: $draft.fontFamily)
                .textFieldStyle(.roundedBorder)
            Toggle("Negrita", isOn: $draft.bold).toggleStyle(.switch)
            Toggle("Cursiva", isOn: $draft.italic).toggleStyle(.switch)
            ColorPicker("Texto principal", selection: $draft.textColor)
            ColorPicker("Texto secundario", selection: $draft.secondaryTextColor)
            slider("Tamaño", value: $draft.fontSize, range: 18...72)
            slider("Espaciado líneas", value: $draft.lineSpacing, range: 0...40)
            slider("Espaciado letras", value: $draft.characterSpacing, range: -2...10)
            Picker("Horizontal", selection: $draft.textAlignment) {
                Text("Izquierda").tag(TextAlignment.leading)
                Text("Centro").tag(TextAlignment.center)
                Text("Derecha").tag(TextAlignment.trailing)
            }
            .pickerStyle(.segmented)
            Picker("Vertical", selection: $draft.verticalAlignment) {
                ForEach(ProjectionVerticalAlignment.allCases, id: \.self) { alignment in
                    Text(alignment.displayName).tag(alignment)
                }
            }
            .pickerStyle(.segmented)
            slider("Margen", value: $draft.textMargin, range: 0...90)
            slider("Desplazamiento vertical", value: $draft.verticalOffset, range: -180...180)
        }
    }

    private var effectsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Sombra", isOn: $draft.shadowEnabled).toggleStyle(.switch)
            ColorPicker("Color sombra", selection: $draft.shadowColor)
            slider("Radio sombra", value: $draft.shadowRadius, range: 0...24)
            slider("Sombra X", value: $draft.shadowX, range: -20...20)
            slider("Sombra Y", value: $draft.shadowY, range: -20...20)
            Toggle("Contorno", isOn: $draft.outlineEnabled).toggleStyle(.switch)
            ColorPicker("Color contorno", selection: $draft.outlineColor)
            slider("Ancho contorno", value: $draft.outlineWidth, range: 0...8)
            Toggle("Glow", isOn: $draft.glowEnabled).toggleStyle(.switch)
            slider("Radio glow", value: $draft.glowRadius, range: 0...28)
        }
    }

    private var backgroundTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            ColorPicker("Color fondo", selection: $draft.backgroundColor)
            slider("Opacidad fondo", value: $draft.backgroundOpacity, range: 0...1)
            Picker("Caja de texto", selection: $draft.textBoxMode) {
                ForEach(ProjectionTextBoxMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            ColorPicker("Color caja", selection: $draft.textBoxColor)
            slider("Opacidad caja", value: $draft.textBoxOpacity, range: 0...1)
            slider("Padding H", value: $draft.textBoxHorizontalPadding, range: 0...80)
            slider("Padding V", value: $draft.textBoxVerticalPadding, range: 0...40)
            slider("Esquina", value: $draft.textBoxCornerRadius, range: 0...40)
        }
    }

    private var commentTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Mostrar comentario", isOn: $draft.commentVisible).toggleStyle(.switch)
            TextField("Fuente comentario opcional", text: $draft.commentFontFamily)
                .textFieldStyle(.roundedBorder)
            Toggle("Comentario negrita", isOn: $draft.commentBold).toggleStyle(.switch)
            Toggle("Comentario cursiva", isOn: $draft.commentItalic).toggleStyle(.switch)
            ColorPicker("Color comentario", selection: $draft.commentColor)
            slider("Tamaño comentario", value: $draft.commentFontSize, range: 10...48)
        }
    }

    private var referenceTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Mostrar referencia", isOn: $draft.showReference).toggleStyle(.switch)
            TextField("Fuente referencia opcional", text: $draft.referenceFontFamily)
                .textFieldStyle(.roundedBorder)
            ColorPicker("Color referencia", selection: $draft.referenceColor)
            slider("Tamaño referencia", value: $draft.referenceFontSize, range: 10...48)
            Picker("Posición referencia", selection: $draft.referencePosition) {
                ForEach(ProjectionReferencePosition.allCases, id: \.self) { position in
                    Text(position.displayName).tag(position)
                }
            }
            .pickerStyle(.segmented)
            Toggle("Caja propia referencia", isOn: $draft.referenceBoxEnabled).toggleStyle(.switch)
            ColorPicker("Color caja referencia", selection: $draft.referenceBoxColor)
            slider("Opacidad caja referencia", value: $draft.referenceBoxOpacity, range: 0...1)
        }
    }

    private var configurationTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Convertir texto a mayúsculas", isOn: $draft.uppercaseEnabled).toggleStyle(.switch)
            Toggle("Permitir salto de línea", isOn: $draft.wrapText).toggleStyle(.switch)
            TextField("Transición opcional", text: $draft.transitionName)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var visualizationTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Texto de ejemplo", text: $previewText, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            TextField("Referencia ejemplo", text: $previewReference)
                .textFieldStyle(.roundedBorder)
            TextField("Comentario ejemplo", text: $previewComment)
                .textFieldStyle(.roundedBorder)
            slider("Ancho útil", value: $draft.maxTextWidth, range: 0.35...1.0)
        }
    }

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview fiel")
                .font(.system(size: 12, weight: .black))
            ZStack {
                draft.backgroundColor
                    .opacity(draft.backgroundOpacity)
                TextRenderEngineView(
                    layout: TextRenderEngine.layout(
                        input: TextRenderInput(
                            title: nil,
                            lines: previewText.components(separatedBy: .newlines).filter { !$0.isEmpty },
                            comment: previewComment,
                            reference: previewReference,
                            theme: draft.projectionTheme(id: selectedThemeID),
                            renderScale: 0.36
                        )
                    )
                )
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func themePreview(_ theme: ProjectionTheme) -> some View {
        ZStack {
            theme.backgroundColor.opacity(theme.backgroundOpacity)
            TextRenderEngineView(
                layout: TextRenderEngine.layout(
                    input: TextRenderInput(
                        title: nil,
                        lines: ["Aa Bb Cc"],
                        comment: nil,
                        reference: "REF",
                        theme: theme,
                        renderScale: 0.25
                    )
                )
            )
        }
    }

    private var selectedTheme: ProjectionTheme? {
        themeManager.availableThemes.first(where: { $0.id == selectedThemeID })
    }

    private func selectTheme(_ theme: ProjectionTheme) {
        selectedThemeID = theme.id
        draft = ThemeEditorDraft(theme: theme)
    }

    private func saveDraft() {
        let theme = draft.projectionTheme(id: selectedThemeID)
        if selectedThemeID == nil {
            themeManager.addTheme(theme)
            selectedThemeID = theme.id
        } else {
            themeManager.updateTheme(theme)
        }
    }

    private func toggleBatchSelection(_ id: UUID) {
        if selectedThemeIDs.contains(id) {
            selectedThemeIDs.remove(id)
        } else {
            selectedThemeIDs.insert(id)
        }
    }

    private func confirmDeletion(of theme: ProjectionTheme) {
        themeManager.deleteTheme(theme)
        selectedThemeIDs.remove(theme.id)
        if let next = themeManager.availableThemes.first {
            selectTheme(next)
        } else {
            selectedThemeID = nil
            draft = ThemeEditorDraft()
        }
        themePendingDeletion = nil
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
            Slider(value: value, in: range)
            Text(value.wrappedValue.formatted(.number.precision(.fractionLength(0...2))))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .frame(width: 46, alignment: .trailing)
        }
    }
}

private enum ThemeEditorTab: CaseIterable {
    case font
    case effects
    case background
    case comment
    case reference
    case configuration
    case visualization

    var title: String {
        switch self {
        case .font: return "Fuente"
        case .effects: return "Efecto"
        case .background: return "Fondo"
        case .comment: return "Comentario"
        case .reference: return "Referencia"
        case .configuration: return "Config"
        case .visualization: return "Preview"
        }
    }
}

private struct ThemeEditorDraft {
    var name: String = ""
    var scope: ProjectionThemeScope = .universal
    var fontFamily = ""
    var fontSize: Double = 30
    var bold = true
    var italic = false
    var textColor: Color = .white
    var secondaryTextColor: Color = .white.opacity(0.8)
    var textAlignment: TextAlignment = .center
    var verticalAlignment: ProjectionVerticalAlignment = .center
    var lineSpacing: Double = 14
    var characterSpacing: Double = 0
    var textMargin: Double = 28
    var verticalOffset: Double = 0
    var maxTextWidth: Double = 0.86
    var backgroundColor: Color = .black
    var backgroundOpacity: Double = 1
    var shadowEnabled = false
    var shadowRadius: Double = 4
    var shadowColor: Color = .black.opacity(0.5)
    var shadowX: Double = 0
    var shadowY: Double = 2
    var outlineEnabled = false
    var outlineColor: Color = .black
    var outlineWidth: Double = 2
    var glowEnabled = false
    var glowRadius: Double = 4
    var textBoxMode: ProjectionTextBoxMode = .none
    var textBoxColor: Color = .black
    var textBoxOpacity: Double = 0.55
    var textBoxHorizontalPadding: Double = 22
    var textBoxVerticalPadding: Double = 8
    var textBoxCornerRadius: Double = 10
    var uppercaseEnabled = false
    var wrapText = true
    var transitionName = ""
    var commentVisible = true
    var commentFontFamily = ""
    var commentFontSize: Double = 20
    var commentBold = false
    var commentItalic = false
    var commentColor: Color = .white.opacity(0.72)
    var showReference = true
    var referenceFontFamily = ""
    var referenceFontSize: Double = 20
    var referenceColor: Color = .white.opacity(0.75)
    var referencePosition: ProjectionReferencePosition = .belowText
    var referenceBoxEnabled = false
    var referenceBoxColor: Color = .black
    var referenceBoxOpacity: Double = 0.45

    init() {}

    init(theme: ProjectionTheme) {
        name = theme.name
        scope = theme.scope
        fontFamily = theme.fontFamily ?? ""
        fontSize = theme.fontSize
        bold = theme.fontWeight == .bold || theme.fontWeight == .black || theme.fontWeight == .heavy || theme.fontWeight == .semibold
        italic = theme.italic
        textColor = theme.textColor
        secondaryTextColor = theme.secondaryTextColor
        textAlignment = theme.textAlignment
        verticalAlignment = theme.verticalAlignment
        lineSpacing = theme.lineSpacing
        characterSpacing = theme.characterSpacing
        textMargin = theme.textMargin
        verticalOffset = theme.verticalOffset
        maxTextWidth = theme.maxTextWidth
        backgroundColor = theme.backgroundColor
        backgroundOpacity = theme.backgroundOpacity
        shadowEnabled = theme.shadowEnabled
        shadowRadius = theme.shadowRadius
        shadowColor = theme.shadowColor
        shadowX = theme.shadowX
        shadowY = theme.shadowY
        outlineEnabled = theme.outlineEnabled
        outlineColor = theme.outlineColor
        outlineWidth = theme.outlineWidth
        glowEnabled = theme.glowEnabled
        glowRadius = theme.glowRadius
        textBoxMode = theme.textBoxMode
        textBoxColor = theme.textBoxColor
        textBoxOpacity = theme.textBoxOpacity
        textBoxHorizontalPadding = theme.textBoxHorizontalPadding
        textBoxVerticalPadding = theme.textBoxVerticalPadding
        textBoxCornerRadius = theme.textBoxCornerRadius
        uppercaseEnabled = theme.uppercaseEnabled
        wrapText = theme.wrapText
        transitionName = theme.transitionName ?? ""
        commentVisible = theme.commentVisible
        commentFontFamily = theme.commentFontFamily ?? ""
        commentFontSize = theme.commentFontSize
        commentBold = theme.commentBold
        commentItalic = theme.commentItalic
        commentColor = theme.commentColor
        showReference = theme.showReference
        referenceFontFamily = theme.referenceFontFamily ?? ""
        referenceFontSize = theme.referenceFontSize
        referenceColor = theme.referenceColor
        referencePosition = theme.referencePosition
        referenceBoxEnabled = theme.referenceBoxEnabled
        referenceBoxColor = theme.referenceBoxColor
        referenceBoxOpacity = theme.referenceBoxOpacity
    }

    func projectionTheme(id: UUID? = nil) -> ProjectionTheme {
        ProjectionTheme(
            id: id ?? UUID(),
            name: name.isEmpty ? "Tema nuevo" : name,
            scope: scope,
            backgroundStyle: .solid,
            backgroundGradient: LinearGradient(colors: [backgroundColor, backgroundColor], startPoint: .topLeading, endPoint: .bottomTrailing),
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            fontFamily: fontFamily.isEmpty ? nil : fontFamily,
            fontSize: fontSize,
            fontWeight: bold ? .bold : .regular,
            italic: italic,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            textAlignment: textAlignment,
            verticalAlignment: verticalAlignment,
            lineSpacing: lineSpacing,
            characterSpacing: characterSpacing,
            textMargin: textMargin,
            verticalOffset: verticalOffset,
            maxTextWidth: maxTextWidth,
            shadowEnabled: shadowEnabled,
            shadowRadius: shadowRadius,
            shadowColor: shadowColor,
            shadowX: shadowX,
            shadowY: shadowY,
            outlineEnabled: outlineEnabled,
            outlineColor: outlineColor,
            outlineWidth: outlineWidth,
            glowEnabled: glowEnabled,
            glowRadius: glowRadius,
            textBoxMode: textBoxMode,
            textBoxColor: textBoxColor,
            textBoxOpacity: textBoxOpacity,
            textBoxHorizontalPadding: textBoxHorizontalPadding,
            textBoxVerticalPadding: textBoxVerticalPadding,
            textBoxCornerRadius: textBoxCornerRadius,
            showReference: showReference,
            uppercaseEnabled: uppercaseEnabled,
            wrapText: wrapText,
            transitionName: transitionName.isEmpty ? nil : transitionName,
            commentVisible: commentVisible,
            commentFontFamily: commentFontFamily.isEmpty ? nil : commentFontFamily,
            commentFontSize: commentFontSize,
            commentBold: commentBold,
            commentItalic: commentItalic,
            commentColor: commentColor,
            referenceFontFamily: referenceFontFamily.isEmpty ? nil : referenceFontFamily,
            referenceFontSize: referenceFontSize,
            referenceColor: referenceColor,
            referencePosition: referencePosition,
            referenceBoxEnabled: referenceBoxEnabled,
            referenceBoxColor: referenceBoxColor,
            referenceBoxOpacity: referenceBoxOpacity
        )
    }
}
