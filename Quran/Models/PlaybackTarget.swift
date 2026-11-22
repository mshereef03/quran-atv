import Foundation

/// A surah to play, optionally resuming from a specific ayah (used by the "Continue" shelf).
struct PlaybackTarget: Identifiable, Hashable {
    let chapter: Chapter
    let startIndex: Int
    /// When true, always seek to `startIndex` even if this chapter is already the one
    /// actively playing — used by "Start Over", so restarting an in-progress surah actually
    /// jumps back to the beginning instead of silently continuing from where it was.
    let forceRestart: Bool

    var id: Int { chapter.id }

    init(chapter: Chapter, startIndex: Int = 0, forceRestart: Bool = false) {
        self.chapter = chapter
        self.startIndex = startIndex
        self.forceRestart = forceRestart
    }
}
