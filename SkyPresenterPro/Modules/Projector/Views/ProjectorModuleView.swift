// Archivo: ProjectorModuleView.swift
// Función: Define la raíz visual del módulo Proyector.
// Contiene: ProjectorModuleView.
// Uso: Presenta el módulo Proyector con monitor principal y columna lateral de estado compacta sin espacios muertos.

import SwiftUI

struct ProjectorModuleView: View {
    @EnvironmentObject private var projectionEngine: ProjectionEngine

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ConsoleModuleHeader(
                title: "Proyector",
                subtitle: "Monitoreo de la salida pública en tiempo real"
            ) {
                headerChip(
                    projectionEngine.state.currentSlide == nil ? "En espera" : "En vivo",
                    tint: projectionEngine.state.currentSlide == nil ? Color.orange.opacity(0.12) : Color.green.opacity(0.12),
                    foreground: projectionEngine.state.currentSlide == nil ? .orange : .green
                )
            }

            ConsoleSubBar {
                HStack(spacing: AppSpacing.sm) {
                    headerChip(sourceLabel, tint: Color.blue.opacity(0.12), foreground: .blue)
                    headerChip(projectionEngine.state.nextSlide == nil ? "Sin cola" : "Cola activa", tint: Color.green.opacity(0.12), foreground: .green)
                    Spacer()
                }
            }

            HStack(alignment: .top, spacing: AppSpacing.md) {
                ProjectorMonitorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                projectorStatusSidebar
                    .frame(width: 240, alignment: .top)
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

    private var projectorStatusSidebar: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            statusCard(
                title: "Origen",
                value: sourceLabel,
                detail: "Módulo que controla la salida actual."
            )

            statusCard(
                title: "Actual",
                value: projectionEngine.state.currentSlide?.title ?? "Sin slide",
                detail: projectionEngine.state.currentSlide?.reference ?? "No hay contenido proyectado."
            )

            statusCard(
                title: "Siguiente",
                value: projectionEngine.state.nextSlide?.title ?? "Sin siguiente",
                detail: projectionEngine.state.nextSlide?.reference ?? "No hay cola preparada."
            )

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func statusCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .black))
                .lineLimit(2)

            Text(detail)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private var sourceLabel: String {
        switch projectionEngine.state.source {
        case .worship:   return "Alabanzas"
        case .bible:     return "Biblia"
        case .presentation: return "Presentaciones"
        case .announcement: return "Anuncios"
        case .none:      return "Sin fuente"
        }
    }

    private func headerChip(_ title: String, tint: Color, foreground: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint))
    }
}
