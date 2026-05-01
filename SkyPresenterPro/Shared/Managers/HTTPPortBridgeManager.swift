// Archivo: HTTPPortBridgeManager.swift
// Función: Audita la disponibilidad del helper HTTP y resuelve la mejor URL pública remota.
// Contiene: HTTPPortBridgeManager, HTTPPortBridgeResolution.
// Uso: RemoteServerService lo usa para decidir automáticamente entre bridge sin puerto, Bonjour o IP:puerto.

import Foundation

struct HTTPPortBridgeResolution {
    let primaryURL: String
    let alternateURL: String
    let bonjourHostName: String?
    let bonjourURL: String
    let bridgeStatus: HTTPPortBridgeStatus
    let accessStrategy: RemoteAccessStrategy
    let isPortlessModeActive: Bool
}

final class HTTPPortBridgeManager {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 1.5
        configuration.timeoutIntervalForResource = 1.5
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    func helperArtifactsExist() -> Bool {
        let helperExecutable = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/HelperTools/HTTPPortBridgeHelper")
        let helperPlist = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LaunchDaemons/com.SkyPresenter.SkyPresenterPro.HTTPBridge.plist")
        return FileManager.default.fileExists(atPath: helperExecutable.path) &&
            FileManager.default.fileExists(atPath: helperPlist.path)
    }

    func preferredBonjourHostName() -> String? {
        let rawHost = ProcessInfo.processInfo.hostName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawHost.isEmpty else { return nil }
        if rawHost == "localhost" || rawHost == "127.0.0.1" {
            return nil
        }

        if rawHost.hasSuffix(".local") {
            return rawHost
        }

        let bareHost = rawHost.components(separatedBy: ".").first ?? rawHost
        return bareHost.isEmpty ? nil : "\(bareHost).local"
    }

    func resolveBestEndpoint(ipAddress: String?, port: Int) async -> HTTPPortBridgeResolution {
        let bridgeAvailable = helperArtifactsExist()
        let bonjourHost = preferredBonjourHostName()
        let ip = ipAddress ?? "127.0.0.1"

        let ipPortURL = Self.buildURL(host: ip, port: port, includePort: true)
        let bonjourPortURL = bonjourHost.map { Self.buildURL(host: $0, port: port, includePort: true) } ?? ""
        let ipPortlessURL = Self.buildURL(host: ip, port: port, includePort: false)
        let bonjourPortlessURL = bonjourHost.map { Self.buildURL(host: $0, port: port, includePort: false) } ?? ""

        if bridgeAvailable {
            if !bonjourPortlessURL.isEmpty, await isHealthy(urlString: "\(bonjourPortlessURL)/health") {
                return HTTPPortBridgeResolution(
                    primaryURL: bonjourPortlessURL,
                    alternateURL: ipPortlessURL,
                    bonjourHostName: bonjourHost,
                    bonjourURL: bonjourPortlessURL,
                    bridgeStatus: .active,
                    accessStrategy: .helperBridge,
                    isPortlessModeActive: true
                )
            }

            if await isHealthy(urlString: "\(ipPortlessURL)/health") {
                return HTTPPortBridgeResolution(
                    primaryURL: ipPortlessURL,
                    alternateURL: bonjourPortURL.isEmpty ? ipPortURL : bonjourPortURL,
                    bonjourHostName: bonjourHost,
                    bonjourURL: bonjourPortlessURL,
                    bridgeStatus: .active,
                    accessStrategy: .helperBridge,
                    isPortlessModeActive: true
                )
            }
        }

        if !bonjourPortURL.isEmpty, await isHealthy(urlString: "\(bonjourPortURL)/health") {
            return HTTPPortBridgeResolution(
                primaryURL: bonjourPortURL,
                alternateURL: ipPortURL,
                bonjourHostName: bonjourHost,
                bonjourURL: bonjourPortURL,
                bridgeStatus: bridgeAvailable ? .inactive : .unavailable,
                accessStrategy: .bonjour,
                isPortlessModeActive: false
            )
        }

        return HTTPPortBridgeResolution(
            primaryURL: ipPortURL,
            alternateURL: bonjourPortURL,
            bonjourHostName: bonjourHost,
            bonjourURL: bonjourPortURL,
            bridgeStatus: bridgeAvailable ? .inactive : .unavailable,
            accessStrategy: .ipWithPort,
            isPortlessModeActive: false
        )
    }

    private func isHealthy(urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return false
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            return body.contains("\"ok\":true")
        } catch {
            return false
        }
    }

    private static func buildURL(host: String, port: Int, includePort: Bool) -> String {
        guard includePort, port > 0 else {
            return "http://\(host)"
        }
        return "http://\(host):\(port)"
    }
}
