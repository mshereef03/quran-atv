import SwiftUI

struct SurahsView: View {
    let chapters: [Chapter]
    let juzs: [Juz]
    let onSelect: (PlaybackTarget) -> Void
    let onSearch: () -> Void
    let onToggleBookmark: (Int) -> Void

    @State private var filter: RevelationFilter = .all
    @State private var selectedJuz: Int?

    private let columns = [GridItem(.adaptive(minimum: 340, maximum: 340), spacing: 48)]

    private var filteredChapters: [Chapter] {
        chapters.filter { filter.matches($0) && matchesSelectedJuz($0) }
    }

    private func matchesSelectedJuz(_ chapter: Chapter) -> Bool {
        guard let selectedJuz, let juz = juzs.first(where: { $0.juzNumber == selectedJuz }) else {
            return true
        }
        return juz.chapterIDs.contains(chapter.id)
    }

    /// Summarizes whichever filters are active so the single filter button's label reflects
    /// the current state at a glance, instead of just saying "Filter" once something is set.
    private var activeFilterLabel: String? {
        var parts: [String] = []
        if filter != .all { parts.append(filter.title) }
        if let selectedJuz { parts.append("Juz \(selectedJuz)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All Surahs")
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("\(filteredChapters.count) of \(chapters.count) chapters available for ayah-by-ayah streaming")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(maxWidth: 460, alignment: .leading)
                    }

                    Spacer()

                    HStack(spacing: 18) {
                        Button(action: onSearch) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                            }
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(FilterPillButtonStyle(isSelected: false))

                        Menu {
                            Section("Revelation") {
                                ForEach(RevelationFilter.allCases) { option in
                                    Button {
                                        filter = option
                                    } label: {
                                        if filter == option {
                                            Label(option.title, systemImage: "checkmark")
                                        } else {
                                            Text(option.title)
                                        }
                                    }
                                }
                            }

                            if !juzs.isEmpty {
                                Section("Juz\u{2019}") {
                                    Button {
                                        selectedJuz = nil
                                    } label: {
                                        if selectedJuz == nil {
                                            Label("All Juz\u{2019}", systemImage: "checkmark")
                                        } else {
                                            Text("All Juz\u{2019}")
                                        }
                                    }
                                    ForEach(juzs) { juz in
                                        Button {
                                            selectedJuz = juz.juzNumber
                                        } label: {
                                            if selectedJuz == juz.juzNumber {
                                                Label("Juz \(juz.juzNumber)", systemImage: "checkmark")
                                            } else {
                                                Text("Juz \(juz.juzNumber)")
                                            }
                                        }
                                    }
                                }
                            }

                            if filter != .all || selectedJuz != nil {
                                Section {
                                    Button(role: .destructive) {
                                        filter = .all
                                        selectedJuz = nil
                                    } label: {
                                        Text("Clear Filters")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text(activeFilterLabel ?? "Filter")
                            }
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(FilterPillButtonStyle(isSelected: filter != .all || selectedJuz != nil))
                    }
                }
                .focusSection()

                LazyVGrid(columns: columns, spacing: 40) {
                    ForEach(filteredChapters) { chapter in
                        Button {
                            onSelect(PlaybackTarget(chapter: chapter))
                        } label: {
                            SurahMoodCard(chapter: chapter)
                        }
                        .buttonStyle(CardButtonStyle())
                        .focusEffectDisabled()
                        .contextMenu { bookmarkContextMenuItem(for: chapter, onToggle: onToggleBookmark) }
                    }
                }
                .focusSection()
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
}

enum RevelationFilter: String, CaseIterable, Identifiable {
    case all, meccan, medinan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .meccan: return "Meccan"
        case .medinan: return "Medinan"
        }
    }

    func matches(_ chapter: Chapter) -> Bool {
        switch self {
        case .all: return true
        case .meccan: return chapter.revelationPlace == "makkah"
        case .medinan: return chapter.revelationPlace == "madinah"
        }
    }
}

private struct FilterPillButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        FilterPillBody(configuration: configuration, isSelected: isSelected)
    }

    fileprivate struct FilterPillBody: View {
        let configuration: Configuration
        let isSelected: Bool
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .foregroundStyle(isSelected ? .black : .white.opacity(0.75))
                .background(Capsule().fill(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.clear)))
                .overlay(Capsule().strokeBorder(Theme.accent.opacity(isFocused && !isSelected ? 0.8 : 0), lineWidth: 2))
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.18), value: isFocused)
        }
    }
}

