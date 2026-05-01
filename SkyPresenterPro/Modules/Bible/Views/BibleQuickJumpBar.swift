// Archivo: BibleQuickJumpBar.swift
// Función: Barra compacta de búsqueda y salto rápido del módulo Biblia.
// Contiene: BibleQuickJumpBar.
// Uso: Una sola fila horizontal — campo, botón Ir, limpiar y métricas inline, sin ConsoleSubBar ni hints multilínea.

import SwiftUI

struct BibleQuickJumpBar: View {
    @EnvironmentObject private var viewModel: BibleViewModel
    @State private var query: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)

            TextField("Gn 1:1, Jn 3:16, Sal 23...", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .onSubmit { goToReference() }

            Button("Ir") { goToReference() }
                .buttonStyle(PrimaryActionButtonStyle())

            Button("Limpiar") {
                query = ""
                viewModel.updateSearch("")
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: 1, height: 16)

            Text("Caps \(viewModel.chapters.count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Text("·")
                .foregroundStyle(.secondary)

            Text("Vers \(viewModel.verses.count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            if let verse = viewModel.navigation.selectedVerse {
                Text("· Sel \(verse.number)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func goToReference() {
        let parser = BibleSearchService()
        if let reference = parser.parseReference(query) {
            viewModel.jump(to: reference)
        } else {
            viewModel.updateSearch(query)
        }
    }
}
