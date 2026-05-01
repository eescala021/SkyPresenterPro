// Archivo: BibleLibraryWindow.swift
// Función: Define un contenedor visual para la biblioteca bíblica.
// Contiene: BibleLibraryWindow.
// Uso: Sirve como scaffold para encapsular el grid de libros y futuros controles de biblioteca.
import SwiftUI

struct BibleLibraryWindow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md, content: content)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
