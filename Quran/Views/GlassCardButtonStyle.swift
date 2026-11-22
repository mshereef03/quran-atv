import SwiftUI

/// The standard tvOS tile style used across the app: an opaque elevated surface
/// (not a translucent "glass" effect) with a clear, high-contrast focus state.
/// Sizing is the caller's responsibility — give the label its own `.frame(...)`.
struct GlassCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TileBody(configuration: configuration)
    }

    private struct TileBody: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isFocused ? Theme.cardFillFocused : Theme.cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Theme.accent.opacity(isFocused ? 0.85 : 0), lineWidth: 2)
                )
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0.25), radius: isFocused ? 20 : 8, y: isFocused ? 12 : 4)
                .scaleEffect(isFocused ? 1.07 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isFocused)
        }
    }
}
