// Archivo: ProjectionOutputSurface.swift
// Función: Superficie de salida pública unificada — muestra StandbyView o ProjectionRenderer según el estado.
// Contiene: ProjectionOutputSurface.
// Uso: Se usa en ProjectorMonitorView y en la salida externa real.
//      Cuando no hay salida activa muestra StandbyView (con identidad de iglesia o fallback).

import SwiftUI

struct ProjectionOutputSurface: View {
    @EnvironmentObject private var projectionEngine: ProjectionEngine
    @EnvironmentObject private var themeResolver: ThemeResolver
    @EnvironmentObject private var churchIdentity: ChurchIdentityService

    var body: some View {
        if projectionEngine.state.isActive, let slide = projectionEngine.state.currentSlide {
            ProjectionRenderer(slide: slide, theme: resolvedTheme)
        } else {
            StandbyView(identity: churchIdentity)
        }
    }

    private var resolvedTheme: ProjectionTheme {
        switch projectionEngine.state.source {
        case .worship:      return themeResolver.theme(for: .module(.worship))
        case .bible:        return themeResolver.theme(for: .module(.bible))
        case .announcement: return themeResolver.theme(for: .module(.announcement))
        case .presentation: return themeResolver.theme(for: .global)
        case .none:         return themeResolver.theme(for: .global)
        }
    }
}
