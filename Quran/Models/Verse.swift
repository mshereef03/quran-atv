import Foundation

struct Verse: Identifiable, Decodable, Hashable {
    let id: Int
    let verseKey: String
    let textUthmani: String
    let translations: [Translation]?

    /// The English translation text (Saheeh International), with Quran.com's footnote
    /// markup stripped out.
    var translationText: String? {
        translations?.first?.text.strippingHTMLTags
    }

    struct Translation: Decodable, Hashable {
        let text: String
    }

    /// The ayah text followed by the traditional Quranic end-of-ayah ornament (﴿۝﴾)
    /// with its verse number set in Arabic-Indic digits, as printed in a Mushaf.
    var textWithAyahMark: String {
        textUthmani + ayahMarkSuffix
    }

    /// Just the end-of-ayah ornament + verse number, so callers can color it distinctly
    /// from the body text (as printed Mushafs typically pick out in a second color).
    var ayahMarkSuffix: String {
        guard let ayahNumber = Int(verseKey.split(separator: ":").last ?? "") else {
            return ""
        }
        return " \u{06DD}" + ayahNumber.arabicIndicString
    }

    enum CodingKeys: String, CodingKey {
        case id
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
        case translations
    }
}

private extension String {
    var strippingHTMLTags: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

struct VersesResponse: Decodable {
    let verses: [Verse]
    let pagination: Pagination
}

struct Pagination: Decodable {
    let currentPage: Int
    let nextPage: Int?
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case nextPage = "next_page"
        case totalPages = "total_pages"
    }
}
