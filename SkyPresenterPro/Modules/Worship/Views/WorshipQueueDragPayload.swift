import Foundation

enum WorshipQueueDragPayload {
    case song(UUID)
    case queueItem(UUID)

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let id = UUID(uuidString: parts[1]) else { return nil }

        switch parts[0] {
        case "song":
            self = .song(id)
        case "queue":
            self = .queueItem(id)
        default:
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .song(let id):
            return "song:\(id.uuidString)"
        case .queueItem(let id):
            return "queue:\(id.uuidString)"
        }
    }
}
