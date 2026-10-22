#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_APP_PATH="${LUMAVIEW_TEST_APP_PATH:-$LUMAVIEW_WORK_ROOT/LumaView-video-test.app}"
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/video-tests}"
mkdir -p "$TEST_OUTPUT"
TEST_RUN_OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-video-results.XXXXXX")"
TEST_RUN_OUTPUT="$(cd "$TEST_RUN_OUTPUT" && pwd -P)"
# Foundation standardizes these macOS temp aliases without the /private prefix.
# Match its file URL spelling while retaining a normalized, single-slash path.
case "$TEST_RUN_OUTPUT" in
  /private/var/*|/private/tmp/*) TEST_RUN_OUTPUT="${TEST_RUN_OUTPUT#/private}" ;;
esac
finish_tests() {
  local test_status=$?
  trap - EXIT
  # Always preserve available stage reports/logs, including early failures.
  if cp -R "$TEST_RUN_OUTPUT/." "$TEST_OUTPUT/"; then
    rm -rf "$TEST_RUN_OUTPUT"
  else
    echo "Could not save all reports; temporary results retained at $TEST_RUN_OUTPUT" >&2
    test_status=1
  fi
  exit "$test_status"
}
trap finish_tests EXIT
rm -f "$TEST_OUTPUT/video-test-results.txt" "$TEST_OUTPUT/extended-media-test-results.txt"
if [[ "${LUMAVIEW_SKIP_TEST_BUILD:-0}" != "1" ]]; then
  LUMAVIEW_TEST_BUILD=1 LUMAVIEW_APP_PATH="$TEST_APP_PATH" "$TEST_SOURCE_ROOT/build.sh" --host
fi
# Both stages share this fresh directory because compatibility tests reuse the
# native video fixtures, but neither stage touches earlier workspace files.
open -n -W "$TEST_APP_PATH" --stdout "$TEST_RUN_OUTPUT/video-app-stdout.log" --stderr "$TEST_RUN_OUTPUT/video-app-stderr.log" --args --video-self-test "$TEST_RUN_OUTPUT"
cat "$TEST_RUN_OUTPUT/video-test-results.txt"
awk '/^FAIL / {failed=1} END {exit failed}' "$TEST_RUN_OUTPUT/video-test-results.txt"
open -n -W "$TEST_APP_PATH" --stdout "$TEST_RUN_OUTPUT/extended-media-app-stdout.log" --stderr "$TEST_RUN_OUTPUT/extended-media-app-stderr.log" --args --extended-media-self-test "$TEST_RUN_OUTPUT"
cat "$TEST_RUN_OUTPUT/extended-media-test-results.txt"
awk '/^FAIL / {failed=1} END {exit failed}' "$TEST_RUN_OUTPUT/extended-media-test-results.txt"
