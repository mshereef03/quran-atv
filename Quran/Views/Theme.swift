import SwiftUI

/// Shared color system: a deep, near-black green backdrop with a mint accent —
/// matching a reference "Tilawah"-style design the user supplied.
enum Theme {
    static let backgroundTop = Color(red: 0.08, green: 0.14, blue: 0.10)
    static let backgroundBottom = Color(red: 0.03, green: 0.05, blue: 0.035)
    /// A brighter center glow used for the player's radial "spotlight" backdrop.
    static let backgroundGlow = Color(red: 0.16, green: 0.26, blue: 0.19)
    static let accent = Color(red: 0.56, green: 0.85, blue: 0.68)
    static let cardFill = Color(red: 0.10, green: 0.15, blue: 0.12)
    static let cardFillFocused = Color(red: 0.14, green: 0.20, blue: 0.16)
    static let pillFill = Color(red: 0.11, green: 0.16, blue: 0.13)
}
