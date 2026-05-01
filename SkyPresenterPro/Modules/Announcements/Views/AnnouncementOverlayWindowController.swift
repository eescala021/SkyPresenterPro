import AppKit
import SwiftUI

@MainActor
final class AnnouncementOverlayWindowController {
    static let shared = AnnouncementOverlayWindowController()

    private var window: NSWindow?

    private init() {}

    func show(viewModel: AnnouncementViewModel) {
        let rootView = AnnouncementOverlayEditorWindow()
            .environmentObject(viewModel)

        let targetWindow = window ?? buildWindow()
        targetWindow.contentView = NSHostingView(rootView: rootView)
        targetWindow.center()
        targetWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = targetWindow
    }

    private func buildWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier("announcement_overlay_window")
        window.title = "Anuncios"
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.level = .floating
        return window
    }
}
