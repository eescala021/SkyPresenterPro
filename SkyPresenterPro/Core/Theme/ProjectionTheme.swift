// Archivo: ProjectionTheme.swift
// Función: Define la estructura visual completa de un tema de proyección.
// Contiene: ProjectionThemeScope, ProjectionBackgroundStyle, ProjectionTheme.
// Uso: Motor de renderizado, resolución de temas y selectores de UI en Biblia/Alabanzas.

import SwiftUI

// MARK: - Scope

enum ProjectionThemeScope: String, Codable, CaseIterable {
    case worship    // Solo Alabanzas
    case bible      // Solo Biblia
    case universal  // Ambos módulos

    var displayName: String {
        switch self {
        case .worship:   return "Alabanzas"
        case .bible:     return "Biblia"
        case .universal: return "Universal"
        }
    }
}

// MARK: - Background style

enum ProjectionBackgroundStyle: String, Codable {
    case gradient   // LinearGradient (comportamiento original)
    case solid      // Color sólido
    case image      // Ruta de archivo local
}

// MARK: - Theme

struct ProjectionTheme: Identifiable, Equatable {
    static func == (lhs: ProjectionTheme, rhs: ProjectionTheme) -> Bool {
        lhs.id == rhs.id
    }

    let id: UUID
    var name: String
    var scope: ProjectionThemeScope

    // MARK: Fondo
    var backgroundStyle: ProjectionBackgroundStyle
    var backgroundGradient: LinearGradient
    var backgroundColor: Color
    var backgroundImagePath: String?
    var backgroundOpacity: Double

    // MARK: Texto
    var fontFamily: String?       // nil → SF Pro / sistema
    var fontSize: CGFloat         // tamaño base de líneas principales (escala con renderScale)
    var fontWeight: Font.Weight
    var italic: Bool
    var textColor: Color
    var secondaryTextColor: Color
    var textAlignment: TextAlignment
    var lineSpacing: CGFloat
    var textMargin: CGFloat       // padding interior del bloque de texto

    // MARK: Efectos
    var shadowEnabled: Bool
    var shadowRadius: CGFloat
    var shadowColor: Color
    var outlineEnabled: Bool
    var outlineColor: Color
    var glowEnabled: Bool
    var glowRadius: CGFloat

    // MARK: Opciones
    var showReference: Bool

    // MARK: - Init completo

    init(
        id: UUID = UUID(),
        name: String,
        scope: ProjectionThemeScope = .universal,
        backgroundStyle: ProjectionBackgroundStyle = .gradient,
        backgroundGradient: LinearGradient,
        backgroundColor: Color = .black,
        backgroundImagePath: String? = nil,
        backgroundOpacity: Double = 1.0,
        fontFamily: String? = nil,
        fontSize: CGFloat = 30,
        fontWeight: Font.Weight = .semibold,
        italic: Bool = false,
        textColor: Color = .white,
        secondaryTextColor: Color = .white.opacity(0.75),
        textAlignment: TextAlignment = .center,
        lineSpacing: CGFloat = 14,
        textMargin: CGFloat = 28,
        shadowEnabled: Bool = false,
        shadowRadius: CGFloat = 4,
        shadowColor: Color = .black.opacity(0.5),
        outlineEnabled: Bool = false,
        outlineColor: Color = .black,
        glowEnabled: Bool = false,
        glowRadius: CGFloat = 4,
        showReference: Bool = true
    ) {
        self.id = id
        self.name = name
        self.scope = scope
        self.backgroundStyle = backgroundStyle
        self.backgroundGradient = backgroundGradient
        self.backgroundColor = backgroundColor
        self.backgroundImagePath = backgroundImagePath
        self.backgroundOpacity = backgroundOpacity
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.italic = italic
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.textAlignment = textAlignment
        self.lineSpacing = lineSpacing
        self.textMargin = textMargin
        self.shadowEnabled = shadowEnabled
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.outlineEnabled = outlineEnabled
        self.outlineColor = outlineColor
        self.glowEnabled = glowEnabled
        self.glowRadius = glowRadius
        self.showReference = showReference
    }

    // MARK: - Compatibilidad con usos previos

    var frameAlignment: Alignment {
        switch textAlignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    // MARK: - Presets

    static let `default` = ProjectionTheme(
        name: "Medianoche",
        scope: .universal,
        backgroundGradient: LinearGradient(
            colors: [Color.black, Color.blue.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let bibleDefault = ProjectionTheme(
        name: "Biblia",
        scope: .bible,
        backgroundGradient: LinearGradient(
            colors: [Color.black, Color.purple.opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let white = ProjectionTheme(
        name: "Blanco",
        scope: .universal,
        backgroundStyle: .solid,
        backgroundGradient: LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom),
        backgroundColor: .white,
        textColor: .black,
        secondaryTextColor: Color.black.opacity(0.55),
        shadowEnabled: true,
        shadowRadius: 0,
        shadowColor: .clear
    )

    static let ocean = ProjectionTheme(
        name: "Océano",
        scope: .universal,
        backgroundGradient: LinearGradient(
            colors: [
                Color(red: 0.01, green: 0.03, blue: 0.18),
                Color(red: 0.03, green: 0.16, blue: 0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let royal = ProjectionTheme(
        name: "Royal",
        scope: .universal,
        backgroundGradient: LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.0, blue: 0.22),
                Color(red: 0.20, green: 0.04, blue: 0.52)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let forest = ProjectionTheme(
        name: "Bosque",
        scope: .worship,
        backgroundGradient: LinearGradient(
            colors: [
                Color(red: 0.01, green: 0.09, blue: 0.03),
                Color(red: 0.04, green: 0.24, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let sunset = ProjectionTheme(
        name: "Atardecer",
        scope: .worship,
        backgroundGradient: LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.03, blue: 0.02),
                Color(red: 0.58, green: 0.14, blue: 0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let slate = ProjectionTheme(
        name: "Pizarra",
        scope: .bible,
        backgroundGradient: LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.10),
                Color(red: 0.12, green: 0.14, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    // MARK: - Librerías de temas

    static var builtinLibrary: [ProjectionTheme] {
        [.default, .bibleDefault, .ocean, .royal, .forest, .sunset, .slate, .white]
    }

    static var worshipLibrary: [ProjectionTheme] {
        builtinLibrary.filter { $0.scope == .worship || $0.scope == .universal }
    }

    static var bibleLibrary: [ProjectionTheme] {
        builtinLibrary.filter { $0.scope == .bible || $0.scope == .universal }
    }
}
