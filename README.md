# Emacs Configuration Example

Example configuration for teaching others how to build their own Emacs configuration.

## Updating Packages

Every package, Elpaca included, is pinned to an exact commit in `elpaca-lock.el`. Because each lock file recipe has a `:ref`, Elpaca treats every package as pinned, so `M-x elpaca-update-all` does nothing. Do not edit `elpaca-lock.el` by hand either; it is regenerated during the upgrade.

Upgrade with the `upgrade-dependencies` Claude skill ([`.claude/skills/upgrade-dependencies/SKILL.md`](.claude/skills/upgrade-dependencies/SKILL.md)). From the repository root, start Claude Code and run `/upgrade-dependencies`. The scripts it uses run on macOS and Linux.

The upgrade is built in a candidate, a separate copy of the config at `var/upgrade-candidate/`, so the running Emacs is untouched until the upgrade lands. Commit or stash any changes to the config first; the candidate is created from `HEAD`.

### Process

1. **Prepare.** Claude creates the candidate, fetches every package's repository to find what is outdated, and runs a baseline check that records the problems that already exist.
2. **Review.** Claude reads each upstream change against how this config uses the package, including a security pass, and gives each repository a verdict: no impact, needs a config change, or hold.
3. **Approve.** Choose which repositories to upgrade. The default is everything not on hold.
4. **Apply.** Claude checks out exactly the reviewed commits in the candidate, rebuilds them, and makes the needed config changes in the candidate's files.
5. **Check.** Claude boots the candidate headlessly, loads every package, compiles the config, regenerates the candidate's lock file, and compares the result with the baseline. Anything new is fixed or its repository is moved to hold.
6. **Review the candidate.** Read the change with `git -C var/upgrade-candidate diff`. To try it interactively alongside the running Emacs, run `scripts/upgrade-try.sh`.
7. **Land.** Quit Emacs, then run `scripts/upgrade-land.sh`. It stages the candidate's changes in the repository, snapshots `elpaca/` to `elpaca.prev/`, moves the live packages to the reviewed commits, and checks the live config. Nothing is committed.
8. **Commit.** Review the staged change with `git diff --cached` and commit it. Claude offers a commit message built from the review.
9. **Clean up.** Remove the candidate with `scripts/upgrade-cleanup.sh`.

On the next launch, Emacs natively recompiles the upgraded packages in the background.

### Rolling Back

With Emacs closed, run:

```bash
scripts/upgrade-rollback.sh
```

This restores `elpaca.prev/` as `elpaca/`, keeps the failed install as `elpaca.failed/`, and prints the git step for undoing the config changes.

Once a later upgrade has replaced the snapshot, revert the upgrade's commit and move the packages back to the reverted lock file:

```bash
scripts/upgrade-run.sh . elpaca-sync-to-lock.el
```

### Abandoning an Upgrade

To discard an upgrade before landing it, run `scripts/upgrade-cleanup.sh`. The live config and packages are unaffected.
