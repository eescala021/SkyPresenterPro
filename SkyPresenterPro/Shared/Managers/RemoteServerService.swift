// Archivo: RemoteServerService.swift
// Función: Servidor HTTP local real usando Network.framework (NWListener).
// Contiene: RemoteServerService, ServerStateSnapshot, SessionStore, HTTPRequest, HTTPResponseBuilder.
// Uso: Sirve la web app remota en GET / y expone la API REST completa en el puerto 8080.

import Combine
import Foundation
import Network
import Darwin

// MARK: - Thread-safe state snapshot (leído desde background sin capturar self)

private final class ServerStateSnapshot: @unchecked Sendable {
    private let lock = NSLock()
    private var _pin: String = ""
    private var _isRunning: Bool = false
    private var _ip: String = "127.0.0.1"

    func update(pin: String, isRunning: Bool, ip: String = "127.0.0.1") {
        lock.lock(); defer { lock.unlock() }
        _pin = pin
        _isRunning = isRunning
        _ip = ip
    }

    var pin: String {
        lock.lock(); defer { lock.unlock() }
        return _pin
    }

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isRunning
    }

    var ip: String {
        lock.lock(); defer { lock.unlock() }
        return _ip
    }
}

// MARK: - Thread-safe connection counter

private final class ConnectionCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    @discardableResult
    func increment() -> Int {
        lock.lock(); defer { lock.unlock() }
        _count += 1; return _count
    }

    @discardableResult
    func decrement() -> Int {
        lock.lock(); defer { lock.unlock() }
        _count = max(0, _count - 1); return _count
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return _count
    }
}

// MARK: - Thread-safe session store (HTTP layer — no MainActor needed)

private final class SessionStore: @unchecked Sendable {
    private let lock = NSLock()
    private var _sessions: [String: Date] = [:]    // token → expiresAt

    @discardableResult
    func create() -> (token: String, expiresAt: Date) {
        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let expires = Date().addingTimeInterval(8 * 3600)   // 8 horas
        lock.lock(); defer { lock.unlock() }
        _sessions[token] = expires
        return (token, expires)
    }

    func isValid(_ token: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let exp = _sessions[token] else { return false }
        if exp < Date() { _sessions.removeValue(forKey: token); return false }
        return true
    }

    func revoke(_ token: String) {
        lock.lock(); defer { lock.unlock() }
        _sessions.removeValue(forKey: token)
    }

    func revokeAll() {
        lock.lock(); defer { lock.unlock() }
        _sessions.removeAll()
    }
}

// MARK: - Minimal HTTP parser (GET + POST, headers, body)

private struct HTTPRequest {
    let method: String
    let path: String
    let query: [String: String]
    let headers: [String: String]
    let body: String
    let rawBody: Data

    static func parse(_ raw: String, rawData: Data) -> HTTPRequest? {
        // Split headers from body on \r\n\r\n
        let separator = "\r\n\r\n"
        guard let sepRange = raw.range(of: separator) else { return nil }
        let headerSection = String(raw[..<sepRange.lowerBound])
        let bodyString = String(raw[sepRange.upperBound...])

        // Parse first line
        let lines = headerSection.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { return nil }
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }

        let method = parts[0]
        let fullPath = parts[1]
        var path = fullPath
        var query: [String: String] = [:]

        if let qMark = fullPath.firstIndex(of: "?") {
            path = String(fullPath[..<qMark])
            let qs = String(fullPath[fullPath.index(after: qMark)...])
            for pair in qs.components(separatedBy: "&") {
                let kv = pair.components(separatedBy: "=")
                if kv.count == 2 {
                    query[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
                }
            }
        }

        // Parse headers (skip first line)
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            if let colonRange = line.range(of: ":") {
                let key = String(line[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces).lowercased()
                let value = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }

        // Extract body bytes (everything after the double CRLF)
        let rawBody: Data
        if let sepDataRange = rawData.range(of: Data("\r\n\r\n".utf8)) {
            rawBody = rawData.subdata(in: sepDataRange.upperBound..<rawData.endIndex)
        } else {
            rawBody = Data()
        }

        return HTTPRequest(method: method, path: path, query: query,
                           headers: headers, body: bodyString, rawBody: rawBody)
    }

    /// Extrae el Bearer token del header Authorization.
    var bearerToken: String? {
        guard let auth = headers["authorization"],
              auth.hasPrefix("Bearer ") else { return nil }
        return String(auth.dropFirst(7)).trimmingCharacters(in: .whitespaces)
    }

    /// Parsea el body como JSON → [String: Any]
    var jsonBody: [String: Any]? {
        guard !rawBody.isEmpty else { return nil }
        return try? JSONSerialization.jsonObject(with: rawBody) as? [String: Any]
    }
}

// MARK: - HTTP response builder

private enum HTTPResponseBuilder {
    static func html(_ body: String, status: Int = 200) -> Data {
        let header = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: text/html; charset=utf-8\r\n" +
            "Access-Control-Allow-Origin: *\r\n" +
            "Content-Length: \(body.utf8.count)\r\n" +
            "Connection: close\r\n\r\n"
        var d = Data(header.utf8)
        d.append(Data(body.utf8))
        return d
    }

    static func json(_ body: String, status: Int = 200) -> Data {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 204: statusText = "No Content"
        case 401: statusText = "Unauthorized"
        case 403: statusText = "Forbidden"
        case 404: statusText = "Not Found"
        default:  statusText = "Error"
        }
        let header = "HTTP/1.1 \(status) \(statusText)\r\n" +
            "Content-Type: application/json; charset=utf-8\r\n" +
            "Access-Control-Allow-Origin: *\r\n" +
            "Access-Control-Allow-Headers: Authorization, Content-Type\r\n" +
            "Content-Length: \(body.utf8.count)\r\n" +
            "Connection: close\r\n\r\n"
        return Data((header + body).utf8)
    }

    static func options() -> Data {
        let header = "HTTP/1.1 204 No Content\r\n" +
            "Access-Control-Allow-Origin: *\r\n" +
            "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
            "Access-Control-Allow-Headers: Authorization, Content-Type\r\n" +
            "Connection: close\r\n\r\n"
        return Data(header.utf8)
    }

    static func notFound()    -> Data { json("{\"error\":\"not_found\"}",    status: 404) }
    static func unauthorized() -> Data { json("{\"error\":\"invalid_pin\"}", status: 401) }

    /// Escapa caracteres JSON básicos en un String.
    static func jsonEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
         .replacingOccurrences(of: "\r", with: "\\r")
    }
}

// MARK: - RemoteServerService

@MainActor
final class RemoteServerService: ObservableObject {

    @Published private(set) var serverState = RemoteServerState()

    /// Servicios opcionales para enriquecer respuestas — asignados post-init por AppEnvironment.
    var deviceRegistry: RemoteDeviceRegistry?
    var sessionManager: RemoteSessionManager?

    private var listener: NWListener?
    private let serverQueue  = DispatchQueue(label: "com.skypresenterpro.remote.server", qos: .utility)
    private let snapshot     = ServerStateSnapshot()
    private let connections  = ConnectionCounter()
    private let sessions     = SessionStore()
    private let defaultPort: UInt16 = 8080

    // MARK: - Public API

    func start() {
        guard !serverState.isRunning else { return }

        let ip  = detectedLocalIP() ?? "127.0.0.1"
        let pin = generatePIN()

        guard let nwPort = NWEndpoint.Port(rawValue: defaultPort) else { return }

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: nwPort)
        } catch {
            return
        }

        serverState = RemoteServerState(
            isRunning: true,
            serverURL: "http://\(ip):\(defaultPort)",
            port: Int(defaultPort),
            pin: pin,
            detectedIPAddress: ip
        )
        snapshot.update(pin: pin, isRunning: true, ip: ip)

        // Captura valores locales — evita capturar self en los closures de background
        let capturedSnapshot    = snapshot
        let capturedConnections = connections
        let capturedSessions    = sessions
        let capturedQueue       = serverQueue

        listener?.newConnectionHandler = { [weak self] connection in
            let remoteIP = Self.extractIP(from: connection)
            capturedConnections.increment()

            Task { @MainActor [weak self] in
                let device = RemoteDevice(name: "Remoto", ipAddress: remoteIP)
                self?.deviceRegistry?.registerDevice(device)
            }

            Self.handleHTTP(
                connection: connection,
                queue: capturedQueue,
                snapshot: capturedSnapshot,
                sessions: capturedSessions
            ) {
                capturedConnections.decrement()
                Task { @MainActor [weak self] in
                    self?.deviceRegistry?.connectedDevices
                        .filter { $0.ipAddress == remoteIP }
                        .forEach { self?.deviceRegistry?.removeDevice(id: $0.id) }
                }
            }
        }

        listener?.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                Task { @MainActor [weak self] in
                    self?.serverState.isRunning = false
                    self?.snapshot.update(pin: "", isRunning: false)
                }
            }
        }

        listener?.start(queue: serverQueue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        sessions.revokeAll()
        deviceRegistry?.clearAll()
        sessionManager?.revokeAllSessions()

        serverState = RemoteServerState(
            isRunning: false,
            serverURL: "",
            port: Int(defaultPort),
            pin: "",
            detectedIPAddress: serverState.detectedIPAddress
        )
        snapshot.update(pin: "", isRunning: false)
    }

    func toggle() {
        serverState.isRunning ? stop() : start()
    }

    func regeneratePIN() {
        let newPIN = generatePIN()
        serverState.pin = newPIN
        snapshot.update(pin: newPIN, isRunning: serverState.isRunning, ip: serverState.detectedIPAddress ?? "127.0.0.1")
    }

    // MARK: - Static HTTP handler (no self captured)

    nonisolated private static func handleHTTP(
        connection: NWConnection,
        queue: DispatchQueue,
        snapshot: ServerStateSnapshot,
        sessions: SessionStore,
        onClose: @escaping () -> Void
    ) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
            defer {
                connection.cancel()
                onClose()
            }

            guard let data,
                  !data.isEmpty,
                  let raw     = String(data: data, encoding: .utf8),
                  let request = HTTPRequest.parse(raw, rawData: data)
            else {
                connection.send(
                    content: HTTPResponseBuilder.notFound(),
                    completion: .contentProcessed { _ in }
                )
                return
            }

            // CORS preflight
            if request.method == "OPTIONS" {
                connection.send(content: HTTPResponseBuilder.options(),
                                completion: .contentProcessed { _ in })
                return
            }

            let responseData = Self.routeRequest(request, snapshot: snapshot, sessions: sessions)
            connection.send(
                content: responseData,
                completion: .contentProcessed { _ in }
            )
        }
    }

    nonisolated private static func routeRequest(
        _ request: HTTPRequest,
        snapshot: ServerStateSnapshot,
        sessions: SessionStore
    ) -> Data {

        // ── Unauthenticated endpoints ──────────────────────────────────

        if request.method == "GET" && request.path == "/" {
            let html = RemoteWebAppPage.html(appVersionString: "1.0")
            return HTTPResponseBuilder.html(html)
        }

        if request.method == "GET" && request.path == "/health" {
            let ip   = snapshot.ip
            let json = "{\"host\":\"\(ip)\",\"port\":8080,\"ok\":true}"
            return HTTPResponseBuilder.json(json)
        }

        if request.method == "POST" && request.path == "/login" {
            guard let body = request.jsonBody,
                  let password = body["password"] as? String
            else {
                return HTTPResponseBuilder.json("{\"error\":\"bad_request\"}", status: 400)
            }

            let currentPIN = snapshot.pin
            guard !currentPIN.isEmpty, password == currentPIN else {
                return HTTPResponseBuilder.unauthorized()
            }

            let (token, expiresAt) = sessions.create()
            let iso = ISO8601DateFormatter().string(from: expiresAt)
            let json = "{\"sessionToken\":\"\(token)\",\"expiresAt\":\"\(iso)\"}"
            return HTTPResponseBuilder.json(json)
        }

        if request.method == "POST" && request.path == "/logout" {
            if let token = request.bearerToken {
                sessions.revoke(token)
            }
            return HTTPResponseBuilder.json("{\"ok\":true}")
        }

        // ── Authenticated endpoints ────────────────────────────────────

        // Validate Bearer token for all remaining endpoints
        guard let token = request.bearerToken, sessions.isValid(token) else {
            return HTTPResponseBuilder.unauthorized()
        }

        switch request.path {

        // ── /status ───────────────────────────────────────────────────
        case "/status":
            let bus = RemoteCommandBus.shared
            let slideJSON = bus.currentSlideJSON
            return HTTPResponseBuilder.json(slideJSON)

        // ── /action ───────────────────────────────────────────────────
        case "/action":
            guard request.method == "POST",
                  let body = request.jsonBody,
                  let command = body["command"] as? String
            else {
                return HTTPResponseBuilder.json("{\"error\":\"bad_request\"}", status: 400)
            }

            switch command {
            case "next":
                RemoteCommandBus.shared.send(.nextSlide)
            case "previous":
                RemoteCommandBus.shared.send(.previousSlide)
            case "escape", "clear":
                RemoteCommandBus.shared.send(.clearOutput)
            case "project_bible_verse":
                RemoteCommandBus.shared.send(.projectBibleVerse(
                    versionID: body["versionID"] as? Int ?? 1,
                    bookIndex: body["bookIndex"] as? Int ?? 1,
                    chapter:   body["chapter"]   as? Int ?? 1,
                    verse:     body["verse"]     as? Int ?? 1
                ))
            case "project_current":
                RemoteCommandBus.shared.send(.projectCurrent)
            default:
                break
            }
            return HTTPResponseBuilder.json("{\"ok\":true}")

        // ── Legacy simple endpoints (keep backwards compat) ───────────
        case "/next":
            RemoteCommandBus.shared.send(.nextSlide)
            return HTTPResponseBuilder.json("{\"ok\":true,\"command\":\"next\"}")

        case "/previous":
            RemoteCommandBus.shared.send(.previousSlide)
            return HTTPResponseBuilder.json("{\"ok\":true,\"command\":\"previous\"}")

        case "/clear":
            RemoteCommandBus.shared.send(.clearOutput)
            return HTTPResponseBuilder.json("{\"ok\":true,\"command\":\"clear\"}")

        case "/current":
            return HTTPResponseBuilder.json(RemoteCommandBus.shared.currentSlideJSON)

        // ── Bible API ─────────────────────────────────────────────────
        case "/api/bible/versions":
            return HTTPResponseBuilder.json(RemoteWebAssetProvider.versionsJSON())

        case "/api/bible/books":
            return HTTPResponseBuilder.json(RemoteWebAssetProvider.booksJSON())

        case "/api/bible/chapters":
            let bookNum = Int(request.query["book"] ?? "1") ?? 1
            return HTTPResponseBuilder.json(RemoteWebAssetProvider.chaptersJSON(book: bookNum))

        case "/api/bible/verses":
            let bookNum    = Int(request.query["book"]    ?? "1") ?? 1
            let chapterNum = Int(request.query["chapter"] ?? "1") ?? 1
            return HTTPResponseBuilder.json(RemoteWebAssetProvider.versesJSON(book: bookNum, chapter: chapterNum))

        // ── Presentation pages ────────────────────────────────────────
        case "/api/presentation/pages":
            return HTTPResponseBuilder.json("[]")

        default:
            return HTTPResponseBuilder.notFound()
        }
    }

    // MARK: - Helpers

    nonisolated private static func extractIP(from connection: NWConnection) -> String {
        if case .hostPort(let host, _) = connection.endpoint {
            return "\(host)"
        }
        return "unknown"
    }

    private func generatePIN() -> String {
        String(format: "%06d", Int.random(in: 100_000...999_999))
    }

    private func detectedLocalIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let current = ptr {
            let flags      = Int32(current.pointee.ifa_flags)
            let isUp       = (flags & IFF_UP) != 0
            let isRunning  = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            let family     = current.pointee.ifa_addr.pointee.sa_family

            if family == UInt8(AF_INET), isUp, isRunning, !isLoopback {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    current.pointee.ifa_addr,
                    socklen_t(current.pointee.ifa_addr.pointee.sa_len),
                    &hostname, socklen_t(hostname.count),
                    nil, 0,
                    NI_NUMERICHOST
                )
                if result == 0 { address = String(cString: hostname); break }
            }
            ptr = current.pointee.ifa_next
        }
        return address
    }
}
