import SwiftUI

struct BibleBooksPane: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 11)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(viewModel.books) { book in
                bookTile(book)
            }
        }
        .padding(1)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
    }

    private func bookTile(_ book: BibleBook) -> some View {
        let isSelected = viewModel.navigation.selectedBook == book

        return Button {
            viewModel.selectBook(book)
        } label: {
            VStack(spacing: 2) {
                Text(book.shortName)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.98))
                    .lineLimit(1)

                Text(book.name)
                    .font(.system(size: 3.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(isSelected ? book.consoleColor.opacity(0.92) : book.consoleColor)
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
