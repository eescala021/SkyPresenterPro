// Archivo: MainConsoleShellView.swift
// Función: Define la carcasa principal de la consola con cabecera compacta de una fila y área de módulos.
// Contiene: MainConsoleShellView.
// Uso: Shell visual de la app con header compacto inline y navegación de módulos integrada en una sola barra.

import SwiftUI

struct MainConsoleShellView: View {
    @Binding var selectedRoute: AppRoute
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                consoleChrome

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
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
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: syncLegacyRemoteRouteIfNeeded)
        .onChange(of: selectedRoute) { _, _ in
            syncLegacyRemoteRouteIfNeeded()
        }
    }

    // MARK: - Chrome (una sola fila compacta)

    private var consoleChrome: some View {
        HStack(alignment: .center, spacing: 0) {
            brandSection
            chromeSeparator
            LegacyModuleTabs(selectedRoute: $selectedRoute)
            Spacer(minLength: 4)
            shortcutBadges
            chromeSeparator
            screenStatus
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var brandSection: some View {
        HStack(spacing: 7) {
            Text("SkyPresenterPro")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .lineLimit(1)
            Text("V1.4")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.blue)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.blue.opacity(0.14)))
        }
    }

    private var chromeSeparator: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 10)
    }

    private var shortcutBadges: some View {
        HStack(spacing: 4) {
            chromeBadge("F8", AppColors.success)
            chromeBadge("F9", AppColors.accent)
            chromeBadge("F10", Color.black.opacity(0.75))
        }
    }

    private func chromeBadge(_ title: String, _ color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(color))
    }

    private var screenStatus: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(AppColors.success)
                .frame(width: 7, height: 7)
            Text("Sin pantalla")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch effectiveRoute {
        case .worship:
            WorshipModuleView()
        case .bible:
            BibleModuleView()
        case .presentations:
            PresentationModuleView()
        case .projector:
            ProjectorModuleView()
        case .settings:
            SettingsWindowRoot()
        case .help:
            HelpWindowView()
        case .remote:
            SettingsWindowRoot()
        }
    }

    private var effectiveRoute: AppRoute {
        selectedRoute == .remote ? .settings : selectedRoute
    }

    private func syncLegacyRemoteRouteIfNeeded() {
        guard selectedRoute == .remote else { return }
        settingsViewModel.selectPane(.remote)
        selectedRoute = .settings
    }
}
