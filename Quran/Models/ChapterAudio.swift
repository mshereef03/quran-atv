import Foundation

/// A reciter's single continuous recording of a whole surah, with per-ayah timing so the
/// app can sync displayed text and seek to a given ayah without ever cutting the audio.
struct ChapterAudioFile: Decodable {
    let audioURL: String
    let timestamps: [VerseTiming]

    enum CodingKeys: String, CodingKey {
        case audioURL = "audio_url"
        case timestamps
    }
}

struct VerseTiming: Decodable {
    let verseKey: String
    /// Milliseconds from the start of the chapter's audio file.
    let timestampFrom: Int
    let timestampTo: Int

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case timestampFrom = "timestamp_from"
        case timestampTo = "timestamp_to"
    }
}

struct ChapterAudioResponse: Decodable {
    let audioFile: ChapterAudioFile

    enum CodingKeys: String, CodingKey {
        case audioFile = "audio_file"
    }
}
