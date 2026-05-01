import SwiftUI

struct WorshipSlidesPane: View {
    @EnvironmentObject private var viewModel: WorshipViewModel
    @EnvironmentObject private var livePresentationEngine: LivePresentationEngine

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 1) {
                panelHeader

                if viewModel.selectedSong == nil {
                    emptyState("Selecciona una alabanza para ver sus diapositivas.")
                } else if viewModel.selectedSections.isEmpty {
                    emptyState("La canción no tiene diapositivas disponibles.")
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(
                            columns: gridColumns(for: geometry.size.width),
                            spacing: 1
                        ) {
                            ForEach(Array(viewModel.selectedSections.enumerated()), id: \.element.id) { index, section in
                                slideTile(section, index: index)
                            }
                        }
                        .padding(1)
                        .background(Color.white.opacity(0.75))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var panelHeader: some View {
        ZStack(alignment: .center) {
            Text(headerDetail)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 7)
                .offset(y: 5)

            Text("DIAPOSITIVAS")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 26, alignment: .center)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(Color.white.opacity(0.75))
    }

    private func slideTile(_ section: WorshipSection, index: Int) -> some View {
        let state = tileState(for: section)
        let previewLines = Array(section.lines.prefix(2)).joined(separator: "\n")

        return Button {
            viewModel.selectSection(section)
            viewModel.prepareSection(section)
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    if state == .live {
                        stateDot(.green)
                    } else if state == .selected {
                        stateDot(AppColors.accent)
                    } else if state == .next {
                        stateDot(.orange)
                    }

                    Spacer(minLength: 0)
                }
                .frame(height: 8)

                Text(String(index + 1))
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(numberColor(for: state))
                    .frame(maxWidth: .infinity)

                Text(previewLines.isEmpty ? "Sin texto" : previewLines)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(textColor(for: state))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(tileFill(for: state))
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(borderColor(for: state), lineWidth: borderWidth(for: state))
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                viewModel.selectSection(section)
                viewModel.prepareSection(section)
                viewModel.projectPreparedSection()
            }
        )
    }

    private func gridColumns(for availableWidth: CGFloat) -> [GridItem] {
        let minimum = max(92, floor((availableWidth - 4) / 3))
        return [
            GridItem(.adaptive(minimum: minimum, maximum: 160), spacing: 1)
        ]
    }

    private var headerDetail: String {
        if let projectedIndex = projectedSectionIndex {
            return "Slide \(projectedIndex + 1)"
        }
        if let preparedIndex = preparedSectionIndex {
            return "Prep \(preparedIndex + 1)"
        }
        return "Total \(viewModel.selectedSections.count)"
    }

    private var preparedSectionIndex: Int? {
        guard let preparedID = viewModel.preparedSection?.id else { return nil }
        return viewModel.selectedSections.firstIndex(where: { $0.id == preparedID })
    }

    private var projectedSectionIndex: Int? {
        guard let currentSlide = livePresentationEngine.state.currentSlide,
              livePresentationEngine.state.source == .worship else {
            return nil
        }
        return viewModel.selectedSections.firstIndex(where: { $0.lines == currentSlide.lines })
    }

    private func tileState(for section: WorshipSection) -> WorshipSlidesTileState {
        if isProjected(section) {
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

    private func isProjected(_ section: WorshipSection) -> Bool {
        guard livePresentationEngine.state.source == .worship,
              let currentSlide = livePresentationEngine.state.currentSlide else {
            return false
        }
        return currentSlide.lines == section.lines
    }

    private func tileFill(for state: WorshipSlidesTileState) -> Color {
        switch state {
        case .live:
            return Color.green.opacity(0.82)
        case .next:
            return Color.orange.opacity(0.16)
        case .selected:
            return AppColors.accent.opacity(0.92)
        case .idle:
            return AppColors.accent.opacity(0.09)
        }
    }

    private func borderColor(for state: WorshipSlidesTileState) -> Color {
        switch state {
        case .live:
            return Color.green.opacity(0.9)
        case .next:
            return Color.orange.opacity(0.62)
        case .selected:
            return Color.white.opacity(0.76)
        case .idle:
            return Color.white.opacity(0.26)
        }
    }

    private func borderWidth(for state: WorshipSlidesTileState) -> CGFloat {
        switch state {
        case .live:
            return 1.8
        case .selected:
            return 1.2
        case .next:
            return 1
        case .idle:
            return 0.7
        }
    }

    private func numberColor(for state: WorshipSlidesTileState) -> Color {
        switch state {
        case .live, .selected:
            return .white
        case .next:
            return .orange
        case .idle:
            return AppColors.accent
        }
    }

    private func textColor(for state: WorshipSlidesTileState) -> Color {
        switch state {
        case .live, .selected:
            return .white.opacity(0.95)
        case .next:
            return .primary
        case .idle:
            return .secondary
        }
    }

    private func stateDot(_ color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.95))
            .frame(width: 5, height: 5)
    }
}

private enum WorshipSlidesTileState {
    case live
    case next
    case selected
    case idle
}
