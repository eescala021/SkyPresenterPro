import SwiftUI
import AppKit

// Archivo: SkyPresenterProApp.swift
// Función: Punto de entrada de la aplicación.
// Contiene: SkyPresenterProApp, RootConsoleView, ProjectionHotkeysCommands.
// Uso: Registra ventanas, inyecta dependencias y muestra la consola principal.

@main
struct SkyPresenterProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup("Consola de Control") {
            RootConsoleView()
                .environmentObject(environment)
                .environmentObject(environment.projectionEngine)
                .environmentObject(environment.themeResolver)
                .environmentObject(environment.appLanguageManager)
                .environmentObject(environment.displayManager)
                .environmentObject(environment.externalDisplayManager)
                .environmentObject(environment.remoteControlManager)
                .environmentObject(environment.remoteServerService)
                .environmentObject(environment.remoteDeviceRegistry)
                .environmentObject(environment.remoteSessionManager)
                .environmentObject(environment.themeManager)
                .environmentObject(environment.backupManager)
                .environmentObject(environment.stageDisplayManager)
                .environmentObject(environment.historyManager)
                .environmentObject(environment.errorManager)
                .environmentObject(environment.worshipViewModel)
                .environmentObject(environment.bibleViewModel)
                .environmentObject(environment.settingsViewModel)
                .environmentObject(environment.announcementViewModel)
                .environmentObject(environment.presentationViewModel)
                .environmentObject(environment.churchIdentityService)
                .onAppear {
                    environment.initializeIfNeeded()
                }
        }
        .defaultSize(width: 1380, height: 860)
        .commands {
            ProjectionHotkeysCommands(environment: environment)
        }

        Window("Ajustes", id: "settings") {
            SettingsWindowRoot()
                .environmentObject(environment.settingsViewModel)
                .environmentObject(environment.appLanguageManager)
                .environmentObject(environment.displayManager)
                .environmentObject(environment.remoteControlManager)
                .environmentObject(environment.remoteServerService)
                .environmentObject(environment.remoteDeviceRegistry)
                .environmentObject(environment.remoteSessionManager)
                .environmentObject(environment.themeManager)
                .environmentObject(environment.backupManager)
                .environmentObject(environment.churchIdentityService)
        }
        .defaultSize(width: 980, height: 700)

        Window("Ayuda", id: "help") {
            HelpWindowView()
                .environmentObject(environment.settingsViewModel)
        }
        .defaultSize(width: 920, height: 680)
    }
}

// MARK: - Hotkeys globales centralizados

// Archivo: SkyPresenterProApp.swift
// Función: Sistema único de hotkeys globales. NO duplicar lógica — todo pasa por AppEnvironment.
// Contiene: ProjectionHotkeysCommands.
// Uso: cmd+1-5 módulos, cmd+P proyectar, ESC standby, cmd+Shift+S servidor, cmd+Shift+Z credenciales.

struct ProjectionHotkeysCommands: Commands {
    @ObservedObject var environment: AppEnvironment

    var body: some Commands {
        // MARK: Módulos
        CommandMenu("Módulos") {
            Button("Biblia") { environment.navigate(to: .bible) }
                .keyboardShortcut("1", modifiers: .command)

            Button("Alabanzas") { environment.navigate(to: .worship) }
                .keyboardShortcut("2", modifiers: .command)

            Button("Presentaciones") { environment.navigate(to: .presentations) }
                .keyboardShortcut("3", modifiers: .command)

            Button("Proyector") { environment.navigate(to: .projector) }
                .keyboardShortcut("4", modifiers: .command)

            Button("Remoto") { environment.navigate(to: .remote) }
                .keyboardShortcut("5", modifiers: .command)
        }

        // MARK: Operación en vivo
        CommandMenu("Operación en vivo") {
            Button("Proyectar actual") {
                environment.triggerHotkey(.projectCurrent)
            }
            .keyboardShortcut("p", modifiers: .command)

            Button("STANDBY — Limpiar salida") {
                environment.triggerStandby()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Divider()

            Button("Anterior") {
                environment.triggerHotkey(.previousSlide)
            }
            .keyboardShortcut(.leftArrow, modifiers: [])

            Button("Siguiente") {
                environment.triggerHotkey(.nextSlide)
            }
            .keyboardShortcut(.rightArrow, modifiers: [])

            Divider()

            Button("Limpiar salida (alt)") {
                environment.triggerHotkey(.clearOutput)
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }

        // MARK: Sistema remoto
        CommandMenu("Servidor Remoto") {
            Button("Iniciar / Detener servidor") {
                environment.remoteServerService.toggle()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Regenerar credenciales") {
                environment.regenerateRemoteCredentials()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])

            Divider()

            Button("Relanzar aplicación") {
                environment.relaunch()
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])
        }
    }
}

// MARK: - Root

struct RootConsoleView: View {
    @AppStorage("app.lastSelectedRoute") private var lastSelectedRouteRawValue: String = AppRoute.bible.rawValue
    @State private var selectedRoute: AppRoute = .bible
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        MainConsoleShellView(selectedRoute: $selectedRoute)
            .background(
                WindowAccessor { window in
                    let delays: [TimeInterval] = [0, 0.05, 0.15, 0.35, 0.75, 1.25]
                    for delay in delays {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            AppDelegate.enforceVisibleFrame(for: window)
                        }
                    }
                }
            )
            .onAppear {
                selectedRoute = .bible
                lastSelectedRouteRawValue = AppRoute.bible.rawValue
            }
            .onChange(of: selectedRoute) { _, newValue in
                lastSelectedRouteRawValue = newValue.rawValue
            }
            // Observa activeRoute desde AppEnvironment (hotkeys de módulo)
            .onChange(of: environment.activeRoute) { _, newRoute in
                selectedRoute = newRoute
            }
    }
}
