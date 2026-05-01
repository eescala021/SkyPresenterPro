import SwiftUI

struct BibleImportWindow: View {
    @ObservedObject var viewModel: BibleImportViewModel
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            header
            fileSelector
            metadataForm
            actionBar
            statusView
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.xl)
        .frame(width: 560, height: 420)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Confirmar importación XML")
                .font(AppTypography.paneTitle)

            Text("Antes de guardar la Biblia en la biblioteca, define nombre, idioma, alias y contenedor.")
                .foregroundStyle(.secondary)
        }
    }

    private var fileSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Archivo XML")
                .font(.headline)

            HStack(spacing: AppSpacing.sm) {
                Text(viewModel.selectedFileURL?.lastPathComponent ?? "Ninguno")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button("Cambiar archivo") {
                    viewModel.selectFile()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .modifier(AppCardStyle())
    }

    private var metadataForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("1. Nombre de la Biblia")
                    .font(.system(size: 12, weight: .black))
                TextField("Ej: Reina Valera 1960", text: $viewModel.bibleName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("2. Idioma")
                    .font(.system(size: 12, weight: .black))
                Picker("Idioma", selection: $viewModel.selectedLanguage) {
                    ForEach(BibleVersionLanguage.allCases) { language in
                        Text(language.pickerLabel).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3. Alias")
                        .font(.system(size: 12, weight: .black))
                    TextField("Ej: RVR", text: $viewModel.alias)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Contenedor")
                        .font(.system(size: 12, weight: .black))
                    Picker("Contenedor", selection: $viewModel.selectedSlot) {
                        ForEach(BibleVersionSlot.allCases) { slot in
                            Text(slot.title).tag(slot)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
            }
        }
        .modifier(AppCardStyle())
    }

    private var actionBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Button("Cancelar", action: onCancel)
                .buttonStyle(SecondaryActionButtonStyle())

            Button("Importar XML", action: onConfirm)
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!viewModel.canImport)

            Spacer()
        }
    }

    private var statusView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if viewModel.isImporting {
                ProgressView()
            }

            if !viewModel.importStatusMessage.isEmpty {
                Text(viewModel.importStatusMessage)
                    .foregroundStyle(
                        viewModel.didImportSuccessfully ? AppColors.success : AppColors.danger
                    )
                    .font(.system(size: 11, weight: .semibold))
            }
        }
    }
}
