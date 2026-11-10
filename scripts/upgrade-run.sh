#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 CONFIG-DIR SCRIPT.el [ARGS...]" >&2
  exit 1
fi

scripts="$(cd "$(dirname "$0")" && pwd)"
config_dir="$(cd "$1" && pwd)"
script="$2"
shift 2

case "$script" in
  /*) ;;
  *) script="$scripts/$script" ;;
esac

exec emacs -Q --batch \
  --init-directory="$config_dir" \
  -l "$scripts/elpaca-upgrade-lib.el" \
  -l "$config_dir/init.el" \
  -l "$script" \
  -- "$@" < /dev/null
