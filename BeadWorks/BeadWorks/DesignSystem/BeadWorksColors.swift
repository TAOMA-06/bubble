import SwiftUI

enum BeadWorksColor {
    // 背景层 — 温暖米白色，模拟拼豆垫板
    static let background = Color(red: 0.98, green: 0.96, blue: 0.92) // #FAF5EB
    static let surface = Color.white
    static let surfaceElevated = Color(red: 0.96, green: 0.94, blue: 0.90) // #F5F0E6
    
    // 边框 — 软木色，模拟拼豆板边缘
    static let border = Color(red: 0.85, green: 0.80, blue: 0.72) // #D9CCB8
    
    // 文字 — 深棕色，模拟木制拼豆工具
    static let textPrimary = Color(red: 0.20, green: 0.16, blue: 0.12) // #33291E
    static let textSecondary = Color(red: 0.45, green: 0.38, blue: 0.30) // #73614D
    static let textTertiary = Color(red: 0.65, green: 0.58, blue: 0.48) // #A6947A
    
    // 强调色 — 拼豆常用颜色
    static let accentRed = Color(red: 0.90, green: 0.22, blue: 0.21) // #E63836
    static let accentBlue = Color(red: 0.12, green: 0.53, blue: 0.90) // #1F87E6
    static let accentYellow = Color(red: 0.99, green: 0.85, blue: 0.21) // #FCD936
    static let accentGreen = Color(red: 0.26, green: 0.63, blue: 0.28) // #43A147
    static let accentPurple = Color(red: 0.55, green: 0.27, blue: 0.68) // #8C45AE
    static let accentOrange = Color(red: 0.95, green: 0.58, blue: 0.11) // #F3941C
    
    // 主强调色
    static let accent = accentRed
    
    // 画布背景 — 浅灰色，模拟拼豆板
    static let canvasBackground = Color(red: 0.92, green: 0.90, blue: 0.86) // #EBE6DB
    
    // 完成状态 — 柔和的金色
    static let success = Color(red: 0.95, green: 0.80, blue: 0.30) // #F2CC4D
    
    // 警告状态
    static let warning = Color(red: 0.95, green: 0.65, blue: 0.20) // #F2A633
    
    // 错误状态
    static let error = Color(red: 0.90, green: 0.22, blue: 0.21) // #E63836
}

enum BeadWorksFont {
    static func title(_ weight: Font.Weight = .bold) -> Font {
        .system(.largeTitle, design: .rounded, weight: weight)
    }
    
    static func headline(_ weight: Font.Weight = .semibold) -> Font {
        .system(.title3, design: .rounded, weight: weight)
    }
    
    static func body(_ weight: Font.Weight = .regular) -> Font {
        .system(.body, design: .rounded, weight: weight)
    }
    
    static func caption(_ weight: Font.Weight = .medium) -> Font {
        .system(.caption, design: .rounded, weight: weight)
    }
    
    static func button(_ weight: Font.Weight = .semibold) -> Font {
        .system(.body, design: .rounded, weight: weight)
    }
}