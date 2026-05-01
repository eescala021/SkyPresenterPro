import Foundation

enum LivePresentationMode: String, Codable {
    case bible
    case worship
    case presentation
    case standby
    case logo
    case black
    case idle
}

enum LivePresentationOrigin: String, Codable {
    case bible
    case worship
    case presentation
    case announcement
    case system
    case none
}

struct LivePresentationState: Equatable, Codable {
    var mode: LivePresentationMode = .idle
    var origin: LivePresentationOrigin = .none
    var source: ProjectionSource = .none
    var displayMode: ProjectionDisplayMode = .standby
    var currentContent: ProjectionContent = .empty
    var nextContent: ProjectionContent?
    var currentSlide: ProjectionSlide?
    var nextSlide: ProjectionSlide?
    var isLive: Bool = false
    var updatedAt: Date = .now
}

struct LivePresentationSuspendedContext: Equatable, Codable {
    let state: LivePresentationState
    let reason: String
    let createdAt: Date
}

@MainActor
final class LivePresentationEngine: ObservableObject {
    @Published private(set) var state = LivePresentationState()

    private(set) var suspendedContext: LivePresentationSuspendedContext?

    func sync(from projectionState: ProjectionState) {
        apply(
            LivePresentationState(
                mode: mode(for: projectionState),
                origin: origin(for: projectionState.source),
                source: projectionState.source,
                displayMode: projectionState.displayMode,
                currentContent: projectionState.currentContent,
                nextContent: projectionState.nextContent,
                currentSlide: projectionState.currentSlide,
                nextSlide: projectionState.nextSlide,
                isLive: projectionState.displayMode == .content && projectionState.isActive,
                updatedAt: projectionState.updatedAt
            )
        )
    }

    func showStandby() {
        apply(
            LivePresentationState(
                mode: .standby,
                origin: .system,
                source: .none,
                displayMode: .standby,
                currentContent: ProjectionContent(kind: .empty, slide: nil, label: "Standby"),
                nextContent: nil,
                currentSlide: nil,
                nextSlide: nil,
                isLive: false,
                updatedAt: .now
            )
        )
    }

    func showLogo() {
        apply(
            LivePresentationState(
                mode: .logo,
                origin: .system,
                source: .none,
                displayMode: .logo,
                currentContent: ProjectionContent(kind: .empty, slide: nil, label: "Logo"),
                nextContent: nil,
                currentSlide: nil,
                nextSlide: nil,
                isLive: false,
                updatedAt: .now
            )
        )
    }

    func showBlack() {
        apply(
            LivePresentationState(
                mode: .black,
                origin: .system,
                source: .none,
                displayMode: .blank,
                currentContent: ProjectionContent(kind: .empty, slide: nil, label: "Sin letra"),
                nextContent: nil,
                currentSlide: nil,
                nextSlide: nil,
                isLive: false,
                updatedAt: .now
            )
        )
    }

    func suspendCurrentContext(reason: String) {
        guard state.mode != .idle else { return }
        suspendedContext = LivePresentationSuspendedContext(
            state: state,
            reason: reason,
            createdAt: .now
        )
    }

    @discardableResult
    func restoreSuspendedContextIfAvailable() -> LivePresentationState? {
        guard let suspendedContext else { return nil }
        self.suspendedContext = nil
        apply(suspendedContext.state)
        return suspendedContext.state
    }

    func clearSuspendedContext() {
        suspendedContext = nil
    }

    private func apply(_ newState: LivePresentationState) {
        guard state != newState else { return }
        state = newState
    }

    private func mode(for projectionState: ProjectionState) -> LivePresentationMode {
        switch projectionState.displayMode {
        case .logo:
            return .logo
        case .blank:
            return .black
        case .standby:
            return .standby
        case .content:
            switch projectionState.source {
            case .bible:
                return .bible
            case .worship:
                return .worship
            case .presentation:
                return .presentation
            case .announcement, .none:
                return projectionState.isActive ? .idle : .standby
            }
        }
    }

    private func origin(for source: ProjectionSource) -> LivePresentationOrigin {
        switch source {
        case .bible:
            return .bible
        case .worship:
            return .worship
        case .presentation:
            return .presentation
        case .announcement:
            return .announcement
        case .none:
            return .none
        }
    }
}
