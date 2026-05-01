// Archivo: SettingsViewModel.swift
// Función: Gestiona el estado reactivo de las secciones de configuración.
// Contiene: SettingsViewModel.
// Uso: Se inyecta en Ajustes para coordinar tabs, paneles y valores visibles.
//      Persiste preferencias en UserDefaults y aplica dark mode a NSApp.appearance.

import Combine
import SwiftUI
import AppKit

@MainActor
final class SettingsViewModel: ObservableObject {

    enum Pane: String, CaseIterable, Identifiable {
        case general    = "General"
        case projection = "Proyección"
        case worship    = "Alabanzas"
        case bible      = "Biblia"
        case remote     = "Remoto"
        case backup     = "Respaldo"

        var id: String { rawValue }
    }

    // MARK: - Navigation

    @Published var selectedPane: Pane = .general
    @Published var appName: String = "SkyPresenterPro"

    // MARK: - Preferences (persisted)

    @Published var autoSaveEnabled: Bool = true
    @Published var darkInterfacePreferred: Bool = false
    @Published var projectorPreviewScale: Double = 1.0
    @Published var worshipAutoBlankSlideEnabled: Bool = true
    @Published var bibleShowReferenceEnabled: Bool = true
    @Published var remoteControlEnabled: Bool = false
    @Published var backupEnabled: Bool = true

    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        restoreFromDefaults()
        wireUpPersistence()
        applyAppearance(darkInterfacePreferred)
    }

    // MARK: - Navigation

    func selectPane(_ pane: Pane) {
        selectedPane = pane
    }

    // MARK: - Private: restore

    private func restoreFromDefaults() {
        let ud = UserDefaults.standard
        autoSaveEnabled              = ud.object(forKey: "settings.autoSave")         as? Bool   ?? true
        darkInterfacePreferred       = ud.object(forKey: "settings.darkMode")         as? Bool   ?? false
        worshipAutoBlankSlideEnabled = ud.object(forKey: "settings.worshipAutoBlank") as? Bool   ?? true
        bibleShowReferenceEnabled    = ud.object(forKey: "settings.bibleShowRef")     as? Bool   ?? true
        remoteControlEnabled         = ud.object(forKey: "settings.remoteEnabled")    as? Bool   ?? false
        backupEnabled                = ud.object(forKey: "settings.backupEnabled")    as? Bool   ?? true

        let savedScale = ud.double(forKey: "settings.projectorScale")
        projectorPreviewScale = savedScale > 0 ? savedScale : 1.0
    }

    // MARK: - Private: wire persistence

    private func wireUpPersistence() {
        let ud = UserDefaults.standard

        $autoSaveEnabled
            .dropFirst()
            .sink { ud.set($0, forKey: "settings.autoSave") }
            .store(in: &cancellables)

        $worshipAutoBlankSlideEnabled
            .dropFirst()
            .sink { ud.set($0, forKey: "settings.worshipAutoBlank") }
            .store(in: &cancellables)

        $bibleShowReferenceEnabled
            .dropFirst()
            .sink { ud.set($0, forKey: "settings.bibleShowRef") }
            .store(in: &cancellables)

        $remoteControlEnabled
            .dropFirst()
            .sink { ud.set($0, forKey: "settings.remoteEnabled") }
            .store(in: &cancellables)

        $backupEnabled
            .dropFirst()
            .sink { ud.set($0, forKey: "settings.backupEnabled") }
            .store(in: &cancellables)

        $projectorPreviewScale
            .dropFirst()
            .sink { ud.set($0, forKey: "settings.projectorScale") }
            .store(in: &cancellables)

        // Dark mode también aplica NSApp.appearance
        $darkInterfacePreferred
            .dropFirst()
            .sink { [weak self] dark in
                ud.set(dark, forKey: "settings.darkMode")
                self?.applyAppearance(dark)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: appearance

    private func applyAppearance(_ dark: Bool) {
        NSApp.appearance = dark ? NSAppearance(named: .darkAqua) : nil
    }
}
