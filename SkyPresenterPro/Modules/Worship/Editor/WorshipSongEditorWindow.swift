import SwiftUI

struct WorshipSongEditorWindow: View {
    @ObservedObject var viewModel: WorshipSongEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                metadataPane
                    .frame(width: 300)
                Divider()
                lyricsPane
                    .frame(minWidth: 430)
                Divider()
                previewPane
                    .frame(minWidth: 500)
            }
            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Editor PRO de Alabanzas")
                    .font(.system(size: 18, weight: .black))
                Text("Mayúsculas automáticas, slides en tiempo real, tema y fondo por diapositiva.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            chip("\(viewModel.slides.count) slides", color: .blue)
            chip(viewModel.canSave ? "Listo" : "Incompleto", color: viewModel.canSave ? .green : .orange)
        }
        .padding(14)
    }

    private var metadataPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                metadataField("Título", text: Binding(
                    get: { viewModel.draft?.title ?? "" },
                    set: viewModel.updateTitle
                ), required: true)
                metadataField("Artista", text: Binding(
                    get: { viewModel.draft?.artist ?? "" },
                    set: viewModel.updateArtist
                ))
                metadataText("Nota", text: Binding(
                    get: { viewModel.draft?.note ?? "" },
                    set: viewModel.updateNote
                ))
                metadataField("Autor", text: Binding(
                    get: { viewModel.draft?.author ?? "" },
                    set: viewModel.updateAuthor
                ))
                metadataField("Derechos", text: Binding(
                    get: { viewModel.draft?.copyright ?? "" },
                    set: viewModel.updateCopyright
                ))
                WorshipSongEditorThemePane(viewModel: viewModel)
            }
            .padding(14)
        }
    }

    private var lyricsPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Letra")
                    .font(.system(size: 14, weight: .black))
                Spacer()
                Text("Doble Enter = nueva diapositiva · Máximo 4 líneas por slide")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: Binding(
                get: { viewModel.draft?.rawText ?? "" },
                set: viewModel.updateRawText
            ))
            .font(.system(size: 15, weight: .medium, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.035))
            )
        }
        .padding(14)
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Preview")
                    .font(.system(size: 14, weight: .black))
                Spacer()
                Text("Miniaturas reales")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                    ForEach(viewModel.slides) { slide in
                        WorshipSongEditorPreviewCard(
                            slide: slide,
                            projectionSlide: viewModel.previewSlide(for: slide),
                            theme: viewModel.previewTheme(for: slide),
                            backgroundItem: viewModel.previewBackground(for: slide),
                            isSelected: viewModel.selectedSlideID == slide.id,
                            selectAction: { viewModel.selectSlide(slide) },
                            applyBackground: { item in viewModel.applyBackground(item, to: slide) },
                            clearBackground: { viewModel.clearBackground(for: slide) },
                            applyBackgroundToAll: { item in viewModel.applyBackgroundToAll(item) }
                        )
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding(14)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text(viewModel.message)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(viewModel.isErrorMessage ? .red : .secondary)

            Spacer()

            Button("Cancelar") {
                viewModel.cancel()
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button("Guardar") {
                viewModel.save()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.canSave)
        }
        .padding(14)
    }

    private func metadataField(_ title: String, text: Binding<String>, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(required ? "\(title) *" : title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func metadataText(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.system(size: 12, weight: .medium))
                .frame(height: 84)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.04))
                )
        }
    }

    private func chip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

private struct WorshipSongEditorThemePane: View {
    @ObservedObject var viewModel: WorshipSongEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tema")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)

            Picker("Tema", selection: Binding(
                get: { viewModel.draft?.selectedThemeID ?? viewModel.availableThemes.first?.id },
                set: { id in
                    let theme = viewModel.availableThemes.first(where: { $0.id == id })
                    viewModel.selectTheme(theme)
                }
            )) {
                ForEach(viewModel.availableThemes) { theme in
                    Text(theme.name).tag(Optional(theme.id))
                }
            }
            .pickerStyle(.menu)
        }
    }
}

private struct WorshipSongEditorPreviewCard: View {
    let slide: WorshipSongEditorPreviewSlide
    let projectionSlide: ProjectionSlide
    let theme: ProjectionTheme?
    let backgroundItem: MediaLibraryItem?
    let isSelected: Bool
    let selectAction: () -> Void
    let applyBackground: (MediaLibraryItem?) -> Void
    let clearBackground: () -> Void
    let applyBackgroundToAll: (MediaLibraryItem?) -> Void

    @EnvironmentObject private var themeResolver: ThemeResolver

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(slide.sectionTitle)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(slide.lines.count) líneas")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            ProjectionPreviewSurface(
                slide: projectionSlide,
                source: .worship,
                themeOverride: theme,
                backgroundOverride: backgroundItem
            )
            .frame(height: 132)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.45) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: selectAction)
        .contextMenu {
            Button("Usar tema") {
                applyBackground(nil)
            }
            Divider()
            ForEach(backgroundChoices) { item in
                Button(item.name) {
                    applyBackground(item)
                }
            }
            Divider()
            Button("Quitar fondo") {
                clearBackground()
            }
            Menu("Aplicar a todas") {
                Button("Usar tema") {
                    applyBackgroundToAll(nil)
                }
                ForEach(backgroundChoices) { item in
                    Button(item.name) {
                        applyBackgroundToAll(item)
                    }
                }
            }
        }
    }

    private var backgroundChoices: [MediaLibraryItem] {
        let resolver = Mirror(reflecting: self)
        _ = resolver
        return []
    }
}
