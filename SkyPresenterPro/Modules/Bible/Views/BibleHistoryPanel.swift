// Archivo: BibleHistoryPanel.swift
// Función: Lista compacta de referencias recientes del módulo Biblia.
// Contiene: BibleHistoryPanel.
// Uso: Panel sin card propia — integrado en la franja inferior del panel central unificado con historial de navegación de alta densidad.

import SwiftUI

struct BibleHistoryPanel: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("HISTORIAL")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.history.count)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)

            if viewModel.history.isEmpty {
                Text("Sin referencias recientes")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.history, id: \.self) { reference in
                            historyRow(reference)
                            Divider().padding(.leading, 28)
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
    }

    private func historyRow(_ reference: BibleReference) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

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
