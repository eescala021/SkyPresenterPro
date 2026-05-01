import SwiftUI

struct WorshipImportExportPanelView: View {
    @ObservedObject var viewModel: WorshipImportExportPanelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(alignment: .top, spacing: 12) {
                editorColumn
                previewColumn
            }

            footer
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Importar / Exportar Alabanzas")
                    .font(.system(size: 22, weight: .black))

                Spacer()

                Text(viewModel.mode == .importing ? "Modo importar" : "Modo exportar")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(viewModel.mode == .importing ? .blue : .green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill((viewModel.mode == .importing ? Color.blue : Color.green).opacity(0.14)))
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Título")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    TextField("Título de la canción", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Artista")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    TextField("Ministerio / autor", text: $viewModel.artist)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var editorColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                actionButton("Importar", color: .blue, action: viewModel.importSong)
                actionButton("Exportar", color: .green, action: viewModel.exportCurrentSong)
                actionButton("Cargar archivo (.txt)", color: .orange, action: viewModel.loadTextFile)
                actionButton("Copiar resultado", color: .purple, action: viewModel.copyResult)
                actionButton("Cancelar", color: .secondary, action: viewModel.cancel)
            }

            TextEditor(text: $viewModel.text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .onChange(of: viewModel.text) { _, _ in
                    viewModel.textDidChange()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var previewColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vista previa de secciones")
                .font(.system(size: 14, weight: .black))

            if viewModel.previewSections.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sin secciones detectadas")
                        .font(.system(size: 13, weight: .bold))
                    Text("Pega una letra o carga un archivo para ver el resultado del parser.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.035))
                )
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.previewSections) { section in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(section.title)
                                        .font(.system(size: 13, weight: .black))
                                    Spacer()
                                    Text("\(section.slideCount) slides")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }

                                Text(section.lines.joined(separator: "\n"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.88))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .frame(width: 290, maxHeight: .infinity, alignment: .topLeading)
    }

    private var footer: some View {
        Text(viewModel.message)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(viewModel.isErrorMessage ? Color.red : Color.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((viewModel.isErrorMessage ? Color.red : Color.green).opacity(0.08))
            )
    }

    private func actionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(color == .secondary ? Color.primary : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill((color == .secondary ? Color.black : color).opacity(color == .secondary ? 0.06 : 0.14))
                )
        }
        .buttonStyle(.plain)
    }
}
