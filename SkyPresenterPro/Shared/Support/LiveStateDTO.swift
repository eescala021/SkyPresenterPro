import Foundation

struct LiveSlideStyleDTO: Codable, Equatable {
    var source: String
    var contentKind: String
    var displayMode: String
    var themeHint: String
}

struct LiveSlideDTO: Codable, Equatable {
    var id: String?
    var title: String?
    var subtitle: String?
    var reference: String?
    var body: String?
    var lines: [String]
    var notes: [String]
    var imagePath: String?
    var contentAssetPath: String?
    var contentAssetKind: String?
    var isBlank: Bool
    var style: LiveSlideStyleDTO
}

struct LiveBackgroundDTO: Codable, Equatable {
    var mode: String
    var assetPath: String?
    var assetKind: String?
}

struct LiveStateDTO: Codable, Equatable {
    var mode: String
    var module: String
    var currentSource: String
    var navigationContext: String
    var displayMode: String
    var displayState: String
    var isLive: Bool
    var isLyricsHidden: Bool
    var version: Int
    var updatedAt: Date
    var reference: String?
    var body: String?
    var previousReference: String?
    var previousBody: String?
    var nextReference: String?
    var nextBody: String?
    var contextNextReference: String?
    var contextNextBody: String?
    var mediaTitle: String?
    var mediaSubtitle: String?
    var currentSlide: LiveSlideDTO?
    var nextSlide: LiveSlideDTO?
    var background: LiveBackgroundDTO
    var frameKey: String?
    var nextFrameKey: String?
    var contentType: String?
    var visualOverride: String?

    static let empty = LiveStateDTO(
        mode: LivePresentationMode.idle.rawValue,
        module: ProjectionSource.none.rawValue,
        currentSource: ProjectionSource.none.rawValue,
        navigationContext: ProjectionNavigationContext.none.rawValue,
        displayMode: ProjectionDisplayMode.standby.rawValue,
        displayState: ProjectionDisplayMode.standby.rawValue,
        isLive: false,
        isLyricsHidden: false,
        version: 0,
        updatedAt: .now,
        reference: nil,
        body: nil,
        previousReference: nil,
        previousBody: nil,
        nextReference: nil,
        nextBody: nil,
        contextNextReference: nil,
        contextNextBody: nil,
        mediaTitle: nil,
        mediaSubtitle: nil,
        currentSlide: nil,
        nextSlide: nil,
        background: LiveBackgroundDTO(mode: "theme", assetPath: nil, assetKind: nil),
        frameKey: nil,
        nextFrameKey: nil,
        contentType: nil,
        visualOverride: nil
    )

    init(state: LivePresentationState, extras: LiveStateTransportExtras = .empty) {
        let currentSlideDTO = LiveSlideDTO(slide: state.currentSlide, source: state.source, displayMode: state.displayMode)
        let nextSlideDTO = LiveSlideDTO(slide: state.nextSlide, source: state.source, displayMode: state.displayMode)
        let resolvedReference = Self.reference(for: state)
        let resolvedBody = Self.body(for: state)
        let resolvedNextReference = nextSlideDTO?.reference ?? state.nextContent?.label
        let resolvedNextBody = nextSlideDTO?.body

        mode = state.mode.rawValue
        module = state.source.rawValue
        currentSource = state.source.rawValue
        navigationContext = state.navigationContext.rawValue
        displayMode = state.displayMode.rawValue
        displayState = state.displayMode.rawValue
        isLive = state.isLive
        isLyricsHidden = state.isLyricsHidden
        version = state.version
        updatedAt = state.updatedAt
        reference = resolvedReference
        body = resolvedBody
        previousReference = nil
        previousBody = nil
        nextReference = resolvedNextReference
        nextBody = resolvedNextBody
        contextNextReference = resolvedNextReference
        contextNextBody = resolvedNextBody
        mediaTitle = extras.mediaTitle
        mediaSubtitle = extras.mediaSubtitle
        currentSlide = currentSlideDTO
        nextSlide = nextSlideDTO
        background = LiveBackgroundDTO(
            mode: extras.visualOverride == nil ? "theme" : "override",
            assetPath: currentSlideDTO?.contentAssetPath,
            assetKind: currentSlideDTO?.contentAssetKind
        )
        frameKey = extras.frameKey
        nextFrameKey = extras.nextFrameKey
        contentType = extras.contentType ?? state.currentContent.kind.rawValue
        visualOverride = extras.visualOverride
    }

    func jsonString() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self), let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private static func reference(for state: LivePresentationState) -> String? {
        switch state.displayMode {
        case .logo:
            return "LOGO"
        case .blank:
            return state.isLyricsHidden ? "SIN LETRA" : "SALIDA OCULTA"
        case .standby:
            return "STANDBY"
        case .content:
            return state.currentSlide?.reference ?? state.currentSlide?.title ?? state.currentContent.label
        }
    }

    private static func body(for state: LivePresentationState) -> String? {
        switch state.displayMode {
        case .logo:
            return "Salida en logo."
        case .blank:
            return state.isLyricsHidden ? "El contexto sigue activo y se restaurara al navegar." : "Salida oculta."
        case .standby:
            return "Salida en espera."
        case .content:
            if let lines = state.currentSlide?.lines, !lines.isEmpty {
                return lines.joined(separator: "\n")
            }
            if let subtitle = state.currentSlide?.subtitle, !subtitle.isEmpty {
                return subtitle
            }
            if let notes = state.currentSlide?.notes.first, !notes.isEmpty {
                return notes
            }
            return nil
        }
    }
}

extension LiveSlideDTO {
    init?(slide: ProjectionSlide?, source: ProjectionSource, displayMode: ProjectionDisplayMode) {
        guard let slide else { return nil }

        let resolvedBody: String?
        if !slide.lines.isEmpty {
            resolvedBody = slide.lines.joined(separator: "\n")
        } else {
            resolvedBody = slide.subtitle
        }

        self.init(
            id: slide.id.uuidString,
            title: slide.title,
            subtitle: slide.subtitle,
            reference: slide.reference ?? slide.title,
            body: resolvedBody,
            lines: slide.lines,
            notes: slide.notes,
            imagePath: slide.imagePath,
            contentAssetPath: slide.contentAssetPath,
            contentAssetKind: slide.contentAssetKind?.rawValue,
            isBlank: slide.isBlank,
            style: LiveSlideStyleDTO(
                source: source.rawValue,
                contentKind: slide.contentAssetKind?.rawValue ?? (slide.lines.isEmpty ? "empty" : "slide"),
                displayMode: displayMode.rawValue,
                themeHint: source.rawValue
            )
        )
    }
}

struct LiveStateTransportExtras: Equatable {
    var frameKey: String?
    var nextFrameKey: String?
    var mediaTitle: String?
    var mediaSubtitle: String?
    var contentType: String?
    var visualOverride: String?

    static let empty = LiveStateTransportExtras()
}
