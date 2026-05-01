import AppKit
import SwiftUI

struct ProjectionAppearancePanel: View {
    let source: ProjectionSource

    @EnvironmentObject private var themeResolver: ThemeResolver
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var mediaLibraryManager: MediaLibraryManager

    private let themeColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private let mediaColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    themeSection
                    mediaSection
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tema y Fondo")
                    .font(.system(size: 13, weight: .black))
                Text("Galería visual para \(source.displayName.lowercased())")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                statusPill(currentTheme.name, tint: AppColors.accent)

                if let currentBackground {
                    statusPill(currentBackground.name, tint: .orange)
                } else {
                    statusPill("Sin fondo asignado", tint: .secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(
                title: "Temas",
                subtitle: "El tema solo afecta tipografía, color, sombra y alineación"
            )

            LazyVGrid(columns: themeColumns, spacing: 10) {
                ForEach(themeManager.themes(for: source)) { theme in
                    themeCard(theme)
                }
            }
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader(
                    title: "Fondos",
                    subtitle: "Las imágenes y videos se aplican solo al fondo"
                )

                Spacer()

                Button("Quitar fondo") {
                    mediaLibraryManager.setBackground(nil, for: source)
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }

            LazyVGrid(columns: mediaColumns, spacing: 10) {
                ForEach(backgroundItems) { item in
                    mediaCard(item)
                }
            }
        }
    }

    private func themeCard(_ theme: ProjectionTheme) -> some View {
        let isSelected = currentTheme.id == theme.id

        return Button {
            themeResolver.setTheme(theme, forModule: source)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.9), Color.gray.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Text(source == .bible ? "Juan 3:16" : "TEMPRANO YO TE BUSCARÉ")
                        .font(.system(size: 14, weight: .bold))
                        .multilineTextAlignment(theme.textAlignment)
                        .foregroundStyle(theme.textColor)
                        .shadow(
                            color: theme.shadowEnabled ? theme.shadowColor : .clear,
                            radius: theme.shadowEnabled ? theme.shadowRadius : 0
                        )
                        .padding(.horizontal, 10)
                }
                .frame(height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(theme.name)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isSelected ? AppColors.accent : .primary)
                    .lineLimit(1)

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

    private func mediaCard(_ item: MediaLibraryItem) -> some View {
        let isSelected = mediaLibraryManager.isSelectedBackground(item, for: source)

        return Button {
            mediaLibraryManager.setBackground(item, for: source)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                preview(for: item)
                    .frame(height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(item.name)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isSelected ? .orange : .primary)
                    .lineLimit(1)

                Text(item.kind == .image ? "Imagen" : "Video loop")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.10) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.orange : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func preview(for item: MediaLibraryItem) -> some View {
        switch item.kind {
        case .image:
            if let image = NSImage(contentsOfFile: item.filePath) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                mediaFallback(title: item.name, tint: .blue)
            }
        case .video:
            mediaFallback(title: item.name, tint: .orange)
                .overlay {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
    }

    private func mediaFallback(title: String, tint: Color) -> some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.78), Color.black.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(10)
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .black))
            Text(subtitle)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func statusPill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.12)))
    }

    private var currentTheme: ProjectionTheme {
        themeResolver.theme(for: .module(source))
    }

    private var currentBackground: MediaLibraryItem? {
        mediaLibraryManager.backgroundItem(for: source)
    }

    private var backgroundItems: [MediaLibraryItem] {
        (mediaLibraryManager.imageItems + mediaLibraryManager.videoItems)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private extension ProjectionSource {
    var displayName: String {
        switch self {
        case .worship: return "Alabanzas"
        case .bible: return "Biblia"
        case .presentation: return "Presentaciones"
        case .announcement: return "Anuncios"
        case .none: return "General"
        }
    }
}
