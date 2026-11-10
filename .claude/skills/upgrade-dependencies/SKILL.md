---
name: upgrade-dependencies
description: Upgrade this Emacs config's Elpaca packages (Elpaca included) in an isolated candidate copy, review every upstream change against how the config uses the package, auto-apply needed config fixes, smoke test, and land only after the user reviews. Use when asked to upgrade/update Emacs packages or Elpaca, check for outdated dependencies, or review elpaca-lock.el changes.
---

# Upgrade Dependencies

Every package is pinned to an exact commit in `elpaca-lock.el`. Because each lock file recipe carries a `:ref`, Elpaca treats every package as pinned, so `elpaca-update-all` does nothing; never use it, and never hand-edit `elpaca-lock.el`.

The upgrade is built in a candidate: a detached git worktree at `var/upgrade-candidate/` with a copy of `elpaca/` (copy-on-write on APFS, btrfs, and XFS; a full copy on other filesystems). The scripts run on macOS and Linux. Everything up to landing happens there, so the user's running Emacs is never touched and they can keep working. Landing stages the changes in the repository and moves the live packages to the reviewed commits; the user reviews and commits.

Run every command from the repository root. Never commit; the user commits after reviewing, and if they ask you to commit, use the git-commit skill.

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/upgrade-prepare.sh` | Create the candidate |
| `scripts/upgrade-run.sh DIR SCRIPT.el [ARGS]` | Boot the config in `DIR` headlessly and run an Elisp script |
| `elpaca-outdated.el` | Fetch every repo and write `var/upgrade/outdated.tsv` |
| `elpaca-apply-update.el REPO=REF ...` | Check out reviewed commits and rebuild |
| `elpaca-check.el --label NAME [--write-lock]` | Smoke test and write `var/upgrade/check-NAME.md` |
| `elpaca-sync-to-lock.el [--dry-run]` | Move checkouts to the refs in the lock file and rebuild |
| `scripts/upgrade-try.sh` | Open a GUI Emacs on the candidate, alongside the live one |
| `scripts/upgrade-land.sh` | Stage the candidate's changes and sync the live packages |
| `scripts/upgrade-rollback.sh` | Restore the live packages from before landing |
| `scripts/upgrade-cleanup.sh` | Remove the candidate |

Report paths below are relative to the candidate (`var/upgrade-candidate/var/upgrade/`). Batch output always contains a few known messages (`Source file ... newer than byte-compiled file`, `Failed to restore scratch buffers`, startup warnings); the check reports are the place to look, not the raw output.

## 1. Prepare

```sh
scripts/upgrade-prepare.sh
scripts/upgrade-run.sh var/upgrade-candidate elpaca-outdated.el
scripts/upgrade-run.sh var/upgrade-candidate elpaca-check.el --label baseline
```

If a candidate already exists, ask the user whether to continue it or remove it with `scripts/upgrade-cleanup.sh`.

`outdated.tsv` has one row per repo, not per package: mono-repos such as `magit` (`magit`, `magit-section`), `embark`, `treemacs`, and `elpaca` (`elpaca`, `elpaca-use-package`) provide several package ids and are updated together. Columns: `repo`, `ids`, `source-dir`, `url`, `old-ref`, `new-ref`, `branch`, `commits`, `fast-forward`, `changes`.

`check-baseline.md` records the problems that already exist, so that only new problems are attributed to the upgrade.

## 2. Review

The user does not know what to look for in upstream Elisp changes; this review is the reason the skill exists. The question for each repo is "does this change affect how this config uses the package?", not "what changed?"

For each repo, build a usage profile, then read the changes against it.

### Usage Profile

Search `config.org`, `init.el`, `early-init.el`, and `custom/` for:

- The package's `use-package` block, and everything in it: `:custom`, `:bind`, `:general`, `:hook`, `:init`, `:config`, `:after`, `:ensure` recipe.
- Every symbol with the package's prefix (`consult-`, `evil-collection-`, ...), anywhere in the config, including keybindings made with `general` and `evil-define-key`.
- Private symbols (with a double hyphen, such as `consult--source-buffer`). Upstream renames these without notice; any use of one is high risk and must be checked against the new code.
- Packages the config uses through this one: `embark-consult`, `treemacs-evil`, the `evil-collection` modes the config enables, and so on.

### What To Look For

Read the change history first, then the code:

```sh
git -C <source-dir> log --oneline <old-ref>..<new-ref>
git -C <source-dir> diff <old-ref> <new-ref> -- 'NEWS*' 'CHANGELOG*' '*.org' '*.md'
git -C <source-dir> diff <old-ref> <new-ref> -- '*.el'
```

Then check each of these against the usage profile:

- **Removed or renamed definitions.** A `defun`, `defvar`, `defcustom`, `defmacro`, `defalias`, `defface`, keymap, or mode the config uses now only appears on a `-` line.
- **Obsolete declarations.** New `make-obsolete`, `make-obsolete-variable`, `define-obsolete-function-alias`, or `define-obsolete-variable-alias` forms naming a symbol the config uses. These keep working for now, but the replacement should be adopted.
- **Changed signatures.** Functions the config calls, or hooks it adds functions to, now take different arguments.
- **Changed defaults.** A `defcustom` the config relies on without setting has a new default; behavior changes silently.
- **Changed key bindings.** Upstream maps now bind or unbind keys the config also binds, which matters especially with `evil-collection`.
- **Package metadata.** `Package-Requires` raises the minimum Emacs version (this config runs Emacs 32), raises a dependency's minimum version, or adds a new dependency. A new dependency is new code to review.
- **Load-time behavior.** Code that now runs on `require` or on mode activation: new timers, hooks added globally, advice on core functions.

Then a security pass over the whole diff:

- New network access (`url-retrieve`, `make-network-process`, curl or wget), new process execution (`call-process`, `start-process`, `shell-command`), or `eval` of data read from files or the network.
- Obfuscated, minified, encoded, or binary content; new executables or build scripts.
- Access to credentials, `auth-source`, environment variables, or files outside the package's own concerns.
- A change of maintainer or repository URL, or `fast-forward` being `NO` (upstream rewrote history). Always flag these.
- A large or unrelated change in what the commit messages describe as minor.

A clean security pass means nothing suspicious was found in the diff, not that the package is proven safe; say so in those terms.

For `elpaca`, also compare `elpaca-installer-version` in the new `elpaca.el` with the value in `init.el`, and the installer block in the new `README.org` with the bootstrap in `init.el`. If either changed, propose the `init.el` update as a config change.

### Delegating

Review in parallel, with one general-purpose subagent per repo that has a non-trivial diff or appears in the usage profile; batch trivial repos (one or two small commits, no usage beyond loading the package) into a single subagent. Give each subagent the row from `outdated.tsv`, the instructions in this section, and the paths of the config files, and have it return, for each repo: a verdict, the reason for it, any exact config edit, and the security result.

### Verdicts

- **No impact:** nothing in the change touches the usage profile.
- **Needs config change:** the upgrade is fine with a specific edit to `config.org` (or `init.el` or `custom/`); give the exact edit.
- **Hold:** do not upgrade now; give the reason (a breaking change without a clear fix, a security concern, a dependency that cannot be upgraded).

Write the review to `review.md` in the reports directory: a summary table (repo, commits, verdict, one-line reason), followed by a section for each repo whose verdict is not "no impact" with a short explanation of why the change matters for this config. Present the table and those sections to the user; one line is enough for "no impact" repos.

## 3. Approve

Ask the user which repos to upgrade, all in one question. The default to offer is every repo except those on hold. Repos that are not approved keep their current commit and lock file entry. If nothing is approved, remove the candidate with `scripts/upgrade-cleanup.sh` and stop.

## 4. Apply

Pass a `repo=new-ref` pair for every approved row (the `repo` and `new-ref` columns):

```sh
scripts/upgrade-run.sh var/upgrade-candidate elpaca-apply-update.el <repo>=<new-ref> ...
```

This checks out exactly the reviewed commit (it never pulls, so nothing that landed upstream after the review is picked up) and rebuilds every package from that repo, plus any package whose build is older than its source.

Then make the config edits from the "needs config change" verdicts in the candidate's files (`var/upgrade-candidate/config.org` and so on, never the live ones). Make them without asking; the user reviews them before anything lands.

## 5. Check

```sh
scripts/upgrade-run.sh var/upgrade-candidate elpaca-check.el --label after --write-lock
diff var/upgrade-candidate/var/upgrade/check-baseline.md var/upgrade-candidate/var/upgrade/check-after.md
```

Booting installs any new dependency, and `--write-lock` then regenerates the candidate's `elpaca-lock.el`. The check also compiles native modules such as vterm's without prompting.

Every new entry in the report is attributable to the upgrade and must be resolved: fix the config and run the check again, or move the repo to hold (check it back out at `old-ref` with `elpaca-apply-update.el` and run the check again). Sections:

- **Packages That Did Not Finish:** an Elpaca build or install failed.
- **Startup Warnings:** warnings raised while booting the config.
- **Packages That Fail To Load:** `require` of the package signals an error.
- **Config Compile Warnings:** the config compiled with every package loaded, which shows obsolete, undefined, and wrong-arity calls. Its line numbers refer to the candidate's generated `config.el`; find the matching block in `config.org`. It misses some problems inside `use-package` bodies, so it supplements the review, not replaces it.
- **Stale Builds:** byte-compiled files older than their source.
- **Differences From Lock File:** checkouts that disagree with the lock file; always none after `--write-lock`.
- **Lock File Changes Since HEAD:** the refs that moved, which is the readable version of the lock file diff (Elpaca reformats recipes between versions, so the raw diff can be noisy).

## 6. User Review

Give the user:

- The verdict table, the config edits made, and anything new in the check compared with the baseline.
- `git -C var/upgrade-candidate diff` for the full change.
- The offer to try the candidate interactively with `scripts/upgrade-try.sh`, which opens a separate GUI Emacs on the candidate while their live Emacs keeps running.

Wait for the user's go-ahead before landing.

## 7. Land

The user must quit their live Emacs first; the script refuses to run otherwise. Then:

```sh
scripts/upgrade-land.sh
```

This stages the candidate's changes in the repository (`git apply --index --3way`, so a conflict stops it before any package is touched), snapshots `elpaca/` to `elpaca.prev/`, moves the live checkouts to the locked refs (fetching them from the candidate, not the network), rebuilds what changed, and runs the check against the live config as `check-landed.md`. It reports whether that check matches the candidate's.

Only changed packages are rebuilt, so Emacs natively recompiles only those packages in the background on the next launch.

Then tell the user the upgrade is staged but not committed, and offer a commit message built from `review.md`: a summary line, the upgraded repos with their verdicts, the config changes made, and the repos held with the reason.

After the user commits, remove the candidate:

```sh
scripts/upgrade-cleanup.sh
```

## Rollback

With Emacs closed:

```sh
scripts/upgrade-rollback.sh
```

This puts `elpaca.prev/` back as `elpaca/` and keeps the failed install as `elpaca.failed/`. It then prints the git step for undoing the config changes: `git restore --staged --worktree ...` if the upgrade is not committed, or `git revert` if it is.

Once a later upgrade has replaced the snapshot, roll back by reverting the commit and running `scripts/upgrade-run.sh . elpaca-sync-to-lock.el`.
