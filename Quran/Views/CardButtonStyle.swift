import SwiftUI

/// A button style that fully replaces system chrome — unlike `.plain` combined with
/// `.focusEffectDisabled()`, which can still leave a faint focus platter showing through
/// on compound/multi-region content. The label itself reads `@Environment(\.isFocused)`
/// for its own border/scale/color feedback.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
