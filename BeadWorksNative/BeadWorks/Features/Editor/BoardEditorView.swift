import SwiftUI
import UIKit

struct BoardEditorView: View {
    let context: EditorContext

    @Environment(BoardStore.self) private var boardStore
    @State private var model: BoardEditorViewModel

    init(context: EditorContext) {
        self.context = context
        _model = State(initialValue: BoardEditorViewModel(context: context))
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
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BeadWorksTheme.workbenchWood, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: performIroning) {
                    Label("熨烫", systemImage: "flame.fill")
                }
                .tint(BeadWorksTheme.accent)
                .disabled(model.board.isEmpty)
                .accessibilityIdentifier("ironButton")
            }
        }
        .navigationDestination(isPresented: $model.showFinished) {
            if let ironedImage = model.ironedImage {
                FinishedWorkView(board: model.board, previewImage: ironedImage)
            }
        }
        .onDisappear {
            if let draft = model.makeDraft() {
                boardStore.saveDraft(draft)
            }
        }
    }

    private var workbenchCanvas: some View {
        ZStack(alignment: .topLeading) {
            PegboardCanvasView(
                board: model.board,
                showGuide: model.showGuide,
                showMismatches: model.showMismatches,
                toolMode: model.toolMode,
                scale: model.scale,
                onPaint: { location, cellSize in
                    model.handleTouch(at: location, cellSize: cellSize)
                },
                onPaintEnd: { model.endStroke() },
                onPinchBegan: { model.beginPinch() },
                onPinchChanged: { model.updatePinch(magnification: $0) },
                onResetView: { model.resetView() }
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    MaterialNote(text: model.boardDescription, systemImage: "square.grid.3x3.fill")
                    MaterialNote(text: "\(model.board.filledCount) 颗", systemImage: "circle.grid.3x3.fill")
                }
                if model.board.hasTemplate {
                    MaterialNote(text: model.matchStats.summary, systemImage: "checkmark.seal.fill")
                }
            }
            .padding(12)
        }
        .padding(12)
        .pegboardPanel()
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var controlConsole: some View {
        VStack(spacing: 0) {
            toolbar
            Rectangle().fill(BeadWorksTheme.divider).frame(height: 1)
            colorPalette
        }
        .background(BeadWorksTheme.trayBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.4)).frame(height: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 10, y: -4)
    }

    private var toolbar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Picker("工具", selection: $model.toolMode) {
                    Image(systemName: ToolMode.place.systemImage).tag(ToolMode.place)
                    Image(systemName: ToolMode.erase.systemImage).tag(ToolMode.erase)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 140)
                .accessibilityIdentifier("toolModePicker")

                iconToolButton(.eyedropper)
                iconToolButton(.pan)

                Spacer(minLength: 4)

                Button(action: model.undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!model.canUndo)
                .accessibilityIdentifier("undoButton")
                .accessibilityLabel("撤销")

                Button(action: model.redo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!model.canRedo)
                .accessibilityIdentifier("redoButton")
                .accessibilityLabel("重做")

                Button(role: .destructive, action: model.clear) {
                    Image(systemName: "trash")
                }
                .accessibilityIdentifier("clearButton")
                .accessibilityLabel("清空")
            }

            HStack(spacing: 8) {
                MaterialNote(text: model.selectedColorName, systemImage: "eyedropper.halffull")
                if model.board.hasTemplate {
                    overlayToggle(
                        title: "图纸",
                        isOn: model.showGuide,
                        identifier: "guideToggle"
                    ) {
                        model.showGuide.toggle()
                    }
                    overlayToggle(
                        title: "纠错",
                        isOn: model.showMismatches,
                        identifier: "mismatchToggle"
                    ) {
                        model.showMismatches.toggle()
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func overlayToggle(
        title: String,
        isOn: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
        }
        .buttonStyle(.bordered)
        .tint(isOn ? BeadWorksTheme.accent : BeadWorksTheme.ink.opacity(0.55))
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "开" : "关")
        .accessibilityAddTraits(.isButton)
    }

    private func iconToolButton(_ mode: ToolMode) -> some View {
        Button {
            model.toolMode = mode
        } label: {
            Image(systemName: mode.systemImage)
                .frame(width: 34, height: 28)
        }
        .buttonStyle(.bordered)
        .tint(model.toolMode == mode ? BeadWorksTheme.accent : BeadWorksTheme.ink.opacity(0.55))
        .accessibilityIdentifier("toolButton_\(mode.rawValue)")
        .accessibilityLabel(mode.label)
    }

    private var colorPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BeadColor.palette) { color in
                    ColorSwatchButton(color: color, isSelected: color.id == model.selectedColorId) {
                        model.selectColor(color.id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func performIroning() {
        let renderer = ImageRenderer(content: IroningRenderView(board: model.board, style: .fullFused))
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }
        model.ironedImage = image
        model.showFinished = true
        boardStore.clearDraft()
    }
}

#Preview {
    NavigationStack {
        BoardEditorView(context: .freeform(size: 16))
    }
    .environment(BoardStore())
}
