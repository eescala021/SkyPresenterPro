// Archivo: RemoteCommand.swift
// Función: Define los comandos del control remoto y el bus thread-safe entre módulos.
// Contiene: RemoteCommand, RemoteCommandBus.
// Uso: RemoteServerService envía comandos desde background; PresentationViewModel los recibe en MainActor.

import Combine
import Foundation

// MARK: - Commands

enum RemoteCommand: String, Codable, CaseIterable {
    case nextSlide
    case previousSlide
    case clearOutput
    case projectWorship
    case projectBible
    case projectPresentation
    case fetchStatus
    case authenticate
}

// MARK: - Command Bus (thread-safe)

/// Puente entre el servidor HTTP (background) y los ViewModels (@MainActor).
/// - `send(_:)` es seguro desde cualquier hilo.
/// - `publisher` se debe observar con `.receive(on: DispatchQueue.main)`.
/// - `currentSlideJSON` es seguro para lectura desde background (NSLock).
final class RemoteCommandBus {
    static let shared = RemoteCommandBus()
    private init() {}

    // MARK: - Commands via PassthroughSubject (thread-safe)

    private let subject = PassthroughSubject<RemoteCommand, Never>()

    var publisher: AnyPublisher<RemoteCommand, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Envía un comando desde cualquier hilo.
    func send(_ command: RemoteCommand) {
        subject.send(command)
    }

    // MARK: - Current slide state (lock-protected)

    private let slideLock = NSLock()
    private var _currentSlideJSON: String = "{\"title\":null,\"index\":null,\"source\":\"none\"}"

    /// Lectura thread-safe del JSON del slide actual.
    var currentSlideJSON: String {
        slideLock.lock()
        defer { slideLock.unlock() }
        return _currentSlideJSON
    }

    /// Actualizar desde @MainActor cuando el slide proyectado cambia.
    func updateCurrentSlide(_ json: String) {
        slideLock.lock()
        defer { slideLock.unlock() }
        _currentSlideJSON = json
    }
}
