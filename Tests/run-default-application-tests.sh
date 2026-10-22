#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-default-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers \
  "$PROJECT_ROOT/Sources/Localization.swift" \
  "$PROJECT_ROOT/Sources/MediaFormats.swift" "$PROJECT_ROOT/Sources/DefaultImageApplication.swift" "$PROJECT_ROOT/Tests/DefaultApplicationTests.swift" \
  -o "$TEST_BUILD_DIR/default-application-tests"
# The executable only reads supported UTIs. Every association write uses an
# in-memory mock, so this suite never changes the user's file associations.
"$TEST_BUILD_DIR/default-application-tests"
