import SwiftUI
import UniformTypeIdentifiers

struct WorshipServiceQueuePane: View {
    @EnvironmentObject private var viewModel: WorshipViewModel
    @State private var isQueueDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            actionBar
            Divider()

            Group {
                if viewModel.queue.isEmpty {
                    emptyQueueDropZone
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(viewModel.queue.enumerated()), id: \.element.id) { index, item in
                                queueRow(item, index: index)
                                    .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                                        handleDrop(providers: providers, destinationIndex: index)
                                    }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onDrop(of: [UTType.plainText.identifier], isTargeted: $isQueueDropTargeted) { providers in
                handleDrop(providers: providers, destinationIndex: viewModel.queue.count)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.84))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Servicio")
                    .font(.system(size: 14, weight: .black))

                metricChip("\(viewModel.queue.count)", tint: Color.green.opacity(0.12), foreground: .green)

                Spacer()
            }

            Text("Playlist operativa con reordenamiento libre, scroll vertical y drag and drop desde biblioteca.")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var actionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                actionButton("Cargar siguiente", systemImage: "arrow.down.to.line") {
                    viewModel.loadNextQueueItem()
                }
                .disabled(viewModel.nextQueueItem == nil)

                actionButton("Proyectar siguiente", systemImage: "play.fill") {
                    viewModel.projectNextQueueItem()
                }
                .disabled(viewModel.nextQueueItem == nil)
            }

            HStack(spacing: 6) {
                actionButton("Consumir siguiente", systemImage: "checkmark.circle.fill") {
                    viewModel.consumeNextQueueItem()
                }
                .disabled(viewModel.nextQueueItem == nil)

                actionButton("Limpiar servicio", systemImage: "trash.slash") {
                    viewModel.clearQueue()
                }
                .disabled(viewModel.queue.isEmpty)
            }

            if let nextQueueItem = viewModel.nextQueueItem {
                Text("Sigue: \(nextQueueItem.song.title)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func queueRow(_ item: WorshipQueueItem, index: Int) -> some View {
        let isSelected = viewModel.selectedSongID == item.song.id
        let isLive = viewModel.liveState.currentSongID == item.song.id
        let isLastProjected = viewModel.isLastProjectedSong(item.song.id)
        let hasProjected = viewModel.hasProjectedSong(item.song.id)

        return HStack(spacing: 8) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(isLive ? Color.green : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.song.title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isLive ? Color.green : .primary)
                    .lineLimit(1)

                Text(item.song.artist.isEmpty ? "Sin artista" : item.song.artist)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isLive {
                metricChip("LIVE", tint: Color.green.opacity(0.12), foreground: .green)
            } else if isLastProjected {
                metricChip("ULTIMA", tint: Color.purple.opacity(0.14), foreground: .purple)
            } else if isSelected {
                metricChip("SEL", tint: AppColors.accent.opacity(0.12), foreground: AppColors.accent)
            } else if index == 0 {
                metricChip("NEXT", tint: Color.orange.opacity(0.12), foreground: .orange)
            }

            if hasProjected && !isLive && !isLastProjected {
                metricChip("USADA", tint: Color.gray.opacity(0.14), foreground: .secondary)
            }

            queueActionButton("arrow.down.to.line") {
                viewModel.selectQueueItem(item)
            }

            queueActionButton("play.fill") {
                viewModel.projectQueueItem(item)
            }

            queueActionButton("checkmark.circle.fill") {
                viewModel.consumeQueueItem(item)
            }

            queueActionButton("arrow.up") {
                viewModel.moveQueueItemUp(item)
            }
            .disabled(!viewModel.canMoveQueueItemUp(item))

            queueActionButton("arrow.down") {
                viewModel.moveQueueItemDown(item)
            }
            .disabled(!viewModel.canMoveQueueItemDown(item))

            queueActionButton("trash") {
                viewModel.removeQueueItem(item)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isLive ? Color.green.opacity(0.10) : (isSelected ? AppColors.accent.opacity(0.08) : Color.black.opacity(0.03)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isLive ? Color.green.opacity(0.8) : (isSelected ? AppColors.accent.opacity(0.7) : Color.black.opacity(0.05)), lineWidth: isSelected || isLive ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onDrag {
            NSItemProvider(object: NSString(string: WorshipQueueDragPayload.queueItem(item.id).rawValue))
        }
        .onTapGesture {
            viewModel.selectQueueItem(item)
        }
        .onTapGesture(count: 2) {
            viewModel.projectQueueItem(item)
        }
    }

    private var emptyQueueDropZone: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isQueueDropTargeted ? AppColors.accent.opacity(0.10) : Color.black.opacity(0.03))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isQueueDropTargeted ? AppColors.accent : .secondary)

                    Text("Arrastra canciones desde la biblioteca para crear el servicio")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(isQueueDropTargeted ? AppColors.accent : .secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isQueueDropTargeted ? AppColors.accent.opacity(0.7) : Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))

                Text(title)
                    .font(.system(size: 10, weight: .black))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func queueActionButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
    }

    private func handleDrop(providers: [NSItemProvider], destinationIndex: Int) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let payload = object as? NSString else { return }
            let payloadValue = String(payload)
            Task { @MainActor in
                viewModel.handleQueueDropPayload(payloadValue, destinationIndex: destinationIndex)
            }
        }

        return true
    }

    private func metricChip(_ title: String, tint: Color, foreground: Color) -> some View {
        ConsoleAdaptiveText(
            text: title,
            style: .chip,
            font: .system(size: 10, weight: .black),
            color: foreground,
            lineLimit: 1
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint))
    }
}
