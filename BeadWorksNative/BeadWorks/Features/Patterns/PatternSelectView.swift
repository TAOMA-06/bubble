import SwiftUI

struct PatternSelectView: View {
    @Binding var path: NavigationPath
    private let patterns = BuiltinPatternFactory.all()

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("示例图纸")
                        .font(.title2.bold())
                        .foregroundStyle(BeadWorksTheme.ink)
                    Text("半透明引导摆豆，可打开纠错提示。这些是调试/示例内容，不是关卡。")
                        .font(.subheadline)
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.58))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                        ForEach(patterns) { pattern in
                            Button {
                                path.append(Route.editor(.template(pattern: pattern)))
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    BeadBoardCanvas(board: pattern.previewBoard, style: .editing, showGuide: false)
                                        .padding(8)
                                        .background(BeadWorksTheme.pegboardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    Text(pattern.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(BeadWorksTheme.ink)
                                    Text("16×16 复刻")
                                        .font(.caption)
                                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.5))
                                }
                                .padding(12)
                                .beadPanel(cornerRadius: 16)
                            }
                            .buttonStyle(PressableCardStyle())
                            .accessibilityIdentifier("patternCard_\(pattern.id)")
                            .accessibilityLabel(pattern.title)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("示例图纸")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BeadWorksTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
