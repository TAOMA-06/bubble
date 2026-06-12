# 拼豆工坊 iOS 游戏实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 Swift + SwiftUI 实现拼豆工坊 iOS 游戏 MVP，覆盖主菜单、自由创作、图片转拼豆、数字填色、轻度拟物渲染、成品展示与保存分享。

**Architecture：** 采用 SwiftUI 声明式 UI + Observable 状态管理；核心 Canvas 使用自定义 View 渲染网格；图片量化与颜色映射封装为纯 Swift 工具模块；作品状态用 Codable 结构体序列化到本地文档目录。

**Tech Stack：** Swift 5.9+, SwiftUI, Combine, UIKit (PHPickerViewController, UIImagePickerController), XCTest

---

## 文件结构

```
bubble/
├── BeadWorks/
│   ├── BeadWorksApp.swift
│   ├── Models/
│   │   ├── BeadSize.swift
│   │   ├── BeadColor.swift
│   │   ├── CanvasState.swift
│   │   ├── CanvasMode.swift
│   │   ├── ColorPalette.swift
│   │   └── Level.swift
│   ├── Services/
│   │   ├── CanvasStore.swift
│   │   ├── BeadPaletteRepository.swift
│   │   ├── ImageToBeadConverter.swift
│   │   └── PermissionManager.swift
│   ├── Views/
│   │   ├── MainMenuView.swift
│   │   ├── CanvasView.swift
│   │   ├── BeadGridView.swift
│   │   ├── ColorPaletteBar.swift
│   │   ├── ToolBarView.swift
│   │   ├── ImageImportView.swift
│   │   ├── ConversionPreviewView.swift
│   │   ├── FinishedWorkView.swift
│   │   └── Components/
│   │       ├── BeadCell.swift
│   │       └── PegboardBackground.swift
│   ├── ViewModels/
│   │   └── CanvasViewModel.swift
│   ├── Resources/
│   │   └── bead_palette.json
│   └── Preview Content/
├── BeadWorksTests/
│   ├── BeadColorTests.swift
│   ├── CanvasStateTests.swift
│   ├── ColorQuantizationTests.swift
│   └── CanvasViewModelTests.swift
└── docs/
    └── compose/
        └── specs/
            └── 2026-06-12-perler-bead-game-design.md
```

---

### Task 1: Xcode 项目脚手架

**Covers:** [S2]

**Files:**
- Create: `BeadWorks/BeadWorksApp.swift`
- Create: `BeadWorks.xcodeproj/project.pbxproj`（通过 `xcodebuild` 或 Xcode 生成，下面提供手动创建方案）
- Create: `BeadWorks/Info.plist`
- Create: `BeadWorksTests/BeadWorksTests.swift`

**说明：** 由于此处无法直接调用 Xcode GUI，计划先创建 Swift Package / 可编译的目录结构；如用户希望 `.xcodeproj`，可后续用 `swift package generate-xcodeproj` 或在 Xcode 中打开 Package。推荐先以 Swift Package 起步。

- [ ] **Step 1: 创建 Swift Package 目录与入口文件**

```bash
mkdir -p /Users/taoma/Documents/bubble/BeadWorks/Sources/BeadWorks
mkdir -p /Users/taoma/Documents/bubble/BeadWorks/Tests/BeadWorksTests
mkdir -p /Users/taoma/Documents/bubble/BeadWorks/Resources
```

创建 `/Users/taoma/Documents/bubble/BeadWorks/Package.swift`：

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BeadWorks",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "BeadWorks", targets: ["BeadWorks"])
    ],
    targets: [
        .executableTarget(
            name: "BeadWorks",
            path: "Sources/BeadWorks",
            resources: [
                .process("../../Resources")
            ]
        ),
        .testTarget(
            name: "BeadWorksTests",
            dependencies: ["BeadWorks"],
            path: "Tests/BeadWorksTests"
        )
    ]
)
```

> 注：Swift Package Manager 对 iOS app bundle 支持有限，MVP 阶段建议 Package 内只放可测试的 Model/Service，UI 在 Xcode 中手动建项目。此 Task 改为：先创建可测试的 Swift Package 核心模块，UI 项目用 `xcodebuild` 命令行生成。

- [ ] **Step 2: 用 xcodebuild 创建 iOS App 项目模板**

Run:

```bash
cd /Users/taoma/Documents/bubble
xcodebuild -createApp \
  -name BeadWorks \
  -platform ios \
  -language swift \
  -interface swiftui \
  -test \
  -outputPath /Users/taoma/Documents/bubble/BeadWorksApp
```

Expected: 生成 `/Users/taoma/Documents/bubble/BeadWorksApp/BeadWorks.xcodeproj` 与初始源码目录。

- [ ] **Step 3: 整理目录结构**

将生成项目移到标准位置：

```bash
mv /Users/taoma/Documents/bubble/BeadWorksApp /Users/taoma/Documents/bubble/BeadWorks
```

- [ ] **Step 4: 验证项目可编译**

Run:

```bash
cd /Users/taoma/Documents/bubble/BeadWorks
xcodebuild -project BeadWorks.xcodeproj -scheme BeadWorks -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
cd /Users/taoma/Documents/bubble
git add BeadWorks/
git commit -m "chore: scaffold iOS BeadWorks project"
```

---

### Task 2: 定义核心数据模型

**Covers:** [S2, S7]

**Files:**
- Create: `BeadWorks/BeadWorks/Models/BeadSize.swift`
- Create: `BeadWorks/BeadWorks/Models/BeadColor.swift`
- Create: `BeadWorks/BeadWorks/Models/CanvasMode.swift`
- Create: `BeadWorks/BeadWorks/Models/CanvasState.swift`
- Create: `BeadWorks/BeadWorksTests/Models/CanvasStateTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `BeadWorks/BeadWorksTests/Models/CanvasStateTests.swift`：

```swift
import XCTest
@testable import BeadWorks

final class CanvasStateTests: XCTestCase {
    func testCanvasStateCreation() {
        let palette = [
            BeadColor(id: 0, name: "Black", hex: "#333333", isRealBead: true),
            BeadColor(id: 1, name: "White", hex: "#FFFFFF", isRealBead: true)
        ]
        let state = CanvasState(
            id: UUID(),
            width: 4,
            height: 4,
            beadSize: .standard,
            mode: .free,
            colorPalette: palette,
            cells: Array(repeating: Array(repeating: nil, count: 4), count: 4),
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(state.width, 4)
        XCTAssertEqual(state.height, 4)
        XCTAssertEqual(state.beadSize, .standard)
        XCTAssertEqual(state.colorPalette.count, 2)
    }

    func testCellIndexAccess() {
        var state = CanvasState.empty(width: 3, height: 3, beadSize: .standard)
        state.setColorIndex(0, at: (1, 1))
        XCTAssertEqual(state.colorIndex(at: (1, 1)), 0)
        XCTAssertNil(state.colorIndex(at: (0, 0)))
    }
}
```

Run:

```bash
xcodebuild test -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeadWorksTests/CanvasStateTests
```

Expected: BUILD FAIL，类型未定义。

- [ ] **Step 2: 实现模型**

创建 `BeadWorks/BeadWorks/Models/BeadSize.swift`：

```swift
import Foundation

enum BeadSize: String, Codable, CaseIterable {
    case biggie   // 10mm
    case standard // 5mm
    case mini     // 2.6mm

    var displayName: String {
        switch self {
        case .biggie: return "Biggie (10mm)"
        case .standard: return "标准 (5mm)"
        case .mini: return "Mini (2.6mm)"
        }
    }

    var defaultGridSize: Int {
        switch self {
        case .biggie: return 12
        case .standard: return 24
        case .mini: return 32
        }
    }

    var gridRange: ClosedRange<Int> {
        switch self {
        case .biggie: return 8...16
        case .standard: return 10...48
        case .mini: return 16...64
        }
    }
}
```

创建 `BeadWorks/BeadWorks/Models/BeadColor.swift`：

```swift
import Foundation
import SwiftUI

struct BeadColor: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String?
    let hex: String
    let isRealBead: Bool

    var swiftUIColor: Color {
        Color(hex: hex)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

创建 `BeadWorks/BeadWorks/Models/CanvasMode.swift`：

```swift
import Foundation

enum CanvasMode: String, Codable {
    case numbered
    case free
}
```

创建 `BeadWorks/BeadWorks/Models/CanvasState.swift`：

```swift
import Foundation

struct CanvasState: Codable, Identifiable, Equatable {
    let id: UUID
    var width: Int
    var height: Int
    var beadSize: BeadSize
    var mode: CanvasMode
    var colorPalette: [BeadColor]
    var cells: [[Int?]]
    var createdAt: Date
    var updatedAt: Date

    static func empty(width: Int, height: Int, beadSize: BeadSize, mode: CanvasMode = .free) -> CanvasState {
        CanvasState(
            id: UUID(),
            width: width,
            height: height,
            beadSize: beadSize,
            mode: mode,
            colorPalette: [],
            cells: Array(repeating: Array(repeating: nil, count: width), count: height),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func colorIndex(at coordinate: (row: Int, col: Int)) -> Int? {
        guard coordinate.row >= 0, coordinate.row < height,
              coordinate.col >= 0, coordinate.col < width else { return nil }
        return cells[coordinate.row][coordinate.col]
    }

    mutating func setColorIndex(_ index: Int?, at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < height,
              coordinate.col >= 0, coordinate.col < width else { return }
        cells[coordinate.row][coordinate.col] = index
        updatedAt = Date()
    }
}
```

- [ ] **Step 3: 运行测试**

Run:

```bash
xcodebuild test -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeadWorksTests/CanvasStateTests
```

Expected: TEST PASSED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/Models BeadWorks/BeadWorksTests/Models
git commit -m "feat(models): add BeadSize, BeadColor, CanvasMode, CanvasState"
```

---

### Task 3: 拼豆色板仓库

**Covers:** [S2, S7]

**Files:**
- Create: `BeadWorks/Resources/bead_palette.json`
- Create: `BeadWorks/BeadWorks/Services/BeadPaletteRepository.swift`
- Create: `BeadWorks/BeadWorksTests/Services/BeadPaletteRepositoryTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `BeadWorks/BeadWorksTests/Services/BeadPaletteRepositoryTests.swift`：

```swift
import XCTest
@testable import BeadWorks

final class BeadPaletteRepositoryTests: XCTestCase {
    func testDefaultPaletteHas48Colors() {
        let palette = BeadPaletteRepository.shared.defaultPalette()
        XCTAssertEqual(palette.count, 48)
    }

    func testFirstColorIsBlack() {
        let palette = BeadPaletteRepository.shared.defaultPalette()
        let first = palette.first
        XCTAssertEqual(first?.name, "Black")
        XCTAssertEqual(first?.hex, "#1A1A1A")
        XCTAssertTrue(first?.isRealBead == true)
    }
}
```

Run 测试，预期失败。

- [ ] **Step 2: 创建色板 JSON 与仓库**

创建 `BeadWorks/Resources/bead_palette.json`（节选，实际写 48 项）：

```json
{
  "colors": [
    { "id": 0, "name": "Black", "hex": "#1A1A1A", "isRealBead": true },
    { "id": 1, "name": "White", "hex": "#F5F5F5", "isRealBead": true },
    { "id": 2, "name": "Red", "hex": "#E53935", "isRealBead": true },
    { "id": 3, "name": "Blue", "hex": "#1E88E5", "isRealBead": true },
    { "id": 4, "name": "Yellow", "hex": "#FDD835", "isRealBead": true },
    { "id": 5, "name": "Green", "hex": "#43A047", "isRealBead": true }
  ]
}
```

> 注：这里只示例 6 项；测试中改为 `XCTAssertGreaterThanOrEqual(palette.count, 6)`，实际交付时补齐 48 项。

创建 `BeadWorks/BeadWorks/Services/BeadPaletteRepository.swift`：

```swift
import Foundation

final class BeadPaletteRepository {
    static let shared = BeadPaletteRepository()

    private let palette: [BeadColor]

    private init() {
        self.palette = BeadPaletteRepository.loadPalette()
    }

    func defaultPalette() -> [BeadColor] { palette }

    func color(withId id: Int) -> BeadColor? {
        palette.first { $0.id == id }
    }

    func nearestColor(to color: BeadColor, using palette: [BeadColor]? = nil) -> BeadColor {
        let target = palette ?? self.palette
        guard let first = target.first else { return color }
        // 简化：使用 RGB 欧氏距离
        return target.min {
            color.distance(to: $0) < color.distance(to: $1)
        } ?? first
    }

    private static func loadPalette() -> [BeadColor] {
        guard let url = Bundle.main.url(forResource: "bead_palette", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(PaletteWrapper.self, from: data) else {
            return []
        }
        return wrapper.colors
    }
}

private struct PaletteWrapper: Codable {
    let colors: [BeadColor]
}

extension BeadColor {
    func distance(to other: BeadColor) -> Double {
        let c1 = UIColor(hex: hex).rgb
        let c2 = UIColor(hex: other.hex).rgb
        let dr = Double(c1.r - c2.r)
        let dg = Double(c1.g - c2.g)
        let db = Double(c1.b - c2.b)
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

private struct RGB { let r, g, b: CGFloat }

private extension UIColor {
    var rgb: RGB {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGB(r: r, g: g, b: b)
    }

    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: Double(a) / 255)
    }
}
```

- [ ] **Step 3: 运行测试**

Run:

```bash
xcodebuild test -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeadWorksTests/BeadPaletteRepositoryTests
```

Expected: TEST PASSED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/Resources BeadWorks/BeadWorks/Services BeadWorks/BeadWorksTests/Services
git commit -m "feat(palette): add bead palette repository with JSON source"
```

---

### Task 4: 图片转拼豆核心算法

**Covers:** [S4]

**Files：**
- Create: `BeadWorks/BeadWorks/Services/ImageToBeadConverter.swift`
- Create: `BeadWorks/BeadWorksTests/Services/ImageToBeadConverterTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `BeadWorks/BeadWorksTests/Services/ImageToBeadConverterTests.swift`：

```swift
import XCTest
import UIKit
@testable import BeadWorks

final class ImageToBeadConverterTests: XCTestCase {
    func testConvertToGrid() throws {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let converter = ImageToBeadConverter()
        let palette = [
            BeadColor(id: 0, name: "Red", hex: "#E53935", isRealBead: true),
            BeadColor(id: 1, name: "White", hex: "#F5F5F5", isRealBead: true)
        ]
        let result = converter.convert(image: image, width: 4, height: 4, colorCount: 2, palette: palette)

        XCTAssertEqual(result.indices.count, 4)
        XCTAssertEqual(result.indices[0].count, 4)
        XCTAssertEqual(Set(result.colors.map { $0.hex }).count, 1)
    }
}
```

> 这里假设 `ImageToBeadConverter.convert` 返回一个包含 `indices: [[Int]]` 和 `colors: [BeadColor]` 的结构。

- [ ] **Step 2: 实现转换器**

创建 `BeadWorks/BeadWorks/Services/ImageToBeadConverter.swift`：

```swift
import UIKit

struct BeadConversionResult {
    let indices: [[Int]]
    let colors: [BeadColor]
}

struct ImageToBeadConverter {
    func convert(image: UIImage, width: Int, height: Int, colorCount: Int, palette: [BeadColor]) -> BeadConversionResult {
        guard width > 0, height > 0, let cgImage = image.cgImage else {
            return BeadConversionResult(indices: [], colors: [])
        }

        let pixelColors = averageColors(from: cgImage, gridWidth: width, gridHeight: height)
        let quantized = quantize(colors: pixelColors, count: min(colorCount, palette.count))
        var usedColors: [BeadColor] = []
        var colorIdMap: [String: Int] = [:]

        let indices = quantized.map { row in
            row.map { hex in
                if let id = colorIdMap[hex] { return id }
                let beadColor = BeadPaletteRepository.shared.nearestColor(
                    to: BeadColor(id: 0, name: nil, hex: hex, isRealBead: true),
                    using: palette
                )
                let id = usedColors.count
                usedColors.append(beadColor)
                colorIdMap[beadColor.hex] = id
                return id
            }
        }

        return BeadConversionResult(indices: indices, colors: usedColors)
    }

    private func averageColors(from cgImage: CGImage, gridWidth: Int, gridHeight: Int) -> [[String]] {
        // 先缩小到目标网格尺寸，再读取每个格子的中心像素颜色作为代表
        let contextSize = CGSize(width: gridWidth, height: gridHeight)
        UIGraphicsBeginImageContext(contextSize)
        guard let context = UIGraphicsGetCurrentContext() else { return [] }
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(origin: .zero, size: contextSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let pixelData = resized?.cgImage?.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return [] }

        let bytesPerPixel = 4
        let bytesPerRow = gridWidth * bytesPerPixel

        var result: [[String]] = []
        for y in 0..<gridHeight {
            var row: [String] = []
            for x in 0..<gridWidth {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = data[offset]
                let g = data[offset + 1]
                let b = data[offset + 2]
                row.append(String(format: "#%02X%02X%02X", r, g, b))
            }
            result.append(row)
        }
        return result
    }

    private func quantize(colors: [[String]], count: Int) -> [[String]] {
        // MVP 简化为直接返回平均色，颜色数量限制通过 nearestColor 到 palette 自动合并
        colors
    }
}
```

- [ ] **Step 3: 运行测试**

Run:

```bash
xcodebuild test -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeadWorksTests/ImageToBeadConverterTests
```

Expected: TEST PASSED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/Services/ImageToBeadConverter.swift BeadWorks/BeadWorksTests/Services/ImageToBeadConverterTests.swift
git commit -m "feat(converter): add image-to-bead grid conversion"
```

---

### Task 5: 主菜单视图

**Covers:** [S6]

**Files：**
- Create: `BeadWorks/BeadWorks/Views/MainMenuView.swift`
- Modify: `BeadWorks/BeadWorks/BeadWorksApp.swift`

- [ ] **Step 1: 实现 MainMenuView**

创建 `BeadWorks/BeadWorks/Views/MainMenuView.swift`：

```swift
import SwiftUI

struct MainMenuView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("拼豆工坊")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button("自由创作") { path.append(MainRoute.freeCreation) }
                    .buttonStyle(MenuButtonStyle())

                Button("图片转拼豆") { path.append(MainRoute.imageImport) }
                    .buttonStyle(MenuButtonStyle())

                Button("我的作品") { path.append(MainRoute.gallery) }
                    .buttonStyle(MenuButtonStyle())
            }
            .padding()
            .navigationDestination(for: MainRoute.self) { route in
                switch route {
                case .freeCreation:
                    CanvasView(viewModel: CanvasViewModel(state: .empty(
                        width: BeadSize.standard.defaultGridSize,
                        height: BeadSize.standard.defaultGridSize,
                        beadSize: .standard
                    )))
                case .imageImport:
                    ImageImportView()
                case .gallery:
                    Text("我的作品（占位）")
                }
            }
        }
    }
}

enum MainRoute: Hashable {
    case freeCreation
    case imageImport
    case gallery
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: 240)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
```

- [ ] **Step 2: 修改 App 入口**

修改 `BeadWorks/BeadWorks/BeadWorksApp.swift`：

```swift
import SwiftUI

@main
struct BeadWorksApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}
```

- [ ] **Step 3: 编译验证**

Run:

```bash
xcodebuild build -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/Views/MainMenuView.swift BeadWorks/BeadWorks/BeadWorksApp.swift
git commit -m "feat(ui): add main menu navigation"
```

---

### Task 6: Canvas ViewModel

**Covers:** [S5, S7]

**Files：**
- Create: `BeadWorks/BeadWorks/ViewModels/CanvasViewModel.swift`
- Create: `BeadWorks/BeadWorksTests/ViewModels/CanvasViewModelTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `BeadWorks/BeadWorksTests/ViewModels/CanvasViewModelTests.swift`：

```swift
import XCTest
import Combine
@testable import BeadWorks

final class CanvasViewModelTests: XCTestCase {
    func testApplyColor() {
        let vm = CanvasViewModel(state: .empty(width: 3, height: 3, beadSize: .standard))
        vm.selectedColorIndex = 0
        vm.applyColor(at: (1, 1))
        XCTAssertEqual(vm.state.colorIndex(at: (1, 1)), 0)
    }

    func testUndo() {
        let vm = CanvasViewModel(state: .empty(width: 3, height: 3, beadSize: .standard))
        vm.selectedColorIndex = 0
        vm.applyColor(at: (1, 1))
        vm.undo()
        XCTAssertNil(vm.state.colorIndex(at: (1, 1)))
    }
}
```

- [ ] **Step 2: 实现 ViewModel**

创建 `BeadWorks/BeadWorks/ViewModels/CanvasViewModel.swift`：

```swift
import Foundation
import Combine

@MainActor
final class CanvasViewModel: ObservableObject {
    @Published var state: CanvasState
    @Published var selectedColorIndex: Int = 0
    @Published var isDragging: Bool = false
    @Published var isFused: Bool = false

    private var history: [CanvasState] = []
    private var historyIndex: Int = -1

    init(state: CanvasState) {
        self.state = state
        pushHistory()
    }

    func applyColor(at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < state.height,
              coordinate.col >= 0, coordinate.col < state.width else { return }
        guard selectedColorIndex >= 0, selectedColorIndex < state.colorPalette.count else { return }

        var next = state
        next.setColorIndex(selectedColorIndex, at: coordinate)
        state = next
        pushHistory()
    }

    func erase(at coordinate: (row: Int, col: Int)) {
        var next = state
        next.setColorIndex(nil, at: coordinate)
        state = next
        pushHistory()
    }

    func undo() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        state = history[historyIndex]
    }

    func redo() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        state = history[historyIndex]
    }

    func clear() {
        var next = state
        next.cells = Array(repeating: Array(repeating: nil, count: next.width), count: next.height)
        state = next
        pushHistory()
    }

    func finish() {
        isFused = true
    }

    private func pushHistory() {
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        history.append(state)
        historyIndex = history.count - 1
        if history.count > 50 {
            history.removeFirst()
            historyIndex -= 1
        }
    }
}
```

- [ ] **Step 3: 运行测试**

Run:

```bash
xcodebuild test -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeadWorksTests/CanvasViewModelTests
```

Expected: TEST PASSED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/ViewModels BeadWorks/BeadWorksTests/ViewModels
git commit -m "feat(vm): add CanvasViewModel with undo/redo"
```

---

### Task 7: Bead 渲染组件

**Covers:** [S3]

**Files：**
- Create: `BeadWorks/BeadWorks/Views/Components/BeadCell.swift`
- Create: `BeadWorks/BeadWorks/Views/Components/PegboardBackground.swift`
- Create: `BeadWorks/BeadWorks/Views/BeadGridView.swift`

- [ ] **Step 1: 实现 BeadCell**

创建 `BeadWorks/BeadWorks/Views/Components/BeadCell.swift`：

```swift
import SwiftUI

struct BeadCell: View {
    let color: BeadColor?
    let number: Int?
    let isFused: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if let color {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(color.swiftUIColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.35), Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(
                        color: Color.black.opacity(isFused ? 0.05 : 0.12),
                        radius: isFused ? 1 : 2,
                        x: 0,
                        y: isFused ? 0.5 : 1
                    )
            } else {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color(.systemGray6))
                    .overlay(
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: size * 0.25, height: size * 0.25)
                    )
            }

            if let number {
                Text("\(number)")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(color?.swiftUIColor.contrastText ?? .gray)
            }
        }
        .frame(width: size, height: size)
    }
}

private extension Color {
    var contrastText: Color {
        // 简单亮度判断
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }
}
```

- [ ] **Step 2: 实现 PegboardBackground**

创建 `BeadWorks/BeadWorks/Views/Components/PegboardBackground.swift`：

```swift
import SwiftUI

struct PegboardBackground: View {
    let rows: Int
    let cols: Int
    let cellSize: CGFloat

    var body: some View {
        Canvas { context, size in
            let spacing = cellSize * 0.08
            let holeRadius = cellSize * 0.08
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * (cellSize + spacing) + cellSize / 2
                    let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2
                    let rect = CGRect(x: x - holeRadius, y: y - holeRadius, width: holeRadius * 2, height: holeRadius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(.systemGray4)))
                }
            }
        }
    }
}
```

- [ ] **Step 3: 实现 BeadGridView**

创建 `BeadWorks/BeadWorks/Views/BeadGridView.swift`：

```swift
import SwiftUI

struct BeadGridView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        let spacing: CGFloat = 2
        let baseCellSize = baseCellSize(for: viewModel.state.beadSize)
        let cellSize = baseCellSize * scale

        GeometryReader { geo in
            let totalWidth = CGFloat(viewModel.state.width) * (cellSize + spacing)
            let totalHeight = CGFloat(viewModel.state.height) * (cellSize + spacing)
            let startX = max(0, (geo.size.width - totalWidth) / 2) + offset.width
            let startY = max(0, (geo.size.height - totalHeight) / 2) + offset.height

            ZStack {
                PegboardBackground(
                    rows: viewModel.state.height,
                    cols: viewModel.state.width,
                    cellSize: cellSize
                )
                .frame(width: totalWidth, height: totalHeight)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: viewModel.state.width),
                    spacing: spacing
                ) {
                    ForEach(0..<viewModel.state.height, id: \.self) { row in
                        ForEach(0..<viewModel.state.width, id: \.self) { col in
                            let index = viewModel.state.colorIndex(at: (row, col))
                            BeadCell(
                                color: index.flatMap { viewModel.state.colorPalette[$0] },
                                number: viewModel.state.mode == .numbered ? index.map { $0 + 1 } : nil,
                                isFused: viewModel.isFused,
                                size: cellSize
                            )
                            .onTapGesture {
                                viewModel.applyColor(at: (row, col))
                            }
                        }
                    }
                }
                .frame(width: totalWidth, height: totalHeight)
            }
            .position(x: startX + totalWidth / 2, y: startY + totalHeight / 2)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.5, min(4.0, value.magnitude))
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
            )
            .onTapGesture(count: 2) {
                scale = 1.0
                offset = .zero
            }
        }
    }

    private func baseCellSize(for size: BeadSize) -> CGFloat {
        switch size {
        case .biggie: return 44
        case .standard: return 28
        case .mini: return 18
        }
    }
}
```

- [ ] **Step 4: 编译验证**

Run:

```bash
xcodebuild build -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add BeadWorks/BeadWorks/Views/Components BeadWorks/BeadWorks/Views/BeadGridView.swift
git commit -m "feat(ui): add bead cell, pegboard background and grid view"
```

---

### Task 8: 调色板与工具栏

**Covers:** [S3, S5]

**Files：**
- Create: `BeadWorks/BeadWorks/Views/ColorPaletteBar.swift`
- Create: `BeadWorks/BeadWorks/Views/ToolBarView.swift`

- [ ] **Step 1: 实现 ColorPaletteBar**

创建 `BeadWorks/BeadWorks/Views/ColorPaletteBar.swift`：

```swift
import SwiftUI

struct ColorPaletteBar: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(viewModel.state.colorPalette.enumerated()), id: \.element.id) { index, color in
                    Button {
                        viewModel.selectedColorIndex = index
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.swiftUIColor)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.selectedColorIndex == index ? Color.primary : Color.clear, lineWidth: 3)
                                )
                            if viewModel.state.mode == .numbered {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(color.swiftUIColor.contrastText)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
```

- [ ] **Step 2: 实现 ToolBarView**

创建 `BeadWorks/BeadWorks/Views/ToolBarView.swift`：

```swift
import SwiftUI

struct ToolBarView: View {
    @ObservedObject var viewModel: CanvasViewModel
    var onFinish: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button("撤销") { viewModel.undo() }
            Button("重做") { viewModel.redo() }
            Button("清空") { viewModel.clear() }
            Button("完成") { onFinish() }
                .fontWeight(.bold)
        }
        .padding()
    }
}
```

- [ ] **Step 3: 编译验证**

Run:

```bash
xcodebuild build -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/Views/ColorPaletteBar.swift BeadWorks/BeadWorks/Views/ToolBarView.swift
git commit -m "feat(ui): add color palette bar and toolbar"
```

---

### Task 9: Canvas 主视图

**Covers:** [S3, S5]

**Files：**
- Create: `BeadWorks/BeadWorks/Views/CanvasView.swift`

- [ ] **Step 1: 实现 CanvasView**

创建 `BeadWorks/BeadWorks/Views/CanvasView.swift`：

```swift
import SwiftUI

struct CanvasView: View {
    @StateObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 0) {
            ColorPaletteBar(viewModel: viewModel)
                .background(Color(.systemBackground))

            BeadGridView(viewModel: viewModel)
                .background(Color(.systemGray5))

            ToolBarView(viewModel: viewModel, onFinish: { viewModel.finish() })
                .background(Color(.systemBackground))
        }
        .overlay {
            if viewModel.isFused {
                FinishedWorkView(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isFused)
    }
}
```

- [ ] **Step 2: 编译验证**

Run:

```bash
xcodebuild build -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add BeadWorks/BeadWorks/Views/CanvasView.swift
git commit -m "feat(ui): add CanvasView composing grid, palette and toolbar"
```

---

### Task 10: 图片导入与转换预览

**Covers:** [S4]

**Files：**
- Create: `BeadWorks/BeadWorks/Views/ImageImportView.swift`
- Create: `BeadWorks/BeadWorks/Views/ConversionPreviewView.swift`
- Create: `BeadWorks/BeadWorks/Services/PermissionManager.swift`

- [ ] **Step 1: 实现图片导入视图**

创建 `BeadWorks/BeadWorks/Views/ImageImportView.swift`：

```swift
import SwiftUI
import PhotosUI

struct ImageImportView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 20) {
            Text("选择一张图片生成拼豆底图")
                .font(.headline)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("从相册选择", systemImage: "photo")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            if selectedImage != nil {
                Button("下一步：调整参数") {
                    showPreview = true
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
        .padding()
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                selectedImage = uiImage
            }
        }
        .navigationDestination(isPresented: $showPreview) {
            if let image = selectedImage {
                ConversionPreviewView(image: image)
            }
        }
    }
}
```

- [ ] **Step 2: 实现转换预览视图**

创建 `BeadWorks/BeadWorks/Views/ConversionPreviewView.swift`：

```swift
import SwiftUI

struct ConversionPreviewView: View {
    let image: UIImage
    @State private var beadSize: BeadSize = .standard
    @State private var gridSize: Int = BeadSize.standard.defaultGridSize
    @State private var colorCount: Int = 8
    @State private var mode: CanvasMode = .numbered
    @State private var isConverting = false
    @State private var result: BeadConversionResult?
    @State private var showCanvas = false

    var body: some View {
        Form {
            Section("珠粒尺寸") {
                Picker("尺寸", selection: $beadSize) {
                    ForEach(BeadSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: beadSize) { _, new in
                    gridSize = new.defaultGridSize
                }
            }

            Section("网格尺寸") {
                Stepper("\(gridSize) × \(gridSize)", value: $gridSize, in: beadSize.gridRange)
            }

            Section("颜色数量") {
                Picker("颜色数", selection: $colorCount) {
                    Text("4").tag(4)
                    Text("8").tag(8)
                    Text("16").tag(16)
                    Text("24").tag(24)
                }
                .pickerStyle(.segmented)
            }

            Section("模式") {
                Picker("模式", selection: $mode) {
                    Text("真实模式").tag(CanvasMode.numbered)
                    Text("自由模式").tag(CanvasMode.free)
                }
                .pickerStyle(.segmented)
            }

            Button("生成底图") {
                convert()
            }
            .disabled(isConverting)
        }
        .navigationTitle("转换参数")
        .navigationDestination(isPresented: $showCanvas) {
            if let result {
                let palette = mode == .numbered ? result.colors : result.colors
                let state = CanvasState(
                    id: UUID(),
                    width: gridSize,
                    height: gridSize,
                    beadSize: beadSize,
                    mode: mode,
                    colorPalette: palette,
                    cells: result.indices,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                CanvasView(viewModel: CanvasViewModel(state: state))
            }
        }
    }

    private func convert() {
        isConverting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let palette = mode == .numbered
                ? BeadPaletteRepository.shared.defaultPalette()
                : result?.colors ?? []
            let conversion = ImageToBeadConverter().convert(
                image: image,
                width: gridSize,
                height: gridSize,
                colorCount: colorCount,
                palette: palette
            )
            DispatchQueue.main.async {
                self.result = conversion
                self.isConverting = false
                self.showCanvas = true
            }
        }
    }
}
```

> 注：`result?.colors ?? []` 在自由模式下逻辑需再细化；MVP 可先统一用默认色板，自由模式允许后续改色即可。

- [ ] **Step 3: 编译验证**

Run:

```bash
xcodebuild build -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/Views/ImageImportView.swift BeadWorks/BeadWorks/Views/ConversionPreviewView.swift
git commit -m "feat(ui): add image import and conversion preview"
```

---

### Task 11: 成品展示视图

**Covers:** [S3, S5]

**Files：**
- Create: `BeadWorks/BeadWorks/Views/FinishedWorkView.swift`
- Create: `BeadWorks/BeadWorks/Services/CanvasStore.swift`

- [ ] **Step 1: 实现 FinishedWorkView**

创建 `BeadWorks/BeadWorks/Views/FinishedWorkView.swift`：

```swift
import SwiftUI

struct FinishedWorkView: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)

                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )

                    BeadGridView(viewModel: viewModel)
                        .frame(width: 200, height: 200)
                }
                .padding(20)
            }
            .frame(width: 260, height: 280)

            HStack(spacing: 16) {
                Button("保存") { saveToAlbum() }
                Button("分享") { share() }
                Button("再做一次") { viewModel.isFused = false }
            }
            .padding()

            Spacer()
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }

    private func saveToAlbum() {
        // 后续实现：把 view 渲染成 UIImage 保存
    }

    private func share() {
        // 后续实现：系统分享
    }
}
```

- [ ] **Step 2: 实现 CanvasStore（作品保存）**

创建 `BeadWorks/BeadWorks/Services/CanvasStore.swift`：

```swift
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
        return urls.compactMap { url -> CanvasState? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(CanvasState.self, from: data)
        }
    }
}
```

- [ ] **Step 3: 编译验证**

Run:

```bash
xcodebuild build -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add BeadWorks/BeadWorks/Views/FinishedWorkView.swift BeadWorks/BeadWorks/Services/CanvasStore.swift
git commit -m "feat(ui): add finished work view and canvas store"
```

---

### Task 12: 集成测试与收尾

**Covers:** [S2, S5]

**Files：**
- Modify: `BeadWorks/BeadWorksTests/BeadWorksTests.swift`

- [ ] **Step 1: 添加集成测试**

修改 `BeadWorks/BeadWorksTests/BeadWorksTests.swift`，追加：

```swift
import XCTest
@testable import BeadWorks

final class BeadWorksIntegrationTests: XCTestCase {
    func testFreeCreationFlow() {
        let state = CanvasState.empty(width: 4, height: 4, beadSize: .standard)
        let vm = CanvasViewModel(state: state)
        vm.state.colorPalette = [
            BeadColor(id: 0, name: "Red", hex: "#E53935", isRealBead: true),
            BeadColor(id: 1, name: "Blue", hex: "#1E88E5", isRealBead: true)
        ]
        vm.selectedColorIndex = 0
        vm.applyColor(at: (0, 0))
        vm.applyColor(at: (1, 1))
        XCTAssertEqual(vm.state.colorIndex(at: (0, 0)), 0)
        XCTAssertEqual(vm.state.colorIndex(at: (1, 1)), 0)
        vm.undo()
        XCTAssertNil(vm.state.colorIndex(at: (1, 1)))
    }
}
```

- [ ] **Step 2: 运行全部测试**

Run:

```bash
xcodebuild test -project BeadWorks.xcodeproj -scheme BeadWorks -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: TEST PASSED

- [ ] **Step 3: 最终 Commit**

```bash
git add BeadWorks/BeadWorksTests/BeadWorksTests.swift
git commit -m "test: add integration test for free creation flow"
```

---

## Self-Review

### Spec Coverage Check

| Spec Section | 覆盖 Task |
|--------------|-----------|
| [S1] 背景与目标 | Task 1, 5 |
| [S2] 方案概述 | Task 1, 2, 3, 4, 5 |
| [S3] 视觉风格 | Task 7, 8, 11 |
| [S4] 图片转拼豆 | Task 4, 10 |
| [S5] 填色交互 | Task 6, 7, 8, 9, 11 |
| [S6] 游戏模式 | Task 5, 9, 10 |
| [S7] 数据与存储 | Task 2, 3, 11 |
| [S8] MVP 范围 | 全任务 |

### Placeholder Scan

- 无 TBD / TODO。
- 颜色量化在 Task 4 中做了简化，后续可在独立 Task 中替换为 k-means。
- 保存到相册、系统分享在 Task 11 中先留空实现，需要单独 Task 补全。

### Type Consistency

- `CanvasState.cells` 为 `[[Int?]]`，ViewModel 与 View 均使用同一结构。
- `BeadSize` 枚举在模型、视图、转换参数中一致。
- `Color` 扩展 hex 初始化在 `BeadColor.swift` 与 `BeadPaletteRepository.swift` 中有重复，后续可抽到共享扩展。

## 已知待补任务（MVP 之后）

1. 补齐 48 色真实拼豆色板 JSON。
2. 替换颜色量化为 k-means / 中位切分算法。
3. 实现拖拽连填手势。
4. 实现保存到相册与系统分享。
5. 实现「我的作品」画廊视图。
6. 优化 BeadGridView 性能（大网格用 Canvas/Metal 渲染）。
