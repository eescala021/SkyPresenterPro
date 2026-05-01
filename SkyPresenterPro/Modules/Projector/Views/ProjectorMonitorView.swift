// Archivo: ProjectorMonitorView.swift
// Función: Monitor de la salida pública. Muestra SIEMPRE ProjectionOutputSurface (standby o contenido real).
// Contiene: ProjectorMonitorView.
// Uso: El monitor refleja en todo momento el estado real del proyector: standby o slide activo.

import SwiftUI

struct ProjectorMonitorView: View {
    @EnvironmentObject private var projectionEngine: ProjectionEngine

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Monitor del proyector")
                    .font(.system(size: 28, weight: .black))

                Spacer()

                Text(statusText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.12))
                    )
            }

            ConsoleSubBar {
                HStack(spacing: AppSpacing.sm) {
                    monitorChip(statusText, tint: statusColor.opacity(0.12), foreground: statusColor)
                    monitorChip(projectionEngine.state.sourceDisplayName, tint: Color.blue.opacity(0.12), foreground: .blue)
                    monitorChip(projectionEngine.state.currentContent.label, tint: Color.black.opacity(0.05), foreground: .primary)
                    Spacer()
                }
            }

            // El monitor SIEMPRE muestra la salida real (standby o contenido)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black)

                ProjectionOutputSurface()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Meta bar inferior — solo visible si hay salida activa
                if isProjectingLive {
                    HStack(spacing: AppSpacing.md) {
                        projectorMeta(title: "Actual", value: projectionEngine.state.currentContent.label)
                        projectorMeta(title: "Siguiente", value: projectionEngine.state.nextContent?.label ?? "Sin siguiente")
                        projectorMeta(title: "Origen", value: projectionEngine.state.sourceDisplayName)
                        projectorMeta(title: "Estado", value: "Salida pública real")
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 420, maxHeight: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var statusText: String {
        isProjectingLive ? "En vivo" : "Standby"
    }

    private var statusColor: Color {
        isProjectingLive ? .green : .orange
    }

    private var isProjectingLive: Bool {
        projectionEngine.state.source != .none && projectionEngine.state.currentSlide != nil
    }

    private func monitorChip(_ value: String, tint: Color, foreground: Color) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .black))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tint)
            )
    }

    private func projectorMeta(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}
