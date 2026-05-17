import XCTest
@testable import TunnelBar

final class CloudflaredFailureClassifierTests: XCTestCase {
    func testConnectionRefusedExplainsLocalServerIsNotRunning() throws {
        let mapping = try LocalURLParser.parse("http://localhost:3000/share/review")

        let message = CloudflaredFailureClassifier.message(
            outputLines: [
                "ERR error=\"dial tcp 127.0.0.1:3000: connect: connection refused\""
            ],
            mapping: mapping,
            fallback: "fallback"
        )

        XCTAssertEqual(
            message,
            "Nothing is responding at http://localhost:3000. Start your local dev server, then try again."
        )
    }

    func testQuickTunnelCreationFailureUsesActionableCloudflaredMessage() {
        let message = CloudflaredFailureClassifier.message(
            outputLines: [
                "ERR failed to request quick tunnel: service temporarily unavailable"
            ],
            mapping: nil,
            fallback: "fallback"
        )

        XCTAssertEqual(
            message,
            "cloudflared could not create a tunnel. Check Diagnostics, then try again."
        )
    }

    func testUnknownFailureFallsBack() {
        XCTAssertEqual(
            CloudflaredFailureClassifier.message(
                outputLines: ["unexpected output"],
                mapping: nil,
                fallback: "fallback"
            ),
            "fallback"
        )
    }
}
