// Archivo: ChurchIdentityService.swift
// Función: Gestiona la identidad de la iglesia (nombre, logo, mensaje standby, reloj) con persistencia real.
// Contiene: ChurchIdentityService.
// Uso: Inyectado en AppEnvironment; persiste nombre en UserDefaults y logo (PNG) en Application Support/SkyPresenterPro.

import Combine
import SwiftUI
import AppKit

@MainActor
final class ChurchIdentityService: ObservableObject {

    @Published private(set) var churchName: String = ""
    @Published private(set) var logoImage: NSImage? = nil
    @Published private(set) var standbyMessage: String = ""
    @Published private(set) var standbyShowClock: Bool = false

    private let nameKey      = "church.identity.name"
    private let messageKey   = "church.identity.standbyMessage"
    private let clockKey     = "church.identity.showClock"
    private let logoFilename = "church_logo.png"

    private var logoURL: URL? {
        guard let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        return dir.appendingPathComponent(logoFilename)
    }

    init() {
        let ud = UserDefaults.standard
        churchName       = ud.string(forKey: nameKey)    ?? ""
        standbyMessage   = ud.string(forKey: messageKey) ?? ""
        standbyShowClock = ud.bool(forKey: clockKey)
        loadLogo()
    }

    // MARK: - Nombre de iglesia

    func setName(_ name: String) {
        churchName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(churchName, forKey: nameKey)
    }

    func clearName() {
        churchName = ""
        UserDefaults.standard.removeObject(forKey: nameKey)
    }

    // MARK: - Standby

    func setStandbyMessage(_ msg: String) {
        standbyMessage = msg
        UserDefaults.standard.set(msg, forKey: messageKey)
    }

    func setShowClock(_ value: Bool) {
        standbyShowClock = value
        UserDefaults.standard.set(value, forKey: clockKey)
    }

    // MARK: - Logo

    func importLogo(from url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        saveLogo(image)
    }

    func replaceLogo(with image: NSImage) {
        saveLogo(image)
    }

    func clearLogo() {
        logoImage = nil
        if let u = logoURL { try? FileManager.default.removeItem(at: u) }
    }

    // MARK: - Private

    private func loadLogo() {
        guard let u = logoURL,
              FileManager.default.fileExists(atPath: u.path),
              let image = NSImage(contentsOf: u) else {
            logoImage = nil
            return
        }
        logoImage = image
    }

    private func saveLogo(_ image: NSImage) {
        guard let u = logoURL else { return }
        let dir = u.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let tiff = image.tiffRepresentation,
              let rep  = NSBitmapImageRep(data: tiff),
              let png  = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: u)
        logoImage = image
    }
}
