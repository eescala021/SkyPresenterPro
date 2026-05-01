import SwiftUI

struct BibleThemesPanel: View {
    @EnvironmentObject private var themeResolver: ThemeResolver

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Temas")
                        .font(.system(size: 13, weight: .black))
                    Text("Galería visual para la proyección bíblica")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(currentTheme.name)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColors.accent.opacity(0.12)))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ProjectionTheme.bibleLibrary) { theme in
                        themeCard(theme)
                    }
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func themeCard(_ theme: ProjectionTheme) -> some View {
        let isSelected = currentTheme.id == theme.id

        return Button {
            themeResolver.setTheme(theme, forModule: .bible)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    backgroundPreview(for: theme)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text("Juan 3:16")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.textColor)
                        .shadow(
                            color: theme.shadowEnabled ? theme.shadowColor : .clear,
                            radius: theme.shadowEnabled ? theme.shadowRadius : 0
                        )
                }
                .frame(height: 100)

                Text(theme.name)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(isSelected ? AppColors.accent : Color.primary)

                Text(theme.scope.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.10) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.accent : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func backgroundPreview(for theme: ProjectionTheme) -> some View {
        switch theme.backgroundStyle {
        case .gradient:
            theme.backgroundGradient
        case .solid:
            theme.backgroundColor
        case .image:
            if let path = theme.backgroundImagePath,
               let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                theme.backgroundGradient
            }
        }
    }

    private var currentTheme: ProjectionTheme {
        themeResolver.theme(for: .module(.bible))
    }
}
