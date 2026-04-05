import AppKit
import Combine
import SwiftUI

final class ExternalDisplayManager: ObservableObject {
    @Published private(set) var isExternalDisplayConnected: Bool = false
    @Published private(set) var externalScreenName: String?

    private var projectorWindow: NSWindow?
    private var screenObserver: Any?

    // References to environment objects needed by the Projector view
    private weak var displayManager: DisplayManager?
    private weak var themeManager: ThemeManager?
    private weak var announcementManager: AnnouncementManager?

    init() {
        checkScreens()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkScreens()
        }
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        closeProjectorWindow()
    }

    func configure(displayManager: DisplayManager, themeManager: ThemeManager, announcementManager: AnnouncementManager) {
        self.displayManager = displayManager
        self.themeManager = themeManager
        self.announcementManager = announcementManager
        checkScreens()
    }

    // MARK: - Screen Detection

    private func checkScreens() {
        let screens = NSScreen.screens
        let externalScreen = screens.count > 1 ? screens[1] : nil

        if let screen = externalScreen {
            isExternalDisplayConnected = true
            externalScreenName = screen.localizedName
            openProjectorWindow(on: screen)
        } else {
            isExternalDisplayConnected = false
            externalScreenName = nil
            closeProjectorWindow()
        }
    }

    // MARK: - Window Management

    private func openProjectorWindow(on screen: NSScreen) {
        guard let displayManager, let themeManager, let announcementManager else { return }

        // If window already exists on the correct screen, just update frame
        if let window = projectorWindow {
            if window.screen == screen {
                window.setFrame(screen.frame, display: true)
                return
            }
            // Screen changed, close and recreate
            closeProjectorWindow()
        }

        let projectorView = Projector(isExternalDisplay: true)
            .environmentObject(displayManager)
            .environmentObject(themeManager)
            .environmentObject(announcementManager)

        let hostingController = NSHostingController(rootView: projectorView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.setFrame(screen.frame, display: true)
        window.level = .normal
        window.isOpaque = true
        window.backgroundColor = .black
        window.collectionBehavior = [.fullScreenNone, .canJoinAllSpaces]
        window.hasShadow = false
        window.isReleasedWhenClosed = false

        // Place on the external screen
        window.setFrameOrigin(screen.frame.origin)
        window.makeKeyAndOrderFront(nil)

        self.projectorWindow = window
    }

    private func closeProjectorWindow() {
        projectorWindow?.close()
        projectorWindow = nil
    }
}
