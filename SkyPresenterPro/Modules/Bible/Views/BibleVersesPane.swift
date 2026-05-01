import SwiftUI

struct BibleVersesPane: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            versePager

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(viewModel.pagedVerses) { verse in
                    verseTile(verse)
                }
            }
            .padding(1)
            .background(Color.white.opacity(0.75))
        }
    }

    private var versePager: some View {
        HStack(spacing: 8) {
            if viewModel.versePageCount > 1 {
                pageButton(systemImage: "chevron.left", enabled: viewModel.canGoToPreviousVersePage) {
                    viewModel.goToPreviousVersePage()
                }

                Text("\(viewModel.versePageIndex + 1)/\(viewModel.versePageCount)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(selectedBookColor)

                pageButton(systemImage: "chevron.right", enabled: viewModel.canGoToNextVersePage) {
                    viewModel.goToNextVersePage()
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func verseTile(_ verse: BibleVerse) -> some View {
        let isSelected = viewModel.navigation.selectedVerse == verse

        return Button {
            viewModel.selectVerse(verse)
        } label: {
            Text("\(verse.number)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isSelected ? .white : selectedBookColor)
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(isSelected ? selectedBookColor.opacity(0.98) : selectedBookFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.82 : 0.26), lineWidth: isSelected ? 2 : 0.8)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                viewModel.selectVerse(verse)
                viewModel.projectCurrentSelection()
            }
        )
    }

    private func pageButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(enabled ? selectedBookColor : Color.secondary.opacity(0.45))
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selectedBookFill)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var selectedBookColor: Color {
        viewModel.navigation.selectedBook?.chapterVerseColor ?? Color.blue
    }

    private var selectedBookFill: Color {
        viewModel.navigation.selectedBook?.chapterVerseFill ?? Color.blue.opacity(0.18)
    }
}
