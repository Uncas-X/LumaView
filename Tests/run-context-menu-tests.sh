#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_APP_PATH="${LUMAVIEW_TEST_APP_PATH:-$LUMAVIEW_WORK_ROOT/LumaView-context-menu-test.app}"
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/context-menu-ui-tests}"
mkdir -p "$TEST_OUTPUT"
TEST_RUN_OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-context-results.XXXXXX")"
TEST_RUN_OUTPUT="$(cd "$TEST_RUN_OUTPUT" && pwd -P)"
case "$TEST_RUN_OUTPUT" in /private/var/*|/private/tmp/*) TEST_RUN_OUTPUT="${TEST_RUN_OUTPUT#/private}" ;; esac
finish_tests() {
  local test_status=$?
  trap - EXIT
  if cp -R "$TEST_RUN_OUTPUT/." "$TEST_OUTPUT/"; then rm -rf "$TEST_RUN_OUTPUT";
  else echo "Could not save reports; results retained at $TEST_RUN_OUTPUT" >&2; test_status=1; fi
  exit "$test_status"
}
trap finish_tests EXIT
rm -f "$TEST_OUTPUT/context-menu-test-results.txt"
if [[ "${LUMAVIEW_SKIP_TEST_BUILD:-0}" != "1" ]]; then
  LUMAVIEW_TEST_BUILD=1 LUMAVIEW_APP_PATH="$TEST_APP_PATH" "$TEST_SOURCE_ROOT/build.sh" --host
fi
open -n -W "$TEST_APP_PATH" --stdout "$TEST_RUN_OUTPUT/context-menu-app-stdout.log" --stderr "$TEST_RUN_OUTPUT/context-menu-app-stderr.log" --args --context-menu-self-test "$TEST_RUN_OUTPUT"
cat "$TEST_RUN_OUTPUT/context-menu-test-results.txt"
awk '/^FAIL / {failed=1} END {exit failed}' "$TEST_RUN_OUTPUT/context-menu-test-results.txt"
