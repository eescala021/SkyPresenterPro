// Archivo: WorshipModuleView.swift
// Función: Define la vista raíz del módulo de Alabanzas.
// Contiene: WorshipModuleView.
// Uso: Presenta la biblioteca, el editor central y el panel de preview en vivo con layout compacto y sin espacios muertos.

import SwiftUI

struct WorshipModuleView: View {
    @EnvironmentObject private var viewModel: WorshipViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            moduleHeader

            ThreePaneLayout(leadingWidth: 240, trailingWidth: 280) {
                WorshipLibraryPane()
            } center: {
                WorshipWorkspacePane()
            } trailing: {
                WorshipLivePane()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var moduleHeader: some View {
        ConsoleModuleHeader(
            title: "Alabanzas",
            subtitle: "Biblioteca de canciones, edición y preview en vivo"
        ) {
            HStack(spacing: AppSpacing.sm) {
                infoChip("\(viewModel.filteredSongs.count) canciones", tint: Color.blue.opacity(0.14), foreground: .blue)
                infoChip("\(viewModel.queue.count) en cola", tint: Color.green.opacity(0.14), foreground: .green)
            }
        }
    }

    private func infoChip(_ title: String, tint: Color, foreground: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint)
            )
    }
}
