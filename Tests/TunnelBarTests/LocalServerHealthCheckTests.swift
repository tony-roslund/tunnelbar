import Network
import XCTest
@testable import TunnelBar

final class LocalServerHealthCheckTests: XCTestCase {
    func testConnectsToListeningLocalServer() async throws {
        let listener = try NWListener(using: .tcp, on: .any)
        let listenerReady = expectation(description: "listener ready")
        let queue = DispatchQueue(label: "TunnelBarHealthCheckTests")

        listener.newConnectionHandler = { connection in
            connection.cancel()
        }
        listener.stateUpdateHandler = { state in
            if case .ready = state {
                listenerReady.fulfill()
            }
        }
        listener.start(queue: queue)
        defer { listener.cancel() }

        await fulfillment(of: [listenerReady], timeout: 2)

        let port = try XCTUnwrap(listener.port?.rawValue)
        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(port)"))

        let isReachable = await LocalServerHealthCheck.canConnect(
            to: url,
            timeoutSeconds: 1
        )

        XCTAssertTrue(isReachable)
    }
}
