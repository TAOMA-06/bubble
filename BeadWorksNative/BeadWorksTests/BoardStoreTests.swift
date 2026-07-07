import XCTest
@testable import BeadWorks

final class BoardStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoardStoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func makePreviewImage(color: UIColor = .systemOrange) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    func testSaveMakesWorkReadableFromWorksList() throws {
        let store = BoardStore(baseDirectory: tempDirectory)
        var board = BeadBoard(width: 4, height: 4)
        board.place(colorId: 2, x: 0, y: 0)

        let saved = try store.save(board: board, title: "测试作品", previewImage: makePreviewImage())

        XCTAssertEqual(store.works.count, 1)
        XCTAssertEqual(store.works.first?.id, saved.id)
        XCTAssertEqual(store.works.first?.title, "测试作品")
        XCTAssertNotNil(store.previewImage(for: saved))
    }

    func testDeleteRemovesWorkAndPreviewFile() throws {
        let store = BoardStore(baseDirectory: tempDirectory)
        let board = BeadBoard(width: 2, height: 2)
        let saved = try store.save(board: board, title: "待删除", previewImage: makePreviewImage())

        let previewURL = tempDirectory.appendingPathComponent(saved.previewFileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: previewURL.path))

        store.delete(saved)

        XCTAssertTrue(store.works.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: previewURL.path))
    }

    func testWorksPersistAcrossStoreInstances() throws {
        let firstStore = BoardStore(baseDirectory: tempDirectory)
        let board = BeadBoard(width: 3, height: 3)
        _ = try firstStore.save(board: board, title: "持久化测试", previewImage: makePreviewImage())

        let secondStore = BoardStore(baseDirectory: tempDirectory)

        XCTAssertEqual(secondStore.works.count, 1)
        XCTAssertEqual(secondStore.works.first?.title, "持久化测试")
    }

    func testDeleteAllClearsWorksAndFiles() throws {
        let store = BoardStore(baseDirectory: tempDirectory)
        let board = BeadBoard(width: 2, height: 2)
        let first = try store.save(board: board, title: "A", previewImage: makePreviewImage())
        let second = try store.save(board: board, title: "B", previewImage: makePreviewImage())

        store.deleteAll()

        XCTAssertTrue(store.works.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent(first.previewFileName).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent(second.previewFileName).path))
    }
}
