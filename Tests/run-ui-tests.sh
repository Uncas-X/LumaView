#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_APP_PATH="${LUMAVIEW_TEST_APP_PATH:-$LUMAVIEW_WORK_ROOT/LumaView-test.app}"
if [[ "${LUMAVIEW_SKIP_TEST_BUILD:-0}" != "1" ]]; then
  LUMAVIEW_TEST_BUILD=1 LUMAVIEW_APP_PATH="$TEST_APP_PATH" "$TEST_SOURCE_ROOT/build.sh" --host
fi
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/ui-tests}"
TEST_REPORT="$TEST_OUTPUT/ui-test-results.txt"
TEST_RUN_OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-ui-results.XXXXXX")"
TEST_RUN_OUTPUT="$(cd "$TEST_RUN_OUTPUT" && pwd -P)"
# Foundation standardizes macOS /private aliases back to /var and /tmp.
case "$TEST_RUN_OUTPUT" in
  /private/var/*|/private/tmp/*) TEST_RUN_OUTPUT="${TEST_RUN_OUTPUT#/private}" ;;
esac
trap 'rm -rf "$TEST_RUN_OUTPUT"' EXIT
mkdir -p "$TEST_OUTPUT"
rm -f "$TEST_REPORT"
# Launch Services grants the same foreground activation as opening the app in Finder.
open -n -W "$TEST_APP_PATH" --args --self-test "$TEST_RUN_OUTPUT"
# Give each app invocation fresh fixtures; the shell owns the saved reports.
cp -R "$TEST_RUN_OUTPUT/." "$TEST_OUTPUT/"
cat "$TEST_REPORT"
awk '/^FAIL / {failed=1} END {exit failed}' "$TEST_REPORT"
