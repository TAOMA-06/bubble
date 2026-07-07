import SwiftUI

@main
struct BeadWorksApp: App {
    @State private var boardStore = BeadWorksApp.makeBoardStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(boardStore)
        }
    }

    /// UI tests launch with `-uiTestResetStorage` to start from an empty gallery, independent of
    /// whatever earlier test runs left behind in the simulator's Documents directory.
    private static func makeBoardStore() -> BoardStore {
        if ProcessInfo.processInfo.arguments.contains("-uiTestResetStorage") {
            try? FileManager.default.removeItem(at: BoardStore.defaultDirectory())
        }
        return BoardStore()
    }
}
