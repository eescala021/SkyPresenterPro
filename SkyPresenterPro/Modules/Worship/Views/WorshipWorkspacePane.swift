import SwiftUI

struct WorshipWorkspacePane: View {
    @EnvironmentObject private var viewModel: WorshipViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let song = viewModel.selectedSong {
                header(song)
                Divider()
                editorFields
                Divider()
                SongEditorTextArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                footer(song)
            } else {
                WorshipEmptyStateView(text: "Selecciona una alabanza para comenzar.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func header(_ song: WorshipSong) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 16, weight: .black))
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            stateChip("Slides \(parsedSections.count)", color: .blue)
            stateChip("En cola \(viewModel.queue.count)", color: .green)

            if viewModel.editorState.isDirty {
                stateChip("Sin guardar", color: .orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var editorFields: some View {
        HStack(spacing: 8) {
            TextField("Título", text: $viewModel.editorState.title)
                .textFieldStyle(.roundedBorder)
                .onChange(of: viewModel.editorState.title) { _, _ in
                    viewModel.markEditorDirty()
                }

            TextField("Artista", text: $viewModel.editorState.artist)
                .textFieldStyle(.roundedBorder)
                .onChange(of: viewModel.editorState.artist) { _, _ in
                    viewModel.markEditorDirty()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func footer(_ song: WorshipSong) -> some View {
        HStack(spacing: 8) {
            Text("Cada salto de línea define una diapositiva.")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Revertir") {
                viewModel.selectSong(song)
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button("Guardar") {
                viewModel.rebuildSelectedSongFromEditor()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var parsedSections: [WorshipSection] {
        WorshipEditorParser.parse(
            title: viewModel.editorState.title,
            artist: viewModel.editorState.artist,
            rawText: viewModel.editorState.rawText
        )
    }

    private func stateChip(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
