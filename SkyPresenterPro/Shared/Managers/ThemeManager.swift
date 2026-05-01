import AppKit
import Combine
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @Published var availableThemes: [ProjectionTheme] = []
    @Published var selectedGlobalTheme: ProjectionTheme = .default

    private let storageKey = "theme-manager.stored-themes"
    private let mediaLibraryManager: MediaLibraryManager
    private var cancellables = Set<AnyCancellable>()

    init(mediaLibraryManager: MediaLibraryManager) {
        self.mediaLibraryManager = mediaLibraryManager
        restoreThemes()
        wirePersistence()
    }

    func setGlobalTheme(_ theme: ProjectionTheme) {
        selectedGlobalTheme = theme
    }

    func addTheme(_ theme: ProjectionTheme) {
        availableThemes.append(theme)
    }

    func updateTheme(_ theme: ProjectionTheme) {
        guard let index = availableThemes.firstIndex(where: { $0.id == theme.id }) else { return }
        availableThemes[index] = theme
        if selectedGlobalTheme.id == theme.id {
            selectedGlobalTheme = theme
        }
    }

    func deleteTheme(_ theme: ProjectionTheme) {
        availableThemes.removeAll { $0.id == theme.id }
        if selectedGlobalTheme.id == theme.id {
            selectedGlobalTheme = availableThemes.first ?? .default
        }
    }

    func themes(for source: ProjectionSource) -> [ProjectionTheme] {
        availableThemes.filter {
            switch source {
            case .bible:
                return $0.scope == .bible || $0.scope == .universal
            case .worship:
                return $0.scope == .worship || $0.scope == .universal
            default:
                return true
            }
        }
    }

    private func restoreThemes() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let storedThemes = try? JSONDecoder().decode([StoredProjectionTheme].self, from: data) {
            availableThemes = storedThemes.map(\.projectionTheme)
        } else {
            availableThemes = Self.defaultThemes(from: mediaLibraryManager.imageItems)
        }

        selectedGlobalTheme = availableThemes.first ?? .default
    }

    private func wirePersistence() {
        $availableThemes
            .dropFirst()
            .sink { [weak self] themes in
                self?.persist(themes)
            }
            .store(in: &cancellables)
    }

    private func persist(_ themes: [ProjectionTheme]) {
        let stored = themes.map(StoredProjectionTheme.init)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func defaultThemes(from images: [MediaLibraryItem]) -> [ProjectionTheme] {
        let imagePaths = images
            .filter { $0.kind == .image }
            .sorted { $0.name < $1.name }
            .map(\.filePath)

        func imagePath(_ index: Int) -> String? {
            guard imagePaths.indices.contains(index) else { return nil }
            return imagePaths[index]
        }

        return [
            ProjectionTheme(
                name: "Cielo de Gloria",
                scope: .worship,
                backgroundStyle: .image,
                backgroundGradient: LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom),
                backgroundImagePath: imagePath(0),
                fontSize: 32,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.82),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Lectura Dorada",
                scope: .bible,
                backgroundStyle: .image,
                backgroundGradient: LinearGradient(colors: [.brown, .orange], startPoint: .top, endPoint: .bottom),
                backgroundImagePath: imagePath(1),
                fontSize: 30,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.8),
                textAlignment: .leading
            ),
            ProjectionTheme(
                name: "Barras Negras",
                scope: .universal,
                backgroundStyle: .solid,
                backgroundGradient: LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom),
                backgroundColor: Color(red: 0.12, green: 0.12, blue: 0.12),
                fontSize: 30,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.7),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Círculo Minimal",
                scope: .universal,
                backgroundStyle: .solid,
                backgroundGradient: LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom),
                backgroundColor: Color(red: 0.14, green: 0.14, blue: 0.14),
                fontSize: 29,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.72),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Bruma Azul",
                scope: .worship,
                backgroundStyle: .image,
                backgroundGradient: LinearGradient(colors: [.indigo, .blue], startPoint: .top, endPoint: .bottom),
                backgroundImagePath: imagePath(2),
                fontSize: 31,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.8),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Bosque Reverente",
                scope: .worship,
                backgroundStyle: .image,
                backgroundGradient: LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom),
                backgroundImagePath: imagePath(3),
                fontSize: 31,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.8),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Pizarra Clara",
                scope: .bible,
                backgroundStyle: .solid,
                backgroundGradient: LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom),
                backgroundColor: .white,
                fontSize: 28,
                textColor: .black,
                secondaryTextColor: .black.opacity(0.65),
                textAlignment: .leading,
                shadowEnabled: false
            ),
            ProjectionTheme(
                name: "Nocturno Profundo",
                scope: .universal,
                backgroundStyle: .gradient,
                backgroundGradient: LinearGradient(
                    colors: [Color(red: 0.04, green: 0.05, blue: 0.08), Color(red: 0.12, green: 0.16, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                fontSize: 30,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.78),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Marco Blanco",
                scope: .universal,
                backgroundStyle: .solid,
                backgroundGradient: LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom),
                backgroundColor: Color(red: 0.18, green: 0.18, blue: 0.18),
                fontSize: 29,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.74),
                textAlignment: .center
            ),
            ProjectionTheme(
                name: "Luz del Amanecer",
                scope: .bible,
                backgroundStyle: .image,
                backgroundGradient: LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom),
                backgroundImagePath: imagePath(4),
                fontSize: 30,
                textColor: .white,
                secondaryTextColor: .white.opacity(0.82),
                textAlignment: .leading
            )
        ]
    }
}

private struct StoredProjectionTheme: Codable {
    var id: UUID
    var name: String
    var scope: String
    var backgroundStyle: String
    var gradientStart: [CGFloat]
    var gradientEnd: [CGFloat]
    var backgroundColor: [CGFloat]
    var backgroundImagePath: String?
    var backgroundOpacity: Double
    var fontFamily: String?
    var fontSize: CGFloat
    var fontWeight: String
    var italic: Bool
    var textColor: [CGFloat]
    var secondaryTextColor: [CGFloat]
    var textAlignment: String
    var lineSpacing: CGFloat
    var textMargin: CGFloat
    var shadowEnabled: Bool
    var shadowRadius: CGFloat
    var shadowColor: [CGFloat]
    var outlineEnabled: Bool
    var outlineColor: [CGFloat]
    var glowEnabled: Bool
    var glowRadius: CGFloat
    var showReference: Bool

    init(_ theme: ProjectionTheme) {
        id = theme.id
        name = theme.name
        scope = theme.scope.rawValue
        backgroundStyle = theme.backgroundStyle.rawValue
        gradientStart = theme.backgroundGradient.extractColors().0
        gradientEnd = theme.backgroundGradient.extractColors().1
        backgroundColor = theme.backgroundColor.rgbaComponents
        backgroundImagePath = theme.backgroundImagePath
        backgroundOpacity = theme.backgroundOpacity
        fontFamily = theme.fontFamily
        fontSize = theme.fontSize
        fontWeight = theme.fontWeight.storageValue
        italic = theme.italic
        textColor = theme.textColor.rgbaComponents
        secondaryTextColor = theme.secondaryTextColor.rgbaComponents
        textAlignment = theme.textAlignment.storageValue
        lineSpacing = theme.lineSpacing
        textMargin = theme.textMargin
        shadowEnabled = theme.shadowEnabled
        shadowRadius = theme.shadowRadius
        shadowColor = theme.shadowColor.rgbaComponents
        outlineEnabled = theme.outlineEnabled
        outlineColor = theme.outlineColor.rgbaComponents
        glowEnabled = theme.glowEnabled
        glowRadius = theme.glowRadius
        showReference = theme.showReference
    }

    var projectionTheme: ProjectionTheme {
        ProjectionTheme(
            id: id,
            name: name,
            scope: ProjectionThemeScope(rawValue: scope) ?? .universal,
            backgroundStyle: ProjectionBackgroundStyle(rawValue: backgroundStyle) ?? .gradient,
            backgroundGradient: LinearGradient(
                colors: [Color(rgba: gradientStart), Color(rgba: gradientEnd)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            backgroundColor: Color(rgba: backgroundColor),
            backgroundImagePath: backgroundImagePath,
            backgroundOpacity: backgroundOpacity,
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: Font.Weight(storageValue: fontWeight),
            italic: italic,
            textColor: Color(rgba: textColor),
            secondaryTextColor: Color(rgba: secondaryTextColor),
            textAlignment: TextAlignment(storageValue: textAlignment),
            lineSpacing: lineSpacing,
            textMargin: textMargin,
            shadowEnabled: shadowEnabled,
            shadowRadius: shadowRadius,
            shadowColor: Color(rgba: shadowColor),
            outlineEnabled: outlineEnabled,
            outlineColor: Color(rgba: outlineColor),
            glowEnabled: glowEnabled,
            glowRadius: glowRadius,
            showReference: showReference
        )
    }
}

private extension Color {
    var rgbaComponents: [CGFloat] {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        return [nsColor.redComponent, nsColor.greenComponent, nsColor.blueComponent, nsColor.alphaComponent]
    }

    init(rgba: [CGFloat]) {
        let values = rgba.count == 4 ? rgba : [1, 1, 1, 1]
        self = Color(
            red: values[0],
            green: values[1],
            blue: values[2],
            opacity: values[3]
        )
    }
}

private extension Font.Weight {
    var storageValue: String {
        switch self {
        case .black: return "black"
        case .bold: return "bold"
        case .heavy: return "heavy"
        case .light: return "light"
        case .medium: return "medium"
        case .regular: return "regular"
        case .semibold: return "semibold"
        case .thin: return "thin"
        case .ultraLight: return "ultraLight"
        default: return "regular"
        }
    }

    init(storageValue: String) {
        switch storageValue {
        case "black": self = .black
        case "bold": self = .bold
        case "heavy": self = .heavy
        case "light": self = .light
        case "medium": self = .medium
        case "semibold": self = .semibold
        case "thin": self = .thin
        case "ultraLight": self = .ultraLight
        default: self = .regular
        }
    }
}

private extension TextAlignment {
    var storageValue: String {
        switch self {
        case .leading: return "leading"
        case .center: return "center"
        case .trailing: return "trailing"
        }
    }

    init(storageValue: String) {
        switch storageValue {
        case "leading": self = .leading
        case "trailing": self = .trailing
        default: self = .center
        }
    }
}

private extension LinearGradient {
    func extractColors() -> ([CGFloat], [CGFloat]) {
        ([0.08, 0.08, 0.08, 1], [0.22, 0.22, 0.22, 1])
    }
}
