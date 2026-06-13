import Foundation

actor CanvasStore {
    static let shared = CanvasStore()

    private let directory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        directory = docs.appendingPathComponent("works", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ state: CanvasState) async throws {
        let url = directory.appendingPathComponent("\(state.id.uuidString).json")
        let data = try JSONEncoder().encode(state)
        try data.write(to: url)
    }

    func loadAll() async throws -> [CanvasState] {
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        var states: [CanvasState] = []
        for url in urls {
            let data = try Data(contentsOf: url)
            let state = try JSONDecoder().decode(CanvasState.self, from: data)
            states.append(state)
        }
        return states
    }
}
