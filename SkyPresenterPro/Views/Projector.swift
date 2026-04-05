import SwiftUI

private struct AnnouncementStrokeText: View {
    let text: String
    let fontSize: CGFloat
    let textColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat

    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundColor(strokeColor)
                .offset(x: -strokeWidth, y: 0)
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundColor(strokeColor)
                .offset(x: strokeWidth, y: 0)
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundColor(strokeColor)
                .offset(x: 0, y: -strokeWidth)
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundColor(strokeColor)
                .offset(x: 0, y: strokeWidth)
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundColor(textColor)
        }
    }
}

private struct AnnouncementTickerOverlay: View {
    @EnvironmentObject var announcementManager: AnnouncementManager
    let size: CGSize

    var body: some View {
        if announcementManager.settings.isEnabled, let active = announcementManager.activeAnnouncement {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                overlayBody(for: active, date: context.date)
            }
        }
    }

    @ViewBuilder
    private func overlayBody(for active: AnnouncementItem, date: Date) -> some View {
        let barHeight = max(54, size.height * announcementManager.settings.barHeightRatio)
        let verticalPadding = max(18, size.height * 0.04)
        let yOffset = announcementManager.settings.position == .top
            ? -(size.height / 2) + (barHeight / 2) + verticalPadding
            : (size.height / 2) - (barHeight / 2) - verticalPadding

        ZStack {
            barBackground(for: active.priority)

            switch active.type {
            case .static:
                centeredAnnouncementText(active.content, barHeight: barHeight)
            case .flash:
                flashAnnouncementText(active.content, barHeight: barHeight, date: date)
            case .scrolling:
                scrollingAnnouncementText(barHeight: barHeight, date: date)
            }
        }
        .frame(width: size.width * 0.96, height: barHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .offset(y: yOffset)
        .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private func barBackground(for priority: AnnouncementPriority) -> some View {
        let opacity = announcementManager.settings.backgroundOpacity
        switch priority {
        case .breaking:
            LinearGradient(
                colors: [
                    Color.black.opacity(opacity),
                    Color.black.opacity(min(1, opacity + 0.1))
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .high:
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.22, blue: 0.42).opacity(opacity),
                    Color.black.opacity(opacity)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .normal:
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.29, blue: 0.55).opacity(opacity),
                    Color(red: 0.06, green: 0.14, blue: 0.24).opacity(opacity)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .low:
            Color.black.opacity(opacity * 0.84)
        }
    }

    private func centeredAnnouncementText(_ content: String, barHeight: CGFloat) -> some View {
        AnnouncementStrokeText(
            text: content.uppercased(with: Locale(identifier: "es")),
            fontSize: max(22, barHeight * 0.42),
            textColor: .white,
            strokeColor: .black.opacity(0.90),
            strokeWidth: CGFloat(announcementManager.settings.strokeWidth)
        )
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func flashAnnouncementText(_ content: String, barHeight: CGFloat, date: Date) -> some View {
        let visible = Int(date.timeIntervalSinceReferenceDate * 2).isMultiple(of: 2)
        return centeredAnnouncementText(content, barHeight: barHeight)
            .opacity(visible ? 1 : 0.22)
    }

    private func scrollingAnnouncementText(barHeight: CGFloat, date: Date) -> some View {
        let text = announcementManager.tickerFeedText
        let fontSize = max(22, barHeight * 0.42)
        let width = max(estimatedTextWidth(text: text, fontSize: fontSize), size.width * 0.6)
        let totalTravel = size.width + width + 120
        let progress = CGFloat(date.timeIntervalSinceReferenceDate) * CGFloat(announcementManager.settings.speedPointsPerSecond)
        let wrapped = progress.truncatingRemainder(dividingBy: totalTravel)
        let xOffset = (size.width / 2) + (width / 2) + 60 - wrapped

        return AnnouncementStrokeText(
            text: text.uppercased(with: Locale(identifier: "es")),
            fontSize: fontSize,
            textColor: .white,
            strokeColor: .black.opacity(0.92),
            strokeWidth: CGFloat(announcementManager.settings.strokeWidth)
        )
        .fixedSize()
        .offset(x: xOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .clipped()
    }

    private func estimatedTextWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .heavy)
        ]
        return (text as NSString).size(withAttributes: attributes).width
    }
}

struct ProjectionContentCanvas: View {
    let payload: ProjectionPayload?
    let settings: ProjectionStyleSettings
    let size: CGSize
    var isExternalDisplay: Bool = false
    var forcesCompactPreviewLayout: Bool = false
    @EnvironmentObject var displayManager: DisplayManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.12), Color.clear, Color.black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )

            if isSongOutro {
                EmptyView()
            } else if isSongIntro {
                introContent
            } else {
                standardContent
            }
        }
    }

    private var reference: String {
        guard let payload else { return "" }
        let locale = Locale(identifier: "es")
        return payload.reference.uppercased(with: locale)
    }

    private var projectedBody: String {
        guard let payload else { return "" }
        let locale = Locale(identifier: "es")
        return payload.body.uppercased(with: locale)
    }

    private var isSongIntro: Bool {
        payload?.source.hasSuffix(":intro") == true
    }

    private var isSongOutro: Bool {
        payload?.source.hasSuffix(":outro") == true
    }

    private var introLines: [String] {
        projectedBody
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var referenceFontSize: CGFloat {
        let scaled = isBibleProjection
            ? resolvedTextFontSize
            : (resolvedTextFontSize * settings.referenceScale * bibleReferenceScaleMultiplier)
        if isExternalDisplay {
            return max(18, scaled)
        }
        if usesCompactPreviewLayout {
            return min(max(11, scaled * 0.94), 22)
        }
        return min(max(12, scaled), 26)
    }

    private var resolvedTextFontSize: CGFloat {
        if settings.usesAutoTextSize {
            let base = min(size.width, size.height)
            let lengthFactor = max(0.54, 1.16 - Double(projectedBody.count) / 240)
            let minSize: Double
            let maxSize: Double
            let scale: Double

            if isExternalDisplay {
                minSize = settings.minimumAutoTextSize
                maxSize = settings.maximumAutoTextSize
                scale = isManagedTextProjection ? 0.108 : 0.075
            } else if usesCompactPreviewLayout {
                minSize = min(settings.minimumAutoTextSize, 11)
                maxSize = min(settings.maximumAutoTextSize, 32)
                scale = 0.040
            } else {
                minSize = min(settings.minimumAutoTextSize, 12)
                maxSize = min(settings.maximumAutoTextSize, 42)
                scale = 0.050
            }
            let autoSize = min(maxSize, max(minSize, Double(base) * scale * lengthFactor))
            let resolved = autoSize * bibleBodyScaleMultiplier
            if isExternalDisplay, isManagedTextProjection {
                return fittedManagedExternalFontSize(preferred: max(85, resolved))
            }
            return resolved
        }
        if isExternalDisplay {
            let resolved = settings.manualTextSize * bibleBodyScaleMultiplier
            if isManagedTextProjection {
                return fittedManagedExternalFontSize(preferred: max(85, resolved))
            }
            return resolved
        }
        if usesCompactPreviewLayout {
            return min(settings.manualTextSize * bibleBodyScaleMultiplier, 24 * bibleBodyScaleMultiplier)
        }
        return min(settings.manualTextSize * bibleBodyScaleMultiplier, 30 * bibleBodyScaleMultiplier)
    }

    private var resolvedTextOpacity: Double {
        if settings.usesAutoTextOpacity {
            let textLength = max(projectedBody.count, 1)
            return max(0.84, min(1, 1.04 - Double(textLength) / 1500))
        }
        return settings.manualTextOpacity
    }

    private var resolvedBackgroundOpacity: Double {
        if settings.usesAutoBackgroundOpacity {
            let textLength = max(projectedBody.count, 1)
            return max(0.52, min(0.88, 0.60 + Double(textLength) / 820))
        }
        return settings.manualBackgroundOpacity
    }

    private var introTitleFontSize: CGFloat {
        min(size.width * 0.068, 118)
    }

    private var introSubtitleFontSize: CGFloat {
        min(size.width * 0.028, 40)
    }

    private var projectedLines: [String] {
        let baseLines = projectedBody
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !baseLines.isEmpty else { return [] }

        return baseLines.flatMap { wrappedSegments(for: $0) }
    }

    private var usesCompactPreviewLayout: Bool {
        if forcesCompactPreviewLayout { return true }
        guard !isExternalDisplay, let source = payload?.source.lowercased() else { return false }
        return source.hasPrefix("bible:")
            || source.hasPrefix("bible-from-media:")
            || source.hasPrefix("song:")
    }

    private var isBibleProjection: Bool {
        guard let source = payload?.source.lowercased() else { return false }
        return source.hasPrefix("bible:") || source.hasPrefix("bible-from-media:")
    }

    private var isSongProjection: Bool {
        guard let source = payload?.source.lowercased() else { return false }
        return source.hasPrefix("song:")
    }

    private var isManagedTextProjection: Bool {
        isBibleProjection || isSongProjection
    }

    private var managedProjectionWidthRatio: CGFloat {
        if isBibleProjection {
            return max(CGFloat(displayManager.projectionStyleSettings.bibleTextWidthRatio), 0.90)
        }
        if isSongProjection {
            return max(CGFloat(displayManager.projectionStyleSettings.songTextWidthRatio), 0.92)
        }
        return settings.textWidthRatio
    }

    private var managedProjectionWidthFactor: CGFloat {
        if isBibleProjection { return 1.0 }
        if isSongProjection { return 1.0 }
        return 1.0
    }

    private var bibleBodyScaleMultiplier: CGFloat {
        isBibleProjection ? CGFloat(displayManager.bibleProjectionSettings.bodyScaleMultiplier) : 1
    }

    private var bibleReferenceScaleMultiplier: CGFloat {
        isBibleProjection ? CGFloat(displayManager.bibleProjectionSettings.referenceScaleMultiplier) : 1
    }

    private var resolvedPreviewWidthRatio: CGFloat {
        if isExternalDisplay {
            if isManagedTextProjection {
                return managedProjectionWidthRatio
            }
            return settings.textWidthRatio
        }
        if usesCompactPreviewLayout {
            return min(0.96, settings.textWidthRatio + 0.12)
        }
        return min(0.90, settings.textWidthRatio + 0.08)
    }

    private var resolvedPreviewHorizontalPadding: CGFloat {
        if isExternalDisplay {
            if isManagedTextProjection {
                return max(2, settings.textHorizontalPadding * 0.08)
            }
            return settings.textHorizontalPadding
        }
        if usesCompactPreviewLayout {
            return max(6, settings.textHorizontalPadding * 0.42)
        }
        return max(8, settings.textHorizontalPadding * 0.55)
    }

    private var resolvedPreviewVerticalPadding: CGFloat {
        if isExternalDisplay {
            if isBibleProjection {
                return 6
            }
            if isSongProjection {
                return 8
            }
            return 14
        }
        return usesCompactPreviewLayout ? 6 : 8
    }

    private var resolvedPreviewVerticalOffset: CGFloat {
        if isExternalDisplay {
            if isBibleProjection {
                return settings.contentVerticalOffset + (size.height * 0.015)
            }
            if isSongProjection {
                return settings.contentVerticalOffset + (size.height * 0.01)
            }
            return settings.contentVerticalOffset
        }
        return usesCompactPreviewLayout ? settings.contentVerticalOffset * 0.18 : settings.contentVerticalOffset * 0.32
    }

    private var resolvedPreviewLineSpacing: CGFloat {
        if isBibleProjection {
            return max(2, settings.lineSpacing - 6)
        }
        if isSongProjection {
            return max(4, settings.lineSpacing - 4)
        }
        return usesCompactPreviewLayout ? settings.lineSpacing : settings.lineSpacing + 2
    }

    private var standardContent: some View {
        VStack {
            Spacer()

            if projectedBody.isEmpty {
                if !isExternalDisplay {
                    VStack(spacing: 16) {
                        Text("SIN CONTENIDO")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.38))

                        Text("SELECCIONA UNA DIAPOSITIVA DESDE LA CONSOLA")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.24))
                    }
                }
            } else {
                VStack(spacing: isExternalDisplay ? (isBibleProjection ? 10 : 18) : (isBibleProjection ? 8 : 10)) {
                    if !reference.isEmpty {
                        projectionLine(reference, fontSize: referenceFontSize, opacity: settings.referenceOpacity)
                    }

                    ForEach(Array(projectedLines.enumerated()), id: \.offset) { _, line in
                        projectionLine(line, fontSize: resolvedTextFontSize, opacity: resolvedTextOpacity)
                    }
                }
                .frame(maxWidth: size.width * resolvedPreviewWidthRatio)
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .offset(y: resolvedPreviewVerticalOffset)
    }

    private var introContent: some View {
        VStack {
            Spacer()

            VStack(spacing: 18) {
                if let first = introLines.first {
                    Text(first)
                        .font(.system(size: introTitleFontSize, weight: .heavy))
                        .tracking(1.2)
                        .foregroundColor(settings.textColor.swiftUIColor)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.68), radius: 18, x: 0, y: 6)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(Color.black.opacity(0.64))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                if introLines.count > 1 {
                    Text(introLines.dropFirst().joined(separator: "\n"))
                        .font(.system(size: introSubtitleFontSize, weight: .bold))
                        .foregroundColor(settings.textColor.swiftUIColor.opacity(0.94))
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.55), radius: 14, x: 0, y: 5)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.42))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            .frame(maxWidth: size.width * 0.84)

            Spacer()
        }
    }

    @ViewBuilder
    private var textBackground: some View {
        if settings.usesBlackTextBackground {
            Color.black.opacity(resolvedBackgroundOpacity)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var referenceBackground: some View {
        if settings.usesBlackTextBackground {
            Color.black.opacity(min(1, resolvedBackgroundOpacity + 0.08))
        } else {
            Color.white.opacity(0.08)
        }
    }

    private func projectionLine(_ text: String, fontSize: CGFloat, opacity: Double) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy))
            .foregroundColor(settings.textColor.swiftUIColor.opacity(opacity))
            .multilineTextAlignment(.center)
            .lineLimit(isManagedTextProjection ? 1 : nil)
            .lineSpacing(resolvedPreviewLineSpacing)
            .shadow(
                color: Color.black.opacity(min(1, settings.shadowOpacity + 0.14)),
                radius: settings.shadowRadius + 2,
                x: 0,
                y: settings.shadowOffsetY
            )
            .padding(.horizontal, resolvedPreviewHorizontalPadding)
            .padding(.vertical, resolvedPreviewVerticalPadding)
            .background(textBackground)
            .clipShape(RoundedRectangle(cornerRadius: settings.textBlockCornerRadius, style: .continuous))
            .fixedSize(horizontal: isManagedTextProjection, vertical: true)
    }

    private func wrappedSegments(for line: String) -> [String] {
        let compactLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !compactLine.isEmpty else { return [] }

        // Aproximación pragmática para mantener el estilo de bloques segmentados por línea.
        let widthFactor: CGFloat = isManagedTextProjection ? managedProjectionWidthFactor : 1.0
        let glyphFactor: CGFloat = isManagedTextProjection ? 0.56 : 0.54
        let averageGlyphWidth = max(resolvedTextFontSize * glyphFactor, 1)
        let availableWidth = max((size.width * resolvedPreviewWidthRatio * widthFactor) - (resolvedPreviewHorizontalPadding * 2), 120)
        let maxChars = max(Int(availableWidth / averageGlyphWidth), 12)

        if compactLine.count <= maxChars {
            return [compactLine]
        }

        let words = compactLine.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [compactLine] }

        var segments: [String] = []
        var current = ""

        for word in words {
            if current.isEmpty {
                current = word
                continue
            }
            let candidate = current + " " + word
            if candidate.count <= maxChars {
                current = candidate
            } else {
                segments.append(current)
                current = word
            }
        }

        if !current.isEmpty {
            segments.append(current)
        }

        if isManagedTextProjection, segments.count > 1 {
            var merged: [String] = []
            var index = 0
            while index < segments.count {
                let currentSegment = segments[index]
                if index < segments.count - 1, currentSegment.count < 14 {
                    let combined = currentSegment + " " + segments[index + 1]
                    if combined.count <= maxChars {
                        merged.append(combined)
                        index += 2
                        continue
                    }
                }
                merged.append(currentSegment)
                index += 1
            }
            return merged
        }

        return segments
    }

    private func fittedManagedExternalFontSize(preferred: CGFloat) -> CGFloat {
        guard isExternalDisplay, isManagedTextProjection else { return preferred }

        let minimum: CGFloat = 85
        let availableHeight = size.height * (isBibleProjection ? 0.92 : 0.94)
        var candidate = max(minimum, preferred)

        while candidate > minimum {
            let segmentCount = estimatedManagedSegmentCount(fontSize: candidate)
            let lineCount = max(segmentCount + (reference.isEmpty ? 0 : 1), 1)
            let blockHeight = CGFloat(lineCount) * (candidate + (resolvedPreviewVerticalPadding * 2) + resolvedPreviewLineSpacing)

            if blockHeight <= availableHeight {
                return candidate
            }

            candidate -= 1
        }

        return minimum
    }

    private func estimatedManagedSegmentCount(fontSize: CGFloat) -> Int {
        let baseLines = projectedBody
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !baseLines.isEmpty else { return 0 }

        let widthFactor: CGFloat = managedProjectionWidthFactor
        let glyphFactor: CGFloat = isManagedTextProjection ? 0.56 : 0.54
        let averageGlyphWidth = max(fontSize * glyphFactor, 1)
        let availableWidth = max((size.width * resolvedPreviewWidthRatio * widthFactor) - (resolvedPreviewHorizontalPadding * 2), 120)
        let maxChars = max(Int(availableWidth / averageGlyphWidth), 12)

        return baseLines.reduce(into: 0) { total, line in
            let words = line.split(separator: " ").map(String.init)
            guard !words.isEmpty else {
                total += 1
                return
            }

            var segments = 1
            var current = ""

            for word in words {
                if current.isEmpty {
                    current = word
                    continue
                }

                let candidateLine = current + " " + word
                if candidateLine.count <= maxChars {
                    current = candidateLine
                } else {
                    segments += 1
                    current = word
                }
            }

            total += segments
        }
    }
}

struct Projector: View {
    var isExternalDisplay: Bool = false
    var previewFitsContainer: Bool = false
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var announcementManager: AnnouncementManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundLayer
                    .ignoresSafeArea()

                switch displayManager.projectionMode {
                case .logo:
                    logoProjection(size: geometry.size)
                case .blankTheme:
                    EmptyView()
                case .blackout:
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        blackoutProjection(date: context.date, size: geometry.size)
                    }
                case .media:
                    mediaProjection
                case .content:
                    contentProjection(size: geometry.size)
                }

                AnnouncementTickerOverlay(size: geometry.size)
                    .environmentObject(announcementManager)
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch displayManager.projectionMode {
        case .media, .blackout:
            Color.black
        case .logo:
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.25, blue: 0.68),
                    Color(red: 0.08, green: 0.19, blue: 0.56),
                    Color(red: 0.06, green: 0.14, blue: 0.43)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .content, .blankTheme:
            if let mediaImage = displayManager.contentBackgroundMediaImage {
                Image(nsImage: mediaImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let override = displayManager.currentProjection?.backgroundOverride {
                if let url = themeManager.backgroundVideoURL(for: override) {
                    VideoLoopView(url: url)
                } else if let image = themeManager.backgroundImage(for: override) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    themeManager.themeSettings.gradientPreset.gradient
                }
            } else {
                switch themeManager.themeSettings.kind {
                case .gradient:
                    themeManager.themeSettings.gradientPreset.gradient
                case .image:
                    if let image = themeManager.backgroundImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        GradientPreset.midnight.gradient
                    }
                case .video:
                    if let url = themeManager.videoURL {
                        VideoLoopView(url: url)
                    } else {
                        GradientPreset.midnight.gradient
                    }
                }
            }
        }
    }

    private func logoProjection(size: CGSize) -> some View {
        VStack(spacing: 26) {
            if let logoImage = displayManager.logoImage {
                Image(nsImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: size.width * 0.45, maxHeight: size.height * 0.55)
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: min(size.width, size.height) * 0.12, weight: .light))
                    .foregroundColor(Color.white.opacity(0.30))
            }

            Text(displayManager.churchName)
                .font(.system(size: min(60, size.width * 0.04), weight: .bold))
                .foregroundColor(.white)

            if displayManager.logoShowsClock {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(context.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: min(74, size.width * 0.052), weight: .heavy))
                        .foregroundColor(.white.opacity(0.95))
                        .monospacedDigit()
                        .padding(.top, 8)
                }
            }
        }
    }

    private func blackoutProjection(date: Date, size: CGSize) -> some View {
        VStack(spacing: 18) {
            Text(displayManager.churchName)
                .font(.system(size: min(68, size.width * 0.045), weight: .bold))
                .foregroundColor(.white)

            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: min(90, size.width * 0.06), weight: .heavy))
                .foregroundColor(.white.opacity(0.88))
        }
    }

    private func contentProjection(size: CGSize) -> some View {
        ProjectionContentCanvas(
            payload: displayManager.currentProjection,
            settings: displayManager.projectionStyleSettings,
            size: size,
            isExternalDisplay: isExternalDisplay && !previewFitsContainer,
            forcesCompactPreviewLayout: previewFitsContainer
        )
    }

    private var mediaProjection: some View {
        ZStack {
            if let image = displayManager.currentMediaImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
    }
}
