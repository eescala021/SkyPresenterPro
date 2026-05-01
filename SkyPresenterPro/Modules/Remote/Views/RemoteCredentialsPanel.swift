// Archivo: RemoteCredentialsPanel.swift
// Función: Panel compacto de credenciales operativas del servidor remoto local.
// Contiene: RemoteCredentialsPanel.
// Uso: Muestra URL, IP, puerto, usuario y PIN siempre visibles. PIN se muestra aunque el servidor esté detenido.

import SwiftUI

struct RemoteCredentialsPanel: View {

    let serverState: RemoteServerState
    let onRegenerate: () -> Void

    @State private var pinVisible = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow

            // URL — solo si el servidor está activo
            if serverState.isRunning {
                credentialCopyRow(
                    label: "URL",
                    value: serverState.primaryURL.isEmpty ? serverState.serverURL : serverState.primaryURL,
                    canCopy: true
                )
            } else {
                credentialRow(label: "URL", value: "Inicie el servidor para obtener la URL")
            }

            credentialRow(label: "IP", value: serverState.detectedIPAddress ?? "Detectando…")
            credentialRow(label: "Puerto", value: serverState.isRunning ? "\(serverState.port)" : "—")
            credentialRow(label: "Usuario", value: serverState.username.isEmpty ? "—" : serverState.username)

            // PIN — siempre visible (es persistente aunque el servidor esté detenido)
            pinRow

            Divider()

            HStack(spacing: AppSpacing.sm) {
                Button("Regenerar PIN") {
                    onRegenerate()
                }
                .buttonStyle(SecondaryActionButtonStyle())

                if serverState.isRunning {
                    Button("Copiar URL") {
                        copyToClipboard(serverState.primaryURL.isEmpty ? serverState.serverURL : serverState.primaryURL)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Text("Credenciales")
                .font(.system(size: 14, weight: .black))

            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(serverState.isRunning ? Color.green : Color.red.opacity(0.6))
                .frame(width: 7, height: 7)

            Text(serverState.isRunning ? "Activo" : "Detenido")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(serverState.isRunning ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(serverState.isRunning ? Color.green.opacity(0.10) : Color.black.opacity(0.05))
        )
    }

    private var pinRow: some View {
        HStack(alignment: .top) {
            Text("PIN")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            HStack(spacing: 6) {
                Text(pinVisible ? serverState.pin : String(repeating: "•", count: serverState.pin.count))
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)

                Button {
                    pinVisible.toggle()
                } label: {
                    Image(systemName: pinVisible ? "eye.slash" : "eye")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    copyToClipboard(serverState.pin)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private func credentialRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()
        }
    }

    private func credentialCopyRow(label: String, value: String, canCopy: Bool) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.blue)
                .textSelection(.enabled)
                .lineLimit(2)

            Spacer()

            if canCopy {
                Button {
                    copyToClipboard(value)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
