import SwiftUI

struct RecitersView: View {
    @AppStorage(QuranAPIClient.reciterStorageKey) private var selectedReciterID: Int = QuranAPIClient.defaultReciterID
    @AppStorage(QuranAPIClient.reciterNameStorageKey) private var selectedReciterName: String = QuranAPIClient.defaultReciterName

    @State private var recitations: [Recitation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 380, maximum: 380), spacing: 48)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reciters")
                        .font(.system(size: 46, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Select a Qari for ayah-by-ayah streaming across all 114 Surahs.")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.55))
                }

                if isLoading {
                    ProgressView().tint(.white)
                } else if let message = errorMessage {
                    Text(message).foregroundStyle(.white)
                } else {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(recitations) { recitation in
                            Button {
                                selectedReciterID = recitation.id
                                selectedReciterName = recitation.arabicName
                            } label: {
                                ReciterMoodCard(recitation: recitation, isSelected: recitation.id == selectedReciterID, cardWidth: 380)
                            }
                            .buttonStyle(CardButtonStyle())
                            .focusEffectDisabled()
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .task {
            guard recitations.isEmpty else { return }
            isLoading = true
            do {
                recitations = try await QuranAPIClient.shared.fetchRecitations()
            } catch {
                errorMessage = "Couldn't load reciters. Check your connection and try again."
            }
            isLoading = false
        }
    }
}
