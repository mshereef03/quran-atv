import SwiftUI

struct TopBar: View {
    @Binding var selectedTab: AppTab
    let activePlayer: PlayerViewModel?
    let onShowPlayer: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 32) {
            Text("القرآن")
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.titleEnglish)
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(TabPillButtonStyle(isSelected: selectedTab == tab))
                }
            }
            .padding(7)
            .background(Capsule().fill(Theme.pillFill))

            Spacer()

            HStack(spacing: 18) {
                if let activePlayer {
                    NowPlayingPill(player: activePlayer, onTap: onShowPlayer)
                }

                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(SettingsIconButtonStyle())
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 36)
    }
}

/// A small view dedicated to observing the active player, so it can own a non-optional
/// `@ObservedObject` subscription and reactively show/hide itself the moment `isPlaying`
/// changes — `@ObservedObject` doesn't support an Optional wrapped type directly.
private struct NowPlayingPill: View {
    @ObservedObject var player: PlayerViewModel
    let onTap: () -> Void

    var body: some View {
        if player.isPlaying {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                    Text(player.chapter.nameSimple)
                }
                .font(.system(size: 23, weight: .semibold))
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlayQuickActionButtonStyle())
        }
    }
}

private struct TabPillButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        TabPillBody(configuration: configuration, isSelected: isSelected)
    }

    fileprivate struct TabPillBody: View {
        let configuration: Configuration
        let isSelected: Bool
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .foregroundStyle(isSelected ? .black : .white.opacity(0.75))
                .background(
                    Capsule().fill(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.clear))
                )
                .overlay(
                    Capsule().strokeBorder(Theme.accent.opacity(isFocused && !isSelected ? 0.8 : 0), lineWidth: 2)
                )
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}

private struct PlayQuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PlayQuickActionBody(configuration: configuration)
    }

    fileprivate struct PlayQuickActionBody: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .foregroundStyle(.black)
                .background(Capsule().fill(Theme.accent.opacity(isFocused ? 1 : 0.85)))
                .scaleEffect(isFocused ? 1.06 : 1.0)
                .shadow(color: .black.opacity(isFocused ? 0.4 : 0), radius: 12, y: 6)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}

private struct SettingsIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SettingsIconBody(configuration: configuration)
    }

    fileprivate struct SettingsIconBody: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .background(Circle().fill(Theme.pillFill))
                .overlay(
                    Circle().strokeBorder(Theme.accent.opacity(isFocused ? 0.9 : 0), lineWidth: 2)
                )
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}
