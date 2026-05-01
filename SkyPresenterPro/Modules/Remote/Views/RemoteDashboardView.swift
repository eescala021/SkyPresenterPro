// Archivo: RemoteDashboardView.swift
// Función: Vista principal del módulo Remoto — panel de control operativo real.
// Contiene: RemoteDashboardView.
// Uso: Muestra estado del servidor, credenciales, dispositivos y sesiones en layout compacto sin espacio muerto.

import SwiftUI

struct RemoteDashboardView: View {

    @EnvironmentObject private var remoteServerService: RemoteServerService
    @EnvironmentObject private var deviceRegistry: RemoteDeviceRegistry
    @EnvironmentObject private var sessionManager: RemoteSessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header compacto con estado + acciones
            controlBar

            // Contenido principal
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                // Columna izquierda: credenciales + config
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    RemoteCredentialsPanel(
                        serverState: remoteServerService.serverState,
                        onRegenerate: { remoteServerService.regeneratePIN() }
                    )
                    sessionExpirationCard
                }
                .frame(width: 300, alignment: .topLeading)

                // Columna central: dispositivos
                RemoteDevicesPanel(
                    devices: deviceRegistry.connectedDevices,
                    sessions: sessionManager.activeSessions,
                    onDisconnect: { id in
                        deviceRegistry.removeDevice(id: id)
                    },
                    onDisconnectAll: {
                        deviceRegistry.clearAll()
                        sessionManager.revokeAllSessions()
                    }
                )
                .frame(maxWidth: .infinity)

                // Columna derecha: sesiones + integración
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sessionsCard
                    integrationCard
                }
                .frame(width: 220, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Barra de control principal

    private var controlBar: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            // Indicador de estado
            Circle()
                .fill(remoteServerService.serverState.isRunning ? Color.green : Color.red.opacity(0.55))
                .frame(width: 10, height: 10)

            Text(remoteServerService.serverState.isRunning ? "Servidor activo" : "Servidor detenido")
                .font(.system(size: 13, weight: .black))

            if let ip = remoteServerService.serverState.detectedIPAddress,
               remoteServerService.serverState.isRunning {
                Rectangle()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 1, height: 16)

                Text("\(ip):\(remoteServerService.serverState.port)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
                    .textSelection(.enabled)
            }

            Spacer()

            // Contador de dispositivos
            Label("\(deviceRegistry.connectedDevices.count) dispositivos", systemImage: "iphone")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(deviceRegistry.connectedDevices.isEmpty ? Color.secondary : Color.orange)

            // Contador de sesiones
            let validSessions = sessionManager.activeSessions.filter(\.isValid).count
            Label("\(validSessions) sesiones", systemImage: "person.crop.circle")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(validSessions > 0 ? Color.purple : Color.secondary)

            // Botón START / STOP
            serverToggleButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(cardBackground)
    }

    // MARK: - Toggle button

    @ViewBuilder
    private var serverToggleButton: some View {
        if remoteServerService.serverState.isRunning {
            Button("DETENER") {
                remoteServerService.stop()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        } else {
            Button("INICIAR") {
                remoteServerService.start()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }

    // MARK: - Expiración de sesión

    private var sessionExpirationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sesiones")
                .font(.system(size: 14, weight: .black))

            HStack {
                Text("Duración de sesión")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Picker("", selection: Binding(
                    get: { remoteServerService.serverState.sessionExpiration },
                    set: { remoteServerService.setSessionExpiration($0) }
                )) {
                    ForEach(RemoteSessionExpiration.allCases) { exp in
                        Text(exp.title).tag(exp)
                    }
                }
                .labelsHidden()
                .frame(width: 110)
            }

            HStack {
                Text("Sesiones activas")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text("\(sessionManager.activeSessions.filter(\.isValid).count)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.purple)
            }

            Button("Revocar todas las sesiones") {
                sessionManager.revokeAllSessions()
                deviceRegistry.purgeInactiveDevices(olderThan: 0)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(sessionManager.activeSessions.isEmpty)
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: - Sesiones activas detalle

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sesiones activas")
                .font(.system(size: 14, weight: .black))

            let valid = sessionManager.activeSessions.filter(\.isValid)
            if valid.isEmpty {
                Text("Sin sesiones activas")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            } else {
                ForEach(valid) { session in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.username)
                                .font(.system(size: 11, weight: .black))
                                .lineLimit(1)
                            Text(session.token.prefix(10) + "…")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Revocar") {
                            sessionManager.revokeSession(id: session.id)
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: - Integración

    private var integrationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Integración")
                .font(.system(size: 14, weight: .black))

            integrationRow(icon: "book.closed",          label: "Biblia",          active: true)
            integrationRow(icon: "music.note",           label: "Alabanzas",       active: true)
            integrationRow(icon: "rectangle.on.rectangle", label: "Presentaciones", active: true)

            Text("Todos los módulos permiten control y consulta remota.")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(cardBackground)
    }

    private func integrationRow(icon: String, label: String, active: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(active ? .blue : .secondary)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 11, weight: .bold))

            Spacer()

            Circle()
                .fill(active ? Color.green : Color.black.opacity(0.15))
                .frame(width: 7, height: 7)
        }
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
