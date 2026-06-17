import SwiftUI

// 导航路由：底部 TabView 架构下，各 Tab 通过 NavigationPath 推入的目的地。
enum MainRoute: Hashable {
    case freeCanvas(side: Int)
}
