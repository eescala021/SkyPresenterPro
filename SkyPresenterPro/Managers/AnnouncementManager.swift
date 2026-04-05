import Foundation
import SwiftUI
import Combine

enum AnnouncementType: String, Codable, CaseIterable, Identifiable {
    case `static` = "Static"
    case scrolling = "Scrolling"
    case flash = "Flash"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .static: return "Estático"
        case .scrolling: return "Desplazamiento"
        case .flash: return "Parpadeo"
        }
    }

    func matches(_ value: String) -> Bool {
        rawValue.caseInsensitiveCompare(value) == .orderedSame ||
        displayName.caseInsensitiveCompare(value) == .orderedSame
    }
}

enum AnnouncementPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case breaking = "Breaking"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Baja"
        case .normal: return "Normal"
        case .high: return "Alta"
        case .breaking: return "Urgente"
        }
    }

    var rank: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .breaking: return 3
        }
    }
}

enum AnnouncementBarPosition: String, Codable, CaseIterable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .top: return "Superior"
        case .bottom: return "Inferior"
        }
    }
}

struct AnnouncementItem: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var type: AnnouncementType
    var priority: AnnouncementPriority
    var duration: TimeInterval
    var loops: Int
    var isRecurring: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        type: AnnouncementType = .scrolling,
        priority: AnnouncementPriority = .normal,
        duration: TimeInterval = 20,
        loops: Int = 1,
        isRecurring: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.priority = priority
        self.duration = duration
        self.loops = loops
        self.isRecurring = isRecurring
        self.createdAt = createdAt
    }
}

struct AnnouncementSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var backgroundOpacity: Double = 0.70
    var speedPointsPerSecond: Double = 160
    var barHeightRatio: Double = 0.10
    var position: AnnouncementBarPosition = .bottom
    var strokeWidth: Double = 2
    var showsOnStageView: Bool = false
    var separatorText: String = "***"
    var usesInfiniteLoop: Bool = true

    static let `default` = AnnouncementSettings()
}

private struct AnnouncementStorage: Codable {
    var settings: AnnouncementSettings
    var storedItems: [AnnouncementItem]
}

@MainActor
final class AnnouncementManager: ObservableObject {
    @Published var settings: AnnouncementSettings {
        didSet { persist() }
    }
    @Published private(set) var storedItems: [AnnouncementItem]
    @Published private(set) var queue: [UUID]
    @Published private(set) var activeAnnouncementID: UUID?
    @Published var quickDraft: String = ""

    private let storageURL: URL
    private var dismissalTasks: [UUID: Task<Void, Never>] = [:]

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SkyPresenterPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.storageURL = directory.appendingPathComponent("announcements.json")

        if let data = try? Data(contentsOf: storageURL),
           let decoded = try? JSONDecoder().decode(AnnouncementStorage.self, from: data) {
            self.settings = decoded.settings
            self.storedItems = decoded.storedItems
        } else {
            self.settings = .default
            self.storedItems = [
                AnnouncementItem(content: "Bienvenidos a nuestra reunión", type: .scrolling, priority: .normal, duration: 24, loops: 0, isRecurring: true)
            ]
        }

        self.queue = []
        self.activeAnnouncementID = nil
    }

    var queuedAnnouncements: [AnnouncementItem] {
        queue.compactMap { id in storedItems.first(where: { $0.id == id }) }
    }

    var activeAnnouncement: AnnouncementItem? {
        if let activeAnnouncementID,
           let matched = storedItems.first(where: { $0.id == activeAnnouncementID }) {
            return matched
        }

        return queuedAnnouncements.sorted {
            if $0.priority.rank == $1.priority.rank {
                return $0.createdAt < $1.createdAt
            }
            return $0.priority.rank > $1.priority.rank
        }.first
    }

    var scrollingAnnouncements: [AnnouncementItem] {
        queuedAnnouncements.filter { $0.type == .scrolling }
    }

    var stageVisibleAnnouncement: AnnouncementItem? {
        guard settings.showsOnStageView || activeAnnouncement?.priority.rank ?? 0 >= AnnouncementPriority.high.rank else {
            return nil
        }
        return activeAnnouncement
    }

    var tickerFeedText: String {
        let items = scrollingAnnouncements
        guard !items.isEmpty else { return "" }
        let separator = "   \(settings.separatorText)   "
        let text = items.map(\.content).joined(separator: separator)
        return settings.usesInfiniteLoop ? text + separator + text : text
    }

    func saveRecurringAnnouncement(
        content: String,
        type: AnnouncementType,
        priority: AnnouncementPriority,
        duration: TimeInterval,
        loops: Int,
        queueNow: Bool
    ) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = AnnouncementItem(
            content: trimmed,
            type: type,
            priority: priority,
            duration: duration,
            loops: loops,
            isRecurring: true
        )
        storedItems.insert(item, at: 0)
        persist()
        if queueNow {
            enqueue(item.id)
        }
    }

    func updateAnnouncement(_ item: AnnouncementItem) {
        guard let index = storedItems.firstIndex(where: { $0.id == item.id }) else { return }
        storedItems[index] = item
        persist()
    }

    func deleteAnnouncement(id: UUID) {
        dismissalTasks[id]?.cancel()
        dismissalTasks[id] = nil
        storedItems.removeAll { $0.id == id }
        queue.removeAll { $0 == id }
        if activeAnnouncementID == id {
            activeAnnouncementID = nil
        }
        persist()
    }

    func enqueue(_ id: UUID) {
        guard storedItems.contains(where: { $0.id == id }) else { return }
        if !queue.contains(id) {
            queue.append(id)
        }
        if activeAnnouncementID == nil {
            activeAnnouncementID = id
        }
        scheduleDismissIfNeeded(for: id)
    }

    func triggerQuickAnnouncement(
        content: String,
        priority: AnnouncementPriority = .breaking,
        type: AnnouncementType = .scrolling,
        duration: TimeInterval = 18
    ) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = AnnouncementItem(
            content: trimmed,
            type: type,
            priority: priority,
            duration: duration,
            loops: 1,
            isRecurring: false
        )
        storedItems.insert(item, at: 0)
        queue.insert(item.id, at: 0)
        activeAnnouncementID = item.id
        persist()
        scheduleDismissIfNeeded(for: item.id)
    }

    func clearQueue() {
        dismissalTasks.values.forEach { $0.cancel() }
        dismissalTasks.removeAll()
        queue.removeAll()
        activeAnnouncementID = nil
    }

    func dismissActiveAnnouncement() {
        guard let activeAnnouncementID else { return }
        queue.removeAll { $0 == activeAnnouncementID }
        dismissalTasks[activeAnnouncementID]?.cancel()
        dismissalTasks[activeAnnouncementID] = nil
        if let item = storedItems.first(where: { $0.id == activeAnnouncementID }), !item.isRecurring {
            storedItems.removeAll { $0.id == activeAnnouncementID }
        }
        self.activeAnnouncementID = queue.first
        persist()
    }

    private func scheduleDismissIfNeeded(for id: UUID) {
        guard let item = storedItems.first(where: { $0.id == id }), item.duration > 0 else { return }
        dismissalTasks[id]?.cancel()
        dismissalTasks[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(item.duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.autoDismiss(id: id)
        }
    }

    private func autoDismiss(id: UUID) {
        queue.removeAll { $0 == id }
        dismissalTasks[id]?.cancel()
        dismissalTasks[id] = nil
        if let item = storedItems.first(where: { $0.id == id }), !item.isRecurring {
            storedItems.removeAll { $0.id == id }
        }
        if activeAnnouncementID == id {
            activeAnnouncementID = queue.first
        }
        persist()
    }

    private func persist() {
        let storage = AnnouncementStorage(settings: settings, storedItems: storedItems)
        guard let data = try? JSONEncoder().encode(storage) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
