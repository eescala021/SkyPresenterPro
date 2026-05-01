// Archivo: RemoteSession.swift
// Función: Modela una sesión autenticada de un cliente remoto conectado al servidor local.
// Contiene: RemoteSession
// Uso: Se integra en RemoteControlManager para registrar, validar y listar dispositivos remotos activos.
import Foundation

struct RemoteSession: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let username: String
    let deviceName: String
    let sessionToken: String
    let createdAt: Date
    var lastSeenAt: Date
    let expiresAt: Date

    init(
        id: UUID = UUID(),
        username: String,
        deviceName: String,
        sessionToken: String,
        createdAt: Date = Date(),
        lastSeenAt: Date = Date(),
        expiresAt: Date
    ) {
        self.id = id
        self.username = username
        self.deviceName = deviceName
        self.sessionToken = sessionToken
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }
}
