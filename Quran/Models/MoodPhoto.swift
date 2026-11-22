import Foundation

/// The 5 nature photos, repurposed as small moody backdrops behind each card's
/// Arabic calligraphy rather than as a busy full-screen background.
enum MoodPhoto: String, CaseIterable {
    case duskLake = "BackgroundDuskLake"
    case sunsetPalms = "BackgroundSunsetPalms"
    case mistyCoast = "BackgroundMistyCoast"
    case jungleOcean = "BackgroundJungleOcean"
    case karstIslands = "BackgroundKarstIslands"

    /// A stable, evenly-distributed photo for a given id (e.g. a chapter or reciter id).
    static func forID(_ id: Int) -> MoodPhoto {
        let all = allCases
        return all[id % all.count]
    }
}
