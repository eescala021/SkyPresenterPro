// Archivo: BibleAuxiliaryWindowsController.swift
// Función: Administra ventanas nativas auxiliares únicas para Favoritos e Historial del módulo Biblia.
// Contiene: BibleAuxiliaryWindowsController.
// Uso: Abre o trae al frente ventanas auxiliares sin duplicarlas y reutiliza el mismo estado global del módulo.

import AppKit
import SwiftUI

@MainActor
final class BibleAuxiliaryWindowsController {
    static let shared = BibleAuxiliaryWindowsController()

    private var favoritesWindow: NSWindow?
    private var historyWindow: NSWindow?

    private init() {}

    func showFavorites(viewModel: BibleViewModel, environment: AppEnvironment) {
        let rootView = BibleFavoritesPanel()
            .environmentObject(viewModel)
            .environmentObject(environment)
        favoritesWindow = presentWindow(
            window: favoritesWindow,
            identifier: "bible_favorites_window",
            title: "Favoritos Bíblicos",
            defaultSize: NSSize(width: 360, height: 420),
            rootView: rootView
        )
    }

    func showHistory(viewModel: BibleViewModel, environment: AppEnvironment) {
        let rootView = BibleHistoryPanel()
            .environmentObject(viewModel)
            .environmentObject(environment)
        historyWindow = presentWindow(
            window: historyWindow,
            identifier: "bible_history_window",
            title: "Historial Bíblico",
            defaultSize: NSSize(width: 360, height: 440),
            rootView: rootView
        )
    }

    private func presentWindow<Content: View>(
        window: NSWindow?,
        identifier: String,
        title: String,
        defaultSize: NSSize,
        rootView: Content
    ) -> NSWindow {
        let targetWindow = window ?? buildWindow(
            identifier: identifier,
            title: title,
            defaultSize: defaultSize
        )
        targetWindow.contentView = NSHostingView(rootView: rootView)
        targetWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return targetWindow
    }

    private func buildWindow(identifier: String, title: String, defaultSize: NSSize) -> NSWindow {
        let frame = suggestedFrame(for: defaultSize)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier(identifier)
        window.title = title
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.tabbingMode = .disallowed
        window.backgroundColor = .windowBackgroundColor
        window.setFrameAutosaveName(identifier)
        return window
    }

    private func suggestedFrame(for size: NSSize) -> NSRect {
        if let keyWindow = NSApp.keyWindow {
            return keyWindow.frame.insetBy(dx: 40, dy: 40).withSize(size)
        }

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.midX - (size.width / 2),
                y: visible.midY - (size.height / 2)
            )
            return NSRect(origin: origin, size: size)
        }

        return NSRect(origin: .zero, size: size)
    }
}

private extension NSRect {
    func withSize(_ size: NSSize) -> NSRect {
        NSRect(
            x: origin.x,
            y: origin.y,
            width: size.width,
            height: size.height
        )
    }
}
