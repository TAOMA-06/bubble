import Foundation
import Observation
import UIKit

enum BoardStoreError: Error {
    case encodingFailed
}

/// Persists finished works to disk: one shared `index.json` (the `[GalleryWork]` array) plus one
/// PNG preview image per work, all inside `baseDirectory` (defaults to Documents/Gallery). Also
/// keeps a single in-progress `draft.json` so leaving the editor does not lose unsaved beads.
@Observable
final class BoardStore {
    private(set) var works: [GalleryWork] = []
    private(set) var draft: WorkshopDraft?

    private let fileManager: FileManager
    private let baseDirectory: URL

    init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.baseDirectory = baseDirectory ?? Self.defaultDirectory()
        try? self.fileManager.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)
        loadIndex()
        loadDraft()
    }

    static func defaultDirectory() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Gallery", isDirectory: true)
    }

    @discardableResult
    func save(
        board: BeadBoard,
        title: String,
        previewImage: UIImage,
        productType: FinishedProductType = .fridgeMagnet,
        renderStyle: BeadRenderStyle = .fullFused
    ) throws -> GalleryWork {
        guard let data = previewImage.pngData() else { throw BoardStoreError.encodingFailed }

        let id = UUID()
        let previewFileName = "\(id.uuidString).png"
        let previewURL = baseDirectory.appendingPathComponent(previewFileName)
        try data.write(to: previewURL, options: .atomic)

        let work = GalleryWork(
            id: id,
            title: title,
            board: board,
            previewFileName: previewFileName,
            productType: productType,
            renderStyle: renderStyle
        )
        works.insert(work, at: 0)
        try persistIndex()
        return work
    }

    func delete(_ work: GalleryWork) {
        works.removeAll { $0.id == work.id }
        let previewURL = baseDirectory.appendingPathComponent(work.previewFileName)
        try? fileManager.removeItem(at: previewURL)
        try? persistIndex()
    }

    func previewImage(for work: GalleryWork) -> UIImage? {
        let url = baseDirectory.appendingPathComponent(work.previewFileName)
        return UIImage(contentsOfFile: url.path)
    }

    func work(id: UUID) -> GalleryWork? {
        works.first { $0.id == id }
    }

    /// Removes every saved work and its preview image. Used by UI tests to start from a clean
    /// gallery without depending on simulator state left over from previous runs.
    func deleteAll() {
        for work in works {
            let previewURL = baseDirectory.appendingPathComponent(work.previewFileName)
            try? fileManager.removeItem(at: previewURL)
        }
        works.removeAll()
        clearDraft()
        try? persistIndex()
    }

    func saveDraft(_ draft: WorkshopDraft) {
        self.draft = draft
        persistDraft()
    }

    func clearDraft() {
        draft = nil
        try? fileManager.removeItem(at: draftURL)
    }

    private var indexURL: URL { baseDirectory.appendingPathComponent("index.json") }
    private var draftURL: URL { baseDirectory.appendingPathComponent("draft.json") }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        works = (try? decoder.decode([GalleryWork].self, from: data)) ?? []
    }

    private func persistIndex() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(works)
        try data.write(to: indexURL, options: .atomic)
    }

    private func loadDraft() {
        guard let data = try? Data(contentsOf: draftURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        draft = try? decoder.decode(WorkshopDraft.self, from: data)
    }

    private func persistDraft() {
        guard let draft else {
            try? fileManager.removeItem(at: draftURL)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(draft) else { return }
        try? data.write(to: draftURL, options: .atomic)
    }
}
