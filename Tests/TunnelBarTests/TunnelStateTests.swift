import XCTest
@testable import TunnelBar

final class TunnelStateTests: XCTestCase {
    func testStoppedStateHasUserFacingLabel() {
        XCTAssertEqual(TunnelState.stopped.label, "Stopped")
    }
}
