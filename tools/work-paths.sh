#!/bin/bash
# Shared by build and test scripts. Keep generated files inside each checkout.
LUMAVIEW_SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUMAVIEW_WORK_ROOT="${LUMAVIEW_WORK_ROOT:-$LUMAVIEW_SCRIPT_ROOT/.build}"
mkdir -p "$LUMAVIEW_WORK_ROOT/tmp"
LUMAVIEW_WORK_ROOT="$(cd "$LUMAVIEW_WORK_ROOT" && pwd -P)"
export LUMAVIEW_WORK_ROOT
unset LUMAVIEW_SCRIPT_ROOT
