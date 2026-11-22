import SwiftUI

/// Standard tvOS long-press context menu content for toggling a surah's bookmark,
/// shared by every screen that shows a `SurahMoodCard`.
@ViewBuilder
func bookmarkContextMenuItem(for chapter: Chapter, onToggle: @escaping (Int) -> Void) -> some View {
    Button {
        onToggle(chapter.id)
    } label: {
        if BookmarkStore.isBookmarked(chapter.id) {
            Label("Remove Bookmark", systemImage: "star.slash")
        } else {
            Label("Add Bookmark", systemImage: "star")
        }
    }
}
