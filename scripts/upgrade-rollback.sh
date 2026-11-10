#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/upgrade-lib.sh"

require_live_emacs_closed

if [ ! -d "$repo/elpaca.prev" ]; then
  echo "No snapshot at $repo/elpaca.prev to roll back to" >&2
  echo "Instead, revert the upgrade commit and run:" >&2
  echo "  scripts/upgrade-run.sh . elpaca-sync-to-lock.el" >&2
  exit 1
fi

# The failed install is kept so it can be inspected; the snapshot's build
# links point at elpaca/sources by absolute path, so they resolve again as
# soon as it is moved back. - Casey, Tue Nov 10 2026
rm -rf "$repo/elpaca.failed"
mv "$repo/elpaca" "$repo/elpaca.failed"
mv "$repo/elpaca.prev" "$repo/elpaca"

echo "Restored the packages from before the upgrade; the failed install is in elpaca.failed"
echo
echo "Now undo the config changes:"
echo "  Not yet committed: git restore --staged --worktree elpaca-lock.el init.el early-init.el config.org custom"
echo "  Already committed: git revert <upgrade commit>"
