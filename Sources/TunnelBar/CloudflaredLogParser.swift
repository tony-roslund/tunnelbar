import Foundation

public enum CloudflaredLogParser {
    private static let quickTunnelPattern = #"https://[A-Za-z0-9-]+\.trycloudflare\.com"#

    public static func firstQuickTunnelURL(in text: String) -> URL? {
        guard
            let regex = try? NSRegularExpression(pattern: quickTunnelPattern),
            let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..<text.endIndex, in: text)
            ),
            let range = Range(match.range, in: text)
        else {
            return nil
        }

        return URL(string: String(text[range]))
    }
}
