# 拼豆工坊 iOS 原生 MVP（2026-08-30）

> 本文件是云端/仓库可读的权威副本，路径与当初本机 Hermes 计划一致：
> `.hermes/plans/2026-08-30_204842-beadworks-ios-mvp.md`
>
> 本机当时没有把该文件提交进 git；磁盘上也不再有独立原稿。下面内容与
> `docs/compose/specs/2026-08-30-beadworks-ios-mvp.md` 对齐，供后续云端任务直接读取。

## [S1] 目标

做一款 iOS 拼豆（Perler Beads）休闲应用，核心体验：

1. **自由创作**：空白 pegboard 上选色、绘制（16×16 快速板 / 29×29 标准板，默认 29）。
2. **导入图片生成拼豆模板**：相册选图 → 居中裁剪 → 盒式降采样 → 固定色板就近取色（16/24/32/48，默认 32）。
3. **示例图纸复刻**（次级入口）：五张内置 16×16 图纸，半透明引导 + 错误格提示。
4. **熨烫成品**：把当前摆放渲染为轻熔 / 全熔效果（不做物理热量模拟）。
5. **作品库与分享**：本地保存、重新打开编辑、系统分享图、写入相册。

## [S2] 方案概述

| 模块 | 方案 |
|------|------|
| 技术栈 | SwiftUI + Canvas + PhotosPicker，无第三方依赖，iOS 17+ |
| 工程 | `BeadWorksNative/`，XcodeGen `project.yml` + 已提交的 `BeadWorks.xcodeproj` |
| 架构 | 按功能分层：`App` / `Domain` / `Features` / `Services` / `Rendering` / `Support` |
| 状态 | `@Observable` 视图模型（编辑器、导入）+ `BoardStore` 环境对象 |
| 视觉 | 暖色工作台主题；圆珠带孔、高光；熨烫后轻熔/全熔 |
| 图片导入 | `PhotosPicker` → `PhotoTemplateService`（可后台转换） |
| 图纸 | `BuiltinPatternFactory`（爱心 / 星星 / 国风云纹 / 奶茶杯 / 应援字牌） |
| 存档 | Documents/Gallery：`index.json` + PNG；另存 `draft.json` 一份未完成稿 |
| 分享 | 1080×1920 分享卡（标题、尺寸、珠数、成品类型、水印） |

## [S3] 主流程

```
主菜单
├── 继续上次创作（若有草稿）
├── 自由创作（内联 16×16 / 29×29） → 摆豆 → 熨烫 → 成品 → 保存/分享
├── 导入图片 → 选照片 → 预览+选尺寸 → 摆豆（带引导） → 熨烫 → 成品
├── 示例图纸（次级） → 选图纸 → 带引导摆豆 → 熨烫 → 成品
└── 作品库 → 详情 → 重新编辑 / 分享 / 删除
```

## [S4] 编辑器能力

- 工具：摆豆、擦除、取色、移动（缩放后平移）
- 撤销 / 重做：按一次连续笔划提交，而不是每一颗珠
- 双指缩放（1×–4×），双击复位；大板（导入 48×48）可放大后摆放
- 模板引导环可开关；纠错提示标出缺失 / 错色
- 离开编辑器时，非空板写入本地草稿

## [S5] 明确不做（本切片）

- Unity 式 3D 珠子、热量扩散熨烫、烧焦
- Mini / Biggie 物理珠径、云同步、关卡、广告、内购
- 多图批量导入
- 成品 3D 旋转（冰箱贴 / 钥匙扣 / 挂件只作为元数据 + 分享卡标签）

## [S6] 仓库结构

```
BeadWorksNative/BeadWorks/
├── App/            # 入口、导航、启动参数
├── Domain/         # 棋盘、色板、图纸、作品、工具、成品类型
├── Features/       # Home / Editor / PhotoImport / Patterns / FinishedWork / Gallery / Splash
├── Services/       # 存档、转换、内置图纸、匹配、分享、相册
├── Rendering/      # Canvas 珠子与 pegboard
├── Support/        # 主题、修饰器、系统分享页
└── Views/          # 跨页组件
```

Unity 工程 `BeadWorksUnity/` 继续保留、不删除。

## [S7] 默认取舍

1. 不把 Unity 3D / 热量熨烫搬进原生版。
2. 成品类型只做 2D 标签与分享卡，不做 3D 旋转查看。
3. 内置五张图纸从 Unity `BuiltinPatternFactory` 移植。
4. 撤销按整段拖动画一笔回退。
5. 草稿只有一份，覆盖写入。

## [S8] 测试

- 单元测试：棋盘、色板转换、作品库、草稿、撤销、图纸匹配、内置图纸、分享图尺寸
- UI 测试：主菜单、自由创作、导入夹具图、熨烫保存、作品库回编、示例图纸、撤销
- 启动参数：`-uiTestResetStorage`、`-uiTestFixtureImage`

## [S9] 后续云端任务（接着做）

在 Mac / 云端有 Xcode 的环境里：

1. 对照本文件核对 `BeadWorksNative/` 实现是否缺项。
2. 用模拟器跑 `BeadWorksTests` 与 `BeadWorksUITests`，修编译或测试失败。
3. 若用户提供与本文件冲突的 Hermes 原文，以用户原文为准并改代码。
