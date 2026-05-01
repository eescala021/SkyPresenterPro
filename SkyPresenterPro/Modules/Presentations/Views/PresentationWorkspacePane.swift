// Archivo: PresentationWorkspacePane.swift
// Función: Área de trabajo del módulo Presentaciones — preview dominante con tira de slides.
// Contiene: PresentationWorkspacePane.
// Uso: Cabecera compacta inline → preview dominante flex → tira de slides. Sin capas redundantes de información.

import SwiftUI
import AppKit

struct PresentationWorkspacePane: View {
    @EnvironmentObject private var viewModel: PresentationViewModel
    @EnvironmentObject private var projectionEngine: ProjectionEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let document = viewModel.selectedDocument {
                workspaceHeader(document)
                Divider()
                dominantPreview(for: document)
                    .layoutPriority(1)
                Divider()
                PresentationSlidesStrip(document: document)
            } else {
                PresentationEmptyStateView(
                    title: "Sin presentación activa",
                    message: "Selecciona una presentación para comenzar."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Header compacto

    private func workspaceHeader(_ document: PresentationDocument) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPresentationLive ? Color.green : Color.orange)
                .frame(width: 7, height: 7)

            Text(document.title)
                .font(.system(size: 13, weight: .black))
                .lineLimit(1)

            stateChip(viewModel.selectedDocumentPageLabel, color: .blue)
            stateChip(viewModel.preparedDocumentPageLabel, color: .orange)
            stateChip(viewModel.projectedDocumentPageLabel, color: isPresentationLive ? .green : .secondary)

            if let ref = viewModel.detectedReferences.first {
                stateChip(ref.reference.displayText, color: .purple)
            }

            Spacer()

            Button {
                viewModel.goToPreviousSlide()
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .help("Slide anterior")

            Button {
                viewModel.goToNextSlide()
            } label: {
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .help("Slide siguiente")

            Button("Proyectar") {
                viewModel.projectPreparedSlide()
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button {
                viewModel.clearProjection()
            } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .help("Limpiar salida")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Preview dominante (flex)

    private func dominantPreview(for document: PresentationDocument) -> some View {
        ZStack {
            Color.white

            if let imagePath = viewModel.workspaceSlide?.imagePath,
               let nsImage = NSImage(contentsOfFile: imagePath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text(currentSlideTitle(for: document))
                        .font(.system(size: 16, weight: .black))
                        .multilineTextAlignment(.center)
                }
                .padding(AppSpacing.xl)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text(workspaceSlideSubtitle(for: document))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private var isPresentationLive: Bool {
        projectionEngine.state.source == .presentation && projectionEngine.state.currentSlide != nil
    }

    private func currentSlideTitle(for document: PresentationDocument) -> String {
        viewModel.workspaceSlide?.title
            ?? "Página \((viewModel.workspaceSlide?.pageIndex ?? 0) + 1) de \(document.pageCount)"
    }

    private func workspaceSlideSubtitle(for document: PresentationDocument) -> String {
        let pageLabel = viewModel.preparedSlide.map {
            "Página \($0.pageIndex + 1) de \(document.pageCount)"
        } ?? viewModel.selectedDocumentPageLabel
        if let firstNote = viewModel.workspaceSlide?.notes.first, !firstNote.isEmpty {
            return "\(pageLabel) · \(firstNote)"
        }
        return pageLabel
    }

    private func stateChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
