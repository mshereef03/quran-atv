import Foundation

/// Chapters the user has starred for quick access, persisted across launches.
enum BookmarkStore {
    private static let key = "bookmarkedChapterIDs"

    static var all: Set<Int> {
        Set((UserDefaults.standard.array(forKey: key) as? [Int]) ?? [])
    }

    static func isBookmarked(_ chapterID: Int) -> Bool {
        all.contains(chapterID)
    }

    @discardableResult
    static func toggle(_ chapterID: Int) -> Bool {
        var current = all
        let nowBookmarked: Bool
        if current.contains(chapterID) {
            current.remove(chapterID)
            nowBookmarked = false
        } else {
            current.insert(chapterID)
            nowBookmarked = true
        }
        UserDefaults.standard.set(Array(current), forKey: key)
        return nowBookmarked
    }
}
