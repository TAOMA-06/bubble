import XCTest
@testable import BeadWorks

final class BoardHistoryTests: XCTestCase {
    func testCommitThenUndoRestoresPreviousCells() {
        var history = BoardHistory(initial: [nil, nil, nil])
        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)

        history.commit([1, nil, nil])
        XCTAssertTrue(history.canUndo)

        XCTAssertEqual(history.undo(), [nil, nil, nil])
        XCTAssertFalse(history.canUndo)
        XCTAssertTrue(history.canRedo)

        XCTAssertEqual(history.redo(), [1, nil, nil])
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
    }

    func testCommitClearsRedoStack() {
        var history = BoardHistory(initial: [nil])
        history.commit([1])
        _ = history.undo()
        history.commit([2])

        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.undo(), [nil])
    }

    func testDuplicateCommitIsIgnored() {
        var history = BoardHistory(initial: [1])
        history.commit([1])
        XCTAssertFalse(history.canUndo)
    }
}

final class PatternMatcherTests: XCTestCase {
    func testFreeformBoardHasEmptyStats() {
        var board = BeadBoard(width: 2, height: 2)
        board.place(colorId: 1, x: 0, y: 0)
        let stats = PatternMatcher.evaluate(board: board)
        XCTAssertEqual(stats.requiredCells, 0)
        XCTAssertEqual(stats.completion, 1)
    }

    func testCountsCorrectWrongMissingAndExtra() {
        let template: [Int?] = [
            2, 2,
            nil, 3,
        ]
        var board = BeadBoard(width: 2, height: 2, templateCells: template)
        board.place(colorId: 2, x: 0, y: 0) // correct
        board.place(colorId: 1, x: 1, y: 0) // wrong
        board.place(colorId: 4, x: 0, y: 1) // extra on empty template cell
        // (1,1) missing expected 3

        let stats = PatternMatcher.evaluate(board: board)
        XCTAssertEqual(stats.requiredCells, 3)
        XCTAssertEqual(stats.correctCells, 1)
        XCTAssertEqual(stats.wrongCells, 1)
        XCTAssertEqual(stats.missingCells, 1)
        XCTAssertEqual(stats.extraCells, 1)
        XCTAssertEqual(PatternMatcher.status(board: board, x: 0, y: 0), .correct)
        XCTAssertEqual(PatternMatcher.status(board: board, x: 1, y: 0), .wrong)
        XCTAssertEqual(PatternMatcher.status(board: board, x: 0, y: 1), .extra)
        XCTAssertEqual(PatternMatcher.status(board: board, x: 1, y: 1), .missing)
    }
}

final class BuiltinPatternFactoryTests: XCTestCase {
    func testAllPatternsAreSixteenSquareWithPaletteIds() {
        let patterns = BuiltinPatternFactory.all()
        XCTAssertEqual(patterns.map(\.id), ["heart", "star", "guofeng_cloud", "milk_tea_cup", "support_sign"])
        let validIds = Set(BeadColor.palette.map(\.id))
        for pattern in patterns {
            XCTAssertEqual(pattern.size, 16)
            XCTAssertEqual(pattern.cells.count, 256)
            XCTAssertEqual(pattern.source, .builtin)
            for cell in pattern.cells {
                if let id = cell {
                    XCTAssertTrue(validIds.contains(id), "illegal color id \(id) in \(pattern.id)")
                }
            }
        }
    }

    func testHeartUsesRedBeadsAndLeavesEmptyPegs() {
        let heart = BuiltinPatternFactory.heart()
        XCTAssertTrue(heart.cells.contains(where: { $0 == 2 }))
        XCTAssertTrue(heart.cells.contains(where: { $0 == nil }))
    }
}

final class ShareImageServiceTests: XCTestCase {
    func testShareCardHasExpectedCanvasSize() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16))
        let boardImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }

        let card = ShareImageService.composeCard(
            boardImage: boardImage,
            title: "测试作品",
            beadCount: 12,
            width: 16,
            height: 16,
            productType: .keychain
        )

        XCTAssertEqual(card.size.width, ShareImageService.canvasSize.width)
        XCTAssertEqual(card.size.height, ShareImageService.canvasSize.height)
    }
}

final class EditorContextTests: XCTestCase {
    func testTemplateContextBuildsGuidedEmptyBoard() {
        let pattern = BuiltinPatternFactory.heart()
        let context = EditorContext.template(pattern: pattern)
        let board = context.makeBoard()

        XCTAssertEqual(context.title, "爱心")
        XCTAssertTrue(board.isEmpty)
        XCTAssertTrue(board.templateCells?.contains(where: { $0 == 2 }) == true)
    }

    func testRestoredContextKeepsPlacedCells() {
        var board = BeadBoard(width: 4, height: 4)
        board.place(colorId: 5, x: 1, y: 1)
        let restored = EditorContext.restored(board: board, title: "旧作").makeBoard()
        XCTAssertEqual(restored.colorId(atX: 1, y: 1), 5)
    }
}
