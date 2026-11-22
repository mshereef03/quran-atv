import Foundation

enum AppFont: String, CaseIterable, Identifiable {
    case harmattan = "Harmattan"
    case amiriQuran = "Amiri Quran"
    case scheherazadeNew = "Scheherazade New"

    var id: String { rawValue }

    static let storageKey = "selectedFontName"
    static let `default` = AppFont.harmattan
}
