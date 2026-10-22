#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-preferences-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
OUTPUT_DIR="${1:-$LUMAVIEW_WORK_ROOT/default-preferences-tests}"
mkdir -p "$OUTPUT_DIR"
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers \
  "$PROJECT_ROOT/Sources/Localization.swift" \
  "$PROJECT_ROOT/Sources/MediaFormats.swift" \
  "$PROJECT_ROOT/Sources/DefaultImageApplication.swift" \
  "$PROJECT_ROOT/Sources/DefaultViewerPreferences.swift" \
  "$PROJECT_ROOT/Tests/DefaultPreferencesTests.swift" \
  -o "$TEST_BUILD_DIR/default-preferences-tests"
# Native AppKit requires a normal desktop session. The injected fake backend
# records every request in memory and never changes real file associations.
"$TEST_BUILD_DIR/default-preferences-tests" "$OUTPUT_DIR"
