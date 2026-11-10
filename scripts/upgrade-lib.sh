#!/usr/bin/env bash

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
candidate="$repo/var/upgrade-candidate"

require_candidate() {
  if [ ! -e "$candidate" ]; then
    echo "No candidate at $candidate; run scripts/upgrade-prepare.sh first" >&2
    exit 1
  fi
}

# Copy-on-write keeps the copy instant and nearly free on APFS, btrfs, and
# XFS; on other Linux filesystems it falls back to a full copy. Timestamps
# must be preserved or every source looks newer than its byte-compiled
# file. - Casey, Tue Nov 10 2026
copy_tree() {
  case "$(uname -s)" in
    Darwin*) cp -c -p -R "$1" "$2" ;;
    *) cp --reflink=auto -p -R "$1" "$2" ;;
  esac
}

# A running Emacs keeps this config's native-compiled files mapped, which
# identifies it even though it was started with a relative --init-dir. The
# kernel reports the physical path, which differs from $repo when the path
# goes through a symlink. - Casey, Tue Nov 10 2026
live_emacs_running() {
  local eln_cache
  eln_cache="$(cd "$repo" && pwd -P)/eln-cache/"
  case "$(uname -s)" in
    Darwin*)
      local open_files
      open_files="$(lsof -c Emacs -Fn 2>/dev/null || true)"
      grep -q -F "n$eln_cache" <<< "$open_files"
      ;;
    *)
      grep -q -s -F "$eln_cache" /proc/[0-9]*/maps
      ;;
  esac
}

require_live_emacs_closed() {
  if live_emacs_running; then
    echo "Emacs is running with this config; quit it first" >&2
    exit 1
  fi
}
