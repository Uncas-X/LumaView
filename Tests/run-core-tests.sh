#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers -framework AVFoundation \
  "$PROJECT_ROOT/Sources/Localization.swift" \
  "$PROJECT_ROOT/Sources/AudioWaveform.swift" "$PROJECT_ROOT/Sources/AudioArtwork.swift" "$PROJECT_ROOT/Sources/MediaFormats.swift" "$PROJECT_ROOT/Sources/PostScriptDocument.swift" "$PROJECT_ROOT/Sources/VectorRenderer.swift" "$PROJECT_ROOT/Sources/ThumbnailRequest.swift" "$PROJECT_ROOT/Sources/CompatibilityMedia.swift" "$PROJECT_ROOT/Sources/PhotoshopImage.swift" "$PROJECT_ROOT/Sources/ImageLibrary.swift" "$PROJECT_ROOT/Tests/CoreTests.swift" \
  -o "$TEST_BUILD_DIR/core-tests"
"$TEST_BUILD_DIR/core-tests"
