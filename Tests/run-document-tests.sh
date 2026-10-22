#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_APP_PATH="${LUMAVIEW_TEST_APP_PATH:-$LUMAVIEW_WORK_ROOT/LumaView-document-test.app}"
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/document-ui-tests}"
mkdir -p "$TEST_OUTPUT"
TEST_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-document-tests.XXXXXX")"
TEST_RUN_OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-document-results.XXXXXX")"
TEST_RUN_OUTPUT="$(cd "$TEST_RUN_OUTPUT" && pwd -P)"
# Foundation standardizes these macOS temp aliases without the /private prefix.
# Match its file URL spelling while retaining a normalized, single-slash path.
case "$TEST_RUN_OUTPUT" in
  /private/var/*|/private/tmp/*) TEST_RUN_OUTPUT="${TEST_RUN_OUTPUT#/private}" ;;
esac
finish_tests() {
  local test_status=$?
  trap - EXIT
  if cp -R "$TEST_RUN_OUTPUT/." "$TEST_OUTPUT/"; then
    rm -rf "$TEST_RUN_OUTPUT"
  else
    echo "Could not save all reports; temporary results retained at $TEST_RUN_OUTPUT" >&2
    test_status=1
  fi
  rm -rf "$TEST_BUILD_DIR"
  exit "$test_status"
}
trap finish_tests EXIT
rm -f "$TEST_OUTPUT/document-test-results.txt" "$TEST_OUTPUT/document-core-test-results.txt"
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework QuartzCore -framework AVFoundation \
  "$TEST_SOURCE_ROOT/Sources/Localization.swift" "$TEST_SOURCE_ROOT/Sources/ThumbnailRequest.swift" "$TEST_SOURCE_ROOT/Sources/PostScriptDocument.swift" "$TEST_SOURCE_ROOT/Sources/VectorRenderer.swift" \
  "$TEST_SOURCE_ROOT/Sources/DocumentMedia.swift" "$TEST_SOURCE_ROOT/Sources/PhotoCanvas.swift" \
  "$TEST_SOURCE_ROOT/Tests/DocumentMediaTests.swift" -o "$TEST_BUILD_DIR/document-core-tests"
"$TEST_BUILD_DIR/document-core-tests" | tee "$TEST_RUN_OUTPUT/document-core-test-results.txt"
if [[ "${LUMAVIEW_SKIP_TEST_BUILD:-0}" != "1" ]]; then
  LUMAVIEW_TEST_BUILD=1 LUMAVIEW_APP_PATH="$TEST_APP_PATH" "$TEST_SOURCE_ROOT/build.sh" --host
fi
# Only the parent shell copies results into Documents after the GUI app exits.
open -n -W "$TEST_APP_PATH" --stdout "$TEST_RUN_OUTPUT/document-app-stdout.log" --stderr "$TEST_RUN_OUTPUT/document-app-stderr.log" --args --document-self-test "$TEST_RUN_OUTPUT"
cat "$TEST_RUN_OUTPUT/document-test-results.txt"
awk '/^FAIL / {failed=1} END {exit failed}' "$TEST_RUN_OUTPUT/document-test-results.txt"
