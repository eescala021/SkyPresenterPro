import Foundation
import OSLog

final class ProjectionControlLatencyMonitor {
    static let shared = ProjectionControlLatencyMonitor()

    private struct PendingLatency {
        let id: UUID
        let action: String
        let origin: String
        let startedAt: Date
    }

    private struct CompletedLatency {
        let action: String
        let origin: String
        let projectionMs: Double
        let remoteMs: Double
    }

    private let lock = NSLock()
    private let logger = Logger(subsystem: "SkyPresenterPro", category: "ProjectionLatency")
    private var pending: [UUID: PendingLatency] = [:]
    private var projectionTimes: [UUID: Double] = [:]
    private var completed: [CompletedLatency] = []

    private init() {}

    @discardableResult
    func begin(action: String, origin: String) -> UUID {
        let token = UUID()
        lock.lock()
        trimStaleLocked()
        pending[token] = PendingLatency(id: token, action: action, origin: origin, startedAt: .now)
        lock.unlock()
        return token
    }

    func finishProjection(token: UUID) {
        lock.lock()
        guard let pending else {
            lock.unlock()
            return
        }
        projectionTimes[token] = Date().timeIntervalSince(pending.startedAt) * 1000
        lock.unlock()
    }

    func finishRemote(token: UUID) {
        lock.lock()
        guard let pending = pending.removeValue(forKey: token) else {
            lock.unlock()
            return
        }
        let projectionMs = projectionTimes.removeValue(forKey: token) ?? (Date().timeIntervalSince(pending.startedAt) * 1000)
        let remoteMs = Date().timeIntervalSince(pending.startedAt) * 1000
        completed.append(
            CompletedLatency(
                action: pending.action,
                origin: pending.origin,
                projectionMs: projectionMs,
                remoteMs: remoteMs
            )
        )
        if completed.count > 24 {
            completed.removeFirst(completed.count - 24)
        }
        let snapshot = snapshotLocked()
        lock.unlock()

        logger.debug("Latencia \(pending.action, privacy: .public) [\(pending.origin, privacy: .public)] proyección=\(projectionMs, format: .fixed(precision: 1))ms remoto=\(remoteMs, format: .fixed(precision: 1))ms \(snapshot, privacy: .public)")
    }

    func snapshot() -> String {
        lock.lock()
        trimStaleLocked()
        let value = snapshotLocked()
        lock.unlock()
        return value
    }

    private func averageProjectionLocked() -> Double {
        guard !completed.isEmpty else { return 0 }
        return completed.map(\.projectionMs).reduce(0, +) / Double(completed.count)
    }

    private func averageRemoteLocked() -> Double {
        guard !completed.isEmpty else { return 0 }
        return completed.map(\.remoteMs).reduce(0, +) / Double(completed.count)
    }

    private func snapshotLocked() -> String {
        "avgProjection=\(String(format: "%.1f", averageProjectionLocked()))ms avgRemote=\(String(format: "%.1f", averageRemoteLocked()))ms samples=\(completed.count) pending=\(pending.count)"
    }

    private func trimStaleLocked() {
        let staleThreshold = Date().addingTimeInterval(-5)
        let staleIDs = pending.values.filter { $0.startedAt < staleThreshold }.map(\.id)
        staleIDs.forEach {
            pending.removeValue(forKey: $0)
            projectionTimes.removeValue(forKey: $0)
        }
    }
}
