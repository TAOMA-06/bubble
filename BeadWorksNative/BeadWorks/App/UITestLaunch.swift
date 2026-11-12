import Foundation

/// Launch flags used by UI tests. Real launches never pass these arguments.
enum UITestLaunch {
    static var resetsStorage: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTestResetStorage")
    }

    static var usesFixtureImage: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTestFixtureImage")
    }
}
