import SwiftUI

struct WorshipSlidesGrid: View {
    @EnvironmentObject private var viewModel: WorshipViewModel
    @EnvironmentObject private var livePresentationEngine: LivePresentationEngine
    @Environment(\.threePaneIsResizing) private var isThreePaneResizing

    let song: WorshipSong

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if isThreePaneResizing {
                resizingPlaceholder
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(viewModel.selectedSections.enumerated()), id: \.element.id) { index, section in
                                let state = cardState(for: section)
                                card(section: section, index: index, state: state)
                                    .id(section.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        scrollToFocus(with: proxy, animated: false)
                    }
                    .onChange(of: focusSectionID) { _, _ in
                        scrollToFocus(with: proxy, animated: true)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Grilla")
                    .font(.system(size: 13, weight: .black))

                Text("Vista visual de diapositivas con preview real y selección rápida.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(viewModel.selectedSections.count) diapositivas")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.secondary)
        }
    }

    private func card(section: WorshipSection, index: Int, state: WorshipGridCardState) -> some View {
        let slide = previewSlide(for: section)

        return Button {
            viewModel.selectSection(section)
            viewModel.prepareSection(section)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ProjectionPreviewSurface(
                    slide: slide,
                    source: .worship,
                    songID: viewModel.liveState.currentSongID,
                    sectionID: section.id
                )
                .frame(height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(numberTint(for: state))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(numberTint(for: state).opacity(0.12)))

                    Spacer()

                    switch state {
                    case .live:
                        statusChip("EN VIVO", color: .green)
                    case .next:
                        statusChip("SIGUIENTE", color: .orange)
                    case .selected:
                        statusChip("SELECCIÓN", color: .blue)
                    case .idle:
                        EmptyView()
                    }
                }

                Text(section.lines.prefix(2).joined(separator: " "))
                    .font(.system(size: 11, weight: state == .live ? .black : .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor(for: state))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor(for: state), lineWidth: state == .live ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            viewModel.selectSection(section)
            viewModel.prepareSection(section)
            viewModel.projectPreparedSection()
        }
    }

    private var focusSectionID: UUID? {
        if let liveSection = viewModel.selectedSections.first(where: isProjecting) {
            return liveSection.id
        }
        return viewModel.preparedSection?.id ?? viewModel.selectedSection?.id
    }

    private var resizingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.black.opacity(0.03))
            .overlay(alignment: .leading) {
                Text("Grilla visual congelada durante resize.")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
    }

    private func previewSlide(for section: WorshipSection) -> ProjectionSlide {
        ProjectionSlide(
            id: .deterministicProjectionID(seed: ["worship-grid", song.id.uuidString, section.id.uuidString].joined(separator: "|")),
            title: nil,
            subtitle: nil,
            lines: section.lines,
            notes: section.operatorNotes
        )
    }

    private func isProjecting(_ section: WorshipSection) -> Bool {
        guard livePresentationEngine.state.source == .worship,
              let currentSlide = livePresentationEngine.state.currentSlide else { return false }
        return !section.lines.isEmpty && currentSlide.lines == section.lines
    }

    private func cardState(for section: WorshipSection) -> WorshipGridCardState {
        if isProjecting(section) {
            return .live
        }
        if viewModel.preparedSection?.id == section.id {
            return .next
        }
        if viewModel.selectedSection?.id == section.id {
            return .selected
        }
        return .idle
    }

    private func scrollToFocus(with proxy: ScrollViewProxy, animated: Bool) {
        guard let focusSectionID else { return }
        let action = {
            proxy.scrollTo(focusSectionID, anchor: .center)
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.18), action)
        } else {
            action()
        }
    }

    private func backgroundColor(for state: WorshipGridCardState) -> Color {
        switch state {
        case .live:
            return Color.green.opacity(0.18)
        case .next:
            return Color.orange.opacity(0.12)
        case .selected:
            return Color.blue.opacity(0.08)
        case .idle:
            return Color.black.opacity(0.03)
        }
    }

    private func borderColor(for state: WorshipGridCardState) -> Color {
        switch state {
        case .live:
            return Color.green.opacity(0.82)
        case .next:
            return Color.orange.opacity(0.60)
        case .selected:
            return Color.blue.opacity(0.45)
        case .idle:
            return Color.black.opacity(0.05)
        }
    }

    private func numberTint(for state: WorshipGridCardState) -> Color {
        switch state {
        case .live:
            return .green
        case .next:
            return .orange
        case .selected:
            return .blue
        case .idle:
            return .secondary
        }
    }

    private func statusChip(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

private enum WorshipGridCardState {
    case live
    case next
    case selected
    case idle
}
