// Archivo: BibleFavoritesPanel.swift
// Función: Lista compacta de referencias favoritas del módulo Biblia.
// Contiene: BibleFavoritesPanel.
// Uso: Panel sin card propia — integrado en la franja inferior del panel central unificado con acceso rápido de alta densidad.

import SwiftUI

struct BibleFavoritesPanel: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("FAVORITOS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.favorites.count)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)

            if viewModel.favorites.isEmpty {
                Text("Sin favoritos guardados")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.favorites, id: \.self) { reference in
                            favoriteRow(reference)
                            Divider().padding(.leading, 28)
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
    }

    private func favoriteRow(_ reference: BibleReference) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "star.fill")
                .font(.system(size: 9))
                .foregroundStyle(.yellow)

            Text(reference.displayText)
                .font(.system(size: 11, weight: .bold))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.jump(to: reference)
        }
    }
}
