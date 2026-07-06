# iOS Simulator Build

This Unity project is the game source of truth. Use this path to export an Xcode project that targets the iOS Simulator:

```bash
cd BeadWorksUnity
./build-ios-simulator.sh
```

The script:

1. Runs Unity in batch mode.
2. Executes `BeadWorks.Editor.IOSSimulatorBuild.BuildFromCommandLine`.
3. Exports `Builds/iOSSimulator/Unity-iPhone.xcodeproj`.
4. Runs `xcodebuild` against the `Unity-iPhone` scheme for `generic/platform=iOS Simulator`.

Requirements:

- Unity `6000.5.2f1`.
- Unity iOS Build Support module installed.
- Xcode with an iOS Simulator SDK installed.

If Unity is installed somewhere else, pass it through `UNITY_PATH`:

```bash
UNITY_PATH="/path/to/Unity.app/Contents/MacOS/Unity" ./build-ios-simulator.sh
```
