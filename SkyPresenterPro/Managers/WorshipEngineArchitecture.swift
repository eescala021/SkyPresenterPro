import Foundation

// Esquema técnico del Worship Engine por capas.
// Este archivo define contratos de arquitectura para fases siguientes
// sin acoplar ni romper el runtime actual.

protocol WorshipSongRepository {
    func fetchAllSongs() async throws -> [WorshipSongRecord]
    func saveSong(_ song: WorshipSongRecord) async throws
    func deleteSong(id: UUID) async throws
}

protocol WorshipLyricsImporting {
    func importLyrics(query: String) async throws -> String
}

protocol BibleMultiVersionProvider {
    func versions() async throws -> [String]
    func books(version: String) async throws -> [String]
    func chapters(version: String, book: String) async throws -> [Int]
    func verses(version: String, book: String, chapter: Int) async throws -> [String]
}

protocol StageDisplayEventStreaming {
    func broadcastCurrentSlide(reference: String, body: String, notes: String)
    func broadcastNextSlide(reference: String, body: String)
    func broadcastClock(date: Date)
}

struct WorshipEngineModuleGraph {
    var songRepository: any WorshipSongRepository
    var lyricsImporter: (any WorshipLyricsImporting)?
    var bibleProvider: (any BibleMultiVersionProvider)?
    var stageStreaming: (any StageDisplayEventStreaming)?
}

enum PendingWorkArea: String, Codable {
    case security
    case backup
    case interoperability
    case scripture
    case projectionHistory
    case interface
    case webApp
    case themes
    case localization
    case licensing
    case quality
}

struct PendingWorkItem: Identifiable, Codable, Hashable {
    let id: UUID
    let area: PendingWorkArea
    let title: String
    let detail: String
    let targetVersion: String

    init(
        id: UUID = UUID(),
        area: PendingWorkArea,
        title: String,
        detail: String,
        targetVersion: String
    ) {
        self.id = id
        self.area = area
        self.title = title
        self.detail = detail
        self.targetVersion = targetVersion
    }
}

enum SkyPresenterRoadmap {
    static let currentInternalVersion = SkyPresenterVersion.internalRelease
    static let publicLaunchTarget = SkyPresenterVersion.publicLaunchTarget

    // Cola técnica pendiente validada para siguientes fases sin afectar el runtime actual.
    static let securityAndBackupQueue: [PendingWorkItem] = [
        PendingWorkItem(
            area: .interface,
            title: "V1.4 · Pulido total del módulo Alabanzas",
            detail: "Prioridad principal de V1.4: refinar biblioteca, módulo de letra, editor, en directo y playlist de servicio con una UX más cercana a un flujo litúrgico profesional.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .interface,
            title: "V1.4 · Pulido de En Directo",
            detail: "Ajustar escalado, bloques de texto, relación de aspecto y sincronización de previews internos para Biblia, Alabanzas y Presentaciones.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .webApp,
            title: "V1.4 · Pulido de Web App remota",
            detail: "Compactar la interfaz remota para Biblia, Presentaciones y Presentador, con navegación más táctil, menor latencia y estado más estable en tiempo real.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .themes,
            title: "V1.4 · Pulido del motor de Temas",
            detail: "Refinar la edición de temas, la herencia visual y la selección de fondos por módulo y por diapositiva.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .licensing,
            title: "Reemplazo de Reina Valera 1960 por una versión gratuita",
            detail: "Sustituir la versión bíblica por defecto por una licencia gratuita o de dominio permitido para evitar conflictos de derechos de autor en la distribución pública.",
            targetVersion: "V1.4+"
        ),
        PendingWorkItem(
            area: .quality,
            title: "Corrección de metadata y preferencias de Xcode",
            detail: "Eliminar almacenamiento excesivo en UserDefaults, revisar duplicados innecesarios y estabilizar advertencias de consola relacionadas con preferencias y metadata.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .localization,
            title: "Soporte multilingüe ES / EN / PT",
            detail: "Preparar localización base de la app y flujo de selección inicial de idioma para distribución futura mediante instalador/DMG.",
            targetVersion: "V1.4+"
        ),
        PendingWorkItem(
            area: .backup,
            title: "Archivo contenedor de respaldo atómico",
            detail: "Crear un contenedor único tipo .worshipzip/.hbk con capa de base de datos SQLite, configuraciones JSON y carpeta de assets con rutas relativas restaurables.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .backup,
            title: "Exportación selectiva y total con checksum",
            detail: "Permitir exportación por lote de canciones, temas y configuraciones, con serialización previa a JSON/XML y hash SHA-256 para validación de integridad.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .security,
            title: "Escaneo previo e importación con resolución de conflictos",
            detail: "Analizar el lote antes de importar, mostrar resumen y permitir Omitir, Sobrescribir o Duplicar cuando existan canciones repetidas.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .backup,
            title: "Remapeo automático de assets",
            detail: "Copiar imágenes y videos del respaldo al directorio local de la app y actualizar referencias internas para no romper vínculos multimedia.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .backup,
            title: "Auto-snapshot al cerrar la app",
            detail: "Generar respaldos preventivos ligeros de base de datos al cierre, manteniendo rotación automática de solo los últimos 5 archivos.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .interoperability,
            title: "Parser de terceros y migración legacy",
            detail: "Leer archivos .db de EasyWorship y .json de VideoPsalm, mapear Verso/Coro/Puente a la estructura interna y adjuntar sus assets.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .scripture,
            title: "Scripture Engine con SQLite + FTS5 y tres slots activos",
            detail: "Migrar Biblia a bases SQLite indexadas, soportar versiones Estándar, Auxiliar 1 y Auxiliar 2, e importar nuevas versiones desde XML o SQLite.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .scripture,
            title: "Sistema maestro de alias y parser inteligente de referencias",
            detail: "Implementar CanonicalID de 66 libros, alias por idioma, normalización sin tildes, regex para referencias directas y sugerencias por búsqueda difusa.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .scripture,
            title: "Favoritos de predicación y proyección comparativa",
            detail: "Añadir sermon playlist con reordenado, navegación secuencial y render comparativo split-screen entre dos o tres versiones.",
            targetVersion: "V1.4"
        ),
        PendingWorkItem(
            area: .projectionHistory,
            title: "Historial de proyección con sesiones y debounce",
            detail: "Registrar canciones, versículos, imágenes y alertas por SessionID, ignorando proyecciones menores a 5 segundos y guardando snapshots legibles.",
            targetVersion: "V1.3+"
        ),
        PendingWorkItem(
            area: .projectionHistory,
            title: "Analytics, replay y limpieza histórica",
            detail: "Agregar consulta por fecha, Top 10 de canciones más usadas, exportación CSV para licencias y archivado automático de eventos antiguos.",
            targetVersion: "V1.4"
        )
    ]
}
