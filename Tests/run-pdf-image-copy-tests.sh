#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-pdf-image-copy-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
mkdir -p "$LUMAVIEW_WORK_ROOT/pdf-image-copy-tests"
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" -framework CoreGraphics -framework ImageIO \
  "$TEST_SOURCE_ROOT/Sources/PDFImageCopy.swift" "$TEST_SOURCE_ROOT/Tests/PDFImageCopyTests.swift" \
  -o "$TEST_BUILD_DIR/pdf-image-copy-tests"
"$TEST_BUILD_DIR/pdf-image-copy-tests" | tee "$LUMAVIEW_WORK_ROOT/pdf-image-copy-tests/pdf-image-copy-test-results.txt"
