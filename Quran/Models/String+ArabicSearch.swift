import Foundation

extension String {
    /// Folds Arabic text to a loose, search-friendly form: diacritics (tashkeel) stripped,
    /// and common letter variants unified (hamza-bearing alefs, alef maksura, teh marbuta) —
    /// so a search typed on the tvOS on-screen keyboard still matches text from the API that
    /// may use a different (but equivalent) Arabic letter form.
    var arabicSearchFolded: String {
        // The tvOS on-screen Arabic keyboard has a dedicated "لا" (lam-alef) key that can insert
        // a single precomposed ligature codepoint instead of the two separate letters the API
        // text uses. Compatibility decomposition (NFKD) expands that ligature back to "ل" + "ا"
        // before the rest of the folding runs.
        let decomposed = decomposedStringWithCompatibilityMapping
        let folded = decomposed.folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ar"))
        var result = String.UnicodeScalarView()
        for scalar in folded.unicodeScalars {
            switch scalar.value {
            case 0x0622, 0x0623, 0x0625, 0x0671: // آ أ إ ٱ
                result.append(Unicode.Scalar(0x0627)!) // ا
            case 0x0649: // ى
                result.append(Unicode.Scalar(0x064A)!) // ي
            case 0x0629: // ة
                result.append(Unicode.Scalar(0x0647)!) // ه
            case 0x064B...0x0652, 0x0670: // remaining tashkeel/combining marks
                continue
            default:
                result.append(scalar)
            }
        }
        return String(result)
    }
}
