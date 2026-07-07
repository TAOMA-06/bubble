#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "Cleaning iOS build artifacts..."

rm -rf \
  "$PROJECT_ROOT/Builds/iOSSimulator" \
  "$PROJECT_ROOT/Builds/iOSDevice" \
  "$PROJECT_ROOT/Library/Bee/artifacts/iOS" \
  "$PROJECT_ROOT/Il2CppTempDirArtifacts" \
  /private/tmp/BeadWorksUnityDerivedData

# macOS/iCloud duplicate copies (e.g. "mscorlib 2.dll") break IL2CPP linking.
while IFS= read -r -d '' dup; do
  rm -f "$dup"
done < <(find "$PROJECT_ROOT/Builds" "$PROJECT_ROOT/Library/Bee" -name '* 2.*' -print0 2>/dev/null || true)

echo "Clean complete."
