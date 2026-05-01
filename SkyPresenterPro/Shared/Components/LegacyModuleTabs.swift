// Archivo: LegacyModuleTabs.swift
// Función: Dibuja la barra de pestañas de módulos compacta para integración inline en el chrome global.
// Contiene: LegacyModuleTabs.
// Uso: Permite seleccionar el módulo activo con botones compactos en una sola fila horizontal sin etiqueta separada.

import SwiftUI

struct LegacyModuleTabs: View {
    @Binding var selectedRoute: AppRoute

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                tabButton(.bible, icon: "book.closed")
                tabButton(.worship, icon: "music.note")
                tabButton(.presentations, icon: "rectangle.on.rectangle")
                tabButton(.projector, icon: "display")
                tabButton(.settings, icon: "gearshape")
                tabButton(.help, icon: "questionmark.circle")
            }
            .padding(.vertical, 1)
        }
    }

    private func tabButton(_ route: AppRoute, icon: String) -> some View {
        Button {
            selectedRoute = route
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(route.rawValue)
            }
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(selectedRoute == route ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selectedRoute == route ? AppColors.accent : Color.black.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(selectedRoute == route ? AppColors.accent.opacity(0.45) : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
