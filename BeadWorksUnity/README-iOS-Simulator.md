# iOS Simulator Build

在 **Apple Silicon Mac** 上导出 **ARM64 模拟器** Xcode 工程，避免与 iPhone 17 等模拟器架构不匹配。

```bash
cd BeadWorksUnity
./build-ios-simulator.sh
```

脚本会：

1. Unity 批量导出（`Simulator SDK` + `ARM64` 模拟器架构）
2. 输出 `Builds/iOSSimulator/Unity-iPhone.xcodeproj`
3. 用 `xcodebuild` 编译 `arm64` 模拟器包
4. 清理旧的 DerivedData，避免沿用 x86_64 缓存

## 直接看到模拟器效果

如果你想验证“打开 Xcode 后 Cmd+R 会看到的效果”，可以直接运行：

```bash
cd BeadWorksUnity
./run-ios-simulator.sh
```

它会：

1. 调用 `./build-ios-simulator.sh` 导出并编译 Xcode 工程
2. 启动 `SIMULATOR_NAME` 指定的模拟器（默认 `iPhone 17`）
3. 安装并启动 `com.beadworks.unity`
4. 保存启动截图到 `Builds/iOSSimulator/launch-screenshot.png`

如果已经导出并编译过，只想重新安装/启动现有 app：

```bash
./run-ios-simulator.sh --no-export
```

调试包才使用：

```bash
./run-ios-simulator.sh --debug
```

## 在 Xcode 里运行

1. 打开 `Builds/iOSSimulator/Unity-iPhone.xcodeproj`
2. Scheme 选 **Unity-iPhone**
3. 设备选 **iPhone 17**（或其他模拟器）
4. **Cmd+R**

若改过 Unity 代码，重新执行 `./build-ios-simulator.sh` 再 Run。

## 相册权限提示

主菜单「导入图片生成模板」首次点击「选择照片」会弹出系统 `PHPickerViewController`；成品查看页「保存作品」首次调用会触发相册写入授权弹窗。这两条权限文案（`NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`）由 `Assets/Scripts/Editor/IOSNativePostProcessor.cs` 在每次导出时自动写入 `Info.plist`，无需手动编辑 Xcode 工程。模拟器同样会弹出授权提示，可在 **模拟器 → Settings → Privacy & Security → Photos** 里检查/重置授权状态。

## 环境要求

- Unity `6000.5.2f1`
- Unity **iOS Build Support** 模块
- Xcode（建议正式版；Beta 可能与 Unity 导出偶发不兼容）

自定义 Unity 路径：

```bash
UNITY_PATH="/path/to/Unity.app/Contents/MacOS/Unity" ./build-ios-simulator.sh
```

自定义模拟器名称：

```bash
SIMULATOR_NAME="iPhone 17 Pro" ./build-ios-simulator.sh
```

## 真机测试

模拟器与真机导出分离。真机请用：

```bash
./build-ios-device.sh
```

详见 [README-iOS-Device.md](README-iOS-Device.md)。

## 故障排查

| 现象 | 处理 |
|------|------|
| platform doesn't match | 重新跑 `./build-ios-simulator.sh`（会强制 ARM64） |
| `Undefined symbol: _g_CodegenRegistration` | IL2CPP 未完整编译，执行 `./clean-ios-build.sh` 后重跑构建脚本 |
| `mscorlib` duplicate / IL2CPP 3715 errors | 缓存里有 `xxx 2.dll` 重复文件，执行 `./clean-ios-build.sh` |
| Unity 找不到 | 设置 `UNITY_PATH` 或安装 6000.5.2f1 |
| 导出失败 | 查看 `Logs/ios-simulator-export.log` |

在 Xcode 里 Build Failed 时，**先关闭 Xcode**，在终端执行：

```bash
cd BeadWorksUnity
./build-ios-simulator.sh
```

成功后再重新打开 `Builds/iOSSimulator/Unity-iPhone.xcodeproj` → Cmd+R。

Unity 菜单也可手动导出：**BeadWorks → Build → iOS Simulator Xcode Project**
