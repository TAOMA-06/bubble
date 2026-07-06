#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
UNITY_PATH="${UNITY_PATH:-/Applications/Unity/Hub/Editor/6000.5.2f1/Unity.app/Contents/MacOS/Unity}"
UNITY_ROOT="$(cd "$(dirname "$UNITY_PATH")/../../.." && pwd)"
OUTPUT_PATH="${1:-$PROJECT_ROOT/Builds/iOSSimulator}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/BeadWorksUnityDerivedData}"
LOG_DIR="$PROJECT_ROOT/Logs"
LOG_FILE="$LOG_DIR/ios-simulator-export.log"

if [[ ! -x "$UNITY_PATH" ]]; then
  echo "Unity executable not found: $UNITY_PATH" >&2
  exit 1
fi

if [[ ! -d "$UNITY_ROOT/PlaybackEngines/iOSSupport" ]]; then
  echo "Unity iOS Build Support is not installed for: $UNITY_ROOT" >&2
  echo "Install the iOS Build Support module in Unity Hub, then run this script again." >&2
  exit 2
fi

mkdir -p "$LOG_DIR"

"$UNITY_PATH" \
  -batchmode \
  -nographics \
  -quit \
  -projectPath "$PROJECT_ROOT" \
  -executeMethod BeadWorks.Editor.IOSSimulatorBuild.BuildFromCommandLine \
  -buildOutput "$OUTPUT_PATH" \
  -logFile "$LOG_FILE"

XCODE_PROJECT="$OUTPUT_PATH/Unity-iPhone.xcodeproj"
if [[ ! -d "$XCODE_PROJECT" ]]; then
  echo "Unity export finished, but Xcode project was not found at: $XCODE_PROJECT" >&2
  echo "Unity log: $LOG_FILE" >&2
  exit 3
fi

xcodebuild \
  -project "$XCODE_PROJECT" \
  -scheme Unity-iPhone \
  -destination "generic/platform=iOS Simulator" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

echo "iOS Simulator build succeeded."
echo "Xcode project: $XCODE_PROJECT"
