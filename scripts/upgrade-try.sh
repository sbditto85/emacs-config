#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/upgrade-lib.sh"

require_candidate

case "$(uname -s)" in
  Darwin*) open -na Emacs --args --chdir "$repo" --init-dir "$candidate" "$@" ;;
  *) nohup emacs --chdir "$repo" --init-dir "$candidate" "$@" > /dev/null 2>&1 & ;;
esac
