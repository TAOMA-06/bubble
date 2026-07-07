#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
UNITY_PATH="${UNITY_PATH:-/Applications/Unity/Hub/Editor/6000.5.2f1/Unity.app/Contents/MacOS/Unity}"
UNITY_ROOT="$(cd "$(dirname "$UNITY_PATH")/../../.." && pwd)"
OUTPUT_PATH="${1:-$PROJECT_ROOT/Builds/iOSSimulator}"
EXPORT_PATH="$OUTPUT_PATH.exporting"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/BeadWorksUnityDerivedData}"
LOG_DIR="$PROJECT_ROOT/Logs"
LOG_FILE="$LOG_DIR/ios-simulator-export.log"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
BUILD_MODE="${BUILD_MODE:-Release}"

if [[ "${1:-}" == "--debug" ]]; then
  BUILD_MODE="Debug"
  shift
  OUTPUT_PATH="${1:-$PROJECT_ROOT/Builds/iOSSimulator}"
  EXPORT_PATH="$OUTPUT_PATH.exporting"
fi

XCODE_CONFIGURATION="Release"
if [[ "$BUILD_MODE" == "Debug" ]]; then
  XCODE_CONFIGURATION="Debug"
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

# Keep the last successful Xcode export intact until Unity finishes the new export.
# If Unity licensing or Package Manager fails, Xcode can still open the previous project.
rm -rf "$EXPORT_PATH" "$PROJECT_ROOT/Library/Bee/artifacts/iOS" "$PROJECT_ROOT/Il2CppTempDirArtifacts" "$DERIVED_DATA_PATH"

echo "Exporting iOS Simulator project (ARM64, ${BUILD_MODE})..."
UNITY_COMMAND=( \
  "$UNITY_PATH" \
  -batchmode \
  -nographics \
  -quit \
  -projectPath "$PROJECT_ROOT" \
  -executeMethod BeadWorks.Editor.IOSSimulatorBuild.BuildFromCommandLine \
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

# Apple Silicon Mac: prefer arm64 simulator (Unity export should already be ARM64)
ARCH_ARGS=()
if [[ "$(uname -m)" == "arm64" ]]; then
  ARCH_ARGS+=(ONLY_ACTIVE_ARCH=YES)
fi

# Pick a concrete simulator UUID (name alone is ambiguous across iOS 26/27 runtimes)
DESTINATION="generic/platform=iOS Simulator"
SIM_ID="$(xcrun simctl list devices available 2>/dev/null \
  | grep "${SIMULATOR_NAME} (" \
  | head -1 \
  | sed -nE 's/.*\(([A-F0-9-]{36})\).*/\1/p' || true)"
if [[ -n "$SIM_ID" ]]; then
  DESTINATION="platform=iOS Simulator,id=${SIM_ID}"
fi

echo "Building for: ${DESTINATION}"
xcodebuild \
  -project "$XCODE_PROJECT" \
  -scheme Unity-iPhone \
  -destination "$DESTINATION" \
  -configuration "$XCODE_CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  "${ARCH_ARGS[@]}" \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/${XCODE_CONFIGURATION}-iphonesimulator/BeadWorks.app"
if [[ -d "$APP_PATH" ]]; then
  echo "Built app: $APP_PATH"
  file "$APP_PATH/BeadWorks" || true
fi

echo ""
echo "iOS Simulator build succeeded."
echo "Xcode project: $XCODE_PROJECT"
echo "Open in Xcode, select an iPhone Simulator, then Cmd+R."
