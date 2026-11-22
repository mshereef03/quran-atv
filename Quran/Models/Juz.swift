import Foundation

/// One of the Quran's 30 traditional Juz' (reading-section) divisions, with the chapters
/// (and their ayah ranges) it spans — used to let the Surahs screen filter by Juz'.
struct Juz: Decodable, Identifiable {
    let id: Int
    let juzNumber: Int
    let verseMapping: [String: String]

    enum CodingKeys: String, CodingKey {
        case id
        case juzNumber = "juz_number"
        case verseMapping = "verse_mapping"
    }

    var chapterIDs: Set<Int> {
        Set(verseMapping.keys.compactMap { Int($0) })
    }
}

struct JuzsResponse: Decodable {
    let juzs: [Juz]
}
