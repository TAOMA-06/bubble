import SwiftUI

struct GalleryView: View {
    @Environment(BoardStore.self) private var boardStore
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !boardStore.works.isEmpty {
                        HStack {
                            MaterialNote(text: "\(boardStore.works.count) 件作品", systemImage: "tray.full.fill")
                            MaterialNote(text: "本地保存", systemImage: "externaldrive.fill")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }

                    if boardStore.works.isEmpty {
                        EmptyGalleryState()
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(boardStore.works) { work in
                                GalleryCard(work: work, image: boardStore.previewImage(for: work))
                                    .contextMenu {
                                        Button("删除", role: .destructive) {
                                            boardStore.delete(work)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("作品库")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BeadWorksTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        GalleryView()
    }
    .environment(BoardStore())
}
