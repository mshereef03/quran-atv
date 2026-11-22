import Foundation

extension Double {
    /// This duration formatted as "m:ss" using Western digits, e.g. "2:05".
    var timeString: String {
        let total = max(0, Int(self.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
