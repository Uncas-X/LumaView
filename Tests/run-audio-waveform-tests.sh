#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "$LUMAVIEW_WORK_ROOT/tmp/lumaview-audio-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
TEST_ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -O -target "$TEST_ARCH-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers -framework AVFoundation \
  "$TEST_SOURCE_ROOT/Sources/Localization.swift" \
  "$TEST_SOURCE_ROOT/Sources/MediaFormats.swift" \
  "$TEST_SOURCE_ROOT/Sources/DocumentMedia.swift" \
  "$TEST_SOURCE_ROOT/Sources/PostScriptDocument.swift" "$TEST_SOURCE_ROOT/Sources/VectorRenderer.swift" \
  "$TEST_SOURCE_ROOT/Sources/AudioWaveform.swift" \
  "$TEST_SOURCE_ROOT/Sources/AudioArtwork.swift" \
  "$TEST_SOURCE_ROOT/Sources/ThumbnailRequest.swift" "$TEST_SOURCE_ROOT/Sources/CompatibilityMedia.swift" \
  "$TEST_SOURCE_ROOT/Sources/VideoSession.swift" \
  "$TEST_SOURCE_ROOT/Sources/PhotoshopImage.swift" "$TEST_SOURCE_ROOT/Sources/ImageLibrary.swift" \
  "$TEST_SOURCE_ROOT/Tests/AudioWaveformTests.swift" \
  -o "$TEST_BUILD_DIR/audio-waveform-tests"
# Fixture creation uses a development FFmpeg with MP3, FLAC and Opus encoders.
# Runtime compatibility and cover tests always use the tools shipped in the app.
LUMAVIEW_MEDIA_TOOLS="$TEST_SOURCE_ROOT/Resources/MediaTools" \
LUMAVIEW_LOCALIZATIONS="$TEST_SOURCE_ROOT/Resources/Localizations/catalog.json" \
  "$TEST_BUILD_DIR/audio-waveform-tests"
