import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab: AppTab = .listenNow
    @State private var selectedTarget: PlaybackTarget?
    @State private var activePlayerViewModel: PlayerViewModel?
    @State private var showSettings = false
    @State private var showSearch = false
    @AppStorage(QuranAPIClient.reciterNameStorageKey) private var selectedReciterName: String = QuranAPIClient.defaultReciterName
    @AppStorage(QuranAPIClient.reciterStorageKey) private var selectedReciterID: Int = QuranAPIClient.defaultReciterID

    var body: some View {
        Group {
            if selectedTab == .listenNow {
                mainContent
            } else {
                // Tabs are a state switch, not separate pushed screens, so there's nothing
                // for the system to pop here — without this, the Menu button would exit the
                // app straight to the tvOS Home Screen instead of going back to Listen Now.
                mainContent
                    .onExitCommand { selectedTab = .listenNow }
            }
        }
        .navigationDestination(item: $selectedTarget) { target in
            if let activePlayerViewModel {
                PlayerView(viewModel: activePlayerViewModel, startIndex: target.startIndex)
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showSearch) {
            SearchView(
                chapters: viewModel.chapters,
                onSelect: {
                    presentPlayer(for: $0)
                    showSearch = false
                },
                onToggleBookmark: { viewModel.toggleBookmark(chapterID: $0) }
            )
        }
        .task {
            await viewModel.load()
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var mainContent: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 0) {
                TopBar(
                    selectedTab: $selectedTab,
                    activePlayer: activePlayerViewModel,
                    onShowPlayer: {
                        if let activePlayerViewModel {
                            presentPlayer(for: PlaybackTarget(chapter: activePlayerViewModel.chapter))
                        }
                    },
                    onSettings: { showSettings = true }
                )
                .focusSection()

                if viewModel.isLoading && viewModel.chapters.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Spacer()
                } else if let message = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 20) {
                        Text(message).foregroundStyle(.white)
                        Button("Try Again") {
                            Task { await viewModel.load() }
                        }
                    }
                    Spacer()
                } else {
                    Group {
                        switch selectedTab {
                        case .listenNow:
                            ListenNowView(
                                chapters: viewModel.chapters,
                                continueTarget: viewModel.continueTarget,
                                bookmarkedChapters: viewModel.bookmarkedChapters,
                                recentlyPlayedChapters: viewModel.recentlyPlayedChapters,
                                reciterName: selectedReciterName,
                                onSelect: { presentPlayer(for: $0) },
                                onToggleBookmark: { viewModel.toggleBookmark(chapterID: $0) }
                            )
                        case .surahs:
                            SurahsView(
                                chapters: viewModel.chapters,
                                juzs: viewModel.juzs,
                                onSelect: { presentPlayer(for: $0) },
                                onSearch: { showSearch = true },
                                onToggleBookmark: { viewModel.toggleBookmark(chapterID: $0) }
                            )
                        case .reciters:
                            RecitersView()
                        }
                    }
                }
            }
        }
    }

    /// Reuses the active player if it's already playing this chapter with the currently
    /// selected reciter (so pressing play on the same surah again doesn't restart it),
    /// otherwise stops whatever was playing and starts a fresh session for the new one.
    /// A reciter change always forces a fresh session, even for the same chapter, since
    /// that's effectively a different audio source.
    private func presentPlayer(for target: PlaybackTarget) {
        let isSameSession = activePlayerViewModel?.chapter.id == target.chapter.id
            && activePlayerViewModel?.reciterID == selectedReciterID
        if !isSameSession {
            activePlayerViewModel?.stop()
            activePlayerViewModel = PlayerViewModel(chapter: target.chapter)
        } else if target.forceRestart {
            activePlayerViewModel?.jumpToAyah(target.startIndex)
        }
        selectedTarget = target
    }
}
