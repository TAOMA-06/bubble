#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/BeadWorksUnityDerivedData}"
BUILD_MODE="${BUILD_MODE:-Release}"
EXPORT_MODE="yes"
SCREENSHOT_PATH="${SCREENSHOT_PATH:-$PROJECT_ROOT/Builds/iOSSimulator/launch-screenshot.png}"
BUNDLE_ID="com.beadworks.unity"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      BUILD_MODE="Debug"
      shift
      ;;
    --no-export)
      EXPORT_MODE="no"
      shift
      ;;
    --simulator)
      SIMULATOR_NAME="${2:?Missing simulator name after --simulator}"
      shift 2
      ;;
    --screenshot)
      SCREENSHOT_PATH="${2:?Missing screenshot path after --screenshot}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--debug] [--no-export] [--simulator \"iPhone 17\"] [--screenshot path]" >&2
      exit 64
      ;;
  esac
done

XCODE_CONFIGURATION="Release"
if [[ "$BUILD_MODE" == "Debug" ]]; then
  XCODE_CONFIGURATION="Debug"
fi

if [[ "$EXPORT_MODE" == "yes" ]]; then
  if [[ "$BUILD_MODE" == "Debug" ]]; then
    "$SCRIPT_DIR/build-ios-simulator.sh" --debug "$PROJECT_ROOT/Builds/iOSSimulator"
  else
    "$SCRIPT_DIR/build-ios-simulator.sh" "$PROJECT_ROOT/Builds/iOSSimulator"
  fi
fi

XCODE_PROJECT="$PROJECT_ROOT/Builds/iOSSimulator/Unity-iPhone.xcodeproj"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/${XCODE_CONFIGURATION}-iphonesimulator/BeadWorks.app"

if [[ ! -d "$XCODE_PROJECT" ]]; then
  echo "Xcode project not found: $XCODE_PROJECT" >&2
  echo "Run ./build-ios-simulator.sh first, or omit --no-export." >&2
  exit 3
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found: $APP_PATH" >&2
  echo "Run ./build-ios-simulator.sh first, or omit --no-export." >&2
  exit 4
fi

SIM_ID="$(xcrun simctl list devices available 2>/dev/null \
  | grep "${SIMULATOR_NAME} (" \
  | head -1 \
  | sed -nE 's/.*\(([A-F0-9-]{36})\).*/\1/p' || true)"

if [[ -z "$SIM_ID" ]]; then
  echo "Simulator not found: $SIMULATOR_NAME" >&2
  echo "Available simulators:" >&2
  xcrun simctl list devices available >&2
  exit 5
fi

echo "Booting simulator: $SIMULATOR_NAME ($SIM_ID)"
xcrun simctl boot "$SIM_ID" >/dev/null 2>&1 || true
open -a Simulator >/dev/null 2>&1 || true

echo "Installing: $APP_PATH"
xcrun simctl install "$SIM_ID" "$APP_PATH"

echo "Launching: $BUNDLE_ID"
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"

mkdir -p "$(dirname "$SCREENSHOT_PATH")"
sleep 2
xcrun simctl io "$SIM_ID" screenshot "$SCREENSHOT_PATH"

echo ""
echo "BeadWorks launched in Simulator."
echo "Screenshot: $SCREENSHOT_PATH"
echo "Xcode project: $XCODE_PROJECT"
echo "To test in Xcode: open the project, select scheme Unity-iPhone and ${SIMULATOR_NAME}, then Cmd+R."
