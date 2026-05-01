// Archivo: RemoteDevicesPanel.swift
// Función: Panel de dispositivos remotos conectados al servidor local.
// Contiene: RemoteDevicesPanel, RemoteDeviceRow.
// Uso: Se embebe en RemoteDashboardView para listar dispositivos activos con acciones de desconexión.

import SwiftUI

struct RemoteDevicesPanel: View {

    let devices: [RemoteDevice]
    let sessions: [RemoteSession]
    let onDisconnect: (UUID) -> Void
    let onDisconnectAll: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow

            if devices.isEmpty {
                emptyState
            } else {
                ForEach(devices) { device in
                    RemoteDeviceRow(
                        device: device,
                        session: sessions.first { $0.id == device.sessionId },
                        onDisconnect: { onDisconnect(device.id) }
                    )
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Text("Dispositivos")
                .font(.system(size: 18, weight: .black))

            Spacer()

            if !devices.isEmpty {
                Button("Desconectar todos") {
                    onDisconnectAll()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.secondary)

            Text("Sin dispositivos conectados")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)

            Text("Los dispositivos aparecen aquí cuando acceden al servidor local a través del navegador.")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - Device Row

struct RemoteDeviceRow: View {

    let device: RemoteDevice
    let session: RemoteSession?
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "iphone")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 13, weight: .black))

                Text(device.ipAddress)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let session {
                Text(session.isValid ? "Sesión activa" : "Sesión expirada")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(session.isValid ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(session.isValid ? Color.green.opacity(0.10) : Color.black.opacity(0.05))
                    )
            }

            Button("Desconectar") {
                onDisconnect()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(.vertical, 6)
    }
}
