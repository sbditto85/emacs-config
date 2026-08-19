---
name: upgrade-dependencies
description: Check for Elpaca package updates in this Emacs config, review each package's upstream commits for security/behavior concerns, get approval, then apply approved updates and regenerate elpaca-lock.el. Use when asked to upgrade/update Emacs packages, check for outdated dependencies, or review elpaca-lock.el changes.
---

# Upgrading Elpaca dependencies

This repo pins every package to an exact commit in `elpaca-lock.el`. This skill
finds packages with newer upstream commits, has you (Claude) read the actual
diffs and summarize/flag them, gets the user's explicit approval, then applies
only the approved updates and regenerates the lock file — all through Elpaca's
own build machinery, never by hand-editing the lock file.

Run everything from the repo root. **Do not run this while the user's Emacs is
open** — both scripts boot a second, separate Emacs process against the same
`elpaca/` directory the user's live Emacs uses; confirm with the user if
unsure.

## Step 1 — Scan for outdated packages

```sh
emacs -Q --batch --init-directory=. -l init.el -l scripts/elpaca-outdated.el
```

This boots the real config headlessly (so every package declared via
`use-package`/`elpaca` gets queued exactly as it would in normal Emacs),
fetches `origin` for every package's git checkout, and compares the currently
pinned commit against `origin`'s default branch tip. It writes
`var/elpaca-outdated.tsv` (gitignored) with one line per **repo** (not per
package — mono-repos like `magit`/`magit-section` or `treemacs` and its
sub-packages share one checkout and one line):

```
package-ids(comma separated)<TAB>source-dir<TAB>remote-url<TAB>old-ref<TAB>new-ref
```

If a row lists multiple package ids, approving or rejecting it applies to all
of them together — they cannot be updated independently.

## Step 2 — Review each outdated repo

For every row in the TSV, inspect the actual changes between `old-ref` and
`new-ref` in `source-dir`:

```sh
git -C <source-dir> log --oneline <old-ref>..<new-ref>
git -C <source-dir> diff --stat <old-ref>..<new-ref>
git -C <source-dir> log -p <old-ref>..<new-ref>          # full diff — read it
```

Also do a best-effort check for known advisories against the repo itself
(derive owner/repo from the remote URL column):

```sh
gh api repos/<owner>/<repo>/security-advisories 2>/dev/null
```

If `gh` isn't authenticated or the call fails, note that the advisory check
was skipped for that package rather than silently omitting it.

There is no CVE/vulnerability database for arbitrary GitHub-hosted Elisp
packages (unlike `npm audit`/`pip-audit`), so the security review here means
**you actually read the diffs** and flag anything that looks off: new network
calls, `eval`/`shell-command`/curl-pipe-sh patterns, obfuscated or minified
code, credential/env access, sudden unexplained maintainer or repo changes,
or a jump to a suspiciously large/unrelated diff for a "minor" version bump.
Absence of a flag means "nothing suspicious found in this diff," not "proven
safe."

For each repo, produce a short summary: commit count, one or two sentences on
what functionally changed, and an explicit security line (either "no
concerns" or the specific flag).

## Step 3 — Get approval

Present the full set of summaries to the user in one batch (not one at a
time) and ask which repos to approve for update. Anything not explicitly
approved is left untouched — its checkout, and its `elpaca-lock.el` entry,
stay exactly as they are.

## Step 4 — Apply approved updates

Build a `source-dir=new-ref` argument per approved row (from the same TSV
columns) and run:

```sh
emacs -Q --batch --init-directory=. -l init.el -l scripts/elpaca-apply-update.el -- \
  <source-dir-1>=<new-ref-1> <source-dir-2>=<new-ref-2> ...
```

For each pair this checks out exactly `new-ref` with plain `git checkout`
(not a re-fetch/re-merge, so it's immune to any commits that landed upstream
between review and approval), then calls `elpaca-rebuild` on every package id
backed by that directory, waits for all rebuilds via `elpaca-wait`, and
finally calls `elpaca-write-lock-file` to regenerate `elpaca-lock.el` from
Elpaca's own state. Watch the output for byte-compile/native-comp errors or
warnings and surface them — don't treat a clean exit code alone as success.

## Step 5 — Hand back for review

Show the user `git diff elpaca-lock.el` so they can see exactly what moved.
Do not stage or commit it — per standard git-safety practice, only commit
when the user explicitly asks. Suggest they restart Emacs and exercise the
updated packages before committing, since the rebuild only recompiles the
package, it doesn't reload it into any already-running Emacs.

## Rejecting everything

If the user approves nothing, stop after Step 3 — there's nothing to apply,
and the lock file and checkouts remain untouched.
