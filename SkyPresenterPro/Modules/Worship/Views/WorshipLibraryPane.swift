import SwiftUI

struct WorshipLibraryPane: View {
    @EnvironmentObject private var viewModel: WorshipViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            searchBar
            Divider()

            if viewModel.filteredSongs.isEmpty {
                WorshipEmptyStateView(text: "No hay alabanzas para mostrar.")
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.filteredSongs) { song in
                            WorshipSongRow(
                                song: song,
                                isSelected: viewModel.selectedSongID == song.id
                            )
                            .onTapGesture {
                                viewModel.selectSong(song)
                            }
                            .contextMenu {
                                Button("Agregar a servicio") {
                                    viewModel.addToQueue(song)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Alabanzas")
                .font(.system(size: 14, weight: .black))

            Spacer()

            metricChip("\(viewModel.filteredSongs.count)", tint: Color.blue.opacity(0.12), foreground: .blue)
            metricChip("\(viewModel.queue.count)", tint: Color.green.opacity(0.12), foreground: .green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)

            TextField("Buscar...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func metricChip(_ title: String, tint: Color, foreground: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint))
    }
}
