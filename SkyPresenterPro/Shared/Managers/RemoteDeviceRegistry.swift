// Archivo: RemoteDeviceRegistry.swift
// Función: Registra y gestiona los dispositivos remotos. Dispositivo ≠ Sesión.
// Contiene: RemoteDevice, RemoteDeviceRegistry.
// Uso: RemoteServerService registra y actualiza actividad; el dispositivo persiste hasta que:
//      expira sesión, se revoca, el usuario lo elimina, o se llama clearAll().
//      Persiste en UserDefaults para sobrevivir reinicios del servidor dentro de la misma sesión de app.

import Combine
import Foundation

// MARK: - Model

struct RemoteDevice: Identifiable, Equatable, Hashable, Codable {
    let id: UUID

    /// Nombre del dispositivo (user-agent o etiqueta genérica)
    var name: String

    /// Dirección IP desde la que se conectó
    var ipAddress: String

    /// Momento de primera conexión
    var connectedAt: Date

    /// Última actividad registrada (se actualiza en cada request)
    var lastActivity: Date

    /// Sesión activa asociada, si existe
    var sessionId: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        ipAddress: String,
        connectedAt: Date = Date(),
        lastActivity: Date = Date(),
        sessionId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.connectedAt = connectedAt
        self.lastActivity = lastActivity
        self.sessionId = sessionId
    }
}

// MARK: - Registry

@MainActor
final class RemoteDeviceRegistry: ObservableObject {

    @Published private(set) var connectedDevices: [RemoteDevice] = []

    private let storageKey = "remote.device.registry.devices"

    init() {
        load()
    }

    // MARK: - Registration

    /// Registra un nuevo dispositivo. Si ya existe uno con la misma IP, actualiza su actividad.
    func registerDevice(_ device: RemoteDevice) {
        if let index = connectedDevices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
            connectedDevices[index].lastActivity = Date()
        } else {
            connectedDevices.append(device)
            persist()
        }
    }

    // MARK: - Activity tracking

    /// Actualiza el timestamp de última actividad para un dispositivo por ID.
    func updateActivity(id: UUID) {
        if let index = connectedDevices.firstIndex(where: { $0.id == id }) {
            connectedDevices[index].lastActivity = Date()
        }
    }

    /// Actualiza la actividad de un dispositivo por su IP (usado desde el servidor HTTP).
    func updateActivity(forIP ip: String) {
        if let index = connectedDevices.firstIndex(where: { $0.ipAddress == ip }) {
            connectedDevices[index].lastActivity = Date()
        }
    }

    /// Actualiza el nombre de un dispositivo por su IP (llamado tras login exitoso).
    func updateName(forIP ip: String, to name: String) {
        if let index = connectedDevices.firstIndex(where: { $0.ipAddress == ip }) {
            connectedDevices[index].name = name
            persist()
        }
    }

    // MARK: - Removal

    func removeDevice(id: UUID) {
        connectedDevices.removeAll { $0.id == id }
        persist()
    }

    /// Limpia todos los dispositivos (al detener el servidor o revocar todo).
    func clearAll() {
        connectedDevices.removeAll()
        persist()
    }

    /// Elimina dispositivos sin actividad en los últimos `minutes` minutos que no tengan sesión.
    func purgeInactiveDevices(olderThan minutes: Double = 30) {
        let cutoff = Date().addingTimeInterval(-minutes * 60)
        connectedDevices.removeAll { device in
            device.sessionId == nil && device.lastActivity < cutoff
        }
        persist()
    }

    // MARK: - Session binding

    func bindSession(_ sessionId: UUID, to deviceId: UUID) {
        if let index = connectedDevices.firstIndex(where: { $0.id == deviceId }) {
            connectedDevices[index].sessionId = sessionId
            persist()
        }
    }

    func unbindSession(_ sessionId: UUID) {
        if let index = connectedDevices.firstIndex(where: { $0.sessionId == sessionId }) {
            connectedDevices[index].sessionId = nil
            persist()
        }
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(connectedDevices) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let devices = try? JSONDecoder().decode([RemoteDevice].self, from: data) else {
            connectedDevices = []
            return
        }
        connectedDevices = devices
    }
}
