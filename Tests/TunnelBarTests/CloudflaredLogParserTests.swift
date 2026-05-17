import XCTest
@testable import TunnelBar

final class CloudflaredLogParserTests: XCTestCase {
    func testFindsQuickTunnelURLInCloudflaredOutput() {
        let output = "INF Your quick Tunnel has been created! Visit it at https://small-river-123.trycloudflare.com"

        XCTAssertEqual(
            CloudflaredLogParser.firstQuickTunnelURL(in: output)?.absoluteString,
            "https://small-river-123.trycloudflare.com"
        )
    }

    func testIgnoresNonQuickTunnelURLs() {
        let output = "Visit https://example.com instead"

        XCTAssertNil(CloudflaredLogParser.firstQuickTunnelURL(in: output))
    }
}
