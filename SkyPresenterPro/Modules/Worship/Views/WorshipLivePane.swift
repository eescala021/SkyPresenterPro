import SwiftUI

struct WorshipLivePane: View {
    @EnvironmentObject private var projectionEngine: ProjectionEngine
    @EnvironmentObject private var viewModel: WorshipViewModel
    @EnvironmentObject private var themeResolver: ThemeResolver

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            liveHeader
            Divider()
            currentPreviewDominant
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            controlsBar
            Divider()
            themeColumn
                .frame(height: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .onAppear { syncWithProjection() }
        .onChange(of: projectionEngine.state.version) { _, _ in syncWithProjection() }
    }

    private var liveHeader: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isWorshipLive ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 7, height: 7)

            Text(isWorshipLive ? "EN VIVO" : "EN ESPERA")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(isWorshipLive ? .green : .secondary)

            Spacer()

            if let sec = currentLiveSection {
                Text(sec.title.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var currentPreviewDominant: some View {
        ProjectionPreviewSurface(
            slide: projectionEngine.state.currentSlide,
            source: .worship
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var controlsBar: some View {
        HStack(spacing: 6) {
            Button("Anterior") {
                viewModel.goToPreviousProjectedSlide()
                viewModel.selectPreviousSection()
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button("Proyectar") {
                viewModel.projectPreparedSection()
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button("Siguiente") {
                viewModel.goToNextProjectedSlide()
                viewModel.selectNextSection()
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button("Limpiar") {
                viewModel.clearProjection()
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Spacer()

            Text(currentWorshipTheme.name)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(AppColors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(AppColors.accent.opacity(0.12)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private var themeColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TEMAS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Columna única")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 6) {
                    ForEach(ProjectionTheme.worshipLibrary) { theme in
                        themeCard(theme, selected: currentWorshipTheme.id == theme.id)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }

    private func themeCard(_ theme: ProjectionTheme, selected: Bool) -> some View {
        Button {
            themeResolver.setTheme(theme, forModule: .worship)
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    themeCardBackground(for: theme)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text("Aa")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.textColor)
                }
                .frame(width: 60, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.name)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(selected ? AppColors.accent : Color.primary)

                    Text(theme.scope.displayName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
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

    @ViewBuilder
    private func themeCardBackground(for theme: ProjectionTheme) -> some View {
        switch theme.backgroundStyle {
        case .gradient:
            theme.backgroundGradient
        case .solid:
            theme.backgroundColor
        case .image:
            if let path = theme.backgroundImagePath,
               let nsImg = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImg)
                    .resizable()
                    .scaledToFill()
            } else {
                theme.backgroundGradient
            }
        }
    }

    private var isWorshipLive: Bool {
        projectionEngine.state.source == .worship && projectionEngine.state.currentSlide != nil
    }

    private var currentLiveSection: WorshipSection? {
        guard projectionEngine.state.source == .worship,
              let currentSlide = projectionEngine.state.currentSlide else { return nil }
        return viewModel.selectedSections.first(where: { $0.lines == currentSlide.lines })
    }

    private var currentWorshipTheme: ProjectionTheme {
        themeResolver.theme(for: .module(.worship))
    }

    private func syncWithProjection() {
        viewModel.syncLiveState(
            currentSlide: projectionEngine.state.currentSlide,
            nextSlide: projectionEngine.state.nextSlide,
            source: projectionEngine.state.source
        )
    }
}
