import SwiftUI

/// Wraps `HomeView` with an app-launch splash. The splash sits above the home screen in a
/// `ZStack` and fades out once its minimum display time elapses, rather than gating navigation
/// or view construction behind a loading state.
struct AppRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSplash: Bool

    private static let minimumDisplayDuration: TimeInterval = 1.1

    /// UI tests always launch with `-uiTestResetStorage`. Every existing UI test taps home-screen
    /// buttons immediately after `app.launch()`, so the splash is skipped under that flag instead
    /// of making every test wait out a fixed splash duration (or forcing every test to first wait
    /// for the splash to dismiss). Real launches always show it.
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTestResetStorage")
    }

    init() {
        _showSplash = State(initialValue: !Self.isUITesting)
    }

    var body: some View {
        ZStack {
            HomeView()

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard showSplash else { return }
            try? await Task.sleep(nanoseconds: UInt64(Self.minimumDisplayDuration * 1_000_000_000))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
}

#Preview {
    AppRootView()
        .environment(BoardStore())
}
