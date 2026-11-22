import SwiftUI

/// The app's backdrop: a clean, deep green-black studio gradient. Kept neutral so
/// content (and the per-card mood photos) stays the visual focus.
struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.backgroundTop, Theme.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
