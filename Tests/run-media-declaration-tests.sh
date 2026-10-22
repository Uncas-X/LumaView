#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
APP_PATH="${1:-$PROJECT_ROOT/../LumaView.app}"
REPORT_PATH="${2:-$LUMAVIEW_WORK_ROOT/media-declaration-test-results.txt}"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-declaration-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
TEST_APP="$TEST_BUILD_DIR/MediaDeclarationTests.app"
mkdir -p "$TEST_APP/Contents/MacOS"
cp "$APP_PATH/Contents/Info.plist" "$TEST_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable MediaDeclarationTests' "$TEST_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier io.local.lumaview.declaration-tests' "$TEST_APP/Contents/Info.plist"
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" -framework UniformTypeIdentifiers \
  "$PROJECT_ROOT/Sources/Localization.swift" \
  "$PROJECT_ROOT/Sources/MediaFormats.swift" "$PROJECT_ROOT/Tests/MediaDeclarationTests.swift" \
  -o "$TEST_APP/Contents/MacOS/MediaDeclarationTests"
# Execute directly: this Foundation-only helper does not launch an AppKit app
# or register the temporary bundle with Launch Services.
"$TEST_APP/Contents/MacOS/MediaDeclarationTests" "$REPORT_PATH"
