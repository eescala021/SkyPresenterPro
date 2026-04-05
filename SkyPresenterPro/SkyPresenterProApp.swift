import SwiftUI
import Combine

enum SkyPresenterVersion {
    static let internalRelease = "V1.4"
    static let publicLaunchTarget = "V1.5"
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.center()
            }
        }
    }
}

@main
struct SkyPresenterProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var displayManager = DisplayManager()
    @StateObject private var bibleManager = BibleManager()
    @StateObject private var songManager = SongManager()
    @StateObject private var pdfManager = PDFManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var externalDisplayManager = ExternalDisplayManager()
    @StateObject private var remoteControlManager = RemoteControlManager()
    @StateObject private var announcementManager = AnnouncementManager()
    @StateObject private var backupManager = BackupManager()

    var body: some Scene {
        WindowGroup("Consola de Control") {
            ControlPanel()
                .environmentObject(displayManager)
                .environmentObject(bibleManager)
                .environmentObject(songManager)
                .environmentObject(pdfManager)
                .environmentObject(themeManager)
                .environmentObject(externalDisplayManager)
                .environmentObject(remoteControlManager)
                .environmentObject(announcementManager)
                .environmentObject(backupManager)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    bibleManager.loadBundledBible(fileName: "biblia", into: 0, fallbackName: "VERS 1", language: "ES")
                    externalDisplayManager.configure(displayManager: displayManager, themeManager: themeManager, announcementManager: announcementManager)
                    remoteControlManager.configure(
                        displayManager: displayManager,
                        bibleManager: bibleManager,
                        songManager: songManager,
                        pdfManager: pdfManager,
                        themeManager: themeManager,
                        announcementManager: announcementManager
                    )
                    remoteControlManager.regenerateToken()
                    remoteControlManager.regenerateCredentials()
                    displayManager.showStartupScreen()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    backupManager.performAutoSnapshot()
                }
        }
        .defaultSize(width: 1100, height: 700)
    }
}
