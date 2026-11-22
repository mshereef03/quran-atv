import SwiftUI

/// A slim glowing progress capsule, shared by the player's time bar and the Continue hero card.
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * progress))
                    .shadow(color: .white.opacity(0.5), radius: 4)
            }
        }
        .animation(.linear(duration: 0.4), value: progress)
    }
}
