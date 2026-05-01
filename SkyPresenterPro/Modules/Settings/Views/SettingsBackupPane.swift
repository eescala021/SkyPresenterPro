// Archivo: SettingsBackupPane.swift
// Función: Define el pane de respaldo del centro de configuración.
// Contiene: SettingsBackupPane.
// Uso: Presenta el estado del respaldo automático y acciones rápidas de resguardo con la misma estructura visual del sistema.

import SwiftUI

struct SettingsBackupPane: View {
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                backupStateCard
                storageCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            SettingsPreviewSidebar {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SettingsMetricCard(title: "Respaldo", value: viewModel.backupEnabled ? "ACTIVO" : "PAUSADO", detail: "Resguardo automático de datos.", tint: .blue)
                    SettingsMetricCard(title: "Destino", value: "Local", detail: "Unidad principal de trabajo.", tint: .orange)
                    Spacer()
                }
            }
            .frame(width: 278, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        SettingsSectionIntro(
            eyebrow: "Protección",
            title: "Respaldo",
            subtitle: "Control del resguardo automático y del almacenamiento local"
        )
    }

    private var backupStateCard: some View {
        SettingsPanelCard(
            title: "Estado del respaldo",
            subtitle: "Frecuencia y modo de ejecución"
        ) {
            Toggle("Respaldo automático", isOn: $viewModel.backupEnabled)
                .toggleStyle(.switch)

            HStack(spacing: 12) {
                SettingsMiniMetric(title: "Modo", value: viewModel.backupEnabled ? "Automático" : "Manual")
                SettingsMiniMetric(title: "Frecuencia", value: "Diaria")
            }
        }
    }

    private var storageCard: some View {
        SettingsPanelCard(
            title: "Almacenamiento",
            subtitle: "Estado del destino de respaldo"
        ) {
            SettingsInfoRow(title: "Destino", value: "Disco local")
            SettingsInfoRow(title: "Última copia", value: "No disponible")
            SettingsInfoRow(title: "Integridad", value: "Pendiente")

            Button("Crear respaldo manual") {}
                .buttonStyle(PrimaryActionButtonStyle())
        }
    }
}
