#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/upgrade-lib.sh"

require_candidate
require_live_emacs_closed

if ! git -C "$repo" diff --cached --quiet; then
  echo "The repository has staged changes; commit or unstage them first" >&2
  exit 1
fi

# Staging the candidate's changes first means a conflict stops the landing
# before any live package has been touched. - Casey, Tue Nov 10 2026
git -C "$candidate" add -A
git -C "$candidate" diff --cached --binary HEAD | git -C "$repo" apply --index --3way

rm -rf "$repo/elpaca.prev"
copy_tree "$repo/elpaca" "$repo/elpaca.prev"

if ! "$repo/scripts/upgrade-run.sh" "$repo" elpaca-sync-to-lock.el \
     --from-sources "$candidate/elpaca/sources"; then
  echo >&2
  echo "Syncing the live packages failed; to undo, run scripts/upgrade-rollback.sh" >&2
  exit 1
fi

"$repo/scripts/upgrade-run.sh" "$repo" elpaca-check.el --label landed > /dev/null

reports="var/upgrade"
echo
echo "Live check: $repo/$reports/check-landed.md"
if diff <(tail -n +2 "$candidate/$reports/check-after.md") <(tail -n +2 "$repo/$reports/check-landed.md"); then
  echo "The live check matches the candidate's check."
else
  echo "The live check differs from the candidate's check (shown above)."
fi
echo
echo "The upgrade is staged but not committed. Review it with: git diff --cached"
echo "To undo, run scripts/upgrade-rollback.sh"
echo "After committing, remove the candidate with scripts/upgrade-cleanup.sh"
