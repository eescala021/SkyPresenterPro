import SwiftUI

// Archivo: LegacyTopBar.swift
// Función: Dibuja la cabecera superior de la consola con branding, acciones rápidas y estado.
// Contiene: LegacyTopBar.
// Uso: Replica la sensación visual de la app vieja en la parte superior de la ventana principal evitando opciones duplicadas con la barra de módulos.

struct LegacyTopBar: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 30, weight: .black))

                    Text("V1.4")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.12))
                        )
                }

                Text(subtitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                legacyBadge(title: "F8 Logo", color: AppColors.success)
                legacyBadge(title: "F9 Fondo", color: AppColors.accent)
                legacyBadge(title: "F10 Pantalla Negra", color: AppColors.panel)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(AppColors.success)
                    .frame(width: 8, height: 8)

                Text("Sin pantalla externa")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.md)
                    .fill(Color.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.md)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private func legacyBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}
