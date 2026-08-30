import SwiftUI

struct HomeView: View {
    @Environment(BoardStore.self) private var boardStore
    @State private var path = NavigationPath()
    @State private var showSizeOptions = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BeadWorksTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        VStack(spacing: 14) {
                            if let draft = boardStore.draft {
                                continueDraftButton(draft)
                            }

                            MenuButton(
                                title: "自由创作",
                                subtitle: "选择一块板子，从第一颗珠子开始",
                                systemImage: "square.grid.3x3.fill"
                            ) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    showSizeOptions.toggle()
                                }
                            }
                            if showSizeOptions {
                                sizeOptionsSection
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            MenuButton(
                                title: "导入图片",
                                subtitle: "把照片变成可摆放的拼豆模板",
                                systemImage: "photo.on.rectangle.angled"
                            ) {
                                path.append(Route.photoImport)
                            }
                            MenuButton(
                                title: "作品库",
                                subtitle: "查看已完成的作品",
                                systemImage: "square.grid.2x2"
                            ) {
                                path.append(Route.gallery)
                            }

                            Button {
                                path.append(Route.patternSelect)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.grid.3x3.topleft.filled")
                                    Text("示例图纸")
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(BeadWorksTheme.ink.opacity(0.62))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .accessibilityIdentifier("menuButton_示例图纸")
                        }
                        .padding(.horizontal, 22)

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 38)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .editor(let context):
                    BoardEditorView(context: context)
                case .photoImport:
                    PhotoImportView(path: $path)
                case .patternSelect:
                    PatternSelectView(path: $path)
                case .gallery:
                    GalleryView(path: $path)
                case .galleryDetail(let work):
                    GalleryDetailView(work: work, path: $path)
                }
            }
        }
    }

    private func continueDraftButton(_ draft: WorkshopDraft) -> some View {
        Button {
            path.append(Route.editor(.restored(board: draft.board, title: draft.context.title)))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BeadWorksTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("继续上次创作")
                        .font(.headline)
                        .foregroundStyle(BeadWorksTheme.ink)
                    Text("\(draft.board.width)×\(draft.board.height) · 已摆 \(draft.board.filledCount) 颗")
                        .font(.caption)
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.55))
                }
                Spacer()
            }
            .padding(14)
            .beadPanel(cornerRadius: 16, fill: BeadWorksTheme.paperBackground)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("continueDraftButton")
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BeadWorksTheme.paperBackground.opacity(0.9))
                    .frame(width: 194, height: 128)
                    .rotationEffect(.degrees(-2))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)

                BeadMark(diameter: 11, spacing: 5, padding: 10)
                    .offset(x: -54, y: -28)

                VStack(spacing: 4) {
                    Text("bubble")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(BeadWorksTheme.ink)
                        .tracking(1)
                    Text("拼豆工坊")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.62))
                        .tracking(3)
                }
                .offset(y: 8)
            }

            HStack(spacing: 8) {
                MaterialNote(text: "圆珠像素", systemImage: "circle.grid.3x3.fill")
                MaterialNote(text: "29×29 标准板", systemImage: "square.grid.3x3")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeHeader")
    }

    private var sizeOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择拼豆板")
                .font(.caption.weight(.bold))
                .foregroundStyle(BeadWorksTheme.ink.opacity(0.62))
                .textCase(.uppercase)

            ForEach(BoardSizeOption.freeformOptions) { option in
                BoardSizeOptionButton(option: option) {
                    path.append(Route.editor(.freeform(size: option.size)))
                }
            }
        }
        .padding(12)
        .beadPanel(cornerRadius: BeadWorksTheme.panelCornerRadius, fill: BeadWorksTheme.trayBackground.opacity(0.86))
        .accessibilityIdentifier("boardSizeOptions")
    }
}

#Preview {
    HomeView()
        .environment(BoardStore())
}
