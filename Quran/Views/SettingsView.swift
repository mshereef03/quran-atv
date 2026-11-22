import SwiftUI

struct SettingsView: View {
    @AppStorage(AppFont.storageKey) private var selectedFontName: String = AppFont.default.rawValue
    @AppStorage(AyahFontSize.storageKey) private var selectedFontSize: Double = AyahFontSize.default.rawValue
    @AppStorage(TranslationPreference.storageKey) private var showTranslation = false

    private let fontColumns = [GridItem(.adaptive(minimum: 380, maximum: 500), spacing: 28)]
    private let sizeColumns = [GridItem(.adaptive(minimum: 230, maximum: 290), spacing: 28)]
    private let sampleText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 48) {
                    sectionHeader("Font")
                    LazyVGrid(columns: fontColumns, spacing: 24) {
                        ForEach(AppFont.allCases) { font in
                            Button {
                                selectedFontName = font.rawValue
                            } label: {
                                VStack(spacing: 16) {
                                    Text(sampleText)
                                        .font(.custom(font.rawValue, size: 35))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.white)
                                    checkmark(selectedFontName == font.rawValue)
                                }
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, minHeight: 180)
                            }
                            .buttonStyle(GlassCardButtonStyle())
                        }
                    }
                    .focusSection()

                    sectionHeader("Font Size")
                    LazyVGrid(columns: sizeColumns, spacing: 24) {
                        ForEach(AyahFontSize.allCases) { size in
                            Button {
                                selectedFontSize = size.rawValue
                            } label: {
                                VStack(spacing: 12) {
                                    Text("ا")
                                        .font(.custom(selectedFontName, size: size.rawValue * 0.5))
                                        .foregroundStyle(.white)
                                    checkmark(selectedFontSize == size.rawValue)
                                }
                                .frame(maxWidth: .infinity, minHeight: 180)
                            }
                            .buttonStyle(GlassCardButtonStyle())
                        }
                    }
                    .focusSection()

                    sectionHeader("English Translation")
                    HStack(spacing: 24) {
                        Button {
                            showTranslation = true
                        } label: {
                            VStack(spacing: 12) {
                                Text("On")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                                checkmark(showTranslation)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                        }
                        .buttonStyle(GlassCardButtonStyle())

                        Button {
                            showTranslation = false
                        } label: {
                            VStack(spacing: 12) {
                                Text("Off")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                                checkmark(!showTranslation)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                        }
                        .buttonStyle(GlassCardButtonStyle())
                    }
                    .frame(maxWidth: 500)
                    .focusSection()

                    sectionHeader("About")
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Quran data provided by Quran Foundation.")
                        Text("Recitation audio courtesy of each reciter featured in the app.")
                        Text("This app is open source: github.com/mshereef03/quran-atv")
                        Text("Feedback: quranappletv@gmail.com")
                    }
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.horizontal, 90)
                .padding(.vertical, 60)
            }
        }
        .navigationTitle("Settings")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checkmark(_ isSelected: Bool) -> some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Theme.accent)
            .opacity(isSelected ? 1 : 0)
    }
}
