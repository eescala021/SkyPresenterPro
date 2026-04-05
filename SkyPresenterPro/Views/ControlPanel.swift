import AppKit
import CoreImage.CIFilterBuiltins
import SwiftUI
import WebKit

private enum UserGuideDocument {
    static func ensureManualFile() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("SkyPresenterPro-Manual-\(SkyPresenterVersion.internalRelease).html")
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? html.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        } else {
            try? html.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }
        return fileURL
    }

    private static var html: String {
        """
        <!doctype html>
        <html lang="es">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Manual SkyPresenter Pro \(SkyPresenterVersion.internalRelease)</title>
        <style>
        :root { --bg:#eef2f8; --card:#ffffff; --edge:#dce3ef; --soft:#f5f7ff; --accent:#4357c8; --text:#172130; --muted:#5c6778; }
        * { box-sizing:border-box; }
        body { margin:0; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif; background:linear-gradient(180deg,#f4f7ff,#eaf0fb); color:var(--text); }
        .shell { display:grid; grid-template-columns:260px 1fr; min-height:100vh; }
        .nav { position:sticky; top:0; align-self:start; height:100vh; overflow:auto; padding:24px 18px; background:rgba(255,255,255,.82); border-right:1px solid var(--edge); backdrop-filter:blur(14px); }
        .nav h1 { margin:0 0 6px; font-size:24px; }
        .nav p { margin:0 0 18px; color:var(--muted); font-size:13px; line-height:1.45; }
        .nav a { display:block; padding:10px 12px; margin-bottom:8px; border-radius:12px; color:var(--text); text-decoration:none; font-weight:800; background:var(--soft); }
        .nav a:hover { background:#e6ecff; color:var(--accent); }
        .content { padding:28px; display:grid; gap:18px; }
        .hero, .card { background:var(--card); border:1px solid var(--edge); border-radius:20px; box-shadow:0 10px 28px rgba(49,69,122,.06); }
        .hero { padding:24px; }
        .hero h2 { margin:0; font-size:28px; }
        .hero p { margin:10px 0 0; color:var(--muted); line-height:1.6; }
        .card { padding:22px; }
        h2[data-index] { margin:0 0 12px; font-size:22px; }
        h3 { margin:18px 0 10px; font-size:16px; }
        p, li { color:var(--muted); line-height:1.65; }
        ul { margin:0; padding-left:20px; }
        .badge { display:inline-block; padding:6px 10px; border-radius:999px; font-size:11px; font-weight:900; background:#e7edff; color:var(--accent); margin-right:8px; }
        .shortcut { display:grid; grid-template-columns:160px 1fr; gap:12px; padding:10px 0; border-bottom:1px solid var(--edge); }
        .shortcut:last-child { border-bottom:none; }
        .key { font-weight:900; color:var(--accent); }
        .footer { color:var(--muted); font-size:12px; text-align:center; padding-bottom:12px; }
        @media (max-width: 900px) { .shell { grid-template-columns:1fr; } .nav { position:relative; height:auto; border-right:none; border-bottom:1px solid var(--edge); } .shortcut { grid-template-columns:1fr; } }
        </style>
        </head>
        <body>
        <div class="shell">
          <aside class="nav">
            <h1>SkyPresenter Pro</h1>
            <p>Manual de usuario \(SkyPresenterVersion.internalRelease). Índice generado automáticamente por secciones.</p>
            <div id="toc"></div>
          </aside>
          <main class="content">
            <section class="hero">
              <span class="badge">\(SkyPresenterVersion.internalRelease)</span>
              <span class="badge">Meta pública \(SkyPresenterVersion.publicLaunchTarget)</span>
              <h2>Manual general de operación</h2>
              <p>SkyPresenter Pro integra Biblia, Alabanzas, Presentaciones, Temas, Proyector, Remoto, Tira de anuncios y Seguridad/Backup. Este manual resume la operación diaria, los atajos y el flujo recomendado para el operador.</p>
            </section>
            <section class="card">
              <h2 data-index="Primeros pasos">Primeros pasos</h2>
              <p>Al abrir la app, el proyector entra en la pantalla institucional. Desde la barra superior puedes cambiar de módulo, lanzar F8/F9/F10, abrir Ajustes y consultar este manual.</p>
              <ul>
                <li><strong>Biblia:</strong> búsqueda rápida, favoritos y proyección por versículo.</li>
                <li><strong>Alabanzas:</strong> biblioteca, módulo de letra, en directo y playlist de servicio.</li>
                <li><strong>Presentaciones:</strong> PDF/PowerPoint con OCR bíblico y tira de páginas.</li>
                <li><strong>Temas:</strong> fondos, gradientes, imágenes y videos.</li>
                <li><strong>Proyector:</strong> monitor pasivo de la salida final.</li>
              </ul>
            </section>
            <section class="card">
              <h2 data-index="Atajos globales">Atajos globales</h2>
              <div class="shortcut"><div class="key">F8</div><div>Muestra logo, identidad visual y fondo institucional.</div></div>
              <div class="shortcut"><div class="key">F9</div><div>Oculta la letra y deja el fondo activo.</div></div>
              <div class="shortcut"><div class="key">F10</div><div>Muestra pantalla negra con nombre de la iglesia y hora.</div></div>
              <div class="shortcut"><div class="key">ESC</div><div>Finaliza la proyección y vuelve a la pantalla inicial.</div></div>
              <div class="shortcut"><div class="key">← / →</div><div>Navega entre versículos o diapositivas proyectadas.</div></div>
              <div class="shortcut"><div class="key">⌥⌘B / A / M / T / P</div><div>Abre Biblia, Alabanzas, Presentaciones, Temas o Proyector.</div></div>
              <div class="shortcut"><div class="key">⌘F2</div><div>Abre el editor de alabanzas.</div></div>
              <div class="shortcut"><div class="key">⌘?</div><div>Abre este manual de ayuda.</div></div>
            </section>
            <section class="card">
              <h2 data-index="Módulo Biblia">Módulo Biblia</h2>
              <p>El flujo principal es Libro → Capítulo → Versículo. El motor admite detección de referencias, favoritos y comparación futura entre versiones auxiliares.</p>
            </section>
            <section class="card">
              <h2 data-index="Módulo Alabanzas">Módulo Alabanzas</h2>
              <p>La biblioteca filtra por título y contenido. El editor segmenta diapositivas en tiempo real mediante doble Enter y ahora permite fondos por diapositiva. La columna Servicio funciona como playlist reordenable.</p>
            </section>
            <section class="card">
              <h2 data-index="Módulo Presentaciones">Módulo Presentaciones</h2>
              <p>Admite PDF y otros recursos. El OCR analiza texto para detectar versículos y proyectarlos rápidamente sin abandonar la presentación.</p>
            </section>
            <section class="card">
              <h2 data-index="Remoto web">Remoto web</h2>
              <p>La app remota permite Biblia, Presentaciones, Presentador y En Directo. Las credenciales se regeneran al abrir la app para reforzar seguridad operativa.</p>
            </section>
            <section class="card">
              <h2 data-index="Seguridad y Backup">Seguridad y Backup</h2>
              <p>Los respaldos automáticos se crean al cerrar la app. También puedes seleccionar manualmente la carpeta de respaldo y el paquete a restaurar desde Ajustes.</p>
            </section>
            <div class="footer">HECHA POR EJ1996 · SkyPresenter Pro \(SkyPresenterVersion.internalRelease)</div>
          </main>
        </div>
        <script>
        const toc = document.getElementById('toc');
        document.querySelectorAll('h2[data-index]').forEach((heading, index) => {
          const id = 'sec-' + index;
          heading.id = id;
          const link = document.createElement('a');
          link.href = '#' + id;
          link.textContent = heading.dataset.index;
          toc.appendChild(link);
        });
        </script>
        </body>
        </html>
        """
    }
}

private struct HTMLManualView: NSViewRepresentable {
    let fileURL: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != fileURL {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
    }
}

private struct ClosableInfoWindow<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                    Text("Consulta rápida de referencia y operación.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Cerrar") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            content
        }
        .frame(width: 820, height: 680)
        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
    }
}

private enum ControlModule: String, CaseIterable, Identifiable {
    case bible = "Biblia"
    case songs = "Alabanzas"
    case media = "Presentaciones"
    case themes = "Temas"
    case projector = "Proyector"

    var id: String { rawValue }

    var title: String { rawValue.uppercased() }

    var icon: String {
        switch self {
        case .bible: return "book.closed"
        case .songs: return "music.note.list"
        case .media: return "rectangle.stack"
        case .themes: return "photo.stack"
        case .projector: return "play.rectangle.on.rectangle"
        }
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case bible = "Biblia"
    case songs = "Alabanzas"
    case presentations = "Presentaciones"
    case projection = "Proyección"
    case remote = "Remoto"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .bible: return "text.book.closed"
        case .songs: return "music.note.house"
        case .presentations: return "rectangle.stack"
        case .projection: return "play.rectangle.on.rectangle"
        case .remote: return "iphone.gen3.radiowaves.left.and.right"
        }
    }

    var summary: String {
        switch self {
        case .general: return "Identidad del panel y acciones rápidas"
        case .bible: return "Comportamiento del texto bíblico proyectado"
        case .songs: return "Flujo operativo y composición del módulo de alabanzas"
        case .presentations: return "OCR, detección bíblica y comportamiento del módulo de presentaciones"
        case .projection: return "Tamaño, contraste y composición visual"
        case .remote: return "Control web seguro para smartphone en la red local"
        }
    }
}

private enum ThemeGalleryFilter: String, CaseIterable, Identifiable {
    case all = "Todo"
    case gradients = "Gradientes"
    case imported = "Importado"

    var id: String { rawValue }
}

struct ControlPanel: View {
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var bibleManager: BibleManager
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var pdfManager: PDFManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var externalDisplayManager: ExternalDisplayManager
    @EnvironmentObject var remoteControlManager: RemoteControlManager
    @EnvironmentObject var announcementManager: AnnouncementManager
    @EnvironmentObject var backupManager: BackupManager

    @State private var selectedModule: ControlModule = .bible
    @State private var showingSettings: Bool = false
    @State private var churchNameDraft: String = ""
    @State private var keyMonitor: Any?
    @State private var selectedSettingsSection: SettingsSection = .general
    @State private var themeGalleryFilter: ThemeGalleryFilter = .all
    @State private var showingRemoteQRCode: Bool = false
    @State private var showingRemoteDevices: Bool = false
    @State private var showingHelp: Bool = false
    @State private var announcementDraft: String = ""
    @State private var announcementType: AnnouncementType = .scrolling
    @State private var announcementPriority: AnnouncementPriority = .normal
    @State private var announcementDuration: Double = 20
    @State private var manualBackupStatusMessage: String = ""
    @State private var backupImportConflictPolicy: SongImportConflictPolicy = .skip
    @State private var backupImportStatusMessage: String = ""
    @StateObject private var bibleViewState = BibleViewState()

    private var hasProjectedContent: Bool {
        displayManager.isProjectorActive
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()

            Group {
                switch selectedModule {
                case .bible:
                    BibleView(viewState: bibleViewState)
                        .environmentObject(displayManager)
                        .environmentObject(bibleManager)
                case .songs:
                    SongView()
                        .environmentObject(displayManager)
                        .environmentObject(songManager)
                        .environmentObject(themeManager)
                case .media:
                    MediaView()
                        .environmentObject(displayManager)
                        .environmentObject(pdfManager)
                        .environmentObject(bibleManager)
                case .themes:
                    themesModuleView
                case .projector:
                    projectorPreview
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.22), value: selectedModule)
        }
        .frame(minWidth: 1100, minHeight: 680)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.92, blue: 0.95),
                    Color(red: 0.82, green: 0.85, blue: 0.89)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showingHelp) {
            helpSheet
        }
        .onAppear {
            bibleViewState.configure(bibleManager: bibleManager, displayManager: displayManager)
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: .remoteNavigateNext)) { _ in
            handleProjectionNavigation(step: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .remoteNavigatePrevious)) { _ in
            handleProjectionNavigation(step: -1)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("SkyPresenter Pro")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 0.16, green: 0.20, blue: 0.26))
                        Text("Control")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(Color(red: 0.28, green: 0.40, blue: 0.62))
                        Text(SkyPresenterVersion.internalRelease)
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.28, green: 0.40, blue: 0.62))
                            .clipShape(Capsule())
                    }
                    Text(moduleStatusLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 8) {
                ForEach(ControlModule.allCases) { module in
                    Button(action: { selectedModule = module }) {
                        moduleTab(module: module, isActive: selectedModule == module)
                    }
                    .buttonStyle(.plain)
                    .help(tooltipForModule(module))
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                quickActionButton("F8 Logo", isActive: displayManager.projectionMode == .logo) {
                    displayManager.showLogo()
                }
                quickActionButton("F9 Fondo", isActive: displayManager.projectionMode == .blankTheme) {
                    displayManager.showBlankTheme()
                }
                quickActionButton("F10 Negro", isActive: displayManager.projectionMode == .blackout) {
                    displayManager.showBlackout()
                }
            }

            Button(action: {
                churchNameDraft = displayManager.churchName
                selectedSettingsSection = .general
                showingSettings = true
            }) {
                Label("Ajustes", systemImage: "gearshape.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.23, green: 0.28, blue: 0.35))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("?", modifiers: [.command])

            Button(action: {
                showingHelp = true
            }) {
                Label("Ayuda", systemImage: "questionmark.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.23, green: 0.28, blue: 0.35))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            topBarStatusPill
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color(red: 0.88, green: 0.90, blue: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var helpSheet: some View {
        ClosableInfoWindow(title: "Centro de ayuda") {
            HTMLManualView(fileURL: UserGuideDocument.ensureManualFile())
        }
    }

    private func shortcutsCard(items: [(String, String)]) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .center, spacing: 16) {
                    Text(item.0)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.20, green: 0.34, blue: 0.74))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.91, green: 0.94, blue: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .frame(width: 140, alignment: .leading)
                    Text(item.1)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func moduleTab(module: ControlModule, isActive: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: module.icon)
                .font(.system(size: 10, weight: .bold))
            Text(module.title)
                .font(.system(size: 10.5, weight: .bold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(isActive ? .white : Color(red: 0.24, green: 0.28, blue: 0.35))
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [Color(red: 0.20, green: 0.56, blue: 0.91), Color(red: 0.10, green: 0.39, blue: 0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color(red: 0.85, green: 0.88, blue: 0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? Color.white.opacity(0.20) : Color.black.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func quickActionButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    isActive
                    ? LinearGradient(
                        colors: [Color(red: 0.12, green: 0.72, blue: 0.36), Color(red: 0.08, green: 0.56, blue: 0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [Color(red: 0.27, green: 0.46, blue: 0.68), Color(red: 0.20, green: 0.36, blue: 0.56)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    isActive
                    ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.green.opacity(0.6), lineWidth: 2)
                    : nil
                )
        }
        .buttonStyle(.plain)
    }

    private var topBarStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(hasProjectedContent ? Color(red: 0.13, green: 0.56, blue: 0.28) : Color(red: 0.18, green: 0.47, blue: 0.88))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(externalDisplayManager.isExternalDisplayConnected ? "Pantalla externa lista" : "Sin pantalla externa")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.23, green: 0.27, blue: 0.34))
                if let name = externalDisplayManager.externalScreenName {
                    Text(name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text(hasProjectedContent ? "Salida activa" : "Esperando proyección")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            externalDisplayManager.isExternalDisplayConnected
            ? Color(red: 0.88, green: 0.96, blue: 0.90)
            : Color.white.opacity(0.76)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var moduleStatusLabel: String {
        switch selectedModule {
        case .bible:
            return "Consulta, selecciona y proyecta versículos"
        case .songs:
            return "Opera canciones por diapositivas y flujo en vivo"
        case .media:
            return "Opera PDF y PowerPoint como presentaciones en vivo"
        case .themes:
            return "Gestiona fondos, logos, imágenes y videos"
        case .projector:
            return "Monitor general del estado de salida"
        }
    }

    private var settingsSheet: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Centro de Configuración")
                            .font(.system(size: 24, weight: .bold))
                        Text(selectedSettingsSection.summary)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Cerrar") {
                        showingSettings = false
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 8) {
                    ForEach(SettingsSection.allCases) { section in
                        Button(action: { selectedSettingsSection = section }) {
                            settingsTab(section: section, isActive: selectedSettingsSection == section)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.96), Color(red: 0.90, green: 0.93, blue: 0.97)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider()

            HStack(alignment: .top, spacing: 18) {
                ScrollView {
                    currentSettingsContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(20)
                }
                .background(Color.white.opacity(0.36))

                settingsInspectorSidebar
                    .frame(width: 230)
                    .padding(.vertical, 20)
                    .padding(.trailing, 20)
            }
        }
        .frame(width: 1140, height: 760)
        .background(Color(red: 0.94, green: 0.95, blue: 0.98))
    }

    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Identidad visual")
                                .font(.system(size: 20, weight: .bold))
                            Text("Define el nombre institucional y los logos usados por la salida principal.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if let activeLogo = displayManager.logoLibrary.first(where: { $0.id == displayManager.activeLogoID }),
                           let image = displayManager.logoThumbnail(for: activeLogo) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 76, height: 76)
                                .padding(8)
                                .background(Color.white.opacity(0.92))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre de la iglesia")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("Nombre de la iglesia", text: $churchNameDraft)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 8) {
                        Button("Guardar nombre") {
                            displayManager.updateChurchName(churchNameDraft)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Importar logo") {
                            displayManager.importLogo()
                        }
                        .buttonStyle(.bordered)

                        Button("Eliminar logo") {
                            displayManager.removeLogo()
                        }
                        .buttonStyle(.bordered)

                        Spacer(minLength: 0)
                    }
                    .controlSize(.small)

                    if !displayManager.logoLibrary.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(displayManager.logoLibrary) { logo in
                                    Button(action: { displayManager.activeLogoID = logo.id }) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            if let image = displayManager.logoThumbnail(for: logo) {
                                                Image(nsImage: image)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 102, height: 58)
                                            } else {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(Color.white.opacity(0.8))
                                                    .frame(width: 102, height: 58)
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.secondary)
                                                    )
                                            }
                                            Text(logo.title)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.90))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(displayManager.activeLogoID == logo.id ? Color.blue : Color.black.opacity(0.06), lineWidth: displayManager.activeLogoID == logo.id ? 2 : 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Atajos rápidos")
                        .font(.system(size: 18, weight: .bold))

                    infoPanel(
                        title: "Acciones principales",
                        lines: [
                            "F8 muestra el logo.",
                            "F9 deja solo el fondo del tema.",
                            "F10 pone pantalla negra con nombre y hora.",
                            "Opcion+Comando+N lanza un anuncio urgente."
                        ]
                    )
                }
                .padding(18)
                .frame(width: 236, alignment: .topLeading)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seguridad y Backup")
                            .font(.system(size: 20, weight: .bold))
                        Text("Respaldos preventivos y exportación manual de la base local actual.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(SkyPresenterVersion.internalRelease)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.22, green: 0.49, blue: 0.84))
                        .clipShape(Capsule())
                }

                HStack(spacing: 14) {
                    settingsMetricPill(title: "Último respaldo", value: backupManager.latestBackupTimestampLabel)
                    settingsMetricPill(title: "Contenedor", value: ".worshipzip")
                    settingsMetricPill(title: "Meta pública", value: SkyPresenterVersion.publicLaunchTarget)
                }

                VStack(alignment: .leading, spacing: 8) {
                    statusLine(label: "Archivo más reciente", value: backupManager.latestBackupDisplayName)
                    statusLine(label: "Ruta de respaldo", value: backupManager.backupsFolderURL.path)
                    if let restoreURL = backupManager.selectedRestorePackageURL {
                        statusLine(label: "Ruta de restauración", value: restoreURL.path)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 10) {
                    Button("Seleccionar ruta de respaldo") {
                        if let directory = backupManager.selectBackupDestinationDirectory() {
                            manualBackupStatusMessage = "Nueva carpeta de respaldo: \(directory.path)"
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Crear respaldo manual") {
                        if let createdURL = backupManager.createManualBackup() {
                            manualBackupStatusMessage = "Respaldo creado: \(createdURL.lastPathComponent)"
                        } else {
                            manualBackupStatusMessage = backupManager.lastBackupErrorMessage ?? "No se pudo crear el respaldo."
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Abrir carpeta de backups") {
                        backupManager.openBackupsFolder()
                    }
                    .buttonStyle(.bordered)
                }

                if !manualBackupStatusMessage.isEmpty {
                    Text(manualBackupStatusMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.18, green: 0.42, blue: 0.24))
                }

                if let backupError = backupManager.lastBackupErrorMessage, !backupError.isEmpty {
                    Text(backupError)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Importación de respaldo")
                            .font(.system(size: 20, weight: .bold))
                        Text("Analiza el paquete antes de integrar canciones y recursos visuales.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Seleccionar respaldo") {
                        guard let packageURL = backupManager.selectBackupPackage() else { return }
                        do {
                            let summary = try backupManager.scanBackup(at: packageURL)
                            backupImportStatusMessage = "Respaldo detectado: \(summary.songsDetected) canciones, \(summary.imageAssetsDetected) imágenes, \(summary.videoAssetsDetected) videos."
                        } catch {
                            backupImportStatusMessage = "No se pudo analizar el respaldo seleccionado."
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if let summary = backupManager.lastScanSummary {
                    VStack(alignment: .leading, spacing: 10) {
                        statusLine(label: "Paquete", value: summary.packageURL.lastPathComponent)
                        HStack(spacing: 14) {
                            settingsMetricPill(title: "Canciones", value: "\(summary.songsDetected)")
                            settingsMetricPill(title: "Imágenes", value: "\(summary.imageAssetsDetected)")
                            settingsMetricPill(title: "Videos", value: "\(summary.videoAssetsDetected)")
                        }

                        Picker("Conflictos", selection: $backupImportConflictPolicy) {
                            ForEach(SongImportConflictPolicy.allCases) { policy in
                                Text(policy.rawValue).tag(policy)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button("Importar respaldo") {
                            do {
                                let result = try backupManager.importBackup(
                                    from: summary.packageURL,
                                    policy: backupImportConflictPolicy,
                                    songManager: songManager,
                                    themeManager: themeManager
                                )
                                backupImportStatusMessage = "Importación completada. Nuevas: \(result.songs.importedCount), sobrescritas: \(result.songs.overwrittenCount), omitidas: \(result.songs.skippedCount), duplicadas: \(result.songs.duplicatedCount), assets: \(result.importedAssetsCount)."
                            } catch {
                                backupImportStatusMessage = "La importación falló. Revisa el paquete e inténtalo nuevamente."
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if !backupImportStatusMessage.isEmpty {
                    Text(backupImportStatusMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.29))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                Text("Tira de anuncios")
                    .font(.system(size: 20, weight: .bold))

                Toggle("Habilitar overlay de anuncios", isOn: $announcementManager.settings.isEnabled)
                    .toggleStyle(.switch)

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Escribe un anuncio urgente o recurrente", text: $announcementDraft, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)

                        HStack(spacing: 10) {
                            Picker("Tipo", selection: $announcementType) {
                                ForEach(AnnouncementType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Prioridad", selection: $announcementPriority) {
                                ForEach(AnnouncementPriority.allCases) { priority in
                                    Text(priority.displayName).tag(priority)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        HStack(spacing: 12) {
                            Text("Duración")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Slider(value: $announcementDuration, in: 5...120, step: 1)
                            Text("\(Int(announcementDuration)) s")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 46, alignment: .trailing)
                        }

                        HStack(spacing: 10) {
                            Button("Lanzar ahora") {
                                announcementManager.triggerQuickAnnouncement(
                                    content: announcementDraft,
                                    priority: announcementPriority,
                                    type: announcementType,
                                    duration: announcementDuration
                                )
                                announcementDraft = ""
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Guardar recurrente") {
                                announcementManager.saveRecurringAnnouncement(
                                    content: announcementDraft,
                                    type: announcementType,
                                    priority: announcementPriority,
                                    duration: announcementDuration,
                                    loops: announcementManager.settings.usesInfiniteLoop ? 0 : 1,
                                    queueNow: false
                                )
                                announcementDraft = ""
                            }

                            Button("Limpiar cola") {
                                announcementManager.clearQueue()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Mostrar en Stage View", isOn: $announcementManager.settings.showsOnStageView)
                            .toggleStyle(.switch)
                        Toggle("Loop infinito", isOn: $announcementManager.settings.usesInfiniteLoop)
                            .toggleStyle(.switch)

                        Picker("Posición", selection: $announcementManager.settings.position) {
                            ForEach(AnnouncementBarPosition.allCases) { position in
                                Text(position.displayName).tag(position)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Velocidad \(Int(announcementManager.settings.speedPointsPerSecond)) px/s")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Slider(value: $announcementManager.settings.speedPointsPerSecond, in: 40...320, step: 5)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Opacidad \(Int(announcementManager.settings.backgroundOpacity * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Slider(value: $announcementManager.settings.backgroundOpacity, in: 0.15...1.0, step: 0.05)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Altura \(Int(announcementManager.settings.barHeightRatio * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Slider(value: $announcementManager.settings.barHeightRatio, in: 0.06...0.18, step: 0.01)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contorno \(String(format: "%.1f", announcementManager.settings.strokeWidth)) px")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Slider(value: $announcementManager.settings.strokeWidth, in: 0...4, step: 0.5)
                        }

                        TextField("Separador", text: $announcementManager.settings.separatorText)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(width: 280)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Anuncios guardados")
                        .font(.system(size: 14, weight: .bold))

                    if announcementManager.storedItems.isEmpty {
                        Text("Todavía no hay anuncios guardados.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(announcementManager.storedItems) { item in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.content)
                                            .font(.system(size: 13, weight: .semibold))
                                            .lineLimit(2)
                                        Text("\(item.type.displayName) · \(item.priority.displayName) · \(Int(item.duration)) s")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if announcementManager.activeAnnouncement?.id == item.id {
                                        Text("AL AIRE")
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundColor(.green)
                                    }
                                    Button("Lanzar") {
                                        announcementManager.enqueue(item.id)
                                    }
                                    Button("Eliminar", role: .destructive) {
                                        announcementManager.deleteAnnouncement(id: item.id)
                                    }
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.82))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }

    private var bibleSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Panel > Biblia")
                .font(.system(size: 20, weight: .bold))

            Toggle(isOn: $displayManager.bibleProjectionSettings.showsVersionInReference) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mostrar versión en el proyector")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Añade la versión de la Biblia en la referencia proyectada.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $displayManager.bibleProjectionSettings.emphasizesSelectedVersion) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resaltar versión seleccionada")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Refuerza visualmente la versión activa en la barra superior de Biblia.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $displayManager.bibleProjectionSettings.showsImportBadge) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mostrar distintivo de importación")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Mantiene visible la etiqueta IMPORTADO cuando la versión fue añadida por el usuario.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            sliderRow(
                title: "Escala del texto bíblico",
                value: $displayManager.bibleProjectionSettings.bodyScaleMultiplier,
                range: 0.80...1.90,
                format: "%.2fx"
            )

            sliderRow(
                title: "Escala de la referencia y versión",
                value: $displayManager.bibleProjectionSettings.referenceScaleMultiplier,
                range: 0.80...1.90,
                format: "%.2fx"
            )

            Text("Recomendado para este módulo:")
                .font(.system(size: 13, weight: .bold))

            infoPanel(
                title: "Sugerencias",
                lines: [
                    "Mostrar versión en la referencia proyectada.",
                    "Permitir referencia corta o completa.",
                    "Controlar mayúsculas automáticas del texto.",
                    "Ajustar tamaño del cuerpo y de la referencia bíblica."
                ]
            )
        }
    }

    private var songSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Panel > Alabanzas")
                .font(.system(size: 20, weight: .bold))

            Toggle("Mostrar historial de diapositivas", isOn: $displayManager.songModuleSettings.showsHistoryPanel)
                .toggleStyle(.switch)
            Toggle("Mostrar biblioteca lateral", isOn: $displayManager.songModuleSettings.showsLibraryPanel)
                .toggleStyle(.switch)
            Toggle("Mostrar tira de diapositivas", isOn: $displayManager.songModuleSettings.showsFilmstrip)
                .toggleStyle(.switch)
            Toggle("Mostrar panel de acciones en vivo", isOn: $displayManager.songModuleSettings.showsLiveActionsPanel)
                .toggleStyle(.switch)
            Toggle("Vista previa actual + siguiente", isOn: $displayManager.songModuleSettings.showsCurrentAndNextPreview)
                .toggleStyle(.switch)

            infoPanel(
                title: "Operación",
                lines: [
                    "Estas opciones reorganizan la consola de alabanzas según el flujo del operador.",
                    "El editor sigue separado y conserva la lógica de Enter = nueva diapositiva."
                ]
            )
        }
    }

    private var presentationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Panel > Presentaciones")
                .font(.system(size: 20, weight: .bold))

            Toggle("Analizar texto para detectar versículos", isOn: $displayManager.presentationModuleSettings.analyzesTextForVerses)
                .toggleStyle(.switch)
            Toggle("Mostrar panel de versículo detectado", isOn: $displayManager.presentationModuleSettings.showsDetectionPanel)
                .toggleStyle(.switch)
            Toggle("Permitir atajo ⌘P para proyectar versículo", isOn: $displayManager.presentationModuleSettings.allowsVerseShortcut)
                .toggleStyle(.switch)
            Toggle("Mostrar tira de páginas", isOn: $displayManager.presentationModuleSettings.showsFilmstrip)
                .toggleStyle(.switch)
            Toggle("Mostrar panel lateral de salida", isOn: $displayManager.presentationModuleSettings.showsInspectorPanel)
                .toggleStyle(.switch)

            infoPanel(
                title: "Detección",
                lines: [
                    "Se intenta leer texto real del PDF antes de usar OCR.",
                    "ESC restaura la diapositiva cuando se proyecta un versículo desde Presentaciones."
                ]
            )
        }
    }

    private var remoteSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Panel > Control Remoto")
                .font(.system(size: 20, weight: .bold))

            Toggle("Habilitar control web para smartphone", isOn: Binding(
                get: { remoteControlManager.settings.isEnabled },
                set: { remoteControlManager.updateEnabled($0) }
            ))
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 8) {
                Text("Dirección IP anunciada")
                    .font(.system(size: 13, weight: .semibold))

                if remoteControlManager.availableLocalHosts.isEmpty {
                    Text("Conecta el Mac a la red local para detectar direcciones IP disponibles.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Picker("Dirección IP anunciada", selection: Binding(
                        get: { remoteControlManager.settings.preferredHost },
                        set: { remoteControlManager.updatePreferredHost($0) }
                    )) {
                        ForEach(remoteControlManager.availableLocalHosts, id: \.self) { host in
                            Text(host).tag(host)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            sliderRow(
                title: "Tiempo de sesión",
                value: $remoteControlManager.settings.sessionTimeoutMinutes,
                range: 5...180,
                format: "%.0f min"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Credenciales de acceso")
                    .font(.system(size: 13, weight: .semibold))
                Text("Usuario: \(remoteControlManager.settings.username)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("PIN: \(remoteControlManager.settings.password)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Token: \(remoteControlManager.settings.authToken)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 10) {
                    Button(remoteControlManager.settings.isEnabled ? "Detener servidor" : "Iniciar servidor") {
                        remoteControlManager.updateEnabled(!remoteControlManager.settings.isEnabled)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Regenerar acceso") {
                        remoteControlManager.regenerateCredentials()
                        remoteControlManager.regenerateToken()
                    }
                    .buttonStyle(.bordered)

                    Button("Copiar acceso") {
                        NSPasteboard.general.clearContents()
                        let value = """
                        URL: \(remoteControlManager.endpointHint)
                        Usuario: \(remoteControlManager.settings.username)
                        PIN: \(remoteControlManager.settings.password)
                        Token: \(remoteControlManager.settings.authToken)
                        """
                        NSPasteboard.general.setString(value, forType: .string)
                    }
                    .buttonStyle(.bordered)

                    Button("Mostrar QR") {
                        showingRemoteQRCode = true
                    }
                    .buttonStyle(.bordered)
                    .popover(isPresented: $showingRemoteQRCode, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                        RemoteAccessQRCodeSheet(remoteControlManager: remoteControlManager)
                    }

                    Button("Dispositivos") {
                        showingRemoteDevices = true
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showingRemoteDevices) {
                        RemoteDevicesManagementSheet(remoteControlManager: remoteControlManager)
                    }

                    Text(remoteControlManager.isRunning ? "Servidor activo" : "Servidor detenido")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(remoteControlManager.isRunning ? Color.green : .secondary)
                }

                HStack(spacing: 10) {
                    Text("Sesiones activas: \(remoteControlManager.activeSessionCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    Button("Cerrar sesiones") {
                        remoteControlManager.revokeAllSessions()
                    }
                    .buttonStyle(.bordered)
                    .disabled(remoteControlManager.activeSessionCount == 0)
                }
            }

            Toggle("Permitir app web en navegador", isOn: $remoteControlManager.settings.allowsBrowserApp)
                .toggleStyle(.switch)

            Toggle("Permitir consulta remota del estado", isOn: $remoteControlManager.settings.exposesStatusToAuthenticatedClients)
                .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 8) {
                Text("URL de acceso")
                    .font(.system(size: 13, weight: .semibold))
                Text(remoteControlManager.endpointHint.isEmpty ? "Activa el servidor para generar la URL base." : remoteControlManager.endpointHint)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Copiar URL base") {
                    let url = remoteControlManager.quickAccessURL.isEmpty ? remoteControlManager.endpointHint : remoteControlManager.quickAccessURL
                    guard !url.isEmpty else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                }
                .buttonStyle(.bordered)

                Button("Solicitar permiso de red local") {
                    remoteControlManager.requestLocalNetworkPermission()
                }
                .buttonStyle(.borderedProminent)
            }

            if let lastError = remoteControlManager.lastError, !lastError.isEmpty {
                Text("Error: \(lastError)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
            }

            Text(remoteControlManager.localNetworkPermissionStatus)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Seguridad: \(remoteControlManager.lastSecurityEvent)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            infoPanel(
                title: "Compatibilidad",
                lines: [
                    "El control remoto usa HTTP local dentro de la misma red.",
                    "La app intenta usar primero la IP anunciada sin puerto visible si logra abrir el puerto 80; si no, cambia automáticamente a un puerto disponible.",
                    "Se recomienda Chrome, Edge y navegadores similares para el acceso móvil.",
                    "Safari en iPhone puede limitar o bloquear algunas funciones al abrir direcciones HTTP locales.",
                    "El QR abre la dirección completa del servidor para facilitar el acceso.",
                    "Si macOS pide permiso de red local, debes concederlo para usar el control móvil."
                ]
            )
        }
    }

    private var projectionSettingsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Panel > Proyección")
                    .font(.system(size: 20, weight: .bold))

                HStack(alignment: .top, spacing: 18) {
                    advancedProjectionEditor
                    projectionPreviewCard
                }
            }
            .padding(.trailing, 8)
        }
    }

    private var advancedProjectionEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Editor avanzado de texto")
                .font(.system(size: 16, weight: .bold))

            Toggle("Tamaño automático", isOn: $displayManager.projectionStyleSettings.usesAutoTextSize)
                .toggleStyle(.switch)

            if !displayManager.projectionStyleSettings.usesAutoTextSize {
                sliderRow(
                    title: "Tamaño manual",
                    value: $displayManager.projectionStyleSettings.manualTextSize,
                    range: 42...130,
                    format: "%.0f pt"
                )
            }

            Toggle("Opacidad automática del texto", isOn: $displayManager.projectionStyleSettings.usesAutoTextOpacity)
                .toggleStyle(.switch)

            if !displayManager.projectionStyleSettings.usesAutoTextOpacity {
                sliderRow(
                    title: "Opacidad del texto",
                    value: $displayManager.projectionStyleSettings.manualTextOpacity,
                    range: 0.4...1,
                    format: "%.2f"
                )
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Color del texto")
                        .font(.system(size: 13, weight: .semibold))
                    ColorPicker("", selection: projectionTextColorBinding, supportsOpacity: false)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sombreado")
                        .font(.system(size: 13, weight: .semibold))
                    sliderRow(
                        title: "Opacidad",
                        value: $displayManager.projectionStyleSettings.shadowOpacity,
                        range: 0...1,
                        format: "%.2f"
                    )
                    sliderRow(
                        title: "Radio",
                        value: $displayManager.projectionStyleSettings.shadowRadius,
                        range: 0...24,
                        format: "%.0f"
                    )
                    sliderRow(
                        title: "Desplazamiento Y",
                        value: $displayManager.projectionStyleSettings.shadowOffsetY,
                        range: 0...18,
                        format: "%.0f"
                    )
                }
            }

            Toggle("Fondo negro para el texto", isOn: $displayManager.projectionStyleSettings.usesBlackTextBackground)
                .toggleStyle(.switch)

            if displayManager.projectionStyleSettings.usesBlackTextBackground {
                Toggle("Opacidad automática del fondo", isOn: $displayManager.projectionStyleSettings.usesAutoBackgroundOpacity)
                    .toggleStyle(.switch)

                if !displayManager.projectionStyleSettings.usesAutoBackgroundOpacity {
                    sliderRow(
                        title: "Opacidad del fondo",
                        value: $displayManager.projectionStyleSettings.manualBackgroundOpacity,
                        range: 0.25...1,
                        format: "%.2f"
                    )
                }
            }

            sliderRow(
                title: "Escala de referencia",
                value: $displayManager.projectionStyleSettings.referenceScale,
                range: 0.28...0.7,
                format: "%.2f"
            )

            sliderRow(
                title: "Opacidad de referencia",
                value: $displayManager.projectionStyleSettings.referenceOpacity,
                range: 0.35...1,
                format: "%.2f"
            )

            sliderRow(
                title: "Espaciado de líneas",
                value: $displayManager.projectionStyleSettings.lineSpacing,
                range: 0...24,
                format: "%.0f"
            )

            sliderRow(
                title: "Ancho del bloque de texto",
                value: $displayManager.projectionStyleSettings.textWidthRatio,
                range: 0.55...0.94,
                format: "%.2f"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Caja segura por módulo")
                    .font(.system(size: 14, weight: .bold))

                sliderRow(
                    title: "Ancho útil Biblia",
                    value: $displayManager.projectionStyleSettings.bibleTextWidthRatio,
                    range: 0.70...0.92,
                    format: "%.2f"
                )

                sliderRow(
                    title: "Ancho útil Alabanzas",
                    value: $displayManager.projectionStyleSettings.songTextWidthRatio,
                    range: 0.74...0.94,
                    format: "%.2f"
                )

                Text("Estos valores solo afectan la proyección real de Biblia y Alabanzas. El programa hará el salto de línea antes de invadir ese margen.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button("Preset Biblia Clásica") {
                        displayManager.applyBibleClassicProjectionPreset()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Preset Alabanza Amplia") {
                        displayManager.applySongWideProjectionPreset()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(14)
            .background(Color(red: 0.95, green: 0.97, blue: 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            sliderRow(
                title: "Tamaño automático mínimo",
                value: $displayManager.projectionStyleSettings.minimumAutoTextSize,
                range: 85...120,
                format: "%.0f pt"
            )

            sliderRow(
                title: "Tamaño automático máximo",
                value: $displayManager.projectionStyleSettings.maximumAutoTextSize,
                range: 84...148,
                format: "%.0f pt"
            )

            sliderRow(
                title: "Padding horizontal del texto",
                value: $displayManager.projectionStyleSettings.textHorizontalPadding,
                range: 0...48,
                format: "%.0f"
            )

            sliderRow(
                title: "Margen superior de referencia",
                value: $displayManager.projectionStyleSettings.referenceTopInset,
                range: 0...80,
                format: "%.0f"
            )

            sliderRow(
                title: "Desplazamiento vertical",
                value: $displayManager.projectionStyleSettings.contentVerticalOffset,
                range: -120...120,
                format: "%.0f"
            )

            sliderRow(
                title: "Redondeado del bloque",
                value: $displayManager.projectionStyleSettings.textBlockCornerRadius,
                range: 0...20,
                format: "%.0f"
            )

            HStack {
                Spacer()
                Button("Restaurar estilo") {
                    displayManager.resetProjectionStyleSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var projectionPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vista previa")
                .font(.system(size: 16, weight: .bold))

            ProjectionContentCanvas(
                payload: ProjectionPayload(
                    source: "bible:preview",
                    reference: "Génesis 3:2 (REINA VALERA 1909)",
                    body: "Y la mujer respondió a la serpiente: del fruto de los árboles del huerto podemos comer;"
                ),
                settings: displayManager.projectionStyleSettings,
                size: CGSize(width: 360, height: 260),
                isExternalDisplay: false,
                forcesCompactPreviewLayout: true
            )
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.16), lineWidth: 1)
            )

            Text("La vista previa usa el mismo render del proyector. El texto bíblico siempre se proyecta en mayúsculas.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 320, alignment: .topLeading)
    }

    private var themesSettingsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Tema activo")
                        .font(.system(size: 14, weight: .bold))

                    themePreview
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )

                    HStack(spacing: 8) {
                        Circle()
                            .fill(themeIndicatorColor)
                            .frame(width: 9, height: 9)
                        Text(themeIndicatorLabel)
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Text(activeThemeModeLabel)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(themeIndicatorColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(themeIndicatorColor.opacity(0.10))
                            .clipShape(Capsule())
                    }

                    Text("Selecciona un recurso y actívalo en el proyector sin cambiar de consola.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    themeStatCard(
                        title: "Modo activo",
                        value: activeThemeModeLabel,
                        caption: "Recurso que está respondiendo en el proyector",
                        color: themeIndicatorColor
                    )

                    themeStatCard(
                        title: "Biblioteca",
                        value: "\(GradientPreset.allCases.count + themeManager.imageLibrary.count + themeManager.videoLibrary.count + displayManager.logoLibrary.count)",
                        caption: "Gradientes, imágenes, videos y logos cargados",
                        color: Color(red: 0.22, green: 0.49, blue: 0.84)
                    )

                    HStack(spacing: 10) {
                        compactThemeCountCard(
                            title: "Imágenes",
                            count: themeManager.imageLibrary.count,
                            color: Color(red: 0.16, green: 0.70, blue: 0.36)
                        )
                        compactThemeCountCard(
                            title: "Videos",
                            count: themeManager.videoLibrary.count,
                            color: Color(red: 0.82, green: 0.36, blue: 0.12)
                        )
                        compactThemeCountCard(
                            title: "Logos",
                            count: displayManager.logoLibrary.count,
                            color: Color(red: 0.48, green: 0.38, blue: 0.86)
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Acciones rápidas")
                            .font(.system(size: 12, weight: .bold))
                        HStack(spacing: 8) {
                            themeActionPill("Gradiente", systemImage: "sparkles") {
                                themeManager.selectGradient(themeManager.themeSettings.gradientPreset)
                            }
                            themeActionPill("Imagen", systemImage: "photo") {
                                themeManager.selectImageBackground()
                            }
                            .disabled(!themeManager.hasImportedImage)
                        }
                        HStack(spacing: 8) {
                            themeActionPill("Video", systemImage: "play.rectangle") {
                                themeManager.selectVideoBackground()
                            }
                            .disabled(!themeManager.hasImportedVideo)
                            themeActionPill("Logo", systemImage: "photo.on.rectangle") {
                                displayManager.showLogo()
                            }
                            .disabled(displayManager.activeLogoID == nil && displayManager.logoLibrary.isEmpty)
                        }
                        HStack(spacing: 8) {
                            Button("Restablecer") {
                                themeManager.resetToDefault()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(width: 290, alignment: .topLeading)
            }

            HStack(spacing: 8) {
                ForEach(ThemeGalleryFilter.allCases) { filter in
                    Button(action: { themeGalleryFilter = filter }) {
                        Text(filter.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeGalleryFilter == filter ? .white : Color(red: 0.24, green: 0.28, blue: 0.35))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                themeGalleryFilter == filter
                                ? Color(red: 0.22, green: 0.49, blue: 0.84)
                                : Color.white.opacity(0.82)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if themeGalleryFilter == .all || themeGalleryFilter == .gradients {
                VStack(alignment: .leading, spacing: 12) {
                    themeSectionHeader(
                        title: "Gradientes",
                        subtitle: "\(GradientPreset.allCases.count) estilos rápidos para usar sin archivos"
                    )

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(GradientPreset.allCases) { preset in
                            Button(action: { themeManager.selectGradient(preset) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(preset.gradient)
                                        .frame(height: 92)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    themeManager.themeSettings.kind == .gradient && themeManager.themeSettings.gradientPreset == preset
                                                    ? Color.blue : Color.black.opacity(0.06),
                                                    lineWidth: themeManager.themeSettings.kind == .gradient && themeManager.themeSettings.gradientPreset == preset ? 2 : 1
                                                )
                                        )
                                    Text(preset.displayName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.90))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if themeGalleryFilter == .all || themeGalleryFilter == .imported {
                VStack(alignment: .leading, spacing: 14) {
                    themeSectionHeader(
                        title: "Imágenes de fondo",
                        subtitle: themeManager.imageLibrary.isEmpty ? "Importa fondos estáticos para cultos, anuncios o momentos especiales" : "\(themeManager.imageLibrary.count) imágenes disponibles"
                    )

                    HStack {
                        libraryCounter(title: "Imágenes", count: themeManager.imageLibrary.count, color: Color(red: 0.16, green: 0.70, blue: 0.36))
                        Spacer()
                        Button("Importar imagen") { themeManager.importBackgroundImage() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        if themeManager.hasImportedImage {
                            Button("Eliminar activa") { themeManager.removeBackgroundImage() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }

                    if themeManager.imageLibrary.isEmpty {
                        infoPanel(title: "Sin imágenes", lines: ["Importa una imagen fija y selecciónala para activarla en el proyector."])
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(themeManager.imageLibrary) { asset in
                                Button(action: { themeManager.selectImageBackground(asset.id) }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let img = themeManager.imageThumbnail(for: asset) {
                                            Image(nsImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 112)
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(red: 0.95, green: 0.96, blue: 0.99))
                                                .frame(height: 112)
                                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                                        }
                                        Text(asset.title)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.90))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                themeManager.activeImageID == asset.id && themeManager.themeSettings.kind == .image ? Color.blue : Color.black.opacity(0.06),
                                                lineWidth: themeManager.activeImageID == asset.id && themeManager.themeSettings.kind == .image ? 2 : 1
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    themeSectionHeader(
                        title: "Videos en loop",
                        subtitle: themeManager.videoLibrary.isEmpty ? "Importa videos para fondos vivos y continuos" : "\(themeManager.videoLibrary.count) videos disponibles"
                    )

                    HStack {
                        libraryCounter(title: "Videos", count: themeManager.videoLibrary.count, color: Color(red: 0.82, green: 0.36, blue: 0.12))
                        Spacer()
                        Button("Importar video") { themeManager.importBackgroundVideo() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        if themeManager.hasImportedVideo {
                            Button("Eliminar activo") { themeManager.removeBackgroundVideo() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }

                    if themeManager.videoLibrary.isEmpty {
                        infoPanel(title: "Sin videos", lines: ["Importa loops suaves para dar movimiento al fondo del proyector."])
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(themeManager.videoLibrary) { asset in
                                Button(action: { themeManager.selectVideoBackground(asset.id) }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ZStack {
                                            if let thumb = themeManager.videoThumbnail(for: asset) {
                                                Image(nsImage: thumb)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(height: 112)
                                                    .frame(maxWidth: .infinity)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            } else {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color(red: 0.95, green: 0.96, blue: 0.99))
                                                    .frame(height: 112)
                                            }

                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.white.opacity(0.92))
                                        }
                                        Text(asset.title)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.90))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                themeManager.activeVideoID == asset.id && themeManager.themeSettings.kind == .video ? Color.blue : Color.black.opacity(0.06),
                                                lineWidth: themeManager.activeVideoID == asset.id && themeManager.themeSettings.kind == .video ? 2 : 1
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: themeGalleryFilter)
    }

    private var themeIndicatorColor: Color {
        switch themeManager.themeSettings.kind {
        case .gradient: return Color(red: 0.19, green: 0.55, blue: 0.91)
        case .image: return Color(red: 0.16, green: 0.70, blue: 0.36)
        case .video: return Color(red: 0.82, green: 0.36, blue: 0.12)
        }
    }

    private var themeIndicatorLabel: String {
        switch themeManager.themeSettings.kind {
        case .gradient: return "Gradiente: \(themeManager.themeSettings.gradientPreset.displayName)"
        case .image: return "Imagen personalizada"
        case .video: return "Video en bucle"
        }
    }

    private var projectionTextColorBinding: Binding<Color> {
        Binding(
            get: {
                displayManager.projectionStyleSettings.textColor.swiftUIColor
            },
            set: { newValue in
                let nsColor = NSColor(newValue)
                displayManager.projectionStyleSettings.textColor = ProjectionColorSetting(color: nsColor)
            }
        )
    }

    private func settingsTab(section: SettingsSection, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: section.icon)
                .font(.system(size: 12, weight: .bold))
            Text(section.rawValue)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(isActive ? .white : Color(red: 0.24, green: 0.28, blue: 0.35))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isActive
            ? LinearGradient(
                colors: [Color(red: 0.22, green: 0.49, blue: 0.84), Color(red: 0.13, green: 0.36, blue: 0.69)],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [Color.white.opacity(0.9), Color(red: 0.87, green: 0.90, blue: 0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var currentSettingsContent: some View {
        switch selectedSettingsSection {
        case .general:
            settingsContentCard(title: "General", subtitle: "Control principal, identidad y acciones rápidas") {
                generalSettingsSection
            }
        case .bible:
            settingsContentCard(title: "Biblia", subtitle: "Opciones relacionadas con referencias y estilo bíblico") {
                bibleSettingsSection
            }
        case .songs:
            settingsContentCard(title: "Alabanzas", subtitle: "Controles operativos y visibilidad del módulo de canciones") {
                songSettingsSection
            }
        case .presentations:
            settingsContentCard(title: "Presentaciones", subtitle: "Lectura OCR, versículos detectados y control de páginas") {
                presentationSettingsSection
            }
        case .projection:
            settingsContentCard(title: "Proyección", subtitle: "Ajustes visuales avanzados del texto proyectado") {
                projectionSettingsSection
            }
        case .remote:
            settingsContentCard(title: "Remoto", subtitle: "Servidor local y app web segura para smartphone") {
                remoteSettingsSection
            }
        }
    }

    private func settingsContentCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            content()
        }
        .padding(22)
        .background(Color.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var settingsInspectorSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSidebarCard(title: "Panel") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(displayManager.churchName)
                        .font(.system(size: 18, weight: .bold))
                    Text(hasProjectedContent ? "Hay una salida activa en este momento." : "No hay contenido proyectándose ahora.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            settingsSidebarCard(title: "Tema Activo") {
                VStack(alignment: .leading, spacing: 10) {
                    themePreview
                        .frame(height: 122)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text(themeIndicatorLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            settingsSidebarCard(title: "Salida") {
                VStack(alignment: .leading, spacing: 10) {
                    statusLine(label: "Pantalla externa", value: externalDisplayManager.isExternalDisplayConnected ? "Conectada" : "No detectada")
                    statusLine(label: "Modo", value: projectionModeLabel)
                    statusLine(label: "Sección", value: selectedSettingsSection.rawValue)
                }
            }

            Spacer()
        }
    }

    private func settingsSidebarCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statusLine(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
        }
    }

    private func settingsMetricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.29))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.94, green: 0.96, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Slider(value: value, in: range)
        }
    }

    private func infoPanel(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)

            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color(red: 0.22, green: 0.49, blue: 0.84))
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)
                    Text(line)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.28, green: 0.32, blue: 0.39))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.94, green: 0.96, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func themeSectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func themeStatCard(title: String, value: String, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 9, height: 9)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.29))

            Text(caption)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func themeActionPill(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.90))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func libraryCounter(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.29))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.94, green: 0.96, blue: 0.99))
        .clipShape(Capsule())
    }

    private func compactThemeCountCard(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.secondary)
            }
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.29))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var themePreview: some View {
        switch themeManager.themeSettings.kind {
        case .gradient:
            themeManager.themeSettings.gradientPreset.gradient
        case .image:
            if let image = themeManager.backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                GradientPreset.midnight.gradient
            }
        case .video:
            if let thumb = themeManager.videoThumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                GradientPreset.midnight.gradient
            }
        }
    }

    private var projectionModeLabel: String {
        switch displayManager.projectionMode {
        case .content: return "Contenido"
        case .media: return "Multimedia"
        case .logo: return "Logo"
        case .blankTheme: return "Fondo"
        case .blackout: return "Negro"
        }
    }

    private var activeThemeModeLabel: String {
        switch themeManager.themeSettings.kind {
        case .gradient:
            return "GRADIENTE"
        case .image:
            return "IMAGEN"
        case .video:
            return "VIDEO"
        }
    }

    private func tooltipForModule(_ module: ControlModule) -> String {
        switch module {
        case .bible:     return "⌥⌘B"
        case .songs:     return "⌥⌘A"
        case .media:     return "⌥⌘M"
        case .themes:    return "⌥⌘T"
        case .projector: return "⌥⌘P"
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if handleKeyEvent(event) {
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // ⌥⌘ shortcuts para cambio de módulo
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if (flags == [.command, .shift] || flags == [.command]),
           let chars = event.charactersIgnoringModifiers,
           chars == "/" || chars == "?" {
            showingHelp = true
            return true
        }

        if flags == [.command], event.keyCode == 120 {
            selectedModule = .songs
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .openSongEditor, object: nil)
            }
            return true
        }

        if flags == [.option, .command],
           let chars = event.charactersIgnoringModifiers?.lowercased() {
            switch chars {
            case "p":
                selectedModule = .projector
                return true
            case "b":
                selectedModule = .bible
                return true
            case "a":
                selectedModule = .songs
                return true
            case "m":
                selectedModule = .media
                return true
            case "t":
                selectedModule = .themes
                return true
            case "n":
                announcementManager.triggerQuickAnnouncement(
                    content: announcementDraft,
                    priority: .breaking,
                    type: .scrolling,
                    duration: max(announcementDuration, 8)
                )
                return true
            default:
                break
            }
        }

        if isTextInputActive {
            return false
        }

        switch event.keyCode {
        case 53:
            if !displayManager.restorePresentationProjectionIfNeeded() {
                displayManager.endProjection()
            }
            return true
        case 123:
            handleProjectionNavigation(step: -1)
            return true
        case 124:
            handleProjectionNavigation(step: 1)
            return true
        case 100:
            displayManager.showLogo()
            return true
        case 101:
            displayManager.showBlankTheme()
            return true
        case 109:
            displayManager.showBlackout()
            return true
        default:
            return false
        }
    }

    private var isTextInputActive: Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        if responder is NSTextView || responder is NSTextField {
            return true
        }
        return false
    }

    private func handleProjectionNavigation(step: Int) {
        if displayManager.currentProjection?.source.hasPrefix("bible:") == true {
            bibleViewState.handleProjectionAdvance(step: step)
            return
        }

        if navigateProjectedSong(step: step) {
            return
        }

        if navigateProjectedPresentation(step: step) {
            return
        }

        NotificationCenter.default.post(
            name: step < 0 ? .projectorPrevious : .projectorNext,
            object: nil
        )
    }

    private func navigateProjectedSong(step: Int) -> Bool {
        guard let source = displayManager.currentProjection?.source,
              source.hasPrefix("song:"),
              let song = songManager.songs.first(where: { song in
                  song.presentationSlides.contains(where: { $0.source == source })
              }),
              let index = song.presentationSlides.firstIndex(where: { $0.source == source }) else {
            return false
        }

        let targetIndex = min(max(index + step, 0), song.presentationSlides.count - 1)
        let slide = song.presentationSlides[targetIndex]
        displayManager.project(source: slide.source, reference: slide.reference, body: slide.body)
        return true
    }

    private func navigateProjectedPresentation(step: Int) -> Bool {
        guard displayManager.projectionMode == .media,
              let source = displayManager.currentMediaProjection?.source else {
            return false
        }

        let components = source.components(separatedBy: ":")
        guard components.count == 3,
              components[0] == "media",
              let uuid = UUID(uuidString: components[1]),
              let currentPage = Int(components[2]),
              let item = pdfManager.items.first(where: { $0.id == uuid }) else {
            return false
        }

        if item.kind == .pdf {
            let pageCount = max(pdfManager.pageCount(for: item), 1)
            let targetPage = min(max(currentPage + step, 0), pageCount - 1)
            guard let image = pdfManager.image(for: item, pageIndex: targetPage) else { return false }
            displayManager.projectMedia(
                source: "media:\(item.id.uuidString):\(targetPage)",
                title: item.title,
                subtitle: "Página \(targetPage + 1)",
                image: image
            )
            return true
        }

        guard let itemIndex = pdfManager.items.firstIndex(where: { $0.id == item.id }) else { return false }
        let targetIndex = min(max(itemIndex + step, 0), pdfManager.items.count - 1)
        let targetItem = pdfManager.items[targetIndex]
        guard let image = pdfManager.image(for: targetItem, pageIndex: 0) else { return false }
        displayManager.projectMedia(
            source: "media:\(targetItem.id.uuidString):0",
            title: targetItem.title,
            subtitle: targetItem.kind == .pdf ? "Página 1" : targetItem.kind.rawValue,
            image: image
        )
        return true
    }

    private var projectorPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Monitor del proyector")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.16, green: 0.20, blue: 0.27))
                    Text("Monitor pasivo de la salida actual. La operación se hace desde los módulos.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Projector(isExternalDisplay: true)
                .environmentObject(displayManager)
                .environmentObject(themeManager)
                .environmentObject(announcementManager)
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )
        }
        .padding(14)
    }

    private var themesModuleView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: ControlModule.themes.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.76))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ControlModule.themes.title)
                            .font(.system(size: 22, weight: .heavy))
                        Text("GALERÍA DE TEMAS, FONDOS, LOGOS E IDENTIDAD VISUAL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }

                settingsContentCard(title: "Escena visual", subtitle: "Fondos, gradientes, imágenes y videos listos para usar en el proyector") {
                    themesSettingsSection
                }

                settingsContentCard(title: "Logos", subtitle: "Biblioteca persistente de logos para F8 y recursos institucionales") {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Logos disponibles")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Importa varios logos, revisa su miniatura y activa el que quieras usar en F8.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Importar logos") {
                                displayManager.importLogo()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if displayManager.logoLibrary.isEmpty {
                            infoPanel(
                                title: "Sin logos",
                                lines: [
                                    "Importa PNG o JPG en alta resolución.",
                                    "El logo activo se conserva al cerrar y abrir la aplicación."
                                ]
                            )
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                                ForEach(displayManager.logoLibrary) { logo in
                                    Button(action: { displayManager.activeLogoID = logo.id }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color(red: 0.95, green: 0.96, blue: 0.99))
                                                if let image = displayManager.logoThumbnail(for: logo) {
                                                    Image(nsImage: image)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .padding(12)
                                                } else {
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 24, weight: .semibold))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .frame(height: 110)
                                            Text(logo.title)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.84))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(displayManager.activeLogoID == logo.id ? Color.blue : Color.black.opacity(0.06), lineWidth: displayManager.activeLogoID == logo.id ? 2 : 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct RemoteDevicePermissionsRow: View {
    @ObservedObject var remoteControlManager: RemoteControlManager
    @Binding var device: RemoteDevicePermission

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                TextField("Nombre del dispositivo", text: $device.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .bold))
                Text(device.id.uuidString.prefix(8) + "...")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(remoteControlManager.sessionCount(for: device.id)) sesiones activas")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 210, alignment: .leading)

            compactToggle($device.isEnabled, width: 78)
            compactToggle($device.allowsStatus, width: 78)
            compactToggle($device.allowsPresenter, width: 88)
            compactToggle($device.allowsBible, width: 78)
            compactToggle($device.allowsLyrics, width: 78)
            compactToggle($device.allowsPresentations, width: 88)

            Text(lastSeenLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .trailing)

            HStack(spacing: 8) {
                Button("Revocar") {
                    remoteControlManager.revokeSessions(for: device.id)
                }
                .buttonStyle(.bordered)

                Button("Eliminar") {
                    remoteControlManager.removeDevice(device.id)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .frame(width: 160, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(device.isEnabled ? Color.black.opacity(0.05) : Color.red.opacity(0.16), lineWidth: 1)
        )
    }

    private var lastSeenLabel: String {
        device.lastSeenAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func compactToggle(_ isOn: Binding<Bool>, width: CGFloat) -> some View {
        Toggle("", isOn: isOn)
            .labelsHidden()
            .toggleStyle(.switch)
            .scaleEffect(0.85)
            .frame(width: width, alignment: .center)
    }
}

private struct RemoteAccessQRCodeSheet: View {
    @ObservedObject var remoteControlManager: RemoteControlManager
    @Environment(\.dismiss) private var dismiss
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ACCESO MÓVIL")
                        .font(.system(size: 24, weight: .bold))
                    Text("Escanea el QR o usa la URL con las credenciales generadas por la app.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Cerrar") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(alignment: .top, spacing: 20) {
                Group {
                    if let image = qrImage {
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.gray.opacity(0.16))
                            .overlay(
                                Text("QR no disponible")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: 260, height: 260)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USAR CHROME EN EL MÓVIL")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(red: 0.18, green: 0.35, blue: 0.76))
                        Text("Recomendado para iPhone y Android. Safari puede limitar o bloquear direcciones HTTP locales.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.91, green: 0.95, blue: 1.0))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    remoteInfoLine(title: "URL LOCAL", value: remoteControlManager.endpointHint.isEmpty ? "Activa el servidor remoto." : remoteControlManager.endpointHint)
                    remoteInfoLine(title: "URL QR", value: remoteControlManager.qrAccessPayload.isEmpty ? "Activa el servidor remoto." : remoteControlManager.qrAccessPayload)
                    remoteInfoLine(title: "USUARIO", value: remoteControlManager.settings.username)
                    remoteInfoLine(title: "PIN", value: remoteControlManager.settings.password)
                    remoteInfoLine(title: "TOKEN", value: remoteControlManager.settings.authToken)
                    remoteInfoLine(title: "ESTADO", value: remoteControlManager.localNetworkPermissionStatus)

                    Text("Recomendado para móviles: Chrome, Edge o navegadores similares. Safari puede limitar el acceso HTTP local.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Button("Copiar acceso completo") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(remoteControlManager.fullAccessSummary, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .padding(24)
        .frame(width: 860, height: 430)
        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
    }

    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.secondary)
            .frame(width: width, alignment: alignment)
    }

    private var qrImage: NSImage? {
        guard !remoteControlManager.endpointHint.isEmpty else { return nil }
        filter.setValue(Data(remoteControlManager.qrAccessPayload.utf8), forKey: "inputMessage")
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: outputImage.extent.width, height: outputImage.extent.height))
    }

    private func remoteInfoLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct RemoteDevicesManagementSheet: View {
    @ObservedObject var remoteControlManager: RemoteControlManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DISPOSITIVOS Y PERMISOS")
                        .font(.system(size: 24, weight: .bold))
                    Text("Administra usuarios móviles, permisos por dispositivo y sesiones activas.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Cerrar") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("DISPOSITIVOS REGISTRADOS")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text("\(remoteControlManager.registeredDevices.count) dispositivos")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 0) {
                    headerCell("Dispositivo", width: 210, alignment: .leading)
                    headerCell("Activo", width: 78, alignment: .center)
                    headerCell("Estado", width: 78, alignment: .center)
                    headerCell("Present.", width: 88, alignment: .center)
                    headerCell("Biblia", width: 78, alignment: .center)
                    headerCell("Letras", width: 78, alignment: .center)
                    headerCell("Presen.", width: 88, alignment: .center)
                    headerCell("Última vez", width: 150, alignment: .trailing)
                    headerCell("Acciones", width: 160, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(red: 0.90, green: 0.93, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if remoteControlManager.registeredDevices.isEmpty {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                        .frame(height: 110)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("Aún no hay dispositivos registrados")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("Cuando un móvil entre por QR o URL aparecerá en esta lista.")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        )
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(remoteControlManager.registeredDevices) { device in
                                RemoteDevicePermissionsRow(
                                    remoteControlManager: remoteControlManager,
                                    device: Binding(
                                        get: { remoteControlManager.registeredDevices.first(where: { $0.id == device.id }) ?? device },
                                        set: { remoteControlManager.updateDevice($0) }
                                    )
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SESIONES ACTIVAS")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text("\(remoteControlManager.sessionSummaries.count) abiertas")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                if remoteControlManager.sessionSummaries.isEmpty {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                        .frame(height: 84)
                        .overlay(
                            Text("No hay sesiones móviles activas.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        )
                } else {
                    VStack(spacing: 8) {
                        ForEach(remoteControlManager.sessionSummaries) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.deviceName)
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Creada: \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text("Expira: \(session.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Cerrar sesión") {
                                    remoteControlManager.revokeSession(session.id)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 1080, height: 820)
        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
    }

    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.secondary)
            .frame(width: width, alignment: alignment)
    }
}
