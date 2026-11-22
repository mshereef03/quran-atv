import SwiftUI

struct ReciterMoodCard: View {
    let recitation: Recitation
    let isSelected: Bool
    var cardWidth: CGFloat = 380
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Image(MoodPhoto.forID(recitation.id).rawValue)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: 214)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.68), Color.black.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(recitation.arabicName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                if !isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "waveform")
                                .font(.system(size: 17))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(14)
                }
            }
            .frame(width: cardWidth, height: 214)
            .background(Theme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Theme.accent.opacity((isSelected || isFocused) ? 0.9 : 0), lineWidth: 2.5)
            )

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(recitation.englishName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isSelected ? Theme.accent : .white)
                    if let style = recitation.style {
                        Text(style)
                            .font(.system(size: 17))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Selected")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .scaleEffect(isFocused ? 1.035 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
