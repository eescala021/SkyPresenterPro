import AppKit
import Combine
import CoreImage.CIFilterBuiltins
import Foundation
import Network
import SwiftUI

struct RemoteControlSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var port: UInt16 = 8094
    var authToken: String = RemoteControlSettings.generateToken()
    var username: String = RemoteControlSettings.generateUsername()
    var password: String = RemoteControlSettings.generatePassword()
    var sessionTimeoutMinutes: Double = 30
    var exposesStatusToAuthenticatedClients: Bool = true
    var allowsBrowserApp: Bool = true
    var preferredHost: String = ""

    static func generateToken() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).map { String(format: "%02x", $0) }.joined()
    }

    static func generateUsername() -> String {
        "operador\(Int.random(in: 100...999))"
    }

    static func generatePassword() -> String {
        String(format: "%06d", Int.random(in: 0...999_999))
    }
}

private struct RemoteStatusPayload: Codable {
    let running: Bool
    let mode: String
    let projectorActive: Bool
    let currentSource: String
    let reference: String
    let body: String
    let mediaTitle: String
    let mediaSubtitle: String
    let frameKey: String
    let previousReference: String
    let previousBody: String
    let nextReference: String
    let nextBody: String
    let announcementText: String
    let announcementPriority: String
    let announcementType: String
    let announcementVisibleOnStage: Bool
}

private struct RemoteSessionResponse: Codable {
    let sessionToken: String
    let expiresAt: String
}

private struct RemoteLoginPayload: Codable {
    let username: String
    let password: String
    let deviceName: String?
}

struct RemoteDevicePermission: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var allowsStatus: Bool
    var allowsPresenter: Bool
    var allowsBible: Bool
    var allowsLyrics: Bool
    var allowsPresentations: Bool
    var lastSeenAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        allowsStatus: Bool = true,
        allowsPresenter: Bool = true,
        allowsBible: Bool = true,
        allowsLyrics: Bool = true,
        allowsPresentations: Bool = true,
        lastSeenAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.allowsStatus = allowsStatus
        self.allowsPresenter = allowsPresenter
        self.allowsBible = allowsBible
        self.allowsLyrics = allowsLyrics
        self.allowsPresentations = allowsPresentations
        self.lastSeenAt = lastSeenAt
    }
}

private struct RemoteSessionInfo {
    let id: String
    let deviceName: String
    let createdAt: Date
    let expiresAt: Date
    let deviceID: UUID?
}

struct RemoteSessionSummary: Identifiable, Equatable {
    let id: String
    let deviceName: String
    let createdAt: Date
    let expiresAt: Date
    let deviceID: UUID?
}

private struct RemoteBibleVersionSummary: Codable {
    let id: Int
    let title: String
    let language: String
}

private struct RemoteBibleBookSummary: Codable {
    let number: Int
    let name: String
}

private struct RemoteBibleVerseSummary: Codable {
    let number: Int
    let text: String
}

private struct RemoteSongSummary: Codable {
    let id: String
    let title: String
    let author: String
}

private struct RemoteSongSlideSummary: Codable {
    let id: String
    let title: String
    let body: String
    let source: String
}

private struct RemotePresentationSummary: Codable {
    let id: String
    let title: String
    let kind: String
    let pageCount: Int
}

private struct RemotePresentationPageSummary: Codable {
    let page: Int
    let label: String
}

private struct RemoteCommandPayload: Codable {
    let command: String
    let versionID: Int?
    let bookIndex: Int?
    let chapter: Int?
    let verse: Int?
    let songID: String?
    let slideSource: String?
    let presentationID: String?
    let pageIndex: Int?
    let announcementContent: String?
    let announcementType: String?
    let announcementPriority: String?
    let announcementDuration: Double?
}

private struct RemoteAnnouncementPayload: Codable {
    let content: String
    let type: String?
    let priority: String?
    let duration: Double?
}

private struct RemoteAnnouncementSummary: Codable {
    let id: String
    let content: String
    let type: String
    let priority: String
    let duration: Double
    let active: Bool
}

@MainActor
final class RemoteControlManager: ObservableObject {
    @Published var settings: RemoteControlSettings {
        didSet {
            persistSettings()
            guard !suppressSettingsRestart else { return }
            if settings.isEnabled != oldValue.isEnabled || settings.port != oldValue.port {
                restartIfNeeded()
            }
        }
    }
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var endpointHint: String = ""
    @Published private(set) var availableLocalHosts: [String] = []
    @Published private(set) var lastError: String?
    @Published private(set) var lastClientSummary: String = "Sin conexiones"
    @Published private(set) var lastSecurityEvent: String = "Sin alertas"
    @Published private(set) var activeSessionCount: Int = 0
    @Published private(set) var localNetworkPermissionStatus: String = "Aun no se ha solicitado el permiso de red local."
    @Published var registeredDevices: [RemoteDevicePermission] = [] {
        didSet { persistRegisteredDevices() }
    }
    @Published private(set) var sessionSummaries: [RemoteSessionSummary] = []

    private weak var displayManager: DisplayManager?
    private weak var bibleManager: BibleManager?
    private weak var songManager: SongManager?
    private weak var pdfManager: PDFManager?
    private weak var themeManager: ThemeManager?
    private weak var announcementManager: AnnouncementManager?
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var failedAuthAttempts: [Date] = []
    private var sessions: [String: RemoteSessionInfo] = [:]
    private var snapshotCache: (signature: String, frameData: Data, contentType: String)?
    private var thumbnailCache: [String: Data] = [:]
    private var permissionProbeConnection: NWConnection?
    private var suppressSettingsRestart: Bool = false
    private static let settingsKey = "RemoteControlManager.settings"
    private static let devicesKey = "RemoteControlManager.devices"
    private let authWindowSeconds: TimeInterval = 120
    private let authAttemptLimit: Int = 8

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(RemoteControlSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = RemoteControlSettings()
        }
        if let data = UserDefaults.standard.data(forKey: Self.devicesKey),
           let decoded = try? JSONDecoder().decode([RemoteDevicePermission].self, from: data) {
            self.registeredDevices = decoded
        }
        refreshAvailableHosts()
    }

    func configure(
        displayManager: DisplayManager,
        bibleManager: BibleManager,
        songManager: SongManager,
        pdfManager: PDFManager,
        themeManager: ThemeManager,
        announcementManager: AnnouncementManager
    ) {
        self.displayManager = displayManager
        self.bibleManager = bibleManager
        self.songManager = songManager
        self.pdfManager = pdfManager
        self.themeManager = themeManager
        self.announcementManager = announcementManager
        restartIfNeeded()
    }

    func updateEnabled(_ enabled: Bool) {
        settings.isEnabled = enabled
    }

    func updatePreferredHost(_ host: String) {
        updateSettingsWithoutRestart {
            settings.preferredHost = host
        }
        endpointHint = resolvedEndpointHint()
    }

    func regenerateToken() {
        updateSettingsWithoutRestart {
            settings.authToken = RemoteControlSettings.generateToken()
        }
        clearTransientServerErrorIfNeeded()
    }

    func regenerateCredentials() {
        updateSettingsWithoutRestart {
            settings.username = RemoteControlSettings.generateUsername()
            settings.password = RemoteControlSettings.generatePassword()
        }
        revokeAllSessions()
        clearTransientServerErrorIfNeeded()
    }

    func revokeAllSessions() {
        sessions.removeAll()
        refreshSessionSummaries()
        lastSecurityEvent = "Sesiones revocadas"
        clearTransientServerErrorIfNeeded()
    }

    func updateDevice(_ device: RemoteDevicePermission) {
        guard let index = registeredDevices.firstIndex(where: { $0.id == device.id }) else { return }
        registeredDevices[index] = device
        refreshSessionSummaries()
        clearTransientServerErrorIfNeeded()
    }

    func removeDevice(_ deviceID: UUID) {
        registeredDevices.removeAll { $0.id == deviceID }
        sessions = sessions.filter { $0.value.deviceID != deviceID }
        refreshSessionSummaries()
        lastSecurityEvent = "Dispositivo eliminado"
        clearTransientServerErrorIfNeeded()
    }

    func revokeSession(_ sessionID: String) {
        sessions.removeValue(forKey: sessionID)
        refreshSessionSummaries()
        lastSecurityEvent = "Sesión revocada"
        clearTransientServerErrorIfNeeded()
    }

    func revokeSessions(for deviceID: UUID) {
        sessions = sessions.filter { $0.value.deviceID != deviceID }
        refreshSessionSummaries()
        lastSecurityEvent = "Sesiones del dispositivo revocadas"
        clearTransientServerErrorIfNeeded()
    }

    func sessionCount(for deviceID: UUID) -> Int {
        sessionSummaries.filter { $0.deviceID == deviceID }.count
    }

    func requestLocalNetworkPermission() {
        guard settings.isEnabled else {
            localNetworkPermissionStatus = "Activa primero el control remoto para solicitar acceso de red local."
            return
        }

        guard isRunning else {
            localNetworkPermissionStatus = lastError?.isEmpty == false
            ? "El servidor remoto no está listo: \(lastError ?? "")"
            : "Primero asegúrate de que el servidor remoto esté activo."
            return
        }

        guard let host = localIPAddress() else {
            localNetworkPermissionStatus = "No se pudo detectar una IP local. Conecta el Mac a una red Wi‑Fi o Ethernet."
            return
        }

        permissionProbeConnection?.cancel()
        localNetworkPermissionStatus = "Solicitando acceso a la red local… revisa si macOS muestra el permiso."

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: settings.port) ?? 8094,
            using: .tcp
        )
        let currentConnection = connection

        connection.stateUpdateHandler = { [weak self, currentConnection] state in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch state {
                case .ready:
                    self.localNetworkPermissionStatus = "Acceso local disponible. Ya puedes conectar smartphones en la misma red."
                    currentConnection.cancel()
                case .waiting(let error):
                    if case .localNetworkDenied? = currentConnection.currentPath?.unsatisfiedReason {
                        self.localNetworkPermissionStatus = "macOS denegó la red local. Habilítala en Ajustes del Sistema > Privacidad y seguridad > Red local."
                    } else {
                        self.localNetworkPermissionStatus = "macOS está evaluando la red local… \(self.userFacingError(for: error))"
                    }
                case .failed(let error):
                    let message = self.userFacingError(for: error)
                    if message.localizedCaseInsensitiveContains("Connection refused") || message.localizedCaseInsensitiveContains("refused") {
                        self.localNetworkPermissionStatus = "La solicitud de red local se lanzó, pero el servidor todavía no estaba listo. Intenta de nuevo en unos segundos."
                    } else {
                        self.localNetworkPermissionStatus = "No se pudo completar la solicitud de red local: \(message)"
                    }
                case .cancelled:
                    break
                default:
                    break
                }
            }
        }

        permissionProbeConnection = connection
        connection.start(queue: .global(qos: .userInitiated))
    }

    var qrAccessPayload: String {
        endpointHint
    }

    var quickAccessURL: String {
        endpointHint
    }

    var fullAccessSummary: String {
        """
        URL: \(endpointHint)
        Usuario: \(settings.username)
        PIN: \(settings.password)
        Token: \(settings.authToken)
        """
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    private func persistRegisteredDevices() {
        guard let data = try? JSONEncoder().encode(registeredDevices) else { return }
        UserDefaults.standard.set(data, forKey: Self.devicesKey)
    }

    private func updateSettingsWithoutRestart(_ mutation: () -> Void) {
        suppressSettingsRestart = true
        mutation()
        suppressSettingsRestart = false
    }

    private func clearTransientServerErrorIfNeeded() {
        guard isRunning else { return }
        lastError = nil
        localNetworkPermissionStatus = "Acceso local disponible. Ya puedes conectar smartphones en la misma red."
    }

    private func restartIfNeeded() {
        stop()
        guard settings.isEnabled else { return }
        start()
    }

    private func start() {
        do {
            refreshAvailableHosts()
            let result = try makeListener(startingAt: settings.port)
            let listener = result.listener
            if result.port != settings.port {
                updateSettingsWithoutRestart {
                    settings.port = result.port
                }
                lastError = "El puerto configurado estaba ocupado. Se cambió automáticamente al puerto \(result.port)."
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    self?.handle(connection: connection)
                }
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.lastError = nil
                        self?.endpointHint = self?.resolvedEndpointHint() ?? ""
                    case .failed(let error):
                        self?.lastError = self?.userFacingError(for: error) ?? error.localizedDescription
                        self?.isRunning = false
                    case .cancelled:
                        self?.isRunning = false
                    default:
                        break
                    }
                }
            }
            listener.start(queue: .global(qos: .userInitiated))
            self.listener = listener
        } catch {
            lastError = userFacingError(for: error)
            isRunning = false
        }
    }

    private func makeListener(startingAt preferredPort: UInt16) throws -> (listener: NWListener, port: UInt16) {
        var candidatePorts: [UInt16] = []
        if preferredPort != 80 {
            candidatePorts.append(80)
        }
        candidatePorts.append(preferredPort)
        if preferredPort != 8094 {
            candidatePorts.append(8094)
        }
        let upperBound = min(Int(max(preferredPort, 8094)) + 20, Int(UInt16.max))
        candidatePorts.append(contentsOf: ((Int(max(preferredPort, 8094)) + 1)...upperBound).compactMap { UInt16(exactly: $0) })
        candidatePorts = Array(NSOrderedSet(array: candidatePorts)) as? [UInt16] ?? candidatePorts

        var lastFailure: Error?
        for candidate in candidatePorts {
            do {
                let port = NWEndpoint.Port(rawValue: candidate) ?? 8094
                let listener = try NWListener(using: .tcp, on: port)
                return (listener, candidate)
            } catch {
                lastFailure = error
                let description = error.localizedDescription.lowercased()
                let canContinue =
                    description.contains("address already in use") ||
                    description.contains("operation not permitted") ||
                    description.contains("permission denied")
                if !canContinue {
                    throw error
                }
            }
        }

        throw lastFailure ?? NSError(domain: "SkyPresenterRemote", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se encontró un puerto libre para el control remoto."])
    }

    private func stop() {
        listener?.cancel()
        listener = nil
        connections.forEach { $0.cancel() }
        connections.removeAll()
        isRunning = false
        endpointHint = ""
    }

    private func handle(connection: NWConnection) {
        connections.append(connection)
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let connection else { return }
            Task { @MainActor [weak self] in
                switch state {
                case .ready:
                    self?.lastClientSummary = "Cliente conectado"
                    self?.receive(on: connection)
                case .failed(let error):
                    self?.lastError = self?.userFacingError(for: error) ?? error.localizedDescription
                    self?.remove(connection: connection)
                case .cancelled:
                    self?.remove(connection: connection)
                default:
                    break
                }
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
    }

    private func remove(connection: NWConnection) {
        connections.removeAll { $0 === connection }
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256_000) { [weak self] data, _, _, _ in
            guard let self, let data, !data.isEmpty else {
                connection.cancel()
                return
            }
            Task { @MainActor in
                let response = self.handle(requestData: data)
                connection.send(content: response, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    private func handle(requestData: Data) -> Data {
        guard let requestString = String(data: requestData, encoding: .utf8) else {
            return httpResponse(status: "400 Bad Request", body: "Solicitud inválida", contentType: "text/plain")
        }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return httpResponse(status: "400 Bad Request", body: "Solicitud inválida", contentType: "text/plain")
        }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else {
            return httpResponse(status: "400 Bad Request", body: "Solicitud inválida", contentType: "text/plain")
        }

        let method = String(parts[0])
        let path = String(parts[1])

        guard !isAuthenticationTemporarilyBlocked else {
            lastSecurityEvent = "Bloqueo temporal por intentos fallidos"
            return httpResponse(status: "429 Too Many Requests", body: "Acceso temporalmente bloqueado", contentType: "text/plain")
        }

        if method == "POST", path.hasPrefix("/login") {
            return handleLogin(requestString: requestString)
        }

        if method == "POST", path.hasPrefix("/logout") {
            revokeSession(from: requestString)
            return httpResponse(status: "200 OK", body: "{\"ok\":true}", contentType: "application/json")
        }

        if method == "GET", path == "/", settings.allowsBrowserApp {
            return httpResponse(status: "200 OK", body: remoteWebAppPage, contentType: "text/html; charset=utf-8")
        }

        guard isAuthorized(requestString: requestString, path: path) else {
            registerFailedAuthentication()
            return httpResponse(status: "401 Unauthorized", body: "No autorizado", contentType: "text/plain")
        }

        if method == "GET", path.hasPrefix("/status"), settings.exposesStatusToAuthenticatedClients {
            guard hasPermission(for: requestString, area: .status, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            clearAuthenticationFailures()
            return jsonResponse(statusPayload)
        }

        clearAuthenticationFailures()

        if method == "GET", path.hasPrefix("/api/live/image") {
            guard hasPermission(for: requestString, area: .status, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            guard let frame = snapshotFrameData(path: path) else {
                return httpResponse(status: "204 No Content", body: "", contentType: "text/plain")
            }
            return binaryResponse(data: frame.data, contentType: frame.contentType)
        }

        if method == "GET", path.hasPrefix("/api/announcements") {
            guard hasPermission(for: requestString, area: .presenter, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let activeID = announcementManager?.activeAnnouncement?.id
            let payload = announcementManager?.queuedAnnouncements.map {
                RemoteAnnouncementSummary(
                    id: $0.id.uuidString,
                    content: $0.content,
                    type: $0.type.displayName,
                    priority: $0.priority.displayName,
                    duration: $0.duration,
                    active: $0.id == activeID
                )
            } ?? []
            return jsonResponse(payload)
        }

        if method == "POST", path.hasPrefix("/api/announcements/clear") {
            guard hasPermission(for: requestString, area: .presenter, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            announcementManager?.clearQueue()
            return httpResponse(status: "200 OK", body: "{\"ok\":true}", contentType: "application/json")
        }

        if method == "POST", path.hasPrefix("/api/announcements") {
            guard hasPermission(for: requestString, area: .presenter, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let body = requestString.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
            handleAnnouncementPayload(body)
            return httpResponse(status: "200 OK", body: "{\"ok\":true}", contentType: "application/json")
        }

        if method == "GET", path.hasPrefix("/api/bible/versions") {
            guard hasPermission(for: requestString, area: .bible, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let payload = bibleManager?.versions.map { RemoteBibleVersionSummary(id: $0.id, title: $0.title, language: $0.language) } ?? []
            return jsonResponse(payload)
        }

        if method == "GET", path.hasPrefix("/api/bible/books") {
            guard hasPermission(for: requestString, area: .bible, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
            let versionID = Int(query.first(where: { $0.name == "version" })?.value ?? "") ?? 0
            let books = bibleManager?.books(at: versionID).map { RemoteBibleBookSummary(number: $0.number, name: $0.name) } ?? []
            return jsonResponse(books)
        }

        if method == "GET", path.hasPrefix("/api/bible/chapters") {
            guard hasPermission(for: requestString, area: .bible, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
            let versionID = Int(query.first(where: { $0.name == "version" })?.value ?? "") ?? 0
            let bookIndex = Int(query.first(where: { $0.name == "book" })?.value ?? "") ?? 1
            let count = bibleManager?.chapterCount(at: versionID, bookIndex: bookIndex) ?? 0
            return jsonResponse(Array(1...max(count, 0)))
        }

        if method == "GET", path.hasPrefix("/api/bible/verses") {
            guard hasPermission(for: requestString, area: .bible, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
            let versionID = Int(query.first(where: { $0.name == "version" })?.value ?? "") ?? 0
            let bookIndex = Int(query.first(where: { $0.name == "book" })?.value ?? "") ?? 1
            let chapter = Int(query.first(where: { $0.name == "chapter" })?.value ?? "") ?? 1
            let verses = bibleManager?.verses(at: versionID, bookIndex: bookIndex, chapter: chapter).map {
                RemoteBibleVerseSummary(number: $0.number, text: $0.text)
            } ?? []
            return jsonResponse(verses)
        }

        if method == "GET", path.hasPrefix("/api/songs") {
            guard hasPermission(for: requestString, area: .lyrics, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let songs = songManager?.songs.map { RemoteSongSummary(id: $0.id.uuidString, title: $0.title, author: $0.author) } ?? []
            return jsonResponse(songs)
        }

        if method == "GET", path.hasPrefix("/api/song/slides") {
            guard hasPermission(for: requestString, area: .lyrics, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
            let songID = query.first(where: { $0.name == "id" })?.value ?? ""
            guard let uuid = UUID(uuidString: songID),
                  let song = songManager?.songs.first(where: { $0.id == uuid }) else {
                return jsonResponse([RemoteSongSlideSummary]())
            }
            let slides = song.presentationSlides.map { RemoteSongSlideSummary(id: $0.id, title: $0.title, body: $0.body, source: $0.source) }
            return jsonResponse(slides)
        }

        if method == "GET", path.hasPrefix("/api/song/slide-image") {
            guard hasPermission(for: requestString, area: .lyrics, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            guard let data = songSlideImageData(path: path) else {
                return httpResponse(status: "204 No Content", body: "", contentType: "text/plain")
            }
            return binaryResponse(data: data, contentType: "image/jpeg")
        }

        if method == "GET", path.hasPrefix("/api/presentations") {
            guard hasPermission(for: requestString, area: .presentations, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let items = pdfManager?.items.map {
                RemotePresentationSummary(id: $0.id.uuidString, title: $0.title, kind: $0.kind.rawValue, pageCount: pdfManager?.pageCount(for: $0) ?? 0)
            } ?? []
            return jsonResponse(items)
        }

        if method == "GET", path.hasPrefix("/api/presentation/pages") {
            guard hasPermission(for: requestString, area: .presentations, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
            let presentationID = query.first(where: { $0.name == "id" })?.value ?? ""
            guard let uuid = UUID(uuidString: presentationID),
                  let item = pdfManager?.items.first(where: { $0.id == uuid }) else {
                return jsonResponse([RemotePresentationPageSummary]())
            }
            let pages = (0..<(pdfManager?.pageCount(for: item) ?? 0)).map {
                RemotePresentationPageSummary(page: $0, label: item.kind == .pdf ? "Página \($0 + 1)" : "Recurso")
            }
            return jsonResponse(pages)
        }

        if method == "GET", path.hasPrefix("/api/presentation/page-image") {
            guard hasPermission(for: requestString, area: .presentations, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            guard let data = presentationPageImageData(path: path) else {
                return httpResponse(status: "204 No Content", body: "", contentType: "text/plain")
            }
            return binaryResponse(data: data, contentType: "image/jpeg")
        }

        if method == "POST", path.hasPrefix("/action") {
            guard hasPermission(for: requestString, area: .presenter, path: path) else {
                return httpResponse(status: "403 Forbidden", body: "Permiso denegado", contentType: "text/plain")
            }
            let body = requestString.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
            handleCommandPayload(body)
            return httpResponse(status: "200 OK", body: "{\"ok\":true}", contentType: "application/json")
        }

        return httpResponse(status: "404 Not Found", body: "No encontrado", contentType: "text/plain")
    }

    private func handleLogin(requestString: String) -> Data {
        let body = requestString.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
        guard let data = body.data(using: .utf8),
              let payload = try? JSONDecoder().decode(RemoteLoginPayload.self, from: data),
              payload.username == settings.username,
              payload.password == settings.password else {
            registerFailedAuthentication()
            return httpResponse(status: "401 Unauthorized", body: "No autorizado", contentType: "text/plain")
        }

        let deviceName = normalizedDeviceName(payload.deviceName)
        let device = deviceName.map(ensureRegisteredDevice(named:))
        let sessionToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let expiration = Date().addingTimeInterval(settings.sessionTimeoutMinutes * 60)
        sessions[sessionToken] = RemoteSessionInfo(
            id: sessionToken,
            deviceName: device?.name ?? deviceName ?? "Movil",
            createdAt: .now,
            expiresAt: expiration,
            deviceID: device?.id
        )
        refreshSessionSummaries()
        lastSecurityEvent = "Sesión móvil autenticada\(device.map { " · \($0.name)" } ?? "")"
        let formatter = ISO8601DateFormatter()
        clearAuthenticationFailures()
        return jsonResponse(RemoteSessionResponse(sessionToken: sessionToken, expiresAt: formatter.string(from: expiration)))
    }

    private func revokeSession(from requestString: String) {
        guard let token = extractBearerToken(from: requestString) else { return }
        sessions.removeValue(forKey: token)
        refreshSessionSummaries()
        lastSecurityEvent = "Sesión móvil cerrada"
    }

    private func isAuthorized(requestString: String, path: String) -> Bool {
        pruneExpiredSessions()

        if let token = extractBearerToken(from: requestString) {
            if sessions[token] != nil {
                return true
            }
            if token == settings.authToken {
                return true
            }
        }

        if let credentials = extractBasicCredentials(from: requestString),
           credentials.username == settings.username,
           credentials.password == settings.password {
            return true
        }

        let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
        if let sessionToken = query.first(where: { $0.name == "session" })?.value, sessions[sessionToken] != nil {
            return true
        }
        return query.first(where: { $0.name == "token" })?.value == settings.authToken
    }

    private enum RemotePermissionArea {
        case status
        case presenter
        case bible
        case lyrics
        case presentations
    }

    private func hasPermission(for requestString: String, area: RemotePermissionArea, path: String) -> Bool {
        guard let device = authenticatedDevice(from: requestString, path: path) else {
            return true
        }

        guard device.isEnabled else { return false }

        switch area {
        case .status:
            return device.allowsStatus
        case .presenter:
            return device.allowsPresenter
        case .bible:
            return device.allowsBible
        case .lyrics:
            return device.allowsLyrics
        case .presentations:
            return device.allowsPresentations
        }
    }

    private func authenticatedDevice(from requestString: String, path: String) -> RemoteDevicePermission? {
        if let token = extractBearerToken(from: requestString),
           let session = sessions[token],
           let deviceID = session.deviceID {
            return touchDevice(id: deviceID)
        }

        let query = URLComponents(string: "http://localhost\(path)")?.queryItems ?? []
        if let sessionToken = query.first(where: { $0.name == "session" })?.value,
           let session = sessions[sessionToken],
           let deviceID = session.deviceID {
            return touchDevice(id: deviceID)
        }

        return nil
    }

    private func touchDevice(id: UUID) -> RemoteDevicePermission? {
        guard let index = registeredDevices.firstIndex(where: { $0.id == id }) else { return nil }
        registeredDevices[index].lastSeenAt = .now
        return registeredDevices[index]
    }

    private func extractBasicCredentials(from requestString: String) -> (username: String, password: String)? {
        guard let authLine = requestString.components(separatedBy: "\r\n").first(where: { $0.lowercased().hasPrefix("authorization: basic ") }),
              let encoded = authLine.components(separatedBy: " ").last,
              let data = Data(base64Encoded: encoded),
              let credentials = String(data: data, encoding: .utf8) else { return nil }
        let parts = credentials.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }

    private func extractBearerToken(from requestString: String) -> String? {
        guard let authLine = requestString.components(separatedBy: "\r\n").first(where: { $0.lowercased().hasPrefix("authorization: bearer ") }) else {
            return nil
        }
        return authLine.replacingOccurrences(of: "Authorization: Bearer ", with: "")
            .replacingOccurrences(of: "authorization: bearer ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleCommandPayload(_ body: String) {
        guard let data = body.data(using: .utf8),
              let payload = try? JSONDecoder().decode(RemoteCommandPayload.self, from: data) else { return }

        switch payload.command {
        case "next":
            NotificationCenter.default.post(name: .remoteNavigateNext, object: nil)
        case "previous":
            NotificationCenter.default.post(name: .remoteNavigatePrevious, object: nil)
        case "clear":
            displayManager?.clearProjection()
        case "logo":
            displayManager?.showLogo()
        case "blank":
            displayManager?.showBlankTheme()
        case "blackout":
            displayManager?.showBlackout()
        case "escape":
            if displayManager?.restorePresentationProjectionIfNeeded() != true {
                displayManager?.endProjection()
            }
        case "project_bible_verse":
            projectBibleVerse(payload)
        case "project_song_slide":
            projectSongSlide(payload)
        case "project_presentation_page":
            projectPresentationPage(payload)
        case "project_current":
            reprojectCurrent()
        case "trigger_announcement":
            triggerAnnouncement(payload)
        case "clear_announcements":
            announcementManager?.clearQueue()
        default:
            break
        }
    }

    private func handleAnnouncementPayload(_ body: String) {
        guard let data = body.data(using: .utf8),
              let payload = try? JSONDecoder().decode(RemoteAnnouncementPayload.self, from: data) else { return }
        let type = AnnouncementType.allCases.first(where: { $0.matches(payload.type ?? "") }) ?? .scrolling
        let priority = AnnouncementPriority.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(payload.priority ?? "") == .orderedSame ||
            $0.displayName.caseInsensitiveCompare(payload.priority ?? "") == .orderedSame
        }) ?? .normal
        announcementManager?.triggerQuickAnnouncement(
            content: payload.content,
            priority: priority,
            type: type,
            duration: payload.duration ?? 18
        )
    }

    private func triggerAnnouncement(_ payload: RemoteCommandPayload) {
        let type = AnnouncementType.allCases.first(where: { $0.matches(payload.announcementType ?? "") }) ?? .scrolling
        let priority = AnnouncementPriority.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(payload.announcementPriority ?? "") == .orderedSame ||
            $0.displayName.caseInsensitiveCompare(payload.announcementPriority ?? "") == .orderedSame
        }) ?? .breaking
        announcementManager?.triggerQuickAnnouncement(
            content: payload.announcementContent ?? "",
            priority: priority,
            type: type,
            duration: payload.announcementDuration ?? 18
        )
    }

    private func reprojectCurrent() {
        guard let displayManager else { return }
        switch displayManager.projectionMode {
        case .content:
            if let payload = displayManager.currentProjection {
                displayManager.project(source: payload.source, reference: payload.reference, body: payload.body)
            }
        case .media:
            if let media = displayManager.currentMediaProjection {
                let state = presentationState(for: media.source)
                guard
               let item = state.item,
               let image = pdfManager?.image(for: item, pageIndex: state.page)
                else { return }
                displayManager.projectMedia(source: media.source, title: media.title, subtitle: media.subtitle, image: image)
            }
        case .logo:
            displayManager.showLogo()
        case .blankTheme:
            displayManager.showBlankTheme()
        case .blackout:
            displayManager.showBlackout()
        }
    }

    private func projectBibleVerse(_ payload: RemoteCommandPayload) {
        guard let versionID = payload.versionID,
              let bookIndex = payload.bookIndex,
              let chapter = payload.chapter,
              let verseNumber = payload.verse,
              let version = bibleManager?.version(at: versionID),
              let book = bibleManager?.books(at: versionID).first(where: { $0.number == bookIndex }),
              let verse = bibleManager?.verseText(at: versionID, bookIndex: bookIndex, chapter: chapter, verse: verseNumber) else { return }

        let reference: String
        if displayManager?.bibleProjectionSettings.showsVersionInReference == true {
            reference = "\(book.name) \(chapter):\(verseNumber) (\(version.title))"
        } else {
            reference = "\(book.name) \(chapter):\(verseNumber)"
        }
        displayManager?.project(source: "bible:\(versionID):\(bookIndex):\(chapter):\(verseNumber)", reference: reference, body: verse)
    }

    private func projectSongSlide(_ payload: RemoteCommandPayload) {
        guard let songID = payload.songID,
              let uuid = UUID(uuidString: songID),
              let song = songManager?.songs.first(where: { $0.id == uuid }) else { return }

        if let slideSource = payload.slideSource,
           let slide = song.presentationSlides.first(where: { $0.source == slideSource }) {
            displayManager?.project(source: slide.source, reference: slide.reference, body: slide.body)
            return
        }

        if let slide = song.presentationSlides.first {
            displayManager?.project(source: slide.source, reference: slide.reference, body: slide.body)
        }
    }

    private func projectPresentationPage(_ payload: RemoteCommandPayload) {
        guard let presentationID = payload.presentationID,
              let uuid = UUID(uuidString: presentationID),
              let item = pdfManager?.items.first(where: { $0.id == uuid }),
              let pageIndex = payload.pageIndex,
              let image = pdfManager?.image(for: item, pageIndex: pageIndex) else { return }

        let subtitle = item.kind == .pdf ? "Página \(pageIndex + 1)" : item.kind.rawValue
        displayManager?.projectMedia(source: "media:\(item.id.uuidString):\(pageIndex)", title: item.title, subtitle: subtitle, image: image)
    }

    private var statusPayload: RemoteStatusPayload {
        let mode: String
        switch displayManager?.projectionMode {
        case .content: mode = "content"
        case .media: mode = "media"
        case .logo: mode = "logo"
        case .blankTheme: mode = "blank"
        case .blackout: mode = "blackout"
        case .none: mode = "none"
        }
        let previous = previewNeighbors.previous
        let next = previewNeighbors.next
        let overlaySource = displayManager?.currentProjection?.source ?? ""
        let effectiveSource: String
        if overlaySource.hasPrefix("bible-from-media:"),
           let fallbackMediaSource = displayManager?.currentMediaProjection?.source {
            effectiveSource = fallbackMediaSource
        } else {
            effectiveSource = overlaySource.isEmpty ? (displayManager?.currentMediaProjection?.source ?? "") : overlaySource
        }

        return RemoteStatusPayload(
            running: isRunning,
            mode: mode,
            projectorActive: displayManager?.isProjectorActive == true,
            currentSource: effectiveSource,
            reference: displayManager?.currentProjection?.reference ?? "",
            body: displayManager?.currentProjection?.body ?? "",
            mediaTitle: displayManager?.currentMediaProjection?.title ?? "",
            mediaSubtitle: displayManager?.currentMediaProjection?.subtitle ?? "",
            frameKey: snapshotSignature,
            previousReference: previous.0,
            previousBody: previous.1,
            nextReference: next.0,
            nextBody: next.1,
            announcementText: announcementManager?.activeAnnouncement?.content ?? "",
            announcementPriority: announcementManager?.activeAnnouncement?.priority.displayName ?? "",
            announcementType: announcementManager?.activeAnnouncement?.type.displayName ?? "",
            announcementVisibleOnStage: announcementManager?.stageVisibleAnnouncement != nil
        )
    }

    private var previewNeighbors: (previous: (String, String), next: (String, String)) {
        guard let displayManager else { return (("", ""), ("", "")) }

        if displayManager.projectionMode == .content,
           let source = displayManager.currentProjection?.source,
           source.hasPrefix("song:"),
           let song = songManager?.songs.first(where: { $0.presentationSlides.contains(where: { $0.source == source }) }),
           let index = song.presentationSlides.firstIndex(where: { $0.source == source }) {
            let previousIndex = max(index - 1, 0)
            let nextIndex = min(index + 1, song.presentationSlides.count - 1)
            let previous = song.presentationSlides[previousIndex]
            let next = song.presentationSlides[nextIndex]
            return ((previous.reference, previous.body), (next.reference, next.body))
        }

        if displayManager.projectionMode == .media,
           let source = displayManager.currentMediaProjection?.source {
            let state = presentationState(for: source)
            if let item = state.item {
                let maxPage = max((pdfManager?.pageCount(for: item) ?? 1) - 1, 0)
                let previousPage = max(state.page - 1, 0)
                let nextPage = min(state.page + 1, maxPage)
                let previousLabel = item.kind == .pdf ? "Página \(previousPage + 1)" : item.kind.rawValue
                let nextLabel = item.kind == .pdf ? "Página \(nextPage + 1)" : item.kind.rawValue
                return ((item.title, previousLabel), (item.title, nextLabel))
            }
        }

        return (("", ""), ("", ""))
    }

    private func presentationState(for source: String) -> (item: MediaItem?, page: Int) {
        guard source.hasPrefix("media:") else { return (nil, 0) }
        let components = source.split(separator: ":")
        guard components.count >= 3,
              let uuid = UUID(uuidString: String(components[1])),
              let page = Int(components[2]) else {
            return (nil, 0)
        }
        return (pdfManager?.items.first(where: { $0.id == uuid }), page)
    }

    private func snapshotFrameData() -> (data: Data, contentType: String)? {
        snapshotFrameData(path: nil)
    }

    private func snapshotFrameData(path: String?) -> (data: Data, contentType: String)? {
        let targetSize = requestedFrameSize(path: path)
        let signature = "\(snapshotSignature)-\(Int(targetSize.width))x\(Int(targetSize.height))"
        if let cache = snapshotCache, cache.signature == signature {
            return (cache.frameData, cache.contentType)
        }

        let frame: (Data, String)?
        if displayManager?.projectionMode == .media, let image = displayManager?.currentMediaImage {
            frame = resizedImage(image, targetSize: targetSize)?.jpegData(quality: 0.68).map { ($0, "image/jpeg") }
        } else if let displayManager, let themeManager, let announcementManager {
            let snapshotView = Projector(isExternalDisplay: false)
                .environmentObject(displayManager)
                .environmentObject(themeManager)
                .environmentObject(announcementManager)
                .frame(width: targetSize.width, height: targetSize.height)
            let renderer = ImageRenderer(content: snapshotView)
            renderer.scale = 1
            frame = renderer.nsImage?.jpegData(quality: 0.72).map { ($0, "image/jpeg") }
        } else {
            frame = nil
        }

        if let frame {
            snapshotCache = (signature, frame.0, frame.1)
        }
        return frame.map { (data: $0.0, contentType: $0.1) }
    }

    private func songSlideImageData(path: String) -> Data? {
        guard let query = URLComponents(string: "http://localhost\(path)")?.queryItems,
              let songID = query.first(where: { $0.name == "id" })?.value,
              let slideSource = query.first(where: { $0.name == "source" })?.value,
              let uuid = UUID(uuidString: songID),
              let song = songManager?.songs.first(where: { $0.id == uuid }),
              let slide = song.presentationSlides.first(where: { $0.source == slideSource }),
              let displayManager,
              let themeManager else { return nil }
        let cacheKey = "song-thumb-\(songID)-\(slideSource)-\(themeManager.themeSettings.kind.rawValue)-\(themeManager.themeSettings.gradientPreset.rawValue)"
        if let cached = thumbnailCache[cacheKey] {
            return cached
        }

        let content = ZStack {
            Group {
                switch themeManager.themeSettings.kind {
                case .gradient:
                    themeManager.themeSettings.gradientPreset.gradient
                case .image:
                    if let image = themeManager.backgroundImage {
                        Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        GradientPreset.midnight.gradient
                    }
                case .video:
                    if let thumb = themeManager.videoThumbnail {
                        Image(nsImage: thumb).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        GradientPreset.midnight.gradient
                    }
                }
            }

            ProjectionContentCanvas(
                payload: ProjectionPayload(source: slide.source, reference: slide.reference, body: slide.body),
                settings: displayManager.projectionStyleSettings,
                size: CGSize(width: 640, height: 360)
            )
        }
        .frame(width: 640, height: 360)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        let data = renderer.nsImage?.jpegData(quality: 0.64)
        if let data {
            thumbnailCache[cacheKey] = data
        }
        return data
    }

    private func presentationPageImageData(path: String) -> Data? {
        guard let query = URLComponents(string: "http://localhost\(path)")?.queryItems,
              let presentationID = query.first(where: { $0.name == "id" })?.value,
              let pageValue = query.first(where: { $0.name == "page" })?.value,
              let uuid = UUID(uuidString: presentationID),
              let page = Int(pageValue),
              let item = pdfManager?.items.first(where: { $0.id == uuid }) else { return nil }
        let cacheKey = "presentation-thumb-\(presentationID)-\(page)"
        if let cached = thumbnailCache[cacheKey] {
            return cached
        }
        guard let image = pdfManager?.image(for: item, pageIndex: page, targetSize: CGSize(width: 640, height: 360)) else { return nil }
        let data = image.jpegData(quality: 0.68)
        if let data {
            thumbnailCache[cacheKey] = data
        }
        return data
    }

    private func requestedFrameSize(path: String?) -> CGSize {
        guard let path,
              let query = URLComponents(string: "http://localhost\(path)")?.queryItems,
              let widthValue = query.first(where: { $0.name == "width" })?.value,
              let width = Double(widthValue) else {
            return CGSize(width: 960, height: 540)
        }

        let clampedWidth = min(max(width, 320), 1280)
        let roundedWidth = ceil(clampedWidth / 80) * 80
        return CGSize(width: roundedWidth, height: roundedWidth * 9 / 16)
    }

    private func resizedImage(_ image: NSImage, targetSize: CGSize) -> NSImage? {
        let ratio = min(targetSize.width / max(image.size.width, 1), targetSize.height / max(image.size.height, 1), 1)
        let size = CGSize(width: max(image.size.width * ratio, 1), height: max(image.size.height * ratio, 1))
        let output = NSImage(size: size)
        output.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: size))
        output.unlockFocus()
        return output
    }

    private var snapshotSignature: String {
        let themeSignature: String
        if let themeManager {
            themeSignature = "\(themeManager.themeSettings.kind.rawValue)-\(themeManager.themeSettings.gradientPreset.rawValue)-\(themeManager.activeImageID?.uuidString ?? "none")-\(themeManager.activeVideoID?.uuidString ?? "none")"
        } else {
            themeSignature = "no-theme"
        }
        let announcementSignature: String
        if let announcement = announcementManager?.activeAnnouncement {
            announcementSignature = "\(announcement.id.uuidString)-\(announcement.priority.rawValue)-\(announcement.type.rawValue)-\(announcement.content)"
        } else {
            announcementSignature = "no-announcement"
        }

        switch displayManager?.projectionMode {
        case .content:
            return "content-\(displayManager?.currentProjection?.source ?? "none")-\(displayManager?.currentProjection?.reference ?? "")-\(displayManager?.currentProjection?.body ?? "")-\(themeSignature)-\(announcementSignature)"
        case .media:
            return "media-\(displayManager?.currentMediaProjection?.source ?? "none")-\(announcementSignature)"
        case .logo:
            return "logo-\(displayManager?.churchName ?? "")-\(announcementSignature)"
        case .blankTheme:
            return "blank-\(themeSignature)-\(announcementSignature)"
        case .blackout:
            return "blackout-\(Date().formatted(date: .omitted, time: .shortened))-\(announcementSignature)"
        case .none:
            return "none-\(themeSignature)-\(announcementSignature)"
        }
    }

    private var isAuthenticationTemporarilyBlocked: Bool {
        pruneExpiredAuthFailures()
        return failedAuthAttempts.count >= authAttemptLimit
    }

    private func registerFailedAuthentication() {
        failedAuthAttempts.append(Date())
        pruneExpiredAuthFailures()
        lastSecurityEvent = "Intento fallido \(failedAuthAttempts.count)/\(authAttemptLimit)"
    }

    private func clearAuthenticationFailures() {
        failedAuthAttempts.removeAll()
        lastSecurityEvent = "Sin alertas"
    }

    private func pruneExpiredAuthFailures() {
        let cutoff = Date().addingTimeInterval(-authWindowSeconds)
        failedAuthAttempts.removeAll { $0 < cutoff }
    }

    private func pruneExpiredSessions() {
        let now = Date()
        sessions = sessions.filter { $0.value.expiresAt > now }
        let cutoff = now.addingTimeInterval(-(settings.sessionTimeoutMinutes * 60))
        registeredDevices.removeAll { device in
            device.lastSeenAt < cutoff && sessions.values.contains(where: { $0.deviceID == device.id }) == false
        }
        refreshSessionSummaries()
    }

    private func refreshSessionSummaries() {
        let sorted = sessions.values
            .map {
                RemoteSessionSummary(
                    id: $0.id,
                    deviceName: $0.deviceName,
                    createdAt: $0.createdAt,
                    expiresAt: $0.expiresAt,
                    deviceID: $0.deviceID
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
        sessionSummaries = sorted
        activeSessionCount = sorted.count
    }

    private func normalizedDeviceName(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(50))
    }

    private func ensureRegisteredDevice(named name: String) -> RemoteDevicePermission {
        if let index = registeredDevices.firstIndex(where: { $0.name == name }) {
            registeredDevices[index].lastSeenAt = .now
            return registeredDevices[index]
        }

        let device = RemoteDevicePermission(name: name, lastSeenAt: .now)
        registeredDevices.append(device)
        return device
    }

    private func resolvedEndpointHint() -> String {
        let host = settings.preferredHost.isEmpty ? (availableLocalHosts.first ?? localIPAddress() ?? "127.0.0.1") : settings.preferredHost
        return settings.port == 80 ? "http://\(host)" : "http://\(host):\(settings.port)"
    }

    private func refreshAvailableHosts() {
        availableLocalHosts = localIPAddresses()
        if settings.preferredHost.isEmpty {
            settings.preferredHost = availableLocalHosts.first ?? ""
        } else if availableLocalHosts.contains(settings.preferredHost) == false {
            settings.preferredHost = availableLocalHosts.first ?? ""
        }
    }

    private func localIPAddress() -> String? {
        localIPAddresses().first
    }

    private func localIPAddresses() -> [String] {
        var addresses: [String] = []
        var fallbackAddress: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            let family = interface.ifa_addr.pointee.sa_family
            guard family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name == "en1" || name == "bridge0" || name == "pdp_ip0" else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            let value = String(cString: host)
            if !value.hasPrefix("127.") {
                if addresses.contains(value) == false {
                    addresses.append(value)
                }
            }
            fallbackAddress = value
        }

        if addresses.isEmpty, let fallbackAddress {
            return [fallbackAddress]
        }
        return addresses.sorted()
    }

    private func userFacingError(for error: Error) -> String {
        let description = error.localizedDescription
        if description.localizedCaseInsensitiveContains("operation not permitted") {
            return "macOS no permitió usar ese puerto. La app intentará usar otro automáticamente. Si el problema persiste, revisa permisos de red local."
        }
        if description.localizedCaseInsensitiveContains("address already in use") {
            return "La app no pudo usar el puerto inicial y seguirá intentando con otro puerto disponible automáticamente."
        }
        if description.localizedCaseInsensitiveContains("connection refused") {
            return "El servidor remoto no respondió todavía. Intenta de nuevo en unos segundos."
        }
        return description
    }

    private func jsonResponse<T: Encodable>(_ value: T) -> Data {
        guard let data = try? JSONEncoder().encode(value),
              let body = String(data: data, encoding: .utf8) else {
            return httpResponse(status: "500 Internal Server Error", body: "{}", contentType: "application/json")
        }
        return httpResponse(status: "200 OK", body: body, contentType: "application/json")
    }

    private func binaryResponse(data: Data, contentType: String) -> Data {
        var header = "HTTP/1.1 200 OK\r\n"
        header += "Content-Type: \(contentType)\r\n"
        header += "Content-Length: \(data.count)\r\n"
        header += "Connection: close\r\n"
        header += "Access-Control-Allow-Origin: *\r\n"
        header += "Cache-Control: no-store, no-cache, must-revalidate\r\n"
        header += "\r\n"
        return Data(header.utf8) + data
    }

    private func httpResponse(status: String, body: String, contentType: String) -> Data {
        let response = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Headers: Authorization, Content-Type\r
        Cache-Control: no-store, no-cache, must-revalidate\r
        \r
        \(body)
        """
        return Data(response.utf8)
    }

    private var appVersionString: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(SkyPresenterVersion.internalRelease) (\(build))"
    }

    private var remoteWebAppPage: String {
        RemoteWebAppPage.html(appVersionString: appVersionString)
    }

    // Legacy remote HTML removed. The active web client is `remoteWebAppPage`.
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension NSImage {
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    func jpegData(quality: CGFloat) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: max(0.1, min(quality, 1))])
    }
}
