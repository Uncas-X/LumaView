#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-photoshop-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
python3 "$PROJECT_ROOT/Tests/make-photoshop-fixtures.py" "$TEST_BUILD_DIR/fixtures"
xcrun swiftc -swift-version 5 -Onone -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" -framework AppKit -framework ImageIO -framework AVFoundation -framework UniformTypeIdentifiers \
  "$PROJECT_ROOT/Sources/Localization.swift" "$PROJECT_ROOT/Sources/AudioWaveform.swift" \
  "$PROJECT_ROOT/Sources/AudioArtwork.swift" "$PROJECT_ROOT/Sources/MediaFormats.swift" \
  "$PROJECT_ROOT/Sources/ThumbnailRequest.swift" "$PROJECT_ROOT/Sources/PostScriptDocument.swift" \
  "$PROJECT_ROOT/Sources/VectorRenderer.swift" "$PROJECT_ROOT/Sources/CompatibilityMedia.swift" \
  "$PROJECT_ROOT/Sources/PhotoshopImage.swift" "$PROJECT_ROOT/Sources/ImageLibrary.swift" \
  "$PROJECT_ROOT/Tests/PhotoshopImageTests.swift" -o "$TEST_BUILD_DIR/photoshop-tests"
LUMAVIEW_LOCALIZATIONS="$PROJECT_ROOT/Resources/Localizations/catalog.json" \
  "$TEST_BUILD_DIR/photoshop-tests" "$TEST_BUILD_DIR/fixtures"
