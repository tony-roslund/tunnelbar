import Foundation

public struct TunnelHistoryItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let localURL: String
    public let publicURL: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        localURL: String,
        publicURL: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.localURL = localURL
        self.publicURL = publicURL
        self.createdAt = createdAt
    }
}

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [TunnelHistoryItem] = []

    private let defaults: UserDefaults
    private let key = "TunnelBar.history"
    private let limit = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(localURL: String, publicURL: String) {
        let item = TunnelHistoryItem(localURL: localURL, publicURL: publicURL)
        items.removeAll { $0.localURL == localURL && $0.publicURL == publicURL }
        items.insert(item, at: 0)
        items = Array(items.prefix(limit))
        save()
    }

    func clear() {
        items = []
        save()
    }

    private func load() {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode([TunnelHistoryItem].self, from: data)
        else {
            return
        }

        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
