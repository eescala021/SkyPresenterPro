// Archivo: LegacyStatusBar.swift
// Función: Barra secundaria de estado del sistema y del módulo activo.
// Contiene: LegacyStatusBar.
// Uso: Recupera la sensación de consola operativa debajo del chrome principal.

import SwiftUI

struct LegacyStatusBar: View {
    let leftText: String
    let rightText: String
    var isLive: Bool = false

    var body: some View {
        ConsoleSubBar {
            Label(leftText, systemImage: "circle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()

            Text(rightText)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(isLive ? AppColors.success : Color.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isLive ? Color.green.opacity(0.12) : Color.black.opacity(0.04))
                )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }
}
