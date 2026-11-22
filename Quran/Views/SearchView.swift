import SwiftUI

/// A dedicated search screen, matching the standard tvOS pattern: a prominent,
/// focused text field as the page's main content rather than an inline pill —
/// the system's native edit-mode chrome is expected and looks intentional here.
struct SearchView: View {
    let chapters: [Chapter]
    let onSelect: (PlaybackTarget) -> Void
    let onToggleBookmark: (Int) -> Void

    @State private var searchText = ""
    @State private var isFieldFocused = false

    private let columns = [GridItem(.adaptive(minimum: 340, maximum: 340), spacing: 48)]

    private var results: [Chapter] {
        // Dictation (holding the Siri Remote mic button) can transcribe trailing punctuation
        // or extra whitespace onto otherwise-correct text, so trim before matching.
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !query.isEmpty else { return [] }
        let foldedQuery = query.arabicSearchFolded
        return chapters.filter {
            $0.nameSimple.localizedStandardContains(query)
                || $0.nameArabic.arabicSearchFolded.localizedStandardContains(foldedQuery)
                || String($0.id) == query
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text("Search")
                    .font(.system(size: 46, weight: .heavy))
                    .foregroundStyle(.white)

                HStack(spacing: 18) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.6))
                    SearchTextField(
                        text: $searchText,
                        isFocused: $isFieldFocused,
                        placeholder: "Surah name or number",
                        fontSize: 30
                    )
                    .frame(height: 40)
                }
                .padding(.horizontal, 32)
                .frame(height: 72)
                .frame(maxWidth: 760)
                .background(Capsule().fill(Theme.pillFill))
                .overlay(
                    Capsule().strokeBorder(Theme.accent.opacity(isFieldFocused ? 0.9 : 0), lineWidth: 2)
                )

                if searchText.isEmpty {
                    Text("Start typing to find a Surah.")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.5))
                } else if results.isEmpty {
                    Text("No surahs match \u{201C}\(searchText)\u{201D}.")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(results) { chapter in
                            Button {
                                onSelect(PlaybackTarget(chapter: chapter))
                            } label: {
                                SurahMoodCard(chapter: chapter)
                            }
                            .buttonStyle(CardButtonStyle())
                            .focusEffectDisabled()
                            .contextMenu { bookmarkContextMenuItem(for: chapter, onToggle: onToggleBookmark) }
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
}
