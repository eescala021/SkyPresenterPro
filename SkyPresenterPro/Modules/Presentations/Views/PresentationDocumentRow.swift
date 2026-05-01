// Archivo: PresentationDocumentRow.swift
// Función: Define la fila reutilizable para mostrar un documento en la biblioteca de Presentaciones.
// Contiene: PresentationDocumentRow.
// Uso: Presenta un documento dentro de la biblioteca lateral con énfasis visual en la selección activa,
//      botón de eliminar al hacer hover, y menú contextual de acciones.

import SwiftUI

struct PresentationDocumentRow: View {
    let document: PresentationDocument
    let isSelected: Bool
    var onDelete: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(previewTint)
                    .frame(width: 18, height: 78)

                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(document.sourceFileName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("PDF")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(previewForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(previewTint)
                        )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    // Botón eliminar — visible solo en hover
                    if isHovered, let onDelete {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.red)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.10))
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSelected ? .blue : .secondary)
                    }

                    if isSelected && !isHovered {
                        Text("ACTIVO")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.blue)
                    }
                }
            }

            HStack {
                Text("\(document.pageCount) páginas")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(document.sourceURL == nil ? "Sin archivo enlazado" : "Listo")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.45) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovered in
            isHovered = hovered
        }
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Eliminar presentación", systemImage: "trash")
                }
            }
        }
    }

    private var previewTint: Color {
        isSelected ? Color.blue.opacity(0.18) : Color.gray.opacity(0.12)
    }

    private var previewForeground: Color {
        isSelected ? .blue : .secondary
    }
}
