import AppKit

// Archivo: AppDelegate.swift
// Función: Configura el comportamiento de las ventanas de la app en macOS.
// Contiene: AppDelegate.
// Uso: Mantiene la ventana principal dentro del área visible del escritorio y evita que macOS restaure un frame que invada el Dock o la barra de menú.

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var notificationObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerWindowObservers()

        DispatchQueue.main.async {
            self.configureAllWindows()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
    }

    func applicationShouldSaveApplicationState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        clamp(window: window)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        clamp(window: window)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        clamp(window: window)
    }

    func windowDidBecomeMain(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        configure(window: window)
        clamp(window: window)
    }

    private func registerWindowObservers() {
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            NSWindow.didBecomeMainNotification,
            NSWindow.didEndLiveResizeNotification,
            NSWindow.didMoveNotification,
            NSWindow.didChangeScreenNotification
        ]

        notificationObservers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard let self, let window = notification.object as? NSWindow else {
                    return
                }

                switch name {
                case NSWindow.didBecomeMainNotification:
                    self.configure(window: window)
                    self.clamp(window: window)
                default:
                    self.clamp(window: window)
                }
            }
        }
    }

    private func configureAllWindows() {
        NSApplication.shared.windows.forEach { window in
            configure(window: window)
            clamp(window: window)
        }
    }

    private func configure(window: NSWindow) {
        window.delegate = self
        window.isRestorable = false
        window.setFrameAutosaveName("")
        window.tabbingMode = .disallowed

        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }

        var behavior = window.collectionBehavior
        behavior.remove(.fullScreenPrimary)
        behavior.remove(.fullScreenAuxiliary)
        window.collectionBehavior = behavior
    }

    private func clamp(window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else {
            window.center()
            return
        }

        let visibleFrame = screen.visibleFrame.insetBy(dx: 16, dy: 16)
        let frame = window.frame

        let width = min(frame.width, visibleFrame.width)
        let height = min(frame.height, visibleFrame.height)

        let x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - width)
        let y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - height)

        let clampedFrame = NSRect(x: x, y: y, width: width, height: height)

        window.minSize = NSSize(width: 980, height: 640)
        window.maxSize = NSSize(width: visibleFrame.width, height: visibleFrame.height)

        if !NSEqualRects(frame, clampedFrame) {
            window.setFrame(clampedFrame, display: true, animate: false)
        }
    }
}
