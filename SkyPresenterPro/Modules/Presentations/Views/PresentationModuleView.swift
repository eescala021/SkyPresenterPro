// Archivo: PresentationModuleView.swift
// Función: Define la vista raíz del módulo de Presentaciones.
// Contiene: PresentationModuleView.
// Uso: Compone el layout principal — cabecera única con estado inline, biblioteca, workspace y panel en vivo.

import SwiftUI

struct PresentationModuleView: View {
    @EnvironmentObject private var viewModel: PresentationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            moduleHeader

            ThreePaneLayout(leadingWidth: 220, trailingWidth: 248) {
                PresentationLibraryPane()
            } center: {
                PresentationWorkspacePane()
            } trailing: {
                PresentationLivePane()
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
        .sheet(isPresented: $viewModel.isShowingImportWindow) {
            PresentationImportWindow()
        }
    }

    private var moduleHeader: some View {
        ConsoleModuleHeader(
            title: "Presentaciones",
            subtitle: "PDFs, PowerPoints e insumos para presentar en vivo"
        ) {
            HStack(spacing: AppSpacing.sm) {
                if let doc = viewModel.selectedDocument {
                    infoChip(doc.title, tint: Color.black.opacity(0.06), foreground: .primary)
                    infoChip(viewModel.selectedDocumentPageLabel, tint: Color.orange.opacity(0.12), foreground: .orange)
                    infoChip(viewModel.projectedDocumentPageLabel, tint: Color.green.opacity(0.12), foreground: .green)
                }

                Text("\(viewModel.filteredDocuments.count) archivos")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.secondary)

                Button("Importar") {
                    viewModel.isShowingImportWindow = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func infoChip(_ title: String, tint: Color, foreground: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black))
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint))
    }
}
