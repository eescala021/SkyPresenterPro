import SwiftUI

struct BibleModuleView: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            moduleHeader

            HStack(alignment: .top, spacing: 8) {
                BibleReadingPane()
                    .frame(minWidth: 330, maxWidth: 360, maxHeight: .infinity)

                selectorBoard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var moduleHeader: some View {
        ConsoleModuleHeader(
            title: "Biblia",
            subtitle: "Lectura fija y selección rápida tipo Holyrics"
        ) {
            HStack(spacing: AppSpacing.sm) {
                BibleVersionsBar(
                    versions: ["REIV1960", "RVR1960", "NTV"],
                    selectedVersion: "REIV1960"
                )

                if let ref = viewModel.navigation.currentReference {
                    Text(ref.displayText)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColors.accent))
                }
            }
        }
    }

    private var selectorBoard: some View {
        VStack(spacing: 8) {
            selectorPanel(title: "Libros", trailing: "\(viewModel.books.count)") {
                BibleBooksPane()
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 8) {
                selectorPanel(title: "Capítulos", trailing: "\(viewModel.chapters.count)") {
                    BibleChaptersPane()
                }

                selectorPanel(title: "Versículos", trailing: "\(viewModel.verses.count)") {
                    BibleVersesPane()
                }
            }
            .frame(height: 280)
        }
    }

    private func selectorPanel<Content: View>(
        title: String,
        trailing: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(trailing)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.05)))
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Divider()

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var panelBackground: some View {
        Color.white.opacity(0.82)
    }
}
