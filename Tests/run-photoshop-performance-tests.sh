#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/photoshop-performance}"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-photoshop-performance.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
mkdir -p "$TEST_OUTPUT"
python3 "$TEST_SOURCE_ROOT/Tests/make-photoshop-performance-fixtures.py" "$TEST_BUILD_DIR/fixtures"
xcrun swiftc -swift-version 5 -O -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" -framework AppKit -framework ImageIO \
  "$TEST_SOURCE_ROOT/Sources/Localization.swift" "$TEST_SOURCE_ROOT/Sources/PhotoshopImage.swift" \
  "$TEST_SOURCE_ROOT/Tests/PhotoshopPerformanceTests.swift" -o "$TEST_BUILD_DIR/photoshop-performance-tests"
LUMAVIEW_LOCALIZATIONS="$TEST_SOURCE_ROOT/Resources/Localizations/catalog.json" \
  "$TEST_BUILD_DIR/photoshop-performance-tests" "$TEST_BUILD_DIR/fixtures" "$@" | tee "$TEST_OUTPUT/photoshop-performance-test-results.txt"
