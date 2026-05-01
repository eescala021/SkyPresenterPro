import AppKit
import SwiftUI

struct SettingsAboutPane: View {
    @EnvironmentObject private var remoteService: RemoteServerService

    static var versionDisplayString: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "v\(shortVersion) (\(buildVersion))"
    }

    private var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.SkyPresenter.SkyPresenterPro"
    }

    private var executableName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? "SkyPresenterPro"
    }

    private var releaseChannel: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    private var helperExecutableURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Library/HelperTools/HTTPPortBridgeHelper")
    }

    private var helperPlistURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchDaemons/com.SkyPresenter.SkyPresenterPro.HTTPBridge.plist")
    }

    private var helperStatus: String {
        let fm = FileManager.default
        let hasExecutable = fm.fileExists(atPath: helperExecutableURL.path)
        let hasPlist = fm.fileExists(atPath: helperPlistURL.path)
        if hasExecutable && hasPlist { return "Listo para distribución" }
        if hasExecutable || hasPlist { return "Parcial" }
        return "No integrado"
    }

    private var distributionSummary: String {
        [
            "SkyPresenterPro \(Self.versionDisplayString)",
            "Canal: \(releaseChannel)",
            "Bundle ID: \(bundleIdentifier)",
            "Ejecutable: \(executableName)",
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Bridge remoto: \(helperStatus)"
        ].joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    paneHeader
                    buildStatusCard
                    distributionCard
                    technicalCard
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                SettingsPreviewSidebar {
                    SettingsMetricCard(
                        title: "Versión actual",
                        value: Self.versionDisplayString,
                        detail: "Versión distribuible activa en esta instalación.",
                        tint: .blue
                    )

                    SettingsMetricCard(
                        title: "Canal",
                        value: releaseChannel,
                        detail: "Modo de compilación activo de la aplicación.",
                        tint: .orange
                    )

                    SettingsMetricCard(
                        title: "Bridge remoto",
                        value: helperStatus,
                        detail: remoteService.serverState.bridgeStatus.title,
                        tint: .green
                    )

                    Spacer()
                }
                .frame(width: 278, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, AppSpacing.lg)
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var paneHeader: some View {
        SettingsSectionIntro(
            eyebrow: "Aplicación",
            title: "Acerca de",
            subtitle: "Versión, build y utilidades para distribuir y auditar la consola instalada"
        )
    }

    private var buildStatusCard: some View {
        SettingsPanelCard(
            title: "Versión activa",
            subtitle: "Lectura inmediata del build instalado"
        ) {
            SettingsStatusStrip(items: [
                ("Versión", shortVersion),
                ("Build", buildVersion),
                ("Canal", releaseChannel),
                ("Remoto", remoteService.serverState.bridgeStatus.title)
            ])
        }
    }

    private var distributionCard: some View {
        SettingsPanelCard(
            title: "Distribución",
            subtitle: "Herramientas útiles para compartir y verificar esta versión"
        ) {
            SettingsActionRow(
                title: "Resumen de versión",
                detail: "Copia un bloque listo para soporte, despliegue interno o control de cambios.",
                value: Self.versionDisplayString,
                accent: .blue
            )

            HStack(spacing: 10) {
                Button("Copiar resumen") {
                    copyToPasteboard(distributionSummary)
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button("Abrir app") {
                    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("Abrir logs") {
                    let logsURL = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
                    NSWorkspace.shared.open(logsURL)
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }

            Text(distributionSummary)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var technicalCard: some View {
        SettingsPanelCard(
            title: "Ficha técnica",
            subtitle: "Datos útiles para soporte, QA y despliegue"
        ) {
            SettingsInfoRow(title: "App", value: "SkyPresenterPro")
            SettingsInfoRow(title: "Bundle ID", value: bundleIdentifier, monospaced: true)
            SettingsInfoRow(title: "Ejecutable", value: executableName, monospaced: true)
            SettingsInfoRow(title: "macOS", value: ProcessInfo.processInfo.operatingSystemVersionString)
            SettingsInfoRow(title: "Bridge helper", value: helperStatus)
            SettingsInfoRow(title: "URL remota", value: remoteService.serverState.primaryURL.isEmpty ? "No publicada" : remoteService.serverState.primaryURL, monospaced: true)
        }
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
