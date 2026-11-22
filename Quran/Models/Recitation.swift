import Foundation

struct Recitation: Identifiable, Decodable, Hashable {
    let id: Int
    let englishName: String
    let style: String?
    let translatedName: TranslatedName

    var arabicName: String { translatedName.name }

    struct TranslatedName: Decodable, Hashable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case englishName = "reciter_name"
        case style
        case translatedName = "translated_name"
    }
}

struct RecitationsResponse: Decodable {
    let recitations: [Recitation]
}
