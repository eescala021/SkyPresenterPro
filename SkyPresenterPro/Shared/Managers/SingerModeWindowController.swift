import AppKit
import SwiftUI

@MainActor
final class SingerModeWindowController: NSWindowController {
    static let shared = SingerModeWindowController()

    private var hostingView: NSHostingView<AnyView>?

    private init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show(
        livePresentationEngine: LivePresentationEngine,
        remoteSyncService: RemoteSyncService,
        themeResolver: ThemeResolver,
        mediaLibraryManager: MediaLibraryManager,
        externalDisplayManager: ExternalDisplayManager
    ) {
        prepareWindowIfNeeded(
            livePresentationEngine: livePresentationEngine,
            remoteSyncService: remoteSyncService,
            themeResolver: themeResolver,
            mediaLibraryManager: mediaLibraryManager,
            externalDisplayManager: externalDisplayManager
        )

        showWindow(nil)
        window?.title = "Modo Cantante"
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func prepareWindowIfNeeded(
        livePresentationEngine: LivePresentationEngine,
        remoteSyncService: RemoteSyncService,
        themeResolver: ThemeResolver,
        mediaLibraryManager: MediaLibraryManager,
        externalDisplayManager: ExternalDisplayManager
    ) {
        guard window == nil else {
            hostingView?.rootView = AnyView(
                SingerModeView()
                    .environmentObject(livePresentationEngine)
                    .environmentObject(remoteSyncService)
                    .environmentObject(themeResolver)
                    .environmentObject(mediaLibraryManager)
                    .environmentObject(externalDisplayManager)
            )
            return
        }

        let contentView = SingerModeView()
            .environmentObject(livePresentationEngine)
            .environmentObject(remoteSyncService)
            .environmentObject(themeResolver)
            .environmentObject(mediaLibraryManager)
            .environmentObject(externalDisplayManager)

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        self.hostingView = hostingView

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1480, height: 860),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Modo Cantante"
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        panel.setFrameAutosaveName("SingerModeWindow")
        panel.contentView = hostingView
        panel.minSize = NSSize(width: 960, height: 620)
        panel.center()

        window = panel
    }
}
