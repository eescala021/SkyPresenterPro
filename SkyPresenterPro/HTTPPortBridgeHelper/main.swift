import Foundation
import Network

private final class ConnectionBridge {
    private let inbound: NWConnection
    private let outbound: NWConnection
    private let queue = DispatchQueue(label: "com.skypresenterpro.httpbridge.connection")

    init(inbound: NWConnection, outbound: NWConnection) {
        self.inbound = inbound
        self.outbound = outbound
    }

    func start() {
        inbound.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
            if case .cancelled = state { self?.cancel() }
        }
        outbound.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
            if case .cancelled = state { self?.cancel() }
        }

        inbound.start(queue: queue)
        outbound.start(queue: queue)

        pipe(from: inbound, to: outbound)
        pipe(from: outbound, to: inbound)
    }

    private func pipe(from source: NWConnection, to destination: NWConnection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, !data.isEmpty {
                destination.send(content: data, completion: .contentProcessed { sendError in
                    if sendError != nil {
                        self.cancel()
                    } else if isComplete {
                        self.cancel()
                    } else {
                        self.pipe(from: source, to: destination)
                    }
                })
                return
            }

            if isComplete || error != nil {
                self.cancel()
            } else {
                self.pipe(from: source, to: destination)
            }
        }
    }

    private func cancel() {
        inbound.cancel()
        outbound.cancel()
    }
}

private final class HTTPPortBridgeDaemon {
    private let queue = DispatchQueue(label: "com.skypresenterpro.httpbridge.listener")
    private var listener: NWListener?
    private let targetHost = NWEndpoint.Host.ipv4(IPv4Address.loopback)
    private let targetPort = NWEndpoint.Port(integerLiteral: 8080)

    func run() throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        listener = try NWListener(using: parameters, on: .http)
        listener?.newConnectionHandler = { [weak self] inbound in
            guard let self else { return }
            let outbound = NWConnection(host: self.targetHost, port: self.targetPort, using: .tcp)
            ConnectionBridge(inbound: inbound, outbound: outbound).start()
        }
        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                NSLog("HTTPPortBridgeHelper ready on port 80")
            case .failed(let error):
                NSLog("HTTPPortBridgeHelper failed: \(error.localizedDescription)")
                exit(EXIT_FAILURE)
            default:
                break
            }
        }
        listener?.start(queue: queue)
        dispatchMain()
    }
}

do {
    try HTTPPortBridgeDaemon().run()
} catch {
    NSLog("HTTPPortBridgeHelper could not start: \(error.localizedDescription)")
    exit(EXIT_FAILURE)
}
