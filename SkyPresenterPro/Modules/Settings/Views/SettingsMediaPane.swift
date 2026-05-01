import AppKit
import SwiftUI

struct SettingsMediaPane: View {
    @EnvironmentObject private var mediaLibraryManager: MediaLibraryManager

    @State private var selectedKind: MediaLibraryItem.Kind = .image
    @State private var selectedItemID: UUID?
    @State private var renameValue: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                toolbar
                mediaGrid
                renameCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            SettingsPreviewSidebar {
                SettingsMetricCard(
                    title: "Imágenes",
                    value: "\(mediaLibraryManager.imageItems.count)",
                    detail: "Fondos disponibles para temas.",
                    tint: .blue
                )
                SettingsMetricCard(
                    title: "Video loops",
                    value: "\(mediaLibraryManager.videoItems.count)",
                    detail: "Loops predeterminados de 8 segundos y videos agregados por el usuario.",
                    tint: .orange
                )
                Spacer()
            }
            .frame(width: 278, alignment: .top)
        }
        .onAppear {
            if let first = currentItems.first {
                selectedItemID = first.id
                renameValue = first.name
            }
        }
        .onChange(of: selectedKind) { _, _ in
            if let first = currentItems.first {
                selectedItemID = first.id
                renameValue = first.name
            } else {
                selectedItemID = nil
                renameValue = ""
            }
        }
    }

    private var header: some View {
        SettingsSectionIntro(
            eyebrow: "Biblioteca",
            title: "Multimedia",
            subtitle: "Imágenes y video loops predeterminados y agregados por el usuario"
        )
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Picker("Tipo", selection: $selectedKind) {
                Text("Imágenes").tag(MediaLibraryItem.Kind.image)
                Text("Video loops").tag(MediaLibraryItem.Kind.video)
            }
            .pickerStyle(.segmented)

            Button(selectedKind == .image ? "Agregar imágenes" : "Agregar videos") {
                if selectedKind == .image {
                    mediaLibraryManager.addImages()
                } else {
                    mediaLibraryManager.addVideos()
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())

            if let selectedItem {
                Button("Eliminar") {
                    mediaLibraryManager.remove(selectedItem)
                    if let first = currentItems.first {
                        selectedItemID = first.id
                        renameValue = first.name
                    } else {
                        selectedItemID = nil
                        renameValue = ""
                    }
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
    }

    private var mediaGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(currentItems) { item in
                Button {
                    selectedItemID = item.id
                    renameValue = item.name
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        preview(item)
                            .frame(height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text(item.name)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(selectedItemID == item.id ? AppColors.accent : .primary)
                            .lineLimit(1)

                        Text(item.isDefault ? "Predeterminado" : "Usuario")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedItemID == item.id ? AppColors.accent.opacity(0.10) : Color.black.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selectedItemID == item.id ? AppColors.accent : Color.black.opacity(0.08), lineWidth: selectedItemID == item.id ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var renameCard: some View {
        SettingsPanelCard(
            title: "Editar elemento",
            subtitle: "Renombrar o revisar el elemento seleccionado"
        ) {
            TextField("Nombre", text: $renameValue)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Button("Guardar nombre") {
                    guard let selectedItem else { return }
                    mediaLibraryManager.rename(selectedItem, to: renameValue)
                }
                .buttonStyle(PrimaryActionButtonStyle())

                if let selectedItem {
                    Text(selectedItem.kind == .image ? "Imagen" : "Video loop 8s")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func preview(_ item: MediaLibraryItem) -> some View {
        switch item.kind {
        case .image:
            if let image = NSImage(contentsOfFile: item.filePath) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackPreview(title: item.name, tint: .blue)
            }
        case .video:
            fallbackPreview(title: item.name, tint: .orange)
                .overlay(alignment: .center) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
    }

    private func fallbackPreview(title: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.8), Color.black.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(10)
        }
    }

    private var currentItems: [MediaLibraryItem] {
        switch selectedKind {
        case .image: return mediaLibraryManager.imageItems
        case .video: return mediaLibraryManager.videoItems
        }
    }

    private var selectedItem: MediaLibraryItem? {
        currentItems.first(where: { $0.id == selectedItemID })
    }
}
