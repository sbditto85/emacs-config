#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/upgrade-lib.sh"

if [ -e "$candidate" ]; then
  echo "Candidate already exists at $candidate" >&2
  echo "Land it, or remove it with scripts/upgrade-cleanup.sh" >&2
  exit 1
fi

# The candidate is checked out from HEAD, so uncommitted config changes
# would silently be left out of what gets tested. - Casey, Tue Nov 10 2026
if ! git -C "$repo" diff --quiet HEAD -- init.el early-init.el config.org elpaca-lock.el custom; then
  echo "The config has uncommitted changes; commit or stash them first" >&2
  exit 1
fi

git -C "$repo" worktree add --quiet --detach "$candidate" HEAD

copy_tree "$repo/elpaca" "$candidate/elpaca"

# Elpaca links build files to sources by absolute path, so without
# repointing, the candidate's builds would load the live sources. Elpaca
# may have written either the logical or the physical path of the repo.
# - Casey, Tue Nov 10 2026
live_sources="$repo/elpaca/sources/"
live_sources_physical="$(cd "$repo" && pwd -P)/elpaca/sources/"
candidate_sources="$candidate/elpaca/sources/"
while IFS= read -r -d '' link; do
  target="$(readlink "$link")"
  case "$target" in
    "$live_sources"*) relative="${target#"$live_sources"}" ;;
    "$live_sources_physical"*) relative="${target#"$live_sources_physical"}" ;;
    *) continue ;;
  esac
  ln -sfn "$candidate_sources$relative" "$link"
done < <(find "$candidate/elpaca/builds" -type l -print0)

# A link left pointing at the live sources would make every check test the
# live packages instead of the candidate's. - Casey, Tue Nov 10 2026
while IFS= read -r -d '' link; do
  target="$(readlink "$link")"
  case "$target" in
    "$candidate_sources"*) ;;
    *"/elpaca/sources/"*)
      echo "$link still points outside the candidate: $target" >&2
      echo "Remove the candidate with scripts/upgrade-cleanup.sh" >&2
      exit 1
      ;;
  esac
done < <(find "$candidate/elpaca/builds" -type l -print0)

# CMake refuses to reuse a cache generated for a different directory, which
# breaks recompiling native modules such as vterm's. - Casey, Tue Nov 10 2026
find "$candidate/elpaca/builds" -name CMakeCache.txt -path '*/build/*' -delete

echo "Candidate: $candidate"
