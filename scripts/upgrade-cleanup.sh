#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/upgrade-lib.sh"

require_candidate

git -C "$repo" worktree remove --force "$candidate"

echo "Removed the candidate"
