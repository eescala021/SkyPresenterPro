// Archivo: ProjectionPreviewSurface.swift
// Función: Muestra una vista previa local de un slide proyectable con el tema correcto según fuente.
// Contiene: ProjectionPreviewSurface.
// Uso: Se usa en paneles de preview de Biblia, Alabanzas y Presentaciones.
//      Pasa `source` para resolver el tema correcto del módulo correspondiente.

import SwiftUI

struct ProjectionPreviewSurface: View {
    let slide: ProjectionSlide?
    var source: ProjectionSource = .none

    @EnvironmentObject private var themeResolver: ThemeResolver
    @EnvironmentObject private var externalDisplayManager: ExternalDisplayManager

    var body: some View {
        ProjectionRenderer(
            slide: slide,
            theme: resolvedTheme,
            displayProfile: externalDisplayManager.activeProjectionProfile
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var resolvedTheme: ProjectionTheme {
        switch source {
        case .worship:      return themeResolver.theme(for: .module(.worship))
        case .bible:        return themeResolver.theme(for: .module(.bible))
        case .announcement: return themeResolver.theme(for: .module(.announcement))
        default:            return themeResolver.theme(for: .global)
        }
    }
}
