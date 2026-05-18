import Darwin
import Foundation

enum CloudflaredProcessCleaner {
    struct ProcessSnapshot: Equatable {
        let pid: Int32
        let parentPID: Int32
        let command: String
    }

    @discardableResult
    static func terminateOrphanedBundledProcesses(
        currentProcessID: Int32 = ProcessInfo.processInfo.processIdentifier
    ) -> [Int32] {
        let snapshots = runningProcesses()
        let pids = orphanedBundledProcessIDs(
            in: snapshots,
            currentProcessID: currentProcessID
        )

        terminateWithProcessMatcher()

        for pid in pids {
            _ = Darwin.kill(pid, SIGTERM)
        }

        return pids
    }

    static func orphanedBundledProcessIDs(
        in snapshots: [ProcessSnapshot],
        currentProcessID: Int32
    ) -> [Int32] {
        snapshots.compactMap { snapshot in
            guard isOrphanedBundledCloudflared(snapshot, currentProcessID: currentProcessID) else {
                return nil
            }

            return snapshot.pid
        }
    }

    static func parseProcessList(_ output: String) -> [ProcessSnapshot] {
        output
            .split(separator: "\n")
            .compactMap { line in
                let parts = line.split(
                    separator: " ",
                    maxSplits: 2,
                    omittingEmptySubsequences: true
                )

                guard
                    parts.count == 3,
                    let pid = Int32(parts[0]),
                    let parentPID = Int32(parts[1])
                else {
                    return nil
                }

                return ProcessSnapshot(
                    pid: pid,
                    parentPID: parentPID,
                    command: String(parts[2])
                )
            }
    }

    private static func runningProcesses() -> [ProcessSnapshot] {
        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,ppid=,command="]
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseProcessList(output)
    }

    private static func terminateWithProcessMatcher() {
        let process = Process()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        process.arguments = [
            "-TERM",
            "-f",
            "TunnelBar\\.app/Contents/Resources/cloudflared-(arm64|amd64)"
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
    }

    private static func isOrphanedBundledCloudflared(
        _ snapshot: ProcessSnapshot,
        currentProcessID: Int32
    ) -> Bool {
        guard
            snapshot.pid != currentProcessID,
            snapshot.parentPID != currentProcessID,
            snapshot.command.contains("TunnelBar.app/Contents/Resources/cloudflared-")
        else {
            return false
        }

        return snapshot.command.contains("cloudflared-arm64")
            || snapshot.command.contains("cloudflared-amd64")
    }
}
