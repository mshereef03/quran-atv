import Foundation

enum QuranAPIError: Error {
    case invalidURL
    case invalidResponse
}

struct QuranAPIClient {
    static let shared = QuranAPIClient()

    /// Mishari Rashid al-`Afasy — a widely-used default reciter.
    static let defaultReciterID = 7
    static let defaultReciterName = "مشاري راشد العفاسي"
    static let reciterStorageKey = "selectedReciterID"
    static let reciterNameStorageKey = "selectedReciterName"
    /// Saheeh International — a widely-used English translation.
    static let englishTranslationID = 20

    private let baseURL = "https://api.quran.com/api/v4"

    func fetchChapters() async throws -> [Chapter] {
        guard let url = URL(string: "\(baseURL)/chapters") else {
            throw QuranAPIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.validate(response)
        return try JSONDecoder().decode(ChaptersResponse.self, from: data).chapters
    }

    /// Reciter IDs whose audio files 404 on Quran.com's own CDN (confirmed by spot-checking
    /// every reciter across several chapters) — excluded so users don't hit a dead end.
    private static let brokenReciterIDs: Set<Int> = [8] // Mohamed Siddiq al-Minshawi — Mujawwad

    func fetchRecitations() async throws -> [Recitation] {
        guard let url = URL(string: "\(baseURL)/resources/recitations?language=ar") else {
            throw QuranAPIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.validate(response)
        let recitations = try JSONDecoder().decode(RecitationsResponse.self, from: data).recitations
        return recitations.filter { !Self.brokenReciterIDs.contains($0.id) }
    }

    func fetchVerses(chapterID: Int) async throws -> [Verse] {
        var allVerses: [Verse] = []
        var page = 1
        while true {
            let urlString = "\(baseURL)/verses/by_chapter/\(chapterID)"
                + "?words=false&fields=text_uthmani&translations=\(Self.englishTranslationID)&per_page=50&page=\(page)"
            guard let url = URL(string: urlString) else {
                throw QuranAPIError.invalidURL
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            try Self.validate(response)
            let decoded = try JSONDecoder().decode(VersesResponse.self, from: data)
            allVerses.append(contentsOf: decoded.verses)
            guard let next = decoded.pagination.nextPage else { break }
            page = next
        }
        return allVerses
    }

    /// The reciter's single continuous recording of the whole surah, with per-ayah timing —
    /// naturally gapless since it's the reciter's actual unsegmented recording, unlike
    /// stitching together separate per-ayah clips.
    func fetchChapterAudio(chapterID: Int, reciterID: Int) async throws -> ChapterAudioFile {
        guard let url = URL(string: "\(baseURL)/chapter_recitations/\(reciterID)/\(chapterID)?segments=true") else {
            throw QuranAPIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.validate(response)
        return try JSONDecoder().decode(ChapterAudioResponse.self, from: data).audioFile
    }

    /// The 30 Juz' divisions with the chapters each spans. The API returns duplicate entries
    /// per `juz_number` (different resource ids, identical mapping), so this keeps one.
    func fetchJuzs() async throws -> [Juz] {
        guard let url = URL(string: "\(baseURL)/juzs") else {
            throw QuranAPIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.validate(response)
        let juzs = try JSONDecoder().decode(JuzsResponse.self, from: data).juzs
        var seen = Set<Int>()
        return juzs
            .filter { seen.insert($0.juzNumber).inserted }
            .sorted { $0.juzNumber < $1.juzNumber }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw QuranAPIError.invalidResponse
        }
    }
}
