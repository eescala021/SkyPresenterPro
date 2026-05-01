// Archivo: ProjectionRenderer.swift
// Función: Renderiza visualmente un ProjectionSlide aplicando el tema completo.
// Contiene: ProjectionRenderer.
// Uso: Renderer unificado para preview y salida proyectada. Soporta gradiente, color sólido e imagen de fondo.
//      Aplica tipografía, espaciado, márgenes, sombra y brillo definidos en ProjectionTheme.

import SwiftUI
import AppKit

struct ProjectionRenderer: View {
    let slide: ProjectionSlide?
    let theme: ProjectionTheme
    let displayProfile: ProjectorDisplayProfile

    var body: some View {
        GeometryReader { proxy in
            let renderScale = displayProfile.fitScale(for: proxy.size)
            let safeInsets = displayProfile.scaledSafeInsets(for: proxy.size)

            ZStack {
                Color.black.ignoresSafeArea()

                ZStack {
                    // MARK: - Capa de fondo
                    backgroundLayer
                        .opacity(theme.backgroundOpacity)

                    // MARK: - Capa de contenido
                    if let slide, !slide.isBlank {
                        if let imagePath = slide.imagePath,
                           let nsImage = NSImage(contentsOfFile: imagePath) {
                            renderedImage(nsImage, slide: slide, renderScale: renderScale)
                        } else {
                            renderedText(slide, renderScale: renderScale)
                        }
                    }
                }
                .aspectRatio(displayProfile.aspectRatio, contentMode: .fit)
                .padding(safeInsets)
            }
        }
    }

    // MARK: - Capa de fondo según backgroundStyle

    @ViewBuilder
    private var backgroundLayer: some View {
        switch theme.backgroundStyle {
        case .gradient:
            theme.backgroundGradient
        case .solid:
            theme.backgroundColor
        case .image:
            if let path = theme.backgroundImagePath,
               let nsImg = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImg)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                // Fallback al gradiente si la imagen no carga
                theme.backgroundGradient
            }
        }
    }

    // MARK: - Render de imagen (slides PDF/media)

    private func renderedImage(_ image: NSImage, slide: ProjectionSlide, renderScale: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let title = slide.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: max(11, 14 * renderScale), weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12 * renderScale)
                    .padding(.vertical, 8 * renderScale)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .padding(16 * renderScale)
            }
        }
    }

    // MARK: - Render de texto (Biblia / Alabanzas)

    private func renderedText(_ slide: ProjectionSlide, renderScale: CGFloat) -> some View {
        let margin = max(16, theme.textMargin * renderScale)
        let spacing = max(8, theme.lineSpacing * renderScale)

        return VStack(spacing: spacing) {
            if let title = slide.title {
                textView(
                    title,
                    size: max(26, theme.fontSize * 1.4 * renderScale),
                    weight: theme.fontWeight,
                    color: theme.textColor,
                    scaleFactor: 0.65
                )
            }

            if let subtitle = slide.subtitle {
                textView(
                    subtitle,
                    size: max(16, theme.fontSize * 0.73 * renderScale),
                    weight: .medium,
                    color: theme.secondaryTextColor,
                    scaleFactor: 0.7
                )
            }

            VStack(spacing: max(6, (theme.lineSpacing * 0.46) * renderScale)) {
                ForEach(slide.lines, id: \.self) { line in
                    textView(
                        line,
                        size: max(20, theme.fontSize * renderScale),
                        weight: theme.fontWeight,
                        color: theme.textColor,
                        scaleFactor: 0.55
                    )
                    .frame(maxWidth: .infinity, alignment: theme.frameAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let reference = slide.reference, theme.showReference {
                textView(
                    reference,
                    size: max(14, theme.fontSize * 0.60 * renderScale),
                    weight: .medium,
                    color: theme.secondaryTextColor,
                    scaleFactor: 0.75
                )
            }
        }
        .padding(margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Text view unificado con efectos

    private func textView(
        _ text: String,
        size: CGFloat,
        weight: Font.Weight,
        color: Color,
        scaleFactor: CGFloat
    ) -> some View {
        let resolvedFont: Font = {
            if let family = theme.fontFamily {
                let f = Font.custom(family, size: size)
                return theme.italic ? f.italic() : f
            }
            let f = Font.system(size: size, weight: weight)
            return theme.italic ? f.italic() : f
        }()

        return Text(text)
            .font(resolvedFont)
            .foregroundStyle(color)
            .multilineTextAlignment(theme.textAlignment)
            .minimumScaleFactor(scaleFactor)
            // Sombra
            .shadow(
                color: theme.shadowEnabled ? theme.shadowColor : .clear,
                radius: theme.shadowEnabled ? theme.shadowRadius : 0
            )
            // Brillo/glow (se simula con doble sombra difusa blanca)
            .shadow(
                color: theme.glowEnabled ? color.opacity(0.5) : .clear,
                radius: theme.glowEnabled ? theme.glowRadius : 0
            )
    }
}
