import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var verses: [Verse] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isLoading = false
    /// True whenever we intend to be playing but audio isn't actually flowing yet — the
    /// initial wait for the stream to buffer, *and* any later stall (e.g. a mid-playback
    /// rebuffer after a network hiccup). Tracking only `AVPlayer`'s `.waitingToPlayAtSpecifiedRate`
    /// status isn't enough: a stall can also surface as `.paused` without us calling `pause()`
    /// ourselves, which would otherwise show no indicator at all and look like a dead freeze.
    @Published private(set) var isBuffering = false
    @Published var errorMessage: String?
    @Published private(set) var finished: Bool = false
    @Published private(set) var elapsedSeconds: Double = 0
    @Published private(set) var totalSeconds: Double = 0

    var currentVerse: Verse? {
        guard verses.indices.contains(currentIndex) else { return nil }
        return verses[currentIndex]
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1, max(0, elapsedSeconds / totalSeconds))
    }

    let chapter: Chapter
    /// Which reciter this session was built with, so callers can tell a reciter change
    /// apart from "same chapter, just re-opening the player" and start a fresh session.
    private(set) var reciterID: Int?

    private var reciterName: String = ""
    private var nowPlayingArtwork: MPMediaItemArtwork?
    private var player: AVPlayer?
    /// Each verse's time range within the reciter's single continuous surah recording —
    /// naturally gapless, since this is the reciter's actual unsegmented audio rather than
    /// separate per-ayah clips stitched together.
    private var verseRanges: [CMTimeRange] = []
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    /// Suppresses the periodic time-observer while a seek is in flight, so its stale
    /// (pre-seek) position doesn't clobber the ayah index a rapid skip just set — without
    /// this, quickly tapping skip forward/back repeatedly appeared to do nothing, since the
    /// observer kept snapping the display back before the previous seek had settled.
    private var isSeeking = false
    private var pendingSeekWorkItem: DispatchWorkItem?

    init(chapter: Chapter) {
        self.chapter = chapter
    }

    func start(reciterID: Int, reciterName: String, startIndex: Int = 0) async {
        guard verses.isEmpty else { return }
        self.reciterID = reciterID
        self.reciterName = reciterName
        isLoading = true
        errorMessage = nil
        do {
            async let versesTask = QuranAPIClient.shared.fetchVerses(chapterID: chapter.id)
            async let audioTask = QuranAPIClient.shared.fetchChapterAudio(chapterID: chapter.id, reciterID: reciterID)
            let (fetchedVerses, audioFile) = try await (versesTask, audioTask)
            verses = fetchedVerses
            configureAudioSession()
            loadArtwork()
            try setUpPlayer(audioFile: audioFile)
            setUpRemoteCommands()
            if startIndex > 0, verseRanges.indices.contains(startIndex) {
                // Resume position: seek immediately rather than through the debounce used
                // for rapid transport-button taps, so playback doesn't briefly start at 0.
                isSeeking = true
                currentIndex = startIndex
                performSeek(to: startIndex)
            }
            play()
        } catch {
            errorMessage = "Couldn't load this surah. Check your connection and try again."
        }
        isLoading = false
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    private func loadArtwork() {
        guard let image = UIImage(named: MoodPhoto.forID(chapter.id).rawValue) else { return }
        nowPlayingArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }

    private func setUpPlayer(audioFile: ChapterAudioFile) throws {
        guard let url = URL(string: audioFile.audioURL) else {
            throw QuranAPIError.invalidURL
        }

        let timingByVerseKey = Dictionary(uniqueKeysWithValues: audioFile.timestamps.map { ($0.verseKey, $0) })
        var ranges: [CMTimeRange] = []
        for verse in verses {
            guard let timing = timingByVerseKey[verse.verseKey] else {
                throw QuranAPIError.invalidResponse
            }
            let start = CMTime(value: CMTimeValue(timing.timestampFrom), timescale: 1000)
            let end = CMTime(value: CMTimeValue(timing.timestampTo), timescale: 1000)
            ranges.append(CMTimeRange(start: start, end: end))
        }
        verseRanges = ranges
        totalSeconds = ranges.last?.end.seconds ?? 0

        let item = AVPlayerItem(url: url)
        // The default buffering target for a plain progressive MP3 stream can be
        // conservative, waiting longer than necessary before starting playback. A smaller
        // target gets audio starting sooner, at the minor cost of a possible re-buffer if
        // the network briefly stalls later — fine, since that's surfaced by `isBuffering`.
        item.preferredForwardBufferDuration = 3
        let avPlayer = AVPlayer(playerItem: item)
        player = avPlayer

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePlaybackFinished()
            }
            .store(in: &cancellables)

        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .failed {
                    self?.handlePlaybackFailure()
                }
            }
            .store(in: &cancellables)

        avPlayer.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.isBuffering = self.isPlaying && status != .playing
            }
            .store(in: &cancellables)

        let token = avPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            // `Task { @MainActor in }` safely hops to the main actor rather than asserting
            // we're already on it — `assumeIsolated` traps (crashes) if that assumption is
            // ever wrong, which is a real risk this early after a fresh launch.
            Task { @MainActor in
                self?.handleTimeUpdate(time)
            }
        }
        timeObserverToken = token
    }

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipToNext()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipToPrevious()
            return .success
        }

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
    }

    private func tearDownRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Surah \(chapter.nameSimple)",
            MPMediaItemPropertyArtist: reciterName,
            MPMediaItemPropertyAlbumTitle: "Ayah \(currentIndex + 1) of \(verses.count)",
            MPMediaItemPropertyPlaybackDuration: totalSeconds,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let nowPlayingArtwork {
            info[MPMediaItemPropertyArtwork] = nowPlayingArtwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func handleTimeUpdate(_ time: CMTime) {
        guard !isSeeking else { return }
        elapsedSeconds = time.seconds.isFinite ? time.seconds : 0
        if let index = verseRanges.firstIndex(where: { $0.containsTime(time) }), index != currentIndex {
            currentIndex = index
            PlaybackProgressStore.save(chapterID: chapter.id, verseIndex: index)
        }
        updateNowPlayingInfo()
    }

    private func handlePlaybackFinished() {
        isPlaying = false
        finished = true
        PlaybackProgressStore.clear()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func handlePlaybackFailure() {
        isPlaying = false
        errorMessage = "This reciter's audio isn't available for this surah right now. Try a different reciter."
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func togglePlay() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    /// Public entry point for jumping to a specific ayah (e.g. "Start Over" restarting an
    /// already-playing surah from the beginning) — reuses the same debounced seek as the
    /// transport buttons.
    func jumpToAyah(_ index: Int) {
        seek(to: index)
    }

    func skipToNext() {
        guard currentIndex < verseRanges.count - 1 else { return }
        seek(to: currentIndex + 1)
    }

    func skipToPrevious() {
        guard currentIndex > 0 else { return }
        seek(to: currentIndex - 1)
    }

    /// Updates the displayed ayah immediately on every press (so rapid repeated taps always
    /// feel responsive), but debounces the actual `AVPlayer` seek to fire once shortly after
    /// the presses stop. `isSeeking` is set here — the moment the user's intent is known —
    /// not inside the debounced seek itself, so the periodic position-tracker can't sneak in
    /// a stale update during the debounce window and stomp the index back.
    private func seek(to index: Int) {
        guard verseRanges.indices.contains(index) else { return }
        isSeeking = true
        currentIndex = index
        finished = false
        updateNowPlayingInfo()

        pendingSeekWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSeek(to: index)
        }
        pendingSeekWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    /// The debounce guarantees only one of these is ever in flight at a time (any pending
    /// one is cancelled before it runs whenever a newer press comes in), so there's no need
    /// to guard against overlapping/superseded completions here.
    private func performSeek(to index: Int) {
        guard let player, verseRanges.indices.contains(index) else { return }
        let wasPlaying = isPlaying
        player.seek(to: verseRanges[index].start) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.isSeeking = false
                // Go through `self.player`, not the captured local — if `stop()` ran while
                // this seek was in flight, that's nil and this correctly becomes a no-op
                // instead of resurrecting a player nobody references anymore.
                if wasPlaying {
                    self.player?.play()
                    self.isPlaying = true
                }
            }
        }
    }

    func stop() {
        pendingSeekWorkItem?.cancel()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        player?.pause()
        player = nil
        isPlaying = false
        isBuffering = false
        cancellables.removeAll()
        tearDownRemoteCommands()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
