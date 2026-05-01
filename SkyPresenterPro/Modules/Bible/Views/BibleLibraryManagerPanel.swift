import SwiftUI
import UniformTypeIdentifiers

struct BibleLibraryManagerPanel: View {
    @EnvironmentObject private var viewModel: BibleViewModel

    @StateObject private var importViewModel = BibleImportViewModel()
    @State private var selectedLanguage: BibleVersionLanguage? = nil
    @State private var isImportingVersion = false
    @State private var isShowingImportSheet = false
    @State private var requestedImportSlot: BibleVersionSlot = .primary
    @State private var statusMessage: String?

    private var filteredVersions: [BibleVersionDescriptor] {
        let versions = viewModel.availableVersions
        guard let selectedLanguage else { return versions }
        return versions.filter { $0.language.uppercased() == selectedLanguage.rawValue }
    }

    var body: some View {
        BibleLibraryWindow {
            header
            filtersBar
            versionsGrid
        }
        .fileImporter(
            isPresented: $isImportingVersion,
            allowedContentTypes: [.xml],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importViewModel.prepareImport(url: url, preferredSlot: requestedImportSlot, currentAlias: viewModel.alias(for: requestedImportSlot))
                isShowingImportSheet = true
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isShowingImportSheet) {
            BibleImportWindow(
                viewModel: importViewModel,
                onConfirm: confirmImport,
                onCancel: {
                    isShowingImportSheet = false
                }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Biblioteca Bíblica")
                    .font(AppTypography.paneTitle)
                Text("Gestiona versiones, asigna contenedores, importa XML y define la Biblia activa desde una sola vista.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                requestedImportSlot = viewModel.activeVersionSlot
                isImportingVersion = true
            } label: {
                Label("Agregar XML", systemImage: "plus")
                    .font(.system(size: 11, weight: .black))
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .help("Importa una nueva Biblia XML en el contenedor activo.")
        }
    }

    private var filtersBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Picker("Idioma", selection: Binding(
                get: { selectedLanguage },
                set: { selectedLanguage = $0 }
            )) {
                Text("Todos").tag(BibleVersionLanguage?.none)
                ForEach(BibleVersionLanguage.allCases) { language in
                    Text(language.rawValue).tag(BibleVersionLanguage?.some(language))
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            .help("Filtra las versiones por idioma.")

            Spacer()

            if let statusMessage {
                Text(statusMessage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var versionsGrid: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredVersions) { version in
                    versionCard(version)
                }
            }
        }
    }

    private func versionCard(_ version: BibleVersionDescriptor) -> some View {
        let assignedSlots = BibleVersionSlot.allCases.filter { viewModel.version(for: $0)?.id == version.id }
        let isActive = assignedSlots.contains(viewModel.activeVersionSlot)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(version.name)
                        .font(.system(size: 14, weight: .black))
                    Text(version.displayLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        infoChip(version.source == .builtIn ? "Integrada" : "Importada", tint: version.source == .builtIn ? Color.blue.opacity(0.12) : Color.green.opacity(0.12), color: version.source == .builtIn ? .blue : .green)
                        if isActive {
                            infoChip("Biblia activa", tint: Color.orange.opacity(0.14), color: .orange)
                        }
                        if !assignedSlots.isEmpty {
                            infoChip(assignedSlots.map(\.title).joined(separator: " · "), tint: Color.black.opacity(0.06), color: .primary)
                        }
                    }
                }

                Spacer()

                Menu {
                    ForEach(BibleVersionSlot.allCases) { slot in
                        Button("Asignar a \(slot.title)") {
                            viewModel.assignVersion(version.id, to: slot)
                            statusMessage = "\(version.name) asignada a \(slot.title)"
                        }
                    }
                } label: {
                    Label("Asignar", systemImage: "square.grid.2x2")
                        .font(.system(size: 11, weight: .black))
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .help("Asigna esta Biblia a uno de los contenedores VER1, VER2 o VER3.")

                Button("Activa") {
                    if let firstSlot = assignedSlots.first {
                        viewModel.setActiveVersionSlot(firstSlot)
                        statusMessage = "\(firstSlot.title) ahora es la Biblia activa"
                    }
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(assignedSlots.isEmpty)
                .help("Convierte esta versión en la Biblia activa usando el primer contenedor donde esté asignada.")

                if version.source == .imported {
                    Button(role: .destructive) {
                        switch viewModel.deleteVersion(version) {
                        case .success:
                            statusMessage = "\(version.name) eliminada de la biblioteca"
                        case .failure(let error):
                            statusMessage = error.localizedDescription
                        }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                            .font(.system(size: 11, weight: .black))
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .help("Elimina esta Biblia importada de la biblioteca.")
                }
            }

            HStack(spacing: 8) {
                detailLine("Idioma", version.language)
                detailLine("Archivo", version.fileName ?? "No registrado")
                detailLine("Fecha", formattedDate(version.importedAt))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func detailLine(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoChip(_ text: String, tint: Color, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint))
    }

    private func confirmImport() {
        guard let request = importViewModel.importRequest else {
            importViewModel.markImportFinished(message: "Completa nombre y archivo antes de importar.", success: false)
            return
        }

        importViewModel.markImportStarted()
        Task {
            switch await viewModel.importVersion(using: request) {
            case .success(let descriptor):
                importViewModel.markImportFinished(message: "Importada \(descriptor.name) en \(request.slot.title).", success: true)
                statusMessage = "Importada \(descriptor.name) en \(request.slot.title)"
                try? await Task.sleep(nanoseconds: 450_000_000)
                isShowingImportSheet = false
                importViewModel.reset()
            case .failure(let error):
                importViewModel.markImportFinished(message: error.localizedDescription, success: false)
                statusMessage = error.localizedDescription
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
