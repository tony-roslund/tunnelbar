import XCTest
@testable import TunnelBar

final class CloudflaredProcessCleanerTests: XCTestCase {
    func testParsesProcessListWithCommandsContainingSpaces() {
        let snapshots = CloudflaredProcessCleaner.parseProcessList(
            """
              123     1 /path/to/command --with spaces
              456   123 /another/command
            """
        )

        XCTAssertEqual(
            snapshots,
            [
                .init(pid: 123, parentPID: 1, command: "/path/to/command --with spaces"),
                .init(pid: 456, parentPID: 123, command: "/another/command")
            ]
        )
    }

    func testFindsOnlyOrphanedBundledCloudflaredProcesses() {
        let snapshots: [CloudflaredProcessCleaner.ProcessSnapshot] = [
            .init(
                pid: 101,
                parentPID: 1,
                command: "/Users/tony/TunnelBar.app/Contents/Resources/cloudflared-arm64 tunnel --url http://127.0.0.1:3000"
            ),
            .init(
                pid: 102,
                parentPID: 1,
                command: "/opt/homebrew/bin/cloudflared tunnel --url http://127.0.0.1:3001"
            ),
            .init(
                pid: 103,
                parentPID: 999,
                command: ".build/TunnelBar.app/Contents/Resources/cloudflared-amd64 tunnel --url http://127.0.0.1:3002"
            ),
            .init(
                pid: 999,
                parentPID: 1,
                command: "/Users/tony/TunnelBar.app/Contents/MacOS/TunnelBar"
            )
        ]

        XCTAssertEqual(
            CloudflaredProcessCleaner.orphanedBundledProcessIDs(
                in: snapshots,
                currentProcessID: 999
            ),
            [101]
        )
    }
}
