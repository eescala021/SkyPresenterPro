import Foundation
import OSLog

@MainActor
final class WorshipPerformanceDiagnostics {
    static let shared = WorshipPerformanceDiagnostics()

    private let logger = Logger(subsystem: "com.SkyPresenter.SkyPresenterPro", category: "WorshipPerformance")

    private var resizeSessionStartedAt: Date?
    private var widthCommitCount = 0
    private var livePlaceholderHits = 0
    private var workspaceStripPlaceholderHits = 0
    private var editorPlaceholderHits = 0

    private init() {}

    func beginResizeSessionIfNeeded() {
        guard resizeSessionStartedAt == nil else { return }
        resizeSessionStartedAt = .now
        widthCommitCount = 0
        livePlaceholderHits = 0
        workspaceStripPlaceholderHits = 0
        editorPlaceholderHits = 0
        logger.debug("Resize session started")
    }

    func recordWidthCommit(leading: CGFloat, trailing: CGFloat) {
        widthCommitCount += 1
        logger.debug("Resize commit #\(self.widthCommitCount, privacy: .public) leading=\(leading, privacy: .public) trailing=\(trailing, privacy: .public)")
    }

    func recordLivePlaceholderHit() {
        livePlaceholderHits += 1
    }

    func recordWorkspaceStripPlaceholderHit() {
        workspaceStripPlaceholderHits += 1
    }

    func recordEditorPlaceholderHit() {
        editorPlaceholderHits += 1
    }

    func endResizeSessionIfNeeded() {
        guard let resizeSessionStartedAt else { return }
        let elapsed = Date().timeIntervalSince(resizeSessionStartedAt)
        logger.notice(
            "Resize session finished duration=\(elapsed, privacy: .public)s commits=\(self.widthCommitCount, privacy: .public) livePlaceholderHits=\(self.livePlaceholderHits, privacy: .public) stripPlaceholderHits=\(self.workspaceStripPlaceholderHits, privacy: .public) editorPlaceholderHits=\(self.editorPlaceholderHits, privacy: .public)"
        )
        self.resizeSessionStartedAt = nil
    }
}
