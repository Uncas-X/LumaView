#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-localization-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  "$PROJECT_ROOT/Sources/Localization.swift" "$PROJECT_ROOT/Sources/LocalizationMetadata.swift" "$PROJECT_ROOT/Tests/LocalizationTests.swift" \
  -o "$TEST_BUILD_DIR/localization-tests"
LUMAVIEW_LOCALIZATIONS="$PROJECT_ROOT/Resources/Localizations/catalog.json" \
  "$TEST_BUILD_DIR/localization-tests" "$PROJECT_ROOT/Resources/Localizations"
