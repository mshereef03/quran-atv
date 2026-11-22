import Foundation

enum AyahFontSize: Double, CaseIterable, Identifiable {
    case small = 52
    case medium = 68
    case large = 84
    case extraLarge = 100

    var id: Double { rawValue }

    static let storageKey = "ayahFontSize"
    static let `default` = AyahFontSize.medium
}
