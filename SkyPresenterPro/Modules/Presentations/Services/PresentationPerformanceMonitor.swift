import Foundation
import OSLog

final class PresentationPerformanceMonitor {
    static let shared = PresentationPerformanceMonitor()

    private let lock = NSLock()
    private let logger = Logger(subsystem: "SkyPresenterPro", category: "PresentationsPerformance")

    private var importDurations: [Double] = []
    private var slideDurations: [Double] = []
    private var totalImportedPages = 0
    private var thumbnailHits = 0
    private var thumbnailMisses = 0
    private var thumbnailInFlightJoins = 0
    private var thumbnailGenerated = 0

    private init() {}

    func recordImport(duration: TimeInterval, pageCount: Int) {
        lock.lock()
        append(duration, to: &importDurations)
        totalImportedPages += pageCount
        let summary = snapshotLocked()
        lock.unlock()
        logger.debug("Importación PDF completada en \(duration, format: .fixed(precision: 3))s para \(pageCount) páginas. \(summary, privacy: .public)")
    }

    func recordSlideTransition(duration: TimeInterval, reason: String) {
        lock.lock()
        append(duration, to: &slideDurations)
        let summary = snapshotLocked()
        lock.unlock()
        logger.debug("Transición de slide [\(reason, privacy: .public)] en \(duration, format: .fixed(precision: 3))s. \(summary, privacy: .public)")
    }

    func recordThumbnailCacheHit() {
        lock.lock()
        thumbnailHits += 1
        lock.unlock()
    }

    func recordThumbnailCacheMiss() {
        lock.lock()
        thumbnailMisses += 1
        lock.unlock()
    }

    func recordThumbnailInFlightJoin() {
        lock.lock()
        thumbnailInFlightJoins += 1
        lock.unlock()
    }

    func recordThumbnailGenerated() {
        lock.lock()
        thumbnailGenerated += 1
        lock.unlock()
    }

    func snapshot() -> String {
        lock.lock()
        let summary = snapshotLocked()
        lock.unlock()
        return summary
    }

    private func append(_ value: Double, to values: inout [Double]) {
        values.append(value)
        if values.count > 12 {
            values.removeFirst(values.count - 12)
        }
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func snapshotLocked() -> String {
        let avgImport = average(importDurations)
        let avgSlide = average(slideDurations)
        return "avgImport=\(String(format: "%.3f", avgImport))s avgSlide=\(String(format: "%.3f", avgSlide))s pages=\(totalImportedPages) thumbHit=\(thumbnailHits) thumbMiss=\(thumbnailMisses) thumbJoin=\(thumbnailInFlightJoins) thumbGen=\(thumbnailGenerated)"
    }
}
