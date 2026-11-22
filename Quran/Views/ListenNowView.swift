import SwiftUI

struct ListenNowView: View {
    let chapters: [Chapter]
    let continueTarget: PlaybackTarget?
    let bookmarkedChapters: [Chapter]
    let recentlyPlayedChapters: [Chapter]
    let reciterName: String
    let onSelect: (PlaybackTarget) -> Void
    let onToggleBookmark: (Int) -> Void

    @AppStorage(AppFont.storageKey) private var selectedFontName: String = AppFont.default.rawValue

    /// Well-known short surahs, popular for quick daily listening.
    private static let shortSurahIDs = [1, 112, 113, 114, 103, 108, 109, 110, 111, 106]
    /// Surahs with longstanding traditions around evening/night recitation.
    private static let eveningIDs = [18, 56, 67, 36, 73]
    /// Default featured pick when there's no listening history yet.
    private static let defaultFeaturedID = 55

    private var featuredChapter: Chapter? {
        if let continueTarget { return continueTarget.chapter }
        return chapters.first { $0.id == Self.defaultFeaturedID } ?? chapters.first
    }

    private func chapters(for ids: [Int]) -> [Chapter] {
        let byID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                if let featured = featuredChapter {
                    heroCard(for: featured)
                        .focusSection()
                }

                shelf(title: "Recently Played", chapters: recentlyPlayedChapters)
                shelf(title: "Bookmarked", chapters: bookmarkedChapters)
                shelf(title: "Short Surahs for Daily Listening", chapters: chapters(for: Self.shortSurahIDs))
                shelf(title: "Evening & Reflection", chapters: chapters(for: Self.eveningIDs))
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private func heroCard(for chapter: Chapter) -> some View {
        let isResuming = continueTarget?.chapter.id == chapter.id

        ZStack(alignment: .leading) {
            Image(MoodPhoto.forID(chapter.id).rawValue)
                .resizable()
                .scaledToFill()
                .frame(height: 480)
                .clipped()
                .blur(radius: 2)

            LinearGradient(
                colors: [Color.black.opacity(0.75), Color.black.opacity(0.35), Color.black.opacity(0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Text(isResuming ? "Continue Listening" : "Featured Recitation")
                        .foregroundStyle(Theme.accent)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    Text(reciterName)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .font(.system(size: 23, weight: .semibold))

                Text("سورة " + chapter.nameArabic)
                    .font(.custom(selectedFontName, size: 50))
                    .foregroundStyle(.white)

                Text("Surah \(chapter.nameSimple)")
                    .font(.system(size: 64, weight: .heavy))
                    .foregroundStyle(.white)

                if isResuming, let continueTarget {
                    Text("Ayah \(continueTarget.startIndex + 1) of \(chapter.versesCount)")
                        .font(.system(size: 23))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("Surah \(chapter.id) · \(chapter.revelationLabelEnglish) · \(chapter.versesCount) Ayahs")
                        .font(.system(size: 23))
                        .foregroundStyle(.white.opacity(0.75))
                }

                HStack(spacing: 18) {
                    Button {
                        onSelect(continueTarget ?? PlaybackTarget(chapter: chapter))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                            Text(isResuming ? "Resume" : "Play Recitation")
                        }
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(FilledPillButtonStyle())

                    if isResuming {
                        Button {
                            onSelect(PlaybackTarget(chapter: chapter, startIndex: 0, forceRestart: true))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Start Over")
                            }
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(OutlinePillButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(52)
        }
        .frame(height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private func shelf(title: String, chapters: [Chapter]) -> some View {
        if !chapters.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 56) {
                        ForEach(chapters) { chapter in
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, -16)
            }
            .focusSection()
        }
    }
}

private struct FilledPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FilledPillBody(configuration: configuration)
    }

    fileprivate struct FilledPillBody: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .foregroundStyle(.black)
                .background(Capsule().fill(Theme.accent.opacity(isFocused ? 1 : 0.9)))
                .scaleEffect(isFocused ? 1.06 : 1.0)
                .shadow(color: .black.opacity(isFocused ? 0.4 : 0), radius: 14, y: 8)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}

private struct OutlinePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OutlinePillBody(configuration: configuration)
    }

    fileprivate struct OutlinePillBody: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.white.opacity(0.12)))
                .overlay(Capsule().strokeBorder(Theme.accent.opacity(isFocused ? 0.9 : 0.3), lineWidth: 2))
                .scaleEffect(isFocused ? 1.06 : 1.0)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}
