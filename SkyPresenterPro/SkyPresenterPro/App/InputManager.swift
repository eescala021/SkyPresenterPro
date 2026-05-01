import Foundation

@MainActor
final class InputManager {
    let livePresentationEngine: LivePresentationEngine
    private let projectionEngine: ProjectionEngine
    private let projectionCommandRouter: ProjectionCommandRouter
    private let bibleViewModel: BibleViewModel
    private let worshipViewModel: WorshipViewModel
    private let presentationViewModel: PresentationViewModel

    var activeRouteProvider: (() -> AppRoute)?
    var routeNavigator: ((AppRoute) -> Void)?
    var latencyRegistrar: ((UUID?) -> Void)?

    init(
        livePresentationEngine: LivePresentationEngine,
        projectionEngine: ProjectionEngine,
        projectionCommandRouter: ProjectionCommandRouter,
        bibleViewModel: BibleViewModel,
        worshipViewModel: WorshipViewModel,
        presentationViewModel: PresentationViewModel
    ) {
        self.livePresentationEngine = livePresentationEngine
        self.projectionEngine = projectionEngine
        self.projectionCommandRouter = projectionCommandRouter
        self.bibleViewModel = bibleViewModel
        self.worshipViewModel = worshipViewModel
        self.presentationViewModel = presentationViewModel
    }

    func handle(_ command: RemoteCommand, latencyToken: UUID? = nil) {
        latencyRegistrar?(latencyToken)

        switch command {
        case .nextSlide:
            routeToActiveModule { module in
                switch module {
                case .bible:
                    bibleViewModel.goToNextProjectedSlide()
                case .worship:
                    worshipViewModel.goToNextProjectedSlide()
                case .presentation:
                    presentationViewModel.goNext()
                case .announcement, .none:
                    projectionCommandRouter.goNext()
                }
            }
        case .previousSlide:
            routeToActiveModule { module in
                switch module {
                case .bible:
                    bibleViewModel.goToPreviousProjectedSlide()
                case .worship:
                    worshipViewModel.goToPreviousProjectedSlide()
                case .presentation:
                    presentationViewModel.goPrevious()
                case .announcement, .none:
                    projectionCommandRouter.goPrevious()
                }
            }
        case .clearOutput:
            routeToActiveModule { module in
                switch module {
                case .bible:
                    bibleViewModel.clearProjection()
                case .worship:
                    worshipViewModel.clearProjection()
                case .presentation:
                    presentationViewModel.clearProjection()
                case .announcement, .none:
                    projectionCommandRouter.clear()
                }
            }
        case .standbyOutput:
            handleStandby(latencyToken: latencyToken)
        case .escapeAction:
            handleEscape(latencyToken: latencyToken)
        case .projectBible, .projectBibleVerse:
            bibleViewModel.projectCurrentSelection()
        case .projectWorship:
            worshipViewModel.projectPreparedSection()
        case .projectPresentation, .projectPresentationPage:
            if command == .projectPresentationPage,
               let payload = RemoteCommandBus.shared.consumePresentationAction(),
               let documentID = UUID(uuidString: payload.id) {
                presentationViewModel.projectSlide(documentID: documentID, pageIndex: payload.pageIndex)
            } else {
                presentationViewModel.projectPreparedSlide()
            }
        case .projectCurrent:
            projectCurrentForActiveModule()
        case .fetchStatus, .authenticate:
            break
        }
    }

    func handleProjectDetectedVersesFromPresentations() {
        routeNavigator?(.presentations)
        if !presentationViewModel.liveState.detectedProjectionSession.isActive {
            livePresentationEngine.suspendCurrentContext(reason: "presentation.detectedVerse")
        }
        presentationViewModel.projectDetectedReferencesFromShortcut()
    }

    func handleEscape(latencyToken: UUID? = nil) {
        latencyRegistrar?(latencyToken)
        if presentationViewModel.liveState.detectedProjectionSession.isActive {
            presentationViewModel.restoreSuspendedPresentationProjection()
            livePresentationEngine.restoreSuspendedContextIfAvailable()
            return
        }

        handleStandby(latencyToken: latencyToken)
    }

    func handleStandby(latencyToken: UUID? = nil) {
        latencyRegistrar?(latencyToken)
        bibleViewModel.resetProjectionState()
        worshipViewModel.resetProjectionState()
        presentationViewModel.resetProjectionState()
        livePresentationEngine.clearSuspendedContext()
        livePresentationEngine.showStandby()
        projectionEngine.clear()
    }

    func handleLogo(latencyToken: UUID? = nil) {
        latencyRegistrar?(latencyToken)
        bibleViewModel.resetProjectionState()
        worshipViewModel.resetProjectionState()
        presentationViewModel.resetProjectionState()
        livePresentationEngine.clearSuspendedContext()
        livePresentationEngine.showLogo()
        projectionEngine.showLogo()
    }

    func handleBlank(latencyToken: UUID? = nil) {
        latencyRegistrar?(latencyToken)
        bibleViewModel.resetProjectionState()
        worshipViewModel.resetProjectionState()
        presentationViewModel.resetProjectionState()
        livePresentationEngine.clearSuspendedContext()
        livePresentationEngine.showBlack()
        projectionEngine.showBlank()
    }

    private func routeToActiveModule(_ action: (ProjectionSource) -> Void) {
        action(resolvedControlSource())
    }

    private func projectCurrentForActiveModule() {
        switch resolvedControlSource() {
        case .bible:
            bibleViewModel.projectCurrentSelection()
        case .worship:
            worshipViewModel.projectPreparedSection()
        case .presentation:
            presentationViewModel.projectPreparedSlide()
        case .announcement:
            break
        case .none:
            switch preferredPreparedSource() {
            case .presentation:
                presentationViewModel.projectPreparedSlide()
            case .bible:
                bibleViewModel.projectCurrentSelection()
            case .worship:
                worshipViewModel.projectPreparedSection()
            case .announcement, .none:
                break
            }
        }
    }

    private func resolvedControlSource() -> ProjectionSource {
        let liveSource = projectionEngine.state.source
        if liveSource != .none {
            return liveSource
        }

        switch activeRouteProvider?() ?? .bible {
        case .bible:
            return .bible
        case .worship:
            return .worship
        case .presentations:
            return .presentation
        case .projector, .remote, .settings, .help:
            return preferredPreparedSource()
        }
    }

    private func preferredPreparedSource() -> ProjectionSource {
        let candidates: [(source: ProjectionSource, date: Date)] = [
            presentationViewModel.preparedDocument != nil ? (.presentation, max(presentationViewModel.liveState.lastInteractionAt, presentationViewModel.liveState.lastProjectionRequestAt)) : nil,
            bibleViewModel.navigation.currentReference != nil ? (.bible, max(bibleViewModel.navigation.lastInteractionAt, bibleViewModel.navigation.lastProjectionRequestAt)) : nil,
            worshipViewModel.preparedSection != nil ? (.worship, max(worshipViewModel.liveState.lastInteractionAt, worshipViewModel.liveState.lastProjectionRequestAt)) : nil
        ].compactMap { $0 }

        return candidates.max(by: { $0.date < $1.date })?.source ?? .none
    }
}
