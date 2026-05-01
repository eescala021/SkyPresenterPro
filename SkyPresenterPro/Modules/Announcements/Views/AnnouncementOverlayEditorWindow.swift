import SwiftUI

struct AnnouncementOverlayEditorWindow: View {
    @EnvironmentObject private var viewModel: AnnouncementViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Anuncios")
                    .font(.system(size: 13, weight: .black))
                Spacer()
                Button("Cerrar") {
                    viewModel.hide()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            HStack(spacing: 8) {
                TextField("Nuevo anuncio", text: $viewModel.draftMessage)
                    .textFieldStyle(.roundedBorder)
                Button {
                    viewModel.addDraftItem()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .padding(10)

            Divider()

            ScrollView(showsIndicators: true) {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.items) { item in
                        row(item)
                    }
                }
                .padding(10)
            }
        }
        .frame(minWidth: 520, minHeight: 250)
    }

    private func row(_ item: AnnouncementItem) -> some View {
        HStack(spacing: 8) {
            iconButton(item.isEnabled ? "checkmark" : "circle") {
                viewModel.toggleItem(item)
            }

            iconButton("arrow.up") {
                viewModel.moveItemUp(item)
            }

            iconButton("arrow.down") {
                viewModel.moveItemDown(item)
            }

            TextField(
                "Mensaje",
                text: Binding(
                    get: { item.message },
                    set: { viewModel.updateItem(item.id, message: $0) }
                )
            )
            .textFieldStyle(.roundedBorder)

            Button {
                viewModel.projectItem(item)
            } label: {
                Image(systemName: "bell.badge")
            }
            .buttonStyle(.plain)

            Button {
                viewModel.removeItem(item)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }

    private func iconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
    }
}
