// Archivo: SettingsGeneralPane.swift
// Función: Define el pane general del centro de configuración, incluyendo identidad de iglesia.
// Contiene: SettingsGeneralPane, ChurchIdentityCard.
// Uso: Presenta preferencias base, identidad de iglesia (nombre + logo + standby) con tarjetas compactas.

import SwiftUI
import AppKit

struct SettingsGeneralPane: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var churchIdentity: ChurchIdentityService

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                overviewStrip

                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    ChurchIdentityCard()
                    appearanceCard
                }

                behaviorCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            SettingsPreviewSidebar {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SettingsMetricCard(
                        title: "Iglesia",
                        value: churchIdentity.churchName.isEmpty ? "Sin nombre" : churchIdentity.churchName,
                        detail: churchIdentity.logoImage != nil ? "Logo cargado" : "Sin logo",
                        tint: churchIdentity.churchName.isEmpty ? .secondary : .green
                    )
                    SettingsMetricCard(
                        title: "Estado",
                        value: "Estable",
                        detail: "Sin incidencias de configuración general.",
                        tint: .green
                    )
                    SettingsMetricCard(
                        title: "Autoguardado",
                        value: viewModel.autoSaveEnabled ? "ACTIVO" : "PAUSADO",
                        detail: "Persistencia local de cambios.",
                        tint: .blue
                    )
                    Spacer()
                }
            }
            .frame(width: 278, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        SettingsSectionIntro(
            eyebrow: "Sistema",
            title: "General",
            subtitle: "Identidad de la iglesia, apariencia y comportamiento operativo"
        )
    }

    private var overviewStrip: some View {
        SettingsStatusStrip(items: [
            ("Iglesia", churchIdentity.churchName.isEmpty ? "Sin nombre" : churchIdentity.churchName),
            ("Tema", viewModel.darkInterfacePreferred ? "Oscuro" : "Claro"),
            ("Guardado", viewModel.autoSaveEnabled ? "Auto" : "Manual")
        ])
    }

    private var appearanceCard: some View {
        SettingsPanelCard(
            title: "Apariencia",
            subtitle: "Preferencia visual del operador"
        ) {
            Toggle("Modo oscuro preferido", isOn: $viewModel.darkInterfacePreferred)
                .toggleStyle(.switch)

            SettingsInfoRow(title: "Tema actual", value: viewModel.darkInterfacePreferred ? "Oscuro" : "Claro")
            SettingsInfoRow(title: "Estilo", value: "Pane")
            SettingsActionRow(
                title: "Interfaz",
                detail: "Preferencia aplicada a la consola principal.",
                value: viewModel.darkInterfacePreferred ? "ACTIVA" : "CLARA",
                accent: .blue
            )
        }
    }

    private var behaviorCard: some View {
        SettingsPanelCard(
            title: "Comportamiento",
            subtitle: "Persistencia y modo de operación"
        ) {
            Toggle("Guardar automáticamente", isOn: $viewModel.autoSaveEnabled)
                .toggleStyle(.switch)

            SettingsStatusStrip(items: [
                ("Autoguardado", viewModel.autoSaveEnabled ? "Activo" : "Detenido"),
                ("Operación", "Local"),
                ("Sesión", "Normal")
            ])

            Text("Estas opciones afectan la persistencia y la apariencia general de la consola.")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tarjeta de identidad de iglesia

struct ChurchIdentityCard: View {
    @EnvironmentObject private var churchIdentity: ChurchIdentityService
    @State private var nameInput: String = ""
    @State private var messageInput: String = ""
    @State private var isEditingName = false
    @State private var isEditingMessage = false

    var body: some View {
        SettingsPanelCard(
            title: "Identidad de la Iglesia",
            subtitle: "Nombre, logo y configuración del STANDBY"
        ) {
            // Nombre
            nameRow

            Divider()

            // Logo
            logoRow

            Divider()

            // Standby
            standbyRow
        }
        .onAppear {
            nameInput = churchIdentity.churchName
            messageInput = churchIdentity.standbyMessage
        }
    }

    // MARK: Nombre

    private var nameRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOMBRE DE LA IGLESIA")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            if isEditingName {
                HStack(spacing: 8) {
                    TextField("Nombre de la iglesia...", text: $nameInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, weight: .semibold))

                    Button("Guardar") {
                        churchIdentity.setName(nameInput)
                        isEditingName = false
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Button("Cancelar") {
                        nameInput = churchIdentity.churchName
                        isEditingName = false
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            } else {
                HStack(spacing: 8) {
                    Text(churchIdentity.churchName.isEmpty ? "Sin nombre configurado" : churchIdentity.churchName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(churchIdentity.churchName.isEmpty ? .secondary : .primary)

                    Spacer()

                    Button("Editar") {
                        nameInput = churchIdentity.churchName
                        isEditingName = true
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    if !churchIdentity.churchName.isEmpty {
                        Button("Eliminar") {
                            churchIdentity.clearName()
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Logo

    private var logoRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LOGO DE LA IGLESIA")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if let logo = churchIdentity.logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Button(churchIdentity.logoImage != nil ? "Reemplazar logo" : "Importar logo") {
                        importLogo()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    if churchIdentity.logoImage != nil {
                        Button("Eliminar logo") {
                            churchIdentity.clearLogo()
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: Standby

    private var standbyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STANDBY")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            Toggle("Mostrar reloj en standby", isOn: Binding(
                get: { churchIdentity.standbyShowClock },
                set: { churchIdentity.setShowClock($0) }
            ))
            .toggleStyle(.switch)

            if isEditingMessage {
                HStack(spacing: 8) {
                    TextField("Mensaje del standby...", text: $messageInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))

                    Button("Guardar") {
                        churchIdentity.setStandbyMessage(messageInput)
                        isEditingMessage = false
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Button("Cancelar") {
                        messageInput = churchIdentity.standbyMessage
                        isEditingMessage = false
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            } else {
                HStack(spacing: 8) {
                    Text(churchIdentity.standbyMessage.isEmpty ? "Sin mensaje configurado" : "\"\(churchIdentity.standbyMessage)\"")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(churchIdentity.standbyMessage.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer()

                    Button("Editar mensaje") {
                        messageInput = churchIdentity.standbyMessage
                        isEditingMessage = true
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
        }
    }

    // MARK: Helper

    private func importLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Seleccionar logo de la iglesia"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        churchIdentity.importLogo(from: url)
    }
}
