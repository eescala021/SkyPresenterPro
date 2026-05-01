// Archivo: ConsoleSubBar.swift
// Función: Subbarra horizontal reutilizable para acciones o métricas secundarias de módulos.
// Contiene: ConsoleSubBar.
// Uso: Scaffold visual compacto para información de estado debajo del encabezado principal.

import SwiftUI

struct ConsoleSubBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: AppSpacing.md, content: content)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 1)
    }
}
