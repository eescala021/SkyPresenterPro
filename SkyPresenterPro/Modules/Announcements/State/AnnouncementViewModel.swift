import Combine
import SwiftUI

struct AnnouncementItem: Identifiable, Equatable {
    let id: UUID
    var message: String
    var isEnabled: Bool

    init(id: UUID = UUID(), message: String, isEnabled: Bool = true) {
        self.id = id
        self.message = message
        self.isEnabled = isEnabled
    }
}

@MainActor
final class AnnouncementViewModel: ObservableObject {
    @Published var message: String = ""
    @Published var isVisible: Bool = false
    @Published var style: AnnouncementStyle = .presentationDefault
    @Published var items: [AnnouncementItem] = [
        AnnouncementItem(message: "Bienvenidos"),
        AnnouncementItem(message: "La reunión comienza en 10 minutos", isEnabled: false)
    ]
    @Published var draftMessage: String = ""

    private var projectionRouter: ProjectionCommandRouter?

    func configureProjectionRouter(_ router: ProjectionCommandRouter) {
        projectionRouter = router
    }

    func show(message: String) {
        show(message: message, style: .presentationDefault)
    }

    func show(message: String, style: AnnouncementStyle) {
        self.message = message
        self.style = style
        self.isVisible = true
    }

    func hide() {
        isVisible = false
        projectionRouter?.clear()
    }

    func clear() {
        message = ""
        isVisible = false
        projectionRouter?.clear()
    }

    func updateMessage(_ newMessage: String) {
        message = newMessage
    }

    func updateStyle(_ newStyle: AnnouncementStyle) {
        style = newStyle
    }

    func addDraftItem() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(AnnouncementItem(message: trimmed))
        draftMessage = ""
    }

    func updateItem(_ itemID: UUID, message: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].message = message

        if self.message == items[index].message, isVisible {
            projectItem(items[index])
        }
    }

    func toggleItem(_ item: AnnouncementItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isEnabled.toggle()

        if items[index].isEnabled {
            projectItem(items[index])
        } else if message == item.message {
            hide()
        }
    }

    func removeItem(_ item: AnnouncementItem) {
        items.removeAll { $0.id == item.id }
        if message == item.message {
            hide()
        }
    }

    func moveItems(from offsets: IndexSet, to destination: Int) {
        items.move(fromOffsets: offsets, toOffset: destination)
    }

    func projectItem(_ item: AnnouncementItem) {
        guard item.isEnabled else { return }
        show(message: item.message, style: style)
        let slides = ProjectionPayloadBuilder.fromAnnouncement(item.message)
        projectionRouter?.project(slides: slides, source: .announcement, startAt: 0)
    }

    var hasContent: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
