import Foundation

struct Chapter: Identifiable, Decodable, Hashable {
    let id: Int
    let nameArabic: String
    let nameSimple: String
    let versesCount: Int
    let revelationPlace: String

    /// "مكية" or "مدنية" — whether this surah was revealed in Makkah or Madinah.
    var revelationLabel: String {
        revelationPlace == "makkah" ? "مكية" : "مدنية"
    }

    var revelationLabelEnglish: String {
        revelationPlace == "makkah" ? "Meccan" : "Medinan"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case nameArabic = "name_arabic"
        case nameSimple = "name_simple"
        case versesCount = "verses_count"
        case revelationPlace = "revelation_place"
    }
}

struct ChaptersResponse: Decodable {
    let chapters: [Chapter]
}
