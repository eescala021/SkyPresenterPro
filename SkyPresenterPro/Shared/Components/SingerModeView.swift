import AppKit
import SwiftUI

struct SingerModeView: View {
    @EnvironmentObject private var livePresentationEngine: LivePresentationEngine
    @EnvironmentObject private var remoteSyncService: RemoteSyncService

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 18) {
                singerPanel(
                    title: "ACTUAL",
                    subtitle: statusSubtitle,
                    slide: livePresentationEngine.state.currentSlide,
                    frameKey: remoteSyncService.liveStateDTO.frameKey,
                    prominence: .primary
                )

                singerPanel(
                    title: "SIGUIENTE",
                    subtitle: nextSubtitle,
                    slide: livePresentationEngine.state.nextSlide,
                    frameKey: remoteSyncService.liveStateDTO.nextFrameKey,
                    prominence: .secondary
                )
                .frame(width: max(280, proxy.size.width * 0.34))
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private func singerPanel(
        title: String,
        subtitle: String,
        slide: ProjectionSlide?,
        frameKey: String?,
        prominence: SingerPanelProminence
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: prominence == .primary ? 15 : 13, weight: .black, design: .rounded))
                    .foregroundStyle(prominence == .primary ? Color.white : Color.white.opacity(0.86))
                Text(subtitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.64))
            }

            SingerFramePreviewSurface(
                slide: slide,
                source: livePresentationEngine.currentModule,
                frameKey: frameKey,
                emptyTitle: title == "ACTUAL" ? stateLabel : "SIN SIGUIENTE",
                emptyBody: title == "ACTUAL" ? statusMessage : "La siguiente diapositiva aparecera aqui."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(prominence == .primary ? 0.06 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(prominence == .primary ? 0.16 : 0.1), lineWidth: 1)
                )
        )
    }

    private var statusSubtitle: String {
        switch livePresentationEngine.displayState {
        case .content:
            return livePresentationEngine.state.isLive ? "Salida en vivo" : "Contexto preparado"
        case .logo:
            return "Logo activo"
        case .blank:
            return livePresentationEngine.state.isLyricsHidden ? "Sin letra activo" : "Salida oculta"
        case .standby:
            return "Standby activo"
        }
    }

    private var nextSubtitle: String {
        livePresentationEngine.state.nextSlide == nil ? "Esperando avance" : "Anticipo inmediato"
    }

    private var stateLabel: String {
        switch livePresentationEngine.displayState {
        case .content:
            return livePresentationEngine.state.currentContent.label.uppercased()
        case .logo:
            return "LOGO"
        case .blank:
            return "SIN LETRA"
        case .standby:
            return "STANDBY"
        }
    }

    private var statusMessage: String {
        switch livePresentationEngine.displayState {
        case .content:
            if let currentSlide = livePresentationEngine.state.currentSlide, !currentSlide.lines.isEmpty {
                return currentSlide.lines.joined(separator: "\n").uppercased()
            }
            return "SIN CONTENIDO ACTIVO."
        case .logo:
            return "LA SALIDA PUBLICA ESTA MOSTRANDO EL LOGO."
        case .blank:
            return "EL CONTEXTO SIGUE ACTIVO Y SE RESTAURARA AL NAVEGAR."
        case .standby:
            return "LA SALIDA PUBLICA ESTA EN ESPERA."
        }
    }
}

private struct SingerFramePreviewSurface: View {
    let slide: ProjectionSlide?
    let source: ProjectionSource
    let frameKey: String?
    let emptyTitle: String
    let emptyBody: String

    var body: some View {
        if let frameKey, let image = frameImage(for: frameKey) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else if slide != nil {
            ProjectionPreviewSurface(slide: slide, source: source)
        } else {
            VStack(spacing: 10) {
                Text(emptyTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(emptyBody)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
        }
    }

    private func frameImage(for key: String) -> NSImage? {
        guard let data = RemoteCommandBus.shared.livePreviewData(for: key) else { return nil }
        return NSImage(data: data)
    }
}

private enum SingerPanelProminence {
    case primary
    case secondary
}
