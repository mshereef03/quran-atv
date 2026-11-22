import SwiftUI

/// A surah tile: a numbered, photo-backed card with Arabic calligraphy, and the
/// English name + metadata set below it — matching the reference design's card language.
struct SurahMoodCard: View {
    let chapter: Chapter
    var cardWidth: CGFloat = 340
    @Environment(\.isFocused) private var isFocused
    @AppStorage(AppFont.storageKey) private var selectedFontName: String = AppFont.default.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Image(MoodPhoto.forID(chapter.id).rawValue)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: 214)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.68), Color.black.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text("سورة " + chapter.nameArabic)
                    .font(.custom(selectedFontName, size: 37))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                VStack {
                    HStack {
                        Text(String(format: "%02d", chapter.id))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        if isFocused {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(8)
                                .background(Circle().fill(Theme.accent))
                        }
                    }
                    Spacer()
                }
                .padding(14)
            }
            .frame(width: cardWidth, height: 214)
            .background(Theme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Theme.accent.opacity(isFocused ? 0.9 : 0), lineWidth: 2.5)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(chapter.nameSimple)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isFocused ? Theme.accent : .white)
                Text("\(chapter.revelationLabelEnglish) · \(chapter.versesCount) Ayahs")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .scaleEffect(isFocused ? 1.035 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
