import SwiftUI
import UIKit

struct BoardEditorView: View {
    let context: EditorContext

    @State private var board: BeadBoard
    @State private var selectedColorId: Int
    @State private var toolMode: ToolMode = .place
    @State private var ironedImage: UIImage?
    @State private var showFinished = false

    init(context: EditorContext) {
        self.context = context
        switch context {
        case .freeform(let size):
            _board = State(initialValue: BeadBoard(width: size, height: size))
        case .template(let pattern):
            _board = State(initialValue: BeadBoard(width: pattern.size, height: pattern.size, templateCells: pattern.cells))
        }
        _selectedColorId = State(initialValue: BeadColor.palette[0].id)
    }

    private var title: String {
        switch context {
        case .freeform: return "自由创作"
        case .template: return "拼豆模板"
        }
    }

    private var boardDescription: String {
        if board.width == 29, board.height == 29 {
            return "29×29 标准拼豆板"
        }
        return "\(board.width)×\(board.height) 拼豆板"
    }

    private var selectedColorName: String {
        BeadColor.byId(selectedColorId)?.name ?? "拼豆"
    }

    var body: some View {
        VStack(spacing: 0) {
            workbenchCanvas
            controlConsole
        }
        .background(
            LinearGradient(
                colors: [BeadWorksTheme.workbenchWood, BeadWorksTheme.workbenchWoodDark.opacity(0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BeadWorksTheme.workbenchWood, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: performIroning) {
                    Label("熨烫", systemImage: "flame.fill")
                }
                .tint(BeadWorksTheme.accent)
                .disabled(board.isEmpty)
                .accessibilityIdentifier("ironButton")
            }
        }
        .navigationDestination(isPresented: $showFinished) {
            if let ironedImage {
                FinishedWorkView(board: board, previewImage: ironedImage)
            }
        }
    }

    /// The pegboard sits in a "matted" cream panel on top of a warm wood backdrop, echoing a
    /// real workbench, with a soft shadow to lift it off the wood.
    private var workbenchCanvas: some View {
        GeometryReader { proxy in
            let cellSize = BeadBoardRenderer.cellSize(for: board, in: proxy.size)
            let boardSize = CGSize(
                width: cellSize * CGFloat(board.width),
                height: cellSize * CGFloat(board.height)
            )

            ZStack(alignment: .topLeading) {
                Canvas { graphicsContext, _ in
                    BeadBoardRenderer.draw(board: board, style: .editing, in: graphicsContext, cellSize: cellSize)
                }
                .frame(width: boardSize.width, height: boardSize.height)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let boardOrigin = CGPoint(
                                x: proxy.size.width / 2 - boardSize.width / 2,
                                y: proxy.size.height / 2 - boardSize.height / 2
                            )
                            handleTouch(
                                at: CGPoint(x: value.location.x - boardOrigin.x, y: value.location.y - boardOrigin.y),
                                cellSize: cellSize
                            )
                        }
                )
                .accessibilityIdentifier("boardCanvas")

                HStack(spacing: 8) {
                    MaterialNote(text: boardDescription, systemImage: "square.grid.3x3.fill")
                    MaterialNote(text: "\(board.filledCount) 颗", systemImage: "circle.grid.3x3.fill")
                }
                .padding(12)
            }
        }
        .padding(12)
        .pegboardPanel()
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    /// Tool picker and color palette live in one fixed panel below the canvas, like a console
    /// bolted to the front of the workbench, separated from the pegboard by its own shadow.
    private var controlConsole: some View {
        VStack(spacing: 0) {
            toolbar
            hairline
            colorPalette
        }
        .background(BeadWorksTheme.trayBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.4)).frame(height: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 10, y: -4)
    }

    private var hairline: some View {
        Rectangle().fill(BeadWorksTheme.divider).frame(height: 1)
    }

    private var toolbar: some View {
        HStack(spacing: 14) {
            Picker("工具", selection: $toolMode) {
                Image(systemName: "hand.point.up.left.fill").tag(ToolMode.place)
                Image(systemName: "eraser.fill").tag(ToolMode.erase)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 160)
            .accessibilityIdentifier("toolModePicker")

            MaterialNote(text: selectedColorName, systemImage: "eyedropper.halffull")

            Spacer()

            Button(role: .destructive, action: { board.clear() }) {
                Label("清空", systemImage: "trash")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityIdentifier("clearButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var colorPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BeadColor.palette) { color in
                    ColorSwatchButton(color: color, isSelected: color.id == selectedColorId) {
                        selectedColorId = color.id
                        toolMode = .place
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func handleTouch(at location: CGPoint, cellSize: CGFloat) {
        guard cellSize > 0 else { return }
        let x = Int(floor(location.x / cellSize))
        let y = Int(floor(location.y / cellSize))
        guard x >= 0, x < board.width, y >= 0, y < board.height else { return }
        switch toolMode {
        case .place:
            board.place(colorId: selectedColorId, x: x, y: y)
        case .erase:
            board.erase(x: x, y: y)
        }
    }

    private func performIroning() {
        let renderer = ImageRenderer(content: IroningRenderView(board: board, style: .fullFused))
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }
        ironedImage = image
        showFinished = true
    }
}

#Preview {
    NavigationStack {
        BoardEditorView(context: .freeform(size: 16))
    }
    .environment(BoardStore())
}
