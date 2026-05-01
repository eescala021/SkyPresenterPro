import SwiftUI

struct WorshipThemesPane: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var livePresentationEngine: LivePresentationEngine
    @EnvironmentObject private var viewModel: WorshipViewModel
    @EnvironmentObject private var themeResolver: ThemeResolver
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var quickThemeTarget: WorshipQuickThemeTarget = .module

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Temas")
                    .font(.system(size: 14, weight: .black))

                Spacer()

                Button("Panel completo") {
                    ProjectionAppearanceWindowController.shared.show(for: .worship, environment: environment)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.accent)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Text("Aplicación rápida en una sola columna con scroll, sin salir del flujo operativo.")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            Divider()
            quickThemeScopeBar
            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 6) {
                    ForEach(themeManager.themes(for: .worship)) { theme in
                        themeCard(theme, selected: currentResolvedWorshipTheme.id == theme.id)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
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

    private var currentResolvedWorshipTheme: ProjectionTheme {
        themeResolver.theme(
            for: resolvedQuickThemeScope,
            source: .worship,
            songID: currentSongID,
            sectionID: currentSectionID
        )
    }

    private var currentSongID: UUID? {
        viewModel.selectedSong?.id
    }

    private var currentSectionID: UUID? {
        if livePresentationEngine.state.source == .worship {
            return viewModel.liveState.selectedSectionID
        }
        return viewModel.preparedSection?.id ?? viewModel.selectedSection?.id
    }

    private var quickThemeScopeBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Aplicar tema", selection: $quickThemeTarget) {
                ForEach(WorshipQuickThemeTarget.allCases) { target in
                    Text(target.shortTitle).tag(target)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            HStack(spacing: 6) {
                scopePill(quickThemeTarget.title, color: .blue)

                if let songName = currentSongName {
                    scopePill(songName, color: .green)
                }

                if quickThemeTarget == .section, let sectionName = currentSectionName {
                    scopePill(sectionName, color: .orange)
                }

                Spacer()

                if canClearQuickThemeOverride {
                    Button("Restablecer") {
                        clearQuickThemeOverride()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func themeCard(_ theme: ProjectionTheme, selected: Bool) -> some View {
        Button {
            applyQuickTheme(theme)
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    themePreviewBackground(theme)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text("Santo")
                        .font(.system(size: 12, weight: theme.fontWeight))
                        .italic(theme.italic)
                        .foregroundStyle(theme.textColor)
                        .shadow(
                            color: theme.shadowEnabled ? theme.shadowColor : .clear,
                            radius: theme.shadowEnabled ? min(theme.shadowRadius, 3) : 0
                        )
                }
                .frame(width: 60, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    ConsoleAdaptiveText(
                        text: theme.name,
                        style: .title,
                        font: .system(size: 11, weight: .black),
                        color: selected ? AppColors.accent : .primary,
                        lineLimit: 1
                    )

                    ConsoleAdaptiveText(
                        text: theme.scope.displayName,
                        style: .chip,
                        font: .system(size: 9, weight: .semibold),
                        color: .secondary,
                        lineLimit: 1
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? AppColors.accent.opacity(0.10) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? AppColors.accent : Color.black.opacity(0.08), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func scopePill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
            .lineLimit(1)
    }

    private var currentSongName: String? {
        viewModel.selectedSong?.title
    }

    private var currentSectionName: String? {
        viewModel.preparedSection?.title ?? viewModel.selectedSection?.title
    }

    private var resolvedQuickThemeScope: ThemeScope {
        switch quickThemeTarget {
        case .module:
            return .module(.worship)
        case .song:
            if let currentSongID {
                return .song(currentSongID)
            }
            return .module(.worship)
        case .section:
            if let currentSectionID {
                return .section(currentSectionID)
            }
            if let currentSongID {
                return .song(currentSongID)
            }
            return .module(.worship)
        }
    }

    private func applyQuickTheme(_ theme: ProjectionTheme) {
        switch resolvedQuickThemeScope {
        case .module(let source):
            themeResolver.setTheme(theme, forModule: source)
        case .song(let id):
            themeResolver.setTheme(theme, forSong: id)
        case .section(let id):
            themeResolver.setTheme(theme, forSection: id)
        case .global:
            themeResolver.setGlobalTheme(theme)
        }
    }

    private var canClearQuickThemeOverride: Bool {
        switch resolvedQuickThemeScope {
        case .song(let id):
            return themeResolver.hasSongThemeOverride(id)
        case .section(let id):
            return themeResolver.hasSectionThemeOverride(id)
        case .module, .global:
            return false
        }
    }

    private func clearQuickThemeOverride() {
        switch resolvedQuickThemeScope {
        case .song(let id):
            themeResolver.clearSongTheme(id)
        case .section(let id):
            themeResolver.clearSectionTheme(id)
        case .module, .global:
            break
        }
    }

    @ViewBuilder
    private func themePreviewBackground(_ theme: ProjectionTheme) -> some View {
        switch theme.backgroundStyle {
        case .gradient:
            theme.backgroundGradient
        case .solid:
            theme.backgroundColor
        case .image:
            if let path = theme.backgroundImagePath {
                ProjectionCachedImageView(path: path, contentMode: SwiftUI.ContentMode.fill) {
                    theme.backgroundGradient
                }
            } else {
                theme.backgroundGradient
            }
        }
    }
}

private enum WorshipQuickThemeTarget: String, CaseIterable, Identifiable {
    case module
    case song
    case section

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .module: return "Módulo"
        case .song: return "Canción"
        case .section: return "Slide"
        }
    }

    var title: String {
        switch self {
        case .module: return "Todo Alabanzas"
        case .song: return "Solo esta canción"
        case .section: return "Solo esta diapositiva"
        }
    }
}
