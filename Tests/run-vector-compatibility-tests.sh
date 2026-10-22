#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/vector-compatibility}"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-vector-compatibility.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
mkdir -p "$TEST_OUTPUT"
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework QuartzCore \
  "$TEST_SOURCE_ROOT/Sources/Localization.swift" "$TEST_SOURCE_ROOT/Sources/ThumbnailRequest.swift" "$TEST_SOURCE_ROOT/Sources/PostScriptDocument.swift" "$TEST_SOURCE_ROOT/Sources/VectorRenderer.swift" \
  "$TEST_SOURCE_ROOT/Sources/DocumentMedia.swift" "$TEST_SOURCE_ROOT/Tests/VectorCompatibilityTests.swift" \
  -o "$TEST_BUILD_DIR/vector-compatibility-tests"
"$TEST_BUILD_DIR/vector-compatibility-tests" "$TEST_OUTPUT" "$@" | tee "$TEST_OUTPUT/vector-compatibility-test-results.txt"
