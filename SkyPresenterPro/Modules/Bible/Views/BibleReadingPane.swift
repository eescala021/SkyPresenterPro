import SwiftUI

struct BibleReadingPane: View {
    @EnvironmentObject private var viewModel: BibleViewModel
    @EnvironmentObject private var projectionEngine: ProjectionEngine
    @EnvironmentObject private var themeResolver: ThemeResolver
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            projectionBar
            Divider()
            versesList
            Divider()
            bottomWindowsBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(panelBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(referenceSummaryTitle)
                    .font(.system(size: 24, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer()

                if let verse = viewModel.navigation.selectedVerse {
                    Text("v\(verse.number)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(isBibleLive ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)

                Text(isBibleLive ? "En vivo" : "En espera")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                statePill("Caps \(viewModel.chapters.count)", tint: Color.blue.opacity(0.12), foreground: .blue)
                statePill("Vers \(viewModel.verses.count)", tint: Color.green.opacity(0.12), foreground: .green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var projectionBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button("Anterior") {
                    viewModel.goToPreviousProjectedSlide()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("Proyectar") {
                    viewModel.projectCurrentSelection()
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button("Siguiente") {
                    viewModel.goToNextProjectedSlide()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("Limpiar") {
                    viewModel.clearProjection()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Spacer()

                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorite() ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(viewModel.isFavorite() ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                statePill(selectedVerseLabel, tint: Color.blue.opacity(0.12), foreground: .blue)
                statePill(currentBibleTheme.name, tint: AppColors.accent.opacity(0.12), foreground: AppColors.accent)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var versesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if displayedVerses.isEmpty {
                        Text("Selecciona un libro, capítulo y versículo para ver el texto.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(displayedVerses) { verse in
                            verseRow(verse)
                                .id(verse.id)
                            if verse.id != displayedVerses.last?.id {
                                Divider()
                                    .padding(.leading, 42)
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.navigation.selectedVerse) { _, newVerse in
                guard let verse = newVerse else { return }
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(verse.id, anchor: .center)
                }
            }
        }
    }

    private var bottomWindowsBar: some View {
        HStack(spacing: 8) {
            popupButton(
                title: "Favoritos",
                systemImage: "star.fill",
                tint: .yellow
            ) {
                BibleAuxiliaryWindowsController.shared.showFavorites(
                    viewModel: viewModel,
                    environment: environment
                )
            }

            popupButton(
                title: "Historial",
                systemImage: "clock.arrow.circlepath",
                tint: .secondary
            ) {
                BibleAuxiliaryWindowsController.shared.showHistory(
                    viewModel: viewModel,
                    environment: environment
                )
            }

            popupButton(
                title: "Temas",
                systemImage: "photo.on.rectangle",
                tint: AppColors.accent
            ) {
                BibleAuxiliaryWindowsController.shared.showThemes(
                    viewModel: viewModel,
                    environment: environment,
                    themeResolver: themeResolver
                )
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func verseRow(_ verse: BibleVerse) -> some View {
        let isSelected = viewModel.navigation.selectedVerse == verse
        let isProjected = projectedVerseText == verse.text

        return HStack(alignment: .top, spacing: 8) {
            Text("\(verse.number)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(isSelected || isProjected ? .blue : Color.secondary.opacity(0.6))
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                if isProjected || isSelected {
                    Text(isProjected ? "EN VIVO" : "SELECCIONADO")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(isProjected ? .green : .blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(isProjected ? Color.green.opacity(0.12) : Color.blue.opacity(0.12))
                        )
                }

                Text(verse.text)
                    .font(.system(size: 14, weight: isSelected || isProjected ? .semibold : .regular))
                    .foregroundStyle((isSelected || isProjected) ? Color.primary : Color.primary.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isProjected ? Color.green.opacity(0.06) : (isSelected ? Color.blue.opacity(0.07) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectVerse(verse)
        }
        .onTapGesture(count: 2) {
            viewModel.selectVerse(verse)
            viewModel.projectCurrentSelection()
        }
    }

    private func popupButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    private var displayedVerses: [BibleVerse] {
        viewModel.filteredVerses.isEmpty ? viewModel.verses : viewModel.filteredVerses
    }

    private var referenceSummaryTitle: String {
        if let reference = viewModel.navigation.currentReference {
            return reference.displayText
        }
        return "Sin selección"
    }

    private var isBibleLive: Bool {
        projectionEngine.state.source == .bible && projectionEngine.state.currentSlide != nil
    }

    private var projectedVerseText: String? {
        guard projectionEngine.state.source == .bible else { return nil }
        return projectionEngine.state.currentSlide?.lines.joined(separator: " ")
    }

    private var selectedVerseLabel: String {
        guard let verse = viewModel.navigation.selectedVerse else {
            return "Selección: capítulo completo"
        }
        return "Selección: v\(verse.number)"
    }

    private var currentBibleTheme: ProjectionTheme {
        themeResolver.theme(for: .module(.bible))
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private func statePill(_ text: String, tint: Color, foreground: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint))
    }
}
