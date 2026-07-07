#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
UNITY_PATH="${UNITY_PATH:-/Applications/Unity/Hub/Editor/6000.5.2f1/Unity.app/Contents/MacOS/Unity}"
UNITY_ROOT="$(cd "$(dirname "$UNITY_PATH")/../../.." && pwd)"
OUTPUT_PATH="${1:-$PROJECT_ROOT/Builds/iOSDevice}"
EXPORT_PATH="$OUTPUT_PATH.exporting"
LOG_DIR="$PROJECT_ROOT/Logs"
LOG_FILE="$LOG_DIR/ios-device-export.log"
BUILD_MODE="${BUILD_MODE:-Release}"

if [[ "${1:-}" == "--debug" ]]; then
  BUILD_MODE="Debug"
  shift
  OUTPUT_PATH="${1:-$PROJECT_ROOT/Builds/iOSDevice}"
  EXPORT_PATH="$OUTPUT_PATH.exporting"
fi

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
rm -rf "$EXPORT_PATH" "$PROJECT_ROOT/Library/Bee/artifacts/iOS" "$PROJECT_ROOT/Il2CppTempDirArtifacts"

echo "Exporting iOS Device project (${BUILD_MODE})..."
UNITY_COMMAND=( \
  "$UNITY_PATH" \
  -batchmode \
  -nographics \
  -quit \
  -projectPath "$PROJECT_ROOT" \
  -executeMethod BeadWorks.Editor.IOSDeviceBuild.BuildFromCommandLine \
  -buildOutput "$EXPORT_PATH" \
  -logFile "$LOG_FILE" \
)
if [[ "$BUILD_MODE" == "Debug" ]]; then
  UNITY_COMMAND+=(-developmentBuild)
fi
"${UNITY_COMMAND[@]}"

rm -rf "$OUTPUT_PATH"
mv "$EXPORT_PATH" "$OUTPUT_PATH"

XCODE_PROJECT="$OUTPUT_PATH/Unity-iPhone.xcodeproj"
if [[ ! -d "$XCODE_PROJECT" ]]; then
  echo "Unity export finished, but Xcode project was not found at: $XCODE_PROJECT" >&2
  echo "Unity log: $LOG_FILE" >&2
  exit 3
fi

echo ""
echo "iOS Device Xcode project exported."
echo "Xcode project: $XCODE_PROJECT"
echo ""
echo "Next steps:"
echo "  1. Open the project in Xcode"
echo "  2. Connect your iPhone via USB"
echo "  3. Select your iPhone as the run destination"
echo "  4. Signing & Capabilities → enable Automatically manage signing, pick your Team"
echo "  5. Cmd+R to build and run on device"
