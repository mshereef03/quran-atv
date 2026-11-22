import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case listenNow
    case surahs
    case reciters

    var id: String { rawValue }

    var titleArabic: String {
        switch self {
        case .listenNow: return "استماع"
        case .surahs: return "السور"
        case .reciters: return "القرّاء"
        }
    }

    var titleEnglish: String {
        switch self {
        case .listenNow: return "Listen Now"
        case .surahs: return "Surahs"
        case .reciters: return "Reciters"
        }
    }
}
