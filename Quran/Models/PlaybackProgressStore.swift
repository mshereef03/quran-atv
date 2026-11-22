import Foundation

/// Remembers the last surah/ayah played (for the "Continue" hero) and a short history of
/// recently-played surahs (for the "Recently Played" shelf).
enum PlaybackProgressStore {
    private static let chapterKey = "lastPlayedChapterID"
    private static let verseIndexKey = "lastPlayedVerseIndex"
    private static let recentKey = "recentlyPlayedEntries"
    private static let maxRecentCount = 10

    struct RecentEntry: Codable {
        let chapterID: Int
        let playedAt: Date
    }

    static var lastPlayed: (chapterID: Int, verseIndex: Int)? {
        let id = UserDefaults.standard.integer(forKey: chapterKey)
        guard id > 0 else { return nil }
        return (id, UserDefaults.standard.integer(forKey: verseIndexKey))
    }

    /// Chapter ids in most-recently-played-first order.
    static var recentChapterIDs: [Int] {
        guard let data = UserDefaults.standard.data(forKey: recentKey),
              let entries = try? JSONDecoder().decode([RecentEntry].self, from: data) else {
            return []
        }
        return entries.map(\.chapterID)
    }

    static func save(chapterID: Int, verseIndex: Int) {
        UserDefaults.standard.set(chapterID, forKey: chapterKey)
        UserDefaults.standard.set(verseIndex, forKey: verseIndexKey)

        var entries: [RecentEntry] = []
        if let data = UserDefaults.standard.data(forKey: recentKey) {
            entries = (try? JSONDecoder().decode([RecentEntry].self, from: data)) ?? []
        }
        entries.removeAll { $0.chapterID == chapterID }
        entries.insert(RecentEntry(chapterID: chapterID, playedAt: Date()), at: 0)
        if entries.count > maxRecentCount {
            entries = Array(entries.prefix(maxRecentCount))
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: recentKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: chapterKey)
        UserDefaults.standard.removeObject(forKey: verseIndexKey)
    }
}
