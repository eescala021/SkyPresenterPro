// Archivo: SettingsRemotePane.swift
// Función: Define el pane de control remoto dentro del centro de configuración.
// Contiene: SettingsRemotePane.
// Uso: Presenta estado del servidor remoto real, credenciales, dispositivos y ajustes de sesión con lectura operativa inmediata.

import SwiftUI
import AppKit

struct SettingsRemotePane: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var remoteService: RemoteServerService
    @EnvironmentObject private var remoteDeviceRegistry: RemoteDeviceRegistry
    @EnvironmentObject private var remoteSessionManager: RemoteSessionManager

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                paneHeader
                serverStatusCard

                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    credentialsCard
                    devicesCard
                }

                configurationCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            SettingsPreviewSidebar {
                remoteSummaryColumn
            }
            .frame(width: 278, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: viewModel.remoteControlEnabled) { _, enabled in
            if enabled {
                if !remoteService.serverState.isRunning { remoteService.start() }
            } else {
                if remoteService.serverState.isRunning { remoteService.stop() }
            }
        }
        .onAppear {
            if viewModel.remoteControlEnabled && !remoteService.serverState.isRunning {
                remoteService.start()
            }
        }
    }

    private var paneHeader: some View {
        SettingsSectionIntro(
            eyebrow: "Servidor",
            title: "Remoto",
            subtitle: "Servidor local y app web segura para smartphone"
        )
    }

    private var serverStatusCard: some View {
        SettingsPanelCard(
            title: "Estado del servidor",
            subtitle: "Lectura inmediata de conectividad local"
        ) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(remoteService.serverState.isRunning ? "Servidor activo" : "Servidor detenido")
                            .font(.system(size: 15, weight: .black))
                    } icon: {
                        Circle()
                            .fill(remoteService.serverState.isRunning ? Color.green : Color.red.opacity(0.7))
                            .frame(width: 10, height: 10)
                    }

                    Text(remoteService.serverState.isRunning ? remoteService.serverState.serverURL : "Inicie el servidor para publicar la consola.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                Button(remoteService.serverState.isRunning ? "Detener" : "Iniciar") {
                    remoteService.toggle()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }

            HStack(spacing: 12) {
                SettingsMiniMetric(title: "IP", value: remoteService.serverState.detectedIPAddress ?? "No detectada")
                SettingsMiniMetric(title: "Puerto", value: "\(remoteService.serverState.port)")
                SettingsMiniMetric(title: "PIN", value: remoteService.serverState.isRunning ? remoteService.serverState.pin : "—")
            }
        }
    }

    private var credentialsCard: some View {
        SettingsPanelCard(
            title: "Credenciales",
            subtitle: "Acceso del operador móvil"
        ) {
            HStack {
                Button("Regenerar PIN") {
                    remoteService.regeneratePIN()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(!remoteService.serverState.isRunning)

                Spacer()
            }

            credentialRow(title: "URL", value: remoteService.serverState.isRunning ? remoteService.serverState.serverURL : "Inicie el servidor")
            credentialRow(title: "IP", value: remoteService.serverState.detectedIPAddress ?? "No detectada")
            credentialRow(title: "Puerto", value: "\(remoteService.serverState.port)")
            credentialRow(title: "PIN", value: remoteService.serverState.isRunning ? remoteService.serverState.pin : "—")
            credentialRow(title: "Usuario", value: remoteService.serverState.username.isEmpty ? "—" : remoteService.serverState.username)

            Button("Copiar credenciales") {
                let text = """
                URL: \(remoteService.serverState.serverURL)
                Usuario: \(remoteService.serverState.username)
                PIN: \(remoteService.serverState.pin)
                """
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(!remoteService.serverState.isRunning)
        }
    }

    private var devicesCard: some View {
        SettingsPanelCard(
            title: "Dispositivos",
            subtitle: "Conexiones activas en este momento"
        ) {
            HStack {
                Text("\(remoteDeviceRegistry.connectedDevices.count)")
                    .font(.system(size: 12, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.05))
                    )

                Spacer()
            }

            if remoteDeviceRegistry.connectedDevices.isEmpty {
                Text("Sin dispositivos conectados")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(remoteDeviceRegistry.connectedDevices) { device in
                        let session = sessionForDevice(device)
                        RemoteDeviceRow(
                            device: device,
                            session: session
                        ) {
                            remoteDeviceRegistry.removeDevice(id: device.id)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
    }

    private var configurationCard: some View {
        SettingsPanelCard(
            title: "Configuración",
            subtitle: "Comportamiento del servidor y sesiones"
        ) {
            HStack {
                Text("IP anunciada")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(remoteService.serverState.detectedIPAddress ?? "No detectada")
                    .font(.system(size: 13, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                    )
            }

            Toggle("Iniciar servidor al abrir la app", isOn: $viewModel.remoteControlEnabled)
                .toggleStyle(.switch)

            Toggle("Consulta remota de estado", isOn: .constant(true))
                .toggleStyle(.switch)

            SettingsInfoRow(title: "Sesiones activas", value: "\(remoteService.activeSessionCount)")

            Button("Revocar todas las sesiones") {
                remoteService.revokeAllSessions()
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(remoteService.activeSessionCount == 0)

            HStack {
                Text("Estado: \(remoteService.serverState.isRunning ? "Servidor en línea" : "Servidor detenido")")
                Spacer()
                Text("Seguridad: Sesiones PIN")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
        }
    }

    private var remoteSummaryColumn: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SettingsMetricCard(
                title: "Servidor",
                value: remoteService.serverState.isRunning ? "ACTIVO" : "DETENIDO",
                detail: remoteService.serverState.isRunning
                    ? "Escuchando en \(remoteService.serverState.serverURL)"
                    : "Presiona Iniciar para activar.",
                tint: remoteService.serverState.isRunning ? .green : .red
            )

            SettingsPanelCard(title: "Red", subtitle: "Datos publicados por la consola") {
                SettingsInfoRow(title: "IP local", value: remoteService.serverState.detectedIPAddress ?? "No detectada")
                SettingsInfoRow(title: "Puerto", value: "\(remoteService.serverState.port)")
                SettingsInfoRow(title: "Usuario", value: remoteService.serverState.username)
                SettingsInfoRow(title: "PIN", value: remoteService.serverState.isRunning ? remoteService.serverState.pin : "—")
                SettingsInfoRow(title: "Dispositivos", value: "\(remoteDeviceRegistry.connectedDevices.count)")
            }

            Spacer()
        }
    }

    private func sessionForDevice(_ device: RemoteDevice) -> RemoteSession? {
        guard let sessionId = device.sessionId else { return nil }
        return remoteSessionManager.activeSessions.first(where: { $0.id == sessionId })
    }

    private func credentialRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .black))
                .textSelection(.enabled)
                .lineLimit(1)

            Spacer()
        }
    }
}
