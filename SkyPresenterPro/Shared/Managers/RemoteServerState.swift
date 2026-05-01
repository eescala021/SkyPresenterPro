// Archivo: RemoteServerState.swift
// Función: Agrupa el estado observable del servidor HTTP remoto y sus datos de acceso.
// Contiene: RemoteServerState
// Uso: Se integra en RemoteControlManager y en la UI de ajustes para mostrar disponibilidad, host y puerto.
import Foundation

struct RemoteServerState: Equatable {
    var isEnabled: Bool = false
    var isStarting: Bool = false
    var isRunning: Bool = false
    var host: String = "127.0.0.1"
    var port: UInt16 = 8088
    var connectedSessionCount: Int = 0
    var lastErrorMessage: String?

    var accessURL: URL? {
        URL(string: "http://\(host):\(port)")
    }

    var tabletURL: URL? {
        URL(string: "http://\(host):\(port)/tablets")
    }

    var accessURLString: String {
        accessURL?.absoluteString ?? "http://\(host):\(port)"
    }
}
