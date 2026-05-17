import XCTest
@testable import TunnelBar

final class LocalURLParserTests: XCTestCase {
    func testExtractsLocalhostOriginAndPath() throws {
        let mapping = try LocalURLParser.parse("http://localhost:3001/contracts/template/test-anyone")

        XCTAssertEqual(mapping.origin.absoluteString, "http://localhost:3001")
        XCTAssertEqual(mapping.tunnelOrigin.absoluteString, "http://127.0.0.1:3001")
        XCTAssertEqual(mapping.routeSuffix, "/contracts/template/test-anyone")

        let publicURL = try mapping.publicURL(from: XCTUnwrap(URL(string: "https://example-name.trycloudflare.com")))
        XCTAssertEqual(publicURL.absoluteString, "https://example-name.trycloudflare.com/contracts/template/test-anyone")
    }

    func testPreservesQueryAndFragmentInCopiedURL() throws {
        let mapping = try LocalURLParser.parse("http://127.0.0.1:5173/foo?bar=baz#section")

        XCTAssertEqual(mapping.origin.absoluteString, "http://127.0.0.1:5173")
        XCTAssertEqual(mapping.tunnelOrigin.absoluteString, "http://127.0.0.1:5173")
        XCTAssertEqual(mapping.routeSuffix, "/foo?bar=baz#section")

        let publicURL = try mapping.publicURL(from: XCTUnwrap(URL(string: "https://demo.trycloudflare.com")))
        XCTAssertEqual(publicURL.absoluteString, "https://demo.trycloudflare.com/foo?bar=baz#section")
    }

    func testRootURLUsesQuickTunnelRoot() throws {
        let mapping = try LocalURLParser.parse("http://localhost:3000")

        let publicURL = try mapping.publicURL(from: XCTUnwrap(URL(string: "https://root.trycloudflare.com")))
        XCTAssertEqual(publicURL.absoluteString, "https://root.trycloudflare.com")
    }

    func testRejectsPublicHost() {
        XCTAssertThrowsError(try LocalURLParser.parse("https://example.com:443/path")) { error in
            XCTAssertEqual(error as? LocalURLParserError, .unsupportedScheme("https"))
        }
    }

    func testRejectsMissingPort() {
        XCTAssertThrowsError(try LocalURLParser.parse("http://localhost/path")) { error in
            XCTAssertEqual(error as? LocalURLParserError, .missingPort)
        }
    }
}
