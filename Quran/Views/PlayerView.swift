import SwiftUI

struct PlayerView: View {
    /// Owned by `RootView`, not this view — so popping back out of the player just hides
    /// this screen while playback keeps running, instead of tearing down the session.
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppFont.storageKey) private var selectedFontName: String = AppFont.default.rawValue
    @AppStorage(AyahFontSize.storageKey) private var selectedFontSize: Double = AyahFontSize.default.rawValue
    @AppStorage(QuranAPIClient.reciterStorageKey) private var selectedReciterID: Int = QuranAPIClient.defaultReciterID
    @AppStorage(QuranAPIClient.reciterNameStorageKey) private var selectedReciterName: String = QuranAPIClient.defaultReciterName
    @AppStorage(TranslationPreference.storageKey) private var showTranslation = false
    let startIndex: Int
    @State private var controlsVisible = true
    @State private var hideWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Theme.backgroundGlow, Theme.backgroundBottom],
                center: .center,
                startRadius: 0,
                endRadius: 1000
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if let message = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Text(message)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 700)
                    Button("Go Back") {
                        viewModel.stop()
                        dismiss()
                    }
                    .font(.system(size: 22))
                }
            } else if viewModel.finished {
                VStack(spacing: 28) {
                    Text("Surah Complete")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                    Button("Done") {
                        viewModel.stop()
                        dismiss()
                    }
                    .font(.system(size: 22))
                }
            } else if let verse = viewModel.currentVerse {
                VStack(spacing: 0) {
                    // `ScrollView` doesn't work here: tvOS scrolling is driven by focus
                    // moving between focusable children, and plain Text has nothing
                    // focusable in it, so a scroll view around it can't actually be scrolled
                    // via the remote. Auto-shrinking to fit needs no interaction at all, so
                    // it's the correct tool for the Quran's longest ayahs.
                    Spacer()
                    (
                        Text(verse.textUthmani).foregroundStyle(.white)
                            + Text(verse.ayahMarkSuffix).foregroundStyle(Theme.accent)
                    )
                        .font(.custom(selectedFontName, size: selectedFontSize))
                        .multilineTextAlignment(.center)
                        .lineSpacing(20)
                        .minimumScaleFactor(0.35)
                        .padding(.horizontal, 160)

                    if showTranslation, let translation = verse.translationText {
                        Text(translation)
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 220)
                            .padding(.top, 28)
                    }
                    Spacer()

                    if controlsVisible {
                        transportBar
                            .transition(.opacity)
                    } else {
                        Color.clear
                            .frame(width: 1, height: 1)
                            .contentShape(Rectangle())
                            .focusable(true)
                            .focusEffectDisabled()
                            .onMoveCommand { _ in revealControls() }
                            .padding(.bottom, 50)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: controlsVisible)
            }
        }
        .task {
            await viewModel.start(reciterID: selectedReciterID, reciterName: selectedReciterName, startIndex: startIndex)
            scheduleAutoHide()
        }
        .onDisappear {
            hideWorkItem?.cancel()
        }
        .onPlayPauseCommand {
            viewModel.togglePlay()
            revealControls()
        }
        .onMoveCommand { _ in revealControls() }
        .onExitCommand {
            if isShowingPlaybackControls {
                hideWorkItem?.cancel()
                withAnimation(.easeInOut(duration: 0.25)) {
                    controlsVisible = false
                }
            } else {
                dismiss()
            }
        }
    }

    /// Whether the Menu button should hide the transport controls (first press) rather than
    /// leave the player (second press) — only applies to the normal playing state, so error/
    /// loading/finished screens still dismiss on the very first press as expected.
    private var isShowingPlaybackControls: Bool {
        controlsVisible
            && viewModel.currentVerse != nil
            && !viewModel.isLoading
            && viewModel.errorMessage == nil
            && !viewModel.finished
    }

    private func revealControls() {
        withAnimation(.easeInOut(duration: 0.25)) {
            controlsVisible = true
        }
        scheduleAutoHide()
    }

    private func scheduleAutoHide() {
        hideWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) {
                controlsVisible = false
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    private var transportBar: some View {
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                Text("Surah \(viewModel.chapter.nameSimple)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(selectedReciterName) · \(viewModel.currentIndex + 1) / \(viewModel.verses.count)")
                    .font(.system(size: 21))
                    .foregroundStyle(.white.opacity(0.55))
            }

            HStack(spacing: 18) {
                Text(viewModel.elapsedSeconds.timeString)
                    .font(.system(size: 21).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))

                ProgressBar(progress: viewModel.progress)
                    .frame(height: 6)

                Text("-" + max(0, viewModel.totalSeconds - viewModel.elapsedSeconds).timeString)
                    .font(.system(size: 21).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: 900)

            HStack(spacing: 60) {
                Button {
                    viewModel.skipToPrevious()
                    revealControls()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 29))
                        .foregroundStyle(.white)
                }
                .buttonStyle(TransportButtonStyle(diameter: 72, prominent: false))

                Button {
                    viewModel.togglePlay()
                    revealControls()
                } label: {
                    if viewModel.isBuffering {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(TransportButtonStyle(diameter: 104, prominent: true))

                Button {
                    viewModel.skipToNext()
                    revealControls()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 29))
                        .foregroundStyle(.white)
                }
                .buttonStyle(TransportButtonStyle(diameter: 72, prominent: false))
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 90)
        .padding(.bottom, 70)
    }
}

private struct TransportButtonStyle: ButtonStyle {
    let diameter: CGFloat
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        TransportButtonBody(configuration: configuration, diameter: diameter, prominent: prominent)
    }

    private struct TransportButtonBody: View {
        let configuration: Configuration
        let diameter: CGFloat
        let prominent: Bool
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .frame(width: diameter, height: diameter)
                .background(
                    Circle().fill(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(Color.white.opacity(isFocused ? 0.22 : 0.12)))
                )
                .overlay(
                    Circle().strokeBorder(Theme.accent.opacity(isFocused ? 0.9 : 0), lineWidth: 3)
                )
                .scaleEffect(isFocused ? 1.12 : 1.0)
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 18, y: 10)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}
