import Foundation

/// Shared data owned by the root view and used across the Listen Now / Surahs tabs.
@MainActor
final class AppViewModel: ObservableObject {
    @Published var chapters: [Chapter] = []
    @Published var juzs: [Juz] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var continueTarget: PlaybackTarget?
    @Published var bookmarkedChapters: [Chapter] = []
    @Published var recentlyPlayedChapters: [Chapter] = []

    private var chaptersByID: [Int: Chapter] = [:]

    func load() async {
        guard chapters.isEmpty else {
            refresh()
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            chapters = try await QuranAPIClient.shared.fetchChapters()
            chaptersByID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
        } catch {
            errorMessage = "Couldn't load the Quran. Check your connection and try again."
        }
        isLoading = false
        refresh()
        // Best-effort: the Juz' filter simply won't offer options if this fails.
        juzs = (try? await QuranAPIClient.shared.fetchJuzs()) ?? []
    }

    func refresh() {
        refreshContinueTarget()
        refreshBookmarks()
        refreshRecentlyPlayed()
    }

    func refreshContinueTarget() {
        guard let saved = PlaybackProgressStore.lastPlayed, let chapter = chaptersByID[saved.chapterID] else {
            continueTarget = nil
            return
        }
        continueTarget = PlaybackTarget(chapter: chapter, startIndex: saved.verseIndex)
    }

    func refreshBookmarks() {
        let bookmarkedIDs = BookmarkStore.all
        bookmarkedChapters = chapters.filter { bookmarkedIDs.contains($0.id) }
    }

    func toggleBookmark(chapterID: Int) {
        BookmarkStore.toggle(chapterID)
        refreshBookmarks()
    }

    func refreshRecentlyPlayed() {
        recentlyPlayedChapters = PlaybackProgressStore.recentChapterIDs.compactMap { chaptersByID[$0] }
    }
}
