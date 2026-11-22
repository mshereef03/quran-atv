import Foundation

extension Int {
    /// This number rendered with Arabic-Indic digits (٠١٢...), as printed in a Mushaf.
    var arabicIndicString: String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(self).compactMap { $0.wholeNumberValue }.map { digits[$0] }.joined()
    }
}
