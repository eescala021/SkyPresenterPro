// Archivo: RemoteSessionManager.swift
// Función: Gestiona el ciclo de vida de las sesiones activas del control remoto.
// Contiene: RemoteSessionManager.
// Uso: Crea sesiones validando PIN, revoca sesiones, y depura expiradas.

import Combine
import Foundation

@MainActor
final class RemoteSessionManager: ObservableObject {

    @Published private(set) var activeSessions: [RemoteSession] = []

    /// Duración de sesión en segundos (4 horas).
    private let sessionDuration: TimeInterval = 4 * 60 * 60

    // MARK: - Session creation

    /// Crea una sesión si el PIN proporcionado coincide con el PIN activo del servidor.
    /// - Returns: la nueva sesión, o nil si el PIN es inválido.
    @discardableResult
    func createSession(ifPINMatches provided: String, validPIN: String) -> RemoteSession? {
        guard !validPIN.isEmpty, provided == validPIN else { return nil }
        return createSession(username: "operador")
    }

    /// Crea y registra una sesión sin validación de PIN (uso interno).
    @discardableResult
    func createSession(username: String) -> RemoteSession {
        let session = RemoteSession(
            username: username,
            token: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )
        activeSessions.append(session)
        return session
    }

    // MARK: - Validation

    /// Valida si un token pertenece a una sesión activa y no expirada.
    func isTokenValid(_ token: String) -> Bool {
        activeSessions.contains { $0.token == token && $0.isValid }
    }

    /// Devuelve la sesión activa para un token, o nil si es inválido.
    func session(for token: String) -> RemoteSession? {
        activeSessions.first { $0.token == token && $0.isValid }
    }

    // MARK: - Revocation

    func revokeSession(id: UUID) {
        activeSessions.removeAll { $0.id == id }
    }

    func revokeAllSessions() {
        activeSessions.removeAll()
    }

    /// Elimina sesiones vencidas.
    func purgeExpiredSessions() {
        activeSessions.removeAll { !$0.isValid }
    }
}
