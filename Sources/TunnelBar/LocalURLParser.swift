import Foundation

public enum LocalURLParserError: Error, Equatable, LocalizedError {
    case invalidURL
    case unsupportedScheme(String?)
    case unsupportedHost(String?)
    case missingPort

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Enter a full local URL, such as http://localhost:3000/path."
        case .unsupportedScheme(let scheme):
            "TunnelBar currently supports http localhost URLs, not \(scheme ?? "missing-scheme") URLs."
        case .unsupportedHost(let host):
            "TunnelBar only exposes localhost or 127.0.0.1 URLs in v1, not \(host ?? "missing-host")."
        case .missingPort:
            "Use an explicit local dev-server port, such as http://localhost:3000."
        }
    }
}

public struct LocalURLMapping: Equatable, Sendable {
    public let input: URL
    public let origin: URL
    public let tunnelOrigin: URL
    public let path: String
    public let query: String?
    public let fragment: String?

    public var routeSuffix: String {
        var suffix = path == "/" ? "" : path
        if let query, !query.isEmpty {
            suffix += "?\(query)"
        }
        if let fragment, !fragment.isEmpty {
            suffix += "#\(fragment)"
        }
        return suffix
    }

    public func publicURL(from quickTunnelURL: URL) throws -> URL {
        guard var components = URLComponents(url: quickTunnelURL, resolvingAgainstBaseURL: false) else {
            throw LocalURLParserError.invalidURL
        }

        components.path = path == "/" ? "" : path
        components.percentEncodedQuery = query
        components.percentEncodedFragment = fragment

        guard let url = components.url else {
            throw LocalURLParserError.invalidURL
        }

        return url
    }
}

public enum LocalURLParser {
    public static func parse(_ rawValue: String) throws -> LocalURLMapping {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let components = URLComponents(string: trimmed),
            let url = components.url
        else {
            throw LocalURLParserError.invalidURL
        }

        guard components.scheme == "http" else {
            throw LocalURLParserError.unsupportedScheme(components.scheme)
        }

        guard let host = components.host, isSupportedLocalHost(host) else {
            throw LocalURLParserError.unsupportedHost(components.host)
        }

        guard let port = components.port else {
            throw LocalURLParserError.missingPort
        }

        var originComponents = URLComponents()
        originComponents.scheme = components.scheme
        originComponents.host = host
        originComponents.port = port

        var tunnelOriginComponents = originComponents
        if host == "localhost" {
            tunnelOriginComponents.host = "127.0.0.1"
        }

        guard
            let origin = originComponents.url,
            let tunnelOrigin = tunnelOriginComponents.url
        else {
            throw LocalURLParserError.invalidURL
        }

        return LocalURLMapping(
            input: url,
            origin: origin,
            tunnelOrigin: tunnelOrigin,
            path: components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath,
            query: components.percentEncodedQuery,
            fragment: components.percentEncodedFragment
        )
    }

    private static func isSupportedLocalHost(_ host: String) -> Bool {
        host == "localhost" || host == "127.0.0.1"
    }
}
