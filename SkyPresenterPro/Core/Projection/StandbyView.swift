// Archivo: StandbyView.swift
// Función: Pantalla base global del sistema de proyección cuando no hay contenido activo.
// Contiene: StandbyView.
// Uso: Mostrada en ProjectionOutputSurface cuando isActive == false.
//      Soporta identidad de iglesia (logo, nombre, mensaje) y reloj en tiempo real.
//      Fallback: fondo negro + "Sky Presenter Pro" si no hay configuración personalizada.

import SwiftUI

struct StandbyView: View {
    @ObservedObject var identity: ChurchIdentityService
    @State private var clockText = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hasCustomContent: Bool {
        !identity.churchName.isEmpty
            || identity.logoImage != nil
            || !identity.standbyMessage.isEmpty
            || identity.standbyShowClock
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if hasCustomContent {
                customStandby
            } else {
                fallbackStandby
            }
        }
    }

    // MARK: - Fallback

    private var fallbackStandby: some View {
        Text("Sky Presenter Pro")
            .font(.system(size: 52, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }

    // MARK: - Custom

    private var customStandby: some View {
        VStack(spacing: 20) {
            if let logo = identity.logoImage {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 180)
            }

            if !identity.churchName.isEmpty {
                Text(identity.churchName)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            if !identity.standbyMessage.isEmpty {
                Text(identity.standbyMessage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            if identity.standbyShowClock {
                Text(clockText)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .onReceive(timer) { _ in updateClock() }
                    .onAppear { updateClock() }
            }
        }
        .padding(48)
    }

    private func updateClock() {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        clockText = f.string(from: Date())
    }
}
